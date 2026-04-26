# Lineage: BI_DB_dbo.BI_DB_UK_CommissionReport_byLeverage

**Generated**: 2026-04-22 | **Writer SP**: SP_M_UK_CommissionReport_byLeverage | **Frequency**: Monthly

## ETL Source Chain

```
DWH_dbo.Fact_CustomerAction  (ActionTypeID 1-6, IsValidCustomer=1, DateID in month)
  + DWH_dbo.Dim_Position      (JOIN on PositionID → RegulationIDOnOpen)
  + DWH_dbo.Dim_Customer      (JOIN on RealCID → CountryID)
  + DWH_dbo.Dim_Country       (JOIN on CountryID → Region)
  + DWH_dbo.Dim_Regulation    (JOIN on RegulationIDOnOpen → Name)
  + DWH_dbo.Dim_Instrument    (JOIN on InstrumentID → InstrumentType)
  + DWH_dbo.Dim_ActionType    (JOIN on ActionTypeID — filter only)
    |-- SP_M_UK_CommissionReport_byLeverage @dd DATE ---|
    v
BI_DB_dbo.BI_DB_UK_CommissionReport_byLeverage
  (UC: Not Migrated)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|--------------|-----------|------|
| 1 | CalendarYear | DWH_dbo.Fact_CustomerAction | Occurred | YEAR(Occurred) — GROUP BY key | Tier 2 |
| 2 | CalendarMonth | DWH_dbo.Fact_CustomerAction | Occurred | MONTH(Occurred) — GROUP BY key | Tier 2 |
| 3 | Region | DWH_dbo.Dim_Country | Region | Passthrough via JOIN (Dim_Customer→Dim_Country on CountryID) | Tier 1 |
| 4 | Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough via JOIN (Dim_Position.RegulationIDOnOpen→Dim_Regulation.ID) | Tier 1 |
| 5 | Leverage | DWH_dbo.Fact_CustomerAction | Leverage | Passthrough — GROUP BY key | Tier 1 |
| 6 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough via JOIN on InstrumentID | Tier 1 |
| 7 | Commission | DWH_dbo.Fact_CustomerAction | FullCommissionOnClose, FullCommissionByUnits | SUM: ActionTypeID IN(4,5,6)→FullCommissionOnClose-FullCommissionByUnits; IN(1,2,3)→FullCommissionByUnits | Tier 2 |
| 8 | Trades | DWH_dbo.Fact_CustomerAction | — | COUNT(1) per group (one row per action) | Tier 2 |
| 9 | UpdateDate | — | — | GETDATE() at ETL run time | Tier 2 |
| 10 | EOMonth | DWH_dbo.Fact_CustomerAction | Occurred | EOMONTH(Occurred) — GROUP BY key | Tier 2 |

## Notes

- **ActionTypeID semantics**: IN(4,5,6) = close/expiry/rollover actions; IN(1,2,3) = open/limit/stop actions. Different commission formulas per stream.
- **UNION then aggregate**: Two sub-queries UNIONed before outer GROUP BY to combine commission streams into single monthly grain.
- **RegulationIDOnOpen**: Uses regulation at position open time (not close), sourced from Dim_Position.
