"""Smoke test for DirectMcpSUT: end-to-end one question -> one number.

Run from repo root:
    python tools/eval_suite/loop_authoring/_diag_direct_mcp_sut.py 2>&1 | tee audits/eval_suite/direct_mcp_sut_smoke.txt

Hits the live `databricks-stg` MCP gateway and the Databricks Sonnet 4-6
endpoint, so:
  - Requires a healthy `~/.databrickscfg` (profile=guyman) — re-run
    `databricks auth login --profile guyman` if expired.
  - Costs a tiny bit of LLM compute and a SQL warehouse spin-up.

Expected outcome: numeric_answer is in the 3.5M to 4.2M range
(funded customer count is roughly 3.94M as of 2026-06-10) with three MCP
calls visible in raw.mcp_calls: skills_find_skills, skills_get_skill,
databricks_ops_execute_sql.
"""
from __future__ import annotations

import json
import os
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

from tools.eval_suite.harness.schema import (
    CaseV1, GroundTruth, UcEquivalent, Parity, SkillCoverage, ScoringConfig,
)
from tools.eval_suite.harness.suts import get_sut


def _stub_case() -> CaseV1:
    return CaseV1(
        case_id="smoke_funded",
        status="live",
        source_kind="manual",
        asof="2026-06-10",
        natural_language_question="How many funded customers did eToro have on 2026-06-10?",
        ground_truth=GroundTruth(
            source_db="synapse_prod", routine="manual", sql="-- n/a",
            value=3940000.0, pinned_at="2026-06-14T00:00:00Z",
        ),
        uc_equivalent=UcEquivalent(
            status="draft", sql="-- n/a", value=3940000.0,
            pinned_at="2026-06-14T00:00:00Z",
        ),
        parity=Parity(diff_abs=0.0, diff_pct=0.0, threshold_pct=0.05, passed=True),
        skill_coverage=SkillCoverage(),
        scoring=ScoringConfig(),
    )


def main() -> int:
    print("[1/3] Constructing DirectMcpSUT (spawns mcp-remote, runs initialize)…")
    try:
        sut = get_sut(
            "direct_mcp",
            mcp_server_id="databricks-stg",
            llm_backend="databricks",
            # default model is databricks-claude-sonnet-4-6
        )
    except Exception as e:
        print(f"  FAIL: {type(e).__name__}: {e}")
        return 1
    print("  OK")

    case = _stub_case()
    print(f"\n[2/3] Asking: {case.natural_language_question!r}")
    try:
        resp = sut.ask(case.natural_language_question, case)
    finally:
        sut.close()

    print("\n[3/3] Result:")
    print(f"  numeric_answer = {resp.numeric_answer!r}")
    print(f"  error          = {resp.error!r}")
    print(f"  elapsed_ms     = {resp.elapsed_ms}")
    print(f"  text_answer    = {resp.text_answer!r}")
    print()
    print("  --- sql_used (LLM-emitted) ---")
    print((resp.sql_used or "(none)").rstrip())
    print("  --- /sql_used ---")
    print()
    print("  --- raw.skill_top_id / score / ground_id ---")
    print(f"    top_id     = {resp.raw.get('skill_top_id')}")
    print(f"    top_score  = {resp.raw.get('skill_top_score')}")
    print(f"    ground_id  = {resp.raw.get('skill_ground_id')}")
    print(f"    body_chars = {resp.raw.get('skill_body_chars')}")
    print()
    print("  --- raw.mcp_calls ---")
    for i, c in enumerate(resp.raw.get("mcp_calls") or [], start=1):
        print(f"    [{i}] {c['method']:<32}  {c['elapsed_ms']:>5} ms  err={c.get('error')!r}")
        excerpt = (c.get("result_excerpt") or "")[:200]
        print(f"        result excerpt: {excerpt}")
    print()
    print("  --- raw.llm ---")
    print(f"    {json.dumps(resp.raw.get('llm') or {}, default=str, indent=2)}")
    print()
    print(f"  --- raw.sql_result_cols / first 5 rows ---")
    print(f"    cols      = {resp.raw.get('sql_result_cols')}")
    print(f"    row_count = {resp.raw.get('sql_result_row_count')}")
    for i, row in enumerate(resp.raw.get("sql_result_rows") or [], start=1):
        print(f"    [{i}] {row}")

    if resp.numeric_answer is None:
        print("\nFAIL: no numeric answer extracted.")
        return 2
    if not (1_000_000 <= resp.numeric_answer <= 10_000_000):
        print(f"\nWARN: numeric answer {resp.numeric_answer} outside the "
              f"expected 1M..10M sanity band for funded count.")
    print("\nSmoke green.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
