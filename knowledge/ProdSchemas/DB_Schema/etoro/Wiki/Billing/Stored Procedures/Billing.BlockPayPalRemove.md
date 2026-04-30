# Billing.BlockPayPalRemove

> Removes a PayPal email address from BackOffice.BlockedPayPal, re-enabling that PayPal account for deposits and payments; raises error 60021 if the address was not on the blocklist.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success), RETURN 60021 (not found), RETURN @LocalError (SQL error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BlockPayPalRemove` reverses a PayPal account block by deleting the matching row from `BackOffice.BlockedPayPal`. Once removed, any customer using that PayPal email can again make deposits and payments. This is the counterpart to `Billing.BlockPayPalAdd`.

The procedure enforces the same "must exist to remove" pattern as `Billing.BlockCardRemove` and `Billing.BlockNetellerRemove`: if no row matches, error 60021 is raised to prevent silent no-ops.

---

## 2. Business Logic

### 2.1 Delete-or-Error Pattern

**What**: Deletes the PayPal email from the blocklist, errors if not found.

**Rules**:
- `DELETE FROM BackOffice.BlockedPayPal WHERE PayPalEmailAccount = @PayPalEmailAccount`
- Captures `@@ERROR` and `@@ROWCOUNT` immediately.
- If `@RowCount = 0`: RAISERROR(60021, 16, 1, 'Billing.BlockPayPalRemove', @PayPalEmailAccount) + RETURN 60021.
- If `@RowCount >= 1`: RETURN @LocalError (0 on success).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PayPalEmailAccount | VARCHAR(50) | NO | - | CODE-BACKED | PayPal email address to unblock. Must exactly match a PayPalEmailAccount value in BackOffice.BlockedPayPal (case-sensitive comparison depends on database collation). Max 50 characters. The email is included in the error message if not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PayPalEmailAccount | BackOffice.BlockedPayPal | DELETER | Removes the matching blocked PayPal email entry |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BlockPayPalRemove (procedure)
+-- BackOffice.BlockedPayPal (table)   [DELETE - removes PayPal email from blocklist]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BlockedPayPal | Table (cross-schema) | DELETE target |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **Error 60021 with email in message**: The PayPal email address itself is passed as the second argument to RAISERROR - it will appear in the error message for diagnostics.
- **Consistent error handling**: Same error code (60021) as BlockCardRemove and BlockNetellerRemove for the "not found" case.
- **No TRY-CATCH**: Errors propagate raw.

---

## 8. Sample Queries

### 8.1 Remove a PayPal block
```sql
DECLARE @Result INT;
EXEC @Result = Billing.BlockPayPalRemove @PayPalEmailAccount = 'fraudster@example.com';
SELECT @Result AS ReturnCode,
    CASE @Result
        WHEN 0     THEN 'Success - PayPal account unblocked'
        WHEN 60021 THEN 'Error - email not found in blocklist'
        ELSE 'SQL error'
    END AS ResultDescription;
```

### 8.2 Verify removal
```sql
SELECT PayPalEmailAccount, BlockDate
FROM BackOffice.BlockedPayPal WITH (NOLOCK)
WHERE PayPalEmailAccount = 'fraudster@example.com';
-- Should return 0 rows if removal succeeded
```

### 8.3 View all blocked PayPal accounts
```sql
SELECT TOP 50 PayPalEmailAccount, BlockDate
FROM BackOffice.BlockedPayPal WITH (NOLOCK)
ORDER BY BlockDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.BlockPayPalRemove | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BlockPayPalRemove.sql*
