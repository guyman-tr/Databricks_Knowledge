# Review Sidecar -- BI_DB_dbo.BI_DB_Daily_Dividends

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | OK | 14 columns in DDL, 14 in wiki |
| All columns have tier suffix | OK | 13 Tier 2 + 1 Tier 3 |
| Writer SP confirmed | OK | SP_Daily_Dividends matches OpsDB |
| Sample data reviewed | OK | 5 rows sampled -- Real_Stocks, CFD_Stocks, Other segments present |
| Alias-level attribution | OK | Two-step (#div -> #temp -> INSERT) traced |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | Negative DividendPaid | Medium | Sample shows -248.79 for ESP35/EUR (index CFD). Confirm: are these dividend adjustments or index point changes? |
| 2 | ASIC CFD treatment | High | ASIC regulation forces all settled positions to CFD classification. Verify this is current policy. |
| 3 | BI_DB_US_Stocks completeness | Low | US stock classification depends on this lookup table. Confirm it is maintained and current. |
| 4 | Aggregation grain | Medium | Dividends aggregated per instrument per day (not per customer). Customer-level detail lost. Confirm this is intentional. |

## Reviewer Corrections

*(Empty -- awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 13 | All business columns |
| Tier 3 | 1 | UpdateDate |
