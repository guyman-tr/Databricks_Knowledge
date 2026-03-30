# Object lineage — BI_DB_dbo.Function_Population_Portfolio_Only

> **Synapse**: Function (TVF). **Unity Catalog**: `_Not_Migrated` (no Generic Pipeline gold table / TVF mapping in UC for this object).

## Referenced objects (wiki §3 — Source Objects)

| Object | Schema | Notes |
|--------|--------|-------|
| Dim_Position | DWH_dbo | Referenced in function body |
| Dim_Instrument | DWH_dbo | Referenced in function body |
| Dim_Mirror | DWH_dbo | Referenced in function body |
| External_Sodreconciliation_apex_EXT981_BuyPowerSummary | BI_DB_dbo | Referenced in function body |
| External_USABroker_Apex_Options | BI_DB_dbo | Referenced in function body |
| Dim_Customer | DWH_dbo | Referenced in function body |
| Function_Population_Active_Traders | BI_DB_dbo | Referenced in function body |

## Output contract

See wiki **§4. Output Columns** (table-valued functions) or **§4** scalar return note.

## Pipeline notes

- **Phase 10B (repo)**: Functions stay in-repo; UC External Lineage injection does not apply until a UC entity exists.
- **ALTER**: Companion `Function_Population_Portfolio_Only.alter.sql` is a **comment-only stub** when UC Target is `_Not_Migrated` — `deploy-alter-dwh` must skip executable statements for these files.
