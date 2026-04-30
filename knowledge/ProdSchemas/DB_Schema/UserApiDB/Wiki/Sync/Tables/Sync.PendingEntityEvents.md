# Sync.PendingEntityEvents

> Queue table for cross-system user data synchronization. Rows are inserted by triggers on Customer tables and consumed by the sync service using a distributed lock pattern.

| Property | Value |
|----------|-------|
| **Schema** | Sync |
| **Object Type** | Table |
| **Key Identifier** | ID (BIGINT, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Sync.PendingEntityEvents is the central outbox queue for propagating user data changes from UserApiDB to downstream consumers (message bus, analytics, regulatory systems). When customer profile data changes — basic info, contact details, account settings, risk classification, or user preferences — the corresponding table's UPDATE trigger inserts a row here identifying the GCID and data category (EntityType) that changed.

The sync service polls this queue using a distributed lock pattern: it selects pending events, marks them with a LockTime, publishes them, then marks them Done. This guarantees at-least-once delivery with lock expiry as the retry mechanism.

EntityType values correspond to Dictionary.SyncEntityTypes: 1=BasicInfo, 2=Contact, 3=Account, 4=Risk, 5=Settings.

---

## 2. Business Logic

### 2.1 Distributed Lock Pattern

**What**: Prevents multiple sync service instances from processing the same event simultaneously.

**Columns/Parameters Involved**: `StatusID`, `LockTime`

**Rules**:
- New events arrive with StatusID=1 (Pending) and LockTime=NULL
- Consumer calls Sync.GetAndLockPendingPublishEvents which sets LockTime = GETUTCDATE()
- If consumer crashes, lock expires and the event becomes eligible for re-processing
- Sync.MarkAsDonePendingPublishEvents sets StatusID=2 (Done) on successful publish
- Only StatusID=1 events with no lock (or expired lock) are eligible for pickup

### 2.2 Trigger Population

**What**: Automatic queue insertion on Customer table changes.

**Columns/Parameters Involved**: `GCID`, `EntityType`, `StatusID`, `CreatedAt`

**Rules**:
- Triggers on Customer.BasicUserInfo INSERT/UPDATE → EntityType=1
- Triggers on Customer.ContactUserInfo INSERT/UPDATE → EntityType=2
- Triggers on Customer.AccountUserInfo INSERT/UPDATE → EntityType=3
- Triggers on Customer.RiskUserInfo INSERT/UPDATE → EntityType=4
- Triggers on Customer.SettingsUserInfo INSERT/UPDATE → EntityType=5
- StatusID defaults to 1 (Pending), CreatedAt defaults to GETDATE()

---

## 3. Data Overview

N/A - transactional queue table, high throughput.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint IDENTITY | NO | - | CODE-BACKED | Primary key. Auto-incrementing surrogate key for the queue event. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Identifies the user whose data changed and needs synchronizing. |
| 3 | EntityType | smallint | NO | - | CODE-BACKED | FK to Dictionary.SyncEntityTypes. Data category: 1=BasicInfo, 2=Contact, 3=Account, 4=Risk, 5=Settings. |
| 4 | LockTime | datetime | YES | - | CODE-BACKED | UTC timestamp set when the sync service claims this event. NULL = unclaimed. Used for lock expiry detection. |
| 5 | StatusID | smallint | NO | 1 | CODE-BACKED | FK to Dictionary.SyncStatus. Current state: 1=Pending, 2=Done. Defaults to 1 on insert. |
| 6 | CreatedAt | datetime | NO | getdate() | CODE-BACKED | Timestamp when the event was enqueued by the trigger. Defaults to current datetime. |
| 7 | CorrelationID | uniqueidentifier | YES | - | CODE-BACKED | Optional trace identifier linking this event to a distributed transaction or request chain. |
| 8 | ClientRequestID | uniqueidentifier | YES | - | CODE-BACKED | Optional client-provided idempotency key for the originating request. |
| 9 | RequestTime | datetime | YES | - | CODE-BACKED | Optional timestamp of the originating client request, as provided by the caller. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EntityType | Dictionary.SyncEntityTypes | Explicit FK | Data category being synced |
| StatusID | Dictionary.SyncStatus | Explicit FK | Current processing state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer table triggers | GCID, EntityType | Trigger-written | Enqueues events on data changes |
| Sync.GetAndLockPendingPublishEvents | ID, LockTime | SP reads/writes | Locks and returns pending events |
| Sync.MarkAsDonePendingPublishEvents | ID, StatusID | SP writes | Marks events as processed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Sync.PendingEntityEvents (table)
  +-- Dictionary.SyncEntityTypes (table)
  +-- Dictionary.SyncStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.SyncEntityTypes | Table | FK: EntityType |
| Dictionary.SyncStatus | Table | FK: StatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Sync.GetAndLockPendingPublishEvents | Stored Procedure | SELECT and UPDATE for event pickup |
| Sync.MarkAsDonePendingPublishEvents | Stored Procedure | UPDATE StatusID to Done |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PendingEntityEvents | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_PEE_StatusID | DEFAULT | (1) for StatusID — new events start as Pending |
| DF_PEE_CreatedAt | DEFAULT | getdate() for CreatedAt |
| FK_PEE_EntityType | FOREIGN KEY | EntityType -> Dictionary.SyncEntityTypes |
| FK_PEE_StatusID | FOREIGN KEY | StatusID -> Dictionary.SyncStatus |

---

## 8. Sample Queries

### 8.1 View pending events by entity type
```sql
SELECT et.Name AS EntityType, COUNT(*) AS PendingCount
FROM Sync.PendingEntityEvents pe WITH (NOLOCK)
JOIN Dictionary.SyncEntityTypes et WITH (NOLOCK) ON pe.EntityType = et.EntityTypeId
WHERE pe.StatusID = 1
GROUP BY et.Name ORDER BY PendingCount DESC
```

### 8.2 Find stale locked events (potential stuck consumers)
```sql
SELECT ID, GCID, EntityType, LockTime, CreatedAt
FROM Sync.PendingEntityEvents WITH (NOLOCK)
WHERE StatusID = 1 AND LockTime IS NOT NULL AND LockTime < DATEADD(MINUTE, -5, GETUTCDATE())
```

### 8.3 Queue depth over time
```sql
SELECT CONVERT(date, CreatedAt) AS EventDate, COUNT(*) AS TotalEvents,
       SUM(CASE WHEN StatusID = 1 THEN 1 ELSE 0 END) AS Pending,
       SUM(CASE WHEN StatusID = 2 THEN 1 ELSE 0 END) AS Done
FROM Sync.PendingEntityEvents WITH (NOLOCK)
WHERE CreatedAt >= DATEADD(DAY, -7, GETDATE())
GROUP BY CONVERT(date, CreatedAt) ORDER BY EventDate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Sync.PendingEntityEvents | Type: Table | Source: UserApiDB/UserApiDB/Sync/Tables/Sync.PendingEntityEvents.sql*
