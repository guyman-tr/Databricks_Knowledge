# Wallet.PaymentTransactions

> Stores execution details for fiat payment transactions, recording the exchange rate, destination address, amounts, and fee breakdown for the crypto leg of a fiat-to-crypto purchase.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table stores the crypto execution details for each fiat payment from `Wallet.Payments`. While the parent Payments table records the fiat side (currency and amount), this table records the crypto execution side: exchange rate, blockchain destination address, crypto amount, and fee breakdowns (eToro fee + provider fee + blockchain fee). One PaymentTransaction per Payment (unique constraint on PaymentId).

---

## 2. Business Logic

No complex multi-column patterns. Records execution parameters for the crypto leg of the payment.

---

## 3. Data Overview

N/A for transaction detail table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | PaymentId | bigint | NO | - | VERIFIED | Parent payment. FK to Wallet.Payments.Id. Unique constraint - one transaction record per payment. |
| 3 | ExchangeRate | decimal(36,18) | NO | - | CODE-BACKED | Fiat-to-crypto exchange rate at execution time. Used to convert the fiat Amount to crypto. |
| 4 | ToAddress | nvarchar(512) | YES | - | CODE-BACKED | Blockchain destination address for the purchased crypto. |
| 5 | Amount | decimal(36,18) | NO | - | CODE-BACKED | Amount of crypto being purchased/transferred. |
| 6 | EtoroFeePercentage | decimal(5,2) | YES | - | CODE-BACKED | eToro service fee as a percentage. |
| 7 | EtoroFeeCalculated | decimal(36,18) | YES | - | CODE-BACKED | Calculated eToro fee in crypto units. |
| 8 | ProviderFeePercentage | decimal(5,2) | YES | - | CODE-BACKED | Payment provider's fee as a percentage. |
| 9 | ProviderFeeCalculated | decimal(36,18) | YES | - | CODE-BACKED | Calculated provider fee in crypto units. |
| 10 | EstimatedBlockChainFee | decimal(36,18) | NO | - | CODE-BACKED | Estimated blockchain network fee. |
| 11 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of record creation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentId | Wallet.Payments | FK | Parent payment |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertPaymentTransaction | - | Writer | Creates records |
| Wallet.GetPaymentTransaction | - | Reader | Reads transaction details |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.PaymentTransactions (table)
└── Wallet.Payments (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Payments | Table | FK target for PaymentId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertPaymentTransaction | Stored Procedure | Inserts records |
| Wallet.GetPaymentTransaction | Stored Procedure | Reads records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PaymentTransactions | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...PaymentId | NC UNIQUE | PaymentId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Occurred | DEFAULT | getutcdate() |
| FK_...PaymentId | FK | -> Wallet.Payments.Id |

---

## 8. Sample Queries

### 8.1 Get payment with transaction details
```sql
SELECT p.Amount AS FiatAmount, ft.FiatName, pt.ExchangeRate, pt.Amount AS CryptoAmount,
    pt.EtoroFeePercentage, pt.ProviderFeePercentage, pt.EstimatedBlockChainFee
FROM Wallet.PaymentTransactions pt WITH (NOLOCK)
JOIN Wallet.Payments p WITH (NOLOCK) ON pt.PaymentId = p.Id
JOIN Wallet.FiatTypes ft WITH (NOLOCK) ON p.FiatId = ft.Id
WHERE pt.PaymentId = 123577
```

### 8.2 Average fee percentages
```sql
SELECT AVG(pt.EtoroFeePercentage) AS AvgEtoroFee, AVG(pt.ProviderFeePercentage) AS AvgProviderFee
FROM Wallet.PaymentTransactions pt WITH (NOLOCK)
WHERE pt.EtoroFeePercentage IS NOT NULL
```

### 8.3 Recent payment transactions
```sql
SELECT TOP 10 pt.PaymentId, pt.Amount, pt.ExchangeRate, pt.Occurred
FROM Wallet.PaymentTransactions pt WITH (NOLOCK)
ORDER BY pt.Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.PaymentTransactions | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.PaymentTransactions.sql*
