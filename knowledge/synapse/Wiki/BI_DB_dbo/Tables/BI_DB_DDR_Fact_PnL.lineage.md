# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_PnL

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_DDR_Fact_PnL` |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` |
| **Primary Source** | `BI_DB_dbo.Function_PnL_Single_Day` (TVF) |
| **ETL SP** | `BI_DB_dbo.SP_DDR_Fact_PnL` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`; `Function_Instrument_Snapshot_Enriched` (via TVF for `IsSQF`); `BI_DB_PositionPnL`; `DWH_dbo.Dim_Position`; `BI_DB_CopyFund_Positions` (via TVF) |
| **Generic Pipeline** | `Gold/sql_dp_prod_we/BI_DB_dbo/BI_DB_DDR_Fact_PnL/`, `business_group=bi_db`, `frequency_minutes=1440`, `copy_strategy=Append` (generic_id 1982) |
| **Generated** | 2026-05-14 |

## Source Objects

| Source Object | Role |
|---------------|------|
| `BI_DB_dbo.Function_PnL_Single_Day(@dateID)` | Position-level P&L rows (unrealized change + realized net) for one `DateID`; inner sources include `BI_DB_PositionPnL`, `DWH_dbo.Dim_Position`, `DWH_dbo.Dim_Instrument`, `BI_DB_CopyFund_Positions`, `Function_Instrument_Snapshot_Enriched` |
| `DWH_dbo.Dim_Instrument` | JOIN in `SP_DDR_Fact_PnL` to bring `InstrumentTypeID` at aggregate grain |
| `BI_DB_dbo.SP_DDR_Fact_PnL` | `DELETE`/`INSERT` daily by `DateID`; `GROUP BY` + `SUM`/`COUNT` |

## Lineage Chain

```
DWH_dbo.Dim_Position (CloseDateID = @dateID closes; open path via BI_DB_PositionPnL lag day)
  + BI_DB_dbo.BI_DB_PositionPnL (prior-day vs as-of @dateID snapshots for unrealized)
  + DWH_dbo.Dim_Instrument (InstrumentTypeID, IsFuture on position rows)
  + BI_DB_dbo.BI_DB_CopyFund_Positions (IsCopyFund)
  + BI_DB_dbo.Function_Instrument_Snapshot_Enriched(@dateID) (IsSQF ⇔ Trade.InstrumentGroups GroupID=59)
  |-- Function_PnL_Single_Day(@dateID) ---|
  v
[position-level P&L grain: one row per DateID×CID×Position×… in FINAL CTE]
  |-- SP_DDR_Fact_PnL: JOIN Dim_Instrument ON frfc.InstrumentID; GROUP BY …; SUM/COUNT ---|
  v
BI_DB_dbo.BI_DB_DDR_Fact_PnL (aggregated: RealCID × InstrumentTypeID × copy/settle/direction/future/leverage/SQF/copy-fund flags × DateID)
  |-- Generic Pipeline (Append, daily) ---|
  v
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl (+ etr_* partition cols at UC)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Carried through from TVF output without change in the INSERT list (may still be aggregated in TVF upstream) |
| **rename** | Same value, different target column name |
| **ETL-computed** | Derived in `SP_DDR_Fact_PnL` (`SUM`, `COUNT`, `CASE`, `@date`, `GETDATE()`, `ISNULL`) |
| **join-enriched** | Added via JOIN to `Dim_Instrument` in the SP |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| DateID | Function_PnL_Single_Day | DateID | passthrough | `frfc.DateID` | GROUP BY key |
| Date | — | — | ETL-computed | `@date AS [Date]` | SP parameter `DATE` |
| RealCID | Function_PnL_Single_Day | CID | rename | `frfc.CID AS RealCID` | GROUP BY key |
| InstrumentTypeID | Dim_Instrument | InstrumentTypeID | join-enriched | `di.InstrumentTypeID` via `frfc.InstrumentID = di.InstrumentID` | GROUP BY key |
| IsCopy | Function_PnL_Single_Day | MirrorID | ETL-computed | `CASE WHEN frfc.MirrorID > 0 THEN 1 ELSE 0 END` | GROUP BY key |
| IsSettled | Function_PnL_Single_Day | IsSettled | passthrough | `frfc.IsSettled` | GROUP BY key |
| UnrealizedPnLChange | Function_PnL_Single_Day | UnrealizedPnLChange | ETL-computed | `SUM(frfc.UnrealizedPnLChange)` | Per SP `GROUP BY` |
| NetProfit | Function_PnL_Single_Day | NetProfit | ETL-computed | `SUM(frfc.NetProfit)` | Per SP `GROUP BY` |
| CountPositions | Function_PnL_Single_Day | PositionID | ETL-computed | `COUNT(frfc.PositionID)` | Per SP `GROUP BY` |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | Load watermark |
| IsFuture | Function_PnL_Single_Day | IsFuture | passthrough | `ISNULL(frfc.IsFuture, 0)` | GROUP BY key |
| IsLeveraged | Function_PnL_Single_Day | Leverage | ETL-computed | `CASE WHEN frfc.Leverage > 1 THEN 1 ELSE 0 END` | GROUP BY key |
| IsBuy | Function_PnL_Single_Day | IsBuy | passthrough | `frfc.IsBuy` | GROUP BY key |
| IsCopyFund | Function_PnL_Single_Day | IsCopyFund | passthrough | `ISNULL(frfc.IsCopyFund, 0)` | GROUP BY key |
| IsSQF | Function_PnL_Single_Day | IsSQF | passthrough | `ISNULL(frfc.IsSQF, 0)` | TVF: `case when sqf.InstrumentID is not null then 1 else 0 end` with `sqf` from `Function_Instrument_Snapshot_Enriched(@dateID) WHERE IsSQF = 1`; **semantic**: SpotQuotedFuture — see wiki §4 and `.review-needed.md` Tier 5 |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 5 |
| **Rename** | 1 |
| **ETL-computed** | 7 |
| **Join-enriched** | 1 |
| **Total columns** | 15 |
