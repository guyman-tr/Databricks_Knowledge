"""Inspect the shape of stream-json events from cursor-agent.

Goal: understand the exact JSON keys for tool_use / tool_result / assistant /
thinking events, so the SUT parser can extract:
  - skills_find_skills queries + results
  - skills_get_skill slugs
  - databricks_sql_execute_sql_read_only SQL bodies
  - tool counts per name
"""
from __future__ import annotations
import json
from collections import Counter
from pathlib import Path

PATH = Path("audits/eval_suite/stream_probe_revenue.jsonl")

events = []
raw = PATH.read_bytes()
# PowerShell `>` writes UTF-16-LE with BOM. Detect & decode.
if raw.startswith(b"\xff\xfe"):
    text = raw[2:].decode("utf-16-le", errors="replace")
elif raw.startswith(b"\xef\xbb\xbf"):
    text = raw[3:].decode("utf-8", errors="replace")
else:
    text = raw.decode("utf-8", errors="replace")
for line in text.splitlines():
    line = line.strip()
    if not line:
        continue
    try:
        events.append(json.loads(line))
    except json.JSONDecodeError as e:
        print(f"PARSE FAIL: {e} on line: {line[:200]}")

print(f"Total events: {len(events)}\n")

# Type histogram
type_counter: Counter[str] = Counter()
subtype_counter: Counter[str] = Counter()
for e in events:
    t = e.get("type", "?")
    type_counter[t] += 1
    if e.get("subtype"):
        subtype_counter[f"{t}/{e['subtype']}"] += 1

print("Type histogram:")
for t, n in type_counter.most_common():
    print(f"  {t:<20} {n:>5}")
print("\nSubtype histogram:")
for st, n in subtype_counter.most_common():
    print(f"  {st:<40} {n:>5}")

# Show a sample of each unique (type, subtype) — first occurrence only
print("\n\n=== One sample of each unique (type, subtype) ===")
seen = set()
for e in events:
    key = (e.get("type"), e.get("subtype"))
    if key in seen:
        continue
    seen.add(key)
    print(f"\n--- {key} ---")
    pretty = json.dumps(e, indent=2)
    print(pretty[:1200])

# Show ALL tool_call events: tool name, args (truncated), and brief result
print("\n\n=== ALL tool_call events (started + completed) ===")
for e in events:
    if e.get("type") != "tool_call":
        continue
    sub = e.get("subtype")
    tc = e.get("tool_call", {})
    # Polymorphic shape: {readToolCall|mcpToolCall|writeToolCall|...: {args, result?}}
    inner_key = next(iter(tc.keys()), "?")
    inner = tc.get(inner_key, {})
    args = inner.get("args", {})
    result = inner.get("result")
    call_id = e.get("call_id", "")[:20]
    args_str = json.dumps(args)[:400]
    result_str = (json.dumps(result)[:300] if result else "")
    print(f"\n[{sub:<10}] call={call_id} kind={inner_key}")
    print(f"  args:   {args_str}")
    if sub == "completed":
        print(f"  result: {result_str}")
