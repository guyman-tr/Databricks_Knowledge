# Billing.BlockNetellerRemove

> Removes a Neteller account ID from BackOffice.BlockedNeteller, re-enabling that account for use in deposits and payments; raises error 60021 if the account was not on the blocklist.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success), RETURN 60021 (not found), RETURN @LocalError (SQL error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BlockNetellerRemove` reverses a Neteller account block by deleting the row from `BackOffice.BlockedNeteller`. Once removed, any customer using that Neteller account can again make deposits and payments through eToro. This is the counterpart to `Billing.BlockNetellerAdd`.

The procedure enforces a "must exist to remove" guard: if no row matches the @AccountID, error 60021 ("item not found") is raised and returned. This ensures callers can detect whether the operation had any effect versus silently completing on a non-existent block.

---

## 2. Business Logic

### 2.1 Delete-or-Error Pattern

**What**: Deletes the Neteller account from the blocklist, errors if not found.

**Rules**:
- `DELETE FROM BackOffice.BlockedNeteller WHERE AccountID = @AccountID`
- Captures `@@ERROR` and `@@ROWCOUNT` immediately.
- If `@RowCount = 0`: RAISERROR(60021, 16, 1, 'Billing.BlockNetellerRemove', @ErrMsg) + RETURN 60021. @ErrMsg is the AccountID cast to VARCHAR(12).
- If `@RowCount >= 1`: RETURN @LocalError (0 on success).
- Consistent with BlockCardRemove and BlockPayPalRemove error behavior.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountID | NUMERIC(12,0) | NO | - | CODE-BACKED | Neteller account ID to unblock. Must exactly match a row in BackOffice.BlockedNeteller.AccountID. If no match, error 60021 is raised. The account ID is included in the error message for diagnostics. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AccountID | BackOffice.BlockedNeteller | DELETER | Removes the matching blocked Neteller account entry |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BlockNetellerRemove (procedure)
+-- BackOffice.BlockedNeteller (table)   [DELETE - removes Neteller account from blocklist]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BlockedNeteller | Table (cross-schema) | DELETE target |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **Error 60021 with account ID in message**: Unlike BlockCardRemove (which passes @CardHash), this procedure casts @AccountID to VARCHAR(12) for the error message parameter.
- **No TRY-CATCH**: Errors propagate raw.
- **Symmetric pair**: `Billing.BlockNetellerAdd` is the counterpart.

---

## 8. Sample Queries

### 8.1 Remove a Neteller block
```sql
DECLARE @Result INT;
EXEC @Result = Billing.BlockNetellerRemove @AccountID = 123456789012;
SELECT @Result AS ReturnCode,
    CASE @Result
        WHEN 0     THEN 'Success - Neteller account unblocked'
        WHEN 60021 THEN 'Error - account not found in blocklist'
        ELSE 'SQL error'
    END AS ResultDescription;
```

### 8.2 Verify removal
```sql
SELECT AccountID, BlockDate
FROM BackOffice.BlockedNeteller WITH (NOLOCK)
WHERE AccountID = 123456789012;
-- Should return 0 rows if removal succeeded
```

### 8.3 View all blocked Neteller accounts
```sql
SELECT TOP 50 AccountID, BlockDate
FROM BackOffice.BlockedNeteller WITH (NOLOCK)
ORDER BY BlockDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.BlockNetellerRemove | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BlockNetellerRemove.sql*
