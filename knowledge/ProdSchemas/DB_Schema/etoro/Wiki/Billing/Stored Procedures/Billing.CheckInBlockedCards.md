# Billing.CheckInBlockedCards

> Checks whether a credit card (by its hash or identifier) exists in BackOffice.BlockedCard, setting @CheckResult OUTPUT to 1 (blocked) or 0 (allowed); used during payment authorization to enforce the card blocklist.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CheckResult OUTPUT: 0=not blocked, 1=card is on the blocklist; RETURN @@ERROR |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CheckInBlockedCards` is the authorization check for the card blocklist. During deposit processing, before a credit card payment is approved, this procedure checks whether the card is in `BackOffice.BlockedCard`. If @CheckResult=1, the deposit is rejected because this specific card has been flagged for fraud, chargebacks, or policy violations.

The card is identified by a hash (not the raw card number) for PCI compliance - `BackOffice.BlockedCard` stores a hash or masked representation of the card. This procedure is the counterpart to `Billing.BlockCardAdd` (which adds cards) and `Billing.BlockCardRemove` (which removes them).

---

## 2. Business Logic

### 2.1 Blocked Card Lookup

**What**: EXISTS check in BackOffice.BlockedCard for the given card identifier.

**Rules**:
- `SET @CheckResult = CASE WHEN EXISTS(SELECT 1 FROM BackOffice.BlockedCard WHERE CardHash = @CardHash) THEN 1 ELSE 0 END`
- @CheckResult=1: Card is blocked - reject the deposit.
- @CheckResult=0: Card is not on the blocklist - proceed.
- RETURN @@ERROR.

**@CheckResult Values**:
| Value | Meaning |
|-------|---------|
| 0 | Card is not blocked - allowed to proceed |
| 1 | Card is on the blocklist - reject the deposit |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CardHash | VARCHAR(100) | NO | - | CODE-BACKED | The card's hash or masked identifier used to look up the card in BackOffice.BlockedCard. PCI compliance requires that raw card numbers not be stored; the hash/mask is a consistent representation that allows blocklist matching without exposing the PAN. The exact hashing algorithm and column name depend on BackOffice.BlockedCard schema. |
| 2 | @CheckResult | INTEGER | YES | - | CODE-BACKED | OUTPUT parameter. Set to 1 if the card's hash matches any row in BackOffice.BlockedCard; 0 if not found (card is allowed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CardHash | BackOffice.BlockedCard | READER | EXISTS check for the card's hash/identifier in the blocklist |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files. Called from payment authorization application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CheckInBlockedCards (procedure)
+-- BackOffice.BlockedCard (table)   [READ - EXISTS check for blocked card hash]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BlockedCard | Table (cross-schema) | READ - checks if the card's hash/identifier is on the blocklist |

### 6.2 Objects That Depend On This

No dependents found in Billing schema SP files.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **PCI compliance via hashing**: BackOffice.BlockedCard stores a hash or masked card representation, not the raw PAN, consistent with PCI DSS requirements. The hash must be computed by the caller before passing to this procedure.
- **Part of the card blocklist family**: Three procedures manage the card blocklist - `Billing.BlockCardAdd` (add), `Billing.BlockCardRemove` (remove), `Billing.CheckInBlockedCards` (check). All operate on BackOffice.BlockedCard.
- **Consistent OUTPUT pattern**: Same @CheckResult OUTPUT pattern as `Billing.CheckInBadBins` and `Billing.CheckInBlockedPayPals` - all three authorization checks use this interface for uniform caller integration.
- **Cross-schema access**: The check table lives in BackOffice schema while this procedure is in Billing schema. This cross-schema access is consistent with BlockCardAdd/Remove.

---

## 8. Sample Queries

### 8.1 Check if a card is blocked
```sql
DECLARE @CheckResult INT;
EXEC Billing.CheckInBlockedCards
    @CardHash    = 'abc123def456...',  -- card hash computed by application
    @CheckResult = @CheckResult OUTPUT;
SELECT @CheckResult AS CheckResult,
    CASE @CheckResult
        WHEN 0 THEN 'Allowed - card not blocked'
        WHEN 1 THEN 'Blocked - card is on blocklist'
    END AS Description;
```

### 8.2 View recently blocked cards
```sql
SELECT TOP 20 CardHash, BlockDate
FROM BackOffice.BlockedCard WITH (NOLOCK)
ORDER BY BlockDate DESC;
```

### 8.3 Check blocklist size
```sql
SELECT COUNT(*) AS BlockedCardCount
FROM BackOffice.BlockedCard WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CheckInBlockedCards | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CheckInBlockedCards.sql*
