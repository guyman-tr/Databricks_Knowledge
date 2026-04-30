# Apex.UnLockResource

> Legacy/deprecated unlock procedure that previously released Apex.Lock rows. Currently a no-op that always returns 1.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns @ret (always 1) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.UnLockResource is a deprecated procedure. The original implementation (DELETE FROM Apex.Lock WHERE Key=@Key) is commented out. The procedure now always returns 1 without performing any action. Lock release is handled by Apex.JobLockRelease instead.

This procedure likely remains in the codebase for backward compatibility with callers that haven't been updated to use JobLockRelease.

---

## 2. Business Logic

No active business logic. The original DELETE logic is commented out. Returns 1 unconditionally.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Key | nvarchar(150) | NO | - | CODE-BACKED | The lock key that would have been released. Currently unused - the parameter is accepted but ignored. |

**Returns**: Always returns 1 via RETURN @ret.

---

## 5. Relationships

### 5.1 References To (this object points to)

This procedure does not reference any tables (original DELETE is commented out).

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no active dependencies (original Apex.Lock reference is commented out).

### 6.1 Objects This Depends On

No active dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Call (no-op)

```sql
DECLARE @ret INT;
EXEC @ret = Apex.UnLockResource @Key = N'SomeResource';
SELECT @ret; -- Always returns 1
```

### 8.2 Use JobLockRelease instead

```sql
-- The correct way to release locks:
EXEC Apex.JobLockRelease @Key = 'MyJob', @LockID = 'guid-here', @CurrentTimeUtc = '2026-04-14';
```

### 8.3 Check if any callers still use this

```sql
-- Search application code for references to UnLockResource
-- Consider deprecating if no callers found
SELECT 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.UnLockResource | Type: Stored Procedure | Source: USABroker/Apex/Stored Procedures/Apex.UnLockResource.sql*
