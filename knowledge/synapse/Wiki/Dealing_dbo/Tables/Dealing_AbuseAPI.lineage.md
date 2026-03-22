# Column Lineage: Dealing_dbo.Dealing_AbuseAPI

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_AbuseAPI` |
| **UC Target** | N/A — Dealing_dbo not yet in Unity Catalog |
| **Primary Source** | `DWH_dbo.Dim_Position` (Trade.PositionTbl, etoroDB-REAL) |
| **ETL SP** | `Dealing_dbo.SP_AbuseAPI` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Dim_Country`, `DWH_dbo.Dim_Date`, `BI_DB_dbo.BI_DB_PositionPnL` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Production (Trade.PositionTbl, etoroDB-REAL)
    ↓ DWH ETL → DWH_dbo.Dim_Position
    ↓ ─────────────────────────────────────────────────────────
BI_DB_dbo.BI_DB_PositionPnL ← BI_DB ETL (open position mark-to-market PnL for YTD calc)
DWH_dbo.Dim_Date ← Reference (date spine, ensures sentinel row)
    ↓
SP_AbuseAPI(@Date) — burst detection pipeline
  → #base (positions closed on @Date, ≤24h duration)
  → #minimum3 (CIDs with ≥3 positions per InstrumentType×OpenDate)
  → #msdiff (LAG-computed millisecond gaps between consecutive opens)
  → #lead (LEAD-computed forward gaps and next position IDs)
  → #OneSec (3-position bursts with combined gap ≤1000ms)
  → #DailyNetProfit (per CID×InstrumentType daily PnL sum)
  → #Final (flagged positions: in burst AND DailyNetProfit ≥ $5000)
  → #CID → #a + #b → #YTD (YTD Zero/Commission for flagged CIDs)
  → LEFT JOIN Dim_Date (sentinel insert)
    ↓
Dealing_dbo.Dealing_AbuseAPI
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| CloseDate | DWH_dbo.Dim_Date | FullDate | passthrough | `@Date` via LEFT JOIN Dim_Date | NULL when sentinel (no matches) |
| OpenDate | DWH_dbo.Dim_Position | OpenOccurred | ETL-computed | `CAST(OpenOccurred AS DATE)` | |
| PositionID | DWH_dbo.Dim_Position | PositionID | passthrough | From #Final; one of PositionID/PositionID2/PositionID3 | |
| CID | DWH_dbo.Dim_Position | CID | passthrough | GROUP BY key | PII |
| Country | DWH_dbo.Dim_Country | Name | passthrough | Via Dim_Customer.CountryID | PII |
| Region | DWH_dbo.Dim_Country | Region | passthrough | Via Dim_Customer.CountryID | PII |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | passthrough | Direct | |
| Instrument | DWH_dbo.Dim_Instrument | Name | passthrough | Direct join | Internal instrument name |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | passthrough | Via Dim_Instrument join | Burst grouped by InstrumentType |
| OpenOccurred | DWH_dbo.Dim_Position | OpenOccurred | passthrough | Direct | Millisecond-precision for burst detection |
| CloseOccurred | DWH_dbo.Dim_Position | CloseOccurred | passthrough | Direct | |
| NetProfit | DWH_dbo.Dim_Position | NetProfit | passthrough | Direct | |
| DailyNetProfit | DWH_dbo.Dim_Position | NetProfit | ETL-computed | `SUM(NetProfit)` per CID×InstrumentType×OpenDate | From #DailyNetProfit temp table |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL metadata |
| FullCommissionOnClose | DWH_dbo.Dim_Position | FullCommissionOnClose | passthrough | Direct | |
| Zero | DWH_dbo.Dim_Position | NetProfit, FullCommissionOnClose | ETL-computed | `NetProfit + FullCommissionOnClose` | Position-level zero PnL |
| YTD_Zero | DWH_dbo.Dim_Position + BI_DB_PositionPnL | NetProfit, FullCommission*, PositionPnL | ETL-computed | `SUM(PnL + Commission)` YTD per CID; open positions use BI_DB_PositionPnL.PositionPnL | Handles pre-year positions separately in #b |
| YTD_Commission | DWH_dbo.Dim_Position | FullCommissionOnClose, FullCommissionByUnits | ETL-computed | `SUM(commission)` YTD; closed = FullCommissionOnClose, open = FullCommissionByUnits | |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 10 |
| **ETL-computed** | 8 |
| **Total** | 18 |
