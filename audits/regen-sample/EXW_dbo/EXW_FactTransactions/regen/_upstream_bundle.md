# Pre-Resolved Upstream Bundle for `EXW_dbo.EXW_FactTransactions`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_dbo.EXW_FactTransactions.sql`

```sql
CREATE TABLE [EXW_dbo].[EXW_FactTransactions]
(
	[GCID] [int] NULL,
	[RealCID] [int] NULL,
	[CryptoId] [int] NULL,
	[CryptoName] [nvarchar](500) NULL,
	[InstrumentID] [bigint] NULL,
	[WalletID] [nvarchar](max) NULL,
	[TranID] [bigint] NULL,
	[TranStatusID] [int] NULL,
	[TranStatus] [nvarchar](500) NULL,
	[TranDate] [date] NULL,
	[TranDateID] [bigint] NULL,
	[Amount] [numeric](38, 8) NULL,
	[EtoroFees] [numeric](38, 8) NULL,
	[ProviderFees] [numeric](38, 8) NULL,
	[FeeExchangeRate] [numeric](38, 8) NULL,
	[BlockchainFees] [numeric](38, 8) NULL,
	[EstimatedBlockchainFee] [numeric](38, 8) NULL,
	[ActionTypeID] [int] NULL,
	[ActionTypeName] [nvarchar](500) NULL,
	[AmountUSD] [numeric](38, 8) NULL,
	[EtoroFeesUSD] [numeric](38, 8) NULL,
	[BlockchainFeesUSD] [numeric](38, 8) NULL,
	[EstimatedBlockchainFeesUSD] [numeric](38, 8) NULL,
	[UpdateDate] [datetime] NULL,
	[SenderAddress] [nvarchar](512) NULL,
	[ReciverAddress] [nvarchar](max) NULL,
	[AMLProviderStatus] [varchar](500) NULL,
	[AMLIsPositiveDecision] [int] NULL,
	[IsEtoroFee] [int] NULL,
	[BlockchainTransactionId] [nvarchar](max) NULL,
	[TransactionTypeID] [int] NULL,
	[TransactionType] [varchar](64) NULL,
	[IsRedeem] [int] NULL,
	[IsConversion] [int] NULL,
	[IsPayment] [int] NULL,
	[BlockchainCryptoId] [int] NULL,
	[BlockchainCryptoName] [nvarchar](500) NULL,
	[Occurred] [datetime] NULL,
	[IsFunding] [int] NULL,
	[IsEtoroHandlingFee] [int] NULL,
	[TranDateTime] [datetime] NULL,
	[DateOccured] [date] NULL,
	[LastStatusUpdateOccurred] [datetime] NULL,
	[ReceivedTransactionTypeID] [int] NULL,
	[ReceivedTransactionType] [varchar](64) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [GCID] ),
	HEAP
)

GO

```

---

## Upstream Wikis Found

Found 1 upstream wiki(s). Read EACH one in full.


### Upstream `Wallet.TransactionsView` — production
- **Resolved as**: `WalletDB.Wallet.TransactionsView`
- **Wiki path**: `C:\Users\guyman\Documents\github\CryptoDBs\WalletDB\Wiki\Wallet\Views\Wallet.TransactionsView.md`

# Wallet.TransactionsView

> Comprehensive unified transaction view combining all sent transaction types (redemptions, conversions, payments, staking, and other) with received transactions into a single CTE-based queryable interface with fees, statuses, blockchain details, and customer context. Active replacement for TransactionViewOld.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | View |
| **Key Identifier** | TranID (bigint, from SentTransactions.Id or ReceivedTransactions.Id) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view is the current unified transaction view for the eToro crypto wallet platform, combining all sent and received transactions into a single denormalized output. It replaces the legacy Wallet.TransactionViewOld by adding staking transaction support (TransactionTypeId=9), an "other" catch-all for new types, the LastStatusUpdateOccurred column, and a more maintainable CTE-based architecture.

Without this view, querying a customer's full transaction history would require writing separate queries against multiple transaction tables (SentTransactions, ReceivedTransactions, Redemptions, Conversions, Payments, Staking) and manually unioning them with different fee calculation logic. The view provides a single point of access for all transaction types.

The view is structured as 7 CTEs (redeem_transactions, conversion_in_transactions, conversion_out_transactions, payment_transactions, staking_transactions, other_transactions, received_transactions) that are unioned together, then enriched with the sender address from WalletPool, status name from Dictionary.TransactionStatus, customer Gcid from Wallets, and type name from Dictionary.TransactionTypes. Used by Monitoring.GetAlertValuePerCrypto and referenced in MonitorTeam permissions.

---

## 2. Business Logic

### 2.1 CTE-Based Transaction Routing

**What**: Each sent transaction type has its own CTE with type-specific fee logic, then all CTEs are unioned.

**Columns/Parameters Involved**: `TransactionTypeId`, `ActionTypeId`, `ActionTypeName`

**Rules**:
- `redeem_transactions` (types 0, 8): Redeem/RedeemAsic - fees from Wallet.Redemptions (eToroFeeAmount, EstimatedBlockchainFee + InitialFeeAmount). ROW_NUMBER partitions blockchain fee across outputs
- `conversion_in_transactions` (type 5): ConversionMoneyIn - zero eToro fees, blockchain fee from SentTransactions
- `conversion_out_transactions` (type 6): ConversionMoneyOut - fees from ConversionTransactions with cross-currency exchange rate: ctf.CryptoRateUsd / NULLIF(ctt.CryptoRateUsd, 0)
- `payment_transactions` (type 7): Payment - fees from PaymentTransactions (EtoroFeeCalculated, ProviderFeeCalculated, 1/ExchangeRate)
- `staking_transactions` (type 9): Staking - fees from Staking.StakingTransactions (EtoroFee, BlockchainEstFee). Cross-schema dependency to Staking schema
- `other_transactions` (types NOT IN 0,5,6,7,8,9): Catch-all for CustomerMoneyOut, AmlMoneyBack, Funding, and future types. Fees from SentTransactionOutputs. Filters out self-sends via NormalizedToAddress check
- `received_transactions`: All incoming - no fees, ActionTypeId=2. Filters out self-receives via NormalizedSenderAddress check

**Diagram**:
```
Wallet.TransactionsView
+-- CTE: redeem_transactions (types 0,8) -> Redemptions fees
+-- CTE: conversion_in_transactions (type 5) -> zero eToro fees
+-- CTE: conversion_out_transactions (type 6) -> cross-rate fees
+-- CTE: payment_transactions (type 7) -> payment provider fees
+-- CTE: staking_transactions (type 9) -> staking fees [NEW]
+-- CTE: other_transactions (all others) -> output-level fees
|
+-- UNION ALL -> trx_out1
    +-- JOIN WalletPool -> SenderAddress
    +-- JOIN Dictionary.TransactionStatus -> TransStatus
    = trx_out (ActionTypeId=1, 'Sent')
|
+-- CTE: received_transactions
    +-- JOIN Dictionary.TransactionStatus -> TransStatus
    = (ActionTypeId=2, 'Recive')
|
+-- UNION ALL -> union_trx
    +-- JOIN Wallets -> Gcid
    +-- LEFT JOIN Dictionary.TransactionTypes -> TransactionType
    = final_view (22 columns)
```

### 2.2 Self-Transaction Filtering

**What**: The view excludes transactions where a wallet sends to or receives from its own addresses.

**Columns/Parameters Involved**: `NormalizedToAddress`, `NormalizedSenderAddress`, `WalletAddresses`

**Rules**:
- Sent (other_transactions CTE): `NormalizedToAddress NOT IN (SELECT NormalizedAddress FROM WalletAddresses WHERE WalletId = st.WalletId)` - excludes change outputs and self-sends
- Received: `NormalizedSenderAddress NOT IN (SELECT NormalizedAddress FROM WalletAddresses WHERE WalletId = rt.WalletId)` - excludes self-deposits
- This ensures only externally meaningful transactions appear

### 2.3 Status Resolution Pattern

**What**: Transaction statuses are resolved via correlated subqueries against the status history tables.

**Columns/Parameters Involved**: `TransStatusId`, `LastStatusUpdateOccurred`

**Rules**:
- `TransStatusId = (SELECT TOP 1 StatusId FROM *Statuses WHERE *Id = Id ORDER BY Id DESC)` - gets the most recent status
- `LastStatusUpdateOccurred = (SELECT TOP 1 Occurred FROM *Statuses WHERE *Id = Id ORDER BY Id DESC)` - timestamp of last status change
- This pattern is used for both sent and received transactions

---

## 3. Data Overview

| TranID | gcid | CryptoId | ActionTypeName | TransStatus | Amount | TransactionType | Occurred | Meaning |
|---|---|---|---|---|---|---|---|---|
| 300007 | 0 | 2 (ETH) | Sent | Verified | 0.318099 | Redeem | 2020-08-07 | A verified ETH redemption from an omnibus wallet (Gcid=0). Funds sent from the system wallet as part of a user withdrawal. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | gcid | bigint | NO | - | VERIFIED | Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid. |
| 2 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId. |
| 3 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId. |
| 4 | TranID | bigint | NO | - | CODE-BACKED | Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish. |
| 5 | TransStatusId | int | NO | - | CODE-BACKED | Latest status ID. Resolved via correlated subquery: `SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC`. FK to Dictionary.TransactionStatus. |
| 6 | TransStatus | nvarchar | NO | - | CODE-BACKED | Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval. |
| 7 | TransDate | datetime2(7) | NO | - | CODE-BACKED | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. |
| 8 | Amount | decimal | YES | - | VERIFIED | Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for "other" types. |
| 9 | EtoroFees | decimal | YES | - | CODE-BACKED | eToro platform fees. Source varies: Redemptions -> eToroFeeAmount, ConversionOut -> EtoroFeeCalculated, Payments -> EtoroFeeCalculated, Staking -> EtoroFee, Other -> SentTransactionOutputs.EtoroFees. NULL for receives. |
| 10 | ProviderFees | decimal | YES | - | CODE-BACKED | External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types. |
| 11 | FeeExchangeRate | decimal | YES | - | CODE-BACKED | Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives. |
| 12 | BlockchainFee | decimal | YES | - | CODE-BACKED | Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives. |
| 13 | EffectiveBlockchainFee | decimal | YES | - | CODE-BACKED | Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives. |
| 14 | ActionTypeId | int | NO | - | CODE-BACKED | Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block. |
| 15 | ActionTypeName | nvarchar | NO | - | CODE-BACKED | Human-readable direction: 'Sent' or 'Recive' (legacy misspelling preserved for backward compatibility). |
| 16 | SenderAddress | nvarchar(512) | YES | - | CODE-BACKED | Sender's blockchain address. Sends: from WalletPool.PublicAddress (wallet's own address). Receives: from ReceivedTransactions.SenderAddress (external sender). |
| 17 | ReciverAddress | nvarchar(512) | YES | - | CODE-BACKED | Receiver's blockchain address (legacy misspelling "Reciver"). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress. |
| 18 | BlockchainTransactionId | nvarchar | YES | - | CODE-BACKED | On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions. |
| 19 | TransactionTypeId | int | YES | - | VERIFIED | Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes. |
| 20 | TransactionType | nvarchar | YES | - | CODE-BACKED | Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions. |
| 21 | Occurred | datetime2(7) | NO | - | CODE-BACKED | When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. |
| 22 | LastStatusUpdateOccurred | datetime2(7) | YES | - | CODE-BACKED | Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables "time since last update" monitoring and SLA tracking. New in this version (not in TransactionViewOld). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletId | Wallet.SentTransactions | Source | Outgoing transaction details |
| WalletId | Wallet.SentTransactionOutputs | JOIN | Output amounts, addresses, fees |
| StatusId | Wallet.SentTransactionStatuses | Subquery | Latest sent status |
| WalletId | Wallet.ReceivedTransactions | Source | Incoming transaction details |
| StatusId | Wallet.ReceivedTransactionStatuses | Subquery | Latest received status |
| CorrelationId | Wallet.Redemptions | JOIN | Redemption fees (types 0, 8) |
| CorrelationId | Wallet.Conversions | JOIN | Conversion correlation (types 5, 6) |
| ConversionId | Wallet.ConversionTransactions | JOIN | Conversion fees and rates |
| CorrelationId | Wallet.Payments | JOIN | Payment correlation (type 7) |
| PaymentId | Wallet.PaymentTransactions | JOIN | Payment fees and rates |
| CorrelationId | Staking.Staking | JOIN (cross-schema) | Staking correlation (type 9) |
| StakingId | Staking.StakingTransactions | JOIN (cross-schema) | Staking fees |
| WalletId | Wallet.Wallets | JOIN | Customer Gcid resolution |
| WalletId | Wallet.WalletPool | JOIN | Sender address resolution |
| NormalizedAddress | Wallet.WalletAddresses | Subquery | Self-transaction filtering |
| TransStatusId | Dictionary.TransactionStatus | JOIN (cross-schema) | Status name lookup |
| TransactionTypeId | Dictionary.TransactionTypes | LEFT JOIN (cross-schema) | Type name lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Monitoring.GetAlertValuePerCrypto | Procedure | READER | Reads transaction data for crypto alert monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.TransactionsView (view)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionOutputs (table)
+-- Wallet.SentTransactionStatuses (table)
+-- Wallet.Redemptions (table)
+-- Wallet.Conversions (table)
+-- Wallet.ConversionTransactions (table)
+-- Wallet.Payments (table)
+-- Wallet.PaymentTransactions (table)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.ReceivedTransactionStatuses (table)
+-- Wallet.Wallets (table)
+-- Wallet.WalletPool (table)
+-- Wallet.WalletAddresses (table)
+-- Staking.Staking (table, cross-schema)
+-- Staking.StakingTransactions (table, cross-schema)
+-- Dictionary.TransactionStatus (table, cross-schema)
+-- Dictionary.TransactionTypes (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | Source of all outgoing transactions |
| Wallet.SentTransactionOutputs | Table | Transaction output details |
| Wallet.SentTransactionStatuses | Table | Status history |
| Wallet.Redemptions | Table | Redemption fees |
| Wallet.Conversions | Table | Conversion correlation |
| Wallet.ConversionTransactions | Table | Conversion fees/rates |
| Wallet.Payments | Table | Payment correlation |
| Wallet.PaymentTransactions | Table | Payment fees/rates |
| Wallet.ReceivedTransactions | Table | Incoming transactions |
| Wallet.ReceivedTransactionStatuses | Table | Received status history |
| Wallet.Wallets | Table | Customer Gcid |
| Wallet.WalletPool | Table | Sender address |
| Wallet.WalletAddresses | Table | Self-send filtering |
| Staking.Staking | Table (cross-schema) | Staking correlation |
| Staking.StakingTransactions | Table (cross-schema) | Staking fees |
| Dictionary.TransactionStatus | Table (cross-schema) | Status names |
| Dictionary.TransactionTypes | Table (cross-schema) | Type names |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Monitoring.GetAlertValuePerCrypto | Procedure | Reads for alert threshold monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get recent transactions for a customer
```sql
SELECT TranID, ActionTypeName, TransStatus, Amount, CryptoId, TransactionType, Occurred, LastStatusUpdateOccurred
FROM Wallet.TransactionsView WITH (NOLOCK)
WHERE gcid = 9661239
  AND Occurred >= DATEADD(day, -30, GETDATE())
ORDER BY Occurred DESC
```

### 8.2 Find staking transactions
```sql
SELECT gcid, CryptoId, Amount, EtoroFees, EffectiveBlockchainFee, TransStatus
FROM Wallet.TransactionsView WITH (NOLOCK)
WHERE TransactionTypeId = 9
ORDER BY Occurred DESC
```

### 8.3 Transaction volume by type with resolved names
```sql
SELECT
    ISNULL(TransactionType, 'Receive') AS TxType,
    ActionTypeName,
    COUNT(*) AS TxCount,
    SUM(Amount) AS TotalAmount,
    SUM(ISNULL(EtoroFees, 0)) AS TotalEtoroFees
FROM Wallet.TransactionsView WITH (NOLOCK)
WHERE Occurred >= DATEADD(day, -7, GETDATE())
GROUP BY TransactionType, ActionTypeName
ORDER BY TxCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.TransactionsView | Type: View | Source: WalletDB/Wallet/Views/Wallet.TransactionsView.sql*


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `Wallet.TransactionsView` | production | Wallet | TransactionsView | `C:\Users\guyman\Documents\github\CryptoDBs\WalletDB\Wiki\Wallet\Views\Wallet.TransactionsView.md` |
