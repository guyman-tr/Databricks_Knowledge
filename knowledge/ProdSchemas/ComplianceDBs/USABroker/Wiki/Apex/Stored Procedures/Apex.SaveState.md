# Apex.SaveState

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveState.sql`  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveState` is the **central write path for the Apex workflow state machine**. It atomically advances a customer's processing state across three tightly coupled tables in a single transaction: the logical workflow state (`Apex.State`), the processing queue metadata (`Apex.StateProcessingData`), and the set of active validation errors (`Apex.UserValidationErrors`).

Calling this procedure after processing a customer's work item is how the workflow engine records:
- What state the customer is now in (e.g., PendingApexApproval, Approved, Rejected).
- When they should next be processed (`StateNextUpdatedDate`).
- Whether they are still in active processing (`InWork = 0` on success).
- How many errors have accumulated vs how many retries succeeded.
- What validation errors (if any) are currently blocking them.

The transactional design ensures that if the State or StateProcessingData MERGE fails, none of the three writes are committed — preventing partial state corruption.

---

## 2. Parameters

| Parameter | Type | Nullable | Default | Description |
|-----------|------|----------|---------|-------------|
| `@GCID` | `int` | No | — | Global Customer ID. |
| `@ApexStateID` | `int` | No | — | The new state-machine node ID. |
| `@StateNextUpdatedDate` | `datetime2(7)` | No | — | UTC datetime for the next scheduled processing attempt. |
| `@LastUpdateDate` | `datetime2(7)` | No | — | UTC timestamp of this processing action. |
| `@InWork` | `int` | No | — | 0 = processing complete; 1 = still in work (use for checkpointing). |
| `@RetryCount` | `int` | No | — | Accumulated successful-retry count. |
| `@ErrorCount` | `int` | Yes | `0` | Accumulated error count (decremented from the pre-incremented value set by `GetWorkStates`). |
| `@Comment` | `nvarchar(max)` | Yes | `NULL` | Free-text comment for the state (e.g., rejection reason). Truncated to 4000 characters. |
| `@ValidationErrors` | `Apex.Ids` (TVP) | No | — | Set of validation error IDs currently blocking this customer. Pass empty TVP for no errors. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `State` | `Apex` | MERGE (INSERT / conditional UPDATE) | Within explicit transaction; change-detection on `ApexStateID` and `Comment`. |
| `StateProcessingData` | `Apex` | MERGE (INSERT / conditional UPDATE) | Within explicit transaction; change-detection on all five scheduling fields. |
| `UserValidationErrors` | `Apex` | DELETE + INSERT | Outside the explicit transaction; errors are fully replaced. |

---

## 5. Logic Flow

1. `SET XACT_ABORT ON`.
2. Truncates `@Comment` to 4000 characters with `SUBSTRING(@Comment, 0, 4000)`.
3. **BEGIN TRANSACTION (`Update_Apex_State_Tran`):**
   - **MERGE `Apex.State`:** Match on `GCID`. Update if `ApexStateID` or `Comment` differs. Insert if not found.
   - **MERGE `Apex.StateProcessingData`:** Match on `GCID`. Update if any of the five scheduling fields differ. Insert if not found.
   - **COMMIT.**
4. **CATCH block:** ROLLBACK + THROW (re-raise original exception).
5. **After commit (outside transaction):**
   - `DELETE FROM Apex.UserValidationErrors WHERE GCID = @GCID`.
   - `INSERT INTO Apex.UserValidationErrors (GCID, ApexValidationErrorID) SELECT @GCID, ID FROM @ValidationErrors`.

The validation-error replacement is intentionally **outside** the state transaction — this prevents the error-list from being rolled back if a transient error occurs after the state commit.

---

## 6. Error Handling

- `SET XACT_ABORT ON` ensures any statement error rolls back the open transaction automatically.
- `BEGIN TRY / BEGIN CATCH` with explicit `ROLLBACK` and `THROW` for clean error propagation.
- The post-commit validation-error section has no error handling — if it fails after the state commit succeeds, the caller gets an exception but the state has already been committed. This is a known design trade-off.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.State` | Table | Logical state; MERGE target |
| `Apex.StateProcessingData` | Table | Processing queue; MERGE target |
| `Apex.UserValidationErrors` | Table | Validation errors; fully replaced |
| `Apex.Ids` | User-Defined Table Type | TVP type for `@ValidationErrors` |
| `Apex.GetWorkStates` | Stored Procedure | Claims customers for processing; SaveState writes back the results |
| `Apex.GetState` | Stored Procedure | Reads the state written here |
| `Apex.GetApexDataAndState` | Stored Procedure | Reads state + validation errors written here |

---

## 8. Usage Notes

- **ErrorCount convention:** `GetWorkStates` pre-increments `ErrorCount` before returning customers for processing. On success, call `SaveState` with `ErrorCount - 1` (decrement) to restore the count. On failure, leave it elevated to trigger exponential backoff on the next claim.
- **InWork = 0** should always be set when the worker has finished processing a customer (success or final failure). Failing to do so will leave the customer with `InWork = 1` until the work-timeout expires in `GetWorkStates`.
- **Validation errors:** Pass an empty `@ValidationErrors` TVP to clear all errors; pass a populated TVP to replace the current error set. The delete-then-insert pattern avoids differential logic and always results in exactly the errors you pass.
- **@Comment** is truncated to 4000 characters silently. Ensure rejection or error messages fit within this limit for full audit trail preservation.
- The `Apex.Ids` TVP type must be defined in the database; it is a single-column type with an `ID int` column.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveState.sql` | Quality Score: 9.0/10*
