# Review Needed: BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs

**Generated**: 2026-04-26
**Quality Score**: 7.5/10
**Status**: NEEDS REVIEW -- high Tier 2 count, no SP code directly read

---

## Tier 2 Items (SP Code Analysis -- No Direct SP Read)

All 73 Tier 2 columns are documented based on the SP source metadata provided in the batch context (column names, source table references, business logic descriptions). The actual SP code was not directly read during this documentation pass. Column descriptions for ETL-computed fields (DDMinutes_*, IsSTP_*, NonVerificationReason, etc.) are based on the business logic summary provided.

### Key Tier 2 Columns Requiring Verification

| Column | Question | Priority |
|--------|----------|----------|
| IsVLChangesCountOkay | What is the threshold for "okay"? Is it a fixed number or regulation-dependent? | MEDIUM |
| US_IsAutomatic | What exact logic determines automatic vs manual? Is it based on US_UpdatedBy, or a separate flag? | MEDIUM |
| IsSTP_eToro | Does the EV match condition require EV_MatchStatusID = 2 (Verified) specifically, or does PartiallyVerified (1) also qualify? | HIGH |
| IsSTP_User | Exact conditions for "no documents uploaded" and "no declines" -- is this VD_HasDocuments=0 or a different check? | MEDIUM |
| EV_IsCountryEligible | What are the 25 hardcoded countries? If the list changes, documentation needs updating. | LOW |
| NonVerificationReason | Exact CASE order and conditions should be verified against SP code. The priority order of conditions affects classification. | MEDIUM |
| DepositAttempt | Does this include ALL payment statuses (including declined, chargeback, etc.) or only certain statuses? | MEDIUM |
| FirstDepositAttemptDate | Is this MIN(PaymentDate) across all statuses, or filtered to specific PaymentStatusIDs? | MEDIUM |

## Tier 3 Items

| Column | Question | Priority |
|--------|----------|----------|
| MarketingRegion | Confirmed sourced from Dim_Country.MarketingRegionManualName (Tier 3 in upstream wiki -- from Ext_Dim_Country manual extension table). | LOW |

## Open Questions

1. **SP code not directly reviewed**: The SP_Operations_Onboarding_Flow_UserKPIs code was not read during this documentation session. All Tier 2 descriptions are based on the structured metadata provided (source tables, column mappings, business logic groups). A reviewer with SP access should verify edge cases.

2. **ScreeningService external tables**: Seven External_ScreeningService_* tables are referenced. The exact join logic between these tables (ProviderScreening vs UserScreening vs History) determines which screening record is selected when multiple exist for a customer. This join priority should be verified.

3. **Document verification logic**: The POI/POA column logic (which document submission is selected when a customer has multiple POI/POA documents) needs verification. Is it the latest? The first approved? The first uploaded?

4. **KYC Flow fallback**: The fallback from current KycFlow to History_KycFlow when current = 0 -- does this take the most recent historical record? What if multiple history records exist?

5. **LTV coverage**: BI_DB_LTV_BI_Actual may not have rows for all customers. What percentage of customers in this table have NULL LTV values? Is this expected?

6. **DateTime_FTD vs FirstDepositDate default**: Dim_Customer sets FirstDepositDate to '1900-01-01' for non-depositors. Does the SP pass this through as-is, or convert to NULL?

7. **POI_Manager / POA_Manager**: Are these ManagerIDs from the most recent document classification event, or from the first/approved event?

## Corrections

- If a reviewer reads the SP code, Tier 2 items with verified logic can remain Tier 2 (SP code is a valid Tier 2 source)
- MarketingRegion could be upgraded to Tier 2 if the SP join logic is confirmed against Dim_Country
- Quality score should be revised upward if SP code verification confirms the documented logic

## Reviewer Instructions

1. Read `SP_Operations_Onboarding_Flow_UserKPIs` to verify the IsSTP_eToro and IsSTP_User exact conditions
2. Confirm the NonVerificationReason CASE statement order
3. Verify which ScreeningService tables take priority in the US_* column joins
4. Check the document selection logic for POI/POA when multiple documents exist
5. Verify whether DateTime_FTD passes through the '1900-01-01' default or converts to NULL
