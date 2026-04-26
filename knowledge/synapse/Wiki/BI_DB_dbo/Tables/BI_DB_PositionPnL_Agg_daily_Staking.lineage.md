# Column Lineage — BI_DB_dbo.BI_DB_PositionPnL_Agg_daily_Staking

**Writer SP**: `BI_DB_dbo.SP_PositionPnL_Agg_daily_Staking`
**UC Target**: `_Not_Migrated`
**Generated**: 2026-04-21

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Tier |
|------------|-------------|---------------|-----------|------|
| DateID | BI_DB_dbo.BI_DB_PositionPnL | DateID | Passthrough | Tier 2 |
| Date | BI_DB_dbo.BI_DB_PositionPnL | Date | Passthrough | Tier 2 |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL | InstrumentID | Filtered: IN (100017=Cardano ADA, 100026=TRON TRX) only | Tier 2 |
| CountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | JOIN via dp.CID = fsc.RealCID at DateID range | Tier 2 |
| IsSettled | BI_DB_dbo.BI_DB_PositionPnL | IsSettled | Passthrough (1=real/settled asset, 0=CFD) | Tier 2 |
| IsCopy | BI_DB_dbo.BI_DB_PositionPnL | MirrorID | CASE WHEN MirrorID <> 0 THEN 1 ELSE 0 END | Tier 2 |
| TotalAmountInUnitsDecimal | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM() GROUP BY DateID, InstrumentID, CountryID, RegulationID, IsSettled, IsCopy | Tier 2 |
| TotalAmount_UK_prohibited | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM() WHERE CountryID=218 (UK) AND RegulationID=2 (FCA) AND Dim_Customer.RegisteredReal >= '2022-02-08' | Tier 2 |
| RegulationID | DWH_dbo.Fact_SnapshotCustomer | RegulationID | JOIN via dp.CID = fsc.RealCID at DateID range | Tier 2 |
| UpdateDate | ETL metadata | — | Not explicitly SET in SP; NULL on new inserts; legacy rows populated | Tier 3 |

## Source Objects

| Source | Role |
|--------|------|
| BI_DB_dbo.BI_DB_PositionPnL | Driving source — daily position P&L, units, settlement, mirror, filtered to staking instruments |
| DWH_dbo.Fact_SnapshotCustomer | Customer regulatory snapshot — CountryID + RegulationID per CID per date range |
| DWH_dbo.Dim_Range | Date range resolution — maps DateRangeID to FromDateID/ToDateID for SCD join |
| DWH_dbo.Dim_Customer | Customer demographics — RegisteredReal date for UK prohibition threshold |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (daily open-position snapshot, InstrumentID IN 100017/100026 only)
  + DWH_dbo.Fact_SnapshotCustomer (CountryID, RegulationID at snapshot date)
  + DWH_dbo.Dim_Range (date range join)
  + DWH_dbo.Dim_Customer (RegisteredReal for UK prohibition)
    |-- SP_PositionPnL_Agg_daily_Staking (Daily, P21) ---|
    v
BI_DB_dbo.BI_DB_PositionPnL_Agg_daily_Staking
  (3.01M rows, 20211101–20260412, ROUND_ROBIN, 2 instruments, 14 regulations)
    |-- UC: _Not_Migrated
```
