# Apex.GetState

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetState.sql`  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetState` retrieves the complete workflow state record for a customer by joining the logical state (`Apex.State`) with its processing-queue metadata (`Apex.StateProcessingData`). Together these two tables represent where the customer sits in the Apex onboarding or update state machine, and the scheduling/retry metadata that controls when the workflow engine next picks up that customer for processing.

This is the standard state-inspection call made by the workflow service before deciding what action to take for a customer, by monitoring dashboards to show state distribution, and by operations tooling to check whether a specific user is stuck or scheduled for near-future processing.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID of the customer whose state is requested. |

---

## 3. Result Sets

**Result Set 1 – Combined State + Processing Data**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `GCID` | `Apex.State` | Global Customer ID. |
| `ApexStateID` | `Apex.State` | Numeric ID of the current state-machine node. |
| `StateNextUpdatedDate` | `Apex.StateProcessingData` | Scheduled UTC datetime for the next processing attempt. NULL means "process ASAP." |
| `LastUpdateDate` | `Apex.StateProcessingData` | UTC datetime of the last state processing action. |
| `InWork` | `Apex.StateProcessingData` | 1 if the workflow engine currently holds a lock on this customer; 0 otherwise. |
| `RetryCount` | `Apex.StateProcessingData` | Number of successful retries accumulated. |
| `ErrorCount` | `Apex.StateProcessingData` | Number of errors accumulated (used by the exponential-backoff scheduler in `GetWorkStates`). |
| `BeginTime` | `Apex.State` | UTC timestamp when the current state was entered. |
| `EndTime` | `Apex.State` | UTC timestamp when the state was exited (NULL if still active). |
| `Comment` | `Apex.State` | Free-text comment associated with the current state. |

Returns 0 rows if the customer has no state record (not yet enrolled in the workflow).

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `State` | `Apex` | SELECT | Logical state; INNER JOIN with `StateProcessingData`. |
| `StateProcessingData` | `Apex` | SELECT | Processing queue metadata; INNER JOIN on `GCID`. |

---

## 5. Logic Flow

1. INNER JOINs `Apex.State` and `Apex.StateProcessingData` on `GCID`.
2. Filters by `s.GCID = @GCID`.
3. Returns all columns from both tables needed by workflow and monitoring services.

An INNER JOIN is used, meaning the customer must have rows in both tables. If a `State` row exists without a `StateProcessingData` row (or vice versa), no result is returned — both rows are written atomically by `Apex.SaveState`.

---

## 6. Error Handling

No explicit error handling. Empty result set if no state exists.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.State` | Table | Logical state source |
| `Apex.StateProcessingData` | Table | Processing queue metadata source |
| `Apex.SaveState` | Stored Procedure | Companion writer; atomically upserts both tables |
| `Apex.GetWorkStates` | Stored Procedure | Bulk variant that locks and claims multiple states for batch processing |

---

## 8. Usage Notes

- If `InWork = 1` for a prolonged period, the customer's processing may be stalled. `GetWorkStates` uses `ErrorCount` and `WorkTimeoutSec` to detect and recover from such situations using exponential backoff.
- `StateNextUpdatedDate = NULL` means the record is eligible for immediate processing by the next `GetWorkStates` call.
- Combine with `Apex.GetApexDataAndState` when approval metadata and validation errors are also needed; `GetApexDataAndState` includes a broader context in two result sets.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetState.sql` | Quality Score: 8.5/10*
