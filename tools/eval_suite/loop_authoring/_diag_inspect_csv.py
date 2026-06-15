"""Inspect a telemetry CSV row produced by run_harness.py."""
from __future__ import annotations
import csv, json, sys
from pathlib import Path

path = Path(sys.argv[1] if len(sys.argv) > 1 else "audits/eval_suite/runs/smoke-trace-1case.csv")
with open(path, encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

print(f"Rows: {len(rows)}\n")
for idx, r in enumerate(rows):
    print(f"=== ROW {idx}: {r['case_id']} ===")
    print("--- Core scoring ---")
    for k in ("sut_name", "expected_value", "observed_value", "diff_pct",
              "tolerance_pct", "passed", "reason", "drift_verdict"):
        print(f"  {k:<20} {r.get(k)}")
    print("--- Baseline ---")
    for k in ("baseline_sut_name", "baseline_value", "baseline_diff_pct", "baseline_passed"):
        print(f"  {k:<20} {r.get(k)}")
    print("--- Trace summary ---")
    for k in ("trace_session_id", "trace_model", "trace_tool_call_count",
              "trace_sql_executed_count", "trace_sql_succeeded_count",
              "trace_input_tokens", "trace_output_tokens",
              "trace_cache_read_tokens", "trace_cache_write_tokens"):
        print(f"  {k:<32} {r.get(k)}")
    print("--- Skills loaded ---")
    sk = json.loads(r.get("trace_skills_loaded") or "[]")
    for s in sk:
        print(f"  [{s.get('method')}] {s.get('slug')}")
    print("--- Tool kinds ---")
    print(f"  {r.get('trace_tool_call_by_kind')}")
    print("--- MCP tools ---")
    print(f"  {r.get('trace_mcp_tool_call_by_name')}")
    print("--- sql_used (last successful) ---")
    sql = r.get("sql_used") or ""
    for line in sql.splitlines()[:25]:
        print(f"  {line}")
    if len(sql.splitlines()) > 25:
        print(f"  ... ({len(sql.splitlines())-25} more lines)")
    print("--- Thinking excerpt (tail) ---")
    print((r.get("trace_thinking_excerpt") or "")[:1200])
    print("--- Final answer text (first 1200 chars) ---")
    print((r.get("sut_text_answer") or "")[:1200])
    print()
