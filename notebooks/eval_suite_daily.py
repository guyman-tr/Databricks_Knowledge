# Databricks notebook source
# MAGIC %md
# MAGIC # DDR Eval Suite — Daily Run
# MAGIC
# MAGIC Imports the portable harness from `tools/eval_suite/harness` and runs every
# MAGIC live case once against each configured System Under Test. Writes telemetry
# MAGIC to a Delta table for the Quality Gate dashboard.
# MAGIC
# MAGIC **What this notebook is**
# MAGIC - A thin driver. All harness logic (loading cases, scoring, drift
# MAGIC   classification, judge scoring, telemetry) lives in
# MAGIC   `tools/eval_suite/harness/` and is shared with the Cursor CLI driver
# MAGIC   `tools/eval_suite/run_harness.py`.
# MAGIC - Designed to run on a serverless or shared cluster with the
# MAGIC   `Databricks_Knowledge` repo synced via Repos / Git folders.
# MAGIC
# MAGIC **What this notebook is NOT**
# MAGIC - A place to fix harness bugs. Bugs go in `tools/eval_suite/harness/*.py`.
# MAGIC - A place to author cases. Cases live in `tools/eval_suite/cases/ddr/*.yaml`.
# MAGIC
# MAGIC **Required job parameters / widgets**
# MAGIC | Widget | Default | Notes |
# MAGIC |---|---|---|
# MAGIC | `cases_root` | `tools/eval_suite/cases` | repo-relative path |
# MAGIC | `tags` | `` | comma-separated tag filter; blank = all live cases |
# MAGIC | `suts` | `direct_sql,databricks_mcp,genie_code` | comma-separated SUT names |
# MAGIC | `enable_judge` | `false` | requires `ANTHROPIC_API_KEY` secret |
# MAGIC | `telemetry_table` | `main.bi_db.eval_suite_runs` | Delta target |
# MAGIC | `genie_space_id` | `` | required if `genie_code` SUT is in the list |

# COMMAND ----------

# MAGIC %md
# MAGIC ## 0. Setup
# MAGIC Pip-install the model SDK if running a SUT that needs it. The Genie SUT
# MAGIC and `direct_sql` need only `databricks-sdk` (already on every cluster).
# MAGIC The `databricks_mcp` SUT needs `anthropic` and `mcp`.

# COMMAND ----------

# MAGIC %pip install -q anthropic mcp httpx pyyaml
# COMMAND ----------
dbutils.library.restartPython()

# COMMAND ----------

import os
import sys
import datetime as dt

dbutils.widgets.text("cases_root", "tools/eval_suite/cases", "Cases root (repo-relative)")
dbutils.widgets.text("tags", "", "Tag filter (comma-separated)")
dbutils.widgets.text("suts", "direct_sql,databricks_mcp,genie_code", "SUTs (comma-separated)")
dbutils.widgets.dropdown("enable_judge", "false", ["true", "false"], "Run LLM judge?")
dbutils.widgets.text("telemetry_table", "main.bi_db.eval_suite_runs", "Delta target table")
dbutils.widgets.text("genie_space_id", "", "Genie Space ID (for genie_code SUT)")
dbutils.widgets.text("repo_root", "", "Override repo root (auto-detected if blank)")

cases_root_param = dbutils.widgets.get("cases_root")
tags_param = [t.strip() for t in dbutils.widgets.get("tags").split(",") if t.strip()]
suts_param = [s.strip() for s in dbutils.widgets.get("suts").split(",") if s.strip()]
enable_judge = dbutils.widgets.get("enable_judge") == "true"
telemetry_table = dbutils.widgets.get("telemetry_table").strip()
genie_space_id = dbutils.widgets.get("genie_space_id").strip()
repo_root_override = dbutils.widgets.get("repo_root").strip()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Locate the repo and put `tools/` on `sys.path`

# COMMAND ----------

def _locate_repo_root() -> str:
    if repo_root_override:
        return repo_root_override
    # Strategy 1: Notebook is inside a Repos folder. The repo root is one of the
    # parents that contains `tools/eval_suite/`.
    nb_path = (
        dbutils.notebook.entry_point.getDbutils().notebook().getContext()
        .notebookPath().getOrElse(None)
    )
    if nb_path:
        candidate = "/Workspace" + nb_path  # not always correct on Git folders
        for parent in (
            os.path.dirname(candidate),
            os.path.dirname(os.path.dirname(candidate)),
            os.path.dirname(os.path.dirname(os.path.dirname(candidate))),
        ):
            if os.path.isdir(os.path.join(parent, "tools", "eval_suite", "harness")):
                return parent
    # Strategy 2: Fall back to /Workspace/Repos/<user>/Databricks_Knowledge
    user = os.environ.get("USER") or os.environ.get("USERNAME") or "unknown"
    fallback = f"/Workspace/Repos/{user}/Databricks_Knowledge"
    if os.path.isdir(os.path.join(fallback, "tools", "eval_suite", "harness")):
        return fallback
    raise RuntimeError(
        "Could not locate Databricks_Knowledge repo root. "
        "Set the `repo_root` widget explicitly."
    )


REPO_ROOT = _locate_repo_root()
print(f"REPO_ROOT = {REPO_ROOT}")
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

cases_root = (
    cases_root_param if os.path.isabs(cases_root_param)
    else os.path.join(REPO_ROOT, cases_root_param)
)
print(f"cases_root = {cases_root}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Resolve secrets
# MAGIC The harness reads two secrets via env vars:
# MAGIC - `ANTHROPIC_API_KEY` — needed for `databricks_mcp` SUT and the judge.
# MAGIC - `DATABRICKS_MCP_BEARER` — OAuth bearer for the custom MCP gateway.
# MAGIC
# MAGIC Both are sourced from the `eval_suite` secret scope. Edit the scope name
# MAGIC at `SCOPE` below if your workspace uses a different one.

# COMMAND ----------

SCOPE = "eval_suite"

def _safe_get(scope: str, key: str) -> str | None:
    try:
        return dbutils.secrets.get(scope=scope, key=key)
    except Exception:
        return None

if "databricks_mcp" in suts_param or enable_judge:
    api_key = _safe_get(SCOPE, "anthropic_api_key")
    if api_key:
        os.environ["ANTHROPIC_API_KEY"] = api_key
    else:
        print("WARN: anthropic_api_key not in secret scope; databricks_mcp / judge will skip")

if "databricks_mcp" in suts_param:
    bearer = _safe_get(SCOPE, "databricks_mcp_bearer")
    if bearer:
        os.environ["DATABRICKS_MCP_BEARER"] = bearer
    else:
        print("WARN: databricks_mcp_bearer not in secret scope; databricks_mcp SUT will skip")

if "genie_code" in suts_param and genie_space_id:
    os.environ["EVAL_GENIE_SPACE_ID"] = genie_space_id

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Load cases

# COMMAND ----------

from tools.eval_suite.harness import load_cases  # noqa: E402

cases = load_cases(cases_root, tags_any=tags_param or None)
print(f"Loaded {len(cases)} live case(s).")
for c in cases:
    print(f"  - {c.case_id}  asof={c.asof}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Run each SUT
# MAGIC `direct_sql` is always used as the baseline for non-`direct_sql` runs so
# MAGIC every failure gets a `drift_verdict`. We run `direct_sql` first so we
# MAGIC can reuse its results; in v1 the runner runs the baseline once per
# MAGIC failing case (cheap when most cases pass).

# COMMAND ----------

from tools.eval_suite.harness import run_cases, judge_textual_inplace  # noqa: E402
from tools.eval_suite.harness.suts import get_sut  # noqa: E402

run_id = f"run-{dt.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')}"
print(f"run_id = {run_id}")

baseline_sut = None
all_results = []

for sut_name in suts_param:
    print(f"\n=== SUT: {sut_name} ===")
    try:
        if sut_name == "direct_sql":
            sut = get_sut("direct_sql", spark_session=spark)
        elif sut_name == "databricks_mcp":
            sut = get_sut("databricks_mcp")
        elif sut_name == "genie_code":
            sut = get_sut("genie_code")
        elif sut_name == "mock":
            sut = get_sut("mock")
        else:
            print(f"  unknown SUT: {sut_name}; skipping")
            continue
    except Exception as e:
        print(f"  failed to construct {sut_name}: {e}; skipping")
        continue

    # The first time we see direct_sql we keep it as the baseline for later SUTs.
    use_baseline = baseline_sut if sut_name != "direct_sql" else None
    results = run_cases(cases, sut, run_id=run_id, baseline_sut=use_baseline)
    if sut_name == "direct_sql" and baseline_sut is None:
        baseline_sut = sut

    if enable_judge:
        case_by_id = {c.case_id: c for c in cases}
        judge_textual_inplace(results, case_by_id)

    n_pass = sum(1 for r in results if r.passed)
    print(f"  {sut_name}: {n_pass}/{len(results)} passed")
    all_results.extend(results)

print(f"\nTotal rows: {len(all_results)}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Persist telemetry to Delta

# COMMAND ----------

from tools.eval_suite.harness import write_telemetry  # noqa: E402

write_telemetry(all_results, target="delta", delta_target=telemetry_table, spark=spark)
print(f"Wrote {len(all_results)} rows to {telemetry_table}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 6. Summary

# COMMAND ----------

from collections import Counter

by_sut: dict[str, list] = {}
for r in all_results:
    by_sut.setdefault(r.sut_name, []).append(r)

for sut_name, rows in by_sut.items():
    n = len(rows)
    n_pass = sum(1 for r in rows if r.passed)
    verdicts = Counter(r.drift_verdict for r in rows)
    line = f"{sut_name}: {n_pass}/{n} passed"
    if any(v not in ("PASS", "N/A") for v in verdicts):
        line += f"  drift={dict(verdicts)}"
    if enable_judge:
        n_correct = sum(1 for r in rows if r.judge_label == "correct")
        n_judged = sum(1 for r in rows if r.judge_score is not None)
        line += f"  judge={n_correct}/{n_judged} correct"
    print(line)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 7. Quality gate
# MAGIC Fail the job if any SUT dropped below the gate threshold (default 95%).
# MAGIC Tune by editing `GATE_PCT` below.

# COMMAND ----------

GATE_PCT = 95.0

failed_gates = []
for sut_name, rows in by_sut.items():
    if sut_name in ("mock",):  # mock is harness self-test; never gate it
        continue
    if not rows:
        continue
    pct = 100.0 * sum(1 for r in rows if r.passed) / len(rows)
    if pct < GATE_PCT:
        failed_gates.append((sut_name, pct))

if failed_gates:
    msg = "; ".join(f"{n}={p:.1f}%" for n, p in failed_gates)
    print(f"QUALITY GATE FAILED: {msg}")
    # Use dbutils.notebook.exit to fail the job step deterministically
    dbutils.notebook.exit(f"FAIL: {msg}")
else:
    print(f"QUALITY GATE PASSED: all SUTs >= {GATE_PCT:.0f}%")
