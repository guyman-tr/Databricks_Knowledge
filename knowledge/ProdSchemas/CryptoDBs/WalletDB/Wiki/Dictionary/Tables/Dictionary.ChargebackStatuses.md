# Dictionary.ChargebackStatuses

> Lookup table defining the types of payment reversal actions in the wallet's fiat payment processing system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the types of chargeback and refund actions that can occur against fiat payment transactions in the wallet system. When a customer disputes a credit card charge or the platform initiates a refund, the resulting reversal is classified using one of these statuses.

Chargebacks are a significant financial and compliance concern for any payment platform. Tracking whether a reversal was a true chargeback (initiated by the customer's bank), a voluntary refund (initiated by eToro), or a refund processed as a chargeback helps the finance team reconcile accounts and identify fraud patterns.

The values are consumed by `Wallet.Chargebacks` table records and referenced in payment-related stored procedures (`GetCustomerPaymentById`) and transaction list functions (`GetPaymentTransactionList`, `GetPaymentTransactionListV2`).

---

## 2. Business Logic

### 2.1 Reversal Type Classification

**What**: Three distinct types of payment reversals with different business implications.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `ChargeBack` (1): Customer-initiated dispute through their bank. The bank forcibly reverses the charge. eToro may contest the chargeback or accept it. Tracked for fraud monitoring.
- `Refund` (2): eToro-initiated voluntary return of funds to the customer. Typically for service issues, goodwill, or regulatory compliance.
- `RefundAsChargeback` (3): A refund that is processed through the chargeback mechanism rather than the standard refund flow. May occur when the original payment method requires chargeback-style processing for refunds.

**Diagram**:
```
Payment Reversal
    |
    +---> ChargeBack (1)          [Customer-initiated via bank]
    |       Bank forces reversal, eToro may dispute
    |
    +---> Refund (2)              [eToro-initiated]
    |       Voluntary return, standard refund flow
    |
    +---> RefundAsChargeback (3)  [Hybrid]
            Refund processed through chargeback mechanism
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | ChargeBack | A bank-initiated payment reversal where the customer disputes a charge with their card issuer. The bank debits eToro's merchant account. May indicate fraud, unauthorized use, or legitimate dispute. High financial and regulatory impact. |
| 2 | Refund | A voluntary refund initiated by eToro to return funds to the customer. Processed through standard payment channels. Used for service issues, compliance requirements, or customer goodwill. |
| 3 | RefundAsChargeback | A refund that must be processed using the chargeback mechanism rather than a standard refund flow. Occurs when the payment processor or card network requires chargeback-style processing for the refund to reach the customer. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the chargeback status type. Values: 1=ChargeBack, 2=Refund, 3=RefundAsChargeback. Referenced by Wallet.Chargebacks records and payment transaction queries. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Human-readable label for the reversal type. Used in finance reports, payment reconciliation, and fraud monitoring dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.Chargebacks | ChargebackStatusId | Implicit | Classifies each chargeback record by reversal type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetCustomerPaymentById | Stored Procedure | JOINs to resolve chargeback status names |
| Wallet.GetPaymentTransactionList | Function | JOINs for payment transaction reporting |
| Wallet.GetPaymentTransactionListV2 | Function | JOINs for payment transaction reporting (v2) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ChargebackStatuses | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all chargeback statuses
```sql
SELECT Id, Name
FROM Dictionary.ChargebackStatuses WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Count chargebacks by type
```sql
SELECT cs.Name AS ReversalType, COUNT(c.Id) AS Count
FROM Dictionary.ChargebackStatuses cs WITH (NOLOCK)
LEFT JOIN Wallet.Chargebacks c WITH (NOLOCK) ON c.ChargebackStatusId = cs.Id
GROUP BY cs.Name
ORDER BY Count DESC
```

### 8.3 Recent chargebacks with status names
```sql
SELECT c.Id, c.Amount, cs.Name AS ReversalType, c.Created
FROM Wallet.Chargebacks c WITH (NOLOCK)
JOIN Dictionary.ChargebackStatuses cs WITH (NOLOCK) ON c.ChargebackStatusId = cs.Id
ORDER BY c.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ChargebackStatuses | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.ChargebackStatuses.sql*
