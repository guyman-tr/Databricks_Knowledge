# Review Sidecar: BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions

## Verification Status

| Item | Status | Notes |
|------|--------|-------|
| Writer SP | Verified | `SP_DDR_Fact_Revenue_Generating_Actions` — DELETE/INSERT + options + staking passes |
| Primary lineage | Verified | Many `Function_Revenue_*` TVFs, `Dim_Revenue_Metrics`, `Dim_ActionType`, `Dim_Instrument`, parquet, `V_C2P_Positions`, `BI_DB_CopyFund_Positions` |
| Distribution / CCI | Verified | HASH(RealCID), clustered columnstore from DDL |
| Consumers (repo) | Verified | `BI_DB_V_DDR_Revenue_Breakdown`, `Function_Revenue_Total`, `SP_RevenueForum` |

## Unverified Items

| Topic | Tier | Issue |
|-------|------|-------|
| Currency / FX | T4 | Assumed USD for DDR — confirm per-function |
| Every `Metric` string | T4 | Dictionary in `Dim_Revenue_Metrics` should be reconciled to full union list |
| Options second pass | T4 | All-time function window — confirm consumer expectations for `DateID` vs recognition |
| Staking month rewrite | T4 | Confirm business sign-off on lag and MTD delete scope |
| ActionTypeID null metrics | T4 | Document which metrics legitimately have NULL `ActionTypeID` |

## Quality Notes

- **High complexity** — wiki summarizes SP; deep column provenance per `Metric` requires tracing individual `Function_Revenue_*` TVFs.
- **SDRT IncludedInTotalRevenue** — SP applies explicit UPDATE; trust `Dim_Revenue_Metrics` plus post-fixes when auditing.
