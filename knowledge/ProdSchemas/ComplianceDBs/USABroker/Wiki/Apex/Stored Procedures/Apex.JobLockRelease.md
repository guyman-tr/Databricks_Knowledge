# Apex.JobLockRelease

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.JobLockRelease.sql`  
**Author:** Serhii Poltava  
**Created:** 2019-10-28  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.JobLockRelease` releases a named distributed job lock that was previously acquired via `Apex.JobLockAcquire`. It deletes the lock row only when both the key and the caller's `LockID` GUID match, ensuring that only the legitimate lock owner can release it. After deletion the procedure evaluates and reports whether the release was clean (lock was still valid) or indicates a problem condition (lock was already expired or stolen).

The three return codes enable the calling service to detect and log anomalous situations — such as a lock that expired during processing (potentially allowing another worker to run concurrently) — without raising an exception.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@Key` | `varchar(50)` | No | The name of the lock to release. |
| `@LockID` | `uniqueidentifier` | No | The GUID that was used when acquiring the lock — proves ownership. |
| `@CurrentTimeUtc` | `datetime` | No | The caller's current UTC time; used to determine whether the released lock had already expired. |

---

## 3. Result Sets

**Result Set 1 – Release Status Code**

| Column | Value | Meaning |
|--------|-------|---------|
| `RetCode` | `0` | Lock deleted successfully and was still valid (clean release). |
| `RetCode` | `-1` | Lock row was not found — either it never existed, it expired and was claimed by another process, or it was already released. The caller's lock was effectively stolen. |
| `RetCode` | `-2` | Lock row was found and deleted, but `ExpiresAt` was in the past — the lock had already expired during processing. The job may have run concurrently with another worker for the overlap period. |

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `Lock` | `Apex` | DELETE | Row deleted only when `Key = @Key AND LockID = @LockID`. |

---

## 5. Logic Flow

1. Declare a table variable `@t` to capture the deleted row's `ExpiresAt` via `OUTPUT`.
2. `DELETE FROM Apex.Lock ... OUTPUT deleted.ExpiresAt INTO @t` where `Key = @Key AND LockID = @LockID`.
3. Read the captured `ExpiresAt` into `@ExpiresAt`.
4. **Decision tree:**
   - If `@ExpiresAt IS NULL` → no row was deleted → return `-1` (lock missing/stolen).
   - Else if `@ExpiresAt <= @CurrentTimeUtc` → row was deleted but already expired → return `-2` (expired lock released).
   - Else → row was deleted and was still valid → return `0` (clean release).

---

## 6. Error Handling

No explicit TRY/CATCH. The OUTPUT clause and table variable approach is atomic — the delete and capture happen in a single statement. If no row matches, `@ExpiresAt` remains NULL and the procedure returns `-1`.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.Lock` | Table | Lock registry — DELETE target |
| `Apex.JobLockAcquire` | Stored Procedure | Creates the lock released here |
| `Apex.JobLockRenew` | Stored Procedure | Extends the lock between acquire and release |

---

## 8. Usage Notes

- Always call `JobLockRelease` in a `finally` block (or equivalent) to ensure locks are released even when the job fails.
- A return code of `-1` is a serious signal — it means another process may have taken over the lock and may be running concurrently. Log and alert on this condition.
- A return code of `-2` means the lock expired during processing. The job still completed, but there was a window during which the lock was unowned. Consider shortening job duration or increasing lock timeout and renewal frequency.
- The `LockID` requirement prevents accidental release of another node's lock in a multi-instance environment.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.JobLockRelease.sql` | Quality Score: 9.0/10*
