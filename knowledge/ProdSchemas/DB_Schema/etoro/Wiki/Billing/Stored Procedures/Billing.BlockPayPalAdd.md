# Billing.BlockPayPalAdd

> Inserts a PayPal email account address into BackOffice.BlockedPayPal to prevent that PayPal account from being used for deposits or payments across all customers.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN @@ERROR (0=success, non-zero=SQL error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BlockPayPalAdd` adds a PayPal email address to the global PayPal blocklist. When a PayPal email is in `BackOffice.BlockedPayPal`, any deposit or payment attempt from that PayPal account is blocked, regardless of which eToro customer uses it. This is used when a PayPal account is associated with fraud, chargebacks, or AML concerns.

The procedure is a minimal INSERT wrapper - one call, one row, no validation. It is the PayPal equivalent of `Billing.BlockCardAdd` (for credit cards) and `Billing.BlockNetellerAdd` (for Neteller). See `Billing.BlockPayPalRemove` to reverse the block and `Billing.CheckInBlockedPayPals` for lookups during payment authorization.

---

## 2. Business Logic

### 2.1 Simple Insert

**What**: Inserts one row into BackOffice.BlockedPayPal.

**Rules**:
- `INSERT INTO BackOffice.BlockedPayPal (PayPalEmailAccount, BlockDate) VALUES (@PayPalEmailAccount, GETDATE())`
- BlockDate uses `GETDATE()` (local server time).
- No duplicate check; duplicate email inserts fail if there is a UNIQUE constraint on PayPalEmailAccount.
- No TRY-CATCH: errors propagate via RETURN @@ERROR.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PayPalEmailAccount | VARCHAR(50) | NO | - | CODE-BACKED | The PayPal email address to block. Case-insensitive in practice (PayPal email matching). Maximum 50 characters - matches the column size in BackOffice.BlockedPayPal. This is the PayPal account's registered email, not the eToro customer email. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PayPalEmailAccount | BackOffice.BlockedPayPal | WRITER (INSERT) | Adds one PayPal email to the global blocklist |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BlockPayPalAdd (procedure)
+-- BackOffice.BlockedPayPal (table)   [INSERT - adds PayPal email to blocklist]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BlockedPayPal | Table (cross-schema) | INSERT target |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **Email-based vs hash-based**: Unlike card blocking (which uses a hash of the card number for PCI compliance), PayPal email blocking stores the email in plain text - PayPal email addresses are not considered sensitive PCI data.
- **VARCHAR(50)**: PayPal email addresses are limited to 50 characters in this system.
- **Symmetric pair**: `Billing.BlockPayPalRemove` removes; `Billing.CheckInBlockedPayPals` checks during authorization.

---

## 8. Sample Queries

### 8.1 Block a PayPal account
```sql
DECLARE @Result INT;
EXEC @Result = Billing.BlockPayPalAdd @PayPalEmailAccount = 'fraudster@example.com';
SELECT @Result AS ErrorCode;  -- 0 = success
```

### 8.2 Check if a PayPal email is blocked
```sql
SELECT PayPalEmailAccount, BlockDate
FROM BackOffice.BlockedPayPal WITH (NOLOCK)
WHERE PayPalEmailAccount = 'fraudster@example.com';
```

### 8.3 View recently blocked PayPal accounts
```sql
SELECT TOP 20 PayPalEmailAccount, BlockDate
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
*Object: Billing.BlockPayPalAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BlockPayPalAdd.sql*
