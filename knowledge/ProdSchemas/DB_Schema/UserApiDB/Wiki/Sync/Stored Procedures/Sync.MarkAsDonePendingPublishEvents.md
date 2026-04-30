# Sync.MarkAsDonePendingPublishEvents

> Updates StatusID to 2 (Done) for a set of event IDs provided via a dbo.IdListBigInt table-valued parameter, completing the sync event lifecycle.

| Property | Value |
|----------|-------|
| **Schema** | Sync |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IDs (TVP param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Sync.MarkAsDonePendingPublishEvents is the completion step of the sync pipeline. After a consumer successfully publishes events to the message bus, it calls this SP with the list of processed event IDs to mark them as Done (StatusID=2). This prevents re-processing and is the normal terminal state for events in Sync.PendingEntityEvents.

The SP accepts a batch of IDs via the dbo.IdListBigInt TVP, making bulk completion efficient. Only StatusID=1 (Pending) events that were previously locked by the caller should be passed — passing already-Done IDs is idempotent.

---

## 2. Business Logic

### 2.1 Batch Status Completion

**What**: Bulk state transition from Pending to Done.

**Columns/Parameters Involved**: `@IDs`, `StatusID`

**Rules**:
- Joins Sync.PendingEntityEvents to @IDs TVP on ID
- Sets StatusID = 2 (Done) for all matching rows
- Operation is idempotent — updating already-Done rows to Done has no effect
- No validation that the caller holds the lock — relies on upstream coordination

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IDs | dbo.IdListBigInt (TVP) | NO (param) | - | CODE-BACKED | Table-valued parameter containing the list of event IDs to mark as Done. Single column: ID BIGINT. |

Output: none (row count only).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @IDs | dbo.IdListBigInt | TVP type | Input list of event IDs to complete |
| ID | Sync.PendingEntityEvents | UPDATE | Sets StatusID=2 for matched events |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by external sync service consumers after successful publish.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Sync.MarkAsDonePendingPublishEvents (procedure)
  +-- Sync.PendingEntityEvents (table)
  +-- dbo.IdListBigInt (user-defined table type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Sync.PendingEntityEvents | Table | UPDATE StatusID to 2 |
| dbo.IdListBigInt | User-Defined Table Type | TVP carrying list of IDs to complete |

### 6.2 Objects That Depend On This

No dependents found in SQL layer — called by application/service layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Mark a single event done
```sql
DECLARE @IDs dbo.IdListBigInt
INSERT INTO @IDs VALUES (12345)
EXEC Sync.MarkAsDonePendingPublishEvents @IDs = @IDs
```

### 8.2 Mark a batch of events done
```sql
DECLARE @IDs dbo.IdListBigInt
INSERT INTO @IDs (ID) VALUES (101), (102), (103), (104), (105)
EXEC Sync.MarkAsDonePendingPublishEvents @IDs = @IDs
```

### 8.3 Verify completion
```sql
SELECT ID, StatusID, LockTime FROM Sync.PendingEntityEvents WITH (NOLOCK)
WHERE ID IN (101, 102, 103, 104, 105)
-- StatusID should be 2 for all rows
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Object: Sync.MarkAsDonePendingPublishEvents | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Sync/Stored Procedures/Sync.MarkAsDonePendingPublishEvents.sql*
