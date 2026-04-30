# History.SyncTSL

> Intermediate staging buffer for Trailing Stop Loss (TSL) adjustment events, en route to the DAG/analytics downstream system. When TSL records in Trade.SyncTSL reach Status IN (2,3), they are moved here via DELETE...OUTPUT INTO in batches of 500. From here, a TABLE SWITCH + BCP operation transfers the data to the DAG system, then this table is cleared.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (bigint, NONCLUSTERED PK - from Trade.SequenceSyncTSL sequence) |
| **Partition** | No - CLUSTERED on PositionID, NC PK on ID, both on [HISTORY] |
| **Indexes** | 2 (NONCLUSTERED PK on ID, CLUSTERED on PositionID) |

---

## 1. Business Meaning

This table is a **staging area** in the TSL (Trailing Stop Loss) synchronization pipeline between the eToro trading engine and the DAG analytics/downstream system. It holds TSL adjustment events that have been confirmed by the trading engine (Status=2 or 3 in Trade.SyncTSL) and are awaiting batch transfer to the DAG system via BCP.

**What is a TSL (Trailing Stop Loss)?** A TSL is a dynamic stop-loss that adjusts upward as the market price moves in the customer's favor. Unlike a fixed stop-loss, TSL tracks the market price at a fixed distance or percentage, locking in profits as the price rises. When the price reverses by the configured threshold, the position closes at the TSL level.

Each row here represents a TSL adjustment event: the new stop-loss price, the next threshold at which the TSL will trigger again, and which direction (buy/sell) the position is in.

The table has 0 rows in the current (clone) environment - this is expected as the table is transient: records are written, then immediately BCP'd to DAG and cleared.

**Companion tables**:
- `Trade.SyncTSL`: live queue; source of records moved here
- `History.SyncTSLSwitch`: structural twin used in the TABLE SWITCH operation (same schema)
- `History.SyncTSL_INT`: legacy int-based version (pre-bigint PositionID migration, Nov 2021)
- `History.SyncTSLError`: errors in the TSL sync pipeline

---

## 2. Business Logic

### 2.1 TSL Event Pipeline Overview

**What**: A 3-stage pipeline moves TSL events from the trading engine through to the DAG system.

**Stage 1 - Trade.InsertTSLDataToSyncTbl** (writes to Trade.SyncTSL):
```sql
INSERT INTO Trade.SyncTSL (PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy)
SELECT PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy
FROM @TSLInfo  -- Trade.SyncTSLTblType TVP: batch of TSL updates
-- ID defaults to NEXT VALUE FOR Trade.SequenceSyncTSL
-- Status defaults to 0
-- DateInserted defaults to getutcdate()
```

**Stage 2 - History.DelRecsFromTradeSyncTSL** (moves Trade.SyncTSL -> History.SyncTSL):
```sql
-- Processes batches of 500 records at a time:
DELETE Trade.SyncTSL WITH (READPAST)
OUTPUT DELETED.ID, DELETED.PositionID, DELETED.StopLoss, DELETED.SLManualVer,
       DELETED.NextThresHold, DELETED.IsBuy, DELETED.DateInserted
INTO History.SyncTSL(ID, PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy, DateInserted)
WHERE ID >= @MinRecID AND ID <= @MinRecID + 500 AND ID <= @MaxRecID AND Status IN (2,3)
```
Note: `Status` is dropped - it is NOT preserved in History.SyncTSL (its value at time of archive was 2 or 3 = confirmed/processed).

**Stage 3 - History.MoveRecsFromTradeSyncTSLToPass** (sends to DAG, clears):
```sql
-- Step A: Atomic switch (zero-downtime clear of History.SyncTSL):
ALTER TABLE [History].[SyncTSL] SWITCH TO [History].[SyncTSLSwitch]

-- Step B: BCP to DAG/pass system:
EXEC History.MoveRecsFromHistorySyncTSLToPass_BCP  -- returns 1 on success

-- Step C: Clear switch table if BCP succeeded:
TRUNCATE TABLE [History].[SyncTSLSwitch]
```

The TABLE SWITCH is near-instantaneous (metadata operation) - it avoids locking History.SyncTSL during the potentially slow BCP transfer.

### 2.2 TSL Price Data Types

**What**: Price columns use `dbo.dtPrice` (a UDT for exchange rates and stop-loss prices).

**Columns/Parameters Involved**: `StopLoss`, `NextThresHold`

**Rules**:
- `dbo.dtPrice` is a precision decimal type used consistently across the History schema for price data
- `StopLoss`: the new absolute stop-loss price after the TSL adjustment
- `NextThresHold`: the next trigger price at which the TSL will need to adjust again (the threshold the market must reach to cause another upward TSL move)
- Both are bigint or decimal values representing the exact price at a fixed precision

### 2.3 SLManualVer - Version Control for Manual Overrides

**What**: Tracks whether a manual stop-loss override supersedes the TSL calculation.

**Columns/Parameters Involved**: `SLManualVer`

**Rules**:
- `SLManualVer` is a version counter (smallint). When a customer manually sets a stop-loss on a TSL position, this version increments.
- The trading engine compares TSL-proposed SL values against the manual version to determine if the TSL adjustment should apply or if the manual override takes precedence.
- TSL configuration is per-instrument (from Atlassian: "The TSL configuration is different per instrument")

### 2.4 TSL in Corporate Actions

**What**: TSL thresholds are adjusted for stock splits.

**Rules** (from Atlassian): "TSL ref is updated by TSL ref * split ratio" on a stock split event. This ensures the TSL distance remains proportionally correct after a split.

---

## 3. Data Overview

Table has 0 rows in the current (clone) environment. This is expected - History.SyncTSL is a transient staging table that is typically empty or near-empty: records arrive from Trade.SyncTSL, are BCP'd to DAG, then the table is truncated (via the switch mechanism). In production, rows accumulate between processing cycles, then are cleared.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | - | CODE-BACKED | Unique event ID. Generated by `NEXT VALUE FOR Trade.SequenceSyncTSL` in Trade.SyncTSL and preserved via DELETE...OUTPUT INTO. NONCLUSTERED PK on [HISTORY] filegroup. bigint (changed from int in Nov 2021 migration). |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | The position whose TSL was adjusted. CLUSTERED index key on [HISTORY] filegroup (FILLFACTOR=85) - queries by position are the dominant access pattern. bigint (same Nov 2021 migration). |
| 3 | StopLoss | dbo.dtPrice | NO | - | CODE-BACKED | The new absolute stop-loss price after this TSL adjustment. Uses dbo.dtPrice (precision decimal UDT for price data). The price at which the position will be closed if the market reverses to this level. |
| 4 | SLManualVer | smallint | NO | - | CODE-BACKED | Version counter for manual stop-loss overrides on this position. Used by the trading engine to decide whether to apply the TSL update or respect a manual override. Smallint (range 0-32767). |
| 5 | NextThresHold | dbo.dtPrice | NO | - | CODE-BACKED | The next price threshold at which the TSL will trigger another upward adjustment. Uses dbo.dtPrice. Represents the target price the market must reach to cause the next TSL move. |
| 6 | IsBuy | bit | NO | - | CODE-BACKED | Position direction: 1=Buy (long, TSL adjusts upward as price rises), 0=Sell (short, TSL adjusts downward as price falls). |
| 7 | DateInserted | datetime | NO | - | CODE-BACKED | When the TSL event was originally created in Trade.SyncTSL. Reflects the actual time of the TSL adjustment in the trading engine, not the archive time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Trade.SyncTSL | ID | Source (DELETE...OUTPUT INTO) | Records are moved from Trade.SyncTSL (Status IN (2,3)) to here by History.DelRecsFromTradeSyncTSL. |
| Trade.PositionTbl / History.Position_Active | PositionID | Implicit FK | The position whose TSL was adjusted. bigint FK. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.DelRecsFromTradeSyncTSL | ID | Writer (DELETE...OUTPUT INTO) | Deletes from Trade.SyncTSL and outputs into this table in batches of 500 (Status IN (2,3) only). |
| History.MoveRecsFromTradeSyncTSLToPass | (all) | Consumer (TABLE SWITCH + BCP) | Switches this table to SyncTSLSwitch, BCP's data to DAG/pass system, truncates switch table. |
| History.SyncTSLSwitch | (all) | Switch target | Structural twin; History.SyncTSL SWITCH TO History.SyncTSLSwitch atomically clears this table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SyncTSL (staging table)
- Written by: History.DelRecsFromTradeSyncTSL
  - DELETE Trade.SyncTSL OUTPUT INTO History.SyncTSL WHERE Status IN (2,3)
  - Batches of 500 records
- Source: Trade.SyncTSL
  - Populated by Trade.InsertTSLDataToSyncTbl (TVP batch insert)
  - Status set to 2/3 by trading engine after confirmation
- Consumed by: History.MoveRecsFromTradeSyncTSLToPass
  - SWITCH to SyncTSLSwitch + BCP to DAG + TRUNCATE SyncTSLSwitch
  - Clears this table after successful DAG transfer
```

### 6.1 Objects This Depends On

No FK constraints. Implicit dependencies: Trade.SyncTSL (source), Trade.PositionTbl/History.Position_Active (PositionID).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.MoveRecsFromTradeSyncTSLToPass | SP | TABLE SWITCH source -> to SyncTSLSwitch + BCP to DAG |
| BackOffice.P_GetTrailingStopLossHistory | SP | Read (BackOffice/SSRS reporting) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistSyncTSL_BIGINT1 | NONCLUSTERED | ID ASC | - | - | Active (PAGE compression, HISTORY filegroup) |
| Idx_History_SyncTSL_PositionID_BIGINT11 | CLUSTERED | PositionID ASC | - | - | Active (FILLFACTOR=85, PAGE compression, HISTORY filegroup) |

The NONCLUSTERED PK + CLUSTERED on PositionID pattern matches `Trade.SyncTSL` exactly (except filegroup: Trade uses MAIN, History uses HISTORY). This alignment is required for the TABLE SWITCH to succeed (source and target must have identical structure and indexes).

### 7.2 Constraints

| Name | Type | Definition |
|------|------|------------|
| PK_HistSyncTSL_BIGINT1 | PRIMARY KEY | ID ASC - nonclustered |

Note: No DEFAULT constraints (DateInserted has DEFAULT in Trade.SyncTSL but not here; ID is a sequence in Trade.SyncTSL but not here - values are preserved via OUTPUT INTO).

---

## 8. Sample Queries

### 8.1 Check current staging queue size (operational monitoring)

```sql
SELECT COUNT(*) AS StagedRecords, MIN(DateInserted) AS OldestRecord, MAX(DateInserted) AS NewestRecord
FROM History.SyncTSL WITH (NOLOCK);
```

### 8.2 TSL event history for a specific position

```sql
SELECT
    h.ID,
    h.PositionID,
    h.StopLoss,
    h.NextThresHold,
    h.IsBuy,
    h.SLManualVer,
    h.DateInserted
FROM History.SyncTSL h WITH (NOLOCK)
WHERE h.PositionID = @PositionID
ORDER BY h.DateInserted DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | ID | Title | Relevance |
|--------|----|-------|-----------|
| Confluence | 2100232700 | Trailing Stop Loss | TSL product description: dynamic stop-loss adjusting upward with favorable price moves; TSL vs SL comparison; split adjustment rule (TSL ref * split ratio) |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.2/10, Relationships: 8.8/10, Sources: 8.8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed (History.DelRecsFromTradeSyncTSL, History.MoveRecsFromTradeSyncTSLToPass, Trade.InsertTSLDataToSyncTbl) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SyncTSL | Type: Table | Source: etoro/etoro/History/Tables/History.SyncTSL.sql*
