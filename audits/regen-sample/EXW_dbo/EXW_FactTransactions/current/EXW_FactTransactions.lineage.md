# EXW_dbo.EXW_FactTransactions — Column Lineage

> Generated: 2026-04-20 | Phase 10B | Source: SP_EXW_Fact_Transactions (incremental DELETE+INSERT, daily by @d DATE)

## Production Source

| Property | Value |
|----------|-------|
| **Primary Source DB** | WalletDB |
| **Primary Source Object** | Wallet.TransactionsView (via EXW_dbo.External_WalletDB_Wallet_TransactionsView Bronze Parquet) |
| **Writer** | SP_EXW_Fact_Transactions (@d DATE) — incremental DELETE+INSERT |
| **Enrichment Sources** | EXW_Wallet.AmlValidations, EXW_Wallet.CryptoTypes, EXW_Wallet.EXW_Price, EXW_Wallet.SentTransactions, EXW_Wallet.ReceivedTransactions, DWH_dbo.Dim_Customer, CopyFromLake.WalletDB_Dictionary_ReceivedTransactionTypes |
| **UC Target** | `_Not_Migrated` |
| **Refresh** | Daily DELETE+INSERT by date; rows refreshed when TranDate, Occurred, or LastStatusUpdateOccurred = @d |
| **Last Data** | 2026-04-19 (TranDate); 2026-04-20 07:47 (UpdateDate — SP ran today) |
| **Data Range** | 2018-04-23 to 2026-04-19 |

## Load Pattern

SP_EXW_Fact_Transactions is called with a target date @d. It collects all rows from External_WalletDB_Wallet_TransactionsView that have ANY date field (TransDate, Occurred, LastStatusUpdateOccurred) within the window [@d, @d+1). It then DELETEs existing rows from EXW_FactTransactions where TranID+ActionTypeID matches, and INSERTs the freshly enriched rows. This ensures that any status updates or late-arriving transactions that touch a given date are refreshed.

## ETL Pipeline

```
WalletDB (etoro-walletdb-prod)
  Wallet.TransactionsView          <- 7-CTE unified view (Sent + Received)
    |
    |-- [Generic Pipeline — Override, 60 min] --|
    v
Bronze ADLS: Bronze/WalletDB/Wallet/TransactionsView/
    |
    |-- [EXW_dbo.External_WalletDB_Wallet_TransactionsView] --|
    v
SP_EXW_Fact_Transactions (@d DATE)
  #prep          <- filter by date window
  #relevanttx    <- DISTINCT TranID+ActionTypeId from #prep
  #aml           <- EXW_Wallet.AmlValidations (most recent Rn per CorrelationId or BlockchainTxId+WalletId)
  #sent          <- EXW_Wallet.SentTransactions WHERE TransactionTypeId=1 (CustomerMoneyOut only)
  #amlsent       <- #sent JOIN #aml for sent-side AML
  #ext           <- UNION ALL of Sent (ActionTypeId=1) + Received (ActionTypeId=2) branches
                    with CryptoTypes join (CryptoName, InstrumentId, BlockchainCryptoId, IsEtoroHandlingFee)
  #dcpreprep     <- DWH_dbo.Dim_Customer (GCID→RealCID)
  #factTXPrep    <- #ext + EXW_Price join (USD values) + Dim_Customer join (RealCID)
  #sentredeems   <- SentTransactions WHERE TransactionTypeId IN (0,8) for received-redemption detection
  #receivedredeems <- #prep JOIN #sentredeems via BlockchainTransactionId (to flag redemption inbound)
  #final_Fact_Transactions <- IsRedeem/IsConversion/IsPayment/IsFunding CASE logic applied
    |
    |-- DELETE existing rows (TranID+ActionTypeID match) --|
    |-- INSERT enriched rows --|
    v
EXW_dbo.EXW_FactTransactions
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | GCID | Wallet.TransactionsView (via External) | gcid | Passthrough; renamed gcid→GCID; int in DWH (bigint in source) | Tier 1 |
| 2 | RealCID | DWH_dbo.Dim_Customer | RealCID | LEFT JOIN Dim_Customer ON gcid=GCID; NULL for system/omnibus wallets | Tier 2 |
| 3 | CryptoId | Wallet.TransactionsView (via External) | CryptoId | Passthrough | Tier 1 |
| 4 | CryptoName | EXW_Wallet.CryptoTypes | Name | JOIN CryptoTypes ON CryptoId; CAST nvarchar(500) | Tier 2 |
| 5 | InstrumentID | EXW_Wallet.CryptoTypes | InstrumentId | JOIN CryptoTypes ON CryptoId | Tier 2 |
| 6 | WalletID | Wallet.TransactionsView (via External) | WalletId | Passthrough; renamed WalletId→WalletID; nvarchar(max) | Tier 1 |
| 7 | TranID | Wallet.TransactionsView (via External) | TranID | Passthrough | Tier 1 |
| 8 | TranStatusID | Wallet.TransactionsView (via External) | TransStatusId | Passthrough; renamed TransStatusId→TranStatusID | Tier 1 |
| 9 | TranStatus | Wallet.TransactionsView (via External) | TransStatus | Passthrough; renamed TransStatus→TranStatus; CAST nvarchar(500) | Tier 1 |
| 10 | TranDate | Wallet.TransactionsView (via External) | TransDate | Passthrough; renamed TransDate→TranDate; date in DWH (datetime2 in source) | Tier 1 |
| 11 | TranDateID | Wallet.TransactionsView (via External) | TransDate | CAST(CONVERT(VARCHAR(8), TransDate, 112) AS INT) — yyyyMMdd integer date key | Tier 2 |
| 12 | Amount | Wallet.TransactionsView (via External) | Amount | Passthrough | Tier 1 |
| 13 | EtoroFees | Wallet.TransactionsView (via External) | EtoroFees, FeeExchangeRate | EtoroFees × CONVERT(FLOAT, FeeExchangeRate) — fee adjusted by exchange rate | Tier 2 |
| 14 | ProviderFees | Wallet.TransactionsView (via External) | ProviderFees | Passthrough | Tier 1 |
| 15 | FeeExchangeRate | Wallet.TransactionsView (via External) | FeeExchangeRate | Passthrough | Tier 1 |
| 16 | BlockchainFees | Wallet.TransactionsView (via External) | BlockchainFee | Passthrough; renamed BlockchainFee→BlockchainFees | Tier 1 |
| 17 | EstimatedBlockchainFee | Wallet.TransactionsView (via External) | EffectiveBlockchainFee | Passthrough; renamed EffectiveBlockchainFee→EstimatedBlockchainFee | Tier 1 |
| 18 | ActionTypeID | Wallet.TransactionsView (via External) | ActionTypeId | Passthrough; renamed ActionTypeId→ActionTypeID | Tier 1 |
| 19 | ActionTypeName | Wallet.TransactionsView (via External) | ActionTypeName | Passthrough | Tier 1 |
| 20 | AmountUSD | EXW_Wallet.EXW_Price | AvgPrice | Amount × AvgPrice; join CryptoId WHERE TransDate > DateFrom AND TransDate <= DateTo | Tier 2 |
| 21 | EtoroFeesUSD | EXW_Wallet.EXW_Price | AvgPrice | EtoroFees × AvgPrice | Tier 2 |
| 22 | BlockchainFeesUSD | EXW_Wallet.EXW_Price | AvgPrice | BlockchainFees × AvgPrice | Tier 2 |
| 23 | EstimatedBlockchainFeesUSD | EXW_Wallet.EXW_Price | AvgPrice | EstimatedBlockchainFee × AvgPrice | Tier 2 |
| 24 | UpdateDate | — | — | GETDATE() at SP execution time | Tier 2 |
| 25 | SenderAddress | Wallet.TransactionsView (via External) | SenderAddress | Passthrough | Tier 1 |
| 26 | ReciverAddress | Wallet.TransactionsView (via External) | ReciverAddress | Passthrough; legacy misspelling preserved | Tier 1 |
| 27 | AMLProviderStatus | EXW_Wallet.AmlValidations | ProviderStatus | Most-recent Rn=1; Sent: join via CorrelationId from SentTransactions (TypeId=1); Received: join via BlockchainTransactionId+WalletId | Tier 2 |
| 28 | AMLIsPositiveDecision | EXW_Wallet.AmlValidations | IsPositiveDecision | Same join logic as AMLProviderStatus | Tier 2 |
| 29 | IsEtoroFee | — | — | Hardcoded NULL (logic commented out in SP) | Tier 2 |
| 30 | BlockchainTransactionId | Wallet.TransactionsView (via External) | BlockchainTransactionId | Passthrough | Tier 1 |
| 31 | TransactionTypeID | Wallet.TransactionsView (via External) | TransactionTypeId | Passthrough; renamed TransactionTypeId→TransactionTypeID | Tier 1 |
| 32 | TransactionType | Wallet.TransactionsView (via External) | TransactionType | Passthrough | Tier 1 |
| 33 | IsRedeem | Multiple | TransactionTypeID, ReceivedTransactionTypeID, #receivedredeems | CASE: Sent TypeID IN(0,8)→1; Received RecvTypeID IN(2,7)→1; Received matching blockchain TX of a sent redemption→1 | Tier 2 |
| 34 | IsConversion | Multiple | TransactionTypeID, ReceivedTransactionTypeID | CASE: Sent TypeID IN(5,6)→1; Received RecvTypeID IN(4,5)→1 | Tier 2 |
| 35 | IsPayment | Multiple | TransactionTypeID, ReceivedTransactionTypeID | CASE: Sent TypeID=7→1; Received RecvTypeID=6→1 | Tier 2 |
| 36 | BlockchainCryptoId | EXW_Wallet.CryptoTypes | BlockchainCryptoId | LEFT JOIN CryptoTypes ON CryptoId | Tier 2 |
| 37 | BlockchainCryptoName | EXW_Wallet.CryptoTypes | Name | LEFT JOIN CryptoTypes ON BlockchainCryptoId (second join) | Tier 2 |
| 38 | Occurred | Wallet.TransactionsView (via External) | Occurred | Passthrough; datetime in DWH (datetime2 in source) | Tier 1 |
| 39 | IsFunding | Multiple | TransactionTypeID, ReceivedTransactionTypeID | CASE: Sent TypeID=4→1; Received RecvTypeID=3→1 | Tier 2 |
| 40 | IsEtoroHandlingFee | EXW_Wallet.CryptoTypes | IsEtoroHandlingFee | LEFT JOIN CryptoTypes ON CryptoId | Tier 2 |
| 41 | TranDateTime | Wallet.TransactionsView (via External) | TransDate | TransDate AS TranDateTime — same value as TranDate stored as datetime | Tier 2 |
| 42 | DateOccured | Wallet.TransactionsView (via External) | Occurred | CAST(Occurred AS DATE) — date portion only; name typo 'DateOccured' preserved | Tier 2 |
| 43 | LastStatusUpdateOccurred | Wallet.TransactionsView (via External) | LastStatusUpdateOccurred | Passthrough | Tier 1 |
| 44 | ReceivedTransactionTypeID | EXW_Wallet.ReceivedTransactions | ReceivedTransactionTypeId | LEFT JOIN ReceivedTransactions ON TranID=Id WHERE ActionTypeID=2; NULL for sent | Tier 2 |
| 45 | ReceivedTransactionType | CopyFromLake.WalletDB_Dictionary_ReceivedTransactionTypes | Name | LEFT JOIN on ReceivedTransactionTypeID; NULL for sent | Tier 2 |
_DDL column count: 45. Lineage rows 1-45 account for all columns._

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 21 | GCID, CryptoId, WalletID, TranID, TranStatusID, TranStatus, TranDate, Amount, ProviderFees, FeeExchangeRate, BlockchainFees, EstimatedBlockchainFee, ActionTypeID, ActionTypeName, SenderAddress, ReciverAddress, BlockchainTransactionId, TransactionTypeID, TransactionType, Occurred, LastStatusUpdateOccurred |
| Tier 2 | 24 | RealCID, CryptoName, InstrumentID, TranDateID, EtoroFees, AmountUSD, EtoroFeesUSD, BlockchainFeesUSD, EstimatedBlockchainFeesUSD, UpdateDate, AMLProviderStatus, AMLIsPositiveDecision, IsEtoroFee, IsRedeem, IsConversion, IsPayment, BlockchainCryptoId, BlockchainCryptoName, IsFunding, IsEtoroHandlingFee, TranDateTime, DateOccured, ReceivedTransactionTypeID, ReceivedTransactionType |

## UC External Lineage

UC Target: `_Not_Migrated` — not present in `_generic_pipeline_mapping.json`.
