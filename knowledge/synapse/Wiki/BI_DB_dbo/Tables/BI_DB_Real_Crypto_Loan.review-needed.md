# Review Sidecar -- BI_DB_dbo.BI_DB_Real_Crypto_Loan

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | OK | 11 columns in DDL, 11 in wiki |
| All columns have tier suffix | OK | 10 Tier 2 + 1 Tier 3 |
| Writer SP confirmed | OK | SP_Real_Crypto_Loans matches OpsDB |
| Sample data reviewed | OK | 5 rows sampled -- ADA, ZEC, NEO, TRX, MIOTA. All IsSettled=1, Leverage=2 |
| Alias-level attribution | OK | #pos -> #assetlevel -> INSERT traced |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | Crypto loan = 50% of position | Medium | Description says x2 leverage means 50% loan. Confirm: is CurrentAmountCryptoLoan the full position value or just the loan half? |
| 2 | Month-end only execution | High | SP checks IsLastDayOfMonth from Dim_Date. Confirm this flag is reliable for all month boundaries. |
| 3 | BI_DB_PositionPnL dependency | High | Must run after SP_PositionPnL for accurate current values. Not tracked in OpsDB. |

## Reviewer Corrections

*(Empty -- awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 10 | All business columns |
| Tier 3 | 1 | UpdateDate |
