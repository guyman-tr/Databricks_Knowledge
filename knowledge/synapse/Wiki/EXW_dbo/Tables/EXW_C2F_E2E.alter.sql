-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_C2F_E2E
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e SET TBLPROPERTIES (
    'comment' = 'EXW_C2F_E2E is the central reconciliation and analytics table for the Crypto-to-Fiat (C2F) conversion product. Each row represents a single conversion - a customer selling cryptocurrency and receiving fiat currency - with every stage of the lifecycle captured in a single denormalized row. The "E2E" name reflects the end-to-end scope: from the initial conversion request through the blockchain crypto transfer, the exchange rate locking, the fiat credit to the customer''s account, and the downstream eToro Money settlement. The SP also enriches each row with a customer profile snapshot (regulation, country, player level) valid at the time of the conversion, enabling regulatory and cohort analysis without join overhead. **Business context**: C2F conversions allow eToro Wallet users to sell crypto and receive fiat directly to an IBAN bank account (93% of rows), to an eToro trading account (7.5%), or to fund a trading position. Each conversion requires coordinated execution across three systems: WalletConversionDB...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'EXW_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(GCID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `C2FCorrelationID` COMMENT 'Distributed tracing correlation ID linking this conversion to its Saga.SagaRuns orchestration entry and all cross-service operations. Used as the deduplication key by InsertConversion. Indexed with Id for lookups. All SPs identify conversions by CorrelationId rather than Id. (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `TargetPlatformID` COMMENT 'Fiat destination type. FK to Dictionary.FiatConversionTargets. Values: 1=IbanAccount, 2=EtoroPlatform, 3=EtoroPosition. See [Fiat Conversion Target](../../_glossary.md#fiat-conversion-target). Determines the downstream routing of fiat proceeds. (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `TargetPlatform` COMMENT 'Display name for TargetPlatformID. Values: IbanAccount, EtoroPlatform, EtoroPosition. Lookup from WalletConversionDB Dictionary.FiatConversionTargets. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionCycle` COMMENT 'End-to-end reconciliation status classifying completion state across WalletDB request, blockchain send, and eMoney settlement. Values: Full Cycle (all systems agree success), FailedConversion (ConversionStatusID=2), Wallet Sent Tx Status Issue, Conversion Status Issue, eMoney Data Missing, eMoney Status Issue, eMoney Transaction Missing, Missing Wallet Side, Request Status Issue, Uncompleted Request, Other. Only evaluated for TargetPlatformID=1 (IbanAccount) path. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `LastModificationDateTime` COMMENT 'Latest event timestamp across all sub-systems: GREATEST(FiatTransaction.Occurred, ConversionTime, ConversionStatusTime, CryptoTransactionTime). Represents the most recent activity for this conversion row. Used as the reference timestamp for LastModificationDate and LastModificationDateID. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `LastModificationDate` COMMENT 'Date portion of LastModificationDateTime. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `LastModificationDateID` COMMENT 'Date integer key in YYYYMMDD format derived from LastModificationDate. Used as the reference date for the point-in-time customer snapshot join (Fact_SnapshotCustomer BETWEEN Dim_Range.FromDateID AND ToDateID). (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `GCID` COMMENT 'Global Customer ID identifying the customer who initiated the conversion. Validated NOT NULL by InsertConversion (raises error if null). Indexed for customer-scoped queries (GetConversionAmounts, GetConversionsUsdSum). (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RealCID` COMMENT 'Internal CID after deduplication mapping. Sourced from EXW_dbo.EXW_DimUser.RealCID; maps GCID to the canonical customer record. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RequestID` COMMENT 'Auto-incrementing primary key and the primary identifier for a request across the entire wallet system. Referenced by Wallet.RequestStatuses.RequestId as FK. Also used as lookup key by numerous stored procedures. (Tier 1 - Wallet.Requests)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RequestCryptoID` COMMENT 'Identifier of the cryptocurrency this request operates on. Implicit reference to Wallet.CryptoTypes.CryptoID. For conversions, this is the source crypto. Combined with Gcid for per-user per-crypto request lookups. (Tier 1 - Wallet.Requests)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RequestDateTime` COMMENT 'When the request was created. No default - explicitly set by the calling code. Used for chronological ordering, SLA monitoring, and date-range queries. Indexed descending for recent-request lookups. (Tier 1 - Wallet.Requests)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RequestLastStatusID` COMMENT 'Last-known status ID of the Wallet ConversionToFiat request. Derived by ROW_NUMBER() OVER (PARTITION BY er.Id ORDER BY ers.Timestamp DESC) = 1 from Wallet.RequestStatuses. Values: 1=Done, 2=Error, 7=TransactionVerified, 31=ReadByConversionWorker. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RequestLastStatus` COMMENT 'Display name for RequestLastStatusID. Lookup from WalletDB_Dictionary_RequestStatuses. Values observed: Done, Error, TransactionVerified, ReadByConversionWorker. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RequestLastStatusDateTime` COMMENT 'Timestamp of the last RequestStatuses entry for this request. Corresponds to when the RequestLastStatusID was set. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentTransactionID` COMMENT 'Auto-incrementing primary key. FK target for Wallet.SentTransactionStatuses, Wallet.SentTransactionOutputs, and Wallet.SentTransactionReplaces. (Tier 1 - Wallet.SentTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentBlockchainTransactionID` COMMENT 'The on-chain transaction hash/ID. Unique constraint enforced. Can be looked up on blockchain explorers. Format varies by blockchain (hex for ETH/BTC, base58 for SOL/XRP). (Tier 1 - Wallet.SentTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentWalletID` COMMENT 'The source wallet this transaction was sent from. FK to Wallet.Wallets.WalletId. For customer withdrawals, this is the customer''s wallet. For redemptions, this is the system''s omnibus/redeem wallet. (Tier 1 - Wallet.SentTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentTransactionDateTime` COMMENT 'Timestamp when the transaction was broadcast to the blockchain. NULL only for legacy records. (Tier 1 - Wallet.SentTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentBlockchainFee` COMMENT 'Network fee paid in the crypto''s native units. Recorded after on-chain confirmation. Used for cost analysis, customer billing, and financial reconciliation. (Tier 1 - Wallet.SentTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentCryptoID` COMMENT 'The cryptocurrency sent. FK to Wallet.CryptoTypes.CryptoID. Combined with WalletId for per-wallet per-crypto transaction history queries. (Tier 1 - Wallet.SentTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentAmount` COMMENT 'Amount of crypto transferred in the sent transaction. Sourced from Wallet.SentTransactionOutputs.Amount (the output detail record). Matches or closely tracks CryptoAmount. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentEtoroFees` COMMENT 'eToro fees deducted from the blockchain output. Sourced from Wallet.SentTransactionOutputs.EtoroFees. Observed as 0 for all current rows. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentLastStatusID` COMMENT 'Last-known status ID of the sent transaction. Derived by ROW_NUMBER() OVER (PARTITION BY SentTransactionId ORDER BY ests.Occurred DESC) = 1 from Wallet.SentTransactionStatuses. Values: 2=Verified, 6=WavedError. NULL when no sent transaction exists (failed conversions). (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentLastStatus` COMMENT 'Display name for SentLastStatusID. Lookup from WalletDB_Dictionary_TransactionStatus. Values observed: Verified, WavedError. NULL when SentTransactionID is NULL. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `EstimatedFiatAmount` COMMENT 'Estimated fiat amount the customer will receive, in the target fiat currency (determined by Conversions.FiatId). Calculated as CryptoAmount * CryptoToFiatRate (approximately, with fee adjustments). (Tier 1 - C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `EstimatedUsdAmount` COMMENT 'Estimated USD equivalent of the fiat amount. Used as the normalization currency for regulatory limit calculations (GetConversionsUsdSum). When FiatId=1 (USD), equals FiatAmount. (Tier 1 - C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `EstimatedCryptoToUsdRate` COMMENT 'Exchange rate from the source crypto asset to USD at conversion creation time. The primary pricing rate. (Tier 1 - C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `EstimatedFiatToUsdRate` COMMENT 'Exchange rate from the target fiat currency to USD. When target is USD, this is 1.0. Used to derive the cross-rate: CryptoToFiatRate = CryptoToUsdRate / FiatToUsdRate. (Tier 1 - C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `EstimatedCryptoToFiatRate` COMMENT 'Direct exchange rate from source crypto to target fiat. This is the rate shown to the customer. Derived from CryptoToUsdRate / FiatToUsdRate. (Tier 1 - C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `EstimatedDateTime` COMMENT 'UTC timestamp when the estimate was recorded. Matches Conversions.Occurred since both are created in the same transaction. (Tier 1 - C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `C2FConversionID` COMMENT 'Auto-incrementing surrogate primary key. Referenced by all child tables (ConversionStatuses, CryptoTransactions, EstimatedFiatTransactions, FiatTransactions) via ConversionId FK. (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoID` COMMENT 'Crypto asset identifier (external reference). Identifies which cryptocurrency is being sold. Values observed: 4, 64, 107 (likely mapped to assets like BTC, ETH, etc. in an external system). (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `Crypto` COMMENT 'Display name for CryptoID. Lookup from EXW_Wallet.CryptoTypes. Values observed: BTC, ETH, XRP, USDC, SOL, DOGE, ADA, TRX, LTC, and others. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatCurrencyID` COMMENT 'Fiat currency identifier (external reference). Identifies which fiat currency the customer receives. Values observed: 1, 2 (likely USD, EUR). (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatCurrency` COMMENT 'Display name for FiatCurrencyID. Lookup from EXW_Wallet.FiatTypes. Values observed: GBP (50%), EUR (40%), USD (7.5%), AUD (2%). (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoAmount` COMMENT 'Quantity of cryptocurrency being converted. High precision (18 decimals) to handle fractional crypto amounts. This is the gross amount before fees. (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `TotalFeePercentage` COMMENT 'Fee rate applied to the conversion as a decimal fraction (0.1 = 10%). Used to calculate ConversionFeeAmount in FiatTransactions. Zero fee observed for some EtoroPosition conversions. (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `TotalFeeUSD` COMMENT 'Fee amount in USD. Computed by SP: CAST(CryptoAmount AS FLOAT) * CAST(CryptoToUsdRate AS FLOAT) / 100 * TotalFeePercentage. Approximation subject to float precision. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionDateTime` COMMENT 'UTC timestamp when the conversion was created. Default constraint provides automatic timestamping. Indexed DESC for recency queries. Used by time-windowed queries (GetConversionAmounts, GetConversionsUsdSum) via @FromDateTime filter. (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionDateID` COMMENT 'Date integer key (YYYYMMDD) derived from ConversionDateTime. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionDate` COMMENT 'Date portion of ConversionDateTime. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionStatusID` COMMENT 'FK to Dictionary.ConversionToFiatStatuses. Current status in this transition. Values: 1=Pending, 2=Failed, 3=Completed, 4=Rejected. See [UNVERIFIED: codepoint not in EXW_Dictionary.ConversionStatuses] [Conversion To Fiat Status](../../_glossary.md#conversion-to-fiat-status). Included in NC index on ConversionId for covering queries. (Tier 1 - C2F.ConversionStatuses)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionStatus` COMMENT 'Display name for ConversionStatusID. Lookup from WalletConversionDB_Dictionary_ConversionToFiatStatuses. Values: Pending, Failed, Completed, Rejected. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionStatusDateTime` COMMENT 'UTC timestamp of the most recent ConversionStatuses entry (ORDER BY Occurred DESC, Rn=1). Represents when ConversionStatusID was set. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionStatusDateID` COMMENT 'Date integer key (YYYYMMDD) derived from ConversionStatusDateTime. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionStatusDate` COMMENT 'Date portion of ConversionStatusDateTime. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `BlockchainTransactionID` COMMENT 'On-chain transaction hash/identifier. Unique across all rows (UNIQUE constraint). Format varies by blockchain: Ethereum "0x" + 64 hex chars, Ripple uppercase hex, etc. Serves as proof of on-chain execution. (Tier 1 - C2F.CryptoTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FromAddress` COMMENT 'Source blockchain address of the customer''s wallet at conversion time. Sourced from Wallet.CustomerWalletsView.Address, joined on GCID and CryptoId. Reflects the wallet that sent the crypto. NULL (0 observed) for all rows. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ToAddress` COMMENT 'Destination blockchain address where crypto was sent. May include chain-specific qualifiers (Ripple destination tags as "?dt=..."). Repeated addresses across transactions suggest omnibus wallet patterns. (Tier 1 - C2F.CryptoTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `BlockchainFee` COMMENT 'Network/gas fee charged by the blockchain for processing the transaction. Very small values observed (0.000045 XRP, 6e-8 for ERC-20). Deducted from the transfer, not from the conversion amount. (Tier 1 - C2F.CryptoTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoTransactionDateTime` COMMENT 'UTC timestamp when the crypto transaction was recorded. Default constraint auto-sets. (Tier 1 - C2F.CryptoTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoTransactionDateID` COMMENT 'Date integer key (YYYYMMDD) derived from CryptoTransactionDateTime. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoTransactionDate` COMMENT 'Date portion of CryptoTransactionDateTime. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoToFiatRate` COMMENT 'Actual exchange rate from crypto to fiat at execution time. May differ from EstimatedFiatTransactions.CryptoToFiatRate due to market movement. (Tier 1 - C2F.FiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatToUsdRate` COMMENT 'Actual fiat-to-USD exchange rate at execution time. 1.0 when target currency is USD. (Tier 1 - C2F.FiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoToUsdRate` COMMENT 'Actual crypto-to-USD rate at execution time. Primary pricing rate. (Tier 1 - C2F.FiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatAmount` COMMENT 'Actual fiat amount credited to the customer in the target currency. This is the post-fee amount the customer receives. (Tier 1 - C2F.FiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `UsdAmount` COMMENT 'USD equivalent of the fiat amount. Used for regulatory limit calculations. Preferred over EstimatedFiatTransactions.UsdAmount when available. (Tier 1 - C2F.FiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatAccountID` COMMENT 'Customer''s fiat account identifier where the funds were credited. Format varies by target platform (IBAN account number, platform account ID, etc.). (Tier 1 - C2F.FiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatDetails` COMMENT 'Unique client-load reference ID in format "C2F" + 8 digits. Generated by GenerateUniqueClientLoadReferenceId. Serves as external payment reference. Indexed for lookups. (Tier 1 - C2F.FiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RateTime` COMMENT 'UTC timestamp when the exchange rate was locked for this transaction. May precede the Occurred timestamp if rate was locked before the fiat credit was recorded. (Tier 1 - C2F.FiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatTxTime` COMMENT 'UTC timestamp when the fiat transaction was recorded. (Tier 1 - C2F.FiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyTransactionID` COMMENT 'FiatDwhDB transaction ID for the eToro Money fiat settlement event. Matched by C2FCorrelationID = FiatDwhDB.MoneyCorrelationID. NULL (1,567 rows, 10.8%) for EtoroPosition-path conversions. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyTxCreatedDate` COMMENT 'Date the eToro Money transaction was created in FiatDwhDB. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyReferenceNumber` COMMENT 'External reference ID from the eToro Money system. Matches FiatDetails ("C2F" + 8 digits format) for correlated rows, confirming end-to-end reference linkage. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyLastTxStatusID` COMMENT 'Last transaction status ID in the FiatDwhDB system. Values: 2=Settled (all observed rows with data). (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyLastTxStatus` COMMENT 'Display name for eMoneyLastTxStatusID. Lookup from FiatDwhDB_Dictionary_TransactionStatuses. Value observed: Settled. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyHolderAmount` COMMENT 'Fiat amount credited to the eToro Money holder account. Should match FiatAmount for fully settled rows (minor precision differences observed). (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyLastStatusTime` COMMENT 'Timestamp of the eToro Money transaction event. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyProviderTransactionID` COMMENT 'Provider-side transaction ID from the eToro Money settlement system (large numeric ID, ~17 digits). (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyAccountProgram` COMMENT 'eToro Money account program classification. Values: iban, card. Indicates whether the customer''s eToro Money account is bank-account-based or card-based. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyAccountSubProgram` COMMENT 'eToro Money account sub-program. Values observed: IBAN Standard UK, IBAN Green AUS, Card Standard UK. More granular classification within the program type. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyCurrencyBalanceID` COMMENT 'eToro Money currency balance account ID. Internal identifier for the customer''s balance in the eMoney system. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyProviderCurrencyBalanceID` COMMENT 'Provider-side currency balance ID in the eToro Money system. Distinct from eMoneyCurrencyBalanceID, referencing the provider''s ledger entry. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyHolderID` COMMENT 'eToro Money holder account ID. Internal identifier for the customer''s eToro Money account (FiatDwhDB.HolderID). (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyIsValidETM` COMMENT 'Flag indicating whether the customer has a valid eToro Money (ETM) account. 1=valid for all settled rows with eMoney data. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyEntity` COMMENT 'eToro Money legal entity responsible for the fiat settlement. Values: eToro Money UK, eToro Money Malta, eToro Money AUS. Determines which regulatory entity handled the conversion proceeds. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `IsTestAccount` COMMENT 'Flag indicating whether this is an internal test/QA account. Sourced from EXW_dbo.EXW_DimUser.IsTestAccount. 0 for all production rows observed. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `IsRequestDone` COMMENT 'Computed flag: 1 if the Wallet request reached Done status (RequestStatusId=1), 0 otherwise. Derived by SP via #requestdone presence check: CASE WHEN rd.RequestCorrelationID IS NOT NULL THEN 1 ELSE 0 END. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `TribeHolderAmount` COMMENT 'Amount in the Tribe (eToro Money settlement layer) holder account. Sourced from FiatDwhDB Tribe schema, matched via eMoneyProviderTransactionID. Cross-validates against eMoneyHolderAmount. NULL (1,568 rows) for non-eMoney rows. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `TribeTxDateTime` COMMENT 'Timestamp of the Tribe transaction. Sourced from FiatDwhDB Tribe.WorkDate. NULL when TribeHolderAmount is NULL. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `DepositID` COMMENT 'Billing deposit ID from DWH_dbo.Fact_BillingDeposit. Populated only for EtoroPosition conversions (TargetPlatformID=3) where the fiat proceeds fund a trading deposit (FundingTypeID=27). NULL (13,555 rows, 93%) for IbanAccount and EtoroPlatform paths. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `DepositDateTime` COMMENT 'Payment date of the resulting deposit from Fact_BillingDeposit.PaymentDate. NULL when DepositID is NULL. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `DepositModificationTime` COMMENT 'Last modification time of the deposit record from Fact_BillingDeposit.ModificationDate. NULL when DepositID is NULL. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `DepositLastStatusID` COMMENT 'Last payment status ID of the deposit from Fact_BillingDeposit.PaymentStatusID. NULL when DepositID is NULL. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `DepositLastStatus` COMMENT 'Display name for DepositLastStatusID, joined from DWH_dbo.Dim_PaymentStatus. NULL when DepositID is NULL. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `DepositUSD` COMMENT 'USD-normalized deposit amount from Fact_BillingDeposit.AmountUSD. NULL when DepositID is NULL. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RegulationID` COMMENT 'Regulatory jurisdiction ID at conversion time. Sourced from DWH_dbo.Fact_SnapshotCustomer via point-in-time Dim_Range join on LastModificationDateID. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `Regulation` COMMENT 'Regulation name. Lookup from DWH_dbo.Dim_Regulation. Values observed: FCA, ASIC & GAML, and others. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CountryID` COMMENT 'Customer''s country ID at conversion time. Sourced from DWH_dbo.Fact_SnapshotCustomer via point-in-time Dim_Range join. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `Country` COMMENT 'Country name lookup from DWH_dbo.Dim_Country. Values observed: United Kingdom, Australia, and others. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CustomerRegionID` COMMENT 'US state/region ID for US customers only. Computed: Fact_SnapshotCustomer.RegionID when CountryID=219, NULL otherwise. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `State` COMMENT 'US state name for US customers only. Lookup from DWH_dbo.Dim_State_and_Province when CountryID=219, NULL otherwise. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `IsValidCustomer` COMMENT 'Customer validity flag at conversion time from Fact_SnapshotCustomer. 1=valid for all observed rows. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `IsCreditReportValidCB` COMMENT 'Credit bureau report validity flag at conversion time from Fact_SnapshotCustomer. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `PlayerLevelID` COMMENT 'Customer club tier ID at conversion time from Fact_SnapshotCustomer. FK to DWH_dbo.Dim_PlayerLevel. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `Club` COMMENT 'Club tier name lookup from DWH_dbo.Dim_PlayerLevel. Values observed: Bronze, Gold, Silver, Platinum, Diamond. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `PlayerStatusID` COMMENT 'Customer activity status ID at conversion time from Fact_SnapshotCustomer. FK to DWH_dbo.Dim_PlayerStatus. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `PlayerStatus` COMMENT 'Player status name lookup from DWH_dbo.Dim_PlayerStatus. Values observed: Normal. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `WalletEntity` COMMENT 'eToro legal entity responsible for the customer''s wallet. Sourced from EXW_dbo.EXW_WalletEntity joined on GCID and LastModificationDateID. Values: eToroUK, eToroAUS, eToroEU, and others. NULL (317 rows, 2.2%) when no WalletEntity record found for the date. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `AccountManager` COMMENT 'Full name of the customer''s account manager. Computed by SP as DWH_dbo.Dim_Manager.FirstName + '' '' + LastName, joined via Fact_SnapshotCustomer.AccountManagerID. Value "System " indicates no assigned manager. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of when this row was loaded by SP_EXW_C2F_E2E. Batch watermark; reflects the SP execution time, not the conversion time. (Tier 2 - SP_EXW_C2F_E2E)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `C2FCorrelationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `TargetPlatformID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `TargetPlatform` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionCycle` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `LastModificationDateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `LastModificationDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `LastModificationDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RealCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RequestID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RequestCryptoID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RequestDateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RequestLastStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RequestLastStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RequestLastStatusDateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentTransactionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentBlockchainTransactionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentWalletID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentTransactionDateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentBlockchainFee` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentCryptoID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentEtoroFees` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentLastStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `SentLastStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `EstimatedFiatAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `EstimatedUsdAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `EstimatedCryptoToUsdRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `EstimatedFiatToUsdRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `EstimatedCryptoToFiatRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `EstimatedDateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `C2FConversionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `Crypto` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatCurrencyID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatCurrency` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `TotalFeePercentage` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `TotalFeeUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionDateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionStatusDateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionStatusDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ConversionStatusDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `BlockchainTransactionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FromAddress` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `ToAddress` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `BlockchainFee` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoTransactionDateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoTransactionDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoTransactionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoToFiatRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatToUsdRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CryptoToUsdRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `UsdAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatAccountID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatDetails` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `FiatTxTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyTransactionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyTxCreatedDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyReferenceNumber` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyLastTxStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyLastTxStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyHolderAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyLastStatusTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyProviderTransactionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyAccountProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyAccountSubProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyCurrencyBalanceID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyProviderCurrencyBalanceID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyHolderID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyIsValidETM` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `eMoneyEntity` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `IsTestAccount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `IsRequestDone` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `TribeHolderAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `TribeTxDateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `DepositID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `DepositDateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `DepositModificationTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `DepositLastStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `DepositLastStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `DepositUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `RegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `Regulation` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `CustomerRegionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `State` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `IsValidCustomer` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `IsCreditReportValidCB` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `PlayerLevelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `Club` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `PlayerStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `PlayerStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `WalletEntity` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `AccountManager` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 06:29:04 UTC
-- Batch deploy resume: EXW_dbo deploy batch 1
-- Statements: 208/208 succeeded
-- ====================
