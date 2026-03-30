# Object lineage — BI_DB_dbo.Function_Trading_Volume_PositionLevel

> **Synapse**: Function (TVF). **Unity Catalog**: `_Not_Migrated` (no Generic Pipeline gold table / TVF mapping in UC for this object).

## Referenced objects (wiki §3 — Source Objects)

| Object | Schema | Notes |
|--------|--------|-------|
| Dim_Position | DWH_dbo | Referenced in function body |
| Fact_SnapshotCustomer | DWH_dbo | Referenced in function body |
| Dim_Range | DWH_dbo | Referenced in function body |
| Dim_Instrument | DWH_dbo | Referenced in function body |
| Function_Instrument_Snapshot_Enriched | BI_DB_dbo | Referenced in function body |
| V_C2P_Positions | BI_DB_dbo | Referenced in function body |
| BI_DB_CopyFund_Positions | BI_DB_dbo | Referenced in function body |
| BI_DB_RecurringInvestment_Positions | BI_DB_dbo | Referenced in function body |
| BI_DB_Positions_Opened_From_IBAN | BI_DB_dbo | Referenced in function body |
| BI_DB_Positions_Closed_To_IBAN | BI_DB_dbo | Referenced in function body |

## Output contract

See wiki **§4. Output Columns** (table-valued functions) or **§4** scalar return note.

## Pipeline notes

- **Phase 10B (repo)**: Functions stay in-repo; UC External Lineage injection does not apply until a UC entity exists.
- **ALTER**: Companion `Function_Trading_Volume_PositionLevel.alter.sql` is a **comment-only stub** when UC Target is `_Not_Migrated` — `deploy-alter-dwh` must skip executable statements for these files.
