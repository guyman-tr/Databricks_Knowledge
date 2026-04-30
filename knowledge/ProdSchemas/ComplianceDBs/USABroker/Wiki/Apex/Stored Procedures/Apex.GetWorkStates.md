# Apex.GetWorkStates

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetWorkStates.sql`  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetWorkStates` is the **heart of the Apex workflow engine's work-queue dispatcher**. It atomically claims a batch of customers that are ready for processing from `Apex.StateProcessingData`, marks them as in-work, increments their error count (pre-emptively, to be decremented on success), and returns the full state record for each claimed customer so the calling service can process them.

The procedure implements a robust, concurrency-safe work queue with:
- **Exclusive table locking** (`TABLOCKX`, `XLOCK`) to prevent multiple workers from claiming the same customers.
- **Exponential backoff** using `POWER(2, ErrorCount)` multiplied by `WorkTimeoutSec` to delay retries of failing customers without blocking healthy ones.
- **Work-timeout detection** — customers with `InWork = 1` but whose last update is older than the computed timeout window are reclaimed, enabling recovery from crashed workers.
- **Error-count ceiling** — customers that have exceeded `MaxErrorCount` are excluded, preventing infinite retry loops.

---

## 2. Parameters

| Parameter | Type | Nullable | Default | Description |
|-----------|------|----------|---------|-------------|
| `@ItemsCount` | `int` | Yes | `1,000,000` | Maximum number of customers to claim in a single call. |
| `@WorkTimeoutSec` | `int` | Yes | `600` | Base timeout in seconds; multiplied by `2^ErrorCount` for exponential backoff. |
| `@MaxErrorCount` | `int` | Yes | `5` | Maximum error count; customers at or above this threshold are excluded. |

---

## 3. Result Sets

**Result Set 1 – Claimed Customer States**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `GCID` | `Apex.State` / `Apex.StateProcessingData` | Global Customer ID of the claimed customer. |
| `ApexStateID` | `Apex.State` | Current state-machine node. |
| `StateNextUpdatedDate` | `Apex.StateProcessingData` | Originally scheduled processing time (before this claim). |
| `LastUpdateDate` | `Apex.StateProcessingData` | Set to the current UTC time by this claim operation. |
| `InWork` | `Apex.StateProcessingData` | Always 1 after this operation. |
| `RetryCount` | `Apex.StateProcessingData` | Number of successful retries. |
| `ErrorCount` | `Apex.StateProcessingData` | Incremented by 1 by this call (temporarily elevated). |
| `BeginTime` | `Apex.State` | When the current state began. |
| `EndTime` | `Apex.State` | When the state ended (NULL if active). |
| `Comment` | `Apex.State` | State comment text. |

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `StateProcessingData` | `Apex` | SELECT + UPDATE | `TABLOCKX` + `XLOCK` for exclusive access; CTE used for batch claim. |
| `State` | `Apex` | SELECT | JOINed to return state fields for claimed customers. |

---

## 5. Logic Flow

1. **Begin transaction** (`GetWorkStates_Tran`) with `XACT_ABORT ON`.
2. **Create temp table** `#ApexStateTMP` to hold claimed GCIDs and their updated processing fields.
3. **CTE eligibility filter** — selects `top(@ItemsCount)` GCIDs from `StateProcessingData` using `TABLOCKX`/`XLOCK` where:
   - `StateNextUpdatedDate < NOW` or `IS NULL` (scheduled work is due), **AND**
   - Either `InWork = 0` (not currently claimed), **OR** `InWork = 1` but the exponential-backoff timeout has expired: `LastUpdateDate + (WorkTimeoutSec * 2^ErrorCount) < NOW`, **AND**
   - `ErrorCount <= MaxErrorCount` (not permanently failed).
   - Ordered by `StateNextUpdatedDate ASC` to process oldest-due work first.
4. **UPDATE** `StateProcessingData` for the selected GCIDs: set `InWork = 1`, update `LastUpdateDate`, increment `ErrorCount`. OUTPUT the updated rows into `#ApexStateTMP`.
5. **SELECT** final result set by JOINing `Apex.State` + `Apex.StateProcessingData` on GCIDs in `#ApexStateTMP`.
6. Drop temp table. **COMMIT** transaction.
7. **CATCH block** rolls back on any error and re-THROWs.

---

## 6. Error Handling

- `SET XACT_ABORT ON` ensures any statement-level error automatically rolls back the transaction.
- `BEGIN TRY / BEGIN CATCH` with explicit `ROLLBACK` and `THROW` — the caller receives the original exception.
- If the worker crashes mid-processing, the `InWork = 1` + elevated `ErrorCount` row will be reclaimed on the next `GetWorkStates` call after the backoff window elapses.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.StateProcessingData` | Table | Work queue table; exclusively locked and updated |
| `Apex.State` | Table | State data JOINed for the result set |
| `Apex.GetState` | Stored Procedure | Single-customer state read (no locking) |
| `Apex.SaveState` | Stored Procedure | Writes back the decremented `ErrorCount` and `InWork = 0` after successful processing |

---

## 8. Usage Notes

- **ErrorCount pre-increment:** The error count is incremented at claim time. On successful processing, the worker must call `Apex.SaveState` with `ErrorCount - 1` and `InWork = 0` to restore the count. If the worker crashes without saving, the elevated count causes the next retry to be delayed by the backoff formula.
- **TABLOCKX:** This is an exclusive table lock, meaning only one worker can execute this procedure at a time. This is intentional to guarantee no double-claiming. Scale-out is achieved by batching more items per call rather than by parallelising the claim step.
- **ErrorCount cap:** The `POWER(2, ErrorCount)` expression is capped at `POWER(2, 16)` (65536) to prevent integer overflow for customers with high error counts.
- Customers at exactly `MaxErrorCount` are still included (filter is `<= MaxErrorCount`); they will be excluded only after exceeding it.
- The default `@ItemsCount = 1,000,000` effectively means "all eligible customers"; tune this for your worker's processing capacity.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetWorkStates.sql` | Quality Score: 9.0/10*
