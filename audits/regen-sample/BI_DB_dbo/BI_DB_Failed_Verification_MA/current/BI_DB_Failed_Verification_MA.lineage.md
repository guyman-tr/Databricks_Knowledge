# BI_DB_dbo.BI_DB_Failed_Verification_MA — Column Lineage

## Summary

Marketing automation table for customers with failed KYC document verification. Filters BI_DB_Operations_Onboarding_Flow_UserKPIs to partially verified users (VL2 yes, VL3 no) with phone verification, no US screening issues, not EV-verified, and documents not approved within the last 3 days. Maps rejection reasons to standardized reason codes via temp table lookup.

## Source Objects

| # | Source Object | Schema | Role |
|---|--------------|--------|------|
| 1 | BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs | BI_DB_dbo | Primary — KYC onboarding data with rejection reasons |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| GCID | BI_DB_Operations_Onboarding_Flow_UserKPIs | GCID | Passthrough |
| ReasonNumber | #TempRejectReasons | ReasonNumber | ETL-computed — COALESCE(POI match, POA match, 0). Matches RejectionReasonPOI/POA text to 22 predefined reason codes |
| RejectReasonName | #TempRejectReasons / source | RejectReasonName / RejectionReasonPOI/POA | ETL-computed — COALESCE(POI reason name, POA reason name, raw POI text, raw POA text) |
| CountryName | BI_DB_Operations_Onboarding_Flow_UserKPIs | CountryName | Passthrough |
| CurrentRegulation | BI_DB_Operations_Onboarding_Flow_UserKPIs | CurrentRegulation | Passthrough |
| RejectionReasonPOA | BI_DB_Operations_Onboarding_Flow_UserKPIs | RejectionReasonPOA | Passthrough |
| RejectionReasonPOI | BI_DB_Operations_Onboarding_Flow_UserKPIs | RejectionReasonPOI | Passthrough |
| NonVerificationReason | BI_DB_Operations_Onboarding_Flow_UserKPIs | NonVerificationReason | Passthrough — always 'Docs not Approved' (filter condition) |
| EV_MatchStatus | BI_DB_Operations_Onboarding_Flow_UserKPIs | EV_MatchStatus | Passthrough — never 'Verified' (filter condition) |
| UpdateDate | ETL metadata | GETDATE() | ETL timestamp |
