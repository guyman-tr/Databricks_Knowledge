# Column Lineage: Dealing_dbo.Dealing_ManipulationReport_RealStocks_CID

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_ManipulationReport_RealStocks_CID` |
| **UC Target** | N/A — Dealing_dbo not yet in Unity Catalog |
| **Primary Source** | `DWH_dbo.Dim_Position` (Trade.PositionTbl, etoroDB-REAL) |
| **ETL SP** | `Dealing_dbo.SP_ManipulationReport_RealStocks` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Regulation`, `DWH_dbo.Dim_Country`, `DWH_dbo.Dim_Manager`, `DWH_dbo.Dim_PlayerLevel` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Production (Trade.PositionTbl, etoroDB-REAL)
    ↓ DWH ETL → DWH_dbo.Dim_Position
    ↓ ─────────────────────────────────────────────────────────
DWH_dbo.Fact_SnapshotCustomer ← DWH ETL (customer snapshots)
DWH_dbo.Dim_Customer ← DWH ETL
    ↓
SP_ManipulationReport_RealStocks(@dd)
  → #All_Positions_Data (shared position universe with instrument-level table)
  → #TradesPerInstrument (instrument totals)
  → #TradesPerCIDAndInstrument (per-customer breakdowns)
  → #AvgDailyKPIs (30-day trailing averages)
  → #Flags (flagged customer×instrument rows, filter: PercentOfTotalTrades>0.5 OR PercentOfAvg30Days>2)
    ↓
Dealing_dbo.Dealing_ManipulationReport_RealStocks_CID
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | — | — | ETL-computed | `@dd` parameter | |
| CID | DWH_dbo.Dim_Customer | RealCID | passthrough | GROUP BY key in #TradesPerCIDAndInstrument | PII |
| UserName | DWH_dbo.Dim_Customer | UserName | passthrough | Direct from #All_Positions_Data | PII |
| Country | DWH_dbo.Fact_SnapshotCustomer → DWH_dbo.Dim_Country | CountryName | passthrough | Via #All_Positions_Data | PII |
| Manager | DWH_dbo.Fact_SnapshotCustomer → DWH_dbo.Dim_Manager | ManagerName | passthrough | Via #All_Positions_Data | PII |
| Regulation | DWH_dbo.Dim_Regulation | Name | passthrough | Via #All_Positions_Data; RegulationID IN (1,2,4) | |
| Club | DWH_dbo.Dim_PlayerLevel | Club/Name | passthrough | Via #All_Positions_Data | |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | passthrough | GROUP BY key | |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | passthrough | Via #All_Positions_Data join | |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | passthrough | Via #All_Positions_Data join | |
| NumberOfTrades | DWH_dbo.Dim_Position | PositionID | ETL-computed | `COUNT(CASE WHEN OpenDateID = @dd AND IsPartialCloseChild=0 THEN PositionID END)` per CID×Instrument | Customer's own trade count |
| AllTrades | DWH_dbo.Dim_Position | PositionID | ETL-computed | `COUNT(...)` from #TradesPerInstrument (all-customer total) | Denominator for PercentOfTotalTrades |
| AvgDailyOpen | DWH_dbo.Dim_Position | PositionID | ETL-computed | `OpenVolume30Days / 30` from #AvgDailyKPIs | 30-day trailing average daily opens |
| Volume | DWH_dbo.Dim_Position | Volume | ETL-computed | `SUM(Volume)` per CID×Instrument | USD volume; includes opens and closes |
| Units | DWH_dbo.Dim_Position | AmountInUnitsDecimal | ETL-computed | `SUM(AmountInUnitsDecimal)` per CID×Instrument | Shares count |
| PercentOfAvg30Days | — | — | ETL-computed | `NumberOfTrades / NULLIF(AvgDailyOpen, 0)` | Flagging condition 2: >2 = flagged |
| PercentOfTotalTrades | — | — | ETL-computed | `NumberOfTrades / NULLIF(AllTrades, 0)` | Flagging condition 1: >0.5 = flagged |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL metadata |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 10 |
| **ETL-computed** | 8 |
| **Total** | 18 |
