# Billing.BlockCardRemove

> Removes a specific card hash from the global card blocklist (BackOffice.BlockedCard), re-enabling card-based deposits for any customer holding that card.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success), RETURN 60021 (card not found), RETURN @LocalError (SQL error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BlockCardRemove` is the counterpart to `Billing.BlockCardAdd` - it removes a card from the global blocklist by its hash. When a card hash is deleted from `BackOffice.BlockedCard`, any customer holding that card will again be permitted to use it for deposits. This procedure is used when a fraudulent card block is reversed (e.g., a false positive, a chargeback resolved in the customer's favor, or a manually added block that needs to be undone).

The card is identified by its one-way hash (PCI DSS compliant - no raw card numbers are ever stored). The hash is compared at deposit authorization time; removing it unblocks all future authorization attempts using that card across all customers.

The procedure enforces a "card must exist to remove" guard: if no row matches the @CardHash, it raises error 60021 and returns that code. This prevents silent no-ops from incorrect hash values. There is no TRY-CATCH - SQL errors propagate to the caller via @LocalError.

---

## 2. Business Logic

### 2.1 Delete-or-Error Pattern

**What**: Deletes the matching row from BackOffice.BlockedCard and errors if the card was not found.

**Parameters Involved**: `@CardHash`, `@@ROWCOUNT`

**Rules**:
- `DELETE FROM BackOffice.BlockedCard WHERE CardHash = @CardHash`
- Captures `@@ERROR` and `@@ROWCOUNT` immediately after DELETE.
- If `@RowCount = 0` (no row matched): RAISERROR(60021, 16, 1, 'Billing.BlockCardRemove', @CardHash) and RETURN 60021.
- If `@RowCount >= 1` (row deleted): RETURN @LocalError (0 on success).
- Error 60021 is a custom application error meaning "requested item not found".

```
Call: EXEC Billing.BlockCardRemove @CardHash = 'abc...'
  |-> DELETE BackOffice.BlockedCard WHERE CardHash = @CardHash
  |     if 0 rows deleted: RAISERROR(60021) + RETURN 60021
  |     if 1 row deleted:  RETURN 0
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CardHash | VARCHAR(50) | NO | - | VERIFIED | One-way hash of the card number (PCI DSS compliant). Must exactly match a CardHash value in BackOffice.BlockedCard. If no match is found, error 60021 is raised. Maximum 50 characters. Same hashing algorithm as used by Billing.BlockCardAdd and deposit authorization. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CardHash | BackOffice.BlockedCard | DELETER | Removes one blocked card entry matching the hash. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from risk/fraud management tools or back-office operations.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BlockCardRemove (procedure)
+-- BackOffice.BlockedCard (table)   [DELETE - removes card hash from global blocklist]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BlockedCard | Table (cross-schema) | DELETE target - removes the blocked card hash entry |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **No TRY-CATCH**: Errors other than the "not found" case propagate raw to the caller.
- **RAISERROR(60021)**: Consistent with other remove procedures (BlockNetellerRemove, BlockPayPalRemove) - custom error 60021 signals "requested item not found" across the Billing schema.
- **Symmetric pair**: `Billing.BlockCardAdd` adds; this removes. Together they maintain the card blocklist. See also `Billing.CheckInBlockedCards` for lookups.
- **No logging**: No history table entry is written on removal. The removal itself is the audit event at the database level.

---

## 8. Sample Queries

### 8.1 Remove a blocked card and check result
```sql
DECLARE @Result INT;
EXEC @Result = Billing.BlockCardRemove
    @CardHash = 'a1b2c3d4e5f6789012345678901234567890abcd12';
SELECT @Result AS ReturnCode,
    CASE @Result
        WHEN 0 THEN 'Success - card unblocked'
        WHEN 60021 THEN 'Error - card hash not found in blocklist'
        ELSE 'SQL error'
    END AS ResultDescription;
```

### 8.2 Verify card is no longer blocked after removal
```sql
SELECT  CardHash,
        BlockDate
FROM    BackOffice.BlockedCard WITH (NOLOCK)
WHERE   CardHash = 'a1b2c3d4e5f6789012345678901234567890abcd12';
-- Should return 0 rows if removal succeeded
```

### 8.3 View all currently blocked cards (to find hash to remove)
```sql
SELECT TOP 20
    CardHash,
    BlockDate
FROM    BackOffice.BlockedCard WITH (NOLOCK)
ORDER BY BlockDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos (N/A - no Billing repos) | Corrections: 0 applied*
*Object: Billing.BlockCardRemove | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BlockCardRemove.sql*
