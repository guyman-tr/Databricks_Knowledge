# Wallet.Conversions

> Records crypto-to-crypto conversion operations where a user swaps one cryptocurrency for another, tracking the source and destination wallets, amounts, and exchange direction.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 7 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table records every crypto-to-crypto conversion (swap) executed within the eToro wallet. Each row represents a single conversion operation - for example, swapping 0.01 BTC for 3,022 XLM. With ~50K rows, conversions are less frequent than direct transactions but represent a key feature of the wallet platform.

Each conversion involves two wallets (FromWalletId and ToWalletId) and two crypto assets (FromCryptoId and ToCryptoId). The `ConversionTypeId` determines whether the source amount or destination amount was fixed by the user (the other is calculated from the market rate). Note: the last conversion was in June 2023, suggesting this feature may have been deprecated or replaced by a newer mechanism.

Rows are created by `Wallet.InsertConversion` during the conversion flow. Status tracking is in `Wallet.ConversionStatuses` and transaction details in `Wallet.ConversionTransactions`.

---

## 2. Business Logic

### 2.1 Fixed Amount Direction

**What**: Users can fix either the source or destination amount, with the other calculated from the market rate.

**Columns/Parameters Involved**: `ConversionTypeId`, `FromAmount`, `ToAmount`

**Rules**:
- ConversionTypeId=1 (FixedFrom): User specifies how much to sell (FromAmount is exact, ToAmount is calculated)
- ConversionTypeId=2 (FixedTo): User specifies how much to buy (ToAmount is exact, FromAmount is calculated)
- See [Conversion Type](../../_glossary.md#conversion-type). FK to Dictionary.ConversionTypes.
- All recent conversions are FixedFrom (type 1)

---

## 3. Data Overview

| Id | FromCryptoId | ToCryptoId | FromAmount | ToAmount | ConversionTypeId | Meaning |
|---|---|---|---|---|---|---|
| 50268 | 1 (BTC) | 18 (ADA) | 0.000825 | 60 | 1 (FixedFrom) | Swapped 0.000825 BTC for 60 ADA. User specified the BTC amount to sell. |
| 50267 | 1 (BTC) | 21 (XLM) | 0.01 | 3022.56 | 1 (FixedFrom) | Swapped 0.01 BTC for 3,022 XLM. BTC was the fixed side. |
| 50266 | 1 (BTC) | 6 (LTC) | 0.01 | 3.22 | 1 (FixedFrom) | Swapped 0.01 BTC for 3.22 LTC. Same user converting BTC to multiple alts. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions. |
| 2 | FromWalletId | uniqueidentifier | NO | - | VERIFIED | The source wallet from which crypto is sold. FK to Wallet.Wallets.WalletId. |
| 3 | ToWalletId | uniqueidentifier | NO | - | VERIFIED | The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId. |
| 4 | ConversionTypeId | tinyint | NO | - | VERIFIED | Determines pricing direction: 1=FixedFrom (sell amount fixed), 2=FixedTo (buy amount fixed). See [Conversion Type](../../_glossary.md#conversion-type). FK to Dictionary.ConversionTypes. |
| 5 | FromAmount | decimal(36,18) | NO | - | VERIFIED | Amount of source crypto being sold. In native units of FromCryptoId. |
| 6 | ToAmount | decimal(36,18) | NO | - | VERIFIED | Amount of destination crypto being purchased. In native units of ToCryptoId. |
| 7 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Links to the parent request in Wallet.Requests.CorrelationId. |
| 8 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when the conversion was initiated. |
| 9 | FromCryptoId | int | NO | - | VERIFIED | Source cryptocurrency being sold. FK to Wallet.CryptoTypes.CryptoID. |
| 10 | ToCryptoId | int | NO | - | VERIFIED | Destination cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FromWalletId | Wallet.Wallets | FK | Source wallet for the swap |
| ToWalletId | Wallet.Wallets | FK | Destination wallet for the swap |
| FromCryptoId | Wallet.CryptoTypes | FK | Crypto being sold |
| ToCryptoId | Wallet.CryptoTypes | FK | Crypto being bought |
| ConversionTypeId | Dictionary.ConversionTypes | FK | Pricing direction |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.ConversionStatuses | ConversionId | FK | Tracks conversion lifecycle |
| Wallet.ConversionTransactions | ConversionId | FK | Stores per-leg transaction details |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.Conversions (table)
├── Wallet.Wallets (table)
├── Wallet.CryptoTypes (table)
└── Dictionary.ConversionTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Wallets | Table | FK target for FromWalletId, ToWalletId |
| Wallet.CryptoTypes | Table | FK target for FromCryptoId, ToCryptoId |
| Dictionary.ConversionTypes | Table | FK target for ConversionTypeId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ConversionStatuses | Table | FK on ConversionId |
| Wallet.ConversionTransactions | Table | FK on ConversionId |
| Wallet.InsertConversion | Stored Procedure | Inserts conversion records |
| Wallet.GetConversion | Stored Procedure | Reads conversion details |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Conversions | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_Conversions__CorrelationId | NC | CorrelationId DESC | - | - | Active |
| IX_Wallet_Conversions__FromWalletId_Occurred | NC | FromWalletId, Occurred DESC | - | - | Active |
| IX_Wallet_Conversions__ToWalletId_Occurred | NC | ToWalletId, Occurred DESC | - | - | Active |
| IX_Wallet_Conversions__Occurred | NC | Occurred DESC | - | - | Active |
| IX_Wallet_Conversions_FromWalletId_FromCryptoId_Occurred | NC | FromWalletId, FromCryptoId, Occurred DESC | - | - | Active |
| IX_Wallet_Conversions_ToWalletId_ToCryptoId_Occurred | NC | ToWalletId, ToCryptoId, Occurred DESC | - | - | Active |
| IX_Conversions_ConversionTypeId_Occurred | NC | ConversionTypeId, Occurred | CorrelationId, FromCryptoId, FromWalletId, ToCryptoId, ToWalletId | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_Conversions__Occurred | DEFAULT | getutcdate() |
| FK_...ConversionTypeId | FK | -> Dictionary.ConversionTypes.Id |
| FK_...FromCryptoId, ToCryptoId | FK | -> Wallet.CryptoTypes.CryptoID |
| FK_...FromWalletId, ToWalletId | FK | -> Wallet.Wallets.WalletId |

---

## 8. Sample Queries

### 8.1 Get conversions for a wallet
```sql
SELECT c.Id, ctFrom.Name AS FromCrypto, c.FromAmount, ctTo.Name AS ToCrypto, c.ToAmount, c.Occurred
FROM Wallet.Conversions c WITH (NOLOCK)
JOIN Wallet.CryptoTypes ctFrom WITH (NOLOCK) ON c.FromCryptoId = ctFrom.CryptoID
JOIN Wallet.CryptoTypes ctTo WITH (NOLOCK) ON c.ToCryptoId = ctTo.CryptoID
WHERE c.FromWalletId = '6CAC2E99-10D8-41F1-A684-D24B3CB4AF9F'
ORDER BY c.Occurred DESC
```

### 8.2 Most popular conversion pairs
```sql
SELECT ctFrom.Name AS FromCrypto, ctTo.Name AS ToCrypto, COUNT(*) AS SwapCount
FROM Wallet.Conversions c WITH (NOLOCK)
JOIN Wallet.CryptoTypes ctFrom WITH (NOLOCK) ON c.FromCryptoId = ctFrom.CryptoID
JOIN Wallet.CryptoTypes ctTo WITH (NOLOCK) ON c.ToCryptoId = ctTo.CryptoID
GROUP BY ctFrom.Name, ctTo.Name
ORDER BY SwapCount DESC
```

### 8.3 Find conversion by correlation ID
```sql
SELECT c.*, cvt.Name AS ConversionType
FROM Wallet.Conversions c WITH (NOLOCK)
JOIN Dictionary.ConversionTypes cvt WITH (NOLOCK) ON c.ConversionTypeId = cvt.Id
WHERE c.CorrelationId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.Conversions | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.Conversions.sql*
