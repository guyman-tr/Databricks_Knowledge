# Billing.UpdatePostTransferStatus

> Advances a post-transfer action's lifecycle status, transitioning it between application-managed states (e.g., from in-progress to completed).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Void (no return value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.UpdatePostTransferStatus advances the lifecycle state of a post-transfer action. Unlike Billing.UpdateTransferStatus (which has a terminal-state guard for Received=10), this procedure has no status validation - it unconditionally sets the new PostTransferStatusID.

The procedure is called by the MoneyTransfer application service when a post-transfer action completes, fails, or changes state. Observed values in live data are 1 (in-progress) and 2 (completed), though the application may define additional values not present in the empty Dictionary.PostTransferStatus table.

This is the final step in the post-transfer action lifecycle: CreatePostTransfer creates the action with initial status, and UpdatePostTransferStatus advances it to completion (or other states).

---

## 2. Business Logic

### 2.1 Unconditional Status Update

**What**: Sets PostTransferStatusID without validation - no terminal-state guard (unlike UpdateTransferStatus).

**Columns/Parameters Involved**: `PostTransferStatusID`, `ReferenceID`

**Rules**:
- Single-column UPDATE with no checks on current state
- Any integer value is accepted as @StatusID (no FK constraint to Dictionary.PostTransferStatus)
- Known values: 1 (in-progress), 2 (completed) - application-managed
- No modification timestamp tracking (PostTransferActions has no ModificationDate column or trigger)
- Locates action by ReferenceID via IX_Billing_PostTransferActions index

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StatusID | INT | NO | - | VERIFIED | New post-transfer status value. Known values: 1=in-progress, 2=completed (application-managed, Dictionary.PostTransferStatus is empty). See [Post Transfer Status](../../_glossary.md#post-transfer-status). |
| 2 | @RefID | UNIQUEIDENTIFIER | NO | - | VERIFIED | Business reference GUID. Maps to Billing.PostTransferActions.ReferenceID (indexed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Billing.PostTransferActions | Write (UPDATE) | Sets PostTransferStatusID WHERE ReferenceID = @RefID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdatePostTransferStatus (procedure)
  └── Billing.PostTransferActions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.PostTransferActions | Table | UPDATE target - sets PostTransferStatusID WHERE ReferenceID = @RefID |

### 6.2 Objects That Depend On This

No dependents found in the database.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Mark action as completed
```sql
EXEC Billing.UpdatePostTransferStatus @StatusID = 2, @RefID = '7418D7FB-CBFD-4288-A1CD-7B0C033E910D'
```

### 8.2 Check action status
```sql
SELECT PostTransferActionID, TransferID, PostTransferStatusID, FundingTypeID, CreateDate
FROM Billing.PostTransferActions WITH (NOLOCK)
WHERE ReferenceID = '7418D7FB-CBFD-4288-A1CD-7B0C033E910D'
```

### 8.3 Find actions still in progress
```sql
SELECT TOP 10 PostTransferActionID, TransferID, PostTransferStatusID, CreateDate
FROM Billing.PostTransferActions WITH (NOLOCK)
WHERE PostTransferStatusID = 1
ORDER BY PostTransferActionID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.UpdatePostTransferStatus | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.UpdatePostTransferStatus.sql*
