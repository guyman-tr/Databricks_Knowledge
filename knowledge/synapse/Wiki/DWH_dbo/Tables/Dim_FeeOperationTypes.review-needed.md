# DWH_dbo.Dim_FeeOperationTypes - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None. All columns resolved to Tier 2 (SP code).

## Columns Needing Clarification

- **ETL bug remediation**: The SP_Dictionaries_DL_To_Synapse INSERT at ~line 1404 has no preceding TRUNCATE. Fix: add `TRUNCATE TABLE [DWH_dbo].[Dim_FeeOperationTypes]` before the INSERT block. After SP fix, a one-time manual truncate is needed to clear 897-3=894 accumulated duplicate rows.
- **ROUND_ROBIN distribution**: Same anomaly as Dim_ExecutionOperationType and Dim_CalculationType. For a 3-row table, REPLICATE would eliminate data movement on joins. Was ROUND_ROBIN intentional for these HistoryCosts section tables?
- **FeeOperationTypes vs FeeOperationType**: The source table is `etoro.Dictionary.FeeOperationTypes` (plural) while the DWH table is `Dim_FeeOperationTypes` (plural). Most other Dim_ tables are singular. Was the plural name intentional?
- **Fact_History_Cost consumer**: Documentation shows `Fact_History_Cost (pending)` as the expected FK consumer. Confirm that FeeOperationTypeID in that fact table references this dimension.

## Structural Questions

- **nvarchar(max) for FeeOperationTypeName**: Values are 3-5 character strings (Open, Close, All). nvarchar(max) is heavily oversized. Was this inherited from the source schema or intentional?
- **UpdateDate NOT NULL constraint**: Unusual for a DWH dictionary table. Consistent with Dim_ExecutionOperationType (both from HistoryCosts section of SP_Dictionaries). Was NOT NULL added to prevent nulls during the INSERT-only accumulation or was it inherited from source?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
