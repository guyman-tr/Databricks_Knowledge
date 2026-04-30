# BackOffice.GetCryptoTransactionsApprovals

> Returns approval decision records for crypto transfers (redeems) within a date range, showing which manager/user group approved or rejected each transfer and their stated reason - the crypto transfer approval audit trail in BackOffice.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate/@EndDate (request date window on Billing.Redeem); optional @Instruments, @ShowOnlyApproved filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetCryptoTransactionsApprovals` shows the approval workflow records for crypto transfers. When a customer submits a crypto transfer request, one or more BackOffice managers or automated systems record approval/rejection decisions in `BackOffice.RedeemApproval`. This procedure surfaces those decisions alongside the approving manager, their user group, the approval reason, and any comment.

This is the approval audit trail for the crypto transfer management process. Multiple approval records may exist per transfer (multi-level approval, or initial rejection followed by approval on appeal). The result is filtered by the redeem's RequestDate (not the approval's Occurred date), meaning the date range selects the underlying transfers, not the approval events.

Created March 2019 by Avraham Lahmi.

---

## 2. Business Logic

### 2.1 Date Filter on Redeem.RequestDate

**What**: The date range filters the underlying redeem records, not the approval events themselves.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `Billing.Redeem.RequestDate`

**Rules**:
- `RE.RequestDate BETWEEN @StartDate AND @EndDate` - selects transfers requested in the window.
- INNER JOIN Billing.Redeem ensures only approval records for transfers in the window are returned.
- This means an approval recorded outside the date window but for a transfer within it IS returned.

### 2.2 STRING_SPLIT for Instrument Filter

**What**: @Instruments comma-separated string is parsed via STRING_SPLIT for IN() filter.

**Columns/Parameters Involved**: `@Instruments`, `Billing.Redeem.InstrumentID`

**Rules**:
- `@Instruments IS NULL OR RE.InstrumentID IN (SELECT * FROM STRING_SPLIT(@Instruments, ','))`.
- NULL=all instruments.

### 2.3 @ShowOnlyApproved Filter

**What**: Optionally filters to approved decisions only.

**Columns/Parameters Involved**: `@ShowOnlyApproved`, `BackOffice.RedeemApproval.Approved`

**Rules**:
- `@ShowOnlyApproved IS NULL OR @ShowOnlyApproved = 0 OR BRA.Approved = 1`.
- BRA.Approved is a BIT (1=approved, 0=rejected/pending).
- When @ShowOnlyApproved=1: only rows where manager explicitly approved.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of redeem request date window. Filters Billing.Redeem.RequestDate >= @StartDate. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of redeem request date window. Filters RequestDate <= @EndDate. |
| 3 | @Instruments | VARCHAR(MAX) | YES | NULL | CODE-BACKED | Comma-separated InstrumentIDs. NULL=all crypto instruments. |
| 4 | @ShowOnlyApproved | BIT | YES | NULL | CODE-BACKED | When 1, returns only approval decisions where Approved=1. NULL or 0=all decisions. |
| 5 | Transfer ID | INT | NO | - | CODE-BACKED | BackOffice.RedeemApproval.RedeemID - identifies which crypto transfer this approval belongs to. FK to Billing.Redeem.RedeemID. |
| 6 | User Group | NVARCHAR | YES | - | CODE-BACKED | Name of the user group that processed this approval (Dictionary.UserGroup.Name via BRA.UserGroupID). NULL if no user group assigned. |
| 7 | Manager | NVARCHAR | YES | - | CODE-BACKED | Full name of the manager who made the decision (BackOffice.Manager.FirstName + ' ' + LastName). NULL if no manager assigned (automated decision). |
| 8 | Approved | BIT | NO | - | CODE-BACKED | Whether this decision was an approval (1) or rejection (0). From BackOffice.RedeemApproval.Approved. |
| 9 | Reason | NVARCHAR | YES | - | CODE-BACKED | Approval/rejection reason name (Dictionary.RedeemApprovalReason.Name via BRA.RedeemApprovalReasonID). NULL if no reason recorded. |
| 10 | Comment | NVARCHAR | YES | - | CODE-BACKED | Free-text comment from the manager about this approval decision. From BackOffice.RedeemApproval.Comment. |
| 11 | Occurred | DATETIME | NO | - | CODE-BACKED | UTC timestamp when this approval decision was recorded. From BackOffice.RedeemApproval.Occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedeemID | BackOffice.RedeemApproval | Primary source | All approval records for transfers in the date window. |
| RedeemID | Billing.Redeem | INNER JOIN | Filters approvals to transfers with RequestDate in window. |
| ManagerID | BackOffice.Manager | LEFT JOIN | Manager full name for the approval decision. |
| UserGroupID | Dictionary.UserGroup | LEFT JOIN | User group name. |
| RedeemApprovalReasonID | Dictionary.RedeemApprovalReason | LEFT JOIN | Approval/rejection reason. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BackOffice crypto transfer approval management screen. No SQL procedure callers found in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCryptoTransactionsApprovals (procedure)
├── BackOffice.RedeemApproval (table)
├── Billing.Redeem (table) [cross-schema]
├── BackOffice.Manager (table)
├── Dictionary.UserGroup (table) [cross-schema]
└── Dictionary.RedeemApprovalReason (table) [cross-schema]
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by BackOffice crypto approval screen. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

No SET NOCOUNT ON. NOLOCK on all tables. STRING_SPLIT for @Instruments. No ORDER BY. Encapsulated in BEGIN/END.

---

## 8. Sample Queries

### 8.1 Get all approval decisions for crypto transfers this week
```sql
EXEC BackOffice.GetCryptoTransactionsApprovals
    @StartDate = DATEADD(DAY,-7,GETUTCDATE()),
    @EndDate = GETUTCDATE();
```

### 8.2 Get only approved decisions
```sql
EXEC BackOffice.GetCryptoTransactionsApprovals
    @StartDate = '2026-03-01',
    @EndDate = '2026-03-17',
    @ShowOnlyApproved = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCryptoTransactionsApprovals | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCryptoTransactionsApprovals.sql*
