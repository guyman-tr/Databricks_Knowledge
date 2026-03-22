# Lineage: Dealing_dbo.Dealing_NumberofPositionsOpened_Agg

## Source Tables
| Source | Role |
|--------|------|
| Dealing_dbo.Dealing_DealingDashboard_Clients | Direct source — GROUP BY aggregation |

## Column Lineage

| Target Column | Source Column | Transformation |
|---------------|--------------|----------------|
| DateID | Dealing_DealingDashboard_Clients.DateID | Direct pass-through |
| Date | Dealing_DealingDashboard_Clients.Date | Direct pass-through |
| InstrumentType | Dealing_DealingDashboard_Clients.InstrumentType | Direct pass-through (GROUP BY key) |
| Region | Dealing_DealingDashboard_Clients.Region | Direct pass-through (GROUP BY key) |
| NumberOfPositionsOpened | Dealing_DealingDashboard_Clients.NumberOfPositionsOpened | `SUM(dddc.NumberOfPositionsOpened)` |
| UpdateDate | — | `GETDATE()` at insert time |

## Upstream Lineage Chain
```
Dealing_DealingDashboard_Clients
  └─ BI_DB_dbo.BI_DB_PositionPnL (ultimate source)
       └─ Production Trading Platform
```

## Generic Pipeline
| Property | Value |
|----------|-------|
| Pipeline ID | Found in generic mapping |
| Datalake Path | Gold/sql_dp_prod_we/Dealing_dbo/Dealing_NumberofPositionsOpened_Agg/ |
| Copy Strategy | Config-based |
