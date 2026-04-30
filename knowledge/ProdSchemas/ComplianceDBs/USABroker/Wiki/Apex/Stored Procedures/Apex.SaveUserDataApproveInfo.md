# Apex.SaveUserDataApproveInfo

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserDataApproveInfo.sql`  
**Author:** Dmitriy Gavrish  
**Created:** 2021-08-27  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveUserDataApproveInfo` is a **targeted update** that records only the approval metadata on a customer's `UserData` record — the name of the person who approved the account and the timestamp of that approval. This narrow-scope procedure exists because approval events are raised independently of full profile updates: when a compliance officer or automated workflow approves an account, only these two fields need to be written without touching any other KYC or personal data.

It is called by the compliance approval workflow service when an account reaches the approved state.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID of the customer being approved. |
| `@ApproverName` | `varchar(128)` | No | Name of the staff member or system that approved the account. |
| `@ApprovedByDate` | `datetime2(7)` | No | UTC timestamp when the approval was granted. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserData` | `Apex` | UPDATE | Updates exactly two columns; requires the row to already exist. |

---

## 5. Logic Flow

1. Single `UPDATE Apex.UserData SET ApproverName = @ApproverName, ApprovedByDate = @ApprovedByDate WHERE GCID = @GCID`.
2. No INSERT path — if no `UserData` row exists for the GCID, the UPDATE silently affects 0 rows.
3. No change-detection — always writes both fields when called.

---

## 6. Error Handling

No explicit error handling. If `GCID` does not exist, the update silently affects 0 rows. Callers should verify `@@ROWCOUNT = 1` if confirmation is required.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserData` | Table | KYC data store; UPDATE target |
| `Apex.SaveUserData` | Stored Procedure | Full profile writer; also writes `ApproverName` and `ApprovedByDate` |
| `Apex.GetApexDataAndState` | Stored Procedure | Reads `ApproverName` and `ApprovedByDate` written here |

---

## 8. Usage Notes

- This procedure assumes the `UserData` row already exists. It must be called **after** `Apex.SaveUserData` has been called at least once for the customer.
- Use this instead of `SaveUserData` when only approval metadata needs to be updated — it avoids overwriting all KYC fields with potentially stale data from the calling context.
- `@ApproverName` should contain a human-readable identifier — either a staff member's name or a system/service identifier for automated approvals.
- There is no check for whether the customer is in an approvable state; that logic must be enforced by the caller or the workflow engine.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserDataApproveInfo.sql` | Quality Score: 8.5/10*
