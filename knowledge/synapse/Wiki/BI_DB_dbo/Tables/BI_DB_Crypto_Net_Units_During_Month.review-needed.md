# Review Sidecar -- BI_DB_dbo.BI_DB_Crypto_Net_Units_During_Month

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | OK | 8 columns in DDL, 8 in wiki |
| All columns have tier suffix | OK | 7 Tier 2 + 1 Tier 3 |
| Writer SP confirmed | OK | SP_M_Crypto_RECON matches OpsDB |
| Sample data reviewed | OK | 5 rows sampled -- BTC/USD, LTC/USD patterns consistent |
| Alias-level attribution | OK | Two-step (#pos -> final SELECT) traced |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | Units formula interpretation | Medium | `2*IsBuy-1` maps buy=1->+1, sell=0->-1. `2*Is_open-1` maps open=1->+1, closed=0->-1. Confirm the net flow semantics. |
| 2 | Pre-2022 NULLs | High | SettlementType and IsValidCustomer are NULL for older data. Sample confirms this pattern. |

## Reviewer Corrections

*(Empty -- awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 7 | Month, CID, Regulation, Instrument, Units, SettlementType, IsValidCustomer |
| Tier 3 | 1 | UpdateDate |
