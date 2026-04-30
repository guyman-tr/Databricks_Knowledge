# Trade.PositionToReopen_Timeouts

> Captures reopen operations that timed out. When Trade.PositionToReopen processing fails due to timeout, failed rows are stored here for retry or investigation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | None (log table, no PK) |
| **Partition** | PRIMARY |
| **Live DB** | Exists, 0 rows |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.PositionToReopen_Timeouts is a fallout table for the position reopen workflow. When the system tries to reopen positions from Trade.PositionToReopen (as part of a ReopenOperation), some attempts may time out due to locking, network delays, or long-running validations. Instead of losing those rows, the system inserts them here. Operations staff can then retry manually or investigate the cause.

The table mirrors the structure of Trade.PositionToReopen with a subset of columns: ReopenOperationID, CID, ClosedPositionID, OrigParentPositionID, LevelID, and RequestOccurred. There is no primary key or indexes - it is a simple dump/log table. The table is currently empty (0 rows), indicating no recent timeouts.

---

## 2. Business Logic

### 2.1 Timeout Insert

**What**: When a position reopen times out, the row is moved or copied here.

**Columns/Parameters Involved**: All columns

**Rules**:
- Same ReopenOperationID, CID, ClosedPositionID semantics as Trade.PositionToReopen
- OrigParentPositionID and LevelID relate to copy-trade tree hierarchy
- RequestOccurred records when the reopen was requested

### 2.2 Retry or Investigation

**What**: Rows here are candidates for manual retry or root-cause analysis.

**Rules**:
- No automatic retry logic defined in provided context
- Operations can re-queue rows back to Trade.PositionToReopen if appropriate

---

## 3. Data Overview

| ReopenOperationID | CID | ClosedPositionID | OrigParentPositionID | LevelID | RequestOccurred | Meaning |
|-------------------|-----|------------------|----------------------|---------|-----------------|---------|
| (Empty) | - | - | - | - | - | Table has 0 rows. No timeout events captured recently. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReopenOperationID | int | NO | - | CODE-BACKED | FK to Trade.ReopenOperation. Parent operation. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. Owner of the closed position. |
| 3 | ClosedPositionID | bigint | NO | - | CODE-BACKED | PositionID of the position that was closed and should have been reopened. |
| 4 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Parent position in copy-trade tree. From history at close. |
| 5 | LevelID | int | YES | - | CODE-BACKED | Execution level (1=root, 2+=children) in reopen hierarchy. |
| 6 | RequestOccurred | datetime | NO | - | CODE-BACKED | When the reopen was requested. |

---

## 5. Relationships

### 5.1 References To

- Trade.ReopenOperation (ReopenOperationID)
- Trade.PositionToReopen (structural similarity)
- History.PositionSlim / History.Position (ClosedPositionID)

### 5.2 Referenced By

- Procedures that handle reopen timeouts and optionally retry (exact names not enumerated)

---

## 6. Dependencies

### 6.0 Dependency Chain

Trade.ReopenOperation, Trade.PositionToReopen -> Trade.PositionToReopen_Timeouts

### 6.1 Objects This Depends On

Trade.ReopenOperation, Trade.PositionToReopen

### 6.2 Objects That Depend On This

Timeout-handling and retry procedures

---

## 7. Technical Details

### 7.1 Indexes

None. Simple log table.

### 7.2 Constraints

None specified in provided DDL.

---

*Generated: 2026-03-14 | Quality: 7.0/10*
