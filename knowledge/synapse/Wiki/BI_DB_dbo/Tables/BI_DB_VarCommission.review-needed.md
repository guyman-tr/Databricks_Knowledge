# Review Sidecar -- BI_DB_dbo.BI_DB_VarCommission

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | OK | 16 columns in DDL, 16 in wiki |
| All columns have tier suffix | OK | 15 Tier 2 + 1 Tier 3 |
| Writer SP confirmed | OK | SP_VarCommission matches OpsDB |
| Sample data reviewed | OK | 5 rows sampled -- Stocks type, various instruments, HedgeServerID 112/128 |
| Alias-level attribution | OK | #Commissions temp -> INSERT traced |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | Dim_Customer vs Fact_SnapshotCustomer | Medium | This SP uses Dim_Customer (not Fact_SnapshotCustomer) for IsValidCustomer. Different from most BI_DB SPs. Confirm intentional. |
| 2 | SellCurrencyID=1 shortcut | Low | When SellCurrencyID=1, USDConversionRate is skipped (assumed 1). Confirm CurrencyID 1 = USD. |
| 3 | VarCommission formula accuracy | Medium | Complex CASE logic for same-day open+close, carry-over close, and new open. The formulas differ for each scenario. Verify edge cases. |
| 4 | CalendarYear column | Low | CalendarYear is selected into #Month but not inserted into final table. Confirm it was intentionally excluded. |

## Reviewer Corrections

*(Empty -- awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 15 | All business columns |
| Tier 3 | 1 | UpdateDate |
