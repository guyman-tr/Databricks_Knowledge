# Wallet.Payments

> Records fiat payment operations linked to crypto wallets, tracking fiat-to-crypto purchases where users buy cryptocurrency using fiat currency through a payment provider.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 4 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table records fiat-to-crypto payment operations. Each row represents a payment where a user purchases cryptocurrency using fiat currency (USD, EUR, GBP, AUD) through a payment provider. With ~114K rows, payments are relatively infrequent compared to direct crypto transactions but represent an important on-ramp for fiat-to-crypto. The last payment was September 2022, suggesting this feature may have been replaced by a different mechanism.

Each payment involves a specific wallet (WalletId), a fiat amount (Amount in FiatId currency), and the crypto being purchased (CryptoId). The payment flow is tracked through `Wallet.PaymentStatuses` and transaction details in `Wallet.PaymentTransactions`.

Rows are created by `Wallet.InsertPayment` when a user initiates a fiat-to-crypto purchase.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Payments follow a straightforward initiation -> provider processing -> completion lifecycle tracked in child tables.

---

## 3. Data Overview

| Id | WalletId | Amount | FiatId | CryptoId | ProviderPaymentId | Meaning |
|---|---|---|---|---|---|---|
| 123577 | AA9C3EDC-... | 125 | 2 (EUR) | 1 (BTC) | 4F6F81BE-... | Purchase of BTC worth 125 EUR through payment provider |
| 123576 | EF2C1AA9-... | 110 | 3 (GBP) | 1 (BTC) | 821A66FA-... | Purchase of BTC worth 110 GBP |
| 123575 | 671C1595-... | 125 | 2 (EUR) | 3 (BCH) | 39164A87-... | Purchase of BCH worth 125 EUR |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. FK target for Wallet.PaymentStatuses, Wallet.PaymentTransactions, and Wallet.Chargebacks. |
| 2 | WalletId | uniqueidentifier | NO | - | VERIFIED | The customer's wallet receiving the purchased crypto. FK to Wallet.Wallets.WalletId. |
| 3 | ProviderPaymentId | uniqueidentifier | NO | - | CODE-BACKED | Payment identifier assigned by the external payment provider. Used for reconciliation and provider API calls. |
| 4 | Amount | decimal(36,18) | NO | - | VERIFIED | Fiat amount of the payment. Denominated in the currency specified by FiatId (e.g., 125 EUR). |
| 5 | FiatId | int | NO | - | VERIFIED | The fiat currency used for payment: 1=USD, 2=EUR, 3=GBP, 5=AUD. FK to Wallet.FiatTypes.Id. |
| 6 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Links to the parent request in Wallet.Requests.CorrelationId. |
| 7 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when the payment was initiated. |
| 8 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletId | Wallet.Wallets | FK | Customer's receiving wallet |
| FiatId | Wallet.FiatTypes | FK | Fiat currency used |
| CryptoId | Wallet.CryptoTypes | FK | Crypto being purchased |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.PaymentStatuses | PaymentId | FK | Tracks payment lifecycle |
| Wallet.PaymentTransactions | PaymentId | FK | Stores transaction execution details |
| Wallet.Chargebacks | PaymentId | FK | Records chargebacks/refunds against this payment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.Payments (table)
├── Wallet.Wallets (table)
├── Wallet.CryptoTypes (table)
└── Wallet.FiatTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Wallets | Table | FK target for WalletId |
| Wallet.CryptoTypes | Table | FK target for CryptoId |
| Wallet.FiatTypes | Table | FK target for FiatId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.PaymentStatuses | Table | FK on PaymentId |
| Wallet.PaymentTransactions | Table | FK on PaymentId |
| Wallet.Chargebacks | Table | FK on PaymentId |
| Wallet.InsertPayment | Stored Procedure | Creates payment records |
| Wallet.GetPayment | Stored Procedure | Reads payment details |
| Wallet.GetCustomerPaymentById | Stored Procedure | Reads payment with customer context |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Payments | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_Payments__CorrelationId | NC | CorrelationId DESC | - | - | Active |
| IX_Wallet_Payments__Occurred | NC | Occurred DESC | - | - | Active |
| IX_Wallet_Payments__WalletId_Occurred | NC | WalletId, Occurred DESC | - | - | Active |
| IX_Wallet_Payments_WalletId_CryptoId_Occurred | NC | WalletId, CryptoId, Occurred DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_Payments__Occurred | DEFAULT | getutcdate() |
| FK_...CryptoId | FK | -> Wallet.CryptoTypes.CryptoID |
| FK_...FiatId | FK | -> Wallet.FiatTypes.Id |
| FK_...WalletId | FK | -> Wallet.Wallets.WalletId |

---

## 8. Sample Queries

### 8.1 Get payments for a wallet
```sql
SELECT p.Id, ft.FiatName, p.Amount, ct.Name AS Crypto, p.Occurred
FROM Wallet.Payments p WITH (NOLOCK)
JOIN Wallet.FiatTypes ft WITH (NOLOCK) ON p.FiatId = ft.Id
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON p.CryptoId = ct.CryptoID
WHERE p.WalletId = 'AA9C3EDC-D541-4AFE-98E0-BA39013E0F2C'
ORDER BY p.Occurred DESC
```

### 8.2 Payment volume by fiat currency
```sql
SELECT ft.FiatName, COUNT(*) AS PaymentCount, SUM(p.Amount) AS TotalFiatAmount
FROM Wallet.Payments p WITH (NOLOCK)
JOIN Wallet.FiatTypes ft WITH (NOLOCK) ON p.FiatId = ft.Id
GROUP BY ft.FiatName
ORDER BY PaymentCount DESC
```

### 8.3 Find payment by correlation ID
```sql
SELECT p.Id, p.Amount, ft.FiatName, ct.Name AS Crypto, p.ProviderPaymentId
FROM Wallet.Payments p WITH (NOLOCK)
JOIN Wallet.FiatTypes ft WITH (NOLOCK) ON p.FiatId = ft.Id
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON p.CryptoId = ct.CryptoID
WHERE p.CorrelationId = '4F6F81BE-0558-4899-AC0B-C3F80475C2B6'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.Payments | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.Payments.sql*
