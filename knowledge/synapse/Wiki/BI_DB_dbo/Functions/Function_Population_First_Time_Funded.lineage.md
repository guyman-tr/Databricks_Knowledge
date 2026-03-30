# Object lineage — BI_DB_dbo.Function_Population_First_Time_Funded

> **Synapse**: Function (TVF). **Unity Catalog**: `_Not_Migrated` (no Generic Pipeline gold table / TVF mapping in UC for this object).

## Referenced objects (wiki §3 — Source Objects)

| Object | Schema | Notes |
|--------|--------|-------|
| Fact_CustomerAction | DWH_dbo | Referenced in function body |
| Dim_Customer | DWH_dbo | Referenced in function body |
| BI_DB_DDR_Fact_MIMO_AllPlatforms | BI_DB_dbo | Referenced in function body |
| Dim_FTDPlatform | DWH_dbo | Referenced in function body |
| Fact_SnapshotCustomer | DWH_dbo | Referenced in function body |
| Dim_Range | DWH_dbo | Referenced in function body |
| Dim_Position | DWH_dbo | Referenced in function body |
| Function_Revenue_OptionsPlatform | BI_DB_dbo | Referenced in function body |

## Output contract

See wiki **§4. Output Columns** (table-valued functions) or **§4** scalar return note.

## Pipeline notes

- **Phase 10B (repo)**: Functions stay in-repo; UC External Lineage injection does not apply until a UC entity exists.
- **ALTER**: Companion `Function_Population_First_Time_Funded.alter.sql` is a **comment-only stub** when UC Target is `_Not_Migrated` — `deploy-alter-dwh` must skip executable statements for these files.
