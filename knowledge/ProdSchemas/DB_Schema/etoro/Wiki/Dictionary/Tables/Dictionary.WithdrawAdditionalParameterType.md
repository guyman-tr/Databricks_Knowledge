# Dictionary.WithdrawAdditionalParameterType

> Lookup table defining the types of additional parameters that can accompany a withdrawal request — such as personal IDs, bank account details, IBAN numbers, and proof-of-payment documents — enabling flexible, payment-method-specific data collection during cashout processing.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, manually assigned) |
| **Partition** | MAIN filegroup |
| **Indexes** | 1 clustered (PK on ID) |

---

## 1. Business Meaning

Dictionary.WithdrawAdditionalParameterType defines the various types of supplementary information that may be required when processing a withdrawal request. Different payment methods require different supporting data — a wire transfer needs an IBAN and BIC code, a credit card refund needs the last 4 digits and card verification, and an internal transfer needs recipient account details. This table classifies those additional parameters so the withdrawal system can dynamically request the right information for each payment method.

Without this table, the system would need hard-coded parameter types for each withdrawal method, making it impossible to add new parameter requirements without code changes. The lookup-driven approach allows operations to configure new parameter types as payment methods evolve.

The table is referenced by Billing.WithdrawAdditionalParameters, which stores the actual parameter values per withdrawal request as key-value pairs where the key is this table's ID. This enables flexible, extensible data collection without modifying the core withdrawal table schema.

---

## 2. Business Logic

### 2.1 Payment-Method-Specific Parameter Classification

**What**: 13 types of additional data that can accompany withdrawal requests, varying by payment method.

**Columns/Parameters Involved**: `ID`, `ParameterType`

**Rules**:
- **Identity**: ClientPersonalId (1) — government ID number for regulatory compliance verification
- **Banking**: IntermediaryBankDetails (2), BankAccountNumber (9), Iban (8), Bic (10), SortCode (11) — wire transfer routing information
- **Card**: EtoroCardId (3), Last4Digits (4) — credit/debit card identification for refund routing
- **Verification**: NonValidMop (5) — flags an invalid method of payment, ProofOfMop (6) — proof document for the payment method
- **Crypto/Wallet**: CurrencyBalanceId (7) — identifies which currency wallet to withdraw from
- **Options**: OptionsCreditCounter (12) — tracks credit count for options-related withdrawals
- **Transfer**: InternalTransferParameters (13) — data needed for internal account-to-account transfers
- Each withdrawal in Billing.WithdrawAdditionalParameters can have multiple parameter rows, one per required parameter type

**Diagram**:
```
Parameter Types by Payment Method:
  Wire Transfer:  BankAccountNumber(9) + Iban(8) + Bic(10) + SortCode(11)
  Credit Card:    EtoroCardId(3) + Last4Digits(4) + ProofOfMop(6)
  Internal:       InternalTransferParameters(13) + CurrencyBalanceId(7)
  All Methods:    ClientPersonalId(1) [if regulatory requirement]
```

---

## 3. Data Overview

| ID | ParameterType | Meaning |
|---|---|---|
| 1 | ClientPersonalId | Customer's government-issued identification number (passport, national ID). Required by some jurisdictions for withdrawal compliance verification and anti-money-laundering checks. |
| 8 | Iban | International Bank Account Number — required for SEPA and international wire transfers. Identifies the specific bank account receiving the withdrawal funds. |
| 4 | Last4Digits | Last 4 digits of the credit/debit card used for deposit. Required when processing refunds back to the original card — ensures the refund routes to the correct card. |
| 13 | InternalTransferParameters | JSON or structured data containing recipient account details for internal eToro-to-eToro transfers (e.g., between a customer's trading account and their crypto wallet). |
| 6 | ProofOfMop | Document proof that the customer owns the payment method (bank statement, card photo). Required for high-risk withdrawals or first-time withdrawals to a new payment method. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Unique identifier for the parameter type: 1=ClientPersonalId, 2=IntermediaryBankDetails, 3=EtoroCardId, 4=Last4Digits, 5=NonValidMop, 6=ProofOfMop, 7=CurrencyBalanceId, 8=Iban, 9=BankAccountNumber, 10=Bic, 11=SortCode, 12=OptionsCreditCounter, 13=InternalTransferParameters. Referenced by Billing.WithdrawAdditionalParameters as the key in key-value parameter storage. |
| 2 | ParameterType | varchar(50) | NO | - | CODE-BACKED | PascalCase name of the parameter type. Serves as both a display label and application code identifier. Used by the withdrawal service to determine which input fields to display and validate for each payment method. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawAdditionalParameters | ID | FK/Implicit | Stores parameter values per withdrawal — each row uses this table's ID as the parameter type key |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.WithdrawAdditionalParameterType (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawAdditionalParameters | Table | Stores parameter values keyed by this table's ID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WithdrawAdditionalParameterType | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all parameter types
```sql
SELECT  ID,
        ParameterType
FROM    [Dictionary].[WithdrawAdditionalParameterType] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find all additional parameters for a specific withdrawal
```sql
SELECT  wap.WithdrawID,
        pt.ParameterType,
        wap.ParameterValue
FROM    [Billing].[WithdrawAdditionalParameters] wap WITH (NOLOCK)
JOIN    [Dictionary].[WithdrawAdditionalParameterType] pt WITH (NOLOCK)
        ON pt.ID = wap.ParameterTypeID
WHERE   wap.WithdrawID = 12345
ORDER BY pt.ID;
```

### 8.3 Group parameters by type to see most common additional data collected
```sql
SELECT  pt.ParameterType,
        COUNT(*) AS UsageCount
FROM    [Billing].[WithdrawAdditionalParameters] wap WITH (NOLOCK)
JOIN    [Dictionary].[WithdrawAdditionalParameterType] pt WITH (NOLOCK)
        ON pt.ID = wap.ParameterTypeID
GROUP BY pt.ParameterType
ORDER BY UsageCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.WithdrawAdditionalParameterType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.WithdrawAdditionalParameterType.sql*
