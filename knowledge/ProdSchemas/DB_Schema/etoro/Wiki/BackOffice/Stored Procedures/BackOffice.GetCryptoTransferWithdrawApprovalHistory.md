# BackOffice.GetCryptoTransferWithdrawApprovalHistory

> Returns the full audit trail of withdrawal approval decisions for a date range, combining active and historical approval records.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate / @EndDate date range; filters by Billing.Withdraw.ModificationDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the complete approval decision history for withdrawal requests within a given date window. Each row represents one approval or rejection action taken by a BackOffice manager on a specific withdrawal, including which user group the manager belonged to, the stated reason for the decision, and any free-text comment recorded at the time.

This procedure exists to support BackOffice compliance and audit workflows. Without it, agents reviewing a withdrawal's approval chain would need to query two tables (active and archived) separately and join them manually, which risks missing historical records. Any regulatory audit or dispute resolution process that requires knowing who approved or rejected a withdrawal, when, and why depends on this procedure.

Data flows from two sources: `BackOffice.WithdrawApproval` (active approval records) and `History.WithdrawApproval` (archived records). Both are UNIONed to provide a complete, unbroken history. The date filter is applied against `Billing.Withdraw.ModificationDate` (the last status change date of the parent withdrawal), not the approval timestamp itself - this means the window targets withdrawals that were last modified in the range, not necessarily approved in the range.

---

## 2. Business Logic

### 2.1 Dual-Table History Union

**What**: Approval history spans two physical tables to keep the active table performant while retaining full audit history.

**Columns/Parameters Involved**: `BackOffice.WithdrawApproval`, `History.WithdrawApproval`

**Rules**:
- Both tables have identical schemas; UNION ALL merges them without deduplication
- Active approvals live in `BackOffice.WithdrawApproval`; older records are archived to `History.WithdrawApproval`
- Results are ordered by `Occurred DESC` (the timestamp when the approval action was taken), so the most recent action appears first

**Diagram**:
```
BackOffice.WithdrawApproval (active)
         +
History.WithdrawApproval (archive)
         |
         v
    UNION ALL (WAPH)
         |
   JOIN Billing.Withdraw (date filter on ModificationDate)
         |
   JOIN Manager, UserGroup, WithdrawApprovalReason
         |
   ORDER BY Occurred DESC
```

### 2.2 Date Filter Applied to Parent Withdrawal, Not Approval

**What**: The @StartDate / @EndDate window filters on the withdrawal's last modification date, not the approval action timestamp.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `Billing.Withdraw.ModificationDate`

**Rules**:
- `WHERE BWIT.ModificationDate BETWEEN @StartDate AND @EndDate` targets withdrawals whose overall status last changed in the window
- A withdrawal approved weeks ago but whose status changed recently (e.g., reversal, reprocessing) would appear
- This aligns the query with how BackOffice operators think about "what changed this week" rather than "what was approved this week"

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the date window applied to Billing.Withdraw.ModificationDate. Filters withdrawals whose status last changed on or after this date. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the date window applied to Billing.Withdraw.ModificationDate. Filters withdrawals whose status last changed on or before this date. |
| **Output Columns** | | | | | | |
| 3 | WithdrawID | INT | NO | - | CODE-BACKED | Unique identifier of the parent withdrawal request. FK to Billing.Withdraw.WithdrawID. Links approval records back to the originating cashout. |
| 4 | User Group | NVARCHAR | YES | - | CODE-BACKED | Name of the BackOffice user group the approving/rejecting manager belonged to at the time of action. From Dictionary.UserGroup.Name via WAPH.UserGroupID. Indicates which team tier handled the approval (e.g., Risk, Compliance, Finance). |
| 5 | Manager | NVARCHAR | YES | - | CODE-BACKED | Full name of the BackOffice manager who took the approval action. Computed as BackOffice.Manager.FirstName + ' ' + LastName. NULL if ManagerID has no matching record. |
| 6 | Approved | BIT | NO | - | CODE-BACKED | The approval decision: 1 = approved (withdrawal proceeds), 0 = rejected (withdrawal blocked). Directly from BackOffice.WithdrawApproval.Approved. |
| 7 | Reason | NVARCHAR | YES | - | CODE-BACKED | Standardized reason code label for the approval/rejection decision. From Dictionary.WithdrawApprovalReason.Name. Provides categorical classification of why the decision was made (e.g., "Fraud Suspected", "Documents Verified"). |
| 8 | Comment | NVARCHAR | YES | - | CODE-BACKED | Free-text comment recorded by the manager when taking the approval action. From WAPH.Comment. Contains case-specific notes not captured by the Reason code. |
| 9 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp when the approval or rejection action was recorded. From WAPH.Occurred. Used for ORDER BY DESC so the most recent action appears first. This is the approval action time, distinct from the withdrawal's ModificationDate used for filtering. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | Lookup / JOIN | Joins to get ModificationDate for date filtering; links approval to the parent cashout request |
| ManagerID | BackOffice.Manager | Lookup / JOIN | Resolves manager ID to full name for display |
| UserGroupID | Dictionary.UserGroup | Lookup / JOIN | Resolves user group ID to descriptive name |
| WithdrawApprovalReasonID | Dictionary.WithdrawApprovalReason | Lookup / JOIN | Resolves reason code to human-readable label |
| (source data) | BackOffice.WithdrawApproval | Direct READ | Active approval records |
| (source data) | History.WithdrawApproval | Direct READ | Archived approval records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Called by BackOffice UI to display the withdrawal approval audit trail. Per Confluence MIMOPSB-929 (2022), flagged for migration to API-based access. |
| BackOffice.GetCashOutRequests | (embedded logic) | Parallel implementation | GetCashOutRequests contains its own inline version of this approval history union as a third result set, but references this SP's data pattern independently. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCryptoTransferWithdrawApprovalHistory (procedure)
├── BackOffice.WithdrawApproval (table)
├── History.WithdrawApproval (table)
├── BackOffice.Manager (table)
├── Dictionary.UserGroup (table)
├── Dictionary.WithdrawApprovalReason (table)
└── Billing.Withdraw (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.WithdrawApproval | Table | Primary source of active approval records (UNION ALL) |
| History.WithdrawApproval | Table | Archive source of historical approval records (UNION ALL) |
| BackOffice.Manager | Table | JOINed to resolve ManagerID to FirstName + LastName |
| Dictionary.UserGroup | Table | JOINed to resolve UserGroupID to Name |
| Dictionary.WithdrawApprovalReason | Table | JOINed to resolve WithdrawApprovalReasonID to Name |
| Billing.Withdraw | Table | JOINed to apply ModificationDate date range filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Reads approval history for display in withdrawal management UI |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get approval history for a specific withdrawal

```sql
EXEC BackOffice.GetCryptoTransferWithdrawApprovalHistory
    @StartDate = '2026-03-01',
    @EndDate   = '2026-03-17';
```

### 8.2 Check recent rejections in a narrow window

```sql
-- Run the SP and filter client-side or wrap in a CTE
DECLARE @Results TABLE (
    WithdrawID INT, [User Group] NVARCHAR(100),
    Manager NVARCHAR(200), Approved BIT,
    Reason NVARCHAR(200), Comment NVARCHAR(MAX), Occurred DATETIME
);
INSERT @Results
EXEC BackOffice.GetCryptoTransferWithdrawApprovalHistory
    @StartDate = '2026-03-10', @EndDate = '2026-03-17';
SELECT * FROM @Results WHERE Approved = 0 ORDER BY Occurred DESC;
```

### 8.3 Verify the underlying source tables directly

```sql
SELECT w.WithdrawID, wa.ManagerID, wa.Approved, wa.Occurred,
       dar.Name AS Reason, dug.Name AS UserGroup
FROM BackOffice.WithdrawApproval wa WITH (NOLOCK)
JOIN Billing.Withdraw w WITH (NOLOCK) ON w.WithdrawID = wa.WithdrawID
JOIN Dictionary.WithdrawApprovalReason dar WITH (NOLOCK)
    ON dar.WithdrawApprovalReasonID = wa.WithdrawApprovalReasonID
JOIN Dictionary.UserGroup dug WITH (NOLOCK) ON dug.UserGroupID = wa.UserGroupID
WHERE w.ModificationDate BETWEEN '2026-03-01' AND '2026-03-17'
ORDER BY wa.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MIMOPSB-929 - Approval dependencies on etoro db](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11702501687) | Confluence | Confirmed this SP is called by BackOffice (BO) application only. Flagged as needing migration from direct DB access to API-based architecture. BackOffice.WithdrawApproval and History.WithdrawApproval identified as tables to move to a new schema. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCryptoTransferWithdrawApprovalHistory | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCryptoTransferWithdrawApprovalHistory.sql*
