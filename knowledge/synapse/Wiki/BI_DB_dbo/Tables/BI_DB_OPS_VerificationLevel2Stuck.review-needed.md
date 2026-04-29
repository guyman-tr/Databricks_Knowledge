# BI_DB_dbo.BI_DB_OPS_VerificationLevel2Stuck — Review Needed

## Tier 4 Items

None — all columns resolved to Tier 1 or Tier 2.

## Questions for Reviewer

1. **DesignatedRegulation vs Regulation**: The SP joins Dim_Regulation twice — once on DesignatedRegulationID and once on RegulationID. The final WHERE filter uses DesignatedRegulation (not Regulation). Confirm which regulation field drives the actual compliance decision.
2. **SSN verification for FinCEN**: The SP checks for DocumentTypeID=22 (SSN Card) OR US + EV Verified. Is this the complete set of SSN verification paths?
3. **FINRAONLY added 2025-01-13**: The change history mentions "FinrsOnly" (typo for FINRAONLY). Is this regulation still active and should it use the same rules as FinCEN?
4. **VerificationLevel2Date from CIDFirstDates**: This is LEFT JOINed — some customers may have NULL VerificationLevel2Date. Is this expected for customers who were manually promoted?

## Corrections Applied

- None needed — DDL matches 23 columns exactly.

## Tier Summary

- **Tier 1 (11 columns)**: CID, GCID, RegistrationDate, DesignatedRegulation, Country, VerificationLevelID, PhoneVerifiedName, IsEmailVerified, PlayerStatus, DocumentStatusName, Regulation
- **Tier 2 (12 columns)**: VerificationLevel2Date, KYCFLow, Age, EvMatchStatusName, ScreeningStatus, ScreeningStatusCheck, EmailVerifiedCheck, EVorDocsVerified, NoActiveAlertsCheck, SelfieCheck, ElderlyCheck, UpdateDate
