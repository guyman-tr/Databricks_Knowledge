# EXW_dbo.EXW_FactTransactions

> 4.7M-row crypto wallet transaction fact table tracking every sent and received blockchain transaction from April 2018 to present across 128 cryptocurrencies and 285K customers. Sourced daily from WalletDB Wallet.TransactionsView via SP_EXW_Fact_Transactions, enriched with AML screening, USD pricing, and customer dimension lookups. Incrementally refreshed by date (DELETE+INSERT by TranID+ActionTypeID).

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.TransactionsView via SP_EXW_Fact_Transactions |
| **Refresh** | Daily incremental (per-date @d parameter, DELETE+INSERT by TranID+ActionTypeID) |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_FactTransactions is the core crypto wallet transaction fact table in the EXW (eToroX/Wallet) schema. It contains 4.7M rows spanning April 2018 to April 2026, covering 128 distinct cryptocurrencies and approximately 285K unique customers (by GCID).

Each row represents a single blockchain transaction — either sent (ActionTypeID=1) or received (ActionTypeID=2). The table captures the full lifecycle: transaction amounts in native crypto and USD, platform fees (eToro fees, provider fees, blockchain fees) both in native and USD, AML screening results, blockchain addresses, and transaction classification flags (IsRedeem, IsConversion, IsPayment, IsFunding).

The ETL runs daily via SP_EXW_Fact_Transactions with a date parameter (@d). It reads from External_WalletDB_Wallet_TransactionsView (an external table mapped to WalletDB's Wallet.TransactionsView), enriches with AML data from EXW_Wallet.AmlValidations, crypto metadata from EXW_Wallet.CryptoTypes, USD pricing from EXW_Wallet.EXW_Price, and RealCID from DWH_dbo.Dim_Customer. The load pattern is DELETE+INSERT keyed on TranID+ActionTypeID, allowing status updates to refresh existing rows.

In 2026 YTD data: ~70% received vs 30% sent transactions. Most transactions (99.8%) are in Verified status. Sent types include CustomerMoneyOut (41%), Redeem (40%), and ConversionToFiat (18%).

---

## 2. Business Logic

### 2.1 Transaction Direction Partitioning

**What**: The SP processes sent and received transactions in separate UNION ALL branches with different enrichment logic.

**Columns Involved**: `ActionTypeID`, `ActionTypeName`

**Rules**:
- ActionTypeID=1 ('Sent'): outgoing transactions with AML lookup via CorrelationId (sent path), TransactionTypeID populated, ReceivedTransactionTypeID set to NULL
- ActionTypeID=2 ('Recive'): incoming transactions with AML lookup via BlockchainTransactionId+WalletId, TransactionTypeID from the view, ReceivedTransactionTypeID from EXW_Wallet.ReceivedTransactions

### 2.2 Fee Currency Conversion

**What**: EtoroFees in this table are pre-multiplied by FeeExchangeRate, unlike the raw view where they are separate.

**Columns Involved**: `EtoroFees`, `FeeExchangeRate`

**Rules**:
- `EtoroFees = view.EtoroFees * view.FeeExchangeRate` — already converted to the transaction's native crypto denomination
- This differs from Wallet.TransactionsView where EtoroFees and FeeExchangeRate are stored separately

### 2.3 USD Conversion

**What**: Native crypto amounts and fees are converted to USD using EXW_Wallet.EXW_Price date-range pricing.

**Columns Involved**: `AmountUSD`, `EtoroFeesUSD`, `BlockchainFeesUSD`, `EstimatedBlockchainFeesUSD`

**Rules**:
- USD columns = native amount * AvgPrice where AvgPrice is from EXW_Price matched by CryptoId and date range (TransDate BETWEEN DateFrom AND DateTo)
- If no price match, USD columns will be NULL

### 2.4 Transaction Classification Flags

**What**: Four boolean flags classify transactions by business type, computed via CASE logic combining sent TransactionTypeID and received ReceivedTransactionTypeID.

**Columns Involved**: `IsRedeem`, `IsConversion`, `IsPayment`, `IsFunding`

**Rules**:
- `IsRedeem=1`: Sent types 0,8 OR Received types 2,7 OR received side matched to a sent redeem via BlockchainTransactionId
- `IsConversion=1`: Sent types 5,6 OR Received types 4,5
- `IsPayment=1`: Sent type 7 OR Received type 6
- `IsFunding=1`: Sent type 4 OR Received type 3
- Flags are mutually exclusive by sent TransactionTypeID but a received transaction could theoretically match multiple flags

### 2.5 AML Enrichment

**What**: AML screening results are joined from EXW_Wallet.AmlValidations, using the most recent validation per transaction.

**Columns Involved**: `AMLProviderStatus`, `AMLIsPositiveDecision`

**Rules**:
- Sent transactions: matched by CorrelationId via SentTransactions (TransactionTypeId=1 only), IsSend=1, ROW_NUMBER=1 (latest by Created)
- Received transactions: matched by BlockchainTransactionId+WalletId, IsSend=0, ROW_NUMBER=1 (latest by Created)
- Values: Green (approved), Amber (review needed), Red (rejected), Error (system failure), NULL (not screened)

### 2.6 Blockchain Crypto Resolution

**What**: The underlying blockchain cryptocurrency may differ from the token's CryptoId (e.g., ERC-20 tokens run on the ETH blockchain).

**Columns Involved**: `BlockchainCryptoId`, `BlockchainCryptoName`

**Rules**:
- Resolved via two-hop lookup: CryptoTypes[CryptoId] → BlockchainCryptoId → CryptoTypes[BlockchainCryptoId].Name
- When CryptoId == BlockchainCryptoId, the token is native to its own blockchain

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH(GCID) — optimized for customer-centric queries. JOINs to other GCID-distributed tables (e.g., EXW_DimUser) benefit from co-located distribution.
- **Index**: HEAP — no clustered index. Full table scans on date-filtered queries; use TranDate or DateOccured in WHERE clauses.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer transaction history | `WHERE GCID = @gcid ORDER BY TranDate DESC` |
| Daily transaction volume | `WHERE TranDate = @date GROUP BY ActionTypeName` |
| Redeem transactions only | `WHERE IsRedeem = 1 AND ActionTypeID = 1` for sent redeems |
| USD value by crypto | `GROUP BY CryptoName` with `SUM(AmountUSD)` — filter by TranDate range |
| AML flagged transactions | `WHERE AMLProviderStatus IN ('Amber','Red')` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_DimUser | GCID = GCID | Customer details |
| DWH_dbo.Dim_Customer | GCID = GCID or RealCID = RealCID | Full customer dimension |
| DWH_dbo.Dim_Date | TranDateID = DateID | Calendar attributes |

### 3.4 Gotchas

- **TranID is NOT globally unique** — combine with ActionTypeID to distinguish sent vs received. Same TranID can appear for both ActionTypeID=1 and ActionTypeID=2.
- **'Recive' is intentional** — legacy misspelling preserved from Wallet.TransactionsView for backward compatibility. Do not "fix" it.
- **'ReciverAddress' is intentional** — same legacy misspelling.
- **EtoroFees is pre-converted** — already multiplied by FeeExchangeRate. Unlike the source view, this is NOT the raw fee amount. Do not multiply again.
- **IsEtoroFee is always NULL** — hardcoded NULL in the SP. Column exists but carries no data.
- **DateOccured has one 'r'** — intentional spelling (`Occured` not `Occurred`). The Occurred column (datetime) uses standard spelling.
- **ReceivedTransactionTypeID/Type are NULL for sent** — only populated for ActionTypeID=2.
- **TransactionTypeID is NULL for received** in early data — the upstream view's TransactionTypeId is NULL for received transactions by design.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream wiki (Wallet.TransactionsView or Dim_Customer) |
| Tier 2 | Description derived from SP code analysis (ETL-computed or enrichment lookup) |
| Tier 3 | No traceable upstream; described from DDL + data evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid. (Tier 1 — Wallet.TransactionsView) |
| 2 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer via GCID lookup. (Tier 1 — Customer.CustomerStatic) |
| 3 | CryptoId | int | YES | The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId. (Tier 1 — Wallet.TransactionsView) |
| 4 | CryptoName | nvarchar(500) | YES | Cryptocurrency display name from EXW_Wallet.CryptoTypes.Name. Resolved by CryptoId lookup. Values include BTC, ETH, XRP, XLM, LTC, etc. (Tier 2 — SP_EXW_Fact_Transactions, EXW_Wallet.CryptoTypes) |
| 5 | InstrumentID | bigint | YES | eToro platform instrument identifier for the cryptocurrency. Resolved from EXW_Wallet.CryptoTypes.InstrumentId by CryptoId lookup. Maps crypto to the trading platform instrument. (Tier 2 — SP_EXW_Fact_Transactions, EXW_Wallet.CryptoTypes) |
| 6 | WalletID | nvarchar(max) | YES | The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId. (Tier 1 — Wallet.TransactionsView) |
| 7 | TranID | bigint | YES | Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish. (Tier 1 — Wallet.TransactionsView) |
| 8 | TranStatusID | int | YES | Latest status ID. Resolved via correlated subquery: `SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC`. FK to Dictionary.TransactionStatus. (Tier 1 — Wallet.TransactionsView) |
| 9 | TranStatus | nvarchar(500) | YES | Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval. (Tier 1 — Wallet.TransactionsView) |
| 10 | TranDate | date | YES | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. (Tier 1 — Wallet.TransactionsView) |
| 11 | TranDateID | bigint | YES | ETL-computed date integer in YYYYMMDD format derived from TranDate. CAST(CONVERT(VARCHAR(8), TransDate, 112) AS INT). Used for JOIN to Dim_Date. (Tier 2 — SP_EXW_Fact_Transactions) |
| 12 | Amount | numeric(38,8) | YES | Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for "other" types. (Tier 1 — Wallet.TransactionsView) |
| 13 | EtoroFees | numeric(38,8) | YES | eToro platform fees pre-multiplied by FeeExchangeRate in the SP. DWH note: computed as view.EtoroFees * view.FeeExchangeRate, unlike the source view where these are separate columns. (Tier 2 — SP_EXW_Fact_Transactions) |
| 14 | ProviderFees | numeric(38,8) | YES | External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types. (Tier 1 — Wallet.TransactionsView) |
| 15 | FeeExchangeRate | numeric(38,8) | YES | Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives. (Tier 1 — Wallet.TransactionsView) |
| 16 | BlockchainFees | numeric(38,8) | YES | Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives. (Tier 1 — Wallet.TransactionsView) |
| 17 | EstimatedBlockchainFee | numeric(38,8) | YES | Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives. (Tier 1 — Wallet.TransactionsView) |
| 18 | ActionTypeID | int | YES | Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block. (Tier 1 — Wallet.TransactionsView) |
| 19 | ActionTypeName | nvarchar(500) | YES | Human-readable direction: 'Sent' or 'Recive' (legacy misspelling preserved for backward compatibility). (Tier 1 — Wallet.TransactionsView) |
| 20 | AmountUSD | numeric(38,8) | YES | Transaction amount converted to USD. ETL-computed: Amount * AvgPrice from EXW_Wallet.EXW_Price matched by CryptoId and date range. (Tier 2 — SP_EXW_Fact_Transactions) |
| 21 | EtoroFeesUSD | numeric(38,8) | YES | eToro fees converted to USD. ETL-computed: EtoroFees (post-conversion) * AvgPrice from EXW_Wallet.EXW_Price. (Tier 2 — SP_EXW_Fact_Transactions) |
| 22 | BlockchainFeesUSD | numeric(38,8) | YES | Blockchain network fee converted to USD. ETL-computed: BlockchainFee * AvgPrice from EXW_Wallet.EXW_Price. (Tier 2 — SP_EXW_Fact_Transactions) |
| 23 | EstimatedBlockchainFeesUSD | numeric(38,8) | YES | Estimated blockchain fee converted to USD. ETL-computed: EstimatedBlockchainFee * AvgPrice from EXW_Wallet.EXW_Price. (Tier 2 — SP_EXW_Fact_Transactions) |
| 24 | UpdateDate | datetime | YES | Timestamp of when the row was last inserted/refreshed in Synapse. ETL-computed: GETDATE() at INSERT time. (Tier 2 — SP_EXW_Fact_Transactions) |
| 25 | SenderAddress | nvarchar(512) | YES | Sender's blockchain address. Sends: from WalletPool.PublicAddress (wallet's own address). Receives: from ReceivedTransactions.SenderAddress (external sender). (Tier 1 — Wallet.TransactionsView) |
| 26 | ReciverAddress | nvarchar(max) | YES | Receiver's blockchain address (legacy misspelling "Reciver"). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress. (Tier 1 — Wallet.TransactionsView) |
| 27 | AMLProviderStatus | varchar(500) | YES | AML screening provider status from EXW_Wallet.AmlValidations. Most recent validation per transaction. Values: Green, Amber, Red, Error. NULL if not screened. (Tier 2 — SP_EXW_Fact_Transactions, EXW_Wallet.AmlValidations) |
| 28 | AMLIsPositiveDecision | int | YES | AML positive decision flag from EXW_Wallet.AmlValidations. 1=positive (approved), 0=negative. NULL if not screened. Paired with AMLProviderStatus from the same validation record. (Tier 2 — SP_EXW_Fact_Transactions, EXW_Wallet.AmlValidations) |
| 29 | IsEtoroFee | int | YES | Hardcoded NULL in SP_EXW_Fact_Transactions. Column exists in the DDL but is never populated. (Tier 2 — SP_EXW_Fact_Transactions) |
| 30 | BlockchainTransactionId | nvarchar(max) | YES | On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions. (Tier 1 — Wallet.TransactionsView) |
| 31 | TransactionTypeID | int | YES | Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes. (Tier 1 — Wallet.TransactionsView) |
| 32 | TransactionType | varchar(64) | YES | Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions. (Tier 1 — Wallet.TransactionsView) |
| 33 | IsRedeem | int | YES | ETL-computed redemption flag. Sent: 1 when TransactionTypeID IN (0,8). Received: 1 when ReceivedTransactionTypeID IN (2,7) or blockchain match to a sent redeem. 0 otherwise. (Tier 2 — SP_EXW_Fact_Transactions) |
| 34 | IsConversion | int | YES | ETL-computed conversion flag. Sent: 1 when TransactionTypeID IN (5,6). Received: 1 when ReceivedTransactionTypeID IN (4,5). 0 otherwise. (Tier 2 — SP_EXW_Fact_Transactions) |
| 35 | IsPayment | int | YES | ETL-computed payment flag. Sent: 1 when TransactionTypeID=7. Received: 1 when ReceivedTransactionTypeID=6. 0 otherwise. (Tier 2 — SP_EXW_Fact_Transactions) |
| 36 | BlockchainCryptoId | int | YES | Underlying blockchain cryptocurrency ID. Resolved from EXW_Wallet.CryptoTypes.BlockchainCryptoId by CryptoId lookup. Differs from CryptoId for tokens running on another chain (e.g., ERC-20 tokens have BlockchainCryptoId pointing to ETH). (Tier 2 — SP_EXW_Fact_Transactions, EXW_Wallet.CryptoTypes) |
| 37 | BlockchainCryptoName | nvarchar(500) | YES | Name of the underlying blockchain cryptocurrency. Resolved via two-hop lookup: CryptoTypes[CryptoId].BlockchainCryptoId → CryptoTypes[BlockchainCryptoId].Name. (Tier 2 — SP_EXW_Fact_Transactions, EXW_Wallet.CryptoTypes) |
| 38 | Occurred | datetime | YES | When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. (Tier 1 — Wallet.TransactionsView) |
| 39 | IsFunding | int | YES | ETL-computed funding flag. Sent: 1 when TransactionTypeID=4. Received: 1 when ReceivedTransactionTypeID=3. 0 otherwise. (Tier 2 — SP_EXW_Fact_Transactions) |
| 40 | IsEtoroHandlingFee | int | YES | Whether this cryptocurrency carries an eToro handling fee. Resolved from EXW_Wallet.CryptoTypes.IsEtoroHandlingFee by CryptoId lookup. Property of the crypto type, not the individual transaction. (Tier 2 — SP_EXW_Fact_Transactions, EXW_Wallet.CryptoTypes) |
| 41 | TranDateTime | datetime | YES | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. DWH note: identical to TranDate source (TransDate from the view) but stored as datetime instead of date. (Tier 1 — Wallet.TransactionsView) |
| 42 | DateOccured | date | YES | When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. DWH note: CAST of Occurred to DATE, dropping the time component. Intentional misspelling 'Occured'. (Tier 1 — Wallet.TransactionsView) |
| 43 | LastStatusUpdateOccurred | datetime | YES | Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables "time since last update" monitoring and SLA tracking. New in this version (not in TransactionViewOld). (Tier 1 — Wallet.TransactionsView) |
| 44 | ReceivedTransactionTypeID | int | YES | Received transaction type identifier from EXW_Wallet.ReceivedTransactions.ReceivedTransactionTypeId. NULL for sent transactions (ActionTypeID=1). Used in CASE logic for IsRedeem, IsConversion, IsPayment, IsFunding flags. (Tier 2 — SP_EXW_Fact_Transactions, EXW_Wallet.ReceivedTransactions) |
| 45 | ReceivedTransactionType | varchar(64) | YES | Human-readable received transaction type name from CopyFromLake.WalletDB_Dictionary_ReceivedTransactionTypes. NULL for sent transactions. Values include MoneyIn, Redeem. (Tier 2 — SP_EXW_Fact_Transactions, CopyFromLake.WalletDB_Dictionary_ReceivedTransactionTypes) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| GCID | Wallet.TransactionsView | gcid | Passthrough |
| RealCID | Customer.CustomerStatic (via Dim_Customer) | RealCID | Dim-lookup via GCID |
| CryptoId | Wallet.TransactionsView | CryptoId | Passthrough |
| CryptoName | EXW_Wallet.CryptoTypes | Name | Lookup |
| InstrumentID | EXW_Wallet.CryptoTypes | InstrumentId | Lookup |
| WalletID | Wallet.TransactionsView | WalletId | Passthrough |
| TranID | Wallet.TransactionsView | TranID | Passthrough |
| TranStatusID | Wallet.TransactionsView | TransStatusId | Passthrough |
| TranStatus | Wallet.TransactionsView | TransStatus | Passthrough |
| TranDate | Wallet.TransactionsView | TransDate | Passthrough |
| TranDateID | — | TransDate | CONVERT to YYYYMMDD int |
| Amount | Wallet.TransactionsView | Amount | Passthrough |
| EtoroFees | Wallet.TransactionsView | EtoroFees * FeeExchangeRate | Computed |
| ProviderFees | Wallet.TransactionsView | ProviderFees | Passthrough |
| FeeExchangeRate | Wallet.TransactionsView | FeeExchangeRate | Passthrough |
| BlockchainFees | Wallet.TransactionsView | BlockchainFee | Passthrough (renamed) |
| EstimatedBlockchainFee | Wallet.TransactionsView | EffectiveBlockchainFee | Passthrough (renamed) |
| ActionTypeID | Wallet.TransactionsView | ActionTypeId | Passthrough |
| ActionTypeName | Wallet.TransactionsView | ActionTypeName | Passthrough |
| AmountUSD | — | Amount * AvgPrice | Computed |
| EtoroFeesUSD | — | EtoroFees * AvgPrice | Computed |
| BlockchainFeesUSD | — | BlockchainFee * AvgPrice | Computed |
| EstimatedBlockchainFeesUSD | — | EstimatedBlockchainFee * AvgPrice | Computed |
| UpdateDate | — | GETDATE() | Computed |
| SenderAddress | Wallet.TransactionsView | SenderAddress | Passthrough |
| ReciverAddress | Wallet.TransactionsView | ReciverAddress | Passthrough |
| AMLProviderStatus | EXW_Wallet.AmlValidations | ProviderStatus | Latest by Created |
| AMLIsPositiveDecision | EXW_Wallet.AmlValidations | IsPositiveDecision | Latest by Created |
| IsEtoroFee | — | — | Hardcoded NULL |
| BlockchainTransactionId | Wallet.TransactionsView | BlockchainTransactionId | Passthrough |
| TransactionTypeID | Wallet.TransactionsView | TransactionTypeId | Passthrough |
| TransactionType | Wallet.TransactionsView | TransactionType | Passthrough |
| IsRedeem | — | CASE logic | Computed |
| IsConversion | — | CASE logic | Computed |
| IsPayment | — | CASE logic | Computed |
| BlockchainCryptoId | EXW_Wallet.CryptoTypes | BlockchainCryptoId | Lookup |
| BlockchainCryptoName | EXW_Wallet.CryptoTypes | Name (via chain) | Two-hop lookup |
| Occurred | Wallet.TransactionsView | Occurred | Passthrough |
| IsFunding | — | CASE logic | Computed |
| IsEtoroHandlingFee | EXW_Wallet.CryptoTypes | IsEtoroHandlingFee | Lookup |
| TranDateTime | Wallet.TransactionsView | TransDate | Passthrough (as datetime) |
| DateOccured | Wallet.TransactionsView | Occurred | CAST to DATE |
| LastStatusUpdateOccurred | Wallet.TransactionsView | LastStatusUpdateOccurred | Passthrough |
| ReceivedTransactionTypeID | EXW_Wallet.ReceivedTransactions | ReceivedTransactionTypeId | Enrichment |
| ReceivedTransactionType | WalletDB Dictionary | Name | Lookup |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.TransactionsView (production, WalletDB)
  |-- External Table: External_WalletDB_Wallet_TransactionsView
  v
#prep (date-filtered: TransDate, Occurred, LastStatusUpdateOccurred = @d)
  |-- + EXW_Wallet.AmlValidations (AML enrichment)
  |-- + EXW_Wallet.CryptoTypes (crypto name, InstrumentId, blockchain crypto)
  v
#ext (sent UNION ALL received, with AML + crypto metadata)
  |-- + EXW_Wallet.EXW_Price (USD conversion by CryptoId + date range)
  |-- + DWH_dbo.Dim_Customer (RealCID by GCID)
  v
#factTXPrep (USD amounts computed)
  |-- + EXW_Wallet.SentTransactions + #prep (redeem blockchain match for received)
  v
#final_Fact_Transactions (IsRedeem/IsConversion/IsPayment/IsFunding CASE flags)
  |-- DELETE + INSERT by TranID + ActionTypeID
  v
EXW_dbo.EXW_FactTransactions (4.7M rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | DWH_dbo.Dim_Customer | Customer dimension lookup for RealCID |
| CryptoId | EXW_Wallet.CryptoTypes | Cryptocurrency metadata |
| TranStatusID | Dictionary.TransactionStatus (via Wallet.TransactionsView) | Transaction status name |
| TransactionTypeID | Dictionary.TransactionTypes (via Wallet.TransactionsView) | Sent transaction type name |
| TranDateID | DWH_dbo.Dim_Date | Calendar dimension |
| ReceivedTransactionTypeID | CopyFromLake.WalletDB_Dictionary_ReceivedTransactionTypes | Received transaction type name |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SP_EXW_CompensationClosingCountries | etv alias | READER | Compensation and closing country analysis |
| SP_EXW_EthFeeSent_Blockchain | eft alias | READER | ETH fee analysis for blockchain transactions |
| SP_EXW_FinanceReportsBalancesNew | eft alias | READER | Finance balance reporting |
| SP_EXW_RedeemReconciliation | eft alias | READER | Redeem reconciliation (joins on TranID, ActionTypeID=2) |
| SP_EXW_WalletUsers_30_Days | eft alias | READER | 30-day wallet user activity |

---

## 7. Sample Queries

### 7.1 Customer transaction history with USD values
```sql
SELECT TranID, ActionTypeName, TranStatus, CryptoName, Amount, AmountUSD,
       TransactionType, TranDate, Occurred
FROM EXW_dbo.EXW_FactTransactions
WHERE GCID = 7715009
  AND TranDate >= '2026-01-01'
ORDER BY TranDate DESC
```

### 7.2 Daily transaction volume by type (2026)
```sql
SELECT TranDate, ActionTypeName,
       COUNT(*) AS TxCount,
       SUM(AmountUSD) AS TotalUSD,
       SUM(CASE WHEN IsRedeem = 1 THEN 1 ELSE 0 END) AS Redeems,
       SUM(CASE WHEN IsConversion = 1 THEN 1 ELSE 0 END) AS Conversions
FROM EXW_dbo.EXW_FactTransactions
WHERE TranDate >= '2026-01-01'
GROUP BY TranDate, ActionTypeName
ORDER BY TranDate DESC
```

### 7.3 AML flagged transactions by status
```sql
SELECT AMLProviderStatus, CryptoName,
       COUNT(*) AS TxCount,
       SUM(AmountUSD) AS TotalUSD
FROM EXW_dbo.EXW_FactTransactions
WHERE AMLProviderStatus IS NOT NULL
  AND TranDate >= '2026-01-01'
GROUP BY AMLProviderStatus, CryptoName
ORDER BY TxCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-27 | Quality: 8.5/10 | Phases: 12/14*
*Tiers: 22 T1, 23 T2, 0 T3, 0 T4, 0 T5 | Elements: 45/45, Logic: 9/10, Relationships: 8/10, Sources: 8/10*
*Object: EXW_dbo.EXW_FactTransactions | Type: Table | Production Source: WalletDB.Wallet.TransactionsView via SP_EXW_Fact_Transactions*
