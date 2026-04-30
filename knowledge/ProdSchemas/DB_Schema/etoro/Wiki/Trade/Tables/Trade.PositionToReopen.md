# Trade.PositionToReopen

> Queue table for closed positions that are pending reopen as part of a ReopenOperation (e.g. compensation for exchange forks, unaligned stop-loss adjustments).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | (ReopenOperationID, ClosedPositionID) |
| **Partition** | PRIMARY filegroup, MAIN for unique index |
| **Indexes** | 1 (UQ_ReopenOperation_PositionID) |

---

## 1. Business Meaning

Trade.PositionToReopen is a transient work queue that holds closed positions awaiting reopening. Each row links a closed position (ClosedPositionID) to a ReopenOperation, the customer (CID), and optional parent/level metadata. The table is populated when a reopen operation is initiated (manually or by jobs such as ReopenForUnalignedSlCryptoPositions), validated by Trade.ReopenOperationValidation, and then drained by Trade.PositionsReopen, which calls Trade.PositionReopen for each queued position.

Reopen operations exist to compensate customers when positions were closed under exceptional circumstances (e.g. crypto instrument forks, stop-loss alignment bugs) and need to be reopened with updated parameters. The queue ensures positions are processed in a controlled, auditable order: parent positions first (LevelID = 1), then children, with validation removing ineligible rows before execution.

Upon successful or failed reopen, each row is moved to History.PositionToReopen and deleted from this table. The table is therefore usually empty or sparse; data is short-lived and flows through validation and execution pipelines.

---

## 2. Business Logic

### 2.1 Lifecycle

1. **Insert**: Trade.ReopenOperationAdd creates a ReopenOperation. Callers then INSERT into Trade.PositionToReopen (ReopenOperationID, CID, ClosedPositionID[, RequestOccurred]). Sources include Trade.ReopenForUnalignedSlCryptoPositions (automated crypto SL alignment) and manual/application workflows.
2. **Validation**: Trade.ReopenOperationValidation enriches LevelID and OrigParentPositionID, removes invalid rows (US users, open positions, inactive mirrors, orphaned children), and moves failures to History.PositionToReopen.
3. **Execution**: Trade.PositionsReopen iterates by LevelID and ClosedPositionID, calling Trade.PositionReopen per row. On success or failure, the row is written to History.PositionToReopen and deleted from Trade.PositionToReopen.
4. **Cancel**: Trade.ReopenOperationCancel moves all remaining rows to History.PositionToReopen with Result=0 and FailReason='Reopen Operation Canceled'.

### 2.2 LevelID and OrigParentPositionID

LevelID and OrigParentPositionID are set during validation. Manual positions (MirrorID=0) get LevelID=1. Copy-traded children start with LevelID=NULL; a WHILE loop assigns levels based on parent presence in the queue or History.PositionToReopen. Child positions without a valid parent in the queue or in Trade.Position are removed.

---

## 3. Data Overview

| ReopenOperationID | CID | ClosedPositionID | OrigParentPositionID | LevelID | RequestOccurred | Meaning |
|------------------|-----|------------------|----------------------|---------|-----------------|---------|
| 12345 | 100001 | 9876543210 | NULL | 1 | 2026-03-14 10:00:00 | Root manual position queued for reopen |
| 12345 | 100002 | 9876543211 | 9876543210 | 2 | 2026-03-14 10:00:00 | Child copy-trade position, parent 9876543210 |
| (Empty - transient queue) | | | | | | Table often empty when no reopen in progress |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReopenOperationID | int | NO | - | VERIFIED | FK to Trade.ReopenOperation. Identifies the reopen batch. |
| 2 | CID | int | NO | - | VERIFIED | Customer ID. Must match the closed position owner. |
| 3 | ClosedPositionID | bigint | NO | - | VERIFIED | PositionID from History.PositionSlim of the closed position to reopen. |
| 4 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | ParentPositionID from History at close. Set during validation for hierarchy. |
| 5 | LevelID | int | YES | - | CODE-BACKED | Execution order: 1 = root, 2+ = children. NULL for copy-trade children until assigned. |
| 6 | RequestOccurred | datetime | NO | getutcdate() | VERIFIED | When the reopen was requested. |

---

## 5. Relationships

### 5.1 References To

- Trade.ReopenOperation (ReopenOperationID) - Parent operation
- History.PositionSlim / History.Position (ClosedPositionID) - Closed position metadata
- Trade.PositionTbl (ClosedPositionID) - To detect if position is still open
- Trade.Mirror (via History for MirrorID) - Copy-trade validity
- Customer (CID) - Customer identity

### 5.2 Referenced By

- Trade.PositionsReopen - Reads and processes queue
- Trade.PositionReopen - Called per row, reads and deletes
- Trade.ReopenOperationValidation - Reads, updates, deletes invalid rows
- Trade.ReopenOperationCancel - Deletes all for operation
- Trade.ReopenOperationSendApprovalRequest - Reads for approval email
- Trade.ReopenForUnalignedSlCryptoPositions - Inserts
- History.PositionToReopen - Receives moved rows (archive)

---

## 6. Dependencies

### 6.0 Dependency Chain

Trade.ReopenOperation -> Trade.PositionToReopen -> History.PositionToReopen

### 6.1 Objects This Depends On

Trade.ReopenOperation, History.PositionSlim, History.Position, Trade.PositionTbl, Trade.Mirror, Customer.CustomerMoney

### 6.2 Objects That Depend On This

Trade.PositionsReopen, Trade.PositionReopen, Trade.ReopenOperationValidation, Trade.ReopenOperationCancel, Trade.ReopenOperationSendApprovalRequest, Trade.ReopenForUnalignedSlCryptoPositions, History.PositionToReopen

---

## 7. Technical Details

### 7.1 Indexes

- UQ_ReopenOperation_PositionID (UNIQUE NONCLUSTERED): (ReopenOperationID, ClosedPositionID) ON [MAIN]. Prevents duplicate position per operation. FILLFACTOR 95, DATA_COMPRESSION PAGE.

### 7.2 Constraints

- DF_PositionToReopen_RequestOccurred: DEFAULT (getutcdate()) FOR RequestOccurred

---

## 8. Sample Queries

```sql
-- Pending positions for a reopen operation
SELECT ptr.ReopenOperationID, ptr.CID, ptr.ClosedPositionID, ptr.LevelID, ptr.RequestOccurred
FROM Trade.PositionToReopen ptr WITH (NOLOCK)
WHERE ptr.ReopenOperationID = 12345
ORDER BY ptr.LevelID, ptr.ClosedPositionID;

-- Count by operation
SELECT ReopenOperationID, COUNT(*) AS PendingCount
FROM Trade.PositionToReopen WITH (NOLOCK)
GROUP BY ReopenOperationID;

-- Join to operation and history
SELECT ptr.*, ro.UserName, ro.Occurred AS OpOccurred
FROM Trade.PositionToReopen ptr WITH (NOLOCK)
JOIN Trade.ReopenOperation ro WITH (NOLOCK) ON ro.ReopenOperationID = ptr.ReopenOperationID
WHERE ptr.ReopenOperationID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.5/10*
