# DWH_dbo.Fact_History_Cost — Production Lineage Map

## Source Resolution

| Property | Value |
|----------|-------|
| **Production Database** | HistoryCosts |
| **Production Schema** | History |
| **Production Table** | Costs |
| **Staging** | DWH_staging.HistoryCosts_History_Costs |
| **Ext Table** | DWH_dbo.Ext_History_Cost |
| **ETL SPs** | SP_Fact_History_Cost_DL_To_Synapse → SP_Fact_History_Cost |

## Column Lineage

All columns are direct passthrough from `DWH_staging.HistoryCosts_History_Costs` except:

| # | DWH Column | Source | Transform |
|---|-----------|--------|-----------|
| 24 | DateID | Occurred | CONVERT(INT, CONVERT(VARCHAR(10), Occurred, 112)) |
| 25 | UpdateDate | Computed | GETDATE() |

All other 23 columns: direct passthrough from staging, no transformation.
