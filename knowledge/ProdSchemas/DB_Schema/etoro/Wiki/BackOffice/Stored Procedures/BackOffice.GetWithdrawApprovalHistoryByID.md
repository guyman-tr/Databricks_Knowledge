# BackOffice.GetWithdrawApprovalHistoryByID

> Returns the complete approval decision history for a single withdrawal request by ID - combining current live approval records with the historical audit log for full auditability of a specific withdrawal.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID (required); returns BackOffice.WithdrawApproval UNION History.WithdrawApproval rows for one withdrawal |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetWithdrawApprovalHistoryByID` produces the complete approval audit trail for a single specific withdrawal request. It is the per-withdrawal counterpart to `GetWithdrawApprovalHistory` (which operates on a date range). Used by Back Office compliance and risk teams when investigating or auditing a specific withdrawal: which user groups were involved, which managers approved or rejected, what reasons were given, and the full chronological sequence of decisions.

The procedure uses the same CTE UNION pattern as `GetWithdrawApprovalHistory` - combining `BackOffice.WithdrawApproval` (current live approvals) with `History.WithdrawApproval` (archived/historical decisions) to provide a complete picture including decisions that may have been overwritten. Results are ordered by `Occurred DESC` (most recent first).

Added in MIMOPS-3983.

---

## 2. Business Logic

### 2.1 UNION of Current and Historical Approvals

**What**: Combines the live approval table with the historical archive for complete audit coverage of a single withdrawal.

**Columns/Parameters Involved**: `BackOffice.WithdrawApproval`, `History.WithdrawApproval`

**Rules**:
- Branch 1: BackOffice.WithdrawApproval - current live decisions for this WithdrawID
- Branch 2: History.WithdrawApproval - archived decisions (may include superseded approvals)
- UNION ALL - preserves duplicates (same decision may appear in both tables during transition)
- Filter applied directly to WAWH.WithdrawID = @WithdrawID in WHERE clause
- INNER JOINs on BackOffice.Manager, Dictionary.UserGroup, Dictionary.WithdrawApprovalReason - approvals without matching manager/group/reason are excluded
- Ordered by Occurred DESC (most recent approval decision first)

### 2.2 Withdrawal ID Filter

**What**: Restricts results to a single withdrawal.

**Columns/Parameters Involved**: `@WithdrawID`, `WAWH.WithdrawID`

**Rules**:
- WHERE WAWH.WithdrawID = @WithdrawID (direct equality, not date range)
- Returns ALL approval decisions ever made for that withdrawal (both current and historical)
- OPTION(RECOMPILE) not present (unlike the date-range version) - single equality predicate has stable plan

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal to retrieve approval history for. Required. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal (BackOffice.WithdrawApproval.WithdrawID). Same as @WithdrawID for all rows. |
| 2 | User Group | NVARCHAR | NO | - | CODE-BACKED | Name of the user group that made this decision (Dictionary.UserGroup.Name via UserGroupID). |
| 3 | Manager | NVARCHAR | NO | - | CODE-BACKED | Full name of the manager who submitted the approval decision (BackOffice.Manager.FirstName + LastName). |
| 4 | Approved | BIT | NO | - | CODE-BACKED | Whether this group approved (1) or rejected (0) the withdrawal. |
| 5 | Reason | NVARCHAR | NO | - | CODE-BACKED | Approval/rejection reason name (Dictionary.WithdrawApprovalReason.Name). |
| 6 | Comment | NVARCHAR | YES | - | CODE-BACKED | Free-text comment from the approving manager (BackOffice.WithdrawApproval.Comment). |
| 7 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp when this approval decision was made (BackOffice.WithdrawApproval.Occurred). Ordered DESC (most recent first). |

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

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO withdrawal detail screens) | @WithdrawID | Application | Withdrawal approval audit trail for a specific request |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdrawApprovalHistoryByID (procedure)
├── BackOffice.WithdrawApproval (table) - current approvals
├── History.WithdrawApproval (table) - archived approvals
├── BackOffice.Manager (table)
├── Dictionary.UserGroup (table)
└── Dictionary.WithdrawApprovalReason (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.WithdrawApproval | Table | CTE branch 1 - current approval decisions |
| History.WithdrawApproval | Table | CTE branch 2 - historical approval audit |
| BackOffice.Manager | Table | INNER JOIN - manager name |
| Dictionary.UserGroup | Table | INNER JOIN - user group name |
| Dictionary.WithdrawApprovalReason | Table | INNER JOIN - reason name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called by BO withdrawal detail screens. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOINs on lookup tables | Logic | Manager, UserGroup, and WithdrawApprovalReason are INNER JOINs - approvals without valid manager/group/reason data are excluded from results |
| UNION ALL (not UNION) | Implementation | Duplicate records possible if an approval exists in both current and history tables simultaneously (during transition periods) |
| Difference from GetWithdrawApprovalHistory | Design | This procedure filters by WithdrawID (single record lookup); GetWithdrawApprovalHistory filters by ModificationDate range across all withdrawals. Use this for investigating one withdrawal, use the date-range version for bulk audit reports. |

---

## 8. Sample Queries

### 8.1 Get full approval history for a specific withdrawal
```sql
EXEC [BackOffice].[GetWithdrawApprovalHistoryByID] @WithdrawID = 123456
```

### 8.2 Direct equivalent query
```sql
;WITH WithdrawApprovalWithHistory AS (
    SELECT WithdrawID, UserGroupID, ManagerID, WithdrawApprovalReasonID, Approved, Comment, Occurred
    FROM BackOffice.WithdrawApproval WITH (NOLOCK)
    UNION ALL
    SELECT WithdrawID, UserGroupID, ManagerID, WithdrawApprovalReasonID, Approved, Comment, Occurred
    FROM History.WithdrawApproval WITH (NOLOCK)
)
SELECT WAWH.WithdrawID,
       DUG.Name AS [User Group],
       BM.FirstName + ' ' + BM.LastName AS Manager,
       WAWH.Approved,
       DWAR.Name AS Reason,
       WAWH.Comment,
       WAWH.Occurred
FROM WithdrawApprovalWithHistory WAWH
INNER JOIN BackOffice.Manager BM WITH (NOLOCK) ON BM.ManagerID = WAWH.ManagerID
INNER JOIN Dictionary.UserGroup DUG WITH (NOLOCK) ON DUG.UserGroupID = WAWH.UserGroupID
INNER JOIN Dictionary.WithdrawApprovalReason DWAR WITH (NOLOCK) ON DWAR.WithdrawApprovalReasonID = WAWH.WithdrawApprovalReasonID
WHERE WAWH.WithdrawID = 123456
ORDER BY WAWH.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-3983 | Jira (DDL comment) | Original creation ticket |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira (MIMOPS-3983 from DDL comment) | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdrawApprovalHistoryByID | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetWithdrawApprovalHistoryByID.sql*
