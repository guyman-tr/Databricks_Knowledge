# DWH_dbo.Dim_PhoneVerified -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all 3 columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

- **PhoneVerifiedName (ID=2) typo**: The value "ManualyVerified" (single 'l') is a production typo confirmed in both the upstream wiki and live DWH data. Is there a plan to correct this in production? If corrected upstream, the DWH will inherit the fix on next reload -- no DWH action needed.
- **ID=3 (Initiated) missing from upstream wiki data overview**: The upstream wiki's Data Overview table omits ID=3 (Initiated) -- it lists 0,1,2,4,5 only. The live DWH data confirms ID=3 exists. Upstream wiki may need updating.

## Structural Questions

- **ETL freshness**: UpdateDate shows 2026-03-11 (8 days stale as of 2026-03-19). Is the SP_Dictionaries_DL_To_Synapse scheduled run disrupted? Investigate DataLakeTableStatus.
- **Consumer scope**: Only DWH SPs referencing this table are Dim_Customer and Fact_SnapshotCustomer variants. Confirm no other Fact tables in the batch use PhoneVerifiedID.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
