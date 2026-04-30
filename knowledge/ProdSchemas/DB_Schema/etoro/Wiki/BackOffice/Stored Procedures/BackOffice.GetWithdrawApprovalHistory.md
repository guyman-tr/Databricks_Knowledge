# BackOffice.GetWithdrawApprovalHistory

> Returns the complete approval decision history for withdrawal requests in a date range - combining current live approval records with the historical audit log for full auditability.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate / @EndDate (required); returns BackOffice.WithdrawApproval UNION History.WithdrawApproval rows filtered by withdrawal ModificationDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetWithdrawApprovalHistory` produces an auditable record of all approval decisions made on withdrawal requests within a given time window. It is used by Back Office compliance and risk teams to audit the approval trail: which user group approved/rejected which withdrawal, which manager made the decision, and what reason was given.

The procedure uses a CTE that UNIONs `BackOffice.WithdrawApproval` (current live approvals) and `History.WithdrawApproval` (archived/historical decisions) to provide a complete picture including decisions that have since been overwritten. The date filter is applied on `Billing.Withdraw.ModificationDate` (not on the approval timestamp itself), so all approval events for withdrawals modified within the window are included.

The optional `@CID` parameter restricts results to a single customer's withdrawals.

---

## 2. Business Logic

### 2.1 UNION of Current and Historical Approvals

**What**: Combines the live approval table with the historical archive for complete audit coverage.

**Columns/Parameters Involved**: `BackOffice.WithdrawApproval`, `History.WithdrawApproval`

**Rules**:
- Branch 1: BackOffice.WithdrawApproval - current live decisions
- Branch 2: History.WithdrawApproval - archived decisions (may include superseded approvals)
- UNION ALL - preserves duplicates (same decision may appear in both tables during transition period)
- Date filtering on Billing.Withdraw.ModificationDate, not on approval Occurred timestamp
- JOINs require BackOffice.Manager, Dictionary.UserGroup, Dictionary.WithdrawApprovalReason to be present - these are INNER JOINs, so approvals without matching manager/group/reason are excluded

### 2.2 Date Filter on Withdrawal Modification

**What**: Filters by when the withdrawal was last modified, not when the approval decision was made.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `Billing.Withdraw.ModificationDate`

**Rules**:
- WHERE BWIT.ModificationDate BETWEEN @StartDate AND @EndDate
- A withdrawal's ModificationDate updates when any change is made (status change, approval, rejection)
- This means all approvals for withdrawals that were active/modified in the window are included

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of date range. Filters on Billing.Withdraw.ModificationDate >= @StartDate. Required. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of date range. Filters on Billing.Withdraw.ModificationDate <= @EndDate. Required. |
| 3 | @CID | INT | YES | NULL | CODE-BACKED | Optional customer ID filter. NULL = all customers. When provided: AND BWIT.CID = @CID. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal (BackOffice.WithdrawApproval.WithdrawID). |
| 2 | User Group | NVARCHAR | NO | - | CODE-BACKED | Name of the user group that made this decision (Dictionary.UserGroup.Name via UserGroupID). |
| 3 | Manager | NVARCHAR | NO | - | CODE-BACKED | Full name of the manager who submitted the approval decision (BackOffice.Manager.FirstName + LastName). |
| 4 | Approved | BIT | NO | - | CODE-BACKED | Whether this group approved (1) or rejected (0) the withdrawal. |
| 5 | Reason | NVARCHAR | NO | - | CODE-BACKED | Approval/rejection reason name (Dictionary.WithdrawApprovalReason.Name). |
| 6 | Comment | NVARCHAR | YES | - | CODE-BACKED | Free-text comment from the approving manager (BackOffice.WithdrawApproval.Comment). |
| 7 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp when this approval decision was made (BackOffice.WithdrawApproval.Occurred). Ordered DESC. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | BackOffice.WithdrawApproval | CTE branch 1 | Current live approval decisions |
| WithdrawID | History.WithdrawApproval | CTE branch 2 | Historical archived approval decisions |
| WAWH.ManagerID | BackOffice.Manager | INNER JOIN | Manager full name |
| WAWH.UserGroupID | Dictionary.UserGroup | INNER JOIN | Group name |
| WAWH.WithdrawApprovalReasonID | Dictionary.WithdrawApprovalReason | INNER JOIN | Reason name |
| WAWH.WithdrawID | Billing.Withdraw | INNER JOIN | ModificationDate filter + optional CID filter |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO audit / compliance screens) | @StartDate / @EndDate | Application | Withdrawal approval audit trail |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdrawApprovalHistory (procedure)
├── BackOffice.WithdrawApproval (table) - current approvals
├── History.WithdrawApproval (table) - archived approvals
├── BackOffice.Manager (table)
├── Dictionary.UserGroup (table)
├── Dictionary.WithdrawApprovalReason (table)
└── Billing.Withdraw (table) - date filter + CID filter
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.WithdrawApproval | Table | CTE branch 1 - current approval decisions |
| History.WithdrawApproval | Table | CTE branch 2 - historical approval audit |
| BackOffice.Manager | Table | INNER JOIN - manager name |
| Dictionary.UserGroup | Table | INNER JOIN - user group name |
| Dictionary.WithdrawApprovalReason | Table | INNER JOIN - reason name |
| Billing.Withdraw | Table | INNER JOIN - ModificationDate filter and @CID filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called by BO audit screens and compliance tools. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOINs on lookup tables | Logic | Manager, UserGroup, and WithdrawApprovalReason are INNER JOINs - approvals without valid manager/group/reason data are excluded from results |
| OPTION (RECOMPILE) | Performance | Prevents plan caching issues with optional @CID parameter - forces re-evaluation of the CID = ISNULL(@CID, CID) predicate each execution |
| Date filter on ModificationDate | Semantic | Filter is on Billing.Withdraw.ModificationDate, not on approval Occurred date. A withdrawal modified outside the window would not appear even if an approval decision was made within the window. |
| UNION ALL (not UNION) | Implementation | Duplicate records possible if an approval exists in both current and history tables simultaneously |

---

## 8. Sample Queries

### 8.1 Get all approval history for a date range
```sql
EXEC [BackOffice].[GetWithdrawApprovalHistory]
    @StartDate = '20250101',
    @EndDate = '20250131',
    @CID = NULL
```

### 8.2 Get approval history for a specific customer
```sql
EXEC [BackOffice].[GetWithdrawApprovalHistory]
    @StartDate = '20240101',
    @EndDate = '20251231',
    @CID = 123456
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdrawApprovalHistory | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetWithdrawApprovalHistory.sql*
