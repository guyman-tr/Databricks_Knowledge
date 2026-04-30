# BackOffice.WithdrawRequestApprove

> Marks a withdrawal request as fully approved (Approved=1) by calling Billing.UpsertWithdraw with the best non-auto approval comment; validates existence and non-approval state before updating.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID - PK of Billing.Withdraw |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.WithdrawRequestApprove` is the final approval step in the withdrawal workflow. Once all required back-office groups have recorded their individual approvals in `BackOffice.WithdrawApproval` (via `WithdrawApprovalUpsert`), this SP is called to formally mark the entire withdrawal as approved by setting `Billing.Withdraw.Approved=1`.

This SP is typically called by `WithdrawApprovalAdd` after detecting that all required group approvals are satisfied. It:
1. Validates the withdrawal exists and has not already been approved.
2. Selects the most meaningful comment from `BackOffice.WithdrawApproval` (preferring non-auto-approval comments over 'Auto Approval' entries).
3. Uses `Billing.UpsertWithdraw` to set Approved=1 with the selected comment (since September 2021, replacing a direct UPDATE pattern per DBA-648).

**History**: Prior to September 2021, the SP directly updated `Billing.Withdraw` and inserted into `History.WithdrawAction` for audit tracking. The refactoring to `Billing.UpsertWithdraw` centralized the Withdraw update/history logic in the Billing schema.

---

## 2. Business Logic

### 2.1 Pre-Validation

**What**: Guards against approving non-existent or already-approved withdrawals.

**Rules**:
- `NOT EXISTS (Billing.Withdraw WHERE WithdrawID=@WithdrawID)`: RAISERROR(60025) - "request does not exist". Return 60025.
- `NOT EXISTS (Billing.Withdraw WHERE WithdrawID=@WithdrawID AND Approved=0)`: RAISERROR(60025) - "request already approved". Return 60025.

### 2.2 Comment Selection

**What**: Selects the most meaningful comment from the approval group records.

**Rules**:
- `SELECT TOP 1 Comment FROM BackOffice.WithdrawApproval WHERE WithdrawID=@WithdrawID ORDER BY CASE WHEN Comment NOT LIKE '%Auto Approval%' THEN 0 ELSE 1 END, ApprovedWithdrawID DESC`
- Prefers non-auto-approval comments (rank 0) over auto-approval comments (rank 1).
- Secondary sort by ApprovedWithdrawID DESC - most recent first within same preference tier.

### 2.3 Approval Execution via Billing.UpsertWithdraw

**What**: Sets Approved=1 on Billing.Withdraw via the billing procedure.

**Rules**:
- Constructs @Info row in `Billing.TBL_Withdraw` TVT with: WithdrawID, Approved=1, Comment=@Comment, WithrawActionManagerID=0 (system manager).
- EXEC Billing.UpsertWithdraw @Info - delegates the actual Billing.Withdraw UPDATE and History.WithdrawAction INSERT to the billing procedure.
- RETURN 0 on success.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | int | NO | - | CODE-BACKED | The withdrawal request to approve (maps to Billing.Withdraw.WithdrawID). Must exist and have Approved=0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | SELECT (pre-validation) | Checks existence and Approved=0 state |
| @WithdrawID | BackOffice.WithdrawApproval | SELECT (comment selection) | Reads best non-auto comment for the approval record |
| @WithdrawID | Billing.UpsertWithdraw | EXEC callee | Sets Approved=1 on Billing.Withdraw + writes history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.WithdrawApprovalAdd | - | Caller (likely) | Calls this after all required group approvals are satisfied |
| BackOffice.WithdrawApproval table logic | - | Triggered via SP chain | Approval workflow completion triggers this |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.WithdrawRequestApprove (procedure)
+-- Billing.Withdraw (table) [SELECT: pre-validation]
+-- BackOffice.WithdrawApproval (table) [SELECT: best comment selection]
+-- Billing.UpsertWithdraw (procedure) [EXEC: sets Approved=1 + history]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SELECT: existence check + Approved=0 check |
| BackOffice.WithdrawApproval | Table | SELECT TOP 1 best comment (non-auto preferred) |
| Billing.UpsertWithdraw | Procedure | EXEC: sets Approved=1, Comment, ManagerID=0 (system) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.WithdrawApprovalAdd | Procedure (inferred) | Calls after all group approvals are satisfied |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- RAISERROR(60025) for both validation failures.
- BEGIN/COMMIT TRANSACTION wraps the Billing.UpsertWithdraw call.
- TRY/CATCH with THROW on error.
- `Billing.TBL_Withdraw` is a user-defined table type used as a TVT parameter to Billing.UpsertWithdraw.
- Old pattern (commented out): direct UPDATE Billing.Withdraw + INSERT History.WithdrawAction; replaced September 2021 (DBA-648).

---

## 8. Sample Queries

### 8.1 Approve a withdrawal (called after all group approvals received)

```sql
DECLARE @ret INT;
EXEC @ret = BackOffice.WithdrawRequestApprove @WithdrawID = 1234567;
SELECT @ret AS ReturnCode;  -- 0 = success, 60025 = validation error
```

### 8.2 Check if a withdrawal is ready to approve

```sql
SELECT w.WithdrawID, w.Approved, w.Amount, w.CashoutStatusID,
       COUNT(a.ApprovedWithdrawID) AS GroupDecisions,
       SUM(CASE WHEN a.Approved=1 THEN 1 ELSE 0 END) AS GroupApprovals
FROM Billing.Withdraw w WITH (NOLOCK)
LEFT JOIN BackOffice.WithdrawApproval a WITH (NOLOCK) ON a.WithdrawID = w.WithdrawID
WHERE w.WithdrawID = 1234567
GROUP BY w.WithdrawID, w.Approved, w.Amount, w.CashoutStatusID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| DBA-648 | Jira | Refactored to use Billing.UpsertWithdraw instead of direct UPDATE - September 2021 |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Dependency Inheritance, Caller Scan, Code Analysis, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 1 Jira (from DDL comments) | Procedures: 1 callee analyzed (Billing.UpsertWithdraw) | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.WithdrawRequestApprove | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.WithdrawRequestApprove.sql*
