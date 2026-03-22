---
object: Dealing_dbo.Dealing_DailyVariableSpread
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_DailyVariableSpread

## ETL Chain

```
DWH_dbo.Fact_CustomerAction
  Filters: PlayerLevelID ≠ 4, IsValidCustomer = 1, LabelID NOT IN (26, 30)
  → SP_DailyVariableSpread (@Date)
    GROUP BY FullDate × HedgeServerID × InstrumentType × InstrumentName
    SUM(Commission, FullCommission, RollOverFee)
    → Dealing_dbo.Dealing_DailyVariableSpread
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics.

## Column Lineage

| Column | Source |
|--------|--------|
| FullDate | SP parameter @Date |
| DateID | DWH_dbo.Dim_Date join on FullDate |
| HedgeServerID | DWH_dbo.Fact_CustomerAction |
| InstrumentType | DWH_dbo.Fact_CustomerAction |
| InstrumentName | DWH_dbo.Fact_CustomerAction |
| Commissions | SUM(DWH_dbo.Fact_CustomerAction.Commission) |
| FullCommissions | SUM(DWH_dbo.Fact_CustomerAction.FullCommission) |
| RollOverFee | SUM(DWH_dbo.Fact_CustomerAction.RollOverFee) |
| UpdateDate | GETDATE() at SP execution time |

## Refresh

- **OpsDB tracked**: ✅ Yes — Priority 0, SB_Daily
- **Pipeline status**: ✅ ACTIVE (2026-03-10)
