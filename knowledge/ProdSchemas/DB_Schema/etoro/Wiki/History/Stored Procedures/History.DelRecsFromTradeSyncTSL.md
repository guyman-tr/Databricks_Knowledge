# History.DelRecsFromTradeSyncTSL

> Stage 2 of the TSL sync pipeline: atomically moves confirmed TSL adjustment records (Status IN (2,3)) from Trade.SyncTSL to History.SyncTSL in batches of 500, using DELETE...OUTPUT INTO for atomic move semantics.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; processes Trade.SyncTSL WHERE Status IN (2,3) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

The Trailing Stop Loss (TSL) synchronization pipeline moves TSL adjustment events from the real-time trading engine to the DAG analytics/downstream system in three stages. This procedure is **Stage 2**: it transfers confirmed TSL events from `Trade.SyncTSL` (the live trading queue) into `History.SyncTSL` (the staging area for DAG export).

A TSL event enters `Trade.SyncTSL` with Status=0 (pending) when the trading engine adjusts a trailing stop-loss. After the trading engine confirms the adjustment (Status=2 or Status=3), this procedure moves the confirmed records to `History.SyncTSL`. The move is atomic per batch: `DELETE...OUTPUT INTO` deletes from Trade.SyncTSL and inserts into History.SyncTSL simultaneously, preventing any window where the record exists in neither table. Processing is batched at 500-ID windows to avoid long lock durations.

See also: `History.DelRecsFromTradeSyncTSL111` - an enhanced successor with TRY/CATCH error handling and a temp table buffer that routes failed rows to `History.SyncTSLError`.

---

## 2. Business Logic

### 2.1 Batched Atomic Move (DELETE...OUTPUT INTO)

**What**: Moves batches of confirmed TSL records from Trade.SyncTSL to History.SyncTSL atomically.

**Columns/Parameters Involved**: `@MinRecID`, `@MaxRecID`, `Status` (Trade.SyncTSL)

**Rules**:
- Reads `MIN(ID)` and `MAX(ID)` from Trade.SyncTSL WHERE `Status IN (2,3)`. If NULL (no confirmed records), exits immediately.
- WHILE loop processes IDs in windows of 500: `WHERE ID >= @MinRecID AND ID <= @MinRecID + 500 AND Status IN (2,3)`.
- `DELETE...OUTPUT DELETED.* INTO History.SyncTSL` is atomic: the row is removed from Trade.SyncTSL and inserted into History.SyncTSL in one operation.
- `SET DEADLOCK_PRIORITY LOW` means this procedure loses deadlocks to higher-priority sessions (trading engine gets priority).
- `WITH (READPAST)` on the DELETE skips locked rows, allowing the trading engine to hold locks without blocking this cleanup.
- `Status` is NOT archived: History.SyncTSL has no Status column - all archived rows were confirmed (Status=2 or 3) at archive time.

**Trade.SyncTSL Status values** (discovered from code context):
| Value | Meaning |
|-------|---------|
| 0 | Pending - inserted by trading engine, awaiting confirmation |
| 2 | Confirmed - eligible for archiving by this procedure |
| 3 | Confirmed (alternate) - also eligible for archiving |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

*This procedure takes no parameters.*

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (no parameters) | - | - | - | CODE-BACKED | This procedure has no input parameters. Scope is determined by Trade.SyncTSL.Status IN (2,3). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE + OUTPUT INTO | Trade.SyncTSL | Write (Delete) | Removes confirmed (Status IN (2,3)) records in 500-ID batches. Source of TSL events. |
| INSERT (via OUTPUT) | History.SyncTSL | Write (Insert) | Receives the deleted records as the staging area for DAG export. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent job (scheduled) | EXEC call | Scheduler | Called periodically to move confirmed TSL events from the trading queue. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.DelRecsFromTradeSyncTSL (procedure)
├── Trade.SyncTSL (table) [cross-schema - DELETE source]
└── History.SyncTSL (table) [INSERT target]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SyncTSL | Table | DELETE source (WITH READPAST) - confirmed TSL events are atomically removed and transferred. |
| History.SyncTSL | Table | INSERT target via OUTPUT clause - receives archived TSL records. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.SyncTSL | Table | Populated by this procedure with confirmed TSL events from Trade.SyncTSL. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET DEADLOCK_PRIORITY LOW | Deadlock handling | This procedure yields to the trading engine if a deadlock occurs. |
| WITH (READPAST) | Lock skip | Skips locked rows, allowing the trading engine to operate without blocking this archiving procedure. |
| 500-ID window batching | Performance | Keeps lock duration short; each batch covers at most 500 ID slots (may be fewer actual rows if gaps exist). |

---

## 8. Sample Queries

### 8.1 Check confirmed TSL events pending archiving

```sql
SELECT COUNT(*) AS PendingArchive,
       MIN(ID) AS MinID,
       MAX(ID) AS MaxID
FROM Trade.SyncTSL WITH (NOLOCK)
WHERE Status IN (2, 3);
```

### 8.2 Check recently archived TSL events in History.SyncTSL

```sql
SELECT TOP 10 *
FROM History.SyncTSL WITH (NOLOCK)
ORDER BY DateInserted DESC;
```

### 8.3 Check the full TSL archive for a specific position

```sql
SELECT ID, PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy, DateInserted
FROM History.SyncTSL WITH (NOLOCK)
WHERE PositionID = 12345678
ORDER BY DateInserted;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.DelRecsFromTradeSyncTSL | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.DelRecsFromTradeSyncTSL.sql*
