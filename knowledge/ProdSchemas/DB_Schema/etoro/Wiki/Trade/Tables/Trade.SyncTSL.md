# Trade.SyncTSL

> The Trailing Stop Loss (TSL) synchronization table that stores TSL state for positions with trailing stop enabled, enabling the stop loss to trail upward (for buys) or downward (for sells) as price moves favorably.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (BIGINT, NONCLUSTERED PK), clustered on PositionID |
| **Partition** | No |
| **Indexes** | 4 active (NC PK, clustered on PositionID, IX_TradeSyncTSL_StatusID_New, IX_cov4delete, ix_TradeSyncTSL_New) |

---

## 1. Business Meaning

Trade.SyncTSL is the Trailing Stop Loss (TSL) synchronization table. When a customer enables trailing stop loss on a position, the system tracks the current stop loss price, the next threshold that triggers an adjustment, and the version of any manual stop loss override. This table holds that state and propagates it across replicated database instances so that TSL logic works consistently whether the position is accessed from the primary or a subscriber.

This table exists because TSL is a dynamic feature: as market price moves favorably, the stop loss "trails" (moves closer to current price) to lock in gains. The state must be persisted and synchronized so that replication subscribers, background jobs, and application services all see the same TSL parameters. Without SyncTSL, trailing stop adjustments would be lost or inconsistent across environments. Procedures like Trade.InsertTSLDataToSyncTbl, Trade.FlushTSLForInstrumentID, and Trade.FlushTSLForSpecificTree populate and maintain this table.

Data flows: Inserted by Trade.InsertTSLDataToSyncTbl when TSL is enabled or updated. Status transitions from 0 (New) to 2 (Synced/Active) as the row is propagated, then to 3 (Processed/Completed) when the position closes or TSL is flushed. Rows are read by sync consumers and by the TSL adjustment logic. The table uses Trade.SequenceSyncTSL for ID allocation and has PAGE compression on all indexes.

---

## 2. Business Logic

### 2.1 TSL Status Lifecycle

**What**: Rows progress through sync states from new to active to completed.

**Columns/Parameters Involved**: `Status`, `PositionID`, `ID`, `DateInserted`

**Rules**:
- Status=0 (New): Row freshly inserted, awaiting propagation to subscribers
- Status=2 (Synced/Active): Row has been synchronized; TSL is actively applied. Majority of rows (21.3M) are in this state
- Status=3 (Processed/Completed): Position closed or TSL flushed; row retained for history. ~1.16M rows
- DateInserted records when the row was created for audit and ordering
- IX_cov4delete is filtered WHERE Status IN (2,3) to optimize cleanup or status-based queries

**Diagram**:
```
[InsertTSLDataToSyncTbl] -> INSERT Status=0 (New)
        |
        v
  [Sync propagation] -> UPDATE Status=2 (Synced/Active)
        |
        v
[Position close / FlushTSL] -> UPDATE Status=3 (Processed/Completed)
```

### 2.2 NextThresHold and Stop Loss Trailing

**What**: NextThresHold is the price level that triggers the next TSL adjustment when reached.

**Columns/Parameters Involved**: `NextThresHold`, `StopLoss`, `IsBuy`, `SLManualVer`

**Rules**:
- For buy positions (IsBuy=1): Price moves up -> StopLoss trails up. NextThresHold is the next higher threshold
- For sell positions (IsBuy=0): Price moves down -> StopLoss trails down. NextThresHold is the next lower threshold
- When market price reaches NextThresHold, the TSL logic updates StopLoss and sets a new NextThresHold
- SLManualVer tracks manual stop loss version; used to detect when the user has manually changed the stop and prevent overwriting
- dbo.dtPrice is the price data type used for StopLoss and NextThresHold

---

## 3. Data Overview

| ID | PositionID | StopLoss | SLManualVer | NextThresHold | IsBuy | Status | DateInserted | Meaning |
|---|---|---|---|---|---|---|---|---|
| 22478361 | 2152972353 | 41612.82 | 1 | 104027.11 | 1 | 2 | 2026-03-14 | Active TSL for a buy position. Stop loss trails at 41612.82; next adjustment when price reaches 104027.11. Manual version 1. |
| (sample Status=3) | (varies) | (varies) | (varies) | (varies) | (varies) | 3 | (varies) | Completed row - position closed or TSL flushed. Retained for history. ~1.16M such rows. |
| (sample Status=0) | (varies) | (varies) | (varies) | (varies) | (varies) | 0 | (varies) | New row awaiting sync propagation. Short-lived before moving to Status=2. |

**Selection criteria for the 5 rows:**
- Table has ~22.4M rows. Status=2 dominates (21.3M); Status=3 has 1.16M. Sample shows representative buy position with active TSL state.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | NEXT VALUE FOR Trade.SequenceSyncTSL | CODE-BACKED | Primary key. Allocated from Trade.SequenceSyncTSL sequence. Ensures unique IDs across replicated instances (sequence not replicated). |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | FK to Trade.PositionTbl.PositionID. The position for which this TSL state applies. Clustered index key for PositionID-centric queries. |
| 3 | StopLoss | dbo.dtPrice | NO | - | CODE-BACKED | Current trailing stop loss price. For buys, trails upward as price rises; for sells, trails downward as price falls. |
| 4 | SLManualVer | smallint | NO | - | CODE-BACKED | Manual stop loss version number. Incremented when user manually adjusts stop loss. Used to detect overrides and prevent TSL logic from overwriting user changes. |
| 5 | NextThresHold | dbo.dtPrice | NO | - | CODE-BACKED | The price level that, when reached by market price, triggers the next TSL adjustment. For buys: next higher threshold; for sells: next lower. |
| 6 | IsBuy | bit | NO | - | CODE-BACKED | Direction of position: 1 = buy (stop trails up), 0 = sell (stop trails down). Determines whether StopLoss and NextThresHold move upward or downward. |
| 7 | Status | tinyint | NO | 0 | CODE-BACKED | Sync state: 0=New (awaiting propagation), 2=Synced/Active (TSL applied), 3=Processed/Completed (position closed or flushed). Filtered index IX_cov4delete on Status IN (2,3). |
| 8 | DateInserted | datetime | NO | GETUTCDATE() | CODE-BACKED | When this TSL state row was inserted. UTC. Used for ordering and audit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Lookup | The open or closed position that has TSL enabled. Each row tracks TSL state for one position. |
| StopLoss, NextThresHold | dbo.dtPrice | UDT | Price values stored in the dbo.dtPrice user-defined type. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertTSLDataToSyncTbl | (writes) | Procedure | Inserts new TSL rows when TSL is enabled or updated. |
| Trade.FlushTSLForInstrumentID | (writes) | Procedure | Flushes TSL rows for positions on a given instrument. |
| Trade.FlushTSLForSpecificTree | (writes) | Procedure | Flushes TSL rows for positions in a specific copy-trade tree. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SyncTSL (table)
├── Trade.SequenceSyncTSL (sequence) - ID default
└── dbo.dtPrice (type) - StopLoss, NextThresHold
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SequenceSyncTSL | Sequence | DEFAULT for ID column |
| dbo.dtPrice | User Defined Type | Data type for StopLoss, NextThresHold |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertTSLDataToSyncTbl | Procedure | Inserts rows |
| Trade.FlushTSLForInstrumentID | Procedure | Updates/flushes by InstrumentID |
| Trade.FlushTSLForSpecificTree | Procedure | Updates/flushes by tree |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (implied) | NC PK | ID | - | - | Active |
| Idx_Trade_SyncTSL_PositionID_New | CLUSTERED | PositionID | - | - | Active |
| IX_TradeSyncTSL_StatusID_New | NC | Status, PositionID | - | - | Active |
| IX_cov4delete | NC | ID, Status | StopLoss, SLManualVer, NextThresHold, IsBuy, DateInserted | WHERE Status IN (2,3) | Active |
| ix_TradeSyncTSL_New | NC | Status, ID | PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy | - | Active |

All indexes use DATA_COMPRESSION = PAGE.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DEFAULT for ID | DEFAULT | NEXT VALUE FOR Trade.SequenceSyncTSL |
| DEFAULT for Status | DEFAULT | 0 (New) |
| DEFAULT for DateInserted | DEFAULT | GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 List active TSL rows for a position

```sql
SELECT ID, PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy, Status, DateInserted
FROM Trade.SyncTSL WITH (NOLOCK)
WHERE PositionID = 2152972353;
```

### 8.2 Count rows by Status

```sql
SELECT Status, COUNT(*) AS RowCount
FROM Trade.SyncTSL WITH (NOLOCK)
GROUP BY Status
ORDER BY Status;
```

### 8.3 Find positions with TSL needing sync (Status=0)

```sql
SELECT s.ID, s.PositionID, s.StopLoss, s.NextThresHold, s.IsBuy, s.DateInserted
FROM Trade.SyncTSL s WITH (NOLOCK)
WHERE s.Status = 0
ORDER BY s.DateInserted;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.2/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SyncTSL | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.SyncTSL.sql*
