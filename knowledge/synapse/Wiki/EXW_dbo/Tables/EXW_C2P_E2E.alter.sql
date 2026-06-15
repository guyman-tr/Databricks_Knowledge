-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_C2P_E2E
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e SET TBLPROPERTIES (
    'comment' = 'EXW_C2P_E2E is the end-to-end reconciliation and analytics table for the Crypto-to-Position (C2P) conversion product. Each row represents a single conversion where a customer sells cryptocurrency and the resulting USD value is used to open a new trading position on the eToro platform - the "E2E" scope spanning from the blockchain crypto send through the eToro position opening. C2P is a subset of the broader Crypto-to-Fiat (C2F) product, filtering exclusively on TargetPlatformID=3 (EtoroPosition). Unlike the C2F IbanAccount path - where fiat is credited to a bank account via eToro Money - the C2P path routes the converted value directly into an eToro trading position via an admin position log entry (CompensationReasonID=134 "Crypto Transfer"). The position is opened by the Dealing system on the customer''s behalf and is classified as an AirDrop (IsAirDrop=1) in Fact_CustomerAction. **Business context**: C2P enables a direct "crypto-to-position" workflow: a customer converts BTC, ETH, SOL, or another supporte...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e SET TAGS (
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
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CorrelationID` COMMENT 'Distributed tracing correlation ID linking this conversion to its Saga.SagaRuns orchestration entry and all cross-service operations. Used as the deduplication key by InsertConversion. Indexed with Id for lookups. All SPs identify conversions by CorrelationId rather than Id. (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ConversionID` COMMENT 'Auto-incrementing surrogate primary key. Referenced by all child tables (ConversionStatuses, CryptoTransactions, EstimatedFiatTransactions, FiatTransactions) via ConversionId FK. (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `TargetPlatformID` COMMENT 'Fiat destination type. FK to Dictionary.FiatConversionTargets. Values: 1=IbanAccount, 2=EtoroPlatform, 3=EtoroPosition. See [Fiat Conversion Target](../../_glossary.md#fiat-conversion-target). Determines the downstream routing of fiat proceeds. DWH note: filtered to TargetPlatformID=3 (EtoroPosition) only; no IbanAccount or EtoroPlatform rows in this table. (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `TargetPlatform` COMMENT 'Display name for TargetPlatformID. Always "EtoroPosition" for all rows in this table. Lookup from WalletConversionDB Dictionary.FiatConversionTargets. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ConversionCycle` COMMENT 'End-to-end reconciliation status. Values: Full Cycle (2,509 rows, 63%) - all six checks pass (CryptoAmount not null, EstimatedFiatAmount not null, BlockchainTransactionID not null, ABS(InitialUnits - SentAmount) < 0.000001, RequestStatus=Done, ConversionStatus=Completed); Other (1,458 rows, 37%) - any check fails. Simpler than the C2F 10-state cycle; C2P only tests position match fidelity and completion. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `LastModificationTime` COMMENT 'Latest event timestamp across all sub-systems: GREATEST of 7 event timestamps including AdminLogRequestOccurred, AdminLogExecutionOccurred, ConversionTime, SentTransactionTime, ConversionStatusTime, RequestTime, and PositionOpenTime. Represents the most recent activity for this conversion row. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `LastModificationDate` COMMENT 'Date portion of LastModificationTime. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `LastModificationDateID` COMMENT 'Date integer key in YYYYMMDD format derived from LastModificationDate. Used as the reference date for the point-in-time customer snapshot join (Fact_SnapshotCustomer BETWEEN Dim_Range.FromDateID AND ToDateID). (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `GCID` COMMENT 'Global Customer ID identifying the customer who initiated the conversion. Validated NOT NULL by InsertConversion (raises error if null). Indexed for customer-scoped queries (GetConversionAmounts, GetConversionsUsdSum). (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RealCID` COMMENT 'Internal CID after deduplication mapping. Sourced from EXW_dbo.EXW_DimUser.RealCID; maps GCID to the canonical customer record. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RequestID` COMMENT 'Auto-incrementing primary key and the primary identifier for a request across the entire wallet system. Referenced by Wallet.RequestStatuses.RequestId as FK. Also used as lookup key by numerous stored procedures. (Tier 1 - Wallet.Requests)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RequestTime` COMMENT 'When the request was created. No default - explicitly set by the calling code. Used for chronological ordering, SLA monitoring, and date-range queries. Indexed descending for recent-request lookups. (Tier 1 - Wallet.Requests)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RequestLastStatusID` COMMENT 'Last-known status ID of the Wallet ConversionToPosition request (RequestTypeId=9). Derived by ROW_NUMBER() OVER (PARTITION BY request Id ORDER BY Timestamp DESC) = 1 from Wallet.RequestStatuses. Values: 1=Done, 2=Error, 7=TransactionVerified. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RequestLastStatus` COMMENT 'Display name for RequestLastStatusID. Lookup from WalletDB Dictionary.RequestStatuses. Values: Done, Error, TransactionVerified. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RequestLastStatusTime` COMMENT 'Timestamp of the last RequestStatuses entry for this ConversionToPosition request. Corresponds to when RequestLastStatusID was set. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `WalletRequestType` COMMENT 'Request type display name. Always "ConversionToPosition" for all rows (RequestTypeId=9 filter applied in SP). Lookup from WalletDB Dictionary.RequestTypes. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentTransactionID` COMMENT 'Auto-incrementing primary key. FK target for Wallet.SentTransactionStatuses, Wallet.SentTransactionOutputs, and Wallet.SentTransactionReplaces. (Tier 1 - Wallet.SentTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentWalletID` COMMENT 'The source wallet this transaction was sent from. FK to Wallet.Wallets.WalletId. For customer withdrawals, this is the customer''s wallet. For redemptions, this is the system''s omnibus/redeem wallet. (Tier 1 - Wallet.SentTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentTransactionTime` COMMENT 'Timestamp when the transaction was broadcast to the blockchain. NULL only for legacy records. (Tier 1 - Wallet.SentTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentBlockchainFee` COMMENT 'Network fee paid in the crypto''s native units. Recorded after on-chain confirmation. Used for cost analysis, customer billing, and financial reconciliation. (Tier 1 - Wallet.SentTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FromAddress` COMMENT 'Source blockchain address of the customer''s wallet at conversion time. Sourced from Wallet.CustomerWalletsView.Address, joined on GCID and CryptoId. Reflects the wallet that sent the crypto. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ToAddress` COMMENT 'Destination blockchain address where crypto was sent. Sourced from Wallet.SentTransactionOutputs.ToAddress (output destination record). May include chain-specific qualifiers. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `BlockchainTransactionID` COMMENT 'On-chain transaction hash/identifier. Unique across all rows (UNIQUE constraint). Format varies by blockchain: Ethereum "0x" + 64 hex chars, Ripple uppercase hex, etc. Serves as proof of on-chain execution. (Tier 1 - C2F.CryptoTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `BlockchainFee` COMMENT 'Network/gas fee charged by the blockchain for processing the transaction. Very small values observed (0.000045 XRP, 6e-8 for ERC-20). Deducted from the transfer, not from the conversion amount. (Tier 1 - C2F.CryptoTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentAmount` COMMENT 'Amount of crypto transferred in the sent transaction. Sourced from Wallet.SentTransactionOutputs.Amount. The Full Cycle check requires ABS(InitialUnits - SentAmount) < 0.000001 for unit reconciliation. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentLastStatusID` COMMENT 'Last-known status ID of the sent blockchain transaction. Derived by ROW_NUMBER() OVER (PARTITION BY SentTransactionId ORDER BY Occurred DESC) = 1 from Wallet.SentTransactionStatuses. NULL when no sent transaction exists. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentLastStatus` COMMENT 'Display name for SentLastStatusID. Lookup from WalletDB Dictionary.TransactionStatus. NULL when SentTransactionID is NULL. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentLastStatusTime` COMMENT 'Timestamp of the last SentTransactionStatuses entry for this transaction. NULL when SentTransactionID is NULL. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `WalletTransactionType` COMMENT 'Transaction type display name for the blockchain send. Always "ConversionToFiat" (TransactionTypeId=12) in EXW_Dictionary - C2P sends use the same wallet transaction type as C2F. Lookup from EXW_Dictionary.TransactionTypes. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `EstimatedFiatAmount` COMMENT 'Estimated fiat amount the customer will receive, in the target fiat currency (determined by Conversions.FiatId). Calculated as CryptoAmount * CryptoToFiatRate (approximately, with fee adjustments). (Tier 1 - C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `EstimatedUsdAmount` COMMENT 'Estimated USD equivalent of the fiat amount. Used as the normalization currency for regulatory limit calculations (GetConversionsUsdSum). When FiatId=1 (USD), equals FiatAmount. (Tier 1 - C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `EstimatedCryptoToUsdRate` COMMENT 'Exchange rate from the source crypto asset to USD at conversion creation time. The primary pricing rate. (Tier 1 - C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `EstimatedFiatToUsdRate` COMMENT 'Exchange rate from the target fiat currency to USD. When target is USD, this is 1.0. Used to derive the cross-rate: CryptoToFiatRate = CryptoToUsdRate / FiatToUsdRate. (Tier 1 - C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `EstimatedCryptoToFiatRate` COMMENT 'Direct exchange rate from source crypto to target fiat. This is the rate shown to the customer. Derived from CryptoToUsdRate / FiatToUsdRate. (Tier 1 - C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `EstimatedTime` COMMENT 'UTC timestamp when the estimate was recorded. Matches Conversions.Occurred since both are created in the same transaction. (Tier 1 - C2F.EstimatedFiatTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CryptoID` COMMENT 'Identifier of the cryptocurrency this request operates on. Implicit reference to Wallet.CryptoTypes.CryptoID. For conversions, this is the source crypto. Combined with Gcid for per-user per-crypto request lookups. (Tier 1 - Wallet.Requests)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `Crypto` COMMENT 'Display name for CryptoID. Lookup from EXW_Wallet.CryptoTypes. Values observed: BTC, ETH, SOL, XRP, and others matching the converted asset. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FiatCurrencyID` COMMENT 'Fiat currency identifier (external reference). Identifies which fiat currency the customer receives. Values observed: 1, 2 (likely USD, EUR). DWH note: always 1 (USD) for EtoroPosition path - C2P conversions exclusively target USD. (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FiatCurrency` COMMENT 'Display name for FiatCurrencyID. Always "USD" for all rows in this table (FiatCurrencyID=1 for EtoroPosition). Lookup from EXW_Wallet.FiatTypes. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CryptoAmount` COMMENT 'Quantity of cryptocurrency being converted. High precision (18 decimals) to handle fractional crypto amounts. This is the gross amount before fees. (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `TotalFeePercentage` COMMENT 'Fee rate applied to the conversion as a decimal fraction (0.1 = 10%). Used to calculate ConversionFeeAmount in FiatTransactions. Zero fee observed for some EtoroPosition conversions. (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `TotalFeeUSD` COMMENT 'Fee amount in USD. Computed by SP: CAST(CryptoAmount AS FLOAT) * CAST(CryptoToUsdRate AS FLOAT) / 100 * TotalFeePercentage. Approximation subject to float precision. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ConversionTime` COMMENT 'UTC timestamp when the conversion was created. Default constraint provides automatic timestamping. Indexed DESC for recency queries. Used by time-windowed queries (GetConversionAmounts, GetConversionsUsdSum) via @FromDateTime filter. (Tier 1 - C2F.Conversions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CryptoTransactionTime` COMMENT 'UTC timestamp when the crypto transaction was recorded. Default constraint auto-sets. (Tier 1 - C2F.CryptoTransactions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ConversionStatusID` COMMENT 'FK to Dictionary.ConversionToFiatStatuses. Current status in this transition. Values: 1=Pending, 2=Failed, 3=Completed, 4=Rejected. See [UNVERIFIED: codepoint not in EXW_Dictionary.ConversionStatuses] [Conversion To Fiat Status](../../_glossary.md#conversion-to-fiat-status). Included in NC index on ConversionId for covering queries. (Tier 1 - C2F.ConversionStatuses)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ConversionStatus` COMMENT 'Display name for ConversionStatusID. Lookup from WalletConversionDB Dictionary.ConversionToFiatStatuses. Values: Pending, Failed, Completed, Rejected. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ConversionStatusTime` COMMENT 'UTC timestamp of the most recent ConversionStatuses entry (ORDER BY Occurred DESC, Rn=1). Represents when ConversionStatusID was last set. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PositionID` COMMENT 'eToro trading position ID opened as a result of this C2P conversion. Sourced from Dealing_staging.etoro_Trade_AdminPositionLog where CompensationReasonID=134, joined via RequestCorrelationID = AdminPositionRequestID. NULL (1,456 rows) for Other-cycle conversions with no matched position. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `AdminLogAmountUnits` COMMENT 'Crypto units amount recorded in the admin position log at the time of position opening. From Dealing_staging.etoro_Trade_AdminPositionLog.AmountInUnits. Used in the Full Cycle unit reconciliation check (ABS(InitialUnits - SentAmount) < 0.000001). (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `HedgeServerID` COMMENT 'ID of the hedge server that processed the position open request. From Dealing_staging.etoro_Trade_AdminPositionLog.HedgeServerID. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `AdminLogRequestOccurred` COMMENT 'Timestamp when the position open was requested by the Dealing system. From Dealing_staging.etoro_Trade_AdminPositionLog.RequestOccurred. One of the 7 timestamps feeding LastModificationTime. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `AdminLogExecutionOccurred` COMMENT 'Timestamp when the position open was executed by the Dealing system. From Dealing_staging.etoro_Trade_AdminPositionLog.ExecutionOccurred. One of the 7 timestamps feeding LastModificationTime. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `AdminLogRate` COMMENT 'Exchange rate (instrument price) at the time of position opening. From Dealing_staging.etoro_Trade_AdminPositionLog.Rate. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `AdminLogRateTime` COMMENT 'Timestamp of the exchange rate used for position opening. From Dealing_staging.etoro_Trade_AdminPositionLog.RateTime. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CompensationCreditID` COMMENT 'Credit transaction ID from the admin position log that links the position open to the compensation/crypto-transfer event. From Dealing_staging.etoro_Trade_AdminPositionLog.CompensationCreditID. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PositionUSD` COMMENT 'USD value of the opened position. Sourced from DWH_dbo.Dim_Position.Amount. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PositionUnits` COMMENT 'Decimal units amount of the opened position. Sourced from DWH_dbo.Dim_Position.AmountInUnitsDecimal. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PositionInitialUnits` COMMENT 'Initial units at position open from DWH_dbo.Dim_Position.InitialUnits. Used in reconciliation with AdminLogAmountUnits and SentAmount. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PositionInitialAmountCents` COMMENT 'Initial position value in cents at open time. Sourced from DWH_dbo.Dim_Position.InitialAmountCents. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PositionOpenTime` COMMENT 'Timestamp when the trading position was opened. Sourced from DWH_dbo.Dim_Position.OpenOccurred. One of the 7 timestamps feeding LastModificationTime. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `InstrumentID` COMMENT 'Trading instrument FK. Sourced from Dealing_staging.etoro_Trade_AdminPositionLog or DWH_dbo.Dim_Position. Identifies the instrument (e.g., BTC/USD, SOL/USD) of the opened position. FK to DWH_dbo.Dim_Instrument. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `InstrumentName` COMMENT 'Instrument name lookup from DWH_dbo.Dim_Instrument. Values: BTC/USD, ETH/USD, SOL/USD, XRP/USD, and others - matching the crypto being converted. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CompensationReasonID` COMMENT 'Compensation reason FK. Always 134 (Crypto Transfer) for all C2P conversions. From DWH_dbo.Fact_CustomerAction.CompensationReasonID for ActionTypeID=36 rows. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CompensationReason` COMMENT 'Compensation reason name. Always "Crypto Transfer" (CompensationReasonID=134) for all rows in this table. Lookup from DWH_dbo.Dim_CompensationReason. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FactActionCompensationOccurred` COMMENT 'Timestamp of the compensation credit event (ActionTypeID=36 in Fact_CustomerAction). Represents when the USD credit was applied to fund the position. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FactActionCompensationAmountUSD` COMMENT 'USD amount of the compensation credit (ActionTypeID=36). Positive value representing the credit applied to fund the position open. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FactActionPositionOpenOccurred` COMMENT 'Timestamp of the position open debit event (ActionTypeID=1 in Fact_CustomerAction). Represents when the trading position was debited from the customer''s balance. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FactActionPositionOpenAmountUSD` COMMENT 'USD amount of the position open action (ActionTypeID=1). Negative value (debit) representing the cost of opening the position. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FactActionPositionOpenInitialUnits` COMMENT 'Initial units for the position open action (ActionTypeID=1) from Fact_CustomerAction.InitialUnits. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `IsAirDrop` COMMENT 'Flag from Fact_CustomerAction for the position open action (ActionTypeID=1). Always 1 for C2P positions - positions opened via AdminPositionLog CompensationReasonID=134 (Crypto Transfer) are classified as AirDrop by the Dealing system. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `Commission` COMMENT 'Commission charged on the position open, from Fact_CustomerAction.Commission where ActionTypeID=1. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FullCommission` COMMENT 'Full (gross) commission on the position open, from Fact_CustomerAction.FullCommission where ActionTypeID=1. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `IsTestAccount` COMMENT 'Flag indicating whether this is an internal test/QA account. Sourced from EXW_dbo.EXW_DimUser.IsTestAccount. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RegulationID` COMMENT 'Regulatory jurisdiction ID at conversion time. Sourced from DWH_dbo.Fact_SnapshotCustomer via point-in-time Dim_Range join on LastModificationDateID. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `Regulation` COMMENT 'Regulation name lookup from DWH_dbo.Dim_Regulation. Values observed: FCA, ASIC & GAML, and others. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CountryID` COMMENT 'Customer''s country ID at conversion time. Sourced from DWH_dbo.Fact_SnapshotCustomer via point-in-time Dim_Range join. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `Country` COMMENT 'Country name lookup from DWH_dbo.Dim_Country. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CustomerRegionID` COMMENT 'US state/region ID for US customers only. Computed: Fact_SnapshotCustomer.RegionID when CountryID=219, NULL otherwise. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `State` COMMENT 'US state name for US customers only. Lookup from DWH_dbo.Dim_State_and_Province when CountryID=219, NULL otherwise. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `IsValidCustomer` COMMENT 'Customer validity flag at conversion time from Fact_SnapshotCustomer. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `IsCreditReportValidCB` COMMENT 'Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau); captured at conversion time from Fact_SnapshotCustomer. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PlayerLevelID` COMMENT 'Customer club tier ID at conversion time from Fact_SnapshotCustomer. FK to DWH_dbo.Dim_PlayerLevel. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `Club` COMMENT 'Club tier name lookup from DWH_dbo.Dim_PlayerLevel. Values observed: Bronze, Gold, Silver, Platinum, Diamond. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PlayerStatusID` COMMENT 'Customer activity status ID at conversion time from Fact_SnapshotCustomer. FK to DWH_dbo.Dim_PlayerStatus. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PlayerStatus` COMMENT 'Player status name lookup from DWH_dbo.Dim_PlayerStatus. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `WalletEntity` COMMENT 'eToro legal entity responsible for the customer''s wallet. Sourced from EXW_dbo.EXW_WalletEntity joined on GCID and LastModificationDateID. Values: eToroUK, eToroAUS, eToroEU, and others. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `AccountManager` COMMENT 'Full name of the customer''s account manager. Computed by SP as DWH_dbo.Dim_Manager.FirstName + '' '' + LastName, joined via Fact_SnapshotCustomer.AccountManagerID. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `LabelID` COMMENT 'Customer label ID at conversion time. Sourced from DWH_dbo.Fact_SnapshotCustomer. FK to DWH_dbo.Dim_Label. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `Lable` COMMENT 'Label name lookup from DWH_dbo.Dim_Label. Note: column name is "Lable" (typo for "Label") - matches the production DDL. (Tier 2 - SP_EXW_C2F_E2E)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of when this row was loaded by SP_EXW_C2F_E2E. Batch watermark; reflects the SP execution time, not the conversion time. (Tier 2 - SP_EXW_C2F_E2E)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CorrelationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ConversionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `TargetPlatformID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `TargetPlatform` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ConversionCycle` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `LastModificationTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `LastModificationDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `LastModificationDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RealCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RequestID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RequestTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RequestLastStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RequestLastStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RequestLastStatusTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `WalletRequestType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentTransactionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentWalletID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentTransactionTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentBlockchainFee` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FromAddress` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ToAddress` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `BlockchainTransactionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `BlockchainFee` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentLastStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentLastStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `SentLastStatusTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `WalletTransactionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `EstimatedFiatAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `EstimatedUsdAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `EstimatedCryptoToUsdRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `EstimatedFiatToUsdRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `EstimatedCryptoToFiatRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `EstimatedTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CryptoID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `Crypto` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FiatCurrencyID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FiatCurrency` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CryptoAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `TotalFeePercentage` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `TotalFeeUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ConversionTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CryptoTransactionTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ConversionStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ConversionStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `ConversionStatusTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PositionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `AdminLogAmountUnits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `HedgeServerID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `AdminLogRequestOccurred` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `AdminLogExecutionOccurred` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `AdminLogRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `AdminLogRateTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CompensationCreditID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PositionUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PositionUnits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PositionInitialUnits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PositionInitialAmountCents` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PositionOpenTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `InstrumentID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `InstrumentName` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CompensationReasonID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CompensationReason` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FactActionCompensationOccurred` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FactActionCompensationAmountUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FactActionPositionOpenOccurred` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FactActionPositionOpenAmountUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FactActionPositionOpenInitialUnits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `IsAirDrop` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `Commission` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `FullCommission` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `IsTestAccount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `RegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `Regulation` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `CustomerRegionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `State` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `IsValidCustomer` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `IsCreditReportValidCB` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PlayerLevelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `Club` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PlayerStatusID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `PlayerStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `WalletEntity` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `AccountManager` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `LabelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `Lable` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:16:39 UTC
-- Batch deploy resume: EXW_dbo deploy batch 2
-- Statements: 182/182 succeeded
-- ====================
