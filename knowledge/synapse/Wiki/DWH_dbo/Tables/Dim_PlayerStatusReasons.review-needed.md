# DWH_dbo.Dim_PlayerStatusReasons -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all 3 DWH columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

- **Name is nullable**: Production `Name` column is varchar(50) NULL. In practice, are all 44 rows populated with non-null names? Or are there legitimately null-named reason codes in the live data?
- **ID=43 (Gap)**: The upstream wiki lists IDs 0-43 with the last entry being "Gap" (ID=43). This name is ambiguous -- what kind of "gap"? A data gap record? An account gap? Confirm business meaning.
- **Reason-to-SubReason mapping**: The valid Reason->SubReason combinations are only in production BackOffice.PlayerStatusReasonToSubReason. Should this mapping be replicated to DWH for analyst use? Currently analysts cannot determine valid sub-reasons from DWH alone.

## Structural Questions

- **No ID=0 sentinel**: Unlike Dim_PlayerStatus, Dim_PlayerLevel, etc., this table does NOT add an ETL-generated ID=0 row -- row 0 (None) comes directly from production. Is this intentional? Or is the SP omitting the sentinel INSERT because production already has ID=0?
- **ETL staleness**: UpdateDate = 2026-03-11 across all rows (8+ days stale as of 2026-03-19). Consistent with schema-wide SP_Dictionaries_DL_To_Synapse disruption -- confirm whether this ETL has been restored.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
