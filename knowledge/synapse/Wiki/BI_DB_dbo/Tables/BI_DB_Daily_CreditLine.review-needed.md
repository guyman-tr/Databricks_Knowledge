# Review Sidecar -- BI_DB_dbo.BI_DB_Daily_CreditLine

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | OK | 13 columns in DDL, 13 in wiki |
| All columns have tier suffix | OK | 12 Tier 2 + 1 Tier 3 |
| Writer SP confirmed | OK | SP_Daily_CreditLine matches OpsDB |
| Sample data reviewed | OK | 5 rows sampled -- CLRatio, IsExceeded patterns consistent |
| Alias-level attribution | OK | Multi-step MERGE pipeline traced |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | Self-referencing dependency | High | Today's data depends on yesterday's. If a day is missed, the chain breaks. Confirm recovery procedure. |
| 2 | CLRatio > 0.5 threshold | Medium | 50% threshold triggers IsExceeded. Confirm this is the current business threshold. |
| 3 | Fee tier table completeness | Low | BI_DB_CreditLine_Amounts has specific tiers (500, 750, 1500...). TotalCLAmount values not in the tier table get NULL fee. Sample shows NULL fees for 0 and 15000 amounts. |
| 4 | ExceedingDaysCount logic | Medium | Uses previous day's IsExceeded + ExceedingDaysCount, but the #lastexceeded temp table recalculates from V_Liabilities. Confirm the interaction. |

## Reviewer Corrections

*(Empty -- awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 12 | All business columns |
| Tier 3 | 1 | UpdateDate |
