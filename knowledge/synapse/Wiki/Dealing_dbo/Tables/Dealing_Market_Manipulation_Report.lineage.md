# Column Lineage: Dealing_dbo.Dealing_Market_Manipulation_Report

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Market_Manipulation_Report` |
| **UC Target** | N/A — Dealing_dbo not yet in Unity Catalog |
| **Primary Source** | `DWH_dbo.Dim_Position` (Trade.PositionTbl, etoroDB-REAL) |
| **ETL SP** | `Dealing_dbo.SP_Market_Manipulation_Report` |
| **Secondary Sources** | `DWH_dbo.V_Liabilities`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Dim_Country`, `DWH_dbo.Dim_Manager`, `DWH_dbo.Dim_Regulation`, `DWH_dbo.Dim_PlayerLevel`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted`, `BI_DB_dbo.BI_DB_PositionPnL`, `BI_DB_dbo.BI_DB_CopyDailyData`, `BI_DB_dbo.BI_DB_CIDFirstDates` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Production (Trade.PositionTbl, etoroDB-REAL)
    ↓ DWH ETL → DWH_dbo.Dim_Position
    ↓ ─────────────────────────────────────────────────────────
DWH_dbo.V_Liabilities ← DWH ETL (customer equity snapshots)
BI_DB_dbo.BI_DB_PositionPnL ← BI_DB ETL (mark-to-market open PnL)
BI_DB_dbo.BI_DB_CopyDailyData ← BI_DB ETL (Popular Investor copy PnL)
DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted ← Price feed (60-min candles)
    ↓
SP_Market_Manipulation_Report(@dd) — multi-segment leaderboard computation
  → #temp / #Equity (customer universe + equity ranking)
  → #positions (position universe with PnL and duration)
  → #CIDs / #Final_PnLs (customer PnL aggregates + rankings)
  → #prices / #All_Positions / #Nop_* (NOP computation)
  → #10Min (short-duration profitable trades)
  → #GuruPnL / #Guru_PnL_Final (Popular Investor rankings)
  → #Final (UNION ALL of 20+ KPI segments)
    ↓
Dealing_dbo.Dealing_Market_Manipulation_Report
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | — | — | ETL-computed | `@dd` parameter | |
| KPI | — | — | ETL-computed | String literal per UNION segment | 20+ distinct values |
| Equity | DWH_dbo.V_Liabilities | Liabilities, ActualNWA | ETL-computed | `ISNULL(Liabilities,0) + ISNULL(ActualNWA,0)` for DateID=@dd | NULL for NOP KPIs |
| PnL | DWH_dbo.Dim_Position | NetProfit / BI_DB_PositionPnL.PositionPnL | ETL-computed | Period-scoped SUM(PnL); for open positions uses BI_DB_PositionPnL.PositionPnL; for GURU uses CopyPnL delta | Period varies by KPI |
| Gain | DWH_dbo.Dim_Position | NetProfit, Amount | ETL-computed | `SUM(PnL) / SUM(InvestedAmount)` — realized gain rate; NULLIF to avoid divide-by-zero | Populated for _Gain KPIs only |
| InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | passthrough | Direct from #All_Positions join | Populated for NOP KPIs only |
| PositionID | — | — | — | Always NULL in current SP | Legacy column |
| NOP | DWH_dbo.Dim_Position, Dim_GetSpreadedPriceCandle60MinSplitted | AmountInUnitsDecimal, IsBuy, AskLast/BidLast | ETL-computed | `SUM(units × price × (2×IsBuy-1) × FX_to_USD)` for open positions | Multi-currency FX conversion applied |
| RN | — | — | ETL-computed | `RANK()` or `ROW_NUMBER()` within KPI segment | Sort key varies by KPI |
| CID | DWH_dbo.Dim_Customer | RealCID | passthrough | GROUP BY key | NULL for instrument-only NOP rows; PII |
| UserName | DWH_dbo.Dim_Customer | UserName | passthrough | Direct join | PII |
| Club | DWH_dbo.Dim_PlayerLevel | Name | passthrough | Via Dim_Customer.PlayerLevelID | PII |
| Desk | DWH_dbo.Dim_Country | Desk | passthrough | Via Dim_Customer.CountryID | PII |
| Region | DWH_dbo.Dim_Country | Region | passthrough | Via Dim_Customer.CountryID | PII |
| Country | DWH_dbo.Dim_Country | Name | passthrough | Via Dim_Customer.CountryID | PII |
| Manager | DWH_dbo.Dim_Manager | FirstName + LastName | ETL-computed | `FirstName + ' ' + LastName` concat | PII |
| Regulation | DWH_dbo.Dim_Regulation | Name | passthrough | Via Dim_Customer.RegulationID | |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL metadata |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 9 |
| **ETL-computed** | 8 |
| **Legacy/NULL** | 1 |
| **Total** | 18 |
