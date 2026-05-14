# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts` |
| **Synapse row estimate** | ~804M (`SUM(rows)` across `sys.partitions` · `clustered columnstore`; sample total **804 221 299** rows MCP 2026-05-14) |
| **`DateID` span (evidence)** | **20070827**–**20260425** (MCP MIN/MAX 2026-05-14) |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` (`_generic_pipeline_mapping.json` generic_id **1770**; Merge · 1440 min · Delta) |
| **Primary Source** | `BI_DB_dbo.Function_Trading_Volume_PositionLevel(@dateInt, @dateInt, @OnlyValidCustomers=0)` |
| **ETL SP** | `BI_DB_dbo.SP_DDR_Fact_Trading_Volumes_And_Amounts(@date DATE)` |
| **Secondary artefacts** | Optional guarded QA dump → `BI_DB_dbo.BI_DB_VolumeQA` (same `@dateInt` slice) — see Phase 9 body |
| **Embedded upstreams (via TVF)** | `DWH_dbo.Dim_Position`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Range`, `BI_DB_dbo.Function_Instrument_Snapshot_Enriched`, `BI_DB_dbo.V_C2P_Positions`, `BI_DB_dbo.BI_DB_CopyFund_Positions`, `BI_DB_dbo.BI_DB_RecurringInvestment_Positions`, `BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN`, `BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN` |
| **Synapse DDL columns** | **27** (all nullable in catalogue; clustered columnstore) |
| **Generated** | 2026-05-14 |

---

## Phase 9 — Stored procedure (verbatim core)

Source file:  
`C:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_DDR_Fact_Trading_Volumes_And_Amounts.sql`

```sql
CREATE PROC [BI_DB_dbo].[SP_DDR_Fact_Trading_Volumes_And_Amounts] @date [DATE] AS 
BEGIN  
-- … header / change history trimmed …

DECLARE @dateID int = CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)

IF OBJECT_ID('tempdb..#data') IS NOT NULL DROP TABLE #data
CREATE TABLE #data
    WITH (HEAP,DISTRIBUTION = ROUND_ROBIN)
AS
SELECT * FROM BI_DB_dbo.Function_Trading_Volume_PositionLevel(@dateID, @dateID,0) ftvpl

DELETE FROM BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts WHERE DateID = @dateID

INSERT INTO BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts (
	[DateID],[Date],[RealCID],[InstrumentTypeID],[IsSettled],[IsCopy],[IsBuy],[IsLeverage],[IsFuture],
	[IsCopyFund],[IsOpenedFromIBAN],[IsClosedToIBAN],[IsRecurring],[IsAirDrop],
	[VolumeOpen],[VolumeClose],[InvestedAmountOpen],[InvestedAmountClosed],[TotalVolume],[NetInvestedAmount],
	[CountOpenTransactions],[CountCloseTransactions],[CountTotalTransactions],[UpdateDate],
	[IsSQF],[IsMarginTrade],[IsC2P])
SELECT 
	   ftv.DateID
	 , CONVERT(DATE, CONVERT(VARCHAR(8), ftv.DateID), 112) AS Date
	 , ftv.CID AS RealCID
	 , ftv.InstrumentTypeID
	 , ftv.IsSettled
	 , ftv.IsCopy
	 , ftv.IsBuy
	 , CASE WHEN ftv.Leverage > 1 THEN 1 ELSE 0 END AS IsLeverage
	 , ftv.IsFuture
	 , IsCopyFund
	 , IsOpenedFromIBAN
	 , IsClosedToIBAN
	 , IsRecurring
	 , IsAirDrop
	 , sum(ftv.VolumeOpen				) as VolumeOpen				
	 , sum(ftv.VolumeClose				) as VolumeClose				
	 , sum(ftv.InvestedAmountOpen		) as InvestedAmountOpen		
	 , sum(ftv.InvestedAmountClosed		) as InvestedAmountClosed		
	 , sum(ftv.TotalVolume				) as TotalVolume				
	 , sum(ftv.NetInvestedAmount		) as NetInvestedAmount		
	 , sum(ftv.CountOpenTransactions	) as CountOpenTransactions	
	 , sum(ftv.CountCloseTransactions	) as CountCloseTransactions	
	 , sum(ftv.CountTotalTransactions	) as CountTotalTransactions	
	 , GETDATE() AS UpdateDate
	 , IsSQF
	 , IsMarginTrade
	 , ftv.IsC2P
FROM #data ftv
GROUP BY 
	   ftv.DateID
	 , CONVERT(DATE, CONVERT(VARCHAR(8), ftv.DateID), 112)
	 , ftv.CID 
	 , ftv.InstrumentTypeID
	 , ftv.IsSettled
	 , ftv.IsCopy
	 , ftv.IsBuy
	 , CASE WHEN ftv.Leverage > 1 THEN 1 ELSE 0 END 
	 , ftv.IsFuture
	 , IsCopyFund
	 , IsOpenedFromIBAN
	 , IsClosedToIBAN
	 , IsRecurring
	 , IsAirDrop
	 , IsSQF
	 , IsMarginTrade
	 , ftv.IsC2P

-- QA dump (guarded …)
IF OBJECT_ID('BI_DB_dbo.BI_DB_VolumeQA') IS NOT NULL
BEGIN
	DELETE FROM BI_DB_dbo.BI_DB_VolumeQA WHERE DateID = @dateID
	INSERT INTO BI_DB_dbo.BI_DB_VolumeQA ( /* … columns … */ )
	SELECT /* … position-level cols from #data … */ FROM #data ftvpl
END

END
```

---

## Lineage Chain

```
DWH_dbo.Dim_Position (open events by OpenDateID + close events by CloseDateID · volumes / amounts / flags)
  + DWH_dbo.Dim_Instrument (InstrumentTypeID, IsFuture JOIN)
  + DWH_dbo.Fact_SnapshotCustomer + Dim_Range (customer validity gate inside TVF — SP passes @OnlyValidCustomers = 0)
  + BI_DB_dbo.Function_Instrument_Snapshot_Enriched(@edateInt) → IsSQF (GroupID = 59 · Trade.InstrumentGroups via staging per function wiki)
  + BI_DB_dbo.V_C2P_Positions → IsC2P
  + BI_DB_CopyFund_Positions · BI_DB_RecurringInvestment_Positions · IBAN helper tables → product/context flags
        |
        └── BI_DB_dbo.Function_Trading_Volume_PositionLevel(@dateID, @dateID, 0)  ── temp #data (ROUND_ROBIN heap)
                     |
                     └── BI_DB_dbo.SP_DDR_Fact_Trading_Volumes_And_Amounts(@date)
                               DELETE WHERE DateID = @dateID
                               INSERT … GROUP BY keys + SUM measures + GETDATE() UpdateDate
                               └─► optional BI_DB_VolumeQA QA dump same DateID

Azure Synapse BI_DB DDR table
  └── Generic Pipeline Merge (daily) ──► main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
```

---

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Carried unchanged from TVF output into INSERT list (still part of aggregation grain) |
| **rename** | TVF column renamed in INSERT (`CID`→`RealCID`) |
| **ETL-computed** | Produced or aggregated inside `SP_DDR_Fact_Trading_Volumes_And_Amounts` (`SUM`, `GETDATE()`, `CASE` on leverage) |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|------------|--------------|---------------|-----------|-------|
| DateID | `Function_Trading_Volume_PositionLevel` | `DateID` | passthrough | Event calendar ID (open-leg or close-leg date inside TVF). GROUP BY key. |
| Date | — | — | ETL-computed | `CONVERT(DATE, CONVERT(VARCHAR(8), ftv.DateID), 112)` |
| RealCID | `Function_Trading_Volume_PositionLevel` | `CID` | rename | `ftv.CID AS RealCID` · HASH distribution key on table |
| InstrumentTypeID | `Function_Trading_Volume_PositionLevel` | `InstrumentTypeID` | passthrough | From `Dim_Instrument` JOIN in TVF. GROUP BY key. |
| IsSettled | `Function_Trading_Volume_PositionLevel` | `IsSettled` | passthrough | From `Dim_Position`. GROUP BY key. |
| IsCopy | `Function_Trading_Volume_PositionLevel` | `IsCopy` | passthrough | `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END` in TVF (`Dim_Position.MirrorID`). GROUP BY key. |
| IsBuy | `Function_Trading_Volume_PositionLevel` | `IsBuy` | passthrough | From `Dim_Position`. GROUP BY key. |
| IsLeverage | `Function_Trading_Volume_PositionLevel` | `Leverage` | ETL-computed | `CASE WHEN ftv.Leverage > 1 THEN 1 ELSE 0 END` in SP (GROUP BY repeats same CASE). |
| IsFuture | `Function_Trading_Volume_PositionLevel` | `IsFuture` | passthrough | From `Dim_Instrument`. GROUP BY key. |
| IsCopyFund | `Function_Trading_Volume_PositionLevel` | `IsCopyFund` | passthrough | `BI_DB_CopyFund_Positions` pattern in TVF. GROUP BY key. |
| IsOpenedFromIBAN | `Function_Trading_Volume_PositionLevel` | `IsOpenedFromIBAN` | passthrough | Helper table keyed in TVF · **Synapse DDL `varchar(100)`** despite `Is*` naming. GROUP BY key. |
| IsClosedToIBAN | `Function_Trading_Volume_PositionLevel` | `IsClosedToIBAN` | passthrough | GROUP BY key. |
| IsRecurring | `Function_Trading_Volume_PositionLevel` | `IsRecurring` | passthrough | GROUP BY key. |
| IsAirDrop | `Function_Trading_Volume_PositionLevel` | `IsAirDrop` | passthrough | From `Dim_Position` via TVF. GROUP BY key. Can be **NULL** in live samples (`DateID≥20260101`). |
| VolumeOpen | `Function_Trading_Volume_PositionLevel` | `VolumeOpen` | ETL-computed | `SUM(ftv.VolumeOpen)` |
| VolumeClose | `Function_Trading_Volume_PositionLevel` | `VolumeClose` | ETL-computed | `SUM(ftv.VolumeClose)` |
| InvestedAmountOpen | `Function_Trading_Volume_PositionLevel` | `InvestedAmountOpen` | ETL-computed | `SUM(ftv.InvestedAmountOpen)` |
| InvestedAmountClosed | `Function_Trading_Volume_PositionLevel` | `InvestedAmountClosed` | ETL-computed | `SUM(ftv.InvestedAmountClosed)` |
| TotalVolume | `Function_Trading_Volume_PositionLevel` | `TotalVolume` | ETL-computed | `SUM(ftv.TotalVolume)` |
| NetInvestedAmount | `Function_Trading_Volume_PositionLevel` | `NetInvestedAmount` | ETL-computed | `SUM(ftv.NetInvestedAmount)` |
| CountOpenTransactions | `Function_Trading_Volume_PositionLevel` | `CountOpenTransactions` | ETL-computed | `SUM(ftv.CountOpenTransactions)` |
| CountCloseTransactions | `Function_Trading_Volume_PositionLevel` | `CountCloseTransactions` | ETL-computed | `SUM(ftv.CountCloseTransactions)` |
| CountTotalTransactions | `Function_Trading_Volume_PositionLevel` | `CountTotalTransactions` | ETL-computed | `SUM(ftv.CountTotalTransactions)` |
| UpdateDate | — | — | ETL-computed | `GETDATE()` inside SP execution |
| IsSQF | `Function_Trading_Volume_PositionLevel` | `IsSQF` | passthrough | TVF derives from **`Function_Instrument_Snapshot_Enriched`** → **`Trade.InstrumentGroups` `GroupID = 59`** (see function wiki §4 col 7 · **semantic correction** in `BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.md`). GROUP BY key. |
| IsMarginTrade | `Function_Trading_Volume_PositionLevel` | `IsMarginTrade` | passthrough | TVF uses `CASE WHEN Dim_Position.SettlementTypeID = 5 THEN 1 ELSE 0 END` (dictionary **MARGIN_TRADE** · `Dim_Position.md`). GROUP BY key. |
| IsC2P | `Function_Trading_Volume_PositionLevel` | `IsC2P` | passthrough | TVF **`LEFT JOIN`** / `CASE` on **`V_C2P_Positions`** (copy → own-portfolio migrated positions). GROUP BY key. |

---

## Summary

| Category | Count |
|----------|-------|
| **Passthrough / rename grain keys** | 15 |
| **ETL-computed aggregates / timestamps** | 12 |
| **Total mapped columns** | **27** |
