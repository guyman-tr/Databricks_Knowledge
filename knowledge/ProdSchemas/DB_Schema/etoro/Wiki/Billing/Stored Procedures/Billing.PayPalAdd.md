# Billing.PayPalAdd

> Inserts a new PayPal email account into the legacy Billing.PayPal registry and returns the generated PayPalID - the atomic insert step for registering a new PayPal account in the pre-Funding era PayPal table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PayPalEmailAccount - the new email to register |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayPalAdd` is the insert procedure for `Billing.PayPal`, the legacy table that once served as eToro's PayPal account registry. When a new PayPal email address needed to be registered in the system, this procedure was called to insert the email and retrieve the generated surrogate key (`PayPalID`).

`Billing.PayPal` is a legacy table - it predates the current `Billing.Funding`/`Billing.CustomerToFunding` architecture for payment instrument management. The table has a low row count relative to active customer volumes, indicating it is no longer the primary registration path. This procedure and its table remain in the schema for backward compatibility with older integration flows that still reference PayPalID.

The procedure pattern is minimal: insert one row, capture the identity, return it via OUTPUT parameter and also as a RETURN value (with error handling via `@LocalError = @@ERROR; RETURN @LocalError`).

---

## 2. Business Logic

### 2.1 PayPal Account Registration

**What**: Inserts a new PayPal email into the legacy registry.

**Columns Involved**: `Billing.PayPal.PayPalEmailAccount`, `Billing.PayPal.PayPalID`

**Rules**:
- INSERT INTO Billing.PayPal (PayPalEmailAccount) VALUES (@PayPalEmailAccount).
- @PayPalID OUTPUT is set from SCOPE_IDENTITY() immediately after the insert.
- @LocalError = @@ERROR captures any insert error.
- RETURN @LocalError: returns 0 on success, non-zero on failure (old-style SQL Server error handling pattern).
- No duplicate-check: if the email already exists and there is a UNIQUE constraint, the INSERT will fail with a constraint error that the caller must handle.

**Diagram**:
```
@PayPalEmailAccount (e.g., 'user@example.com')
  |
  INSERT INTO Billing.PayPal (PayPalEmailAccount) VALUES (@PayPalEmailAccount)
  |
  @PayPalID = SCOPE_IDENTITY()
  @LocalError = @@ERROR
  |
  RETURN @LocalError
  (0=success, non-zero=error code)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PayPalEmailAccount | nvarchar(255) | NO | - | CODE-BACKED | The PayPal email address to register. Inserted into `Billing.PayPal.PayPalEmailAccount`. |
| 2 | @PayPalID | int | YES | OUTPUT | CODE-BACKED | OUTPUT: the identity value of the newly inserted row (`SCOPE_IDENTITY()`). The caller uses this as the foreign key PayPalID in related tables. |

**Return value**: int - 0 on success, @@ERROR value on failure (old-style error handling).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PayPalEmailAccount | [Billing.PayPal](../Tables/Billing.PayPal.md) | Write (INSERT) | Inserts a new row into the legacy PayPal email registry. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing application (legacy) | - | EXEC | Called during legacy PayPal account registration. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayPalAdd (procedure)
└── Billing.PayPal (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.PayPal](../Tables/Billing.PayPal.md) | Table | INSERT - registers the new PayPal email account. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Legacy PayPal billing application | Application | Registration of new PayPal accounts via legacy path. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The INSERT targets `Billing.PayPal` which has a PK on PayPalID (identity). If a UNIQUE constraint exists on PayPalEmailAccount, duplicate emails will raise a constraint violation.

### 7.2 Constraints

N/A for stored procedure.

**Error handling pattern**: Uses legacy `@LocalError = @@ERROR; RETURN @LocalError` pattern (pre-TRY/CATCH). The caller must check the RETURN value or @@ERROR to detect failures.

---

## 8. Sample Queries

### 8.1 Register a new PayPal account

```sql
DECLARE @PayPalID INT, @Result INT;
EXEC @Result = Billing.PayPalAdd
    @PayPalEmailAccount = 'user@example.com',
    @PayPalID = @PayPalID OUTPUT;
IF @Result = 0
    SELECT @PayPalID AS NewPayPalID;
ELSE
    PRINT 'Insert failed with error: ' + CAST(@Result AS varchar(10));
```

### 8.2 Check if an email is already in the legacy PayPal registry

```sql
SELECT PayPalID, PayPalEmailAccount
FROM Billing.PayPal WITH (NOLOCK)
WHERE PayPalEmailAccount = 'user@example.com';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayPalAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayPalAdd.sql*
