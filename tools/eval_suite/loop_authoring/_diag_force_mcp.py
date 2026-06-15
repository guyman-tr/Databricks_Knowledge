"""Look at the tool calls in the force-mcp probe to see actual tool names."""
from __future__ import annotations
import json, sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))
from tools.eval_suite.harness.suts._stream_json import decode_stream_bytes, parse_stream_jsonl

raw = Path("audits/eval_suite/probe_force_mcp.jsonl").read_bytes()
events = parse_stream_jsonl(decode_stream_bytes(raw))

print(f"Total events: {len(events)}\n")
# Type histogram
from collections import Counter
types = Counter(f"{e.get('type')}/{e.get('subtype')}" for e in events)
for t, n in types.most_common():
    print(f"  {t:<30} {n}")
print()

# Print all tool_call/started events with their full inner structure
for e in events:
    if e.get("type") == "tool_call" and e.get("subtype") == "started":
        tc = e.get("tool_call", {})
        kind = next(iter(tc.keys()), "?")
        inner = tc.get(kind, {})
        args = inner.get("args", {})
        print(f"\n[started] kind={kind}")
        if kind == "mcpToolCall":
            # Show server, name, arguments
            server = args.get("server") or args.get("serverName") or "?"
            tname = args.get("name") or args.get("toolName") or "?"
            print(f"  server: {server}")
            print(f"  tool:   {tname}")
            print(f"  args keys: {list(args.keys())}")
            print(f"  full args (first 500 chars): {json.dumps(args)[:500]}")
        elif kind == "shellToolCall":
            cmd = (args.get("command") or "")[:200]
            print(f"  command: {cmd}")
        else:
            print(f"  args (first 300): {json.dumps(args)[:300]}")

# Final result
for e in events:
    if e.get("type") == "result":
        print(f"\n\n=== Final assistant text ===")
        print(e.get("result", "")[:1500])
        break
