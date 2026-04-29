# Pre-Resolved Upstream Bundle for `DWH_dbo.Dim_HistorySplitRatio`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `DWH_dbo.Dim_HistorySplitRatio.sql`

```sql
CREATE TABLE [DWH_dbo].[Dim_HistorySplitRatio]
(
	[ID] [int] NOT NULL,
	[InstrumentID] [int] NOT NULL,
	[MinDate] [datetime] NULL,
	[MaxDate] [datetime] NULL,
	[PriceRatio] [decimal](16, 8) NOT NULL,
	[AmountRatio] [decimal](16, 8) NOT NULL,
	[PriceRatioUnAdjusted] [decimal](19, 4) NOT NULL,
	[AmountRatioUnAdjusted] [decimal](19, 4) NOT NULL,
	[UpdateDate] [datetime] NOT NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED INDEX
	(
		[InstrumentID] ASC,
		[MinDate] ASC,
		[MaxDate] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 1 upstream wiki(s). Read EACH one in full.


### Upstream `PriceLog.History.SplitRatio` — production
- **Resolved as**: `etoro.History.SplitRatio`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\History\Tables\History.SplitRatio.md`

# History.SplitRatio

> Active stock split ratio registry for eToro instruments - records each split event with the price and amount adjustment ratios applied to positions, orders, and historical prices, along with a multi-phase completion tracker. This is the primary data store (not a history table), with its own temporal history in History.HistorySplitRatio.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED PK on ID; UNIQUE NONCLUSTERED on InstrumentID + MinDate + MaxDate) |

---

## 1. Business Meaning

**IMPORTANT**: Despite being in the `History` schema, `History.SplitRatio` is the **active primary data store** for stock split ratios. It has its own temporal history table at `History.HistorySplitRatio` (via `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[HistorySplitRatio])`). It was placed in the History schema because it maintains a historical time-series of split events.

This table is the central registry for **stock split adjustments** on eToro's stock instruments. When a publicly listed company performs a stock split (or reverse split), eToro must:
1. Adjust the current prices of the instrument by `PriceRatio`
2. Adjust all customer open positions (units held) by `AmountRatio`
3. Adjust open and close orders
4. Recalculate holding fees
5. Update Redis cache and send notifications

Each row represents one split event for one instrument, bounded by `MinDate`/`MaxDate`. The "active" row for each instrument has `MaxDate = '2100-01-01'` (sentinel). When a new split occurs, the old row's MaxDate is set to the new split's MinDate, and a new row is inserted.

The `CK_InstrumentIsStock` check constraint (`InstrumentID > 1000`) ensures only stocks (not forex, crypto, or other non-stock instruments below ID 1000) have split records.

**Note**: Most of the 10,280 rows have `PriceRatio=1, AmountRatio=1` with the full default date range (2000-01-01 to 2100-01-01) - these are initialization rows for instruments that have no split history, establishing a 1:1 baseline ratio. Only rows with ratios != 1 represent actual split events.

---

## 2. Business Logic

### 2.1 Split Ratio Time-Series Pattern

**What**: Each instrument maintains a chain of non-overlapping split ratio records from its earliest history to the far future.

**Columns/Parameters Involved**: `InstrumentID`, `MinDate`, `MaxDate`, `PriceRatio`, `AmountRatio`

**Rules**:
- `MinDate` = the start of the period this ratio applies (inclusive)
- `MaxDate` = the end of the period (exclusive); sentinel value `'2100-01-01'` = currently active
- UNIQUE INDEX on `(InstrumentID, MinDate, MaxDate)` - no overlapping date ranges per instrument
- `History.InsertSplitRatio` inserts a new split by:
  1. Setting the current active row's `MaxDate = @MinDate`
  2. Inserting a new row with the new ratios and `MinDate = @MinDate, MaxDate = '2100-01-01'`
- PriceRatio and AmountRatio are inversely related: for a 2-for-1 forward split, `AmountRatio=2, PriceRatio=0.5`
- Computed from UnitsBefore/UnitsAfter: `AmountRatio = UnitsAfter / UnitsBefore`, `PriceRatio = UnitsBefore / UnitsAfter`

**Examples**:
- 2-for-1 forward split: PriceRatio=0.5, AmountRatio=2 (positions doubled, price halved)
- 1-for-2 reverse split: PriceRatio=2, AmountRatio=0.5 (positions halved, price doubled)

**Diagram**:
```
InstrumentID=1004 split history:
  Row 1: MinDate=2000-01-01, MaxDate=2025-01-01, Ratio=1 (no adjustment needed)
  Row 2: MinDate=2025-01-01, MaxDate=2025-01-20, PriceRatio=0.5, AmountRatio=2 (2-for-1 split)
  Row 3: MinDate=2025-01-20, MaxDate=2100-01-01, Ratio=? (active - next split pending)
```

### 2.2 Multi-Phase Split Execution

**What**: The split adjustment is applied in multiple phases across different system components, each tracked by a completion flag.

**Columns/Parameters Involved**: `IsCompletedOpenPositions`, `IsCompletedClosePositions`, `IsCompletedOpenOrders`, `IsCompletedCloseOrders`, `IsCompletedPricAndAmount`, `IsCompletedModifyPrice`, `IsCompleteHoldingFees`, `IsNotificationSent`, `IsNotificationStartSent`, `IsCurrencyPriceChanged`, `IsRedisUpdated`

**Rules**:
- All flags default to 0 on insert; set to 1 as each phase completes
- `Trade.SplitOpenPositions` processes open positions -> sets `IsCompletedOpenPositions=1`
- `History.SplitClosePositions` processes close positions -> sets `IsCompletedClosePositions=1`
- `Trade.OpenOrdersSplit` / `Stocks.OpenOrdersSplit` process open orders -> `IsCompletedOpenOrders=1`
- `Trade.CloseOrdersSplit` / `Stocks.CloseOrdersSplit` process close orders -> `IsCompletedCloseOrders=1`
- `Trade.SplitHoldingFees` adjusts holding fees -> sets `IsCompleteHoldingFees=1`
- Notification flags track user communication; Redis flag tracks cache invalidation
- A split is fully complete only when all applicable flags are 1
- Out of 10,280 rows, only 6 have all mandatory flags set to 1 (most are init rows with ratio=1 where processing isn't required)

### 2.3 Adjusted vs. Unadjusted Ratios

**What**: Both precise computed ratios and the original unadjusted values are stored for auditability.

**Columns/Parameters Involved**: `PriceRatio`, `AmountRatio`, `PriceRatioUnAdjusted`, `AmountRatioUnAdjusted`, `PriceRatioUnAdjustedFull`, `AmountRatioUnAdjustedFull`, `UnitsBefore`, `UnitsAfter`

**Rules**:
- `UnitsBefore` and `UnitsAfter`: the raw share counts before and after the split (e.g., 1 and 2 for a 2-for-1 split)
- `PriceRatio` = `UnitsBefore / UnitsAfter` (computed by History.InsertSplitRatio)
- `AmountRatio` = `UnitsAfter / UnitsBefore` (computed by History.InsertSplitRatio)
- `PriceRatioUnAdjusted` / `AmountRatioUnAdjusted`: stored as money - original ratio value before any cumulative adjustment
- `PriceRatioUnAdjustedFull`: decimal(38,19) - maximum precision version for critical calculations

---

## 3. Data Overview

| ID | InstrumentID | MinDate | MaxDate | PriceRatio | AmountRatio | UnitsBefore | UnitsAfter | Meaning |
|---|---|---|---|---|---|---|---|---|
| 10652 | 100038 | 2025-09-01 11:25 | 2025-09-01 11:43 | 0.001 | 1000 | 1 | 24 | Large split (1000x amount ratio); active for only 18 minutes (test or rapid correction) |
| 9629 | 1004 | 2025-01-01 | 2025-01-20 11:27 | 0.5 | 2 | 1 | 2 | Standard 2-for-1 forward split for instrument 1004 |
| 9627 | 1002 | 2025-01-20 09:37 | 2025-01-20 09:44 | 2.0 | 0.5 | 1 | 2 | Reverse split (1-for-2) for instrument 1002; brief 7-minute window |
| 9624 | 1013 | 2025-01-20 06:37 | 2025-01-20 06:43 | 0.25 | 4 | 1 | 2 | 4-for-1 split for instrument 1013 |
| 12036 | 1053988 | 2000-01-01 | 2100-01-01 | 1 | 1 | null | null | Typical initialization row: no split, full date range, all flags=0 |

Total: 10,280 rows | 9,928 distinct instruments | 6 fully completed splits

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) NOT FOR REPLICATION | NO | - | CODE-BACKED | Surrogate primary key, auto-incremented. NOT FOR REPLICATION indicates replication topology. Uniquely identifies each split event. |
| 2 | InstrumentID | int | NO | - | VERIFIED | The stock instrument this split applies to. FK to Trade.Instrument. CHECK constraint enforces InstrumentID > 1000 - only stock instruments (not forex or crypto). |
| 3 | MinDate | datetime | NO | '2000-01-01' | VERIFIED | Start of the period this split ratio is effective. Default '2000-01-01' means "from the beginning of the instrument's history." The split adjustment applies to transactions from this date forward until MaxDate. |
| 4 | MaxDate | datetime | NO | '2100-01-01' | VERIFIED | End of the period this split ratio is effective (exclusive). Sentinel value '2100-01-01' means "currently active - no end date set." When a new split occurs, the current active row's MaxDate is set to the new split's MinDate. |
| 5 | PriceRatio | decimal(16,8) | NO | 1 | VERIFIED | Multiplier applied to historical prices after this split. Equal to UnitsBefore/UnitsAfter. For a 2-for-1 split: PriceRatio=0.5 (price halved). For a 1-for-2 reverse split: PriceRatio=2. CHECK constraint enforces > 0. Default 1 = no adjustment. |
| 6 | AmountRatio | decimal(16,8) | NO | 1 | VERIFIED | Multiplier applied to position unit counts after this split. Equal to UnitsAfter/UnitsBefore. For a 2-for-1 split: AmountRatio=2 (units doubled). For a 1-for-2 reverse split: AmountRatio=0.5. CHECK constraint enforces > 0. Default 1 = no adjustment. |
| 7 | IsCompletedOpenPositions | tinyint | NO | 0 | CODE-BACKED | 1 when all open customer positions for this instrument have had their unit counts adjusted by AmountRatio. Set by Trade.SplitOpenPositions. |
| 8 | IsCompletedClosePositions | tinyint | NO | 0 | CODE-BACKED | 1 when all closed positions within the split window have had their data adjusted. Set by History.SplitClosePositions. |
| 9 | IsCompletedOpenOrders | tinyint | NO | 0 | CODE-BACKED | 1 when all open pending orders have been adjusted for the split. Set by Trade.OpenOrdersSplit or Stocks.OpenOrdersSplit. |
| 10 | IsCompletedCloseOrders | tinyint | NO | 0 | CODE-BACKED | 1 when all close orders have been adjusted for the split. Set by Trade.CloseOrdersSplit or Stocks.CloseOrdersSplit. |
| 11 | PriceRatioUnAdjusted | money | NO | - | CODE-BACKED | Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison. |
| 12 | AmountRatioUnAdjusted | money | NO | - | CODE-BACKED | Original unadjusted amount ratio stored as money type. Before cumulative adjustments. |
| 13 | IsNotificationSent | tinyint | NO | 0 | CODE-BACKED | 1 when the "split completed" user notification has been sent to affected customers. |
| 14 | IsCurrencyPriceChanged | tinyint | NO | 0 | CODE-BACKED | 1 when the currency price has been updated to reflect the split. |
| 15 | IsRedisUpdated | tinyint | NO | 0 | CODE-BACKED | 1 when the Redis cache has been invalidated/updated with the new split ratios. |
| 16 | IsNotificationStartSent | tinyint | YES | 0 | CODE-BACKED | 1 when the "split starting" notification was sent before the split begins. Nullable (added later). |
| 17 | IsCompletedPricAndAmount | tinyint | YES | 0 | CODE-BACKED | 1 when price and amount data in historical price feeds have been adjusted. Nullable (added later). |
| 18 | IsCompletedModifyPrice | tinyint | YES | 0 | CODE-BACKED | 1 when the current market price has been adjusted. Nullable (added later). |
| 19 | IsCompleteHoldingFees | tinyint | NO | 0 | CODE-BACKED | 1 when holding fees (overnight/weekend fees) have been recalculated for the split. Set by Trade.SplitHoldingFees. |
| 20 | DbLoginName | nvarchar(128) | - | - | CODE-BACKED | Computed column: `suser_name()` - SQL Server login that modified this split record. |
| 21 | AppLoginName | varchar(500) | - | - | CODE-BACKED | Computed column: `CONVERT(varchar(500), context_info())` - application context at time of change. |
| 22 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | Temporal system versioning start time. Used by History.HistorySplitRatio for tracking changes to split records. |
| 23 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | Temporal system versioning end time. |
| 24 | HostName | - | - | - | CODE-BACKED | Computed column: `host_name()` - server hostname that modified the record. |
| 25 | UnitsBefore | decimal(19,12) | YES | - | VERIFIED | Number of units per share before the split (e.g., 1). Used to compute PriceRatio and AmountRatio. Nullable for older records inserted before this column was added. |
| 26 | UnitsAfter | decimal(19,12) | YES | - | VERIFIED | Number of units per share after the split (e.g., 2 for a 2-for-1 split). Used with UnitsBefore to derive the adjustment ratios. |
| 27 | PriceRatioUnAdjustedFull | decimal(38,19) | YES | - | CODE-BACKED | Ultra-high precision (38,19) version of PriceRatioUnAdjusted. Added to avoid rounding errors in cumulative split calculations for instruments with many historical splits. |
| 28 | AmountRatioUnAdjustedFull | decimal(38,19) | YES | - | CODE-BACKED | Ultra-high precision (38,19) version of AmountRatioUnAdjusted. Same purpose as PriceRatioUnAdjustedFull. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | The stock instrument being split. CHECK enforces InstrumentID > 1000 (stocks only). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.HistorySplitRatio | HISTORY_TABLE | Temporal History | Temporal history of changes to this table's rows. |
| History.InsertSplitRatio | INSERT/UPDATE | Writer | Creates new split events; closes prior active row by setting MaxDate. |
| History.SplitClosePositions | SELECT/UPDATE | Reader + Updater | Adjusts close positions for the split; sets IsCompletedClosePositions=1. |
| Trade.SplitOpenPositions | SELECT/UPDATE | Reader + Updater | Adjusts open positions; sets IsCompletedOpenPositions=1. |
| Trade.ActivateSplit_Inner | SELECT/UPDATE | Orchestrator | Orchestrates the full split execution pipeline. |
| Trade.SplitHoldingFees | SELECT/UPDATE | Reader + Updater | Adjusts holding fees; sets IsCompleteHoldingFees=1. |
| Trade.OpenOrdersSplit / Stocks.OpenOrdersSplit | SELECT/UPDATE | Reader + Updater | Adjusts open orders; sets IsCompletedOpenOrders=1. |
| Trade.CloseOrdersSplit / Stocks.CloseOrdersSplit | SELECT/UPDATE | Reader + Updater | Adjusts close orders; sets IsCompletedCloseOrders=1. |
| Trade.InsertSplitToPriceDB | SELECT | Reader | Propagates split ratios to the price database. |
| dbo.AccountStatement_GetTransactionsReport_v* | SELECT | Reader | Uses split ratios to adjust historical transaction amounts in account statements. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SplitRatio (table)
  -> Trade.Instrument (FK on InstrumentID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK on InstrumentID - only valid stock instruments (ID > 1000) can have split records. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.HistorySplitRatio | Table | Temporal history of changes to this table (HISTORY_TABLE). |
| History.InsertSplitRatio | Procedure | Primary writer - creates split events and closes prior active rows. |
| History.SplitClosePositions | Procedure | Adjusts close positions for split events. |
| Trade.SplitOpenPositions | Procedure | Adjusts open customer positions. |
| Trade.ActivateSplit_Inner | Procedure | Main orchestrator of the split pipeline. |
| Trade.SplitHoldingFees | Procedure | Recalculates holding fees post-split. |
| Trade.OpenOrdersSplit / Stocks.OpenOrdersSplit | Procedure | Adjusts open orders. |
| Trade.CloseOrdersSplit / Stocks.CloseOrdersSplit | Procedure | Adjusts close orders. |
| Trade.InsertSplitToPriceDB | Procedure | Propagates ratios to price DB. |
| dbo.AccountStatement_GetTransactionsReport_v* | Procedure | Historical reporting with split-adjusted amounts. |
| Trade.CheckValidInstruments | Procedure | References split ratio data. |
| Monitor.CheckInsertInstrumentNewProcess | Procedure | Monitors split insertion process. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistorySplitRatio | CLUSTERED PK | ID ASC | - | - | Active |
| IX_InstrumentID_MinDate_MaxDate | UNIQUE NONCLUSTERED | InstrumentID ASC, MinDate ASC, MaxDate ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistorySplitRatio | PRIMARY KEY | Uniqueness on ID. CLUSTERED. NOT FOR REPLICATION. |
| IX_InstrumentID_MinDate_MaxDate | UNIQUE | No overlapping date ranges per instrument. |
| FK_HistorySplitRatio_TradeInstrument | FOREIGN KEY | InstrumentID -> Trade.Instrument. |
| CK_HistorySplitAmountPriceRatio | CHECK | AmountRatio > 0. |
| CK_HistorySplitRatioPriceRatio | CHECK | PriceRatio > 0. |
| CK_InstrumentIsStock | CHECK | InstrumentID > 1000 (stocks only). |
| DF_HistorySplitRatio_MinDate | DEFAULT | MinDate defaults to '2000-01-01'. |
| DF_HistorySplitRatio_MaxDate | DEFAULT | MaxDate defaults to '2100-01-01' (active sentinel). |
| DF_HistorySplitRatio_PriceRatio | DEFAULT | PriceRatio defaults to 1 (no adjustment). |
| DF_HistorySplitRatio_AmountRatio | DEFAULT | AmountRatio defaults to 1 (no adjustment). |

---

## 8. Sample Queries

### 8.1 Get current active split ratio for a specific instrument
```sql
SELECT
    ID,
    InstrumentID,
    PriceRatio,
    AmountRatio,
    UnitsBefore,
    UnitsAfter,
    MinDate,
    MaxDate
FROM [History].[SplitRatio] WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND MaxDate = '21000101'  -- active sentinel
```

### 8.2 Find splits in progress (not fully completed)
```sql
SELECT
    ID,
    InstrumentID,
    PriceRatio,
    AmountRatio,
    IsCompletedOpenPositions,
    IsCompletedClosePositions,
    IsCompletedOpenOrders,
    IsCompletedCloseOrders,
    IsCompleteHoldingFees,
    IsNotificationSent,
    MinDate
FROM [History].[SplitRatio] WITH (NOLOCK)
WHERE PriceRatio <> 1
  AND (IsCompletedOpenPositions = 0
    OR IsCompletedClosePositions = 0
    OR IsCompleteHoldingFees = 0)
ORDER BY MinDate DESC
```

### 8.3 Get applicable split ratio for a transaction at a historical date
```sql
SELECT PriceRatio, AmountRatio
FROM [History].[SplitRatio] WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND @TransactionDate >= MinDate
  AND @TransactionDate < MaxDate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.3/10 (Elements: 9.5/10, Logic: 10/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SplitRatio | Type: Table | Source: etoro/etoro/History/Tables/History.SplitRatio.sql*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `DWH_dbo.SP_Dim_HistorySplitRatio_DL_To_Synapse`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dim_HistorySplitRatio_DL_To_Synapse.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [DWH_dbo].[SP_Dim_HistorySplitRatio_DL_To_Synapse] AS
BEGIN

-- =============================================
-- Author:     <Adi  Ferber>
-- Create Date: 2021-10-12
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].[SP_Dim_History_SplitRatio_DL_To_Synapse]
-- =============================================



 --truncate table [DWH_dbo].[History_SplitRatio] ----------------------------


    truncate table [DWH_dbo].[Dim_HistorySplitRatio]
--------------------------------------------------
-- --Insert data into [DWH_dbo].[History_SplitRatio] -------------------
	
	

	INSERT INTO [DWH_dbo].[Dim_HistorySplitRatio]
	(
	         ID	
			,InstrumentID	
			,MinDate	
			,MaxDate	
			,PriceRatio	
			,AmountRatio	
			,PriceRatioUnAdjusted  
			,AmountRatioUnAdjusted 
			,UpdateDate 
	  )

	 SELECT
			 ID	
			,InstrumentID	
			,MinDate	
			,MaxDate	
			,PriceRatio	
			,AmountRatio	
			,PriceRatioUnAdjusted  
			,AmountRatioUnAdjusted 
			,Getdate() AS UpdateDate
	From [DWH_staging].[etoro_History_SplitRatio]



END

GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio` | unresolved | dwh | gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio | `—` |
| `PriceLog.History.SplitRatio` | production | History | SplitRatio | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\History\Tables\History.SplitRatio.md` |
| `DWH_dbo.SP_Dim_HistorySplitRatio_DL_To_Synapse` | synapse_sp | DWH_dbo | SP_Dim_HistorySplitRatio_DL_To_Synapse | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dim_HistorySplitRatio_DL_To_Synapse.sql` |
| `DWH_staging.etoro_History_SplitRatio` | unresolved | DWH_staging | etoro_History_SplitRatio | `—` |
