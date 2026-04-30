# Billing.WithdrawalService_GetClientWitdrawComments

> Returns the active predefined comment options available for customers to attach to a withdrawal request, ordered by display priority.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; returns all active rows from Dictionary.ClientWithdrawComment |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supplies the withdrawal comment dropdown data to the front-end UI. When a customer opens the withdrawal form, the application calls this procedure to obtain the list of predefined comment options the customer can select (e.g., "Update Intermediary Bank Details", "Report Non Valid Mean Of Payment"). The procedure returns only active comments (IsActive=1), ensuring retired or disabled options never appear in the UI without requiring code changes.

The procedure exists to centralise comment-list retrieval in one place: the UI does not hard-code the comment options but instead fetches them from the database, allowing operations teams to activate or deactivate options by updating `Dictionary.ClientWithdrawComment.IsActive` without a deployment.

The returned comment IDs are stored with the withdrawal record in `Billing.Withdraw.ClientWithdrawCommentID` when `Billing.WithdrawalService_WithdrawRequestAdd` processes the submission, linking the customer's comment choice to the withdrawal throughout its lifecycle.

---

## 2. Business Logic

### 2.1 Active-Only Filtering

**What**: Only comments visible to customers are returned - retired options are excluded.

**Columns/Parameters Involved**: `IsActive` (filter), `DisplayOrder` (sort)

**Rules**:
- `WHERE IsActive = 1` ensures only currently enabled options appear in the UI
- `ORDER BY DisplayOrder` ensures consistent UI ordering: 1=empty/no-comment (default), 2=update bank details, 3=invalid payment, 4=other
- All 4 current comments are active; deactivation does not delete rows, preserving referential integrity for historical withdrawals

**Diagram**:
```
Dictionary.ClientWithdrawComment (4 rows total)
  IsActive=1 (4 active) --> returned to UI dropdown
  IsActive=0 (0 retired) --> excluded

Return order: ID=0(empty), ID=2(bank), ID=1(invalid), ID=3(other)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClientWithdrawCommentID | int | NO | - | VERIFIED | Output column. The comment option identifier returned to the caller. Values: 0=no comment (default), 1=report invalid payment, 2=update bank details, 3=other. Stored in Billing.Withdraw.ClientWithdrawCommentID when the customer submits the withdrawal. (Source: Dictionary.ClientWithdrawComment) |
| 2 | DisplayOrder | int | NO | - | VERIFIED | Output column. Sort order controlling the sequence of options in the withdrawal UI. Lower numbers appear first: 1=empty/default, 2=bank details, 3=invalid payment, 4=other. (Source: Dictionary.ClientWithdrawComment) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (query) | Dictionary.ClientWithdrawComment | Lookup | Reads all active comment options ordered by display priority |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawalService_GetClientWitdrawComments (procedure)
└── Dictionary.ClientWithdrawComment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ClientWithdrawComment | Table | SELECT source - returns ClientWithdrawCommentID and DisplayOrder filtered to active rows ordered by display priority |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repo (no callers discovered in Phase 8 search).

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure to get withdrawal comment options

```sql
EXEC Billing.WithdrawalService_GetClientWitdrawComments;
```

### 8.2 Verify what the procedure returns (equivalent direct query)

```sql
SELECT  ClientWithdrawCommentID,
        DisplayOrder
FROM    Dictionary.ClientWithdrawComment WITH (NOLOCK)
WHERE   IsActive = 1
ORDER BY DisplayOrder;
```

### 8.3 Join returned comment IDs to their text labels for display

```sql
SELECT  CWC.ClientWithdrawCommentID,
        CWC.Comment,
        CWC.DisplayOrder
FROM    Dictionary.ClientWithdrawComment CWC WITH (NOLOCK)
WHERE   CWC.IsActive = 1
ORDER BY CWC.DisplayOrder;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawalService_GetClientWitdrawComments | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawalService_GetClientWitdrawComments.sql*
