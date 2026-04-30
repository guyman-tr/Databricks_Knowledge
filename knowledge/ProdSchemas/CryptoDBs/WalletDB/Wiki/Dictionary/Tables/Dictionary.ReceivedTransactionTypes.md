# Dictionary.ReceivedTransactionTypes

> Lookup table classifying the types of incoming cryptocurrency transactions received by wallets on the platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table classifies the different reasons cryptocurrency arrives into a wallet on the platform. Each incoming transaction is tagged with a type that indicates whether it is a customer deposit (MoneyIn), a redemption return, a funding operation, a conversion leg, a payment, or a staking refund.

Understanding the type of received transaction is essential for routing the funds correctly, applying the right compliance checks, and generating accurate financial reports.

The table is FK-referenced by `Wallet.ReceivedTransactions`.

---

## 2. Business Logic

### 2.1 Incoming Transaction Classification

**What**: Eight categories of incoming crypto transactions.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `MoneyIn` (1): Customer deposits crypto from an external wallet. Subject to AML screening.
- `Redeem` (2): Return of previously redeemed (sold) crypto - typically a reversal or error correction.
- `Funding` (3): Internal funding operation - crypto moved from omnibus to customer wallet.
- `ConversionFromUser` (4): Incoming leg of a user-initiated crypto-to-crypto conversion.
- `ConversionFromEtoro` (5): Incoming leg of an eToro-initiated conversion (e.g., rebalancing).
- `Payment` (6): Crypto received as a fiat payment settlement.
- `RedeemAsic` (7): ASIC-specific redemption return (Australian Securities and Investments Commission compliance).
- `StakeAndRewardsRefund` (8): Return of staked crypto or staking rewards.

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | MoneyIn | Customer deposits cryptocurrency from an external wallet. The most common type. Triggers AML screening of the sender address before funds are credited. |
| 2 | Redeem | Return of previously redeemed cryptocurrency. Occurs during reversal scenarios or when a redemption is cancelled after partial execution. |
| 4 | ConversionFromUser | Incoming leg of a customer-initiated crypto swap. When a customer converts BTC to ETH, the ETH arrival is tagged as ConversionFromUser. |
| 6 | Payment | Cryptocurrency received as part of a fiat payment settlement. Links the crypto wallet system to the fiat payment processing pipeline. |
| 8 | StakeAndRewardsRefund | Return of staked cryptocurrency or accumulated staking rewards. Occurs when a staking position is unwound or rewards are distributed back to the customer wallet. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the received transaction type. Values: 1=MoneyIn, 2=Redeem, 3=Funding, 4=ConversionFromUser, 5=ConversionFromEtoro, 6=Payment, 7=RedeemAsic, 8=StakeAndRewardsRefund. FK target for Wallet.ReceivedTransactions.ReceivedTransactionTypeId. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Label for the transaction type. Used in transaction reporting, compliance dashboards, and financial reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.ReceivedTransactions | ReceivedTransactionTypeId | FK | Classifies each received transaction |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | FK on ReceivedTransactionTypeId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ReceivedTransactionTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all received transaction types
```sql
SELECT Id, Name FROM Dictionary.ReceivedTransactionTypes WITH (NOLOCK) ORDER BY Id
```

### 8.2 Count received transactions by type
```sql
SELECT rtt.Name, COUNT(rt.ReceivedTransactionId) AS Count
FROM Dictionary.ReceivedTransactionTypes rtt WITH (NOLOCK)
LEFT JOIN Wallet.ReceivedTransactions rt WITH (NOLOCK) ON rt.ReceivedTransactionTypeId = rtt.Id
GROUP BY rtt.Name ORDER BY Count DESC
```

### 8.3 Recent customer deposits (MoneyIn)
```sql
SELECT rt.ReceivedTransactionId, rtt.Name AS Type, rt.Amount, rt.Created
FROM Wallet.ReceivedTransactions rt WITH (NOLOCK)
JOIN Dictionary.ReceivedTransactionTypes rtt WITH (NOLOCK) ON rt.ReceivedTransactionTypeId = rtt.Id
WHERE rtt.Id = 1 ORDER BY rt.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ReceivedTransactionTypes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.ReceivedTransactionTypes.sql*
