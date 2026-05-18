# T034 — Decide-runner decision

**Date**: 2026-05-17
**Decision**: For the FIRST full pilot run, execute `/speckit.implement` (or equivalent batch invocation) from inside the Cursor session. For SUBSEQUENT recurring runs (re-document after data model changes, monthly refresh), use a headless Claude CLI loop.

## Rationale

| Factor | Cursor session | Claude CLI loop |
|---|---|---|
| Wall-clock for full pilot (~80-150 objects) | 45-60 min | 45-60 min |
| Session timeout risk | Cursor session can time out at ~2h | None |
| Interactive debugging | Live | None |
| Operator visibility | High — stdout streams to chat | Low — must `tail -f` summary.md |
| MCP / UC OAuth flow | Requires browser-resident token | Requires CLI-resident token |
| Cost (LLM tokens for Phase 7) | Same | Same |

For the first run, the operator value of seeing each phase's stdout in the chat and being able to interrupt + fix on the spot outweighs the cleanliness of a headless loop. After the first successful run produces a stable baseline, subsequent re-runs are mechanical and benefit from the CLI loop's set-and-forget property.

## Headless loop recipe (CLI / cron / CI)

```bash
# tools/uc_pipelines/loop_runner.sh   (template; not delivered as a hard artifact)
#!/usr/bin/env bash
set -euo pipefail

while true; do
  python tools/uc_pipelines/run_pipeline.py \
    --schemas de_output,bi_output,bi_dealing,etoro_kpi_prep,etoro_kpi \
    --evaluate \
    --audit-dir "knowledge/UC_generated/_runs/$(date -u +%Y-%m-%dT%H-%M-%SZ)" \
  || echo "Run failed; will retry in interval"
  sleep "${INTERVAL_SECONDS:-3600}"
done
```

The exit code from `run_pipeline.py`:

- `0` — all schemas succeeded; everything green
- `1` — at least one schema had a phase failure or eval FAIL
- `2` — pre-flight failure (bad CLI args, missing UC profile)
- `4` — invalid pilot scope or phase list

For automation purposes only `0` is a green run.

## Verdict

T034 is satisfied. The decision is **Cursor for first run, CLI loop for steady-state**.
