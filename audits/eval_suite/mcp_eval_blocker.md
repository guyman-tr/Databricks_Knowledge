# Architectural blocker: cursor-agent CLI cannot reliably exercise your custom MCP

## What we just discovered

When you said "the whole thing is useless if it didn't go through the MCP — we are
ONLY testing the databricks-stg MCP", I went to verify what the agent actually
does when forced. The findings:

1. **Your `databricks-stg` MCP is a remote HTTP MCP** at
   `https://databricks-mcp-gateway-5142916747090026.6.azure.databricksapps.com/mcp`
   reached via `npx mcp-remote` (a stdio↔HTTP bridge that handles OAuth
   client-credentials + token caching).

2. **The cursor-agent CLI does see it in `~/.cursor/mcp.json`** (it's listed in
   `cursor-agent mcp list`), but `cursor-agent mcp list` reports it as
   `not loaded (needs approval)` — meaning the connection isn't established
   until a session attempts to use it.

3. **Forcing the agent to call a `databricks-stg` tool from CLI hangs**.
   I prompted: "Call `mcp_user-databricks-stg_databricks_ops_get_current_user`,
   report what it returned, do not use shell, do not use any other tool."
   The cursor-agent CLI sat for 4+ minutes producing no output (no thinking,
   no tool_call events, no errors) before I killed it. The OAuth handshake
   that `mcp-remote` does to your gateway is not completing under the CLI.

4. **In the IDE chat, the same MCP works fine.** Cursor IDE has a per-app
   OAuth token cache and an MCP supervisor that maintains the connection.
   The CLI does not — it spawns a fresh `npx mcp-remote` per process and
   the OAuth flow either needs an interactive browser pop (impossible in
   a headless `--print` run) or a cached token at a path the CLI doesn't
   look at.

## So what is the `cursor_agent` SUT actually testing?

In its current form: **the model + the `.cursor/skills/` corpus + shell tools.**
NOT your custom MCP. Every previous run that "succeeded" did so by going
through `python tools/dbx_query.py`, which uses the same Databricks SDK
credentials but bypasses your MCP gateway's skills router, prompt
instructions, and tool surface.

That's the "useless" you correctly called out.

## Three honest paths forward

### Path A — Fix cursor-agent CLI auth so it can reach the MCP

Get `mcp-remote`'s OAuth token cached for the CLI process.

- `mcp-remote` writes its token cache to `~/.mcp-auth/<hash>` (per its docs).
  The IDE almost certainly has a working token there. The CLI should reuse
  it... but evidence says it isn't.
- Could also try: `cursor-agent mcp login databricks-stg` (the CLI has a
  `login` subcommand, see `cursor-agent mcp --help`). Haven't tried it
  because it might want a browser flow we can't do in PowerShell well.

**Risk:** even if we fix it, the CLI's OAuth-token reach is fragile. A token
expiry mid-run will silently fail every case from that point. NOT a robust
foundation for daily eval runs.

### Path B — Drop cursor-agent CLI; build a direct-MCP SUT in Python

Skip the agent CLI entirely. Build a small Python harness that:

1. Spawns `mcp-remote` directly (or talks HTTP to the gateway)
2. Uses YOUR Databricks PAT (already in `~/.databrickscfg`) — no browser OAuth
3. Runs the canonical skills flow yourself:
   - LLM driver decides "this is an org question"
   - Calls `skills_find_skills(question)`
   - Calls `skills_get_skill(top_match.id)`
   - Generates SQL (LLM call) grounded in `body_markdown` / `example_sql`
   - Calls `databricks_ops_execute_sql(sql)`
   - Parses result, returns scalar

**Pros:**
- Tests EXACTLY the MCP surface, end-to-end, with no agent-CLI weirdness
- Deterministic, observable, scriptable
- Works in a Databricks notebook (the user's stated end-state)
- Can mix LLM drivers (Cursor API, Databricks foundation models, Anthropic)
  without changing the eval contract

**Cons:**
- ~150-300 lines of new code (an LLM driver + the MCP skills flow)
- Doesn't include "the rest of Cursor" — workspace rules, file-read tools,
  rule precedence — but that was a feature, not a bug, for measuring the
  MCP itself

This is what the user actually asked for in the original spec
("ask the custom MCP the NLP and measure the answer"). The cursor-agent CLI
detour was a useful diagnostic but is the wrong runtime for daily evals.

### Path C — Run the eval inside the Cursor IDE itself, not the CLI

Use Cursor's SDK (`@cursor/sdk` or `cursor-sdk`) which spawns Cursor agents
*inside the running IDE process*. That gives the eval the same MCP runtime
as a real user. But:

- Requires the user's IDE to be open and authenticated during eval runs
- Doesn't translate to a Databricks notebook scheduled job
- Defeats the "fresh agent per question" requirement (same process, same
  cache, possible context leak)

**Verdict: not viable for daily automated evals.**

## My recommendation

**Path B.** The cursor-agent CLI was always going to be wrong for this:
the design goal was always "exercise the MCP", and the CLI is a wrapper that
adds workspace rules + file-read tools the user does NOT want in the test.

Moving to a direct-MCP Python SUT:
- Removes the OAuth-cache fragility
- Tests the actual MCP surface the user wants graded
- Maps cleanly to a Databricks notebook (the production runtime)
- Lets us pick the LLM driver per cost/availability concerns
  (Cursor API for parity with how users build SQL in Cursor; Databricks
  foundation models for "live in DBX" parity; etc.)

The trace plumbing we just wired (stream-json → `_stream_json.py` → CSV columns)
is mostly portable: the new SUT will produce its OWN trace shape (skill_search
events + skill_load events + sql_execs) which we serialize into the same
CSV columns. Most of the harness wins carry over.

## What to throw away

- `cursor_agent.py` SUT — keep as a "memorised baseline" SUT (no MCP, no skills)
  for control-group comparisons, but stop treating its result as the headline.
- `eval_mcp_only_rule.template.mdc` — irrelevant once we go direct-MCP.
- `_mcp_guard.py` — keep `detect_mcp_bypass_violations` for any future SUT
  that uses cursor-agent; the rest goes.

## What to keep

- `_stream_json.py` parser shape — generalize to "trace any SUT" not just cursor-agent
- All the YAML cases (untouched)
- The runner / scorer / telemetry CSV schema (untouched, just one new SUT type)
- The `--rebaseline` direct_sql baseline mode (untouched, more important than ever)
- The triage rubric (parser bug / question ambiguity / signposting / skill gap)
