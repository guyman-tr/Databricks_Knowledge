# Dictionary.TransactionTypes

> Lookup table classifying all types of blockchain transactions in the wallet system, distinguishing between customer withdrawals, funding operations, conversions, payments, staking, and other crypto movements.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table classifies every blockchain transaction by its business purpose. It is one of the most heavily referenced Dictionary tables (16+ consumers), used across sent transactions, received transactions, redemptions, limitations, limit exceeds, views, and stored procedures.

The 16 transaction types cover every category of crypto movement on the platform - from customer-initiated withdrawals to internal funding operations to conversion legs to staking operations. The type determines routing, fee calculation, compliance checks, and reporting categorization.

FK-referenced by `Wallet.SentTransactions`, `Wallet.ReceivedTransactions`, `Wallet.Redemptions`, `Wallet.LimitationsDefinitions`, and `Wallet.LimitExceeds`. Consumed by 6 views and multiple SPs.

---

## 2. Business Logic

### 2.1 Transaction Type Classification

**What**: 16 types covering all crypto movement categories. Non-sequential IDs (gap at 3).

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- **Customer Operations**: `Redeem` (0), `CustomerMoneyOut` (1), `CustomerMoneyBack` (15), `ManualUserMoneyOut` (13)
- **Internal Operations**: `Funding` (4), `OmnibusMoneyOut` (11), `BlockChainActivation` (10)
- **Conversion Legs**: `ConversionMoneyIn` (5), `ConversionMoneyOut` (6), `ConversionToFiat` (12)
- **Compliance**: `AmlMoneyBack` (2) - returning funds flagged by AML
- **Payment**: `Payment` (7)
- **Staking**: `Staking` (9), `StakeAndRewardsRefund` (14)
- **Other**: `RedeemAsic` (8) - ASIC-specific redemption

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 0 | Redeem | Customer sells crypto position - crypto is sent from the platform to be liquidated. The primary crypto-to-fiat off-ramp transaction type. |
| 1 | CustomerMoneyOut | Customer withdraws crypto to an external wallet address. The most common outbound transaction type for direct crypto transfers. |
| 4 | Funding | Internal transfer from omnibus/hot wallet to a customer wallet. Used when a customer needs crypto funded from the platform's reserves. |
| 11 | OmnibusMoneyOut | Batched withdrawal from the platform's omnibus wallet. Multiple customer withdrawals aggregated into a single blockchain transaction for gas efficiency. |
| 14 | StakeAndRewardsRefund | Return of staked crypto or staking rewards. Occurs when a staking position is closed or rewards are distributed to the customer wallet. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier. Values: 0=Redeem, 1=CustomerMoneyOut, 2=AmlMoneyBack, 4=Funding, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking, 10=BlockChainActivation, 11=OmnibusMoneyOut, 12=ConversionToFiat, 13=ManualUserMoneyOut, 14=StakeAndRewardsRefund, 15=CustomerMoneyBack. Gap at Id=3. FK target for SentTransactions, ReceivedTransactions, Redemptions, LimitationsDefinitions, LimitExceeds. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | PascalCase type label. Used across views, stored procedures, and functions for transaction categorization and reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.SentTransactions | TransactionTypeId | FK | Classifies each outgoing blockchain transaction |
| Wallet.ReceivedTransactions | TransactionTypeId | FK | Classifies each incoming blockchain transaction |
| Wallet.Redemptions | TransactionTypeId | FK | Associates redemptions with their transaction type |
| Wallet.LimitationsDefinitions | TransactionTypeId | FK | Links limit rules to specific transaction types |
| Wallet.LimitExceeds | TransactionTypeId | FK | Records which transaction type triggered a limit exceed |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | FK |
| Wallet.ReceivedTransactions | Table | FK |
| Wallet.Redemptions | Table | FK |
| Wallet.LimitationsDefinitions | Table | FK |
| Wallet.LimitExceeds | Table | FK |
| Wallet.TransactionsView | View | JOINs for reporting |
| Wallet.vu_GetWalletBalanceReport* | Views (4) | JOINs for balance reporting |
| Wallet.StuckTransactionsInTheBlockchain | Stored Procedure | Filters by type |
| Wallet.GetLimitationsConfigurations | Stored Procedure | Reads limits per type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TransactionTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all transaction types
```sql
SELECT Id, Name FROM Dictionary.TransactionTypes WITH (NOLOCK) ORDER BY Id
```

### 8.2 Sent transactions by type
```sql
SELECT tt.Name, COUNT(*) AS Count
FROM Wallet.SentTransactions st WITH (NOLOCK)
JOIN Dictionary.TransactionTypes tt WITH (NOLOCK) ON st.TransactionTypeId = tt.Id
GROUP BY tt.Name ORDER BY Count DESC
```

### 8.3 Limits configured per transaction type
```sql
SELECT tt.Name AS TransactionType, COUNT(ld.Id) AS LimitCount
FROM Dictionary.TransactionTypes tt WITH (NOLOCK)
LEFT JOIN Wallet.LimitationsDefinitions ld WITH (NOLOCK) ON ld.TransactionTypeId = tt.Id
GROUP BY tt.Name ORDER BY LimitCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 16 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TransactionTypes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.TransactionTypes.sql*
