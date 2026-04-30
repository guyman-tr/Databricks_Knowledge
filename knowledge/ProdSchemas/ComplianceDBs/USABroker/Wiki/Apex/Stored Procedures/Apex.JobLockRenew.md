# Apex.JobLockRenew

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.JobLockRenew.sql`  
**Author:** Serhii Poltava  
**Created:** 2019-10-28  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.JobLockRenew` extends the expiration time of an already-held distributed job lock. Long-running jobs acquire a lock with an initial expiration time but must periodically renew it to signal to other instances that the job is still actively running and has not crashed. If a job fails to renew before its lock expires, other nodes may claim the lock and start the job again — a desired fail-over behaviour.

This procedure is called on a heartbeat interval (e.g., every 30–60 seconds) by a background job that holds a lock, pushing the expiration window forward to prevent accidental premature expiry.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@Key` | `varchar(50)` | No | The name of the lock to renew. |
| `@LockID` | `uniqueidentifier` | No | The GUID held by the current owner — proves the caller is the legitimate lock holder. |
| `@ExpiresAt` | `datetime` | No | The new expiration datetime (extended from the current time). |
| `@CurrentTimeUtc` | `datetime` | No | The caller's current UTC time; used to verify the lock has not already expired. |

---

## 3. Result Sets

**Result Set 1 – Renewal Result**

| Column | Value | Meaning |
|--------|-------|---------|
| `RowCount` | `1` | Lock found, still valid, and successfully renewed. |
| `RowCount` | `0` | Renewal failed — either the lock does not exist, the `LockID` does not match, or the lock had already expired (`ExpiresAt <= @CurrentTimeUtc`). |

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `Lock` | `Apex` | UPDATE | Row updated only when `Key = @Key AND LockID = @LockID AND ExpiresAt > @CurrentTimeUtc`. |

---

## 5. Logic Flow

1. Executes an `UPDATE` on `Apex.Lock`:
   - Sets `ExpiresAt = @ExpiresAt` (the new, extended expiration).
   - `WHERE Key = @Key AND LockID = @LockID AND ExpiresAt > @CurrentTimeUtc`.
2. Returns `@@ROWCOUNT AS [RowCount]`.

The three-part WHERE clause enforces:
- **Key match** — correct named lock.
- **LockID match** — caller is the owner.
- **Not yet expired** — prevents renewing a lock that has already lapsed (another process may have claimed it).

---

## 6. Error Handling

No explicit TRY/CATCH. A `RowCount = 0` result is the failure signal; the caller should treat this as a lost-lock condition and cease the job's exclusive operations.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.Lock` | Table | Lock registry — UPDATE target |
| `Apex.JobLockAcquire` | Stored Procedure | Creates the lock renewed here |
| `Apex.JobLockRelease` | Stored Procedure | Terminates the lock lifecycle |

---

## 8. Usage Notes

- Call `JobLockRenew` on a background timer thread at an interval well below the lock's expiration window — for example, if `ExpiresAt` is set to 5 minutes, renew every 2 minutes.
- If `RowCount = 0` is returned, the lock was lost. The job should stop processing immediately to avoid concurrent execution with another node that may have taken over.
- The `ExpiresAt` passed to each renew call should be set to `NOW + desired_lease_duration`, not computed relative to the previous `ExpiresAt`.
- `@CurrentTimeUtc` must be synchronised to avoid clock-skew false negatives — a caller with a slow clock may incorrectly fail to renew a lock that appears expired by its own clock.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.JobLockRenew.sql` | Quality Score: 9.0/10*
