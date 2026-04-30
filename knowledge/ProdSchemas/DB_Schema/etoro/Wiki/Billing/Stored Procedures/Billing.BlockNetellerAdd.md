# Billing.BlockNetellerAdd

> Inserts a Neteller account ID into BackOffice.BlockedNeteller to prevent that account from being used for future deposits or payments across all customers.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN @@ERROR (0=success, non-zero=SQL error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BlockNetellerAdd` adds a Neteller account to the global Neteller blocklist. When a Neteller account ID is in `BackOffice.BlockedNeteller`, any deposit or payment attempt from that account across any customer is refused. This is used when a Neteller account is associated with fraudulent activity, chargebacks, or compliance violations.

The procedure is a minimal INSERT wrapper - one call, one row, no validation. It is the Neteller equivalent of `Billing.BlockCardAdd` (for credit cards) and `Billing.BlockPayPalAdd` (for PayPal). See `Billing.BlockNetellerRemove` to reverse the block and `Billing.CheckInBlockedNetellers` (if it exists) for lookups.

---

## 2. Business Logic

### 2.1 Simple Insert

**What**: Inserts one row into BackOffice.BlockedNeteller.

**Rules**:
- `INSERT INTO BackOffice.BlockedNeteller (AccountID, BlockDate) VALUES (@AccountID, GETDATE())`
- BlockDate uses `GETDATE()` (local server time, not GETUTCDATE()).
- No duplicate check: if @AccountID already exists and there is a UNIQUE constraint, the INSERT will fail and @@ERROR will be non-zero.
- No TRY-CATCH: errors propagate via RETURN @@ERROR.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountID | NUMERIC(12,0) | NO | - | CODE-BACKED | Neteller account identifier. A 12-digit numeric account number (Neteller uses numeric account IDs). Inserted into BackOffice.BlockedNeteller.AccountID. This is the Neteller-assigned account number, not the eToro CID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AccountID | BackOffice.BlockedNeteller | WRITER (INSERT) | Adds one Neteller account to the global blocklist |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BlockNetellerAdd (procedure)
+-- BackOffice.BlockedNeteller (table)   [INSERT - adds Neteller account to blocklist]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BlockedNeteller | Table (cross-schema) | INSERT target |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **GETDATE() not GETUTCDATE()**: BlockDate is in local server time - potential inconsistency with other tables using UTC.
- **NUMERIC(12,0)**: Neteller account IDs are up to 12 digits. This type exactly matches the Neteller account ID format.
- **Symmetric pair**: `Billing.BlockNetellerRemove` is the counterpart for removing blocks.

---

## 8. Sample Queries

### 8.1 Block a Neteller account
```sql
DECLARE @Result INT;
EXEC @Result = Billing.BlockNetellerAdd @AccountID = 123456789012;
SELECT @Result AS ErrorCode;  -- 0 = success
```

### 8.2 Check if a Neteller account is already blocked
```sql
SELECT AccountID, BlockDate
FROM BackOffice.BlockedNeteller WITH (NOLOCK)
WHERE AccountID = 123456789012;
```

### 8.3 View recently blocked Neteller accounts
```sql
SELECT TOP 20 AccountID, BlockDate
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
*Object: Billing.BlockNetellerAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BlockNetellerAdd.sql*
