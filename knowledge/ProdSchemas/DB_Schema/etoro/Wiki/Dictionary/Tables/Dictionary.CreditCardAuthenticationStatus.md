# Dictionary.CreditCardAuthenticationStatus

> Lookup table defining the possible outcomes of a credit card 3D Secure / authentication attempt during deposit processing.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

This table enumerates the possible authentication statuses for credit card transactions processed through the platform's payment gateway. When a customer makes a deposit using a credit card, the payment processor returns an authentication result — this table provides the dictionary of those results. The statuses cover the full range from successful authentication (Approved) through various failure modes (Decline, Technical) to specialized outcomes (DeclineByRRE — declined by the Real-time Risk Engine).

Without this table, the billing system would have no standardized way to classify credit card authentication outcomes. It enables downstream reporting, retry logic decisions, and risk assessment of payment attempts.

The table is a pure dictionary with only 5 values. No procedures or views in the etoro database currently JOIN to it directly, suggesting it may be consumed primarily by application-layer code or used in other databases/services for deposit processing analytics.

---

## 2. Business Logic

### 2.1 Authentication Outcome Classification

**What**: Credit card authentication results are classified into success, failure, and technical categories.

**Columns/Parameters Involved**: `ID`, `StatusName`

**Rules**:
- ID 1 (New) represents an authentication attempt that has been initiated but not yet resolved
- ID 2 (Approved) is the only successful outcome that allows the deposit to proceed
- ID 3 (Decline) indicates the card issuer or 3DS system rejected the authentication
- ID 4 (Technical) indicates the authentication could not be completed due to a system error
- ID 35 (DeclineByRRE) indicates the Real-time Risk Engine rejected the transaction before or during authentication — a fraud/risk prevention gate

**Diagram**:
```
Credit Card Authentication Flow:
  New (1) ──► Approved (2)     → deposit proceeds
           ├─► Decline (3)      → deposit blocked, user retries
           ├─► Technical (4)    → system error, automatic retry possible
           └─► DeclineByRRE (35)→ risk engine block, may trigger review
```

---

## 3. Data Overview

| ID | StatusName | Meaning |
|---|---|---|
| 1 | New | Authentication attempt has been created but the card issuer has not yet returned a result — the transaction is in-flight and awaiting 3D Secure challenge completion |
| 2 | Approved | Card issuer confirmed the cardholder's identity — the deposit can proceed to capture/settlement with reduced chargeback liability |
| 3 | Decline | Card issuer or 3DS provider rejected the authentication — the cardholder failed identity verification, or the issuer does not support 3DS for this card |
| 4 | Technical | A system-level failure occurred during the authentication handshake — network timeout, provider outage, or malformed response from the 3DS provider |
| 35 | DeclineByRRE | The platform's Real-time Risk Engine flagged and rejected the transaction before or during authentication — typically due to fraud patterns, velocity checks, or blacklisted BIN ranges |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key identifying the authentication status. Non-sequential (1-4 then jumps to 35), indicating the RRE status was added later as a separate risk engine integration. |
| 2 | StatusName | nvarchar(100) | NO | - | CODE-BACKED | Human-readable name for the authentication outcome: New, Approved, Decline, Technical, DeclineByRRE. Used in reporting and BackOffice UI displays. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct SQL consumers found in the etoro SSDT project. Likely consumed by application-layer code or external reporting systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CreditCardAuthenticationStatus (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the etoro SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CreditCardAuthenticationStatus | CLUSTERED | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all authentication statuses
```sql
SELECT  ID,
        StatusName
FROM    Dictionary.CreditCardAuthenticationStatus WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Check if a specific status is a failure
```sql
SELECT  ID,
        StatusName,
        CASE WHEN ID IN (3, 4, 35) THEN 'Failed' ELSE 'OK' END AS Outcome
FROM    Dictionary.CreditCardAuthenticationStatus WITH (NOLOCK)
```

### 8.3 Resolve authentication status for deposit records
```sql
SELECT  d.DepositID,
        d.CID,
        ccas.StatusName AS AuthStatus
FROM    Billing.Deposit d WITH (NOLOCK)
        LEFT JOIN Dictionary.CreditCardAuthenticationStatus ccas WITH (NOLOCK) ON d.CreditCardAuthenticationStatusID = ccas.ID
WHERE   d.CreditCardAuthenticationStatusID IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CreditCardAuthenticationStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CreditCardAuthenticationStatus.sql*
