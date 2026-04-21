# EXW_dbo.External_WalletDB_Wallet_TransactionsView

> Synapse external table providing a Parquet-backed read-only projection of WalletDB.Wallet.TransactionsView — the unified crypto transaction log combining all sent and received transaction types (redemptions, conversions, payments, staking, and others). Data resides in the Bronze ADLS layer at Bronze/WalletDB/Wallet/TransactionsView. Contains all 22 columns of the source view including fees, statuses, blockchain addresses, and transaction classification. Primary staging source for SP_EXW_Fact_Transactions which builds EXW_FactTransactions.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | External Table (Synapse External Table — Parquet) |
| **Production Source** | WalletDB.Wallet.TransactionsView → Bronze ADLS Parquet |
| **Refresh** | Generic Pipeline (ADF/CopyFromLake) — Override strategy, every 60 minutes |
| **Synapse Distribution** | N/A (External Table) |
| **Synapse Index** | N/A (External Table — no indexes) |
| **Data Source** | `[internal-sources]` |
| **Location** | `Bronze/WalletDB/Wallet/TransactionsView` |
| **File Format** | SynapseParquetFormat |
| **UC Target** | `wallet.bronze_walletdb_wallet_transactionsview` |

---

## 1. Business Meaning

`External_WalletDB_Wallet_TransactionsView` is the Synapse EXW schema's window into the WalletDB transaction log. It exposes data exported from `Wallet.TransactionsView` — the unified CTE-based view that combines all sent transaction types (redemptions, conversions, payments, staking, other) with received transactions.

As an external table, it does not store data in Synapse — it reads Parquet files written to the Bronze ADLS layer by the data ingestion pipeline. This makes it a zero-copy staging layer: the data exists once in ADLS and is read by Synapse on demand.

As of last refresh: 4,711,074 rows; 284,614 distinct GCIDs; TransDate range 2018-04-23 to 2026-04-20 (live). Action split: Received 53% / Sent 47%. TransStatus: Verified (99.7%), WavedError (0.2%), Pending/Error/Timeout (<0.1%). Transaction types: Redeem (24%), CustomerMoneyOut (17.5%), Funding (1.7%), Conversions (2%), Payment (0.5%), other types.

The external table is the **primary input** for `SP_EXW_Fact_Transactions`, which reads all transactions for a given date from this table, enriches them with CryptoTypes (for InstrumentID and USD pricing), AML validation results, and classification flags (IsRedeem, IsConversion, IsPayment, IsFunding), and writes the enriched result to `EXW_dbo.EXW_FactTransactions`. Also consumed by SP_EXW_Transactions_Monthly, SP_EXW_Hourly, SP_EXW_FactRedeemTransactions, SP_EXW_UserCalculatedBalance.

The 22 columns exactly mirror `Wallet.TransactionsView`. Type differences are minimal — `WalletId` is `uniqueidentifier` in WalletDB but `nvarchar(4000)` in the Parquet/external table representation. `ActionTypeName` preserves the legacy misspelling `'Recive'` from the source view.

---

## 2. Business Logic

### 2.1 CTE-Based Transaction Source

**What**: The underlying `Wallet.TransactionsView` (and therefore this external table) combines 7 CTEs into a unified output.

**Columns Involved**: `TransactionTypeId`, `ActionTypeId`, `ActionTypeName`

**Rules**:
- `ActionTypeId = 1` (Sent): redemptions (types 0, 8), conversions (5, 6), payments (7), staking (9), other types
- `ActionTypeId = 2` (Received): incoming transactions from external senders
- `ActionTypeName`: hardcoded `'Sent'` or `'Recive'` (legacy misspelling preserved in source)
- `TransactionTypeId` is NULL for received transactions (type applies to sent only)

### 2.2 Fee Structure by Transaction Type

**What**: Fees are sourced differently depending on transaction type; all are consolidated in this view.

**Columns Involved**: `EtoroFees`, `ProviderFees`, `FeeExchangeRate`, `BlockchainFee`, `EffectiveBlockchainFee`

**Rules**:
- Redemptions (0, 8): EtoroFees from Wallet.Redemptions; BlockchainFee counted once via ROW_NUMBER
- Conversions (6): EtoroFees from ConversionTransactions with cross-currency rate; FeeExchangeRate = CryptoRateUsd / target CryptoRateUsd
- Payments (7): EtoroFees and ProviderFees from PaymentTransactions; FeeExchangeRate = 1/ExchangeRate
- Staking (9): EtoroFees from Staking.StakingTransactions; EffectiveBlockchainFee = BlockchainEstFee
- Received: All fee columns are NULL

### 2.3 Status Resolution

**What**: Latest status is resolved via correlated subquery at the source view level.

**Columns Involved**: `TransStatusId`, `TransStatus`, `LastStatusUpdateOccurred`

**Rules**:
- `TransStatusId = SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC` (most recent)
- `LastStatusUpdateOccurred = SELECT TOP 1 Occurred FROM *Statuses ORDER BY Id DESC`
- Valid TransStatus values: Pending, Verified, Error, Done, Cancelled, NeedsApproval (from Dictionary.TransactionStatus in WalletDB)

---

## 3. Query Advisory

### 3.1 External Table Query Considerations

External tables are read from ADLS Parquet — not from Synapse storage. There are no distribution keys or indexes. Performance depends on Parquet file size and predicate pushdown. Filter by date range using `TransDate` or `Occurred` to limit data scanned.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All transactions for a date | `SELECT * FROM EXW_dbo.External_WalletDB_Wallet_TransactionsView WHERE TransDate = '2024-01-15'` |
| Sent transactions for a customer | `WHERE gcid = @gcid AND ActionTypeId = 1` |
| Received transactions | `WHERE gcid = @gcid AND ActionTypeId = 2` |
| Redemptions only | `WHERE TransactionTypeId IN (0, 8)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_FactTransactions | `TranID + ActionTypeId` | Compare enriched DWH version vs raw source |
| EXW_Wallet.CryptoTypes | `CryptoId` | Crypto asset metadata |

### 3.4 Gotchas

- **`ReciverAddress` is a legacy misspelling**: The column is spelled `ReciverAddress` (not `ReceiverAddress`) in both the WalletDB source view and this external table. This is preserved for backward compatibility.
- **`WalletId` is nvarchar(4000) here, uniqueidentifier in WalletDB**: Parquet serializes the GUID as a string. Cast as needed for join compatibility.
- **Self-transaction filtering in the source**: `Wallet.TransactionsView` excludes self-sends and self-receives (wallet sends to its own address). This external table inherits that filter.
- **No indexes**: Full table scan for every query. Always apply date filters.
- **`ActionTypeName` typo**: `'Recive'` (ActionTypeId=2) is a known legacy misspelling in WalletDB. Do not correct — downstream systems depend on it.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (Wallet.TransactionsView) — all columns pass through unchanged from the documented view |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | gcid | bigint | NOT NULL | Global Customer ID of the wallet owner. Resolved in the source view by joining to Wallet.Wallets via WalletId. gcid=0 indicates omnibus/system wallets. (Tier 1 — Wallet.TransactionsView) |
| 2 | CryptoId | int | NOT NULL | The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID in WalletDB. (Tier 1 — Wallet.TransactionsView) |
| 3 | WalletId | nvarchar(4000) | NOT NULL | The wallet involved in this transaction. Serialized from uniqueidentifier in WalletDB to nvarchar in Parquet. From Wallet.SentTransactions.WalletId or Wallet.ReceivedTransactions.WalletId. (Tier 1 — Wallet.TransactionsView) |
| 4 | TranID | bigint | NOT NULL | Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types — combine with ActionTypeId to distinguish sent from received. (Tier 1 — Wallet.TransactionsView) |
| 5 | TransStatusId | int | NOT NULL | Latest status ID — resolved via correlated subquery on status history tables. FK to Dictionary.TransactionStatus in WalletDB. (Tier 1 — Wallet.TransactionsView) |
| 6 | TransStatus | nvarchar(4000) | NOT NULL | Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval. Also observed in live data: WavedError (error state that has been manually waived). (Tier 1 — Wallet.TransactionsView) |
| 7 | TransDate | datetime2 | NOT NULL | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. (Tier 1 — Wallet.TransactionsView) |
| 8 | Amount | numeric(36,18) | NULL | Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for 'other' types. (Tier 1 — Wallet.TransactionsView) |
| 9 | EtoroFees | numeric(36,18) | NULL | eToro platform fees. Source varies by type: Redemptions→eToroFeeAmount, ConversionOut→EtoroFeeCalculated, Payments→EtoroFeeCalculated, Staking→EtoroFee, Other→SentTransactionOutputs.EtoroFees. NULL for received transactions. (Tier 1 — Wallet.TransactionsView) |
| 10 | ProviderFees | numeric(36,18) | NULL | External provider fees. Only populated for Payment transactions (type 7) from Wallet.PaymentTransactions.ProviderFeeCalculated. NULL for all other types. (Tier 1 — Wallet.TransactionsView) |
| 11 | FeeExchangeRate | numeric(38,6) | NULL | Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for received transactions. (Tier 1 — Wallet.TransactionsView) |
| 12 | BlockchainFee | numeric(36,18) | NULL | Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for received transactions. (Tier 1 — Wallet.TransactionsView) |
| 13 | EffectiveBlockchainFee | numeric(37,18) | NULL | Estimated/effective blockchain fee. Redemptions: EstimatedBlockchainFee+InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for received transactions. (Tier 1 — Wallet.TransactionsView) |
| 14 | ActionTypeId | int | NOT NULL | Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block in the source view. (Tier 1 — Wallet.TransactionsView) |
| 15 | ActionTypeName | nvarchar(4000) | NOT NULL | Human-readable direction: 'Sent' or 'Recive' (legacy misspelling of 'Receive' preserved for backward compatibility across all dependent systems). (Tier 1 — Wallet.TransactionsView) |
| 16 | SenderAddress | nvarchar(4000) | NULL | Sender's blockchain address. Sends: from WalletPool.PublicAddress (wallet's own address). Receives: from ReceivedTransactions.SenderAddress (external sender). (Tier 1 — Wallet.TransactionsView) |
| 17 | ReciverAddress | nvarchar(4000) | NULL | Receiver's blockchain address. Legacy misspelling 'Reciver' preserved from source. Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress. (Tier 1 — Wallet.TransactionsView) |
| 18 | BlockchainTransactionId | nvarchar(4000) | NULL | On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions. (Tier 1 — Wallet.TransactionsView) |
| 19 | TransactionTypeId | int | NULL | Sent transaction type. Core types: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. Also observed in live data: 1=CustomerMoneyOut, 2=AmlMoneyBack, 4=Funding, 10=BlockChainActivation, 11=OmnibusMoneyOut, 12=ConversionToFiat, 13=ManualUserMoneyOut, 14=StakeAndRewardsRefund, 15=CustomerMoneyBack. NULL for received transactions. FK to Dictionary.TransactionTypes in WalletDB. (Tier 1 — Wallet.TransactionsView) |
| 20 | TransactionType | nvarchar(4000) | NULL | Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions. (Tier 1 — Wallet.TransactionsView) |
| 21 | Occurred | datetime2 | NOT NULL | When the transaction record was created in the WalletDB database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. (Tier 1 — Wallet.TransactionsView) |
| 22 | LastStatusUpdateOccurred | datetime2 | NULL | Timestamp of the most recent status change. Resolved via correlated subquery on status history tables. Enables SLA tracking and "time since last update" monitoring. (Tier 1 — Wallet.TransactionsView) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| All 22 columns | Wallet.TransactionsView | Same column names | Parquet passthrough (type differences: WalletId uniqueidentifier→nvarchar) |

### 5.2 ETL Pipeline

```
WalletDB (SQL Server)
    └─ Wallet.TransactionsView (22-column unified transaction view)
        └─ Bronze Pipeline (Databricks/ADF)
            └─ ADLS Gen2: Bronze/WalletDB/Wallet/TransactionsView (Parquet)
                └─ EXW_dbo.External_WalletDB_Wallet_TransactionsView (Synapse External Table)
                    └─ SP_EXW_Fact_Transactions (@d DATE) → EXW_dbo.EXW_FactTransactions
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| All columns | Wallet.TransactionsView | Source view in WalletDB; this external table is its Bronze Parquet projection |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| EXW_dbo.SP_EXW_Fact_Transactions | All columns | Primary input — SELECT by date → builds EXW_FactTransactions |
| EXW_dbo.SP_EXW_Transactions_Monthly | All columns | Monthly transaction aggregation |
| EXW_dbo.SP_EXW_Hourly | All columns | Hourly transaction metrics |
| EXW_dbo.SP_EXW_FactRedeemTransactions | TransactionTypeId, TranID | Redemption transaction detail |
| EXW_dbo.SP_EXW_UserCalculatedBalance | gcid, Amount, ActionTypeId | User balance calculation |

---

## 7. Sample Queries

### 7.1 Recent transactions for a wallet customer
```sql
SELECT TranID, ActionTypeName, TransStatus, Amount, CryptoId, TransactionType, Occurred
FROM EXW_dbo.External_WalletDB_Wallet_TransactionsView
WHERE gcid = 9661239
  AND Occurred >= DATEADD(day, -7, GETDATE())
ORDER BY Occurred DESC
```

### 7.2 Daily redemption volume
```sql
SELECT CAST(TransDate AS date) AS TranDate, CryptoId, COUNT(*) AS TxCount, SUM(Amount) AS TotalAmount
FROM EXW_dbo.External_WalletDB_Wallet_TransactionsView
WHERE TransactionTypeId IN (0, 8)   -- Redeem, RedeemAsic
  AND ActionTypeId = 1
  AND TransDate >= '2024-01-01'
GROUP BY CAST(TransDate AS date), CryptoId
ORDER BY TranDate DESC, TotalAmount DESC
```

### 7.3 Transactions with AML status pending (from status view)
```sql
SELECT TranID, gcid, CryptoId, Amount, TransStatus, LastStatusUpdateOccurred
FROM EXW_dbo.External_WalletDB_Wallet_TransactionsView
WHERE TransStatus = 'NeedsApproval'
ORDER BY LastStatusUpdateOccurred DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object in the EXW_dbo context. The underlying Wallet.TransactionsView is documented in the CryptoDBs/WalletDB wiki and referenced in Confluence "Crypto IN" initiative documentation.

---

*Generated: 2026-04-20 (updated from 2026-04-19) | Quality: 8.1/10 (P16 adversarial: 8.05) | Phases: 14/14*
*Tiers: 22 T1, 0 T2, 0 T3, 0 T4, 0 T5 | Elements: 22/22*
*Object: EXW_dbo.External_WalletDB_Wallet_TransactionsView | Type: External Table | Production Source: WalletDB.Wallet.TransactionsView*
