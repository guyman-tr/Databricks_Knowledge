# Column Lineage: Dealing_dbo.Dealing_Market_Manipulation_Report_FCA

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Market_Manipulation_Report_FCA` |
| **UC Target** | N/A — Dealing_dbo not yet in Unity Catalog |
| **Primary Source** | `DWH_dbo.Dim_Position` (Trade.PositionTbl, etoroDB-REAL) |
| **ETL SP** | `Dealing_dbo.SP_Market_Manipulation_Report_FCA` |
| **Secondary Sources** | `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Range`, `DWH_dbo.V_Liabilities`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Dim_Country`, `DWH_dbo.Dim_Manager`, `DWH_dbo.Dim_Regulation`, `DWH_dbo.Dim_PlayerLevel`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted`, `BI_DB_dbo.BI_DB_PositionPnL` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Production (Trade.PositionTbl, etoroDB-REAL)
    ↓ DWH ETL → DWH_dbo.Dim_Position
    ↓ ─────────────────────────────────────────────────────────
DWH_dbo.Fact_SnapshotCustomer ← DWH ETL (customer snapshots — used for HISTORICAL regulation at @dd)
DWH_dbo.V_Liabilities ← DWH ETL
BI_DB_dbo.BI_DB_PositionPnL ← BI_DB ETL
DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted ← Price feed
    ↓
SP_Market_Manipulation_Report_FCA(@dd) — FCA-scoped leaderboard (DWHRegulationID=2)
  → #temp (FCA customer universe via Fact_SnapshotCustomer + Dim_Range for historical accuracy)
  → #positions, #CIDs, #Final_PnLs (PnL aggregates — same as main SP)
  → #prices, #All_Positions, #Nop_* (NOP — FCA customers only)
  → #10Min (short-duration profitable trades — FCA customers only)
  → #Final (UNION ALL: ~18 KPI segments, NO GURU segments)
    ↓
Dealing_dbo.Dealing_Market_Manipulation_Report_FCA
```

## Column Lineage

Column lineage is identical to `Dealing_Market_Manipulation_Report` with two differences:

1. **Regulation source**: From `Fact_SnapshotCustomer` → `Dim_Range` → `Dim_Regulation` (historical snapshot at @dd), not `Dim_Customer.RegulationID` (current). Always 'FCA' in output.
2. **No GURU-source columns**: PnL for GURU KPIs does not exist in this table.

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| Date | — | — | `@dd` parameter | |
| KPI | — | — | String literal per UNION segment | No GURU_* values |
| Equity | DWH_dbo.V_Liabilities | Liabilities, ActualNWA | `SUM(Liabilities + ActualNWA)` | |
| PnL | DWH_dbo.Dim_Position / BI_DB_PositionPnL | NetProfit / PositionPnL | Period-scoped SUM | |
| Gain | DWH_dbo.Dim_Position | NetProfit, Amount | `SUM(PnL) / SUM(InvestedAmount)` | _Gain KPIs only |
| InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | passthrough | NOP KPIs only |
| PositionID | — | — | Always NULL | Legacy column |
| NOP | Dim_Position + Dim_GetSpreadedPriceCandle60MinSplitted | AmountInUnitsDecimal, price, IsBuy | `SUM(units × price × direction × FX)` | FCA customers only |
| RN | — | — | RANK() or ROW_NUMBER() per KPI | |
| CID | DWH_dbo.Dim_Customer | RealCID | passthrough | PII; FCA only |
| UserName | DWH_dbo.Dim_Customer | UserName | passthrough | PII |
| Club | DWH_dbo.Dim_PlayerLevel | Name | passthrough | PII |
| Desk | DWH_dbo.Dim_Country | Desk | passthrough | PII |
| Region | DWH_dbo.Dim_Country | Region | passthrough | PII |
| Country | DWH_dbo.Dim_Country | Name | passthrough | PII |
| Manager | DWH_dbo.Dim_Manager | FirstName + LastName | concat | PII |
| Regulation | DWH_dbo.Fact_SnapshotCustomer → Dim_Regulation | Name | passthrough | Always 'FCA'; via snapshot for historical accuracy |
| UpdateDate | — | — | `GETDATE()` | ETL metadata |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 9 |
| **ETL-computed** | 7 |
| **Legacy/NULL** | 1 |
| **Concat** | 1 |
| **Total** | 18 |
