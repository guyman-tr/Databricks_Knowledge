# Review Sidecar — Dealing_dbo.V_RequestViewForBestExecution

## Unverified Claims

| # | Claim | Source | Needs |
|---|-------|--------|-------|
| 1 | HedgeExecutionModeID = 3 represents internal/test executions | Inferred from exclusion filter | Confirm with Dealing team |
| 2 | FlowType = 1 means automated (IsManual = 0) | CASE mapping in DDL | Confirm FlowType semantics |
| 3 | Hedge Server path 24h filter is intentional (not a bug) | LEFT JOIN condition includes time filter | Verify — this means RLEL columns may be NULL for older requests |
| 4 | UNION dedup is intentional (vs UNION ALL) | DDL uses UNION | Confirm whether dedup is needed or performance oversight |

## Reviewer Corrections

*(none yet)*
