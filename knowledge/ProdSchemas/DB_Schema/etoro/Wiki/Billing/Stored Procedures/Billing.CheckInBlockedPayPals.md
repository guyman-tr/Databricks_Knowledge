# Billing.CheckInBlockedPayPals

> Checks whether a PayPal email address exists in BackOffice.BlockedPayPal, setting @CheckResult OUTPUT to 1 (blocked) or 0 (allowed); used during payment authorization to enforce the PayPal account blocklist.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CheckResult OUTPUT: 0=not blocked, 1=PayPal email is on the blocklist; RETURN @@ERROR |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CheckInBlockedPayPals` is the authorization check for the PayPal email blocklist. During deposit processing via PayPal, before the payment is approved, this procedure checks whether the customer's PayPal email is in `BackOffice.BlockedPayPal`. If @CheckResult=1, the deposit is rejected because this PayPal account has been flagged for fraud, chargebacks, or AML concerns.

This is the third of the three authorization check procedures (alongside `Billing.CheckInBadBins` and `Billing.CheckInBlockedCards`) and the check-side counterpart to `Billing.BlockPayPalAdd` and `Billing.BlockPayPalRemove`.

---

## 2. Business Logic

### 2.1 Blocked PayPal Email Lookup

**What**: EXISTS check in BackOffice.BlockedPayPal for the given email.

**Rules**:
- `SET @CheckResult = CASE WHEN EXISTS(SELECT 1 FROM BackOffice.BlockedPayPal WHERE PayPalEmailAccount = @PayPalEmailAccount) THEN 1 ELSE 0 END`
- @CheckResult=1: PayPal account is blocked - reject.
- @CheckResult=0: PayPal account is not on the blocklist - proceed.
- RETURN @@ERROR.

**@CheckResult Values**:
| Value | Meaning |
|-------|---------|
| 0 | PayPal email not blocked - allowed to proceed |
| 1 | PayPal email is on the blocklist - reject the deposit |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PayPalEmailAccount | VARCHAR(50) | NO | - | CODE-BACKED | The PayPal account email address to check against the blocklist. Case sensitivity depends on database collation. Max 50 characters - matches the column size in BackOffice.BlockedPayPal. Stored in plain text (PayPal emails are not PCI-sensitive data unlike credit card numbers). |
| 2 | @CheckResult | INTEGER | YES | - | CODE-BACKED | OUTPUT parameter. Set to 1 if the email matches any row in BackOffice.BlockedPayPal; 0 if not found (PayPal account allowed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PayPalEmailAccount | BackOffice.BlockedPayPal | READER | EXISTS check for the email in the PayPal blocklist |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files. Called from payment authorization application code during PayPal deposit flows.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CheckInBlockedPayPals (procedure)
+-- BackOffice.BlockedPayPal (table)   [READ - EXISTS check for blocked PayPal email]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BlockedPayPal | Table (cross-schema) | READ - checks if the PayPal email is on the blocklist |

### 6.2 Objects That Depend On This

No dependents found in Billing schema SP files.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **Plain text email (not hashed)**: Unlike `BackOffice.BlockedCard` which uses a card hash, `BackOffice.BlockedPayPal` stores the email in plain text. PayPal emails are not considered sensitive PCI data.
- **Global blocklist**: The block applies globally - all customers using that PayPal email are affected, not just one customer.
- **Part of the PayPal blocklist family**: Three procedures manage the PayPal blocklist - `Billing.BlockPayPalAdd` (add), `Billing.BlockPayPalRemove` (remove), `Billing.CheckInBlockedPayPals` (check).
- **Consistent OUTPUT pattern**: Same @CheckResult OUTPUT interface as `Billing.CheckInBadBins` and `Billing.CheckInBlockedCards`.

---

## 8. Sample Queries

### 8.1 Check if a PayPal email is blocked
```sql
DECLARE @CheckResult INT;
EXEC Billing.CheckInBlockedPayPals
    @PayPalEmailAccount = 'customer@example.com',
    @CheckResult        = @CheckResult OUTPUT;
SELECT @CheckResult AS CheckResult,
    CASE @CheckResult
        WHEN 0 THEN 'Allowed - PayPal email not blocked'
        WHEN 1 THEN 'Blocked - PayPal email is on blocklist'
    END AS Description;
```

### 8.2 View currently blocked PayPal accounts
```sql
SELECT TOP 20 PayPalEmailAccount, BlockDate
FROM BackOffice.BlockedPayPal WITH (NOLOCK)
ORDER BY BlockDate DESC;
```

### 8.3 Check blocklist size
```sql
SELECT COUNT(*) AS BlockedPayPalCount
FROM BackOffice.BlockedPayPal WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CheckInBlockedPayPals | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CheckInBlockedPayPals.sql*
