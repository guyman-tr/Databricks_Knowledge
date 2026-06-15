"""Validate the stream-json parser against the captured probe trace."""
from __future__ import annotations
import sys, os, json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))

from tools.eval_suite.harness.suts._stream_json import (
    decode_stream_bytes,
    parse_stream_jsonl,
    parse_trace,
)

raw = Path("audits/eval_suite/stream_probe_revenue.jsonl").read_bytes()
text = decode_stream_bytes(raw)
events = parse_stream_jsonl(text)
print(f"Parsed {len(events)} events")

trace = parse_trace(events)
print(f"\n=== Trace summary ===")
print(f"session_id      : {trace.session_id}")
print(f"model           : {trace.model}")
print(f"prompt          : {trace.prompt_text!r}")
print(f"duration_ms     : {trace.duration_ms}")
print(f"is_error        : {trace.is_error}")
print(f"tool_call_count : {trace.tool_call_count}")
print(f"tool kinds      : {trace.tool_call_by_kind}")
print(f"mcp tools       : {trace.mcp_tool_call_by_name}")
print(f"tokens (in/out) : {trace.input_tokens}/{trace.output_tokens}")
print(f"cache (rd/wr)   : {trace.cache_read_tokens}/{trace.cache_write_tokens}")
print(f"thinking len    : {len(trace.thinking_text)} chars")
print(f"final text len  : {len(trace.final_text or '')} chars")

print(f"\n=== Skills loaded ({len(trace.skills_loaded)}) ===")
for s in trace.skills_loaded:
    print(f"  [{s.method:<15}] {s.slug}")

print(f"\n=== SQL execs ({len(trace.sql_execs)}) ===")
for i, x in enumerate(trace.sql_execs, 1):
    flag = "OK " if x.succeeded else "ERR"
    print(f"\n#{i} [{flag}] method={x.method}")
    print("  SQL:")
    for line in x.sql.splitlines()[:12]:
        print(f"    {line}")
    if x.error:
        print(f"  err: {x.error[:200]}")
    if x.result_excerpt:
        print(f"  result: {x.result_excerpt[:200]}")

print(f"\n=== Final text (first 600 chars) ===")
print((trace.final_text or "")[:600])
