# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_PnL

## Column Mapping

| DWH Column | Immediate Source | Upstream / Transform | Notes |
|------------|------------------|----------------------|-------|
| DateID | `BI_DB_dbo.Function_PnL_Single_Day(@dateID)` | `frfc.DateID` | Matches `@dateID` (YYYYMMDD int) |
| Date | ETL parameter | `@date` | Literal calendar date passed to SP |
| RealCID | `Function_PnL_Single_Day` | `frfc.CID` | Real customer ID (not virtual) |
| InstrumentTypeID | `DWH_dbo.Dim_Instrument` | `di.InstrumentTypeID` via `JOIN ON frfc.InstrumentID = di.InstrumentID` | Grain dimension |
| IsCopy | `Function_PnL_Single_Day` | `CASE WHEN frfc.MirrorID > 0 THEN 1 ELSE 0 END` | Copy-trade vs manual |
| IsSettled | `Function_PnL_Single_Day` | `frfc.IsSettled` | Passthrough from position-level logic |
| UnrealizedPnLChange | `Function_PnL_Single_Day` | `SUM(frfc.UnrealizedPnLChange)` | Day’s unrealized PnL movement |
| NetProfit | `Function_PnL_Single_Day` | `SUM(frfc.NetProfit)` | Realized PnL component |
| CountPositions | `Function_PnL_Single_Day` | `COUNT(frfc.PositionID)` | Positions in grain |
| UpdateDate | — | `GETDATE()` | Load timestamp |
| IsFuture | `Function_PnL_Single_Day` | `ISNULL(frfc.IsFuture, 0)` | Futures vs non-futures |
| IsLeveraged | `Function_PnL_Single_Day` | `CASE WHEN frfc.Leverage > 1 THEN 1 ELSE 0 END` | Leverage flag |
| IsBuy | `Function_PnL_Single_Day` | `frfc.IsBuy` | Long vs short |
| IsCopyFund | `Function_PnL_Single_Day` | `ISNULL(frfc.IsCopyFund, 0)` | Copy-fund position |
| IsSQF | `Function_PnL_Single_Day` | `ISNULL(frfc.IsSQF, 0)` | Spot Quoted Futures — from `Function_Instrument_Snapshot_Enriched` join inside TVF |

## Upstream of `Function_PnL_Single_Day` (conceptual)

The table-valued function composes same-day PnL from:

| Source object | Role |
|---------------|------|
| `BI_DB_dbo.BI_DB_PositionPnL` | Start-of-day / end-of-day position PnL snapshots (two `DateID` slices joined) |
| `DWH_dbo.Dim_Position` | Closed positions with `CloseDateID = @dateID` for realized `NetProfit` |
| `DWH_dbo.Dim_Instrument` | `IsFuture` and instrument metadata |
| `BI_DB_dbo.BI_DB_CopyFund_Positions` | Marks copy-fund positions (`IsCopyFund`) |
| `BI_DB_dbo.Function_Instrument_Snapshot_Enriched(@dateID)` | `IsSQF = 1` instruments for SQF tagging |

## ETL Pipeline

```
BI_DB_dbo.Function_PnL_Single_Day(@dateID)
  ← BI_DB_PositionPnL, Dim_Position, Dim_Instrument, BI_DB_CopyFund_Positions, Function_Instrument_Snapshot_Enriched
       │
       └─ JOIN DWH_dbo.Dim_Instrument di ON frfc.InstrumentID = di.InstrumentID
            │
            └─ GROUP BY (grain dimensions)
                 │
                 └─ SP_DDR_Fact_PnL(@date)
                      ├─ DELETE FROM BI_DB_DDR_Fact_PnL WHERE DateID = @dateID
                      └─ INSERT ... SELECT (aggregated measures)
```

## Source Tables (writer SP)

| Source | Role | Columns Used |
|--------|------|----------------|
| `BI_DB_dbo.Function_PnL_Single_Day(@dateID)` | Primary rowset | CID, InstrumentID, MirrorID, IsSettled, UnrealizedPnLChange, NetProfit, PositionID, IsFuture, Leverage, IsBuy, IsCopyFund, IsSQF, DateID |
| `DWH_dbo.Dim_Instrument` | Instrument grain | InstrumentTypeID (join key: InstrumentID) |

## Consumers

| Consumer | Usage |
|----------|-------|
| `BI_DB_dbo.BI_DB_V_DDR_PnL` | Rolls up `UnrealizedPnLChange + NetProfit` by RealCID/Date; splits by instrument type, copy vs manual, settled vs CFD, period starts |
| `BI_DB_dbo.BI_DB_V_DDR_Daily_Panel` | Joins `BI_DB_V_DDR_PnL` for customer daily panel metrics |
| `BI_DB_dbo.Function_DDR_Aggregation_*` (Yesterday, ThisWeek, ThisMonth, ThisQuarter, ThisYear, YoY, MoM) | Period comparisons via `BI_DB_V_DDR_PnL` |
