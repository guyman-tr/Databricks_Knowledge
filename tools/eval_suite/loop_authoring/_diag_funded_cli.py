"""Honest readout of the CLI probe: every tool call, kind, args excerpt, plus final text."""
from __future__ import annotations
import json, sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))
from tools.eval_suite.harness.suts._stream_json import (
    decode_stream_bytes, parse_stream_jsonl, parse_trace
)

raw = Path("audits/eval_suite/probe_funded_cli.jsonl").read_bytes()
events = parse_stream_jsonl(decode_stream_bytes(raw))
trace = parse_trace(events)

print(f"=== CLI probe trace ===")
print(f"events:        {len(events)}")
print(f"final_text:    {len(trace.final_text or '')} chars")
print(f"duration_ms:   {trace.duration_ms}")
print(f"is_error:      {trace.is_error}")
print(f"tool_calls:    {trace.tool_call_count}")
print(f"by kind:       {dict(trace.tool_call_by_kind)}")
print(f"by mcp tool:   {dict(trace.mcp_tool_call_by_name)}")
print(f"sql_execs:     {len(trace.sql_execs)}")
for i, x in enumerate(trace.sql_execs):
    print(f"  [{i}] method={x.method!r} succeeded={x.succeeded}")
    print(f"      sql excerpt: {(x.sql or '')[:250]}")
print(f"skills_loaded: {len(trace.skills_loaded)}")
for s in trace.skills_loaded:
    print(f"  - method={s.method!r}  slug={s.slug!r}")
print()
print("=== Final assistant text (FULL) ===")
print(trace.final_text or "(empty)")
