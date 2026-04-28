# EXW_FactTransactions — Column Lineage

## Source Objects

| # | Source Object | Source Type | Database | Relationship | Description |
|---|--------------|-------------|----------|-------------|-------------|
| 1 | Wallet.TransactionsView | View | WalletDB | Primary (via External_WalletDB_Wallet_TransactionsView) | Unified crypto transaction view combining all sent/received transaction types with fees, statuses, and blockchain details |
| 2 | EXW_Wallet.CryptoTypes | Table | Synapse (external) | Lookup | Cryptocurrency metadata: name, InstrumentId, BlockchainCryptoId, IsEtoroHandlingFee |
| 3 | EXW_Wallet.AmlValidations | Table | Synapse (external) | Enrichment | AML screening results: ProviderStatus, IsPositiveDecision |
| 4 | EXW_Wallet.EXW_Price | Table | Synapse (external) | Lookup | Crypto-to-USD price: AvgPrice for USD conversion |
| 5 | DWH_dbo.Dim_Customer | Table | Synapse | Lookup | Customer dimension: RealCID resolution from GCID |
| 6 | EXW_Wallet.SentTransactions | Table | Synapse (external) | Enrichment | Identifies redeem sent transactions for received-side redeem flag |
| 7 | EXW_Wallet.ReceivedTransactions | Table | Synapse (external) | Enrichment | ReceivedTransactionTypeId for received transactions |
| 8 | CopyFromLake.WalletDB_Dictionary_ReceivedTransactionTypes | Table | Synapse (lake copy) | Lookup | ReceivedTransactionType name resolution |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | GCID | Wallet.TransactionsView | gcid | Passthrough | Tier 1 |
| 2 | RealCID | DWH_dbo.Dim_Customer | RealCID | Dim-lookup via GCID JOIN | Tier 1 |
| 3 | CryptoId | Wallet.TransactionsView | CryptoId | Passthrough | Tier 1 |
| 4 | CryptoName | EXW_Wallet.CryptoTypes | Name | Lookup by CryptoId, CAST to nvarchar(500) | Tier 2 |
| 5 | InstrumentID | EXW_Wallet.CryptoTypes | InstrumentId | Lookup by CryptoId | Tier 2 |
| 6 | WalletID | Wallet.TransactionsView | WalletId | Passthrough | Tier 1 |
| 7 | TranID | Wallet.TransactionsView | TranID | Passthrough | Tier 1 |
| 8 | TranStatusID | Wallet.TransactionsView | TransStatusId | Passthrough (renamed) | Tier 1 |
| 9 | TranStatus | Wallet.TransactionsView | TransStatus | Passthrough, CAST to nvarchar(500) | Tier 1 |
| 10 | TranDate | Wallet.TransactionsView | TransDate | Passthrough (renamed) | Tier 1 |
| 11 | TranDateID | Wallet.TransactionsView | TransDate | ETL-computed: CAST(CONVERT(VARCHAR(8), TransDate, 112) AS INT) | Tier 2 |
| 12 | Amount | Wallet.TransactionsView | Amount | Passthrough | Tier 1 |
| 13 | EtoroFees | Wallet.TransactionsView | EtoroFees, FeeExchangeRate | Transformed: EtoroFees * FeeExchangeRate (currency-converted) | Tier 2 |
| 14 | ProviderFees | Wallet.TransactionsView | ProviderFees | Passthrough | Tier 1 |
| 15 | FeeExchangeRate | Wallet.TransactionsView | FeeExchangeRate | Passthrough | Tier 1 |
| 16 | BlockchainFees | Wallet.TransactionsView | BlockchainFee | Passthrough (renamed) | Tier 1 |
| 17 | EstimatedBlockchainFee | Wallet.TransactionsView | EffectiveBlockchainFee | Passthrough (renamed) | Tier 1 |
| 18 | ActionTypeID | Wallet.TransactionsView | ActionTypeId | Passthrough | Tier 1 |
| 19 | ActionTypeName | Wallet.TransactionsView | ActionTypeName | Passthrough, CAST to nvarchar(500) | Tier 1 |
| 20 | AmountUSD | Wallet.TransactionsView + EXW_Wallet.EXW_Price | Amount, AvgPrice | ETL-computed: Amount * AvgPrice | Tier 2 |
| 21 | EtoroFeesUSD | SP_EXW_Fact_Transactions | EtoroFees (post-conversion), AvgPrice | ETL-computed: EtoroFees * AvgPrice | Tier 2 |
| 22 | BlockchainFeesUSD | Wallet.TransactionsView + EXW_Wallet.EXW_Price | BlockchainFee, AvgPrice | ETL-computed: BlockchainFee * AvgPrice | Tier 2 |
| 23 | EstimatedBlockchainFeesUSD | Wallet.TransactionsView + EXW_Wallet.EXW_Price | EstimatedBlockchainFee, AvgPrice | ETL-computed: EstimatedBlockchainFee * AvgPrice | Tier 2 |
| 24 | UpdateDate | SP_EXW_Fact_Transactions | — | ETL-computed: GETDATE() at insert time | Tier 2 |
| 25 | SenderAddress | Wallet.TransactionsView | SenderAddress | Passthrough | Tier 1 |
| 26 | ReciverAddress | Wallet.TransactionsView | ReciverAddress | Passthrough | Tier 1 |
| 27 | AMLProviderStatus | EXW_Wallet.AmlValidations | ProviderStatus | Enrichment: latest AML validation per CorrelationId (sent) or BlockchainTransactionId+WalletId (received) | Tier 2 |
| 28 | AMLIsPositiveDecision | EXW_Wallet.AmlValidations | IsPositiveDecision | Enrichment: latest AML validation, same partitioning as AMLProviderStatus | Tier 2 |
| 29 | IsEtoroFee | SP_EXW_Fact_Transactions | — | Hardcoded NULL | Tier 2 |
| 30 | BlockchainTransactionId | Wallet.TransactionsView | BlockchainTransactionId | Passthrough | Tier 1 |
| 31 | TransactionTypeID | Wallet.TransactionsView | TransactionTypeId | Passthrough | Tier 1 |
| 32 | TransactionType | Wallet.TransactionsView | TransactionType | Passthrough | Tier 1 |
| 33 | IsRedeem | SP_EXW_Fact_Transactions | ActionTypeID, TransactionTypeID, ReceivedTransactionTypeID | ETL-computed: CASE logic combining sent (types 0,8) and received (types 2,7 or blockchain match) | Tier 2 |
| 34 | IsConversion | SP_EXW_Fact_Transactions | ActionTypeID, TransactionTypeID, ReceivedTransactionTypeID | ETL-computed: CASE logic — sent (types 5,6) or received (types 4,5) | Tier 2 |
| 35 | IsPayment | SP_EXW_Fact_Transactions | ActionTypeID, TransactionTypeID, ReceivedTransactionTypeID | ETL-computed: CASE logic — sent (type 7) or received (type 6) | Tier 2 |
| 36 | BlockchainCryptoId | EXW_Wallet.CryptoTypes | BlockchainCryptoId | Lookup by CryptoId | Tier 2 |
| 37 | BlockchainCryptoName | EXW_Wallet.CryptoTypes | Name (via BlockchainCryptoId chain) | Lookup: CryptoTypes[CryptoId].BlockchainCryptoId → CryptoTypes[BlockchainCryptoId].Name | Tier 2 |
| 38 | Occurred | Wallet.TransactionsView | Occurred | Passthrough | Tier 1 |
| 39 | IsFunding | SP_EXW_Fact_Transactions | ActionTypeID, TransactionTypeID, ReceivedTransactionTypeID | ETL-computed: CASE logic — sent (type 4) or received (type 3) | Tier 2 |
| 40 | IsEtoroHandlingFee | EXW_Wallet.CryptoTypes | IsEtoroHandlingFee | Lookup by CryptoId | Tier 2 |
| 41 | TranDateTime | Wallet.TransactionsView | TransDate | Passthrough (renamed from TransDate) | Tier 1 |
| 42 | DateOccured | Wallet.TransactionsView | Occurred | Passthrough with CAST to DATE | Tier 1 |
| 43 | LastStatusUpdateOccurred | Wallet.TransactionsView | LastStatusUpdateOccurred | Passthrough | Tier 1 |
| 44 | ReceivedTransactionTypeID | EXW_Wallet.ReceivedTransactions | ReceivedTransactionTypeId | Enrichment for received (ActionTypeId=2); NULL for sent | Tier 2 |
| 45 | ReceivedTransactionType | CopyFromLake.WalletDB_Dictionary_ReceivedTransactionTypes | Name | Lookup by ReceivedTransactionTypeId; NULL for sent | Tier 2 |

---

*Generated: 2026-04-27 | Object: EXW_dbo.EXW_FactTransactions | Writer SP: SP_EXW_Fact_Transactions*
