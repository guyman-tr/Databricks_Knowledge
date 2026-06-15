#!/usr/bin/env python3
"""
UC-Pipeline Productized Coordinator (Phase -1 → Phase 7).

Headless entrypoint for the full uc-pipeline-doc pack. Designed for parity
between Cursor agent prompts and Claude CLI loop terminals (same flags, same
stdout shape, no interactive prompts).

Schedules schema workers in two waves derived statically from the pilot DAG:

  Wave 1 (parallel, ProcessPoolExecutor max_workers=min(4, --max-parallelism)):
    de_output, bi_output, bi_dealing, etoro_kpi_prep
  Wave 2 (sequential, after Wave 1 completes):
    etoro_kpi  (depends on etoro_kpi_prep)

Each worker process executes phases 1→6 (and optionally Phase 7 adversarial
eval) for a single schema. Workers do NOT issue UC queries — those are batched
in Phase -1 (DAG build) before fan-out, preserving the 3-query budget per run.

See `specs/009-uc-pipeline-productize/contracts/cli.contract.md` for the
authoritative flag list and stdout shape.

Usage:
  python tools/uc_pipelines/run_pipeline.py --schemas de_output,bi_output,bi_dealing,etoro_kpi_prep,etoro_kpi
  python tools/uc_pipelines/run_pipeline.py --schemas etoro_kpi_prep --phases 1,2,3,4,5,6 --no-evaluate
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import multiprocessing as mp
import os
import subprocess
import sys
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools"))

OBJ_OUT_ROOT = REPO / "knowledge" / "UC_generated"
DEFAULT_PILOT_SCHEMAS = ["de_output", "bi_output", "bi_dealing", "etoro_kpi_prep", "etoro_kpi"]
# Bronze schemas where we have Tier 1 wikis available via the upstream wiki
# index. These schemas only contain bronze passthrough tables — the in-scope
# subset is determined per-object by classify_writer (BRONZE_TIER1_INHERITANCE).
BRONZE_TIER1_SCHEMAS = ["general", "bi_db", "wallet", "emoney", "trading",
                         "billing", "finance", "dealing", "compliance",
                         "experience", "pii_data", "config"]
WAVE_2_SCHEMAS = {"etoro_kpi"}
PHASE_LIST_DEFAULT = "-1,0,1,2,3,4,4.5,4.6,5,6,7"


def _ts_safe(ts: dt.datetime) -> str:
    return ts.strftime("%Y-%m-%dT%H-%M-%SZ")


def _now() -> dt.datetime:
    return dt.datetime.utcnow().replace(microsecond=0)


def _log(prefix: str, msg: str) -> None:
    sys.stdout.write(f"[{prefix}] {msg}\n")
    sys.stdout.flush()


def _emit_pack_line(msg: str) -> None:
    _log("uc-pipeline-pack", msg)


def _emit_schema_line(schema: str, msg: str) -> None:
    _log(schema, msg)


def _run_subprocess(cmd: list[str], cwd: Path = REPO) -> tuple[int, str, str]:
    proc = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True,
                          encoding="utf-8", errors="replace")
    return (proc.returncode, proc.stdout, proc.stderr)


def _wave_assignment(schemas: list[str]) -> tuple[list[str], list[str]]:
    """Returns (wave1_schemas, wave2_schemas) preserving CLI order."""
    wave1 = [s for s in schemas if s not in WAVE_2_SCHEMAS]
    wave2 = [s for s in schemas if s in WAVE_2_SCHEMAS]
    return wave1, wave2


def phase_minus1_build_dag(catalog: str, schemas: list[str], force: bool,
                            audit_dir: Path, dry_run: bool = False) -> tuple[int, dict]:
    """Issues the 3 UC queries; writes _dag.json. Returns (rc, dag_summary)."""
    dag_path = OBJ_OUT_ROOT / "_dag.json"
    if dag_path.exists() and not force:
        try:
            existing = json.loads(dag_path.read_text(encoding="utf-8"))
            built_at = existing.get("built_at", "?")
            _emit_pack_line(f"Phase -1: re-using existing DAG at {dag_path.relative_to(REPO)} (built {built_at}; pass --force to rebuild)")
            nodes = existing.get("nodes", [])
            return (0, {
                "total_nodes": len(nodes),
                "in_scope_nodes": sum(1 for n in nodes if n.get("in_pilot_scope")),
                "out_scope_nodes": sum(1 for n in nodes if not n.get("in_pilot_scope")),
                "edges": len(existing.get("edges", [])),
                "uc_query_budget": existing.get("uc_query_budget", {}),
                "information_schema_queries": existing.get("uc_query_budget", {}).get("information_schema_queries", 1),
                "phases_run": PHASE_LIST_DEFAULT,
            })
        except Exception as e:
            _emit_pack_line(f"Phase -1: existing DAG unparseable ({e}) — rebuilding")

    if dry_run:
        _emit_pack_line(f"Phase -1 DRY-RUN: would issue 3 UC queries for {','.join(schemas)} (catalog={catalog}); not executing")
        return (0, {"dry_run": True, "schemas": schemas, "catalog": catalog,
                     "uc_query_budget": {"column_lineage_queries": 1,
                                           "table_lineage_queries": 1,
                                           "information_schema_queries": 1},
                     "phases_run": PHASE_LIST_DEFAULT})

    _emit_pack_line(f"Phase -1: building DAG for {','.join(schemas)} (3 UC queries)...")
    cmd = [sys.executable, str(REPO / "tools" / "uc_pipelines" / "build_dag.py"),
           "--schemas", ",".join(schemas), "--catalog", catalog]
    rc, out, err = _run_subprocess(cmd)
    for ln in (out + err).splitlines():
        if ln.strip():
            _emit_pack_line(f"  {ln}")
    if rc != 0:
        return (rc, {})

    try:
        d = json.loads(dag_path.read_text(encoding="utf-8"))
        nodes = d.get("nodes", [])
        return (0, {
            "total_nodes": len(nodes),
            "in_scope_nodes": sum(1 for n in nodes if n.get("in_pilot_scope")),
            "out_scope_nodes": sum(1 for n in nodes if not n.get("in_pilot_scope")),
            "edges": len(d.get("edges", [])),
            "uc_query_budget": d.get("uc_query_budget", {}),
            "information_schema_queries": d.get("uc_query_budget", {}).get("information_schema_queries", 1),
            "phases_run": PHASE_LIST_DEFAULT,
        })
    except Exception as e:
        return (1, {"error": str(e)})


def phase_0_build_wiki_index(force: bool) -> int:
    index_path = OBJ_OUT_ROOT / "_upstream_wiki_index.json"
    if index_path.exists() and not force:
        try:
            d = json.loads(index_path.read_text(encoding="utf-8"))
            _emit_pack_line(f"Phase 0: re-using upstream wiki index ({d.get('stats', {}).get('total', '?')} wikis indexed; pass --force to rebuild)")
            return 0
        except Exception:
            pass
    cmd = [sys.executable, str(REPO / "tools" / "uc_pipelines" / "build_upstream_wiki_index.py")]
    rc, out, err = _run_subprocess(cmd)
    for ln in (out + err).splitlines():
        if "indexed" in ln or "stats=" in ln:
            _emit_pack_line(f"  {ln.strip()}")
    return rc


def _phase_cmd(phase, schema: str, catalog: str) -> list[str] | None:
    base = [sys.executable]
    # Accept both ints and floats (4.5, 4.6 are sub-phases added in the
    # Grounded Synthesis Contract port from DWH Phase 6 + Phase 9).
    if phase == 1:
        return base + [str(REPO / "tools" / "uc_pipelines" / "discover_schema.py"),
                       "--schema", schema, "--catalog", catalog, "--phase", "both",
                       "--no-row-counts", "--no-samples"]
    if phase == 2:
        return base + [str(REPO / "tools" / "uc_pipelines" / "fetch_writer_source.py"),
                       "--schema", schema]
    if phase == 3:
        return base + [str(REPO / "tools" / "uc_pipelines" / "cache_upstream_wikis.py"),
                       "--schema", schema, "--catalog", catalog]
    if phase == 4:
        return base + [str(REPO / "tools" / "uc_pipelines" / "build_lineage.py"),
                       "--schema", schema]
    if phase == 4.5:
        return base + [str(REPO / "tools" / "uc_pipelines" / "discover_concepts.py"),
                       "--schema", schema]
    if phase == 4.6:
        return base + [str(REPO / "tools" / "uc_pipelines" / "extract_formulas.py"),
                       "--schema", schema]
    if phase == 5:
        return base + [str(REPO / "tools" / "uc_pipelines" / "generate_wiki.py"),
                       "--schema", schema]
    if phase == 6:
        return base + [str(REPO / "tools" / "uc_pipelines" / "validate_pipeline_wiki.py"),
                       "--schema", schema]
    return None


def _read_schema_card_in_scope(schema: str) -> list[str]:
    """Read the schema's _schema_card.md to get the authoritative in-scope object list."""
    card = OBJ_OUT_ROOT / schema / "_schema_card.md"
    if not card.exists():
        return []
    try:
        import re
        import yaml  # type: ignore
        text = card.read_text(encoding="utf-8")
        m = re.match(r"^---\n(.+?)\n---\n", text, re.DOTALL)
        if not m:
            return []
        fm = yaml.safe_load(m.group(1)) or {}
        return [o["name"] for o in (fm.get("objects") or []) if o.get("in_scope")]
    except Exception:
        return []


def _enumerate_schema_objects(schema: str) -> list[dict]:
    """Returns one row per in-scope object with its current pipeline status.
    Reads from _schema_card.md (authoritative in-scope list) + Tables/ + Views/.
    """
    schema_root = OBJ_OUT_ROOT / schema
    if not schema_root.is_dir():
        return []
    in_scope_names = _read_schema_card_in_scope(schema)
    if not in_scope_names:
        return []

    out: list[dict] = []
    for name in in_scope_names:
        md_path: Path | None = None
        status_path: Path | None = None
        for folder in ("Tables", "Views"):
            cand = schema_root / folder / f"{name}.md"
            if cand.exists():
                md_path = cand
                sp = schema_root / folder / f"{name}.status.json"
                if sp.exists():
                    status_path = sp
                break
        if status_path:
            try:
                sp_data = json.loads(status_path.read_text(encoding="utf-8"))
                out.append({
                    "name": name,
                    "in_pilot_scope": True,
                    "status": sp_data.get("status", "Generated"),
                    "status_detail": sp_data.get("status_detail"),
                    "blocked_on_upstream": sp_data.get("blocked_on_upstream"),
                    "routing_attempts": sp_data.get("routing_attempts"),
                    "n_unverified": int(sp_data.get("n_unverified") or 0),
                    "tier_breakdown": sp_data.get("tier_counts") or {},
                })
                continue
            except Exception:
                pass
        if md_path:
            tier_breakdown, n_unverified = _extract_tiers_from_md(md_path)
            alter = md_path.with_suffix(".alter.sql").exists()
            out.append({
                "name": name,
                "in_pilot_scope": True,
                "status": "Generated" if alter else "Generated (no .alter.sql yet)",
                "n_unverified": n_unverified,
                "tier_breakdown": tier_breakdown,
            })
        else:
            out.append({
                "name": name,
                "in_pilot_scope": True,
                "status": "Pending",
                "n_unverified": 0,
            })
    return out


def _extract_tiers_from_md(md_path: Path) -> tuple[dict, int]:
    try:
        text = md_path.read_text(encoding="utf-8")
    except Exception:
        return ({}, 0)
    import re
    m = re.match(r"^---\n(.+?)\n---\n", text, re.DOTALL)
    if not m:
        return ({}, 0)
    try:
        import yaml  # type: ignore
        fm = yaml.safe_load(m.group(1)) or {}
    except Exception:
        return ({}, 0)
    tb = fm.get("tier_breakdown") or {}
    return (tb, int(tb.get("unverified_columns") or 0))


def _phase7_eval_single(schema: str, obj_name: str, attempt: int) -> tuple[int, dict | None]:
    """Run adversarial evaluator on a single object. Returns (rc, record_dict_or_None)."""
    eval_py = REPO / "tools" / "uc_pipelines" / "adversarial_evaluate.py"
    if not eval_py.exists():
        return (0, None)
    cmd = [sys.executable, str(eval_py),
           "--schema", schema, "--object", obj_name,
           "--attempt", str(attempt), "--quiet"]
    rc, _, _ = _run_subprocess(cmd)
    rec_path = OBJ_OUT_ROOT / schema / "_discovery" / "evaluations" / f"{obj_name}.json"
    if rec_path.exists():
        try:
            return (rc, json.loads(rec_path.read_text(encoding="utf-8")))
        except Exception:
            return (rc, None)
    return (rc, None)


def _phase7_regenerate_single(schema: str, obj_name: str) -> int:
    """Re-run Phase 5 (generate_wiki) + Phase 6 (validator) for one object."""
    gen = REPO / "tools" / "uc_pipelines" / "generate_wiki.py"
    val = REPO / "tools" / "uc_pipelines" / "validate_pipeline_wiki.py"
    rc1, _, _ = _run_subprocess([sys.executable, str(gen), "--schema", schema,
                                  "--object", obj_name, "--force"])
    if rc1 != 0:
        return rc1
    md_path = None
    for folder in ("Tables", "Views"):
        p = OBJ_OUT_ROOT / schema / folder / f"{obj_name}.md"
        if p.exists():
            md_path = p
            break
    if md_path is None:
        return 1
    rc2, _, _ = _run_subprocess([sys.executable, str(val), "--wiki", str(md_path),
                                  "--assert-no-inference"])
    return rc2


def _worker_run_phase7(schema: str, in_scope_names: list[str],
                         sample: int | None) -> dict:
    """Phase 7 per-schema. Iterates objects with generated wikis, evaluates,
    retries once on FAIL. Returns a phase-record dict and updates evaluator
    sidecar files. The aggregated per-object verdicts are read later by the
    audit summarizer.
    """
    eval_targets: list[tuple[str, str, Path]] = []
    for name in in_scope_names:
        for folder in ("Tables", "Views"):
            cand = OBJ_OUT_ROOT / schema / folder / f"{name}.md"
            if cand.exists():
                eval_targets.append((name, folder, cand))
                break

    if sample is not None and sample > 0 and sample < len(eval_targets):
        import random as _rnd
        _rnd.seed(0xBADBEEF)
        eval_targets = _rnd.sample(eval_targets, sample)

    started = time.time()
    first_pass = 0
    regen_pass = 0
    final_fail = 0
    dim_totals: dict[str, float] = {}
    per_object: dict[str, dict] = {}
    n_eval = 0

    for obj_name, _folder, _md in eval_targets:
        n_eval += 1
        _, rec1 = _phase7_eval_single(schema, obj_name, attempt=1)
        if not rec1:
            per_object[obj_name] = {"verdict": "UNKNOWN", "attempt": 1,
                                     "reason": "evaluator produced no record"}
            continue

        if rec1["verdict"] == "PASS":
            first_pass += 1
            per_object[obj_name] = {"verdict": "PASS", "attempt": 1,
                                     "weighted_score": rec1["weighted_score"]}
            for k, v in rec1["scores"].items():
                dim_totals[k] = dim_totals.get(k, 0.0) + float(v)
            continue

        rc_regen = _phase7_regenerate_single(schema, obj_name)
        if rc_regen != 0:
            final_fail += 1
            per_object[obj_name] = {
                "verdict": "FAIL", "attempt": 1,
                "weighted_score": rec1["weighted_score"],
                "regeneration_skipped": True,
                "regen_rc": rc_regen,
                "feedback": rec1.get("regeneration_feedback"),
            }
            for k, v in rec1["scores"].items():
                dim_totals[k] = dim_totals.get(k, 0.0) + float(v)
            continue

        _, rec2 = _phase7_eval_single(schema, obj_name, attempt=2)
        if rec2 and rec2["verdict"] == "PASS":
            regen_pass += 1
            per_object[obj_name] = {"verdict": "PASS", "attempt": 2,
                                     "weighted_score": rec2["weighted_score"]}
            for k, v in rec2["scores"].items():
                dim_totals[k] = dim_totals.get(k, 0.0) + float(v)
        else:
            final_fail += 1
            ws = (rec2 or rec1)["weighted_score"]
            per_object[obj_name] = {
                "verdict": "FAIL", "attempt": 2,
                "weighted_score": ws,
                "feedback": (rec2 or rec1).get("regeneration_feedback"),
            }
            for k, v in (rec2 or rec1)["scores"].items():
                dim_totals[k] = dim_totals.get(k, 0.0) + float(v)

    wall = time.time() - started
    dim_avg = {k: round(v / max(n_eval, 1), 2) for k, v in dim_totals.items()}
    return {
        "wall_seconds": wall,
        "n_evaluated": n_eval,
        "first_pass_pass": first_pass,
        "regen_pass": regen_pass,
        "final_fail": final_fail,
        "dimension_averages": dim_avg,
        "per_object": per_object,
    }


def _worker_run_schema(args_dict: dict) -> dict:
    """Runs phases 1→6 (+ optional 7) for a single schema. Returns a per-schema audit dict."""
    schema = args_dict["schema"]
    catalog = args_dict["catalog"]
    phases = args_dict["phases"]
    force = args_dict["force"]
    evaluate = bool(args_dict.get("evaluate", True))
    evaluate_sample = args_dict.get("evaluate_sample")
    audit_dir = Path(args_dict["audit_dir"])
    audit_dir.mkdir(parents=True, exist_ok=True)

    started = _now()
    phase_records: dict[str, dict] = {}
    failures: list[str] = []
    for ph in phases:
        if ph in (-1, 0, 7):
            continue
        cmd = _phase_cmd(ph, schema, catalog)
        if cmd is None:
            failures.append(f"phase {ph}: no command mapping")
            continue
        if force:
            cmd.append("--force")
        t0 = time.time()
        rc, out, err = _run_subprocess(cmd)
        wall = time.time() - t0
        phase_records[str(ph)] = {
            "wall_seconds": wall,
            "rc": rc,
            "rows": 0,
            "stdout_tail": "\n".join(out.splitlines()[-3:]),
            "stderr_tail": "\n".join(err.splitlines()[-5:]),
        }
        if rc != 0:
            failures.append(f"phase {ph} rc={rc}: {err.splitlines()[-1] if err.splitlines() else 'no stderr'}")
            # Phase 6 (validator) is a quality report, not a pipeline halt — keep going.
            # Phases 1-5 are data fetching/generation; their failure prevents downstream work.
            if ph != 6:
                break

    if 7 in phases and evaluate:
        in_scope = _read_schema_card_in_scope(schema)
        phase7_record = _worker_run_phase7(schema, in_scope, evaluate_sample)
        phase_records["7"] = {
            "wall_seconds": phase7_record["wall_seconds"],
            "rc": 0,
            "rows": phase7_record["n_evaluated"],
            "first_pass_pass": phase7_record["first_pass_pass"],
            "regen_pass": phase7_record["regen_pass"],
            "final_fail": phase7_record["final_fail"],
            "dimension_averages": phase7_record["dimension_averages"],
            "per_object": phase7_record["per_object"],
        }

    objects = _enumerate_schema_objects(schema)

    if "7" in phase_records:
        eval_per = phase_records["7"].get("per_object", {})
        for obj in objects:
            ev = eval_per.get(obj["name"])
            if not ev:
                continue
            obj["evaluator_verdict"] = ev["verdict"]
            obj["evaluator_attempt"] = ev["attempt"]
            obj["evaluator_score"] = ev.get("weighted_score")
            if ev["verdict"] == "FAIL" and obj.get("status") == "Generated":
                obj["status"] = "Failed (eval)"
                obj["status_detail"] = (ev.get("feedback") or "")[:240]

    for f in failures:
        for obj in objects:
            if obj["status"] == "Pending":
                obj["status"] = f"Failed (phase fail: {f.split(':')[0]})"

    finished = _now()
    result = {
        "schema": schema,
        "catalog": catalog,
        "started_at": started.isoformat() + "Z",
        "finished_at": finished.isoformat() + "Z",
        "wall_seconds": (finished - started).total_seconds(),
        "phases": phase_records,
        "failures": failures,
        "objects": objects,
    }

    out_json = audit_dir / f"{schema}.json"
    out_json.write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
    return result


def _validate_pilot_scope(schemas: list[str]) -> list[str]:
    valid = set(DEFAULT_PILOT_SCHEMAS) | set(BRONZE_TIER1_SCHEMAS)
    bad = [s for s in schemas if s not in valid]
    return bad


def _validate_phases(phases_str: str) -> tuple[list, str | None]:
    """Phases may be ints (-1..7) or the floats 4.5 / 4.6 (Phases added in
    the Grounded Synthesis Contract port — concept discovery and formula
    extraction)."""
    try:
        raw = [s.strip() for s in phases_str.split(",") if s.strip()]
        phases: list = []
        for s in raw:
            if "." in s:
                phases.append(float(s))
            else:
                phases.append(int(s))
    except ValueError as e:
        return ([], f"malformed --phases {phases_str!r}: {e}")
    valid = {-1, 0, 1, 2, 3, 4, 4.5, 4.6, 5, 6, 7}
    bad = [p for p in phases if p not in valid]
    if bad:
        return ([], f"unknown phase(s): {bad}; valid: {sorted(valid, key=float)}")
    return (phases, None)


def main() -> int:
    ap = argparse.ArgumentParser(description="UC-Pipeline Productized Coordinator")
    ap.add_argument("--schemas", required=True,
                    help="Comma-separated pilot schemas. "
                         f"Valid: {','.join(DEFAULT_PILOT_SCHEMAS)}")
    ap.add_argument("--catalog", default="main")
    ap.add_argument("--phases", default=PHASE_LIST_DEFAULT,
                    help=f"Comma-separated phase numbers. Default: {PHASE_LIST_DEFAULT}")
    ap.add_argument("--force", action="store_true",
                    help="Re-run every phase regardless of existing outputs")
    ap.add_argument("--dry-run", action="store_true",
                    help="Run Phase -1 only; print DAG summary and exit")
    ap.add_argument("--max-objects-per-schema", type=int, default=None,
                    help="(unused stub for compat — pilot runs unbounded)")
    ap.add_argument("--max-parallelism", type=int, default=4,
                    help="Number of concurrent worker processes for Wave 1")
    ap.add_argument("--evaluate", dest="evaluate", action="store_true", default=True,
                    help="(default ON) run adversarial evaluator after Phase 6")
    ap.add_argument("--no-evaluate", dest="evaluate", action="store_false",
                    help="Skip Phase 7 adversarial evaluation entirely")
    ap.add_argument("--evaluate-sample", type=int, default=None,
                    help="Sample N random objects per schema for adversarial eval")
    ap.add_argument("--audit-dir", default=None,
                    help="Override per-run audit dir. Default uses ISO8601 UTC stamp.")
    ap.add_argument("--verbose", action="store_true",
                    help="Per-object phase output to stdout")
    args = ap.parse_args()

    schemas = [s.strip() for s in args.schemas.split(",") if s.strip()]
    bad = _validate_pilot_scope(schemas)
    if bad:
        print(f"ERROR: non-pilot schema(s) in --schemas: {bad}; valid: {DEFAULT_PILOT_SCHEMAS}",
              file=sys.stderr)
        return 4
    phases, perr = _validate_phases(args.phases)
    if perr:
        print(f"ERROR: {perr}", file=sys.stderr)
        return 4
    if args.max_parallelism < 0:
        print(f"ERROR: --max-parallelism must be >= 0", file=sys.stderr)
        return 4

    started = _now()
    audit_dir = Path(args.audit_dir) if args.audit_dir else (
        OBJ_OUT_ROOT / "_runs" / _ts_safe(started))
    audit_dir.mkdir(parents=True, exist_ok=True)

    cli_args_str = " ".join(sys.argv[1:])
    _emit_pack_line(f"Run {started.isoformat()}Z starting "
                    f"(max_parallelism={args.max_parallelism}, "
                    f"evaluate={'ON' if args.evaluate else 'OFF'})")

    dag_summary: dict = {}
    errors: list[str] = []

    if -1 in phases:
        rc, dag_summary = phase_minus1_build_dag(args.catalog, schemas, args.force,
                                                   audit_dir, dry_run=args.dry_run)
        if rc != 0:
            _emit_pack_line(f"Phase -1 ABORT (rc={rc})")
            return 2
        _emit_pack_line(f"Phase -1: DAG built — nodes={dag_summary.get('total_nodes')}, "
                        f"in-scope={dag_summary.get('in_scope_nodes')}, "
                        f"out-of-scope={dag_summary.get('out_scope_nodes')}, "
                        f"edges={dag_summary.get('edges')}, "
                        f"budget={dag_summary.get('uc_query_budget')}")

    if args.dry_run:
        _emit_pack_line(f"DRY-RUN: exiting after Phase -1")
        return 0

    if 0 in phases:
        rc = phase_0_build_wiki_index(args.force)
        if rc != 0:
            _emit_pack_line(f"Phase 0 wiki index FAILED (rc={rc}); continuing — per-schema Phase 3 will surface gaps")

    wave1, wave2 = _wave_assignment(schemas)

    worker_phases = [p for p in phases if p != -1 and p != 0]
    worker_results: dict[str, dict] = {}

    worker_common = {
        "catalog": args.catalog, "phases": worker_phases,
        "force": args.force, "audit_dir": str(audit_dir),
        "evaluate": args.evaluate, "evaluate_sample": args.evaluate_sample,
    }

    if wave1:
        wave1_max = max(1, min(args.max_parallelism, len(wave1)))
        if wave1_max <= 1:
            _emit_pack_line(f"Wave 1 launching sequentially ({len(wave1)} schemas, max_parallelism={wave1_max}):")
            for sch in wave1:
                _emit_schema_line(sch, "starting...")
                r = _worker_run_schema({"schema": sch, **worker_common})
                worker_results[sch] = r
                _emit_schema_line(sch, f"finished in {r['wall_seconds']:.1f}s "
                                       f"({len(r['objects'])} objects, "
                                       f"{len(r['failures'])} phase failures)")
        else:
            _emit_pack_line(f"Wave 1 launching in parallel ({len(wave1)} schemas, max_parallelism={wave1_max}):")
            with ProcessPoolExecutor(max_workers=wave1_max,
                                       mp_context=mp.get_context("spawn")) as pool:
                futs = {pool.submit(_worker_run_schema, {"schema": sch, **worker_common}): sch for sch in wave1}
                for fut in as_completed(futs):
                    sch = futs[fut]
                    try:
                        r = fut.result()
                        worker_results[sch] = r
                        _emit_schema_line(sch, f"finished in {r['wall_seconds']:.1f}s "
                                               f"({len(r['objects'])} objects, "
                                               f"{len(r['failures'])} phase failures)")
                    except Exception as e:
                        errors.append(f"Wave 1 worker {sch} crashed: {e}")
                        worker_results[sch] = {"schema": sch, "error": str(e),
                                                "objects": [], "phases": {}, "failures": [str(e)]}
                        _emit_schema_line(sch, f"CRASHED: {e}")

    if wave2:
        _emit_pack_line(f"Wave 2 launching ({len(wave2)} schemas, sequential):")
        for sch in wave2:
            _emit_schema_line(sch, "starting (depends on Wave 1 outputs)...")
            r = _worker_run_schema({"schema": sch, **worker_common})
            worker_results[sch] = r
            _emit_schema_line(sch, f"finished in {r['wall_seconds']:.1f}s "
                                   f"({len(r['objects'])} objects, "
                                   f"{len(r['failures'])} phase failures)")

    finished = _now()
    wall_seconds = (finished - started).total_seconds()
    _emit_pack_line(f"All waves complete in {wall_seconds:.1f}s — writing audit summary...")

    dag_summary_path = audit_dir / "dag_summary.json"
    dag_summary_path.write_text(json.dumps(dag_summary, indent=2), encoding="utf-8")

    audit_cmd = [sys.executable, str(REPO / "tools" / "uc_pipelines" / "write_audit_summary.py"),
                 "--audit-dir", str(audit_dir),
                 "--dag-summary-json", str(dag_summary_path),
                 "--cli-args", cli_args_str,
                 "--wall-clock-seconds", f"{wall_seconds:.1f}"]
    for sch, _ in worker_results.items():
        audit_cmd.extend(["--worker-result", f"{sch}:{(audit_dir / (sch + '.json')).as_posix()}"])
    for e in errors:
        audit_cmd.extend(["--error", e])
    rc, out, err = _run_subprocess(audit_cmd)
    for ln in (out + err).splitlines():
        if ln.strip():
            _emit_pack_line(f"  {ln.strip()}")

    has_failures = any(r.get("failures") for r in worker_results.values()) or bool(errors)
    summary_path = audit_dir / "summary.md"
    _emit_pack_line(f"Run complete. Summary: {summary_path.relative_to(REPO) if summary_path.is_absolute() else summary_path}")
    schema_rollup = []
    for sch in schemas:
        r = worker_results.get(sch, {})
        objs = r.get("objects", [])
        generated = sum(1 for o in objs if o.get("status") == "Generated")
        total = len(objs)
        schema_rollup.append(f"{sch} {generated}/{total}")
    _emit_pack_line("Per-schema: " + ", ".join(schema_rollup))
    _emit_pack_line(f"EXIT {1 if has_failures else 0}")
    return 1 if has_failures else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr, flush=True)
        sys.exit(1)
