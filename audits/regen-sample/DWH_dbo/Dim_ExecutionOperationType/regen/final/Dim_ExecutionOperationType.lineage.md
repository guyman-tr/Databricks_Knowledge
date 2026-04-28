# Lineage — DWH_dbo.Dim_ExecutionOperationType

## Source Objects

| # | Source Object | Source Type | Relationship | Schema |
|---|--------------|-------------|--------------|--------|
| 1 | `HistoryCosts_Dictionary_ExecutionOperationType` | Staging Table | Direct source (via SP_Dictionaries_DL_To_Synapse) | DWH_staging |
| 2 | `SP_Dictionaries_DL_To_Synapse` | Stored Procedure | Writer SP (TRUNCATE + INSERT) | DWH_dbo |

## Column Lineage

| DWH Column | Source Object | Source Column | Transform | Tier |
|-----------|--------------|---------------|-----------|------|
| OperationTypeId | DWH_staging.HistoryCosts_Dictionary_ExecutionOperationType | Id | Rename: `[Id]` → `[OperationTypeId]` | Tier 2 |
| OperationType | DWH_staging.HistoryCosts_Dictionary_ExecutionOperationType | OperationType | Passthrough (no transform) | Tier 2 |
| UpdateDate | SP_Dictionaries_DL_To_Synapse | — | ETL-computed: `getdate()` at load time | Tier 2 |

## Notes

- No upstream wiki exists for `HistoryCosts.Dictionary.ExecutionOperationType` (production source).
- All columns are Tier 2 because the SP code traces the source, but no upstream wiki documentation is available to inherit from.
- The table is fully truncated and reloaded on each SP execution (no incremental load).
