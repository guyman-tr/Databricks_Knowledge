# Review Needed: BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings

## 1. Temporary Solution Status

- **SP author comment**: "this is a temporary solution to bring the cashout rollbacks pips into finance... the end game of this should be to receive in views from DBAs on production"
- **Risk**: Hard-coded logic (DepotID lists, FundingTypeID=2 wire handling, PWMBUS hardcode for FundingTypeID_Funding=32) can diverge from production routing without notification
- **Action**: Verify with DBA team whether production views have been created to replace this logic

## 2. Unresolved MID Values

- ~11% of recent rows have **empty string** MIDName and MID values (28,785 out of 260,322 in Sept 2025 sample)
- 179 rows have MIDName = 'NA' (distinct from empty — these hit the fallback logic but could not be resolved)
- **Action**: Investigate root cause — may indicate new depots/funding types not covered by the hard-coded CASE logic

## 3. External Table Dependencies

The following external tables are not documented in the wiki ecosystem and their schemas cannot be verified from SSDT:
- `BI_DB_dbo.External_eToro_Dictionary_MapMerchantCodeToMid`
- `BI_DB_dbo.External_eToro_Billing_MerchantAccountRouting`
- `BI_DB_dbo.External_eToro_Dictionary_MerchantAccount`
- `BI_DB_dbo.External_etoro_billing_vWithdrawToFunding_Alltime`
- `Dealing_staging.External_Etoro_History_WithdrawToFundingAction`

**Action**: Document these external tables or verify they are covered by existing upstream wikis.

## 4. Tier Coverage

All 7 columns are Tier 2 (ETL-computed). This is correct — the table is entirely synthesized by `SP_PIPs_Report_MID_Settings` with no direct passthroughs from upstream sources. The upstream bundle wikis inform the business context but no column values are passed through unchanged.

## 5. Data Freshness

- Data range: 2024-01-01 to 2025-09-10 (most recent data as of query time)
- **Action**: Confirm the SP is still running daily and check if there is a gap between the latest data and today's date

---

*Generated: 2026-04-29 | Reviewer: DWH Semantic Documentation Pipeline*
