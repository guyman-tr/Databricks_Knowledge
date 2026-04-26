# Lineage: BI_DB_dbo.BI_DB_eTorian_PnL

## Object Metadata

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Name** | BI_DB_eTorian_PnL |
| **Object Type** | Table |
| **Writer SP** | BI_DB_dbo.SP_eTorian_PnL_NetProfit (month-end block only) |
| **Production Source** | BI_DB_dbo.BI_DB_PositionPnL (open position PnL at month-end, via DateID=@DateID) |
| **ETL Pattern** | Month-end only — guarded by `IF @Date = EOMONTH(@Date)`; DELETE WHERE EOM_Snapshot_OpenPosition=@Date + INSERT from #PnL |
| **UC Target** | _Not_Migrated |

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (fsc)
  |-- INNER JOIN DWH_dbo.Dim_Range (dr) ON DateRangeID (active SCD row for @Date)
  |-- INNER JOIN DWH_dbo.Dim_Customer (dc) ON RealCID
  |   Filter: PlayerLevelID=4, AccountStatusID!=2 (or NULL), AccountTypeID IN (7,13),
  |           PlayerStatusID!=2 [plus CID=149 hardcoded]
  |-- → #list (CID, UserName) — eTorian customer roster at @Date

BI_DB_dbo.BI_DB_PositionPnL (bdppl)
  |-- INNER JOIN #list ON CID
  |-- INNER JOIN DWH_dbo.Dim_Instrument (di) ON InstrumentID
  |   Filter: bdppl.DateID = @DateID (month-end point-in-time open positions)
  |   Group by CID, UserName, bdppl.Date
  |   PnL buckets:
  |     Pnl_Crypto      ← SUM(PositionPnL) WHERE InstrumentTypeID = 10
  |     Pnl_Stocks_ETFs ← SUM(PositionPnL) WHERE InstrumentTypeID IN (5, 6)
  |     Pnl_Other       ← SUM(PositionPnL) WHERE InstrumentTypeID IN (1, 2, 4)
  |-- → #PnL temp table
  |
  |   [IF @Date = EOMONTH(@Date) — month-end guard]
  |-- DELETE FROM BI_DB_eTorian_PnL WHERE EOM_Snapshot_OpenPosition = @Date
  |-- INSERT (CID, UserName, EOM_Snapshot_OpenPosition, Pnl_Crypto, Pnl_Stocks_ETFs,
  |           Pnl_Other, GETDATE())
  v
BI_DB_dbo.BI_DB_eTorian_PnL
  (78,213 rows | Jan 2021 – Mar 2026 | 63 months | HASH(CID), CLUSTERED(EOM_Snapshot_OpenPosition))
  UC: _Not_Migrated

[Same SP also writes daily — always]:
  DWH_dbo.Dim_Position (dp)
  |-- WHERE CloseDateID = @DateID
  v
BI_DB_dbo.BI_DB_eTorian_NetProfit  (companion — closed positions, daily grain)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Via #list; eTorian filter (PlayerLevelID=4) | Tier 2 |
| 2 | UserName | DWH_dbo.Dim_Customer | UserName | Via #list join on RealCID | Tier 2 |
| 3 | EOM_Snapshot_OpenPosition | SP parameter | @Date | Passed directly; written only when @Date=EOMONTH(@Date) | Tier 2 |
| 4 | Pnl_Crypto | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | SUM WHERE InstrumentTypeID=10 | Tier 2 |
| 5 | Pnl_Stocks_ETFs | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | SUM WHERE InstrumentTypeID IN (5, 6) | Tier 2 |
| 6 | Pnl_Other | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | SUM WHERE InstrumentTypeID IN (1, 2, 4) | Tier 2 |
| 7 | UpdateDate | ETL | GETDATE() | Set at INSERT time | Tier 2 |

## Source Objects

| Source Object | Type | Role |
|--------------|------|------|
| BI_DB_dbo.BI_DB_PositionPnL | Table | Primary source — open position PnL per CID per instrument at DateID |
| DWH_dbo.Fact_SnapshotCustomer | Table | eTorian customer filter (PlayerLevelID=4, active SCD row) |
| DWH_dbo.Dim_Customer | Table | UserName lookup via RealCID |
| DWH_dbo.Dim_Range | Table | SCD date range filter for Fact_SnapshotCustomer active row |
| DWH_dbo.Dim_Instrument | Table | InstrumentTypeID lookup for PnL bucket routing |

## UC External Lineage

UC Target: _Not_Migrated — no Unity Catalog lineage applicable.
