# DWH_dbo.Dim_ActionType — Column Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Evidence |
|---|--------------|-------------|-------------|----------|
| 1 | Generic Pipeline (external source) | External Load | Writer | DWH_Migration.Dim_ActionType staging table; Override copy strategy, daily |
| 2 | DWH_dbo.Fact_CustomerAction | Table | Reader (FK) | JOINs on ActionTypeID |
| 3 | DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse | Stored Procedure | Reader | JOINs Dim_ActionType for CategoryID filtering |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|-----------|--------------|--------------|-----------|------|
| 1 | ActionTypeID | Unknown (external) | — | Direct load via Generic Pipeline | Tier 3 |
| 2 | Name | Unknown (external) | — | Direct load via Generic Pipeline | Tier 3 |
| 3 | UpdateDate | Unknown (external) | — | Direct load via Generic Pipeline | Tier 3 |
| 4 | InsertDate | Unknown (external) | — | Direct load via Generic Pipeline | Tier 3 |
| 5 | Category | Unknown (external) | — | Direct load via Generic Pipeline | Tier 3 |
| 6 | CategoryID | Unknown (external) | — | Direct load via Generic Pipeline | Tier 3 |

## Notes

- No writer SP exists in DWH_dbo for this table.
- Data is loaded via DWH_Migration staging table (varchar-typed columns cast to target types).
- No upstream wiki was resolvable. `_no_upstream_found.txt` marker present.
- Production origin is unknown — likely a manually-maintained or application-managed lookup table from the production trading platform.
