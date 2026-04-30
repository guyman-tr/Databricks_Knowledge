# Billing.SetRejectsAsInactiveForWithdraw

> Deactivates all existing rejection records for a given withdrawal, clearing the way for a fresh rejection record to be inserted as the new active rejection.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID - targets all Billing.WithdrawRejects rows for a withdrawal |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.SetRejectsAsInactiveForWithdraw` is the cleanup step in the withdrawal re-rejection flow. It bulk-sets `IsActive = 0` on every existing `Billing.WithdrawRejects` row for the given `@WithdrawID`, ensuring that when a new rejection record is subsequently inserted (by `Billing.WithdrawReject`), it becomes the sole active rejection. This preserves the full rejection history while maintaining the invariant that only one rejection record per withdrawal is active at a time.

This procedure exists because a withdrawal can be rejected, re-submitted, and rejected again an arbitrary number of times. Without this step, the table would accumulate multiple `IsActive=1` rows per withdrawal, breaking the operations queue logic that relies on `IsActive=1` to identify current rejections.

Normally called exclusively by `Billing.WithdrawReject` immediately before inserting a new rejection row. The two operations together form the atomic rejection pattern: deactivate old records, insert new active record, update `Billing.Withdraw.CashoutStatusID=7`.

---

## 2. Business Logic

### 2.1 IsActive Rotation for Re-Rejection

**What**: When a withdrawal is rejected a second or subsequent time, prior rejection records must be marked inactive before the new record is created.

**Columns/Parameters Involved**: `@WithdrawID`, `Billing.WithdrawRejects.IsActive`, `Billing.WithdrawRejects.WithdrawID`

**Rules**:
- All existing rows in `Billing.WithdrawRejects` where `WithdrawID = @WithdrawID` are updated to `IsActive = 0`, regardless of their prior state.
- This procedure does not validate whether the withdrawal exists or is in a rejectable state - that validation is the responsibility of the caller (`Billing.WithdrawReject`).
- No rows are inserted or deleted; the full rejection history is preserved.
- The subsequent INSERT by `Billing.WithdrawReject` creates the new `IsActive=1` row.

**Diagram**:
```
Before call:
  WithdrawRejects: RejectID=1, WithdrawID=42, IsActive=1 (old rejection)

Call: EXEC Billing.SetRejectsAsInactiveForWithdraw @WithdrawID=42

After call:
  WithdrawRejects: RejectID=1, WithdrawID=42, IsActive=0 (archived)

Caller then inserts:
  WithdrawRejects: RejectID=2, WithdrawID=42, IsActive=1 (new active rejection)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | The ID of the withdrawal whose rejection records should be deactivated. Maps to `Billing.WithdrawRejects.WithdrawID` and identifies the parent withdrawal in `Billing.Withdraw`. All `WithdrawRejects` rows with this ID are updated to `IsActive=0`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.WithdrawRejects | Direct UPDATE | Targets all rejection records for the specified withdrawal and sets IsActive=0 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawReject | @WithdrawID | EXEC caller | Calls this procedure before inserting a new active rejection row, implementing the re-rejection deactivation pattern |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SetRejectsAsInactiveForWithdraw (procedure)
└── Billing.WithdrawRejects (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawRejects | Table | UPDATE - sets IsActive=0 for all rows matching @WithdrawID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawReject | Procedure | Calls this as the first step in the re-rejection sequence to archive prior rejection records before inserting a new one |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check active rejections before and after calling this procedure
```sql
-- Before: see active rejections for a withdrawal
SELECT RejectID, WithdrawID, IsActive, RejectDate, Comment
FROM Billing.WithdrawRejects WITH (NOLOCK)
WHERE WithdrawID = 12345
ORDER BY RejectDate DESC;

-- After EXEC Billing.SetRejectsAsInactiveForWithdraw @WithdrawID=12345
-- all rows will show IsActive=0
```

### 8.2 Find withdrawals with multiple historical rejections
```sql
SELECT WithdrawID,
       COUNT(*) AS TotalRejections,
       SUM(CASE WHEN IsActive = 1 THEN 1 ELSE 0 END) AS ActiveRejections
FROM Billing.WithdrawRejects WITH (NOLOCK)
GROUP BY WithdrawID
HAVING COUNT(*) > 1
ORDER BY TotalRejections DESC;
```

### 8.3 Audit rejection history for a customer's withdrawals
```sql
SELECT w.WithdrawID,
       w.CashoutStatusID,
       wr.RejectID,
       wr.IsActive,
       wr.RejectDate,
       wr.Comment
FROM Billing.WithdrawRejects wr WITH (NOLOCK)
INNER JOIN Billing.Withdraw w WITH (NOLOCK) ON w.WithdrawID = wr.WithdrawID
WHERE w.CustomerID = 987654
ORDER BY wr.WithdrawID, wr.RejectDate;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Cashier Service Redesign](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1803878401/Cashier+Service+Redesign) | Confluence | Page found in search but content not accessible (2021-03-21); no facts extracted |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Billing.WithdrawReject via dep doc) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.SetRejectsAsInactiveForWithdraw | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.SetRejectsAsInactiveForWithdraw.sql*
