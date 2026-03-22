# Review Sidecar -- BI_DB_dbo.BI_DB_Crypto_Net_Units_End_Of_Month

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | OK | 8 columns in DDL, 8 in wiki |
| All columns have tier suffix | OK | 7 Tier 2 + 1 Tier 3 |
| Writer SP confirmed | OK | SP_M_Crypto_RECON matches OpsDB |
| Sample data reviewed | OK | 5 rows sampled -- XLM/USD, NEO/USD, BCH/USD patterns consistent |
| Alias-level attribution | OK | Single SELECT -- all aliases traceable |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | Regulation JOIN key | Medium | Uses DR.ID (not DR.DWHRegulationID like the During_Month block). Confirm both map correctly. |

## Reviewer Corrections

*(Empty -- awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 7 | Month, CID, Regulation, Instrument, Units, SettlementType, IsValidCustomer |
| Tier 3 | 1 | UpdateDate |
