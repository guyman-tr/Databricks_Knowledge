# dbo.ReleaseLock

> Releases an application-level lock by deleting its record from dbo.Lock.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @lockKey (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.ReleaseLock releases a distributed lock acquired by dbo.LockResource. Simply deletes the row from dbo.Lock matching the lock key. Companion to LockResource.

---

## 2. Business Logic

No complex business logic. Single DELETE by LockKey.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @lockKey | nvarchar(150) (IN) | NO | - | CODE-BACKED | Named resource to unlock. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.Lock | DELETE FROM | Releases the lock |

### 5.2 Referenced By (other objects point to this)

Application services after completing locked work.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.ReleaseLock (procedure)
  +-- dbo.Lock (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Lock | Table | DELETE FROM |

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

### 8.1 Release a lock
```sql
EXEC dbo.ReleaseLock @lockKey = N'MyResource'
```

### 8.2 Acquire and release pattern
```sql
EXEC dbo.LockResource @lockKey = N'MyResource'
-- ... do work ...
EXEC dbo.ReleaseLock @lockKey = N'MyResource'
```

### 8.3 Verify release
```sql
EXEC dbo.ReleaseLock @lockKey = N'MyResource'
SELECT COUNT(*) FROM dbo.Lock WITH (NOLOCK) WHERE LockKey = N'MyResource' -- Should be 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: dbo.ReleaseLock | Type: Stored Procedure | Source: UserApiDB/UserApiDB/dbo/Stored Procedures/dbo.ReleaseLock.sql*
