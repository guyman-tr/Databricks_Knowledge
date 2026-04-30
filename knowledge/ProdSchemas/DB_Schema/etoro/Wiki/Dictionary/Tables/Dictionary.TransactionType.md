# Dictionary.TransactionType

> Lookup table defining the three top-level financial transaction categories: Deposit, Refund, and Payout (withdrawal).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK CLUSTERED) |
| **Partition** | No — on PRIMARY |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.TransactionType defines the highest-level classification of financial transactions flowing through the eToro platform. Every money movement between the platform and a customer falls into one of three categories: Deposit (money in), Refund (money back to customer due to reversal), or Payout (withdrawal/cashout of funds).

This coarse classification is used to route transactions through the appropriate processing pipelines. Deposits flow through the deposit engine (Billing.DepositProcess), payouts through the cashout engine, and refunds through the chargeback/reversal pipeline. Each of these top-level types has sub-classifications handled by more detailed lookup tables (e.g., DepositType, CashoutType, PaymentStatus).

---

## 2. Business Logic

### 2.1 Money Flow Direction

**What**: Each transaction type represents a direction of money flow between the platform and the customer.

**Columns/Parameters Involved**: `ID`, `TransactionType`

**Rules**:
- **Deposit (0)**: Money flows FROM the customer TO the platform. Increases account balance.
- **Refund (1)**: Money flows FROM the platform TO the customer as a reversal of a previous deposit. Decreases account balance.
- **Payout (2)**: Money flows FROM the platform TO the customer as a requested withdrawal. Decreases account balance.

**Diagram**:
```
Customer ──── Deposit (0) ────→ Platform (balance ↑)
Customer ←──── Refund (1) ────── Platform (balance ↓, reversal)
Customer ←──── Payout (2) ────── Platform (balance ↓, withdrawal)
```

---

## 3. Data Overview

| ID | TransactionType | Meaning |
|---|---|---|
| 0 | Deposit | Money flowing from the customer to the platform — credit card charge, wire transfer, e-wallet payment. Increases the customer's available balance for trading. |
| 1 | Refund | Money returned to the customer as a reversal of a previous deposit — chargeback, processing error correction, or merchant-initiated refund. Different from Payout because it reverses an existing transaction rather than creating a new outflow. |
| 2 | Payout | Customer-initiated withdrawal of funds from their account — cashout via wire, card refund, or e-wallet. Decreases available balance. Subject to cashout rules, verification requirements, and processing fees. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Transaction category identifier: **0**=Deposit (money in), **1**=Refund (money back, reversal), **2**=Payout (withdrawal/cashout). |
| 2 | TransactionType | varchar(100) | NO | - | CODE-BACKED | Human-readable transaction category name: "Deposit", "Refund", "Payout". Used in billing reports and transaction history displays. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing tables | TransactionTypeID | Implicit | Billing records classify each transaction into one of these three categories |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.TransactionType (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing subsystem | Various | Transaction classification for routing and reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryTransactionType | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryTransactionType | PRIMARY KEY | Unique transaction type identifier, FILLFACTOR 95, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all transaction types
```sql
SELECT  ID,
        TransactionType
FROM    Dictionary.TransactionType WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Classify a transaction by type
```sql
SELECT  tt.TransactionType  AS Category,
        'Customer deposit via credit card' AS Example
FROM    Dictionary.TransactionType tt WITH (NOLOCK)
WHERE   tt.ID = 0;
```

### 8.3 Join transaction types with billing data
```sql
SELECT  tt.TransactionType,
        COUNT(*)            AS TransactionCount
FROM    Billing.Deposit d WITH (NOLOCK)
CROSS JOIN Dictionary.TransactionType tt WITH (NOLOCK)
WHERE   tt.ID = 0
GROUP BY tt.TransactionType;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TransactionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TransactionType.sql*
