# Sync.GetAndLockPendingPublishEvents

> Selects and locks a batch of pending sync events using an OUTPUT clause, implementing a distributed lock pattern to prevent duplicate processing by concurrent consumers.

| Property | Value |
|----------|-------|
| **Schema** | Sync |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @EventsCount (batch size param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Sync.GetAndLockPendingPublishEvents is the consumer-side dequeue operation for the sync pipeline. It atomically selects up to @EventsCount pending events, stamps them with the current UTC time as LockTime, and returns them to the caller in a single UPDATE...OUTPUT statement. This prevents two concurrent sync service instances from picking up the same event.

The lock expiry mechanism — where events with an old LockTime become re-eligible — provides automatic retry on consumer failure without requiring a separate cleanup job. Consumers call this SP to get their work batch, publish to the message bus, then call Sync.MarkAsDonePendingPublishEvents to complete the cycle.

---

## 2. Business Logic

### 2.1 Atomic Select-and-Lock

**What**: Single UPDATE with OUTPUT to prevent race conditions between consumers.

**Columns/Parameters Involved**: `StatusID`, `LockTime`, `@EventsCount`

**Rules**:
- Targets TOP (@EventsCount) rows WHERE StatusID = 1 (Pending) AND (LockTime IS NULL OR LockTime < lock-expiry threshold)
- Sets LockTime = GETUTCDATE() on selected rows in the same statement
- Returns affected rows via OUTPUT INSERTED.* so caller receives the claimed events
- Lock expiry window (e.g., 5 minutes) allows automatic retry if consumer crashes mid-flight
- No explicit transaction needed — single UPDATE is atomic by definition

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @EventsCount | int | NO (param) | - | CODE-BACKED | Maximum number of events to claim in this batch. Controls consumer throughput per call. |

Output (via OUTPUT INSERTED): ID, GCID, EntityType, LockTime, StatusID, CreatedAt, CorrelationID, ClientRequestID, RequestTime — all columns of Sync.PendingEntityEvents for the claimed rows.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Sync.PendingEntityEvents | UPDATE + OUTPUT | Claims pending events and returns them |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by external sync service consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Sync.GetAndLockPendingPublishEvents (procedure)
  +-- Sync.PendingEntityEvents (table)
        +-- Dictionary.SyncEntityTypes (table)
        +-- Dictionary.SyncStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Sync.PendingEntityEvents | Table | UPDATE to set LockTime; OUTPUT to return claimed rows |

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

### 8.1 Claim a batch of 10 events
```sql
EXEC Sync.GetAndLockPendingPublishEvents @EventsCount = 10
```

### 8.2 Capture output for processing
```sql
DECLARE @ClaimedEvents TABLE (
    ID BIGINT, GCID INT, EntityType SMALLINT, LockTime DATETIME,
    StatusID SMALLINT, CreatedAt DATETIME, CorrelationID UNIQUEIDENTIFIER,
    ClientRequestID UNIQUEIDENTIFIER, RequestTime DATETIME
)
INSERT INTO @ClaimedEvents
EXEC Sync.GetAndLockPendingPublishEvents @EventsCount = 50
SELECT * FROM @ClaimedEvents
```

### 8.3 Monitor lock activity
```sql
-- View currently locked events
SELECT ID, GCID, EntityType, LockTime, DATEDIFF(SECOND, LockTime, GETUTCDATE()) AS LockedForSeconds
FROM Sync.PendingEntityEvents WITH (NOLOCK)
WHERE StatusID = 1 AND LockTime IS NOT NULL
ORDER BY LockTime
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Object: Sync.GetAndLockPendingPublishEvents | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Sync/Stored Procedures/Sync.GetAndLockPendingPublishEvents.sql*
