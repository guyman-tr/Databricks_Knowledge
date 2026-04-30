# Billing.BlockCardAdd

> Inserts a card hash into BackOffice.BlockedCard to permanently block a specific payment card from being used across all customers, using a hash-based identifier to avoid storing raw card numbers.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN @@ERROR (0=success, non-zero=error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BlockCardAdd` adds a specific card to the global card blocklist. Unlike `Billing.BadBinAdd` (which blocks ranges of card BIN prefixes affecting all cards from an issuer product) or `Billing.BlockAllPaymentMethodsForCID`/`Billing.BlockAllRelatedMeansOfPayment` (which block a customer's instruments), this procedure targets a specific individual card identified by its hash.

Card blocking by hash is used when a specific physical card is known to be fraudulent, stolen, or subject to a chargeback - regardless of which customer holds it. The card hash is a one-way hash of the card number (PCI DSS compliance - raw card numbers are never stored). Any future deposit attempt using a card that matches this hash will be blocked.

The procedure is a minimal INSERT wrapper - one call, one row, no validation.

---

## 2. Business Logic

### 2.1 Simple Hash Insert

**What**: Inserts one row into BackOffice.BlockedCard.

**Parameters/Columns Involved**: `@CardHash`, `BackOffice.BlockedCard`

**Rules**:
- `INSERT INTO BackOffice.BlockedCard (CardHash, BlockDate) VALUES (@CardHash, GETDATE())`.
- BlockDate uses `GETDATE()` (local server time, not GETUTCDATE()).
- No duplicate check: duplicate @CardHash inserts will fail if the table has a UNIQUE constraint on CardHash, or succeed with duplicate rows if it does not.
- No manager or description metadata recorded.
- No TRY-CATCH: errors propagate to the caller.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CardHash | VARCHAR(50) | NO | - | VERIFIED | One-way hash of the card number (PCI DSS compliant - no raw card data). This hash is compared against incoming deposit card hashes at authorization time. Maximum 50 characters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CardHash | BackOffice.BlockedCard | WRITER (INSERT) | Inserts one blocked card entry per call. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from risk management and fraud operations tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BlockCardAdd (procedure)
+- BackOffice.BlockedCard (table)   [INSERT - card blocklist entry]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BlockedCard | Table (cross-schema) | INSERT target - adds card hash to the global blocklist |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from fraud prevention tools.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **RETURN @@ERROR**: Old-style error check (no TRY-CATCH). RETURN @@ERROR returns 0 on success, non-zero on SQL error. Callers should check the return value.
- **GETDATE() not GETUTCDATE()**: BlockDate records local server time rather than UTC. This may cause timestamp inconsistencies with other Billing tables that use GETUTCDATE().
- **No removal procedure visible in this batch**: BlockCardAdd adds to the blocklist but no corresponding BlockCardRemove was found in the current batch. Check for that procedure elsewhere in the schema.
- **Cross-schema write**: Writes to BackOffice.BlockedCard (cross-schema dependency). This is the only Billing SP in this batch with a BackOffice write target.

---

## 8. Sample Queries

### 8.1 Block a specific card
```sql
DECLARE @Result INT;
EXEC @Result = Billing.BlockCardAdd
    @CardHash = 'a1b2c3d4e5f6789012345678901234567890abcd12';
SELECT @Result AS ErrorCode;  -- 0 = success
```

### 8.2 Check if a card hash is already blocked
```sql
SELECT  CardHash,
        BlockDate
FROM    BackOffice.BlockedCard WITH (NOLOCK)
WHERE   CardHash = 'a1b2c3d4e5f6789012345678901234567890abcd12';
```

### 8.3 Review all recently blocked cards
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
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.BlockCardAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BlockCardAdd.sql*
