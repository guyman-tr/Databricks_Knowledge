-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_FactTransactions
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions SET TBLPROPERTIES (
    'comment' = '`EXW_FactTransactions` is the central transaction fact table for EXW crypto analytics. Each row represents one transaction event from the eToro crypto wallet platform - either a sent transaction (redemption, conversion, payment, staking, funding, or other outgoing type) or a received transaction (inbound crypto transfer). A single on-chain transaction can appear as two rows: one for the sender (ActionTypeID=1) and one for the receiver (ActionTypeID=2). As of last refresh: 4,709,301 rows; 284,567 distinct GCIDs; TranDate range 2018-04-23 to 2026-04-19 (live). Direction split: Received=2,496,494 (53%) / Sent=2,212,807 (47%). Transaction status: Verified (99.7%), WavedError (0.24%), Confirmed/Pending/Error (<0.1% combined). IsRedeem=47.9%, IsConversion=4.1%, IsFunding=2.0%, IsPayment=1.0%. UpdateDate = 2026-04-20 (SP ran today - actively refreshed). SP_EXW_Fact_Transactions is called with a target date @d. It processes all transactions whose TranDate, Occurred, or LastStatusUpdateOccurred falls within [**@d**...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'EXW_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(GCID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `GCID` COMMENT 'Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid. DWH note: Renamed from gcid. Stored as int (bigint in source view). HASH distribution key. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `RealCID` COMMENT 'Platform-internal customer ID from DWH_dbo.Dim_Customer, joined on GCID. NULL for omnibus/system wallets (GCID=0) and customers not yet in Dim_Customer. Enables joins to DWH fact tables that key on RealCID. (Tier 2 - SP_EXW_Fact_Transactions via Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `CryptoId` COMMENT 'The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `CryptoName` COMMENT 'Human-readable name of the cryptocurrency. From EXW_Wallet.CryptoTypes.Name, joined on CryptoId. E.g., ''BTC'', ''ETH'', ''XRP''. (Tier 2 - SP_EXW_Fact_Transactions via CryptoTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `InstrumentID` COMMENT 'DWH instrument identifier for this cryptocurrency. From EXW_Wallet.CryptoTypes.InstrumentId, joined on CryptoId. Used to join to instrument-level dimension tables. E.g., BTC=100000, ETH=100010. (Tier 2 - SP_EXW_Fact_Transactions via CryptoTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `WalletID` COMMENT 'The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId. DWH note: Renamed from WalletId. Stored as nvarchar(max) (uniqueidentifier in WalletDB, serialized as string in Bronze Parquet). (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TranID` COMMENT 'Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TranStatusID` COMMENT 'Latest status ID. Resolved via correlated subquery: `SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC`. FK to Dictionary.TransactionStatus. DWH note: Renamed from TransStatusId. Live values: 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TranStatus` COMMENT 'Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval. DWH note: Renamed from TransStatus. Also observed in live data: WavedError (6), Confirmed (1), PermanentError (5), Timeout (4). (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TranDate` COMMENT 'Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. DWH note: Renamed from TransDate. Stored as date (datetime2 in source view). (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TranDateID` COMMENT 'Integer date key in yyyyMMdd format derived from TranDate. Computed as CAST(CONVERT(VARCHAR(8), TransDate, 112) AS INT). Used for joining to integer-keyed date dimension tables. (Tier 2 - SP_EXW_Fact_Transactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `Amount` COMMENT 'Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for ''other'' types. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `EtoroFees` COMMENT 'eToro platform fee normalized by exchange rate: source EtoroFees × FeeExchangeRate. For most types FeeExchangeRate=1; for ConversionOut the fee is normalized to the destination crypto''s value basis. Do NOT re-multiply by FeeExchangeRate. NULL when no fee applies. (Tier 2 - SP_EXW_Fact_Transactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `ProviderFees` COMMENT 'External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `FeeExchangeRate` COMMENT 'Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `BlockchainFees` COMMENT 'Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives. DWH note: Renamed from BlockchainFee. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `EstimatedBlockchainFee` COMMENT 'Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives. DWH note: Renamed from EffectiveBlockchainFee. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `ActionTypeID` COMMENT 'Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block. DWH note: Renamed from ActionTypeId. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `ActionTypeName` COMMENT 'Human-readable direction: ''Sent'' or ''Recive'' (legacy misspelling preserved for backward compatibility). (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `AmountUSD` COMMENT 'Transaction amount in USD. Amount × AvgPrice from EXW_Wallet.EXW_Price (join on CryptoId WHERE TransDate > DateFrom AND TransDate <= DateTo). NULL when no price available for the crypto+date combination. (Tier 2 - SP_EXW_Fact_Transactions via EXW_Price)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `EtoroFeesUSD` COMMENT 'eToro fees in USD. EtoroFees (already rate-adjusted) × AvgPrice from EXW_Wallet.EXW_Price. NULL when no price available. (Tier 2 - SP_EXW_Fact_Transactions via EXW_Price)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `BlockchainFeesUSD` COMMENT 'Blockchain network fees in USD. BlockchainFees × AvgPrice from EXW_Wallet.EXW_Price. NULL when no price available. (Tier 2 - SP_EXW_Fact_Transactions via EXW_Price)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `EstimatedBlockchainFeesUSD` COMMENT 'Estimated blockchain fees in USD. EstimatedBlockchainFee × AvgPrice from EXW_Wallet.EXW_Price. NULL when no price available. (Tier 2 - SP_EXW_Fact_Transactions via EXW_Price)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `UpdateDate` COMMENT 'Timestamp when SP_EXW_Fact_Transactions last wrote this row. Set to GETDATE() at SP execution time. Not the transaction date - use TranDate or Occurred for temporal filtering. (Tier 2 - SP_EXW_Fact_Transactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `SenderAddress` COMMENT 'Sender''s blockchain address. Sends: from WalletPool.PublicAddress (wallet''s own address). Receives: from ReceivedTransactions.SenderAddress (external sender). (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `ReciverAddress` COMMENT 'Receiver''s blockchain address (legacy misspelling ''Reciver''). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `AMLProviderStatus` COMMENT 'AML provider decision for this transaction. Values: Amber (needs review), NA (not applicable), Green (clear), Red (flagged), Error (provider error). Joined from EXW_Wallet.AmlValidations (most-recent Rn=1). NULL when no AML check was performed for this transaction. (Tier 2 - SP_EXW_Fact_Transactions via AmlValidations)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `AMLIsPositiveDecision` COMMENT 'AML positive-decision flag from EXW_Wallet.AmlValidations.IsPositiveDecision. 1=positive (cleared); 0=negative (flagged); NULL=no AML check performed. Uses same join as AMLProviderStatus. (Tier 2 - SP_EXW_Fact_Transactions via AmlValidations)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `IsEtoroFee` COMMENT 'Reserved column - always NULL. The classification logic for this flag was commented out in SP_EXW_Fact_Transactions. Retained in schema for backward compatibility. (Tier 2 - SP_EXW_Fact_Transactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `BlockchainTransactionId` COMMENT 'On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TransactionTypeID` COMMENT 'Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes. DWH note: Renamed from TransactionTypeId. Also observed in live data: 1=CustomerMoneyOut, 2=AmlMoneyBack, 4=Funding, 10=BlockChainActivation, 11=OmnibusMoneyOut, 12=ConversionToFiat, 13=ManualUserMoneyOut, 15=CustomerMoneyBack. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TransactionType` COMMENT 'Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions. (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `IsRedeem` COMMENT 'Flag: 1 if this transaction is a crypto redemption (withdrawal to blockchain). Sent: TransactionTypeID IN (0=Redeem, 8=RedeemAsic). Received: ReceivedTransactionTypeID IN (2=Redeem, 7) OR matching blockchain TX ID of a sent redemption. 0 otherwise. (Tier 2 - SP_EXW_Fact_Transactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `IsConversion` COMMENT 'Flag: 1 if this transaction is a crypto conversion. Sent: TransactionTypeID IN (5=ConversionMoneyIn, 6=ConversionMoneyOut). Received: ReceivedTransactionTypeID IN (4=ConversionToEtoro, 5=ConversionFromEtoro). 0 otherwise. (Tier 2 - SP_EXW_Fact_Transactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `IsPayment` COMMENT 'Flag: 1 if this transaction is a crypto payment. Sent: TransactionTypeID = 7 (Payment). Received: ReceivedTransactionTypeID = 6 (Payment). 0 otherwise. (Tier 2 - SP_EXW_Fact_Transactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `BlockchainCryptoId` COMMENT 'Cryptocurrency ID of the underlying blockchain asset. For ERC-20 tokens (USDEX, EURX, GBPX): BlockchainCryptoId=2 (ETH). For native coins: equals CryptoId. From EXW_Wallet.CryptoTypes.BlockchainCryptoId, joined on CryptoId. (Tier 2 - SP_EXW_Fact_Transactions via CryptoTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `BlockchainCryptoName` COMMENT 'Name of the underlying blockchain asset. For ERC-20 tokens: ''ETH''. For native coins: equals CryptoName. From EXW_Wallet.CryptoTypes.Name where CryptoId=BlockchainCryptoId. (Tier 2 - SP_EXW_Fact_Transactions via CryptoTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `Occurred` COMMENT 'When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. DWH note: Stored as datetime (datetime2 in source view). (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `IsFunding` COMMENT 'Flag: 1 if this transaction is a wallet pool pre-funding event. Sent: TransactionTypeID = 4 (Funding). Received: ReceivedTransactionTypeID = 3. 0 otherwise. Pool funding occurs before a wallet is assigned to a customer (see EXW_WalletInventory). (Tier 2 - SP_EXW_Fact_Transactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `IsEtoroHandlingFee` COMMENT 'Flag from EXW_Wallet.CryptoTypes indicating whether this crypto uses eToro''s handling fee model. 0=standard provider-fee model (BTC, ETH, etc.). From EXW_Wallet.CryptoTypes.IsEtoroHandlingFee, joined on CryptoId. (Tier 2 - SP_EXW_Fact_Transactions via CryptoTypes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TranDateTime` COMMENT 'Transaction date stored as datetime. Same value as TranDate (derived from TransDate) but as datetime type. Added for compatibility with datetime filtering in reporting tools. (Tier 2 - SP_EXW_Fact_Transactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `DateOccured` COMMENT 'Date portion of Occurred. CAST(Occurred AS DATE). Enables day-level grouping by actual occurrence date vs. TranDate (blockchain-assigned date). Column name has legacy typo ''DateOccured'' (not ''DateOccurred'') preserved from original schema. (Tier 2 - SP_EXW_Fact_Transactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `LastStatusUpdateOccurred` COMMENT 'Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables ''time since last update'' monitoring and SLA tracking. New in this version (not in TransactionViewOld). (Tier 1 - Wallet.TransactionsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `ReceivedTransactionTypeID` COMMENT 'Type classification for received transactions. From EXW_Wallet.ReceivedTransactions.ReceivedTransactionTypeId (LEFT JOIN on TranID=Id WHERE ActionTypeID=2). NULL for all sent transactions. Values: 1=MoneyIn, 2=Redeem, 5=ConversionFromEtoro, 6=Payment. FK to WalletDB_Dictionary_ReceivedTransactionTypes. (Tier 2 - SP_EXW_Fact_Transactions via ReceivedTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `ReceivedTransactionType` COMMENT 'Human-readable type name for received transactions. From CopyFromLake.WalletDB_Dictionary_ReceivedTransactionTypes.Name, joined on ReceivedTransactionTypeID. NULL for all sent transactions and ~76% of received rows. (Tier 2 - SP_EXW_Fact_Transactions via WalletDB_Dictionary_ReceivedTransactionTypes)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `RealCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `CryptoId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `CryptoName` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `InstrumentID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `WalletID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TranID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TranStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TranStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TranDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TranDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `Amount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `EtoroFees` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `ProviderFees` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `FeeExchangeRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `BlockchainFees` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `EstimatedBlockchainFee` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `ActionTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `ActionTypeName` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `AmountUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `EtoroFeesUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `BlockchainFeesUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `EstimatedBlockchainFeesUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `SenderAddress` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `ReciverAddress` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `AMLProviderStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `AMLIsPositiveDecision` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `IsEtoroFee` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `BlockchainTransactionId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TransactionTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TransactionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `IsRedeem` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `IsConversion` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `IsPayment` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `BlockchainCryptoId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `BlockchainCryptoName` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `Occurred` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `IsFunding` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `IsEtoroHandlingFee` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `TranDateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `DateOccured` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `LastStatusUpdateOccurred` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `ReceivedTransactionTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ALTER COLUMN `ReceivedTransactionType` SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:19:22 UTC
-- Batch deploy resume: EXW_dbo deploy batch 2
-- Statements: 92/92 succeeded
-- ====================
