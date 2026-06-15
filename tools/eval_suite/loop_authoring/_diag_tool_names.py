"""Extract the actual tool names cursor-agent advertises for user-databricks-stg."""
from __future__ import annotations
import json, re, sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))
from tools.eval_suite.harness.suts._stream_json import decode_stream_bytes, parse_stream_jsonl

raw = Path("audits/eval_suite/probe_tool_names.jsonl").read_bytes()
events = parse_stream_jsonl(decode_stream_bytes(raw))

# Look at the final assistant text — that's where the agent listed the tools
for e in events:
    if e.get("type") == "result":
        print("=== Final result ===")
        print(e.get("result", "")[:3000])
        break
