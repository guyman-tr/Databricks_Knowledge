# Pre-Resolved Upstream Bundle for `EXW_dbo.EXW_FactConversions`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_dbo.EXW_FactConversions.sql`

```sql
CREATE TABLE [EXW_dbo].[EXW_FactConversions]
(
	[ConversionID] [bigint] NULL,
	[CorrelationID] [uniqueidentifier] NULL,
	[RequestTime] [datetime] NULL,
	[FromWalletId] [uniqueidentifier] NULL,
	[FromAddress] [nvarchar](512) NULL,
	[SendingGCID] [bigint] NULL,
	[RequestedFromAmount] [numeric](38, 8) NULL,
	[FromCryptoID] [int] NULL,
	[FromCrypto] [nvarchar](500) NULL,
	[ConversionStatus] [varchar](500) NULL,
	[ModificationTime] [datetime] NULL,
	[FromAmount] [numeric](38, 8) NULL,
	[ToEtoroEstimatedBCFee] [numeric](38, 8) NULL,
	[ToEtoroDate] [datetime] NULL,
	[ConversionID2] [bigint] NULL,
	[ToWalletId] [uniqueidentifier] NULL,
	[ToAddress] [nvarchar](512) NULL,
	[RecievingGCID] [bigint] NULL,
	[RequestedToAmount] [numeric](38, 8) NULL,
	[ToCryptoID] [int] NULL,
	[ToCrypto] [nvarchar](500) NULL,
	[ToAmount] [numeric](38, 8) NULL,
	[FromEtoroEstimatedBCFee] [numeric](38, 8) NULL,
	[FromEtoroDate] [datetime] NULL,
	[ToEtoroSentTXID] [bigint] NULL,
	[ToEtoroSentBlockchainTXID] [nvarchar](max) NULL,
	[FromEtoroSentTXID] [bigint] NULL,
	[FromEtoroSentBlockchainTXID] [nvarchar](max) NULL,
	[SentToEtoroWalletAmount] [numeric](38, 8) NULL,
	[SentToEtoroWalletEtoroFees] [numeric](38, 8) NULL,
	[SentToEtoroBlockchainFees] [numeric](38, 8) NULL,
	[SentFromEtoroWalletAmount] [numeric](38, 8) NULL,
	[SentFromEtoroWalletEtoroFees] [numeric](38, 8) NULL,
	[SentFromEtoroBlockchainFees] [numeric](38, 8) NULL,
	[ToEtoroReceivedTXID] [bigint] NULL,
	[ToEtoroReceivedAmount] [numeric](38, 8) NULL,
	[ToEtoroReceiveBlockchainFee] [numeric](38, 8) NULL,
	[FromEtoroReceivedTXID] [bigint] NULL,
	[FromEtoroReceivedAmount] [numeric](38, 8) NULL,
	[FromEtoroReceiveBlockchainFee] [numeric](38, 8) NULL,
	[ReceivedTime] [datetime] NULL,
	[UpdateDate] [datetime] NULL,
	[FromBlockchainCryptoId] [int] NULL,
	[FromBlockchainCryptoName] [nvarchar](500) NULL,
	[ToBlockchainCryptoId] [int] NULL,
	[ToBlockchainCryptoName] [nvarchar](500) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [SendingGCID] ),
	HEAP
)

GO

```

---

## Upstream Wikis Found

Found 2 upstream wiki(s). Read EACH one in full.


### Upstream `Wallet.Conversions` — production
- **Resolved as**: `WalletDB.Wallet.Conversions`
- **Wiki path**: `C:\Users\guyman\Documents\github\CryptoDBs\WalletDB\Wiki\Wallet\Tables\Wallet.Conversions.md`

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


### Upstream `Wallet.ConversionTransactions` — production
- **Resolved as**: `WalletDB.Wallet.ConversionTransactions`
- **Wiki path**: `C:\Users\guyman\Documents\github\CryptoDBs\WalletDB\Wiki\Wallet\Tables\Wallet.ConversionTransactions.md`

# Wallet.ConversionTransactions

> Stores the per-leg transaction details of crypto-to-crypto conversions, recording the exchange rate, destination address, amounts, and fees for each side of the swap.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC (1 unique) + 1 clustered PK |

---

## 1. Business Meaning

This table stores the detailed execution parameters for each leg of a crypto conversion. A typical conversion has two legs: one for the crypto being sold (outgoing) and one for the crypto being purchased (incoming). Each row records the exchange rate, destination address, amount, and fee details for one leg. FK to both `Wallet.Conversions` and `Wallet.Wallets`/`Wallet.CryptoTypes`.

---

## 2. Business Logic

### 2.1 Dual-Leg Conversion Execution

**What**: Each conversion produces two transaction records - one per leg of the swap.

**Columns/Parameters Involved**: `ConversionId`, `WalletId`, `CryptoId`, `Amount`

**Rules**:
- Unique constraint on (ConversionId, WalletId, CryptoId) ensures one record per wallet-crypto per conversion
- The sell leg records the amount leaving the source wallet
- The buy leg records the amount entering the destination wallet
- CryptoRateUsd captures the USD price at execution time for valuation

---

## 3. Data Overview

N/A for transaction detail table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | ConversionId | bigint | NO | - | VERIFIED | Parent conversion. FK to Wallet.Conversions.Id. Part of unique constraint. |
| 3 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet for this conversion leg. FK to Wallet.Wallets.WalletId. Part of unique constraint. |
| 4 | CryptoRateUsd | decimal(36,18) | NO | - | CODE-BACKED | USD exchange rate of this crypto at execution time. Used for valuation and fee calculation. |
| 5 | ToAddress | nvarchar(512) | YES | - | CODE-BACKED | Destination blockchain address for this conversion leg. NULL when the transfer is internal. |
| 6 | Amount | decimal(36,18) | NO | - | VERIFIED | Amount of crypto for this conversion leg in native units. |
| 7 | EtoroFeePercentage | decimal(5,2) | YES | - | CODE-BACKED | eToro fee percentage applied to this leg. |
| 8 | EtoroFeeCalculated | decimal(36,18) | YES | - | CODE-BACKED | Calculated eToro fee amount in the crypto's native units. |
| 9 | EstimatedBlockChainFee | decimal(36,18) | NO | - | CODE-BACKED | Estimated blockchain network fee for this leg. |
| 10 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of this transaction record creation. |
| 11 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency for this leg. FK to Wallet.CryptoTypes.CryptoID. Part of unique constraint. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ConversionId | Wallet.Conversions | FK | Parent conversion |
| WalletId | Wallet.Wallets | FK | Wallet for this leg |
| CryptoId | Wallet.CryptoTypes | FK | Crypto for this leg |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertConversionTransaction | - | Writer | Creates transaction records |
| Wallet.GetConversionTransaction | - | Reader | Reads conversion details |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.ConversionTransactions (table)
├── Wallet.Conversions (table)
├── Wallet.Wallets (table)
└── Wallet.CryptoTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Conversions | Table | FK target for ConversionId |
| Wallet.Wallets | Table | FK target for WalletId |
| Wallet.CryptoTypes | Table | FK target for CryptoId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertConversionTransaction | Stored Procedure | Inserts records |
| Wallet.GetConversionTransaction | Stored Procedure | Reads records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ConversionTransactions | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...ConversionId_WalletId_CryptoId | NC UNIQUE | ConversionId, WalletId, CryptoId | - | - | Active |
| IX_...WalletId_CryptoId_Occurred | NC | WalletId, CryptoId, Occurred DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Occurred | DEFAULT | getutcdate() |
| FK_...ConversionId | FK | -> Wallet.Conversions.Id |
| FK_...CryptoId | FK | -> Wallet.CryptoTypes.CryptoID |
| FK_...WalletId | FK | -> Wallet.Wallets.WalletId |

---

## 8. Sample Queries

### 8.1 Get both legs of a conversion
```sql
SELECT ct.ConversionId, c.Name AS Crypto, ct.Amount, ct.CryptoRateUsd, ct.EtoroFeeCalculated
FROM Wallet.ConversionTransactions ct WITH (NOLOCK)
JOIN Wallet.CryptoTypes c WITH (NOLOCK) ON ct.CryptoId = c.CryptoID
WHERE ct.ConversionId = 50268
```

### 8.2 Conversion fees analysis
```sql
SELECT TOP 20 ct.ConversionId, c.Name AS Crypto, ct.Amount, ct.EtoroFeePercentage, ct.EtoroFeeCalculated
FROM Wallet.ConversionTransactions ct WITH (NOLOCK)
JOIN Wallet.CryptoTypes c WITH (NOLOCK) ON ct.CryptoId = c.CryptoID
WHERE ct.EtoroFeeCalculated > 0
ORDER BY ct.Id DESC
```

### 8.3 Conversion volume for a wallet
```sql
SELECT c.Name AS Crypto, COUNT(*) AS LegCount, SUM(ct.Amount) AS TotalAmount
FROM Wallet.ConversionTransactions ct WITH (NOLOCK)
JOIN Wallet.CryptoTypes c WITH (NOLOCK) ON ct.CryptoId = c.CryptoID
WHERE ct.WalletId = '6CAC2E99-10D8-41F1-A684-D24B3CB4AF9F'
GROUP BY c.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ConversionTransactions | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ConversionTransactions.sql*


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `Wallet.Conversions` | production | Wallet | Conversions | `C:\Users\guyman\Documents\github\CryptoDBs\WalletDB\Wiki\Wallet\Tables\Wallet.Conversions.md` |
| `Wallet.ConversionTransactions` | production | Wallet | ConversionTransactions | `C:\Users\guyman\Documents\github\CryptoDBs\WalletDB\Wiki\Wallet\Tables\Wallet.ConversionTransactions.md` |
| `EXW_Wallet.CryptoTypes` | unresolved | EXW_Wallet | CryptoTypes | `—` |
