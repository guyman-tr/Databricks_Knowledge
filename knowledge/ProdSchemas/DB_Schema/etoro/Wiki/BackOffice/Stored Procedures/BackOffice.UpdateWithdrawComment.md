# BackOffice.UpdateWithdrawComment

> Sets the operations Comment field on a Billing.Withdraw record by WithdrawID, with legacy error handling via RAISERROR(60000).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID - PK of Billing.Withdraw |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpdateWithdrawComment` is a simple maintenance SP that allows back-office agents to annotate a withdrawal record with an operations comment. The `Comment` field on `Billing.Withdraw` holds additional processing notes (nvarchar(255)), distinct from `Remark` (system notes) and `RequestorComments` (customer-submitted notes). This SP provides the write path for back-office staff to add or update agent commentary on a specific withdrawal.

Introduced in June 2014, the SP uses old-style `IF @@ERROR` error handling rather than TRY/CATCH. The ROLLBACK statement applies only if the SP is called within an outer transaction; the SP itself does not issue `BEGIN TRANSACTION`.

---

## 2. Business Logic

### 2.1 Comment Update

**What**: Sets `Billing.Withdraw.Comment` to @Comment for the specified withdrawal.

**Columns/Parameters Involved**: `@WithdrawID`, `@Comment`, `Billing.Withdraw.Comment`

**Rules**:
- Direct SET with no ISNULL guard - passing NULL clears the existing comment.
- Target is `Billing.Withdraw WHERE WithdrawID = @WithdrawID` (PK lookup).
- No rows updated if @WithdrawID does not exist (no error raised for miss).
- On @@ERROR: ROLLBACK TRANSACTION + RAISERROR(60000) - applies if within outer transaction.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | int | NO | - | CODE-BACKED | Primary key of the withdrawal record (maps to Billing.Withdraw.WithdrawID, IDENTITY(1,1)). Must exist; no error raised if not found. |
| 2 | @Comment | nvarchar(255) | NO | - | CODE-BACKED | Operations comment to set on the withdrawal (maps to Billing.Withdraw.Comment, nvarchar(255)). NULL clears existing comment. Max 255 unicode characters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | UPDATE target | Sets Comment WHERE WithdrawID=@WithdrawID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No direct callers found in BackOffice SPs. | - | - | Called from back-office withdrawal management workflows. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateWithdrawComment (procedure)
+-- Billing.Withdraw (table) [UPDATE target: Comment field]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | UPDATE target - sets Comment by WithdrawID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from back-office withdrawal management. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Legacy `IF @@ERROR` error handling (2014 style - predates TRY/CATCH adoption in this schema).
- ROLLBACK TRANSACTION applies only when called within an outer transaction.
- RAISERROR(60000,16,1,...) - standard BackOffice error code for SP failures.
- No TRY/CATCH block - errors propagate to caller via RAISERROR.

---

## 8. Sample Queries

### 8.1 Add a comment to a withdrawal

```sql
EXEC BackOffice.UpdateWithdrawComment
    @WithdrawID = 1234567,
    @Comment    = N'Flagged for manual review - customer requested expedited processing';
```

### 8.2 Clear a comment

```sql
EXEC BackOffice.UpdateWithdrawComment
    @WithdrawID = 1234567,
    @Comment    = NULL;  -- clears the existing comment
```

### 8.3 View current comment and related notes for a withdrawal

```sql
SELECT WithdrawID, Comment, Remark, RequestorComments, CashoutStatusID
FROM Billing.Withdraw WITH (NOLOCK)
WHERE WithdrawID = 1234567;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateWithdrawComment | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateWithdrawComment.sql*
