# Trade.PositionTblRep_Log

> Replication log for Trade.PositionTbl. Tracks which PositionIDs have been replicated to a reporting or secondary database. Single-column table on DICTIONARY filegroup.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | PositionID |
| **Partition** | DICTIONARY filegroup |
| **Live DB** | Exists, 0 rows |
| **Indexes** | IDX_PositionTblRep_Log (PositionID) FILLFACTOR=90 |

---

## 1. Business Meaning

Trade.PositionTblRep_Log is a simple tracking table used during replication of position data. When a position in Trade.PositionTbl is replicated (likely to a reporting or secondary database), its PositionID is logged here. This allows the replication process to know which positions have been sent and which still need to be replicated. The "Rep_Log" suffix means Replication Log.

The table is currently empty (0 rows in live), which suggests either replication is not active, or the backlog has been fully processed and the log cleared. The table resides on the DICTIONARY filegroup, which typically holds small reference data.

---

## 2. Business Logic

### 2.1 Log and Clear Pattern

**What**: PositionIDs are inserted when replicated, then removed once the replication consumer acknowledges or the backlog is cleared.

**Columns/Parameters Involved**: `PositionID`

**Rules**:
- INSERT when a position is queued or sent for replication
- DELETE when replication is confirmed or log is purged
- Empty table = no pending replication or caught up

---

## 3. Data Overview

| PositionID | Meaning |
|------------|---------|
| (Empty) | Table has 0 rows. No positions currently logged for replication. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | PositionID from Trade.PositionTbl. Logged when replicated. |

---

## 5. Relationships

### 5.1 References To

- Trade.PositionTbl (PositionID) - Source of position data

### 5.2 Referenced By

- Replication procedures or jobs that read/write this log (exact procedures not enumerated here)

---

## 6. Dependencies

### 6.0 Dependency Chain

Trade.PositionTbl -> Trade.PositionTblRep_Log

### 6.1 Objects This Depends On

Trade.PositionTbl

### 6.2 Objects That Depend On This

Replication-related procedures (reader/writer for log)

---

## 7. Technical Details

### 7.1 Indexes

- IDX_PositionTblRep_Log: (PositionID) FILLFACTOR=90 ON [DICTIONARY]

### 7.2 Constraints

- None specified in provided DDL

---

*Generated: 2026-03-14 | Quality: 6.5/10*
