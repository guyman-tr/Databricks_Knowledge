# Review Needed: BI_DB_dbo.BI_DB_Failed_Verification_MA

## Open Questions

1. **GCID NOT NULL in DDL but upstream says "NULL for older accounts"**: The DDL defines GCID as NOT NULL, but the upstream BI_DB_Operations_Onboarding_Flow_UserKPIs wiki (inherited from Customer.CustomerStatic) states GCID can be NULL for older accounts. The SP does not apply any ISNULL/COALESCE on GCID. If a customer with NULL GCID passes all WHERE filters, the INSERT would fail. Confirm whether this is an intentional exclusion (older accounts are outside the 24-month window) or a latent bug.

2. **ReasonNumber = 0 covers diverse reasons**: When the rejection reason text does not match any of the 22 hardcoded codes, ReasonNumber defaults to 0. This groups genuinely different reasons (Duplicate, Underage, High Risk Country, Corrupted File, SSN Card issues, Visa issues, POA - Business/Work Address, Not Needed, Other) under the same code. Marketing Automation workflows relying on ReasonNumber alone will lose granularity for these cases. Currently 96 rows (9.2%) have ReasonNumber=0.

3. **No downstream consumers found**: No views, SPs, or other tables in the SSDT project reference this table. Confirm whether the table is consumed by an external Marketing Automation system (e.g., Braze, Iterable) via direct query or export.

4. **@Date parameter unused**: The SP accepts a `@Date` parameter but does not reference it in any query — the 3-day lookback uses `GETDATE()` directly. The parameter may be a placeholder for future use or a convention from the batch orchestrator.

5. **GCID near-unique but not unique**: 1,034 distinct GCIDs across 1,039 rows. Five GCIDs appear more than once, likely due to matching both a POI and POA rejection reason in the hardcoded lookup. Consumers expecting one row per customer should be aware of this.

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 7 | GCID, CountryName, CurrentRegulation, RejectionReasonPOA, RejectionReasonPOI, NonVerificationReason, EV_MatchStatus |
| Tier 2 | 3 | ReasonNumber, RejectReasonName, UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
