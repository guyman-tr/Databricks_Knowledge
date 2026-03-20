# DWH_dbo.Dim_PlayerStatusSubReasons -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all 3 DWH columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

- **All columns nullable including PK**: PlayerStatusSubReasonID, PlayerStatusSubReasonName, and UpdateDate are ALL defined as NULL in the DDL. PlayerStatusSubReasonID is the clustered index key -- a nullable PK is unusual. Is this intentional or a DDL oversight? Will Synapse allow NULL in a clustered index column?
- **IDs 83+**: Upstream wiki shows 83 rows (0-82) as of 2026-03-13. Have any new sub-reasons been added since then? The live DWH max is also 82, but the ETL is stale (2026-03-11). Production may have grown.
- **Reason-SubReason mapping in DWH**: The valid Reason->SubReason combinations are only in production BackOffice.PlayerStatusReasonToSubReason. Should this mapping table be brought into DWH? Currently analysts cannot filter to valid sub-reasons for a given reason without joining to production.

## Structural Questions

- **Column rename**: Production `Name` -> DWH `PlayerStatusSubReasonName`. This is inconsistent with Dim_PlayerStatusReasons which keeps `Name` as `Name`. Was the rename intentional to avoid ambiguity in wide JOINs?
- **No ID=0 sentinel**: Row 0 (None) comes from production, consistent with Dim_PlayerStatusReasons.
- **ETL staleness**: UpdateDate = 2026-03-11 across all rows (8+ days stale as of 2026-03-19). Consistent with schema-wide SP_Dictionaries_DL_To_Synapse disruption.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
