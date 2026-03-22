# Column Lineage: Dealing_dbo.Dealing_CopyPortfolio_Allocation

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_CopyPortfolio_Allocation` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Sources** | `BI_DB_dbo.BI_DB_PositionPnL`, `BI_DB_dbo.BI_DB_CopyDailyData` |
| **ETL SP** | `Dealing_dbo.SP_CopyPortfolio_Allocation` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer` |
| **Generated** | 2026-03-21 |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula |
|-----------|-------------|---------------|-----------|---------------------|
| Date | — | — | ETL-computed | `@Date` SP parameter |
| CID | BI_DB_CopyDailyData + BI_DB_PositionPnL | CID | passthrough | Portfolio manager CID (filtered via CopyType='Portfolio') |
| Username | DWH_dbo.Dim_Customer | UserName | join-enriched | Via RealCID JOIN |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL | InstrumentID | passthrough | Direct |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | join-enriched | Via InstrumentID JOIN |
| NetUnits | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal, IsBuy | ETL-computed | `SUM((2*IsBuy-1)*AmountInUnitsDecimal)` — signed net units |
| NOP | BI_DB_dbo.BI_DB_PositionPnL | NOP | ETL-computed | `SUM(NOP)` per CID+InstrumentID |
| UnitsPercent | — | — | ETL-computed | `ABS(NetUnits)/SUM(ABS(NetUnits))` per CID — portfolio allocation by units |
| NOP_Percent | — | — | ETL-computed | `ABS(NOP)/SUM(ABS(NOP))` per CID — portfolio allocation by notional |
| UpdateDate | — | — | ETL-computed | `GETDATE()` |
| AUM | BI_DB_dbo.BI_DB_CopyDailyData | CopyAUM | passthrough | Assets under management for this portfolio |
| Copiers | BI_DB_dbo.BI_DB_CopyDailyData | NumOfCopiers | passthrough | Number of copiers following this portfolio |

## Summary

| Category | Count |
|----------|-------|
| **ETL-computed** | 5 |
| **Join-enriched** | 2 |
| **Passthrough** | 4 |
| **Total** | 12 (including Date) |
