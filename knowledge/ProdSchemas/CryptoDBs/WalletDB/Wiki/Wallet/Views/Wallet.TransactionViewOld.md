# Wallet.TransactionViewOld

> Legacy unified transaction view combining sent and received transactions across six transaction types (CustomerMoneyOut, AmlMoneyBack, Funding, Redemptions, Conversions, Payments) into a single queryable surface with fees, statuses, and blockchain details.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | View |
| **Key Identifier** | TranID (bigint, from SentTransactions.Id or ReceivedTransactions.Id) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view is the predecessor of Wallet.TransactionsView, providing a unified view of all wallet transaction activity - both outgoing (sent) and incoming (received). It combines six different sent transaction types (CustomerMoneyOut, AmlMoneyBack, Funding, Redeem, ConversionMoneyIn, ConversionMoneyOut, Payment) with received transactions into a single output, resolving the customer's GCID, blockchain addresses, fee breakdowns, and transaction statuses.

This view exists as a legacy abstraction that was replaced by Wallet.TransactionsView, which adds support for staking transactions and uses CTE-based architecture instead of direct UNIONs. The "Old" suffix confirms it is deprecated. No stored procedures or other views in the SSDT reference it, indicating it has been fully superseded.

The view reads directly from base tables (Wallets, WalletPool, WalletAssets, SentTransactions, SentTransactionOutputs, SentTransactionStatuses, Redemptions, Conversions, ConversionTransactions, Payments, PaymentTransactions, ReceivedTransactions, ReceivedTransactionStatuses, WalletAddresses) and cross-schema Dictionary tables (TransactionStatus, TransactionTypes). Fees are calculated differently per transaction type - redemptions use eToroFeeAmount, conversions use EtoroFeeCalculated with cross-rate calculation, and payments use both EtoroFeeCalculated and ProviderFeeCalculated.

---

## 2. Business Logic

### 2.1 Transaction Type Routing

**What**: Different sent transaction types have different fee structures and JOIN paths, requiring separate UNION blocks.

**Columns/Parameters Involved**: `TransactionTypeId`, `ActionTypeId`, `ActionTypeName`

**Rules**:
- Block 1 (TransactionTypeId IN 1, 2, 4): CustomerMoneyOut, AmlMoneyBack, Funding - simple fee from outputs, filters out self-sends via NormalizedToAddress check
- Block 2 (TransactionTypeId IN 0, 8): Redeem, RedeemAsic - fees from Redemptions table, ROW_NUMBER partitions blockchain fees across outputs
- Block 3 (TransactionTypeId = 5): ConversionMoneyIn - zero EtoroFees, fees from ConversionTransactions
- Block 4 (TransactionTypeId = 6): ConversionMoneyOut - fees with cross-currency exchange rate calculation (ctf.CryptoRateUsd / ctt.CryptoRateUsd)
- Block 5 (TransactionTypeId = 7): Payment - fees from PaymentTransactions with exchange rate
- Block 6: Received transactions - separate structure with no fees, ActionTypeId=2
- ActionTypeId: 1=Sent, 2=Recive (note: intentional legacy misspelling "Recive")

**Diagram**:
```
Wallet.TransactionViewOld
+-- UNION: Sent Transactions (ActionTypeId=1)
|   +-- Block 1: CustomerMoneyOut / AmlMoneyBack / Funding (types 1,2,4)
|   +-- Block 2: Redeem / RedeemAsic (types 0,8)
|   +-- Block 3: ConversionMoneyIn (type 5)
|   +-- Block 4: ConversionMoneyOut (type 6)
|   +-- Block 5: Payment (type 7)
|   +-- JOIN Dictionary.TransactionStatus -> TransStatus
|   +-- LEFT JOIN Dictionary.TransactionTypes -> TransactionType
+-- UNION ALL: Received Transactions (ActionTypeId=2)
    +-- JOIN Dictionary.TransactionStatus -> TransStatus
    +-- Filter: exclude self-receives (NormalizedSenderAddress != own addresses)
```

### 2.2 Self-Transaction Filtering

**What**: The view excludes transactions where a wallet sends to or receives from itself.

**Columns/Parameters Involved**: `NormalizedToAddress`, `NormalizedSenderAddress`, `WalletAddresses`

**Rules**:
- Sent: `NormalizedToAddress NOT IN (SELECT NormalizedAddress FROM WalletAddresses WHERE WalletId = st.WalletId)` - excludes change outputs
- Received: `NormalizedSenderAddress NOT IN (SELECT NormalizedAddress FROM WalletAddresses WHERE WalletId = rt.WalletId)` - excludes self-deposits
- This ensures only externally meaningful transactions appear in the unified view

### 2.3 Fee Exchange Rate Calculation

**What**: For conversion transactions, fees are denominated in different cryptos and require exchange rate normalization.

**Columns/Parameters Involved**: `FeeExchangeRate`, `EtoroFees`, `ProviderFees`

**Rules**:
- ConversionMoneyOut (type 6): `FeeExchangeRate = ctf.CryptoRateUsd / NULLIF(ctt.CryptoRateUsd, 0)` - converts fee from source crypto to destination crypto
- Payment (type 7): `FeeExchangeRate = 1 / pt.ExchangeRate` - inverts the payment exchange rate
- Other types: `FeeExchangeRate = 1` (same currency, no conversion needed)

---

## 3. Data Overview

| TranID | gcid | CryptoId | ActionTypeName | TransStatus | Amount | BlockchainTransactionId (truncated) | Meaning |
|---|---|---|---|---|---|---|---|
| 105414 | 3386714 | 2 (ETH) | Recive | Verified | 0.1 | 0x88bfd3a1ab... | A verified incoming ETH transaction. No fees on receives. SenderAddress shows the external source. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | gcid | bigint | NO | - | VERIFIED | Global Customer ID of the wallet owner. Resolved by joining SentTransactions/ReceivedTransactions -> Wallets.Gcid. From Wallet.Wallets.Gcid. |
| 2 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency of this transaction. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId. FK to Wallet.CryptoTypes.CryptoID. |
| 3 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId. |
| 4 | TranID | bigint | NO | - | CODE-BACKED | Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique - must be combined with ActionTypeId to distinguish. |
| 5 | TransStatusId | int | NO | - | CODE-BACKED | Latest status ID from SentTransactionStatuses or ReceivedTransactionStatuses. Resolved via correlated subquery (TOP 1 ORDER BY Id DESC). FK to Dictionary.TransactionStatus. |
| 6 | TransStatus | nvarchar | NO | - | CODE-BACKED | Human-readable status name resolved from Dictionary.TransactionStatus. Values include: Pending, Verified, Error, Done, Cancelled, NeedsApproval. |
| 7 | TransDate | datetime2(7) | NO | - | CODE-BACKED | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate (the on-chain timestamp). |
| 8 | Amount | decimal | YES | - | VERIFIED | Transaction amount in native crypto units. For sends: from SentTransactionOutputs.Amount. For receives: from ReceivedTransactions.Amount. ISNULL wrapper for "other" types defaults to 0. |
| 9 | EtoroFees | decimal | YES | - | CODE-BACKED | eToro platform fees. Source varies by type: Redemptions -> eToroFeeAmount, ConversionOut -> EtoroFeeCalculated, Payments -> EtoroFeeCalculated, other sends -> from SentTransactionOutputs.EtoroFees. NULL for received transactions. |
| 10 | ProviderFees | decimal | YES | - | CODE-BACKED | External provider fees (fiat payment provider). Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types. |
| 11 | FeeExchangeRate | decimal | YES | - | CODE-BACKED | Exchange rate for converting fees between crypto currencies. ConversionOut: source/dest USD rate ratio. Payment: inverse of payment exchange rate. Others: 1 (same currency). NULL for receives. |
| 12 | BlockchainFee | decimal | YES | - | CODE-BACKED | Actual blockchain network fee (gas/miner fee) in the transaction's native crypto. For redemptions: only counted once per transaction (ROW_NUMBER=1 gets the fee, others get 0). From SentTransactions.BlockchainFee. NULL for receives. |
| 13 | EffectiveBlockchainFee | decimal | YES | - | CODE-BACKED | The estimated/effective blockchain fee used for fee calculation. For redemptions: EstimatedBlockchainFee + InitialFeeAmount. For conversions: from ConversionTransactions.EstimatedBlockChainFee. For payments: from PaymentTransactions.EstimatedBlockChainFee. NULL for receives. |
| 14 | ActionTypeId | int | NO | - | CODE-BACKED | Direction of the transaction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded in each UNION block. |
| 15 | ActionTypeName | nvarchar | NO | - | CODE-BACKED | Human-readable direction label: 'Sent' or 'Recive' (legacy misspelling of "Receive" preserved for backward compatibility). |
| 16 | SenderAddress | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address of the sender. For sends: resolved from WalletPool.PublicAddress (the wallet's own address). For receives: from ReceivedTransactions.SenderAddress (external sender). |
| 17 | ReciverAddress | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address of the receiver (legacy misspelling "Reciver"). For sends: from SentTransactionOutputs.ToAddress. For receives: from ReceivedTransactions.ReceiverAddress. |
| 18 | BlockchainTransactionId | nvarchar | YES | - | CODE-BACKED | The on-chain transaction hash/ID. Unique identifier on the blockchain. From SentTransactions.BlockchainTransactionId or ReceivedTransactions.BlockchainTransactionId. |
| 19 | TransactionTypeId | int | YES | - | VERIFIED | Categorizes the sent transaction type: 0=Redeem, 1=CustomerMoneyOut, 2=AmlMoneyBack, 4=Funding, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic. NULL for received transactions. FK to Dictionary.TransactionTypes. |
| 20 | TransactionType | nvarchar | YES | - | CODE-BACKED | Human-readable transaction type name resolved from Dictionary.TransactionTypes. NULL for received transactions. |
| 21 | Occurred | datetime2(7) | NO | - | CODE-BACKED | When the transaction was recorded in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletId | Wallet.Wallets | JOIN | Resolves Gcid (customer) for each transaction |
| WalletId | Wallet.WalletPool | JOIN | Resolves SenderAddress for sent transactions |
| WalletId | Wallet.WalletAssets | JOIN | Filters to active assets for sent transactions |
| TranID (sent) | Wallet.SentTransactions | Source | Sent transaction details |
| TranID (sent) | Wallet.SentTransactionOutputs | JOIN | Output amounts and addresses |
| TranID (sent) | Wallet.SentTransactionStatuses | Subquery | Latest status resolution |
| TranID (received) | Wallet.ReceivedTransactions | Source | Received transaction details |
| TranID (received) | Wallet.ReceivedTransactionStatuses | Subquery | Latest status resolution |
| CorrelationId | Wallet.Redemptions | JOIN | Redemption-specific fees (types 0, 8) |
| CorrelationId | Wallet.Conversions | JOIN | Conversion correlation (types 5, 6) |
| ConversionId | Wallet.ConversionTransactions | JOIN | Conversion fees and exchange rates |
| CorrelationId | Wallet.Payments | JOIN | Payment correlation (type 7) |
| PaymentId | Wallet.PaymentTransactions | JOIN | Payment fees and exchange rates |
| TransStatusId | Dictionary.TransactionStatus | JOIN | Status name resolution |
| TransactionTypeId | Dictionary.TransactionTypes | LEFT JOIN | Transaction type name resolution |
| NormalizedToAddress | Wallet.WalletAddresses | Subquery | Self-send filtering |

### 5.2 Referenced By (other objects point to this)

No stored procedures, views, or functions in the SSDT reference this view. It has been superseded by Wallet.TransactionsView.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.TransactionViewOld (view, LEGACY)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionOutputs (table)
+-- Wallet.SentTransactionStatuses (table)
+-- Wallet.Wallets (table)
+-- Wallet.WalletPool (table)
+-- Wallet.WalletAssets (table)
+-- Wallet.Redemptions (table)
+-- Wallet.Conversions (table)
+-- Wallet.ConversionTransactions (table)
+-- Wallet.Payments (table)
+-- Wallet.PaymentTransactions (table)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.ReceivedTransactionStatuses (table)
+-- Wallet.WalletAddresses (table)
+-- Dictionary.TransactionStatus (table, cross-schema)
+-- Dictionary.TransactionTypes (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | Source of outgoing transactions |
| Wallet.SentTransactionOutputs | Table | Transaction output amounts and addresses |
| Wallet.SentTransactionStatuses | Table | Latest status per transaction |
| Wallet.Wallets | Table | Resolves customer Gcid |
| Wallet.WalletPool | Table | Resolves sender blockchain address |
| Wallet.WalletAssets | Table | Asset filter for sent transactions |
| Wallet.Redemptions | Table | Redemption fees and amounts |
| Wallet.Conversions | Table | Conversion correlation |
| Wallet.ConversionTransactions | Table | Conversion fees and exchange rates |
| Wallet.Payments | Table | Payment correlation |
| Wallet.PaymentTransactions | Table | Payment fees and exchange rates |
| Wallet.ReceivedTransactions | Table | Source of incoming transactions |
| Wallet.ReceivedTransactionStatuses | Table | Latest status for received transactions |
| Wallet.WalletAddresses | Table | Self-transaction filtering |
| Dictionary.TransactionStatus | Table (cross-schema) | Status name lookup |
| Dictionary.TransactionTypes | Table (cross-schema) | Transaction type name lookup |

### 6.2 Objects That Depend On This

No dependents found. Superseded by Wallet.TransactionsView.

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
SELECT TranID, ActionTypeName, TransStatus, Amount, CryptoId, TransactionType, Occurred
FROM Wallet.TransactionViewOld WITH (NOLOCK)
WHERE gcid = 3386714
ORDER BY Occurred DESC
```

### 8.2 Find a specific blockchain transaction
```sql
SELECT gcid, CryptoId, Amount, ActionTypeName, EtoroFees, BlockchainFee
FROM Wallet.TransactionViewOld WITH (NOLOCK)
WHERE BlockchainTransactionId = '0x88bfd3a1ab8c2bf9c6516948ecdc2879aed517b09b822efeec7f896262d5d207'
```

### 8.3 Summarize transaction volume by type
```sql
SELECT
    ISNULL(TransactionType, 'Receive') AS TxType,
    ActionTypeName,
    COUNT(*) AS TxCount,
    SUM(Amount) AS TotalAmount
FROM Wallet.TransactionViewOld WITH (NOLOCK)
WHERE Occurred >= DATEADD(day, -7, GETDATE())
GROUP BY TransactionType, ActionTypeName
ORDER BY TxCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.TransactionViewOld | Type: View | Source: WalletDB/Wallet/Views/Wallet.TransactionViewOld.sql*
