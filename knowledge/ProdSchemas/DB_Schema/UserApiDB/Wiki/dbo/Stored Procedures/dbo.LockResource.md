# dbo.LockResource

> Acquires an application-level lock by inserting into dbo.Lock, with automatic cleanup of stale locks (30+ seconds old). Returns 1 if acquired, 0 if already locked.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @lockKey (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.LockResource provides distributed locking. First cleans up stale locks (>= 30 seconds old), then attempts to acquire the named lock via conditional INSERT (only if not already locked). Returns @@ROWCOUNT (1=acquired, 0=already held).

---

## 2. Business Logic

### 2.1 Lock Acquisition with Cleanup

**Rules**:
- DELETE locks older than 30 seconds (auto-cleanup)
- INSERT only if LockKey doesn't already exist (WHERE NOT EXISTS)
- Returns @@ROWCOUNT: 1 = lock acquired, 0 = already locked

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @lockKey | nvarchar(150) (IN) | NO | - | CODE-BACKED | Named resource to lock. |

Output: @@ROWCOUNT (1=acquired, 0=already locked).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.Lock | DELETE + INSERT | Lock management |

### 5.2 Referenced By (other objects point to this)

Application services for distributed locking.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.LockResource (procedure)
  +-- dbo.Lock (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Lock | Table | DELETE (cleanup) + INSERT (acquire) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Acquire lock
```sql
EXEC dbo.LockResource @lockKey = N'MyResource'
```

### 8.2 Check if acquired
```sql
DECLARE @result TABLE (Cnt INT)
INSERT INTO @result EXEC dbo.LockResource @lockKey = N'MyResource'
SELECT CASE WHEN (SELECT Cnt FROM @result) = 1 THEN 'Acquired' ELSE 'Already Locked' END
```

### 8.3 Release after use
```sql
EXEC dbo.LockResource @lockKey = N'MyResource'
-- ... do work ...
EXEC dbo.ReleaseLock @lockKey = N'MyResource'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: dbo.LockResource | Type: Stored Procedure | Source: UserApiDB/UserApiDB/dbo/Stored Procedures/dbo.LockResource.sql*
