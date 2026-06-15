"""Summarize the 15-case trace run into a glanceable markdown report.

For each case, surfaces:
  - pass/fail + diff_pct + verdict
  - skills loaded
  - SQL-exec count (succeeded / total) + last successful SQL (truncated)
  - tokens (in + out + cache)
  - reasoning excerpt (last 600 chars of thinking)
  - final answer first paragraph

Output: audits/eval_suite/runs/<run>.summary.md
"""
from __future__ import annotations
import csv
import json
import sys
from pathlib import Path

if len(sys.argv) < 2:
    print("usage: _diag_summarize_15.py <csv_path>", file=sys.stderr)
    sys.exit(1)

csv_path = Path(sys.argv[1])
out_path = csv_path.with_suffix(".summary.md")

with open(csv_path, encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

n = len(rows)
n_pass = sum(1 for r in rows if r["passed"].lower() == "true")
n_fail = n - n_pass

# Top-line stats
total_in = sum(int(r["trace_input_tokens"] or 0) for r in rows)
total_out = sum(int(r["trace_output_tokens"] or 0) for r in rows)
total_cache_r = sum(int(r["trace_cache_read_tokens"] or 0) for r in rows)
total_cache_w = sum(int(r["trace_cache_write_tokens"] or 0) for r in rows)
total_elapsed_s = sum(int(r["elapsed_ms"] or 0) for r in rows) // 1000

# Skill-load census
from collections import Counter
skill_counter: Counter[str] = Counter()
for r in rows:
    sk = json.loads(r.get("trace_skills_loaded") or "[]")
    for s in sk:
        skill_counter[f"{s.get('method')}: {s.get('slug')}"] += 1

# MCP tool usage census
mcp_counter: Counter[str] = Counter()
tool_kind_counter: Counter[str] = Counter()
for r in rows:
    for k, v in json.loads(r.get("trace_mcp_tool_call_by_name") or "{}").items():
        mcp_counter[k] += int(v)
    for k, v in json.loads(r.get("trace_tool_call_by_kind") or "{}").items():
        tool_kind_counter[k] += int(v)

lines: list[str] = []
lines.append(f"# Eval suite trace run — {csv_path.name}")
lines.append("")
lines.append(f"- Run: `{rows[0]['run_id']}` started {rows[0]['run_started_at']}")
lines.append(f"- Host: `{rows[0]['host']}`  Backend: `{rows[0]['sut_name']}`  Baseline: `{rows[0]['baseline_sut_name']}`")
lines.append(f"- Result: **{n_pass}/{n} passed, {n_fail} failed**")
lines.append(f"- Total wall time: {total_elapsed_s}s  ({total_elapsed_s/60:.1f} min)")
lines.append(f"- Total tokens: in={total_in:,}  out={total_out:,}  cache_read={total_cache_r:,}  cache_write={total_cache_w:,}")
lines.append("")

lines.append("## Skill-load census (across all 15 cases)")
lines.append("")
for k, v in skill_counter.most_common():
    lines.append(f"- `{k}` × **{v}**")
lines.append("")

lines.append("## Tool-call census")
lines.append("")
lines.append("**By kind (cursor-agent native tools):**")
for k, v in tool_kind_counter.most_common():
    lines.append(f"- `{k}` × {v}")
lines.append("")
lines.append("**By MCP tool name:**")
if mcp_counter:
    for k, v in mcp_counter.most_common():
        lines.append(f"- `{k}` × {v}")
else:
    lines.append("- _(no MCP tool calls — agent routed all SQL through `python tools/dbx_query.py`)_")
lines.append("")

# Per-case detail
lines.append("## Per-case detail")
lines.append("")

# Sort: failures first (most-divergent first), then passes
def sort_key(r: dict) -> tuple:
    passed = r["passed"].lower() == "true"
    try:
        d = abs(float(r["diff_pct"])) if r.get("diff_pct") else 0.0
    except (ValueError, TypeError):
        d = 0.0
    # passes after fails; within group sort by largest divergence first
    return (passed, -d)

for r in sorted(rows, key=sort_key):
    cid = r["case_id"]
    passed = r["passed"].lower() == "true"
    badge = "✅ PASS" if passed else "❌ FAIL"
    diff = r.get("diff_pct") or ""
    if diff:
        try:
            diff = f"{float(diff):+.4f}%"
        except ValueError:
            pass
    verdict = r.get("drift_verdict", "N/A")
    lines.append(f"### {badge} `{cid}`  ({verdict}, diff={diff})")
    lines.append("")
    lines.append(f"- **Question:** {r['natural_language_question'].strip()}")
    lines.append(f"- **Expected (baseline UC live):** `{r['expected_value']}`  &nbsp; **Observed (agent):** `{r['observed_value']}`")
    if r.get("sut_error"):
        lines.append(f"- **SUT error:** `{r['sut_error']}`")
    skills = json.loads(r.get("trace_skills_loaded") or "[]")
    if skills:
        skills_md = ", ".join(f"`{s.get('slug')}` ({s.get('method')})" for s in skills)
    else:
        skills_md = "_(none — agent answered without loading any skill file)_"
    lines.append(f"- **Skills loaded:** {skills_md}")
    n_sql = r.get("trace_sql_executed_count") or "0"
    n_sql_ok = r.get("trace_sql_succeeded_count") or "0"
    lines.append(f"- **SQL execs:** {n_sql_ok}/{n_sql} succeeded  &nbsp; **Tool calls:** {r.get('trace_tool_call_count') or '0'}")
    tok_in = r.get("trace_input_tokens") or "0"
    tok_out = r.get("trace_output_tokens") or "0"
    tok_cr = r.get("trace_cache_read_tokens") or "0"
    tok_cw = r.get("trace_cache_write_tokens") or "0"
    lines.append(f"- **Tokens:** in={tok_in}  out={tok_out}  cache_read={tok_cr}  cache_write={tok_cw}")
    lines.append(f"- **Elapsed:** {int(r.get('elapsed_ms') or 0)/1000:.1f}s")
    lines.append("")
    sql = (r.get("sql_used") or "").strip()
    if sql:
        lines.append("**Last successful SQL the agent ran (its answer-producing query):**")
        lines.append("")
        lines.append("```sql")
        for ln in sql.splitlines()[:30]:
            lines.append(ln)
        if len(sql.splitlines()) > 30:
            lines.append(f"-- ... ({len(sql.splitlines())-30} more lines)")
        lines.append("```")
        lines.append("")
    excerpt = (r.get("trace_thinking_excerpt") or "").strip()
    if excerpt:
        lines.append("**Reasoning (tail of thinking trace):**")
        lines.append("")
        lines.append("> " + excerpt[-800:].replace("\n", "\n> "))
        lines.append("")
    final = (r.get("sut_text_answer") or "").strip()
    if final:
        # First ~600 chars of the agent's final answer
        first = final[:600]
        lines.append("**Agent's answer (first 600 chars):**")
        lines.append("")
        lines.append("```")
        lines.append(first)
        if len(final) > 600:
            lines.append("...")
        lines.append("```")
        lines.append("")
    lines.append("---")
    lines.append("")

out_path.write_text("\n".join(lines), encoding="utf-8")
print(f"Wrote: {out_path}")
print(f"Lines: {len(lines)}")
