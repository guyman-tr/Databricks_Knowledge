# Trade.MirrorToReopen

> Stores mirrors (CopyTrader relationships) queued to be reopened as part of a ReopenOperation (ReopenTypeID = 2).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | (ReopenOperationID, ClosedMirrorID) |
| **Partition** | None; on MAIN filegroup |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

Trade.MirrorToReopen is a transient queue table that holds closed CopyTrader mirror relationships awaiting reopen within a ReopenOperation. When a user's mirror (copy relationship to a trading guru) is closed and the business decides to reopen it, a ReopenOperation is created with ReopenTypeID = 2 (Mirror). The closed mirror IDs and associated customer IDs are inserted into MirrorToReopen.

The table enables batch processing of mirror reopens. Trade.MirrorsReopen iterates over rows for a given ReopenOperationID, calling Trade.MirrorReopen for each. On success, the row is moved to History.MirrorToReopen and deleted from this table. On failure, the row is also moved to History with Result=0 and FailReason, then deleted.

The lifecycle mirrors Trade.PositionToReopen but operates on mirrors (CopyTrader relationships) instead of positions. Reopen operations can be manual (back-office initiated) or automated. Trade.ReopenOperationCancel moves pending rows to History when an operation is canceled.

---

## 2. Business Logic

### 2.1 Mirror Reopen Queue

Rows are inserted by callers after Trade.ReopenOperationAdd creates a ReopenOperation with ReopenTypeID = 2. Trade.MirrorsReopen reads from MirrorToReopen joined to Trade.ReopenOperation, orders by ClosedMirrorID, and executes Trade.MirrorReopen for each. Each processed row is deleted and written to History.MirrorToReopen with ReopenMirrorID (success) or FailReason (failure).

### 2.2 Cancellation

Trade.ReopenOperationCancel, when ReopenTypeID = 2, deletes all rows for the operation and outputs them into History.MirrorToReopen with Result=0 and FailReason='Reopen Operation Canceled'.

---

## 3. Data Overview

| ReopenOperationID | CID | ClosedMirrorID | RequestOccurred | Meaning |
|-------------------|-----|----------------|-----------------|---------|
| 123 | 45678 | 999 | 2025-03-14 10:00:00 | Mirror 999 for customer 45678 queued in operation 123 |
| - | - | - | - | Transient; table often empty when no mirror reopen in progress |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReopenOperationID | int | NO | - | VERIFIED | FK to Trade.ReopenOperation. Operation that owns this reopen request. |
| 2 | CID | int | NO | - | VERIFIED | Customer ID; must match the closed mirror's CID. |
| 3 | ClosedMirrorID | int | NO | - | VERIFIED | Closed mirror ID from History.Mirror (MirrorOperationID = 2 = UnRegister). |
| 4 | RequestOccurred | datetime | NO | GETUTCDATE() | VERIFIED | UTC when the reopen request was queued. |

---

## 5. Relationships

### 5.1 References To

| Referenced Object | Key | Relationship |
|------------------|-----|--------------|
| Trade.ReopenOperation | ReopenOperationID | Parent operation; ReopenTypeID=2 for mirrors |
| Customer (implicit) | CID | Customer whose mirror is to be reopened |
| History.Mirror (implicit) | ClosedMirrorID | Source of closed mirror data |

### 5.2 Referenced By

| Object | Usage |
|--------|-------|
| Trade.MirrorsReopen | Cursor reads rows, joins ReopenOperation |
| Trade.MirrorReopen | Reads and deletes row after processing |
| Trade.ReopenOperationCancel | Deletes rows on cancel, outputs to History |
| History.MirrorToReopen | Receives moved rows (success or failure) |

---

## 6. Dependencies

### 6.0 Dependency Chain

Trade.ReopenOperation -> Trade.MirrorToReopen -> History.MirrorToReopen

### 6.1 Objects This Depends On

| Object | Type | Purpose |
|--------|------|---------|
| Trade.ReopenOperation | Table | ReopenOperationID, ReopenTypeID |

### 6.2 Objects That Depend On This

| Object | Type | Purpose |
|--------|------|---------|
| Trade.MirrorsReopen | Procedure | Iterates and triggers MirrorReopen |
| Trade.MirrorReopen | Procedure | Processes single mirror, deletes row |
| Trade.ReopenOperationCancel | Procedure | Cancels operation, moves rows to History |
| History.MirrorToReopen | Table | Audit of processed requests |

---

## 7. Technical Details

### 7.1 Indexes

| Name | Type | Key Columns | Purpose |
|-----|------|-------------|---------|
| PK_Dictionary_ReopenType | Clustered PK | ReopenOperationID, ClosedMirrorID | Uniqueness and fast lookup by operation |

### 7.2 Constraints

| Name | Type | Definition |
|-----|------|------------|
| PK_Dictionary_ReopenType | PRIMARY KEY | (ReopenOperationID, ClosedMirrorID) |
| DF_MirrorToReopen_RequestOccurred | DEFAULT | GETUTCDATE() for RequestOccurred |

---

## 8. Sample Queries

```sql
-- Pending mirror reopens for an operation
SELECT ReopenOperationID, CID, ClosedMirrorID, RequestOccurred
FROM Trade.MirrorToReopen WITH (NOLOCK)
WHERE ReopenOperationID = @ReopenOperationID
ORDER BY ClosedMirrorID;

-- Count mirrors queued per operation
SELECT ReopenOperationID, COUNT(*) AS MirrorsQueued
FROM Trade.MirrorToReopen WITH (NOLOCK)
GROUP BY ReopenOperationID;

-- Operations with pending mirror reopens
SELECT mtr.ReopenOperationID, tro.Occurred, tro.UserName, tro.ReopenTypeID
FROM Trade.MirrorToReopen mtr WITH (NOLOCK)
JOIN Trade.ReopenOperation tro WITH (NOLOCK) ON mtr.ReopenOperationID = tro.ReopenOperationID
WHERE tro.ReopenTypeID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.2/10 | Sources: DDL, Trade.MirrorsReopen, Trade.MirrorReopen, Trade.ReopenOperationCancel*
