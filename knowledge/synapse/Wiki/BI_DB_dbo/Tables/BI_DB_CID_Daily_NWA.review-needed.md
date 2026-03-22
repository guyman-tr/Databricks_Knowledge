# Review Sidecar — BI_DB_dbo.BI_DB_CID_Daily_NWA

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | ✅ | 20 columns in DDL, 20 in wiki |
| All columns have tier suffix | ✅ | 19 Tier 2 + 1 Tier 3 |
| Writer SP confirmed | ✅ | SP_CID_Daily_NWA matches OpsDB |
| Sample data reviewed | ✅ | 5 rows sampled — NWA, BonusCredit, CreditLine patterns consistent |
| Alias-level attribution | ✅ | Single SELECT — all aliases directly traceable |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | ActualNWA definition | ✅ Resolved | Confirmed: "Non-Withdrawable Amount" — trading bonuses whose principal cannot be cashed out. Corrected by human reviewer. |
| 2 | IsValidCustomer filter | Medium | Uses legacy logic: NOT(PlayerLevelID = 4 AND AccountTypeID <> 2) AND LabelID NOT IN (26,30). Other SPs (like SP_ASIC_ClientBalanceFinance) switched to IsCreditReportValidCB. Confirm if this legacy filter is intentional. |
| 3 | Region values | Low | Sample shows "Spain" as both a Country and Region. Confirm Dim_Country.Region mapping is correct. |
| 4 | BI_DB_Daily_CreditLine dependency | High | SQL-level dependency on BI_DB_Daily_CreditLine (another P99 table). Not tracked in OpsDB but must run before this SP for accurate credit line values. |

## Reviewer Corrections

*(Empty — awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 19 | All business columns |
| Tier 3 | 1 | UpdateDate |
