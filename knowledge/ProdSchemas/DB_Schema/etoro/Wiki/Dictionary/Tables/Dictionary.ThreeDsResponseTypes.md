# Dictionary.ThreeDsResponseTypes

> Classifies 3D Secure (3DS) authentication response outcomes for credit card deposit transactions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ThreeDsResponseTypeID (int, PK) |
| **Row Count** | 15 |
| **Indexes** | 1 (clustered PK, FILLFACTOR 95) |

---

## 1. Business Meaning

### What It Is
Dictionary.ThreeDsResponseTypes is a lookup table that classifies the outcomes of 3D Secure (3DS) credit card authentication during deposit transactions. 3DS is the industry standard for strong customer authentication (Visa Secure, Mastercard Identity Check, etc.).

### Why It Exists
When customers make credit card deposits, the 3DS authentication flow can produce multiple outcomes beyond simple pass/fail. The platform needs to track and report on each specific outcome type for fraud monitoring, regulatory reporting, PSP troubleshooting, and risk analysis. This table provides the complete taxonomy of 15 possible 3DS response states.

### How It Works
The `ThreeDsResponseTypeID` is stored in `Billing.CreditCardAuthentication` (active) and `History.BillingCreditCardAuthenticationHistory` (archived). Procedures like `Billing.CreditCardAuthentication_Update` write the response type after each 3DS challenge, while `Monitor.AlertConsecutive3dsFailures` monitors for patterns of failures. BackOffice reporting procedures join against this table to display human-readable response names.

---

## 2. Business Logic

### Value Map (Complete — 15 rows)

| ThreeDsResponseTypeID | Name | Business Meaning |
|-----------------------|------|------------------|
| 0 | Unspecified | Default — no 3DS response recorded yet or not applicable |
| 1 | Success | 3DS authentication passed — cardholder verified |
| 2 | Failed Signature | 3DS signature verification failed — possible tampering |
| 3 | Not Enrolled | Card not enrolled in 3DS program |
| 4 | Enrollment Unavailable | 3DS enrollment service unavailable at issuing bank |
| 5 | Bypassed Enrollment | 3DS enrollment check was bypassed (e.g., low-risk transaction) |
| 6 | Enrollment Error | Technical error during 3DS enrollment check |
| 7 | Timeout | 3DS authentication timed out — cardholder didn't respond |
| 8 | Failed Authentication | Cardholder failed 3DS authentication (wrong code/password) |
| 9 | Authentication Error | Technical error during 3DS authentication step |
| 10 | Authentication Unavailable | 3DS authentication service unavailable |
| 11 | Bypassed Authentication | 3DS authentication was bypassed (risk-based exemption) |
| 12 | Missing Authentication | Expected 3DS authentication data not received |
| 13 | Skipped 3ds | 3DS was intentionally skipped (e.g., recurring payment, trusted merchant) |
| 14 | Unexpected | Unexpected/unclassified 3DS response |

### 3DS Flow Phases
Two distinct phases, each with its own failure modes:
1. **Enrollment** (IDs 3-6): Checks if the card supports 3DS
2. **Authentication** (IDs 7-12): The actual cardholder verification challenge

---

## 3. Data Overview

| ThreeDsResponseTypeID | Name | Scenario |
|-----------------------|------|----------|
| 1 | Success | Customer enters OTP code correctly during deposit |
| 7 | Timeout | Customer opens 3DS popup but never enters the code |
| 8 | Failed Authentication | Customer enters wrong OTP three times |
| 13 | Skipped 3ds | Recurring deposit where 3DS is exempted |
| 3 | Not Enrolled | Customer's bank doesn't support 3DS |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ThreeDsResponseTypeID | int | NO | — | HIGH | Primary key identifying the 3DS response outcome. Sequential 0-14. Referenced by Billing.CreditCardAuthentication and History.BillingCreditCardAuthenticationHistory. |
| 2 | Name | varchar(50) | YES | — | HIGH | Human-readable response description. Nullable in DDL but populated for all rows. |

---

## 5. Relationships

### Referenced By (Implicit — no declared FK)

| Consumer Table | Column | Relationship | Evidence |
|----------------|--------|-------------|----------|
| Billing.CreditCardAuthentication | ThreeDsResponseTypeID | Implicit FK | Active 3DS authentication records |
| History.BillingCreditCardAuthenticationHistory | ThreeDsResponseTypeID | Implicit FK | Archived 3DS records |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| Billing.CreditCardAuthentication_Update | UPDATE | Writes 3DS response type after authentication |
| Billing.CreditCardAuthentication_Get | SELECT | Reads 3DS response for display |
| Monitor.AlertConsecutive3dsFailures | SELECT | Monitors for consecutive 3DS failure patterns |
| BackOffice.GetRiskExposureReportPCIVersion | SELECT (JOIN) | Risk exposure reporting with 3DS outcomes |
| BackOffice.BillingDepositsPCIVersion | SELECT (JOIN) | Deposit reporting with 3DS response names |
| BackOffice.GetDepositRuleAggregation | SELECT | Deposit rule aggregation with 3DS data |
| BackOffice.NewRiskAlertsPCIVersion | SELECT | Risk alerts based on 3DS patterns |
| Billing.GetDepositsCustomerCardPCIVersion | SELECT | Customer card deposit history with 3DS info |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table with no foreign keys.

### Depended On By
- `Billing.CreditCardAuthentication` — stores 3DS response per authentication attempt
- 8+ procedures for billing, monitoring, and risk reporting

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_ThreeDsResponseTypes | CLUSTERED PK | ThreeDsResponseTypeID ASC | FILLFACTOR 95 |

---

## 8. Sample Queries

```sql
-- Get all 3DS response types
SELECT  ThreeDsResponseTypeID,
        Name
FROM    Dictionary.ThreeDsResponseTypes WITH (NOLOCK)
ORDER BY ThreeDsResponseTypeID;

-- Count authentications by response type
SELECT  drt.Name AS ResponseType,
        COUNT(*) AS AuthCount
FROM    Billing.CreditCardAuthentication cca WITH (NOLOCK)
JOIN    Dictionary.ThreeDsResponseTypes drt WITH (NOLOCK)
        ON cca.ThreeDsResponseTypeID = drt.ThreeDsResponseTypeID
GROUP BY drt.Name
ORDER BY AuthCount DESC;

-- Find failed 3DS authentications
SELECT  cca.*,
        drt.Name AS ResponseType
FROM    Billing.CreditCardAuthentication cca WITH (NOLOCK)
JOIN    Dictionary.ThreeDsResponseTypes drt WITH (NOLOCK)
        ON cca.ThreeDsResponseTypeID = drt.ThreeDsResponseTypeID
WHERE   drt.ThreeDsResponseTypeID IN (2, 8, 9);
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `ThreeDsResponseTypes`.

---

*Generated: 2026-03-14 | Quality: 9.2/10*
*Object: Dictionary.ThreeDsResponseTypes | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ThreeDsResponseTypes.sql*
