# EXW_dbo.EXW_FactTransactions

> Enriched crypto transaction fact table for the EXW schema. Combines every wallet transaction (sent and received) from WalletDB.Wallet.TransactionsView with USD pricing, AML validation status, crypto metadata, customer ID resolution, and transaction-type classification flags. Primary source for EXW transaction analytics. 4,709,301 rows covering 2018-04-23 to 2026-04-19 (live; refreshed daily).

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Synapse Dedicated Pool) |
| **Production Source** | WalletDB.Wallet.TransactionsView → Bronze Parquet → External_WalletDB_Wallet_TransactionsView |
| **Refresh** | Daily incremental DELETE+INSERT via SP_EXW_Fact_Transactions (@d DATE) |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **Grain** | One row per transaction × action type (TranID + ActionTypeID) |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions` |

---

## 1. Business Meaning

`EXW_FactTransactions` is the central transaction fact table for EXW crypto analytics. Each row represents one transaction event from the eToro crypto wallet platform — either a sent transaction (redemption, conversion, payment, staking, funding, or other outgoing type) or a received transaction (inbound crypto transfer). A single on-chain transaction can appear as two rows: one for the sender (ActionTypeID=1) and one for the receiver (ActionTypeID=2).

As of last refresh: 4,709,301 rows; 284,567 distinct GCIDs; TranDate range 2018-04-23 to 2026-04-19 (live). Direction split: Received=2,496,494 (53%) / Sent=2,212,807 (47%). Transaction status: Verified (99.7%), WavedError (0.24%), Confirmed/Pending/Error (<0.1% combined). IsRedeem=47.9%, IsConversion=4.1%, IsFunding=2.0%, IsPayment=1.0%. UpdateDate = 2026-04-20 (SP ran today — actively refreshed).

SP_EXW_Fact_Transactions is called with a target date @d. It processes all transactions whose TranDate, Occurred, or LastStatusUpdateOccurred falls within [**@d**, **@d+1**). It DELETEs existing rows for those TranID+ActionTypeID combinations, then INSERTs freshly enriched rows. This ensures status updates and late-arriving transactions are refreshed correctly. As a result, a given TranDate row may be refreshed multiple times if subsequent status changes occur.

---

## 2. Business Logic

### 2.1 Transaction Classification Flags

**What**: Four binary flags classify each transaction into its business category.

**Columns Involved**: `IsRedeem`, `IsConversion`, `IsPayment`, `IsFunding`, `TransactionTypeID`, `ReceivedTransactionTypeID`, `ActionTypeID`

**Rules**:
- `IsRedeem = 1`:
  - Sent: `TransactionTypeID IN (0=Redeem, 8=RedeemAsic)`
  - Received: `ReceivedTransactionTypeID IN (2=Redeem, 7)` OR received transaction matches blockchain TX ID of a sent redemption (`#receivedredeems` lookup)
- `IsConversion = 1`:
  - Sent: `TransactionTypeID IN (5=ConversionMoneyIn, 6=ConversionMoneyOut)`
  - Received: `ReceivedTransactionTypeID IN (4=ConversionToEtoro, 5=ConversionFromEtoro)`
- `IsPayment = 1`:
  - Sent: `TransactionTypeID = 7 (Payment)`
  - Received: `ReceivedTransactionTypeID = 6 (Payment)`
- `IsFunding = 1`:
  - Sent: `TransactionTypeID = 4 (Funding)` — pool wallet pre-funding
  - Received: `ReceivedTransactionTypeID = 3`
- Flags are mutually exclusive in the data: a row is at most one type; ~45% of rows have all flags = 0 (e.g., CustomerMoneyOut, AmlMoneyBack, ManualUserMoneyOut, unclassified received)

### 2.2 EtoroFees Currency Normalization

**What**: EtoroFees in this table is NOT the raw platform fee from the source view. It is multiplied by FeeExchangeRate to normalize cross-currency conversion fees.

**Columns Involved**: `EtoroFees`, `FeeExchangeRate`

**Rules**:
- `EtoroFees = source.EtoroFees × CONVERT(FLOAT, source.FeeExchangeRate)`
- For most transaction types FeeExchangeRate = 1, so EtoroFees equals the raw source fee
- For ConversionOut (type 6): FeeExchangeRate = source CryptoRateUsd / destination CryptoRateUsd, so the fee is normalized to the destination crypto's value basis
- For Payment (type 7): FeeExchangeRate = 1/ExchangeRate
- **Caution**: Do NOT re-multiply EtoroFees by FeeExchangeRate — it has already been applied

### 2.3 AML Enrichment

**What**: AML provider decisions are joined from EXW_Wallet.AmlValidations. Join logic differs by direction.

**Columns Involved**: `AMLProviderStatus`, `AMLIsPositiveDecision`, `ActionTypeID`

**Rules**:
- **Sent transactions (ActionTypeID=1)**: AML joined via `CorrelationId` — but ONLY for `TransactionTypeId=1` (CustomerMoneyOut). Other sent types resolve AML through SentTransactions.CorrelationId but #amlsent is pre-filtered to TypeId=1 rows from SentTransactions
- **Received transactions (ActionTypeID=2)**: AML joined via `BlockchainTransactionId + WalletId`, most-recent `RnReceived=1`
- AML values: Green (clear), Amber (under review), Red (flagged), NA (not applicable), Error (provider error)
- NULL (~69% of rows) means no AML check was performed for this transaction

### 2.4 USD Pricing via EXW_Price

**What**: Native-currency amounts and fees are converted to USD using a daily price table.

**Columns Involved**: `AmountUSD`, `EtoroFeesUSD`, `BlockchainFeesUSD`, `EstimatedBlockchainFeesUSD`

**Rules**:
- `AmountUSD = Amount × AvgPrice` from `EXW_Wallet.EXW_Price`
- Join: `CryptoId = PE.CryptoID AND TransDate > PE.DateFrom AND TransDate <= PE.DateTo`
- NULL when no price record exists for the crypto+date combination
- Uses TranDate (the blockchain-assigned date), not Occurred, for price lookup

### 2.5 Received Transaction Type Enrichment

**What**: Received transactions (ActionTypeID=2) have an additional type classification from the received-transaction dictionary.

**Columns Involved**: `ReceivedTransactionTypeID`, `ReceivedTransactionType`, `ActionTypeID`

**Rules**:
- `ReceivedTransactionTypeID` from `EXW_Wallet.ReceivedTransactions.ReceivedTransactionTypeId` (LEFT JOIN on TranID=Id WHERE ActionTypeID=2)
- `ReceivedTransactionType` from `CopyFromLake.WalletDB_Dictionary_ReceivedTransactionTypes.Name`
- Values confirmed in live data: 1=MoneyIn (970K, 84.7%), 2=Redeem (174K, 15.2%), 5=ConversionFromEtoro, 6=Payment
- Both are NULL for all sent transactions (ActionTypeID=1)
- ~24% of received rows have a populated ReceivedTransactionTypeID; ~76% of received rows are NULL (not all received transactions are in the ReceivedTransactions table)

### 2.6 BlockchainCryptoId for ERC-20 Tokens

**What**: Some EXW cryptos are ERC-20 tokens on the Ethereum network. This field identifies the underlying blockchain asset.

**Columns Involved**: `BlockchainCryptoId`, `BlockchainCryptoName`, `CryptoId`

**Rules**:
- For native coins (BTC, ETH, XRP): `BlockchainCryptoId = CryptoId`, `BlockchainCryptoName = CryptoName`
- For ERC-20 stablecoins (USDEX, EURX, GBPX): `BlockchainCryptoId = 2 (ETH)`, `BlockchainCryptoName = 'ETH'`
- From `EXW_Wallet.CryptoTypes.BlockchainCryptoId` (inner join on CryptoId from CryptoTypes ct1, then Name from CryptoTypes ct2)

---

## 3. Query Advisory

### 3.1 Distribution and Join Strategy

Table is `HASH(GCID)`, co-distributed with other EXW_dbo tables on GCID. Single-customer queries are fast (single distribution). Cross-customer aggregations require broadcast/shuffle joins. HEAP index — no clustered index overhead.

### 3.2 Date Filtering

| Goal | Recommended Column |
|------|--------------------|
| Filter by transaction date | `TranDate` (date) or `TranDateTime` (datetime, same value) |
| Filter by occurrence timestamp | `Occurred` (when the TX record was created) |
| Filter by last status change | `LastStatusUpdateOccurred` |
| Integer date key join | `TranDateID` (yyyyMMdd int) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.External_WalletDB_Wallet_TransactionsView | `TranID + ActionTypeID` | Compare enriched vs raw source |
| DWH_dbo.Dim_Customer | `RealCID = Dim_Customer.RealCID` | Customer attributes (country, regulation) |
| EXW_dbo.EXW_WalletInventory | `GCID` | Wallet pool state |

### 3.4 Gotchas

- **EtoroFees is pre-multiplied**: `EtoroFees = source.EtoroFees × FeeExchangeRate`. Do not re-apply FeeExchangeRate.
- **TranID is not globally unique**: Combine `TranID + ActionTypeID` to distinguish sent from received rows for the same on-chain transaction.
- **IsEtoroFee is always NULL**: The column exists in the schema but is hardcoded to NULL in the SP; the flag logic was never activated.
- **DateOccured has a typo**: The column is `DateOccured` (not `DateOccurred`). This is preserved from the original schema.
- **AML data is sparse**: ~69% of rows have NULL AML fields. Do not filter by AML status unless specifically analyzing AML coverage.
- **ReciverAddress misspelling**: Preserved from WalletDB source (`ReciverAddress` not `ReceiverAddress`).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (Wallet.TransactionsView) — direct passthrough columns |
| Tier 2 | Derived from SP code — ETL-computed, joined, or renamed with type change |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NULL | Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid. DWH note: Renamed from gcid. Stored as int (bigint in source view). HASH distribution key. (Tier 1 — Wallet.TransactionsView) |
| 2 | RealCID | int | NULL | Platform-internal customer ID from DWH_dbo.Dim_Customer, joined on GCID. NULL for omnibus/system wallets (GCID=0) and customers not yet in Dim_Customer. Enables joins to DWH fact tables that key on RealCID. (Tier 2 — SP_EXW_Fact_Transactions via Dim_Customer) |
| 3 | CryptoId | int | NULL | The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId. (Tier 1 — Wallet.TransactionsView) |
| 4 | CryptoName | nvarchar(500) | NULL | Human-readable name of the cryptocurrency. From EXW_Wallet.CryptoTypes.Name, joined on CryptoId. E.g., 'BTC', 'ETH', 'XRP'. (Tier 2 — SP_EXW_Fact_Transactions via CryptoTypes) |
| 5 | InstrumentID | bigint | NULL | DWH instrument identifier for this cryptocurrency. From EXW_Wallet.CryptoTypes.InstrumentId, joined on CryptoId. Used to join to instrument-level dimension tables. E.g., BTC=100000, ETH=100010. (Tier 2 — SP_EXW_Fact_Transactions via CryptoTypes) |
| 6 | WalletID | nvarchar(max) | NULL | The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId. DWH note: Renamed from WalletId. Stored as nvarchar(max) (uniqueidentifier in WalletDB, serialized as string in Bronze Parquet). (Tier 1 — Wallet.TransactionsView) |
| 7 | TranID | bigint | NULL | Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish. (Tier 1 — Wallet.TransactionsView) |
| 8 | TranStatusID | int | NULL | Latest status ID. Resolved via correlated subquery: `SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC`. FK to Dictionary.TransactionStatus. DWH note: Renamed from TransStatusId. Live values: 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError. (Tier 1 — Wallet.TransactionsView) |
| 9 | TranStatus | nvarchar(500) | NULL | Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval. DWH note: Renamed from TransStatus. Also observed in live data: WavedError (6), Confirmed (1), PermanentError (5), Timeout (4). (Tier 1 — Wallet.TransactionsView) |
| 10 | TranDate | date | NULL | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. DWH note: Renamed from TransDate. Stored as date (datetime2 in source view). (Tier 1 — Wallet.TransactionsView) |
| 11 | TranDateID | bigint | NULL | Integer date key in yyyyMMdd format derived from TranDate. Computed as CAST(CONVERT(VARCHAR(8), TransDate, 112) AS INT). Used for joining to integer-keyed date dimension tables. (Tier 2 — SP_EXW_Fact_Transactions) |
| 12 | Amount | numeric(38,8) | NULL | Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for 'other' types. (Tier 1 — Wallet.TransactionsView) |
| 13 | EtoroFees | numeric(38,8) | NULL | eToro platform fee normalized by exchange rate: source EtoroFees × FeeExchangeRate. For most types FeeExchangeRate=1; for ConversionOut the fee is normalized to the destination crypto's value basis. Do NOT re-multiply by FeeExchangeRate. NULL when no fee applies. (Tier 2 — SP_EXW_Fact_Transactions) |
| 14 | ProviderFees | numeric(38,8) | NULL | External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types. (Tier 1 — Wallet.TransactionsView) |
| 15 | FeeExchangeRate | numeric(38,8) | NULL | Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives. (Tier 1 — Wallet.TransactionsView) |
| 16 | BlockchainFees | numeric(38,8) | NULL | Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives. DWH note: Renamed from BlockchainFee. (Tier 1 — Wallet.TransactionsView) |
| 17 | EstimatedBlockchainFee | numeric(38,8) | NULL | Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives. DWH note: Renamed from EffectiveBlockchainFee. (Tier 1 — Wallet.TransactionsView) |
| 18 | ActionTypeID | int | NULL | Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block. DWH note: Renamed from ActionTypeId. (Tier 1 — Wallet.TransactionsView) |
| 19 | ActionTypeName | nvarchar(500) | NULL | Human-readable direction: 'Sent' or 'Recive' (legacy misspelling preserved for backward compatibility). (Tier 1 — Wallet.TransactionsView) |
| 20 | AmountUSD | numeric(38,8) | NULL | Transaction amount in USD. Amount × AvgPrice from EXW_Wallet.EXW_Price (join on CryptoId WHERE TransDate > DateFrom AND TransDate <= DateTo). NULL when no price available for the crypto+date combination. (Tier 2 — SP_EXW_Fact_Transactions via EXW_Price) |
| 21 | EtoroFeesUSD | numeric(38,8) | NULL | eToro fees in USD. EtoroFees (already rate-adjusted) × AvgPrice from EXW_Wallet.EXW_Price. NULL when no price available. (Tier 2 — SP_EXW_Fact_Transactions via EXW_Price) |
| 22 | BlockchainFeesUSD | numeric(38,8) | NULL | Blockchain network fees in USD. BlockchainFees × AvgPrice from EXW_Wallet.EXW_Price. NULL when no price available. (Tier 2 — SP_EXW_Fact_Transactions via EXW_Price) |
| 23 | EstimatedBlockchainFeesUSD | numeric(38,8) | NULL | Estimated blockchain fees in USD. EstimatedBlockchainFee × AvgPrice from EXW_Wallet.EXW_Price. NULL when no price available. (Tier 2 — SP_EXW_Fact_Transactions via EXW_Price) |
| 24 | UpdateDate | datetime | NULL | Timestamp when SP_EXW_Fact_Transactions last wrote this row. Set to GETDATE() at SP execution time. Not the transaction date — use TranDate or Occurred for temporal filtering. (Tier 2 — SP_EXW_Fact_Transactions) |
| 25 | SenderAddress | nvarchar(512) | NULL | Sender's blockchain address. Sends: from WalletPool.PublicAddress (wallet's own address). Receives: from ReceivedTransactions.SenderAddress (external sender). (Tier 1 — Wallet.TransactionsView) |
| 26 | ReciverAddress | nvarchar(max) | NULL | Receiver's blockchain address (legacy misspelling 'Reciver'). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress. (Tier 1 — Wallet.TransactionsView) |
| 27 | AMLProviderStatus | varchar(500) | NULL | AML provider decision for this transaction. Values: Amber (needs review), NA (not applicable), Green (clear), Red (flagged), Error (provider error). Joined from EXW_Wallet.AmlValidations (most-recent Rn=1). NULL when no AML check was performed for this transaction. (Tier 2 — SP_EXW_Fact_Transactions via AmlValidations) |
| 28 | AMLIsPositiveDecision | int | NULL | AML positive-decision flag from EXW_Wallet.AmlValidations.IsPositiveDecision. 1=positive (cleared); 0=negative (flagged); NULL=no AML check performed. Uses same join as AMLProviderStatus. (Tier 2 — SP_EXW_Fact_Transactions via AmlValidations) |
| 29 | IsEtoroFee | int | NULL | Reserved column — always NULL. The classification logic for this flag was commented out in SP_EXW_Fact_Transactions. Retained in schema for backward compatibility. (Tier 2 — SP_EXW_Fact_Transactions) |
| 30 | BlockchainTransactionId | nvarchar(max) | NULL | On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions. (Tier 1 — Wallet.TransactionsView) |
| 31 | TransactionTypeID | int | NULL | Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes. DWH note: Renamed from TransactionTypeId. Also observed in live data: 1=CustomerMoneyOut, 2=AmlMoneyBack, 4=Funding, 10=BlockChainActivation, 11=OmnibusMoneyOut, 12=ConversionToFiat, 13=ManualUserMoneyOut, 15=CustomerMoneyBack. (Tier 1 — Wallet.TransactionsView) |
| 32 | TransactionType | varchar(64) | NULL | Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions. (Tier 1 — Wallet.TransactionsView) |
| 33 | IsRedeem | int | NULL | Flag: 1 if this transaction is a crypto redemption (withdrawal to blockchain). Sent: TransactionTypeID IN (0=Redeem, 8=RedeemAsic). Received: ReceivedTransactionTypeID IN (2=Redeem, 7) OR matching blockchain TX ID of a sent redemption. 0 otherwise. (Tier 2 — SP_EXW_Fact_Transactions) |
| 34 | IsConversion | int | NULL | Flag: 1 if this transaction is a crypto conversion. Sent: TransactionTypeID IN (5=ConversionMoneyIn, 6=ConversionMoneyOut). Received: ReceivedTransactionTypeID IN (4=ConversionToEtoro, 5=ConversionFromEtoro). 0 otherwise. (Tier 2 — SP_EXW_Fact_Transactions) |
| 35 | IsPayment | int | NULL | Flag: 1 if this transaction is a crypto payment. Sent: TransactionTypeID = 7 (Payment). Received: ReceivedTransactionTypeID = 6 (Payment). 0 otherwise. (Tier 2 — SP_EXW_Fact_Transactions) |
| 36 | BlockchainCryptoId | int | NULL | Cryptocurrency ID of the underlying blockchain asset. For ERC-20 tokens (USDEX, EURX, GBPX): BlockchainCryptoId=2 (ETH). For native coins: equals CryptoId. From EXW_Wallet.CryptoTypes.BlockchainCryptoId, joined on CryptoId. (Tier 2 — SP_EXW_Fact_Transactions via CryptoTypes) |
| 37 | BlockchainCryptoName | nvarchar(500) | NULL | Name of the underlying blockchain asset. For ERC-20 tokens: 'ETH'. For native coins: equals CryptoName. From EXW_Wallet.CryptoTypes.Name where CryptoId=BlockchainCryptoId. (Tier 2 — SP_EXW_Fact_Transactions via CryptoTypes) |
| 38 | Occurred | datetime | NULL | When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. DWH note: Stored as datetime (datetime2 in source view). (Tier 1 — Wallet.TransactionsView) |
| 39 | IsFunding | int | NULL | Flag: 1 if this transaction is a wallet pool pre-funding event. Sent: TransactionTypeID = 4 (Funding). Received: ReceivedTransactionTypeID = 3. 0 otherwise. Pool funding occurs before a wallet is assigned to a customer (see EXW_WalletInventory). (Tier 2 — SP_EXW_Fact_Transactions) |
| 40 | IsEtoroHandlingFee | int | NULL | Flag from EXW_Wallet.CryptoTypes indicating whether this crypto uses eToro's handling fee model. 0=standard provider-fee model (BTC, ETH, etc.). From EXW_Wallet.CryptoTypes.IsEtoroHandlingFee, joined on CryptoId. (Tier 2 — SP_EXW_Fact_Transactions via CryptoTypes) |
| 41 | TranDateTime | datetime | NULL | Transaction date stored as datetime. Same value as TranDate (derived from TransDate) but as datetime type. Added for compatibility with datetime filtering in reporting tools. (Tier 2 — SP_EXW_Fact_Transactions) |
| 42 | DateOccured | date | NULL | Date portion of Occurred. CAST(Occurred AS DATE). Enables day-level grouping by actual occurrence date vs. TranDate (blockchain-assigned date). Column name has legacy typo 'DateOccured' (not 'DateOccurred') preserved from original schema. (Tier 2 — SP_EXW_Fact_Transactions) |
| 43 | LastStatusUpdateOccurred | datetime | NULL | Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables 'time since last update' monitoring and SLA tracking. New in this version (not in TransactionViewOld). (Tier 1 — Wallet.TransactionsView) |
| 44 | ReceivedTransactionTypeID | int | NULL | Type classification for received transactions. From EXW_Wallet.ReceivedTransactions.ReceivedTransactionTypeId (LEFT JOIN on TranID=Id WHERE ActionTypeID=2). NULL for all sent transactions. Values: 1=MoneyIn, 2=Redeem, 5=ConversionFromEtoro, 6=Payment. FK to WalletDB_Dictionary_ReceivedTransactionTypes. (Tier 2 — SP_EXW_Fact_Transactions via ReceivedTransactions) |
| 45 | ReceivedTransactionType | varchar(64) | NULL | Human-readable type name for received transactions. From CopyFromLake.WalletDB_Dictionary_ReceivedTransactionTypes.Name, joined on ReceivedTransactionTypeID. NULL for all sent transactions and ~76% of received rows. (Tier 2 — SP_EXW_Fact_Transactions via WalletDB_Dictionary_ReceivedTransactionTypes) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| GCID, CryptoId, WalletID, TranID, TranStatusID, TranStatus, TranDate, Amount, ProviderFees, FeeExchangeRate, BlockchainFees, EstimatedBlockchainFee, ActionTypeID, ActionTypeName, SenderAddress, ReciverAddress, BlockchainTransactionId, TransactionTypeID, TransactionType, Occurred, LastStatusUpdateOccurred | Wallet.TransactionsView (via External) | Same or renamed | Passthrough (some renamed; see lineage.md) |
| RealCID | DWH_dbo.Dim_Customer | RealCID | LEFT JOIN on GCID |
| CryptoName, InstrumentID, BlockchainCryptoId, BlockchainCryptoName, IsEtoroHandlingFee | EXW_Wallet.CryptoTypes | Name, InstrumentId, BlockchainCryptoId, Name, IsEtoroHandlingFee | JOIN on CryptoId |
| EtoroFees | External + EXW_Price | EtoroFees × FeeExchangeRate | Computed |
| AmountUSD, EtoroFeesUSD, BlockchainFeesUSD, EstimatedBlockchainFeesUSD | EXW_Wallet.EXW_Price | AvgPrice | Computed: native × price |
| AMLProviderStatus, AMLIsPositiveDecision | EXW_Wallet.AmlValidations | ProviderStatus, IsPositiveDecision | JOIN by direction |
| ReceivedTransactionTypeID, ReceivedTransactionType | EXW_Wallet.ReceivedTransactions + WalletDB_Dictionary_ReceivedTransactionTypes | ReceivedTransactionTypeId, Name | JOIN on TranID (received only) |
| IsRedeem, IsConversion, IsPayment, IsFunding | Multiple | TransactionTypeID, ReceivedTransactionTypeID | CASE logic |
| IsEtoroFee, TranDateID, TranDateTime, DateOccured, UpdateDate | — | — | Computed |

### 5.2 ETL Pipeline

```
WalletDB (etoro-walletdb-prod)
  Wallet.TransactionsView (22-column unified view)
    |
    [Generic Pipeline — Bronze Override 60 min]
    |
    ADLS Bronze/WalletDB/Wallet/TransactionsView/
    |
    EXW_dbo.External_WalletDB_Wallet_TransactionsView (External Table)
    |
    SP_EXW_Fact_Transactions (@d DATE)  — daily DELETE+INSERT
      JOIN EXW_Wallet.AmlValidations   (AML enrichment)
      JOIN EXW_Wallet.CryptoTypes      (crypto metadata)
      JOIN EXW_Wallet.EXW_Price        (USD pricing)
      JOIN EXW_Wallet.SentTransactions (AML correlation for CustomerMoneyOut)
      JOIN EXW_Wallet.ReceivedTransactions + WalletDB_Dictionary_ReceivedTransactionTypes
      JOIN DWH_dbo.Dim_Customer        (RealCID)
    |
    EXW_dbo.EXW_FactTransactions  HASH(GCID) HEAP
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Source view Bronze projection |
| GCID | DWH_dbo.Dim_Customer | Customer attribute enrichment |
| CryptoId | EXW_Wallet.CryptoTypes | Crypto metadata |
| TranDate | EXW_Wallet.EXW_Price | USD pricing |
| AMLProviderStatus | EXW_Wallet.AmlValidations | AML decision |
| TranID (ActionTypeID=2) | EXW_Wallet.ReceivedTransactions | Received type classification |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| SP_EXW_Transactions_Monthly | TranDate, GCID, CryptoId | Monthly transaction aggregations |
| SP_EXW_Hourly | TranDateTime, GCID | Hourly activity metrics |
| SP_EXW_UserCalculatedBalance | GCID, Amount, ActionTypeID | User crypto balance |
| EXW reporting layer | Various | Standard crypto analytics |

---

## 7. Sample Queries

### 7.1 Customer transactions for a date range (with USD values)
```sql
SELECT TranID, ActionTypeName, TranDate, CryptoName, Amount, AmountUSD,
       TransactionType, TranStatus, IsRedeem, IsConversion
FROM EXW_dbo.EXW_FactTransactions
WHERE GCID = 9661239
  AND TranDate >= '2024-01-01'
  AND TranDate < '2025-01-01'
ORDER BY TranDate DESC, TranID
```

### 7.2 Daily redemption volume in USD
```sql
SELECT TranDate, CryptoName, COUNT(*) AS TxCount,
       SUM(Amount) AS TotalNative, SUM(AmountUSD) AS TotalUSD
FROM EXW_dbo.EXW_FactTransactions
WHERE IsRedeem = 1
  AND ActionTypeID = 1
  AND TranDate >= '2024-01-01'
GROUP BY TranDate, CryptoName
ORDER BY TranDate DESC, TotalUSD DESC
```

### 7.3 AML-flagged transactions (Red)
```sql
SELECT GCID, TranID, TranDate, CryptoName, Amount, AmountUSD,
       AMLProviderStatus, AMLIsPositiveDecision, LastStatusUpdateOccurred
FROM EXW_dbo.EXW_FactTransactions
WHERE AMLProviderStatus = 'Red'
  AND ActionTypeID = 1
ORDER BY LastStatusUpdateOccurred DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object in the EXW_dbo context. The underlying transaction data is documented in the CryptoDBs/WalletDB wiki (Wallet.TransactionsView). AML enrichment logic relates to the EXW AML processing pipeline.

---

*Generated: 2026-04-20 | Quality: 9.4/10 (P16 adversarial: 9.45) | Phases: 14/14*
*Tiers: 21 T1, 24 T2, 0 T3, 0 T4, 0 T5 | Elements: 45/45*
*Object: EXW_dbo.EXW_FactTransactions | Type: Table | Production Source: WalletDB.Wallet.TransactionsView → SP_EXW_Fact_Transactions*
