# Object lineage — BI_DB_dbo.Function_Revenue_TicketFee

> **Synapse**: Function (TVF). **Unity Catalog**: `_Not_Migrated` (no Generic Pipeline gold table / TVF mapping in UC for this object).

## Referenced objects (wiki §3 — Source Objects)

| Object | Schema | Notes |
|--------|--------|-------|
| BI_DB_Fact_Customer_Action_Position_Distribution | BI_DB_dbo | Referenced in function body |
| Function_Instrument_Snapshot_Enriched | BI_DB_dbo | Referenced in function body |
| Dim_Instrument | DWH_dbo | Referenced in function body |
| Dim_Range | DWH_dbo | Referenced in function body |
| Fact_History_Cost | DWH_dbo | Referenced in function body |
| Fact_SnapshotCustomer | DWH_dbo | Referenced in function body |

## Output contract

See wiki **§4. Output Columns** (table-valued functions) or **§4** scalar return note.

## Pipeline notes

- **Phase 10B (repo)**: Functions stay in-repo; UC External Lineage injection does not apply until a UC entity exists.
- **ALTER**: Companion `Function_Revenue_TicketFee.alter.sql` is a **comment-only stub** when UC Target is `_Not_Migrated` — `deploy-alter-dwh` must skip executable statements for these files.
