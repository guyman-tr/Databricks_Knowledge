#!/usr/bin/env python3
"""
Per-run audit summary writer (UC-Pipeline pack).

Called by `run_pipeline.py` at the END of every run. Stitches per-schema
worker JSON results (one per Wave 1/2 worker) into a single human-readable
Markdown summary at `knowledge/UC_generated/_runs/{ts}/summary.md`.

Output structure follows `data-model.md` "Entity: Per-run audit summary":
  1. Header
  2. Frontmatter-style key-value block
  3. Per-schema rollup table
  4. Blocked-objects table grouped by upstream FQN
  5. Phase time breakdown table
  6. Errors section

Usage:
  python tools/uc_pipelines/write_audit_summary.py \
      --audit-dir knowledge/UC_generated/_runs/2026-05-17T19-00-00Z \
      --worker-result de_output:_runs/.../de_output.json \
      --worker-result etoro_kpi:_runs/.../etoro_kpi.json
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OBJ_OUT_ROOT = REPO / "knowledge" / "UC_generated"


def _now_iso_z() -> str:
    return dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"


def _load_worker_result(p: Path) -> dict:
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception as e:
        return {"schema": p.stem, "error": f"failed to parse worker result: {e}",
                "objects": [], "phases": {}}


def _format_duration(seconds: float | None) -> str:
    if seconds is None:
        return "—"
    if seconds < 60:
        return f"{seconds:.1f}s"
    m, s = divmod(int(seconds), 60)
    if m < 60:
        return f"{m}m{s:02d}s"
    h, m = divmod(m, 60)
    return f"{h}h{m:02d}m{s:02d}s"


def build_summary(*, audit_dir: Path, worker_results: dict[str, dict],
                  dag_summary: dict, cli_args_str: str,
                  wall_clock_seconds: float | None,
                  errors: list[str] | None = None) -> str:
    errors = errors or []
    run_ts = audit_dir.name
    schemas = sorted(worker_results.keys())

    rollup_rows: list[dict] = []
    total = defaultdict(int)
    for sch in schemas:
        r = worker_results[sch]
        objs = r.get("objects", [])
        in_scope = sum(1 for o in objs if o.get("in_pilot_scope", True))
        out_scope = len(objs) - in_scope
        generated = sum(1 for o in objs if o.get("status") == "Generated")
        deployed = sum(1 for o in objs if (o.get("status") or "").startswith("Deployed"))
        blocked = sum(1 for o in objs if (o.get("status") or "").startswith("Blocked"))
        failed = sum(1 for o in objs if (o.get("status") or "").startswith("Failed")
                     or (o.get("status") or "") == "Failed")
        unverified_cols = sum(o.get("n_unverified", 0) or 0 for o in objs)
        rollup_rows.append({
            "schema": sch,
            "in_scope": in_scope,
            "out_scope": out_scope,
            "generated": generated,
            "deployed": deployed,
            "blocked": blocked,
            "failed": failed,
            "unverified_cols": unverified_cols,
        })
        total["in_scope"] += in_scope
        total["out_scope"] += out_scope
        total["generated"] += generated
        total["deployed"] += deployed
        total["blocked"] += blocked
        total["failed"] += failed
        total["unverified_cols"] += unverified_cols

    blocked_by_upstream: dict[str, list[dict]] = defaultdict(list)
    for sch in schemas:
        for o in worker_results[sch].get("objects", []):
            st = o.get("status") or ""
            if st.startswith("Blocked"):
                up = o.get("blocked_on_upstream") or "(unknown)"
                blocked_by_upstream[up].append({
                    "schema": sch,
                    "object": o.get("name"),
                    "attempts": o.get("routing_attempts") or "—",
                })

    phase_times: dict[str, dict[str, float | int]] = defaultdict(lambda: {"wall_seconds": 0.0, "rows": 0})
    for sch in schemas:
        for ph_id, ph_data in (worker_results[sch].get("phases") or {}).items():
            phase_times[ph_id]["wall_seconds"] += float(ph_data.get("wall_seconds") or 0.0)
            phase_times[ph_id]["rows"] += int(ph_data.get("rows") or 0)

    lines: list[str] = []
    lines.append(f"# Run Summary — {run_ts}")
    lines.append("")
    lines.append(f"**Schemas**: {', '.join(schemas)}")
    lines.append(f"**Wall-clock**: {_format_duration(wall_clock_seconds)}")
    lines.append(f"**UC queries**: column_lineage=1 table_lineage=1 information_schema={dag_summary.get('information_schema_queries', '?')}")
    lines.append(f"**Phases run**: {dag_summary.get('phases_run', '-1,0,1,2,3,4,5,6,7')}")
    lines.append(f"**CLI args**: `{cli_args_str}`")
    lines.append(f"**DAG nodes**: {dag_summary.get('total_nodes', '—')} ({dag_summary.get('in_scope_nodes', '—')} in-scope)")
    lines.append("")

    lines.append("## Per-schema rollup")
    lines.append("")
    lines.append("| Schema | In-scope | Out-of-scope | Generated | Deployed | Blocked | Failed | Unverified cols |")
    lines.append("|--------|----------|--------------|-----------|----------|---------|--------|-----------------|")
    for r in rollup_rows:
        lines.append(f"| `{r['schema']}` | {r['in_scope']} | {r['out_scope']} | "
                     f"{r['generated']} | {r['deployed']} | {r['blocked']} | "
                     f"{r['failed']} | {r['unverified_cols']} |")
    lines.append(f"| **TOTAL** | **{total['in_scope']}** | **{total['out_scope']}** | "
                 f"**{total['generated']}** | **{total['deployed']}** | "
                 f"**{total['blocked']}** | **{total['failed']}** | "
                 f"**{total['unverified_cols']}** |")
    lines.append("")

    lines.append("## Blocked objects (grouped by upstream)")
    lines.append("")
    if not blocked_by_upstream:
        lines.append("_None — all in-scope objects either generated, deployed, or out-of-scope._")
    else:
        lines.append("| Upstream FQN | Blocking N objects | Affected objects | Routing-rule attempts |")
        lines.append("|--------------|-------------------|------------------|----------------------|")
        for up, items in sorted(blocked_by_upstream.items(), key=lambda kv: -len(kv[1])):
            objs_str = ", ".join(f"`{i['schema']}.{i['object']}`" for i in items[:5])
            if len(items) > 5:
                objs_str += f" (+{len(items) - 5} more)"
            attempts = "; ".join(sorted(set(i["attempts"] for i in items if i["attempts"])))
            lines.append(f"| `{up}` | {len(items)} | {objs_str} | {attempts or '—'} |")
    lines.append("")

    lines.append("## Phase time breakdown")
    lines.append("")
    lines.append("| Phase | Wall-clock (sum across schemas) | Rows processed |")
    lines.append("|-------|-------------------------------|----------------|")
    for ph_id in sorted(phase_times.keys(), key=lambda x: (int(x) if str(x).lstrip("-").isdigit() else 99)):
        pt = phase_times[ph_id]
        lines.append(f"| {ph_id} | {_format_duration(pt['wall_seconds'])} | {pt['rows']} |")
    lines.append("")

    lines.append("## Adversarial evaluator (Phase 7)")
    lines.append("")
    eval_present = any(
        "7" in (worker_results[s].get("phases") or {}) for s in schemas
    )
    if not eval_present:
        lines.append("_Phase 7 not run for this batch (use `--evaluate` to enable)._")
        lines.append("")
    else:
        lines.append("| Schema | Evaluated | First-pass PASS | Regen PASS | Final FAIL | Avg weighted | InhFid | NarrAcc | NullProv | Compl | Shape | Coher |")
        lines.append("|--------|-----------|----------------|------------|------------|--------------|--------|---------|----------|-------|-------|-------|")
        t_eval = t_fp = t_rp = t_ff = 0
        sum_score = 0.0
        sum_score_count = 0
        agg_dim: dict[str, list[float]] = defaultdict(list)
        final_fail_objects: list[tuple[str, str, float, str]] = []
        for sch in schemas:
            p7 = (worker_results[sch].get("phases") or {}).get("7", {})
            if not p7:
                continue
            n = int(p7.get("rows") or 0)
            fp = int(p7.get("first_pass_pass") or 0)
            rp = int(p7.get("regen_pass") or 0)
            ff = int(p7.get("final_fail") or 0)
            da = p7.get("dimension_averages") or {}
            for k, v in da.items():
                agg_dim[k].append(float(v))
            scores: list[float] = []
            for o in worker_results[sch].get("objects", []):
                s = o.get("evaluator_score")
                if isinstance(s, (int, float)):
                    scores.append(float(s))
                if o.get("evaluator_verdict") == "FAIL":
                    final_fail_objects.append((sch, o.get("name", "?"),
                                                 float(s or 0), (o.get("status_detail") or "")[:160]))
            avg = (sum(scores) / len(scores)) if scores else 0.0
            sum_score += sum(scores)
            sum_score_count += len(scores)
            lines.append(
                f"| `{sch}` | {n} | {fp} | {rp} | {ff} | {avg:.2f} | "
                f"{da.get('inheritance_fidelity', 0):.1f} | "
                f"{da.get('source_code_narration_accuracy', 0):.1f} | "
                f"{da.get('null_with_provenance_correctness', 0):.1f} | "
                f"{da.get('completeness', 0):.1f} | "
                f"{da.get('shape_fidelity', 0):.1f} | "
                f"{da.get('lineage_coherence', 0):.1f} |"
            )
            t_eval += n
            t_fp += fp
            t_rp += rp
            t_ff += ff
        avg_all = (sum_score / sum_score_count) if sum_score_count else 0.0
        dim_avg_all = {k: (sum(v) / len(v) if v else 0.0) for k, v in agg_dim.items()}
        lines.append(
            f"| **TOTAL** | **{t_eval}** | **{t_fp}** | **{t_rp}** | **{t_ff}** | **{avg_all:.2f}** | "
            f"**{dim_avg_all.get('inheritance_fidelity', 0):.1f}** | "
            f"**{dim_avg_all.get('source_code_narration_accuracy', 0):.1f}** | "
            f"**{dim_avg_all.get('null_with_provenance_correctness', 0):.1f}** | "
            f"**{dim_avg_all.get('completeness', 0):.1f}** | "
            f"**{dim_avg_all.get('shape_fidelity', 0):.1f}** | "
            f"**{dim_avg_all.get('lineage_coherence', 0):.1f}** |"
        )
        lines.append("")
        if final_fail_objects:
            lines.append("### Final-FAIL objects")
            lines.append("")
            lines.append("| Schema | Object | Weighted score | First-line feedback |")
            lines.append("|--------|--------|----------------|---------------------|")
            for sch, obj, sc, fb in final_fail_objects:
                fb_clean = (fb or "").replace("|", "\\|").replace("\n", " ")[:120]
                lines.append(f"| `{sch}` | `{obj}` | {sc:.2f} | {fb_clean} |")
            lines.append("")
        else:
            lines.append("_No final-FAIL objects — all evaluated wikis passed the adversarial gate._")
            lines.append("")

    lines.append("## Errors")
    lines.append("")
    if errors:
        for e in errors:
            lines.append(f"- {e}")
    else:
        lines.append("_(none)_")
    lines.append("")

    lines.append(f"---")
    lines.append(f"_Generated by `tools/uc_pipelines/write_audit_summary.py` at {_now_iso_z()}._")
    lines.append("")

    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(description="Write per-run audit summary (UC-Pipeline pack)")
    ap.add_argument("--audit-dir", required=True,
                    help="The _runs/{ts}/ folder this summary belongs to")
    ap.add_argument("--worker-result", action="append", default=[],
                    help="One per schema: 'schema_name:path/to/worker_result.json'. Repeatable.")
    ap.add_argument("--dag-summary-json",
                    help="Optional: path to a JSON file with DAG summary metrics")
    ap.add_argument("--cli-args", default="",
                    help="Original CLI args string for provenance")
    ap.add_argument("--wall-clock-seconds", type=float, default=None,
                    help="Total wall-clock seconds for the run")
    ap.add_argument("--error", action="append", default=[],
                    help="Append an error message to the summary. Repeatable.")
    args = ap.parse_args()

    audit_dir = Path(args.audit_dir)
    audit_dir.mkdir(parents=True, exist_ok=True)

    worker_results: dict[str, dict] = {}
    for spec in args.worker_result:
        if ":" not in spec:
            print(f"WARN: skipping malformed --worker-result {spec!r}", file=sys.stderr)
            continue
        sch, path = spec.split(":", 1)
        worker_results[sch.strip()] = _load_worker_result(Path(path.strip()))

    dag_summary: dict = {}
    if args.dag_summary_json:
        p = Path(args.dag_summary_json)
        if p.exists():
            try:
                dag_summary = json.loads(p.read_text(encoding="utf-8"))
            except Exception as e:
                args.error.append(f"failed to parse dag summary: {e}")

    text = build_summary(
        audit_dir=audit_dir,
        worker_results=worker_results,
        dag_summary=dag_summary,
        cli_args_str=args.cli_args,
        wall_clock_seconds=args.wall_clock_seconds,
        errors=args.error or [],
    )

    out = audit_dir / "summary.md"
    out.write_text(text, encoding="utf-8")
    print(f"[audit-summary] wrote {out.relative_to(REPO) if out.is_absolute() else out}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr, flush=True)
        sys.exit(1)
