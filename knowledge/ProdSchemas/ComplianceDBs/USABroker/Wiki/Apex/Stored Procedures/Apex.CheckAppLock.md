# Apex.CheckAppLock

> Checks the current lock mode of a SQL Server application lock resource, returning whether it is held and in what mode.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns APPLOCK_MODE string |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.CheckAppLock is a diagnostic utility procedure that checks whether a SQL Server application lock (sp_getapplock) is currently held on a named resource. It returns the lock mode string (e.g., 'Exclusive', 'NoLock') for the specified resource in the 'public' database principal context.

This procedure supports the locking infrastructure used by GetAppLock/UnLockResource. It allows the application to query whether a resource is currently locked before attempting to acquire it, enabling non-blocking lock checks for monitoring and diagnostics.

---

## 2. Business Logic

No complex business logic. Single APPLOCK_MODE() call returning the current lock state.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Resource | nvarchar(150) | NO | - | CODE-BACKED | The named resource to check lock status for. Same resource name used with GetAppLock/UnLockResource. |

**Returns**: Single-column result set with APPLOCK_MODE value: 'NoLock', 'Shared', 'Update', 'IntentShared', 'IntentExclusive', 'Exclusive'.

---

## 5. Relationships

### 5.1 References To (this object points to)

This procedure does not reference any tables.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies. Uses built-in APPLOCK_MODE function only.

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

### 8.1 Check if a resource is locked

```sql
EXEC Apex.CheckAppLock @Resource = N'ApexStateProcessor';
```

### 8.2 Check lock in application code pattern

```sql
DECLARE @mode NVARCHAR(50);
EXEC Apex.CheckAppLock @Resource = N'ApexStateProcessor';
-- Returns 'NoLock' if available, 'Exclusive' if held
```

### 8.3 Monitor all known lock resources

```sql
-- Check multiple resources
EXEC Apex.CheckAppLock @Resource = N'ApexStateProcessor';
EXEC Apex.CheckAppLock @Resource = N'ApexSyncWorker';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.CheckAppLock | Type: Stored Procedure | Source: USABroker/Apex/Stored Procedures/Apex.CheckAppLock.sql*
