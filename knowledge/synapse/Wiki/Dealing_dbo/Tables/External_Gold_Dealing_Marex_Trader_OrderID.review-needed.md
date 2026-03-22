# Review Sidecar — Dealing_dbo.External_Gold_Dealing_Marex_Trader_OrderID

## Unverified Claims

| # | Claim | Source | Needs |
|---|-------|--------|-------|
| 1 | Trader format is always `ETO-{alphanum}-{alphanum}` | Live data sample (3 rows) | Verify with larger sample |
| 2 | Gold layer pipeline is Databricks-based | Inferred from `internal-sources` + Gold path convention | Confirm pipeline name/owner |
| 3 | OrderID is 1:1 with Trader | Inferred from SP DISTINCT usage | Verify — could be 1:N if multiple orders per trader per day |
| 4 | ExitOrderID is the close-leg order | Column name inference | Confirm semantics with Dealing team |

## Reviewer Corrections

*(none yet)*
