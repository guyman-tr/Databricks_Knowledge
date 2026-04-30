# Trade.FlushTSLForSpecificTree

> Processes pending Trailing Stop Loss (TSL) sync records for a specific position, resolving conflicts with manual SL changes, and applying the best stop-loss rate to Trade.PositionTreeInfo.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (position/tree whose TSL is being flushed) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FlushTSLForSpecificTree processes queued Trailing Stop Loss (TSL) updates for a specific position. Trailing stop loss is a dynamic stop-loss mechanism that moves the stop rate in the direction of profit as the market moves favorably. TSL events are queued in Trade.SyncTSL (Status=0) and this procedure flushes them into Trade.PositionTreeInfo.

The procedure handles the complexity of TSL conflict resolution: if a user manually changes their stop loss while TSL events are pending, the manual change takes precedence (tracked via SLManualVer). It also ensures that for buy positions, only upward stop-loss movements are applied (closer to profit protection), and for sell positions, only downward movements.

Created with conditions added by Adam Porat on 2021-03-31 (TRAD-4315).

---

## 2. Business Logic

### 2.1 TSL Event Processing

**What**: Reads pending TSL events and applies the best stop-loss to PositionTreeInfo.

**Columns/Parameters Involved**: `PositionID`, `StopLoss`, `SLManualVer`, `NextThresHold`, `IsBuy`, `Status`

**Rules**:
- Reads up to 1000 pending records (Status=0) for the given PositionID from Trade.SyncTSL
- Marks them Status=3 (in-progress) via OUTPUT clause to prevent re-processing
- Deletes records whose SLManualVer is less than the maximum (user manually changed SL after TSL queued)
- Deletes records with conflicting StopLoss values (keeps best: highest for buys, lowest for sells)
- Updates Trade.PositionTreeInfo.StopRate and NextThresHold only when:
  - SLManualVer in SyncTSL >= PTI.SLManualVer (no newer manual change)
  - For buys: new StopLoss > current StopRate (trailing up only)
  - For sells: new StopLoss < current StopRate (trailing down only)
- After processing: marks Trade.SyncTSL records as Status=2 (completed)

**Diagram**:
```
Trade.SyncTSL (Status=0, PositionID=@PositionID)
          |
     Read + mark Status=3 (up to 1000)
          |
     Filter: remove outdated SLManualVer
     Filter: remove non-best StopLoss values
          |
     UPDATE Trade.PositionTreeInfo
       WHERE SLManualVer valid
         AND StopLoss is improvement (buy: up, sell: down)
          |
     Mark Trade.SyncTSL Status=2 (done)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | The PositionID (which maps to TreeID in PositionTreeInfo) whose trailing stop loss events should be flushed from SyncTSL into the position's tree record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.SyncTSL | READ + UPDATE | Reads pending TSL events (Status=0), updates to Status=2 or 3 |
| TreeID | Trade.PositionTreeInfo | UPDATE | Applies new StopRate and NextThresHold from resolved TSL events |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FlushTSLForInstrumentID | (upstream) | EXEC | Likely calls this per-position from an instrument-level flush |
| TSL processing service | External | EXEC | Called by the trading engine when TSL events need flushing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FlushTSLForSpecificTree (procedure)
+-- Trade.SyncTSL (table)
+-- Trade.PositionTreeInfo (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SyncTSL | Table | READ (pending TSL events) + UPDATE (status transitions: 0->3->2) |
| Trade.PositionTreeInfo | Table | UPDATE (StopRate, NextThresHold) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FlushTSLForInstrumentID | Procedure | EXEC - instrument-level flush (upstream) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP 1000 batch | Safety | Processes at most 1000 TSL events per call to bound execution time |
| OUTPUT clause | Atomicity | Reads and marks records in a single atomic operation |
| Directional filtering | Business | Buys: only apply higher stop rates. Sells: only apply lower stop rates. |
| TRY/CATCH with THROW | Error handling | Re-throws exceptions to caller |

---

## 8. Sample Queries

### 8.1 Check pending TSL events for a position

```sql
SELECT ID, PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy, Status
FROM   Trade.SyncTSL WITH (NOLOCK)
WHERE  PositionID = 123456789
  AND  Status = 0
ORDER BY ID;
```

### 8.2 View current stop rate for a position tree

```sql
SELECT TreeID, StopRate, SLManualVer, NextThresHold
FROM   Trade.PositionTreeInfo WITH (NOLOCK)
WHERE  TreeID = 123456789;
```

### 8.3 Check TSL processing backlog

```sql
SELECT Status, COUNT(*) AS EventCount
FROM   Trade.SyncTSL WITH (NOLOCK)
GROUP BY Status;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FlushTSLForSpecificTree | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.FlushTSLForSpecificTree.sql*
