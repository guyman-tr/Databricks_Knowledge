# Lineage: BI_DB_dbo.BI_DB_LTV_Revenue_Multipliers

## Source Chain

| Hop | Object | Type | Role |
|-----|--------|------|------|
| 0 | BI_DB_LTV_Revenue_Multipliers | Synapse Table | Documentation target — multiplier lookup table |
| 1 | SP_M_LTV_Multipliers | Synapse SP | Primary writer — monthly DELETE + INSERT |
| 2 | BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData | Synapse Table | All computations: actual revenue milestones, seniority, activity state |

## T1 Copy Verification

No T1 columns. All columns are SP-computed statistical aggregates. No upstream production wiki applicable.

## Upstream Production Sources

| Column(s) | Production Source | Via |
|-----------|------------------|-----|
| All ratio columns (RatioSnapshotTo*, Ratio*) | BI_DB_CID_MonthlyPanel_FullData | SUM aggregations per (Seniority × MonthsSinceLastActive) bucket |
| Date | ETL run date parameter | @date |
| UpdateDate | ETL | GETDATE() |

## UC Target

`_Not_Migrated` — no entry found in `main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables`. Internal lookup table; not a lake export candidate.
