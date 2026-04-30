# dbo.Lock

> Application-level distributed lock table enabling named resource locking for concurrent operations.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | LockID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

dbo.Lock provides application-level distributed locking. Services acquire a named lock by inserting a row with a unique LockKey, and release it by deleting that row. Used by dbo.LockResource and dbo.ReleaseLock procedures. The AcquiredOn timestamp enables stale lock detection and cleanup.

---

## 2. Business Logic

No complex business logic. Insert = acquire lock, Delete = release lock.

---

## 3. Data Overview

N/A - transient lock records.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LockID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Auto-incrementing lock record ID. |
| 2 | LockKey | nvarchar(150) | NO | - | CODE-BACKED | Named lock identifier. Uniqueness should be enforced by the LockResource procedure's logic. |
| 3 | AcquiredOn | datetime | NO | - | CODE-BACKED | When the lock was acquired. Used for stale lock detection. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.LockResource | LockKey | SP writes | Acquires locks |
| dbo.ReleaseLock | LockKey | SP deletes | Releases locks |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.LockResource | Stored Procedure | INSERT (acquire) |
| dbo.ReleaseLock | Stored Procedure | DELETE (release) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Lock | CLUSTERED PK | LockID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View active locks
```sql
SELECT LockID, LockKey, AcquiredOn FROM dbo.Lock WITH (NOLOCK) ORDER BY AcquiredOn DESC
```

### 8.2 Find stale locks (older than 1 hour)
```sql
SELECT * FROM dbo.Lock WITH (NOLOCK) WHERE AcquiredOn < DATEADD(HOUR, -1, GETUTCDATE())
```

### 8.3 Check if resource is locked
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.Lock WITH (NOLOCK) WHERE LockKey = @ResourceName) THEN 1 ELSE 0 END AS IsLocked
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: dbo.Lock | Type: Table | Source: UserApiDB/UserApiDB/dbo/Tables/dbo.Lock.sql*
