# Trade.PositionTreeInfoRep_Log

> Replication log for Trade.PositionTreeInfo. Tracks which TreeIDs have been replicated to a reporting or secondary database. Single-column table on DICTIONARY filegroup. Mirrors the pattern of Trade.PositionTblRep_Log.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | TreeID |
| **Partition** | DICTIONARY filegroup |
| **Live DB** | Exists, 0 rows |
| **Indexes** | IDX_PositionTreeInfoRep_Log (TreeID) FILLFACTOR=90 |

---

## 1. Business Meaning

Trade.PositionTreeInfoRep_Log is a replication tracking table for copy-trade tree data. When a row in Trade.PositionTreeInfo (shared SL/TP/TSL settings per tree) is replicated to a secondary or reporting system, its TreeID is logged here. This lets the replication process know which trees have been sent and which remain.

The structure mirrors Trade.PositionTblRep_Log but applies to position tree metadata instead of individual positions. The table is on the DICTIONARY filegroup. Currently empty (0 rows), suggesting replication is either inactive or fully caught up and cleared.

---

## 2. Business Logic

### 2.1 Log and Clear Pattern

**What**: TreeIDs are inserted when tree data is replicated, then removed when acknowledged or log is purged.

**Columns/Parameters Involved**: `TreeID`

**Rules**:
- INSERT when a PositionTreeInfo row is queued or sent
- DELETE when replication is confirmed or log cleared
- Empty = no pending tree replication

---

## 3. Data Overview

| TreeID | Meaning |
|--------|---------|
| (Empty) | Table has 0 rows. No trees currently logged for replication. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TreeID | bigint | NO | - | CODE-BACKED | TreeID from Trade.PositionTreeInfo. Logged when replicated. |

---

## 5. Relationships

### 5.1 References To

- Trade.PositionTreeInfo (TreeID) - Source of tree data

### 5.2 Referenced By

- Replication procedures or jobs that read/write this log

---

## 6. Dependencies

### 6.0 Dependency Chain

Trade.PositionTreeInfo -> Trade.PositionTreeInfoRep_Log

### 6.1 Objects This Depends On

Trade.PositionTreeInfo

### 6.2 Objects That Depend On This

Replication-related procedures (reader/writer for log)

---

## 7. Technical Details

### 7.1 Indexes

- IDX_PositionTreeInfoRep_Log: (TreeID) FILLFACTOR=90 ON [DICTIONARY]

### 7.2 Constraints

- None specified in provided DDL

---

*Generated: 2026-03-14 | Quality: 6.5/10*
