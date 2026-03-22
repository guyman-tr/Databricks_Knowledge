# Review Sidecar -- BI_DB_dbo.BI_DB_Crypto_Zero

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | OK | 14 columns in DDL, 14 in wiki |
| All columns have tier suffix | OK | 13 Tier 2 + 1 Tier 3 |
| Writer SP confirmed | OK | SP_M_Crypto_RECON matches OpsDB |
| Sample data reviewed | OK | 5 rows sampled -- unrealized diffs and realized zeros consistent |
| Alias-level attribution | OK | Complex 3-temp-table pipeline fully traced |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | TotalZero meaning | Medium | Named "Zero" but values are not zero. Confirm: does "zero" refer to a reconciliation target (should net to zero if all P&L tracked) or is it a naming convention? |
| 2 | #final FULL OUTER JOIN key | Low | #PnL0 and #PnL1 join on CID+Regulation+Label+SettlementType, but #realized joins on CID+Regulation+Label with a bug: uses `a.SettlementType = b.SettlementType` (references b, not c). Potential data quality issue. |
| 3 | Country column varchar(max) | Low | DDL uses varchar(max) for Country. Unusually large for a country name. |

## Reviewer Corrections

*(Empty -- awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 13 | All business columns |
| Tier 3 | 1 | UpdateDate |
