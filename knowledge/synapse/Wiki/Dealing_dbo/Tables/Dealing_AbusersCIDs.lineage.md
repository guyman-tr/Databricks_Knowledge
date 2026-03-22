# Column Lineage: Dealing_dbo.Dealing_AbusersCIDs

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_AbusersCIDs` |
| **UC Target** | N/A — Dealing_dbo not yet in Unity Catalog |
| **Primary Source** | `DWH_dbo.Dim_Position` (Trade.PositionTbl, etoroDB-REAL) |
| **ETL SP** | `Dealing_dbo.SP_AbusersCIDs` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Date` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Production (Trade.PositionTbl, etoroDB-REAL)
    ↓ DWH ETL → DWH_dbo.Dim_Position
    ↓ ─────────────────────────────────────────────────────────
DWH_dbo.Dim_Date ← Reference (sentinel row)
    ↓
SP_AbusersCIDs(@Date) — short-duration abuse detection
  → #PositionsData (stocks, <10 min, manual close, opened @Date + PercentagePriceChange)
  → #Profit (per CID×Instrument aggregates: SuccessRate, TotalNetProfit, counts)
  → #RelevantCIDs (filter: PositiveProfit≥4, SuccessRate≥0.8, TotalNetProfit≥100, PriceChangeHigherThan1Percent≥4)
  → #AllData (join back to get InstrumentName)
  → #Date + #TotalTable (sentinel via LEFT JOIN Dim_Date)
    ↓
Dealing_dbo.Dealing_AbusersCIDs
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | DWH_dbo.Dim_Date | FullDate | passthrough | `@Date` via LEFT JOIN sentinel | NULL on empty days |
| CID | DWH_dbo.Dim_Position | CID | passthrough | GROUP BY key | PII |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | passthrough | GROUP BY key | Stocks only (InstrumentTypeID=5) |
| InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | passthrough | Direct join | |
| TotalNetProfit | DWH_dbo.Dim_Position | NetProfit | ETL-computed | `SUM(NetProfit)` per CID×InstrumentID | Filter: ≥$100 |
| PositiveProfit | DWH_dbo.Dim_Position | NetProfit | ETL-computed | `COUNT(CASE WHEN NetProfit > 0 THEN 1 END)` | Filter: ≥4 |
| TotalTrades | DWH_dbo.Dim_Position | PositionID | ETL-computed | `COUNT(*)` per CID×InstrumentID | Short-duration stocks only |
| SuccessRate | DWH_dbo.Dim_Position | NetProfit | ETL-computed | `SUM(CASE WHEN NetProfit>0 THEN 1.0 END) / COUNT(*)` | Filter: ≥0.8 |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL metadata |
| PriceChangeHigherThan1Percent | DWH_dbo.Dim_Position | InitForexRate, EndForexRate | ETL-computed | `COUNT(CASE WHEN ABS((End-Init)/Init) >= 0.01 THEN 1 END)` | Filter: ≥4 |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 4 |
| **ETL-computed** | 6 |
| **Total** | 10 |
