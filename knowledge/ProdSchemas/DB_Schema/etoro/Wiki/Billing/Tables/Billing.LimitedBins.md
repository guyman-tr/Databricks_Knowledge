# Billing.LimitedBins

> Single-column blocklist of credit/debit card BIN prefixes (first 6 digits) that are subject to deposit restrictions on the eToro platform.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | Bin (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered on Bin) |

---

## 1. Business Meaning

Billing.LimitedBins stores a set of 79 card BIN (Bank Identification Number) codes - the first 6 digits of a credit or debit card number that identify the issuing bank and card program. When a customer attempts a deposit with a credit card, the deposit service checks whether the card's BIN appears in this table to determine if the card type has deposit restrictions.

This table exists to flag specific card issuers or card programs that eToro has determined require special deposit handling - these may include prepaid cards, certain regional bank cards, virtual cards, or cards from institutions with known compliance or processing issues. The name "LimitedBins" implies these BINs have limited deposit functionality (e.g., restricted amounts, blocked for first deposits, or flagged for compliance review).

The DepositUser database role has SELECT permission on this table, indicating it is queried directly by the deposit processing service (not via stored procedures) as part of the deposit eligibility check flow.

---

## 2. Business Logic

### 2.1 BIN-Based Deposit Restriction

**What**: Any card whose first 6 digits match a Bin in this table is subject to deposit limitations.

**Columns/Parameters Involved**: `Bin`

**Rules**:
- Bin values are 6-digit integers (e.g., 401713, 401795) - the industry-standard BIN length.
- The table functions as a blocklist/allowlist: presence in this table means the card is "limited" in some way.
- The deposit service joins or checks against this table during deposit authorization.
- 79 BINs are currently flagged. All start with 4xxxxx (Visa) or 5xxxxx (Mastercard) range based on TOP 10 sample.
- No expiry or date columns - this is a static list maintained by the payments/compliance team.

---

## 3. Data Overview

| Bin | Meaning |
|-----|---------|
| 401713 | Visa card BIN flagged as limited. Specific issuer/program has deposit restrictions. |
| 401795 | Visa card BIN - second BIN from the same or related Visa issuer range. |
| 402918 | Visa BIN - different issuer, also limited. |
| 405071 | Visa BIN - limited deposit card. |
| 410560 | Visa BIN - limited deposit card. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Bin | int | NO | - | CODE-BACKED | Credit/debit card BIN (Bank Identification Number) - the first 6 digits of the card number identifying the issuing bank and card program. Serves as both the primary key and the sole data element. Cards whose BIN matches an entry here are treated as "limited" in the deposit flow and may face deposit restrictions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositUser (application role) | Bin | SELECT permission | Deposit processing service reads this table directly to check card BIN eligibility. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LimitedBins (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositUser application role | Application | SELECT - reads BIN list during deposit card validation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingLimitedBins | CLUSTERED PK | Bin ASC | - | - | Active (FILLFACTOR=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingLimitedBins | PRIMARY KEY | Bin column - ensures each BIN appears only once |

---

## 8. Sample Queries

### 8.1 Check if a card BIN is limited

```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Billing.LimitedBins WITH (NOLOCK) WHERE Bin = 401713
) THEN 'Limited' ELSE 'Not Limited' END AS BinStatus
```

### 8.2 Get all limited BINs

```sql
SELECT Bin
FROM Billing.LimitedBins WITH (NOLOCK)
ORDER BY Bin
```

### 8.3 Find how many BINs fall in each card network range

```sql
SELECT
    CASE
        WHEN Bin BETWEEN 400000 AND 499999 THEN 'Visa'
        WHEN Bin BETWEEN 500000 AND 559999 THEN 'Mastercard'
        WHEN Bin BETWEEN 340000 AND 379999 THEN 'Amex'
        ELSE 'Other'
    END AS CardNetwork,
    COUNT(*) AS BinCount
FROM Billing.LimitedBins WITH (NOLOCK)
GROUP BY
    CASE
        WHEN Bin BETWEEN 400000 AND 499999 THEN 'Visa'
        WHEN Bin BETWEEN 500000 AND 559999 THEN 'Mastercard'
        WHEN Bin BETWEEN 340000 AND 379999 THEN 'Amex'
        ELSE 'Other'
    END
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 6.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (no SP references found) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.LimitedBins | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.LimitedBins.sql*
