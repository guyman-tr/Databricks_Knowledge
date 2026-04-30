# BackOffice.WithdrawApprovalUpsert

> Adds or updates a group's approval decision for a withdrawal in BackOffice.WithdrawApproval via MERGE, with validation that the withdrawal is not already approved or cancelled; writes previous decision to History.WithdrawApproval on overwrite.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID + @UserGroupID - MERGE key for approval record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.WithdrawApprovalUpsert` is the write path for individual group approval decisions in the withdrawal approval workflow. Customer withdrawals require independent approval from up to four back-office groups (Admin=1, Risk=3, Marketing=4, Trading=6). This SP records or updates a single group's decision for a specific withdrawal.

The SP uses a MERGE keyed on (WithdrawID, UserGroupID) - if the group has already submitted a decision, the existing record is updated; if not, a new record is inserted. When an existing record is overwritten (MATCHED), the old values are captured via OUTPUT and inserted into `History.WithdrawApproval` for audit tracking.

Pre-conditions enforced: the withdrawal must not already be fully approved (`Billing.Withdraw.Approved=1`) and must not be in Canceled cashout status. This prevents decisions being recorded on completed or voided withdrawals.

---

## 2. Business Logic

### 2.1 Pre-Validation

**What**: Guards against recording approvals on already-completed or cancelled withdrawals.

**Rules**:
- `SELECT Approved, DCS.Name FROM Billing.Withdraw JOIN Dictionary.CashoutStatus` for the WithdrawID.
- If `Approved=1`: RAISERROR(60025) - "Withdraw Request Already Approved". Returns 60025.
- If `CashoutStatusName = 'Canceled'`: RAISERROR(60025) - "Can not approve because WithdrawID is in Cancel cashout status". Returns 60025.

### 2.2 MERGE Into BackOffice.WithdrawApproval

**What**: Atomically inserts or updates the group's approval record.

**MERGE Key**: `(BWA.WithdrawID = Src.WithdrawID AND BWA.UserGroupID = Src.UserGroupID)`

**MATCHED (update existing approval)**:
- Updates: ManagerID, Comment, WithdrawApprovalReasonID, Approved, Occurred=GETUTCDATE()
- Captures old values in OUTPUT DELETED into @Info table variable

**NOT MATCHED (new approval from this group)**:
- Inserts new row with: WithdrawID, UserGroupID, ManagerID, WithdrawApprovalReasonID, Approved, Occurred=GETUTCDATE(), Comment

### 2.3 History Tracking (On Overwrite Only)

**What**: When an existing approval is overwritten, the old values are inserted into History.WithdrawApproval.

**Rules**:
- INSERT into History.WithdrawApproval from @Info WHERE ApprovedWithdrawID IS NOT NULL.
- `ApprovedWithdrawID IS NOT NULL` is true only for MATCHED (UPDATE) rows - DELETED.ApprovedWithdrawID is NULL for NOT MATCHED (INSERT) rows.
- This means: first-time group approvals are NOT tracked in history; only changes to existing approvals create a history record.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | int | NO | - | CODE-BACKED | The withdrawal being approved (FK to Billing.Withdraw.WithdrawID). Used as the MERGE key with UserGroupID. |
| 2 | @UserGroupID | int | NO | - | CODE-BACKED | The reviewing group (maps to BackOffice.WithdrawApproval.UserGroupID). Key values: 1=Admin, 3=Risk, 4=Marketing, 6=Trading. Combined with @WithdrawID as the MERGE unique key. |
| 3 | @ManagerID | int | NO | - | CODE-BACKED | The manager/agent recording this decision (maps to BackOffice.WithdrawApproval.ManagerID). 0=automated/system. |
| 4 | @WithdrawApprovalReasonID | int | NO | - | CODE-BACKED | Reason code for the approval decision (maps to BackOffice.WithdrawApproval.WithdrawApprovalReasonID). ReasonID=7=Other (bulk/automated). |
| 5 | @Approved | bit | NO | - | CODE-BACKED | Whether this group approves (1) or rejects (0) the withdrawal (maps to BackOffice.WithdrawApproval.Approved). |
| 6 | @Comment | varchar(max) | NO | - | CODE-BACKED | Free-text comment for this approval decision (maps to BackOffice.WithdrawApproval.Comment). Can be 'Auto Approval' for system-generated decisions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | SELECT (pre-validation) | Checks Approved flag and CashoutStatus |
| @WithdrawID + status | Dictionary.CashoutStatus | JOIN (pre-validation) | Gets CashoutStatusName to check for 'Canceled' |
| @WithdrawID + @UserGroupID | [BackOffice.WithdrawApproval](../Tables/BackOffice.WithdrawApproval.md) | MERGE target | Inserts or updates group approval record |
| Old values | History.WithdrawApproval | INSERT (audit) | Records overwritten approval decisions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No direct callers found in BackOffice SPs. | - | - | Called from withdrawal approval workflow services (MIMOPSB-899 context). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.WithdrawApprovalUpsert (procedure)
+-- Billing.Withdraw (table) [SELECT: pre-validation of Approved flag and CashoutStatusID]
+-- Dictionary.CashoutStatus (table) [JOIN: CashoutStatusName for Canceled check]
+-- BackOffice.WithdrawApproval (table) [MERGE target: INSERT or UPDATE group decision]
+-- History.WithdrawApproval (table) [INSERT: audit trail on overwrite]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SELECT for pre-validation (Approved, CashoutStatusID) |
| Dictionary.CashoutStatus | Table | JOIN for CashoutStatus name (Canceled check) |
| [BackOffice.WithdrawApproval](../Tables/BackOffice.WithdrawApproval.md) | Table | MERGE target: group approval record |
| History.WithdrawApproval | Table | INSERT audit trail when overwriting existing approval |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from withdrawal approval services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- RAISERROR(60025) for pre-validation failures (non-standard error code used across BackOffice for business rule violations).
- BEGIN TRANSACTION / COMMIT TRANSACTION wraps MERGE + History INSERT.
- TRY/CATCH with THROW on error - caller sees the original error.
- History tracking: only MATCHED (UPDATE) cases generate history rows; new inserts are not tracked in History.WithdrawApproval.

---

## 8. Sample Queries

### 8.1 Record Risk group approval

```sql
EXEC BackOffice.WithdrawApprovalUpsert
    @WithdrawID               = 1234567,
    @UserGroupID              = 3,        -- Risk group
    @ManagerID                = 99,       -- reviewing manager ID
    @WithdrawApprovalReasonID = 1,        -- standard approval reason
    @Approved                 = 1,        -- approved
    @Comment                  = 'Verified customer KYC - no issues';
```

### 8.2 Automated (system) approval

```sql
EXEC BackOffice.WithdrawApprovalUpsert
    @WithdrawID               = 1234567,
    @UserGroupID              = 1,        -- Admin group
    @ManagerID                = 0,        -- system (automated)
    @WithdrawApprovalReasonID = 7,        -- Other (auto-approval)
    @Approved                 = 1,
    @Comment                  = 'Auto Approval';
```

### 8.3 Check what approvals exist for a withdrawal

```sql
SELECT UserGroupID, Approved, ManagerID, WithdrawApprovalReasonID, Occurred, Comment
FROM BackOffice.WithdrawApproval WITH (NOLOCK)
WHERE WithdrawID = 1234567;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object (related to MIMOPSB-899 context).

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Dependency Inheritance, Caller Scan, Code Analysis, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.WithdrawApprovalUpsert | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.WithdrawApprovalUpsert.sql*
