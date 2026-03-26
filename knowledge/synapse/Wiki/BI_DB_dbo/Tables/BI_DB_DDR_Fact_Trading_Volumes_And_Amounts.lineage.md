# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `BI_DB_dbo.Function_Trading_Volume_PositionLevel` (TVF) |
| **ETL SP** | `SP_DDR_Fact_Trading_Volumes_And_Amounts` |
| **Secondary Sources** | (all embedded in the function: `Dim_Position`, `Dim_Instrument`, `Fact_SnapshotCustomer`, `V_C2P_Positions`, `BI_DB_CopyFund_Positions`, `BI_DB_RecurringInvestment_Positions`, `BI_DB_Positions_Opened_From_IBAN`, `BI_DB_Positions_Closed_To_IBAN`, `Function_Instrument_Snapshot_Enriched`) |
| **Generated** | 2026-03-26 |

## Lineage Chain

```
DWH_dbo.Dim_Position (position opens + closes)
  + DWH_dbo.Dim_Instrument (InstrumentTypeID, IsFuture)
  + DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer filter)
  + BI_DB_dbo.V_C2P_Positions (IsC2P)
  + BI_DB_dbo.BI_DB_CopyFund_Positions (IsCopyFund)
  + BI_DB_dbo.BI_DB_RecurringInvestment_Positions (IsRecurring)
  + BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN (IsOpenedFromIBAN)
  + BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN (IsClosedToIBAN)
  + Function_Instrument_Snapshot_Enriched (IsSQF)
  |
  |-- Function_Trading_Volume_PositionLevel(@dateID, @dateID, 0)
  |     → 32 columns per position (open + close legs UNIONed)
  |
  |-- SP_DDR_Fact_Trading_Volumes_And_Amounts(@date):
  |     GROUP BY dimension columns, SUM measure columns
  |     DELETE/INSERT by DateID
  v
BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts (793M rows, CID × flags grain)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from function output |
| **rename** | Same value, different column name |
| **ETL-computed** | Derived/calculated by SP logic |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| DateID | Function_Trading_Volume_PositionLevel | DateID | passthrough | Direct: ftv.DateID | GROUP BY key |
| Date | — | — | ETL-computed | `CONVERT(DATE, CONVERT(VARCHAR(8), ftv.DateID), 112)` | Derived from DateID |
| RealCID | Function_Trading_Volume_PositionLevel | CID | rename | `ftv.CID AS RealCID` | Distribution key |
| InstrumentTypeID | Function_Trading_Volume_PositionLevel | InstrumentTypeID | passthrough | Direct | GROUP BY key |
| IsSettled | Function_Trading_Volume_PositionLevel | IsSettled | passthrough | Direct | GROUP BY key |
| IsCopy | Function_Trading_Volume_PositionLevel | IsCopy | passthrough | Direct | GROUP BY key |
| IsBuy | Function_Trading_Volume_PositionLevel | IsBuy | passthrough | Direct | GROUP BY key |
| IsLeverage | Function_Trading_Volume_PositionLevel | Leverage | ETL-computed | `CASE WHEN ftv.Leverage > 1 THEN 1 ELSE 0 END` | GROUP BY key |
| IsFuture | Function_Trading_Volume_PositionLevel | IsFuture | passthrough | Direct | GROUP BY key |
| IsCopyFund | Function_Trading_Volume_PositionLevel | IsCopyFund | passthrough | Direct | GROUP BY key |
| IsOpenedFromIBAN | Function_Trading_Volume_PositionLevel | IsOpenedFromIBAN | passthrough | Direct | GROUP BY key; DDL is varchar(100) |
| IsClosedToIBAN | Function_Trading_Volume_PositionLevel | IsClosedToIBAN | passthrough | Direct | GROUP BY key |
| IsRecurring | Function_Trading_Volume_PositionLevel | IsRecurring | passthrough | Direct | GROUP BY key |
| IsAirDrop | Function_Trading_Volume_PositionLevel | IsAirDrop | passthrough | Direct | GROUP BY key |
| VolumeOpen | Function_Trading_Volume_PositionLevel | VolumeOpen | ETL-computed | `SUM(ftv.VolumeOpen)` | Aggregated notional volume on opens |
| VolumeClose | Function_Trading_Volume_PositionLevel | VolumeClose | ETL-computed | `SUM(ftv.VolumeClose)` | Aggregated notional volume on closes |
| InvestedAmountOpen | Function_Trading_Volume_PositionLevel | InvestedAmountOpen | ETL-computed | `SUM(ftv.InvestedAmountOpen)` | Aggregated invested amount on opens |
| InvestedAmountClosed | Function_Trading_Volume_PositionLevel | InvestedAmountClosed | ETL-computed | `SUM(ftv.InvestedAmountClosed)` | Aggregated invested amount on closes |
| TotalVolume | Function_Trading_Volume_PositionLevel | TotalVolume | ETL-computed | `SUM(ftv.TotalVolume)` | VolumeOpen + VolumeClose per position, then SUMmed |
| NetInvestedAmount | Function_Trading_Volume_PositionLevel | NetInvestedAmount | ETL-computed | `SUM(ftv.NetInvestedAmount)` | InvestedAmountOpen - InvestedAmountClosed per position, then SUMmed |
| CountOpenTransactions | Function_Trading_Volume_PositionLevel | CountOpenTransactions | ETL-computed | `SUM(ftv.CountOpenTransactions)` | 1 per non-partial-close-child open |
| CountCloseTransactions | Function_Trading_Volume_PositionLevel | CountCloseTransactions | ETL-computed | `SUM(ftv.CountCloseTransactions)` | 1 per close event |
| CountTotalTransactions | Function_Trading_Volume_PositionLevel | CountTotalTransactions | ETL-computed | `SUM(ftv.CountTotalTransactions)` | Open + Close count per position |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL timestamp |
| IsSQF | Function_Trading_Volume_PositionLevel | IsSQF | passthrough | Direct | GROUP BY key |
| IsMarginTrade | Function_Trading_Volume_PositionLevel | IsMarginTrade | passthrough | Direct | GROUP BY key |
| IsC2P | Function_Trading_Volume_PositionLevel | IsC2P | passthrough | Direct | GROUP BY key |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 14 |
| **Rename** | 1 |
| **ETL-computed** | 12 |
| **Total** | 27 |
