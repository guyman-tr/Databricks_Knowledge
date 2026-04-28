# Lineage: BI_DB_dbo.BI_DB_Failed_Verification_MA

## Source Objects

| Source Object | Type | Schema | Role |
|---------------|------|--------|------|
| BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs | Table | BI_DB_dbo | Primary source — VL2-not-VL3 customers with document verification failures |
| BI_DB_dbo.SP_Failed_Verification_MA | Stored Procedure | BI_DB_dbo | Writer SP — TRUNCATE+INSERT with hardcoded 22-code rejection reason lookup and 3-day lookback filter |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|---------------|---------------|---------------|-----------|------|
| GCID | BI_DB_Operations_Onboarding_Flow_UserKPIs | GCID | Passthrough | Tier 1 — Customer.CustomerStatic |
| ReasonNumber | SP_Failed_Verification_MA | #TempRejectReasons.ReasonNumber | COALESCE(trr.ReasonNumber, trr1.ReasonNumber, 0) — maps RejectionReasonPOI then RejectionReasonPOA to hardcoded numeric codes; defaults to 0 if no match | Tier 2 — SP_Failed_Verification_MA |
| RejectReasonName | SP_Failed_Verification_MA | #TempRejectReasons + upstream | COALESCE(trr.RejectReasonName, trr1.RejectReasonName, RejectionReasonPOI, RejectionReasonPOA) — prioritises mapped POI reason, then mapped POA reason, then raw POI text, then raw POA text | Tier 2 — SP_Failed_Verification_MA |
| CountryName | BI_DB_Operations_Onboarding_Flow_UserKPIs | CountryName | Passthrough | Tier 1 — Dictionary.Country |
| CurrentRegulation | BI_DB_Operations_Onboarding_Flow_UserKPIs | CurrentRegulation | Passthrough | Tier 1 — Dictionary.Regulation |
| RejectionReasonPOA | BI_DB_Operations_Onboarding_Flow_UserKPIs | RejectionReasonPOA | Passthrough | Tier 1 — BI_DB_Operations_Onboarding_Flow_UserKPIs |
| RejectionReasonPOI | BI_DB_Operations_Onboarding_Flow_UserKPIs | RejectionReasonPOI | Passthrough | Tier 1 — BI_DB_Operations_Onboarding_Flow_UserKPIs |
| NonVerificationReason | BI_DB_Operations_Onboarding_Flow_UserKPIs | NonVerificationReason | Passthrough (always 'Docs not Approved' due to WHERE filter) | Tier 1 — BI_DB_Operations_Onboarding_Flow_UserKPIs |
| EV_MatchStatus | BI_DB_Operations_Onboarding_Flow_UserKPIs | EV_MatchStatus | Passthrough (excludes 'Verified' due to WHERE filter) | Tier 1 — BI_DB_Operations_Onboarding_Flow_UserKPIs |
| UpdateDate | SP_Failed_Verification_MA | GETDATE() | ETL execution timestamp | Tier 2 — SP_Failed_Verification_MA |
