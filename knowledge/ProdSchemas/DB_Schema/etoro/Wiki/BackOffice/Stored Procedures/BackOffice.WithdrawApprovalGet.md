# BackOffice.WithdrawApprovalGet

> Returns all approval records for a specific withdrawal from BackOffice.WithdrawApproval by WithdrawID - one row per group that has reviewed the withdrawal.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawId - FK to Billing.Withdraw.WithdrawID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.WithdrawApprovalGet` retrieves the approval workflow state for a specific customer withdrawal request. Customer withdrawals require independent review and approval from up to four back-office groups (Admin, Risk, Marketing, Trading), with one `BackOffice.WithdrawApproval` row per group. This SP returns all rows for the given WithdrawID, giving the caller a complete view of the multi-party approval status.

The result allows the calling service to determine:
- Which groups have reviewed the withdrawal (presence of rows per UserGroupID)
- Whether each group approved (Approved=1) or rejected (Approved=0)
- Who made the decision (ManagerID - 0 means automated)
- When the decision was made (Occurred)
- What reason was given (WithdrawApprovalReasonID)
- Any agent comment (Comment)

Introduced May 2022 (MIMOPSB-899) as part of the MIMO payment system's withdrawal approval query interface.

---

## 2. Business Logic

### 2.1 Approval Records Retrieval

**What**: SELECT all approval records for the given WithdrawID.

**Columns/Parameters Involved**: `@WithdrawId`, `BackOffice.WithdrawApproval.*`

**Rules**:
- Returns ALL rows for the WithdrawID - may return 0-4 rows depending on how many groups have reviewed.
- No filtering by Approved status - returns both approved and rejected records.
- Order of rows is by the table's clustered index (ApprovedWithdrawID, identity).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawId | int | NO | - | CODE-BACKED | The withdrawal ID to look up (FK to Billing.Withdraw.WithdrawID). Returns all approval group decisions for this withdrawal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawId | [BackOffice.WithdrawApproval](../Tables/BackOffice.WithdrawApproval.md) | SELECT source | Returns all approval rows for the given WithdrawID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No direct callers found in BackOffice SPs. | - | - | Called from MIMO payment system and withdrawal management services. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.WithdrawApprovalGet (procedure)
+-- BackOffice.WithdrawApproval (table) [SELECT source]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [BackOffice.WithdrawApproval](../Tables/BackOffice.WithdrawApproval.md) | Table | SELECT all columns WHERE WithdrawID=@WithdrawId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from MIMO payment services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Uses NOLOCK hint for non-blocking read.

### 7.2 Constraints

- SET NOCOUNT ON.
- Returns 0 rows if @WithdrawId has no approval records yet (withdrawal not yet reviewed by any group).

---

## 8. Sample Queries

### 8.1 Get approval status for a withdrawal

```sql
EXEC BackOffice.WithdrawApprovalGet @WithdrawId = 1234567;
-- Returns: one row per group that reviewed the withdrawal
-- Columns: ID (ApprovedWithdrawID), WithdrawID, UserGroupID, ManagerID,
--          WithdrawApprovalReasonID, Approved, Occurred, Comment
```

### 8.2 Get the same data directly (for filtering/joining)

```sql
SELECT ApprovedWithdrawID AS ID, WithdrawID, UserGroupID, ManagerID,
       WithdrawApprovalReasonID, Approved, Occurred, Comment
FROM BackOffice.WithdrawApproval WITH (NOLOCK)
WHERE WithdrawID = 1234567;
-- UserGroupID: 1=Admin, 3=Risk, 4=Marketing, 6=Trading
-- Approved: 1=Approved, 0=Rejected
-- ManagerID=0 = automated system approval
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPSB-899 | Jira | Initial version - May 2022 |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 1 Jira (from DDL comments) | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.WithdrawApprovalGet | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.WithdrawApprovalGet.sql*
