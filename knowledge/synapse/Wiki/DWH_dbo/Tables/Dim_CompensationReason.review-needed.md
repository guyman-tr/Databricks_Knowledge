# DWH_dbo.Dim_CompensationReason - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns. All elements confirmed via upstream wiki and ETL SP code.

## Columns Needing Clarification

None.

## Structural Questions

- **IDs 5 and 130 absent**: IDs 5 and 130 do not exist in the DWH table. Confirm whether these were intentionally retired (deleted from production) or are gaps that should be investigated. If any historical fact rows reference these IDs they will NULL-out on JOIN.
- **IsTaxable and IsCashflowForGain dropped**: These production flags classify whether a compensation reason has tax implications and whether it appears as a cashflow gain. DWH does not carry them. Should they be added for tax reporting and financial reconciliation analytics?
- **IsActive dropped**: Production has an IsActive flag. DWH includes all 133 rows regardless. Analysts filtering to "current" reasons cannot do so from this dimension alone - they would need to join back to production or maintain a separate active-reason list.
- **DisplayName dropped**: Production has DisplayName (an alternative display label used in some BO UIs). DWH only has Name. Confirm whether DisplayName is needed for any DWH consumer reporting.
- **DWHCompensationID redundancy**: DWHCompensationID = CompensationReasonID (same value, different name). This column adds no information. Is it retained for legacy downstream compatibility, or can it be deprecated?
- **Obsolete category (ID=23)**: The "Obsolete" root (ID=23) and its children (e.g., ID=2 "Position lost") are present in DWH for historical record integrity. Confirm that analytics consumers are aware these reasons should not be treated as valid current-period compensation types.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
