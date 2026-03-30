# Object lineage — BI_DB_dbo.Function_DDR_Aggregation_MoM

> **Synapse**: Function (TVF). **Unity Catalog**: `_Not_Migrated` (no Generic Pipeline gold table / TVF mapping in UC for this object).

## Referenced objects (wiki §3 — Source Objects)

| Object | Schema | Notes |
|--------|--------|-------|
| BI_DB_DDR_Customer_Periodic_Status | BI_DB_dbo | Referenced in function body |
| BI_DB_V_DDR_MIMO | BI_DB_dbo | Referenced in function body |
| BI_DB_V_DDR_Revenue_Breakdown | BI_DB_dbo | Referenced in function body |
| BI_DB_V_DDR_Non_Revenue_Actions | BI_DB_dbo | Referenced in function body |
| BI_DB_V_DDR_PnL | BI_DB_dbo | Referenced in function body |
| BI_DB_V_DDR_AUM | BI_DB_dbo | Referenced in function body |

## Output contract

See wiki **§4. Output Columns** (table-valued functions) or **§4** scalar return note.

## Pipeline notes

- **Phase 10B (repo)**: Functions stay in-repo; UC External Lineage injection does not apply until a UC entity exists.
- **ALTER**: Companion `Function_DDR_Aggregation_MoM.alter.sql` is a **comment-only stub** when UC Target is `_Not_Migrated` — `deploy-alter-dwh` must skip executable statements for these files.
