# Column Lineage: BI_DB_dbo.BI_DB_ClusteringDailyPrepData

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_ClusteringDailyPrepData` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `BI_DB_dbo.BI_DB_PositionPnL` (daily position P&L) + `DWH_dbo.Dim_Position` + `DWH_dbo.Dim_Mirror` |
| **ETL SP** | `SP_ClusteringDailyPrepData` |
| **Secondary Sources** | `Fact_FirstCustomerAction`, `Fact_SnapshotCustomer`, `Dim_Range`, `Dim_Customer`, `Dim_Instrument`, `DWH_CIDsDailyRisk` |
| **Generated** | 2026-03-28 |

## Lineage Chain

```
DWH_dbo.Fact_FirstCustomerAction (first deposit/buy dates)
DWH_dbo.Fact_SnapshotCustomer (V3 verification status via Dim_Range)
    │
    └─ #CIDs: V3 customers whose seniority is divisible by 30 (30-day cycle)
        │
        ├── #DimPosition: Dim_Position (non-mirror, last 2 years)
        │   ├── #InvestingPositions: Indices/Stocks/ETF at leverage 1-2
        │   ├── #Mirrors: Dim_Mirror (copy-trading positions)
        │   ├── #Final: UNION of investing + mirror positions
        │   └── #table: WeightedAvgDuration = SUM(DurationRatio * Amount) / SUM(Amount)
        │
        ├── #TempBI_DB_PositionPnL: BI_DB_PositionPnL (daily position P&L, since 2022-12-30)
        │   └── #Lev: EffectiveLev, InvestingRatio, CryptoRatio, TradingRatio
        │       (all volume-weighted averages per CID × Date)
        │
        ├── #ManualPositions: COUNT of positions → AvgDailyPositions
        │
        └── #DailyRisk0: DWH_CIDsDailyRisk → RiskIndex (1-10 scale from AvgSTD)
            │
            └─ SP_ClusteringDailyPrepData @date
                ├─ DELETE WHERE CalculationDateID = @dateid
                └─ INSERT → BI_DB_dbo.BI_DB_ClusteringDailyPrepData
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| CID | DWH_dbo.Dim_Customer | RealCID | passthrough | Via Fact_FirstCustomerAction + Fact_SnapshotCustomer | V3-verified customer ID |
| CalculationDate | — | — | ETL-computed | `@date` parameter | Date of calculation |
| CalculationDateID | — | — | ETL-computed | `CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)` → YYYYMMDD | Clustered index column |
| WeightedAvgDuration | DWH_dbo.Dim_Position + Dim_Mirror | OpenOccurred, CloseOccurred, Amount | ETL-computed | `SUM(DurationRatio * Amount) / NULLIF(SUM(Amount), 0)` where DurationRatio = `DATEDIFF(DAY, Open, Close) / DATEDIFF(DAY, Open, @date)`. -1 if no investing positions. | Investing + mirror positions only (Indices/Stocks/ETF at leverage 1-2) |
| RiskIndex | BI_DB_dbo.DWH_CIDsDailyRisk | AvgSTD | ETL-computed | AVG of bucketed AvgSTD: <0.034%→1, <0.068%→2, ..., ≥4.763%→10 | 2-year average risk score (1=low, 10=high) |
| AvgDailyPositions | DWH_dbo.Dim_Position | COUNT(*) | ETL-computed | `CountPositions / DATEDIFF(DAY, FirstActionDate, @date)` | Avg positions per day over 2-year window |
| EffectiveLev | BI_DB_dbo.BI_DB_PositionPnL + Dim_Instrument | Amount, Leverage | ETL-computed | `SUM(EffectiveLev * InvestedAmount) / SUM(InvestedAmount)` where daily EffectiveLev = `SUM(Amount * Leverage) / SUM(Amount)` | Volume-weighted average leverage |
| InvestingRatio | BI_DB_dbo.BI_DB_PositionPnL + Dim_Instrument | Amount, InstrumentTypeID, Leverage, MirrorID | ETL-computed | Proportion of amount in (Indices/Stocks/ETF at leverage 1-2) + copy-trading (MirrorID≠0) | 0-1 scale. Part of 3-way ratio |
| CryptoRatio | BI_DB_dbo.BI_DB_PositionPnL + Dim_Instrument | Amount, InstrumentTypeID, MirrorID | ETL-computed | Proportion of amount in Crypto (InstrumentTypeID=10, direct only) | 0-1 scale. Part of 3-way ratio |
| TradingRatio | BI_DB_dbo.BI_DB_PositionPnL + Dim_Instrument | Amount, InstrumentTypeID, Leverage, MirrorID | ETL-computed | Proportion of amount in leveraged trading: (Indices/Stocks/ETF leverage>2) + (Currencies/Commodities), direct only | 0-1 scale. Part of 3-way ratio |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL execution timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **ETL-computed** | 10 |
| **Total** | 11 |
