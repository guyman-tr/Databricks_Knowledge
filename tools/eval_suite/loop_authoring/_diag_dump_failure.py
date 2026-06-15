"""Dump full JSON of a FAILED shellToolCall completed event."""
from __future__ import annotations
import json, sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))
from tools.eval_suite.harness.suts._stream_json import decode_stream_bytes, parse_stream_jsonl

raw = Path("audits/eval_suite/stream_probe_revenue.jsonl").read_bytes()
events = parse_stream_jsonl(decode_stream_bytes(raw))

for e in events:
    if e.get("type") != "tool_call" or e.get("subtype") != "completed":
        continue
    tc = e.get("tool_call", {})
    if "shellToolCall" not in tc:
        continue
    inner = tc["shellToolCall"]
    res = inner.get("result", {})
    if "failure" in res:
        print(json.dumps(e, indent=2)[:4000])
        print("\n\n=====\n")
        break
