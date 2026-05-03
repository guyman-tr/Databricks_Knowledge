-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_V_RedeemReconciliation
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation SET TBLPROPERTIES (
    'comment' = 'EXW_V_RedeemReconciliation is the production BI view for completed crypto redemption reconciliation. It projects a clean, analyst-friendly lens over EXW_RedeemReconciliation by applying two filters that together guarantee the view only contains fully processed redemptions: - **`EntryAppears = ''BothSidesEntry''`**: Both the eToro billing system and the blockchain wallet system have matching records for the position. Rows where only the eToro side has data (request submitted but not yet blockchain-confirmed) are excluded. - **`[etoro - RedeemStatus] = ''TransactionDone''`**: The eToro platform has marked the redemption as fully complete (status 8). In-progress (TransactionInProcess) and non-terminal states are excluded. These two filters together mean every row in this view represents a redemption where both sides agree: eToro says done, and the blockchain has a matching sent transaction record. The view also cleans up the column surface: - All `etoro - *` prefix columns are renamed to camelCase (`CID`, `Crypto...'
);

ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation SET TAGS (
    'domain' = 'billing',
    'object_type' = 'table',
    'source_schema' = 'EXW_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A (view)',
    'synapse_index' = 'N/A (view)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `PositionID` COMMENT 'The trading position being redeemed. No FK constraint (BIGINT, references Trade.PositionTbl). Indexed with RedeemID (IX_PositionID_RedeemID). Used in idempotency guard: only one active redeem allowed per PositionID. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EntryAppears` COMMENT 'Reconciliation completeness classification. Always `''BothSidesEntry''` in this view (filter applied). Base table values: BothSidesEntry (eToro RedeemStatusID IN 7,8 AND wallet match found), OnlyEtoroSideEntry, NoUserReceiveEntry. (Tier 2 - SP_EXW_RedeemReconciliation)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `IsTestAccount` COMMENT 'Flag indicating whether this is an internal test/QA account. Sourced from EXW_dbo.EXW_DimUser.IsTestAccount, joined via RealCID. (Tier 2 - SP_EXW_RedeemReconciliation)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `RedeemID` COMMENT 'Surrogate PK, auto-increment. Output parameter in Billing.Redeem_Add (SET @RedeemID = SCOPE_IDENTITY()). (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `CID` COMMENT 'Customer ID. Renamed from `[etoro - CID]`. No FK constraint but standard eToro CID referencing the customer who submitted the redemption request. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `GCID` COMMENT 'Global Customer ID of the customer requesting the redemption. Renamed from `[Wallet - RequestingGCID]`. Always populated in this view (TransactionDone filter guarantees wallet-side data). (Tier 1 - WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `CryptoName` COMMENT 'Display name for the crypto asset. Lookup from EXW_dbo.EXW_InternalWallet.CryptoName by etoro-CryptoID. Values: XRP, BTC, ETH, and others. (Tier 2 - SP_EXW_RedeemReconciliation)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `CryptoID` COMMENT 'Crypto-wallet-system identifier for the crypto asset. Renamed from `[etoro - CryptoID]`. Distinct from InstrumentID: CryptoID is the wallet/exchange identifier (e.g., 2=Bitcoin) while InstrumentID is the trading system identifier. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroRedeemStatus` COMMENT 'Current state in the redemption state machine. Renamed from `[etoro - RedeemStatus]`. Always `''TransactionDone''` in this view (filter applied). FK to Dictionary.RedeemStatus in source. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroRedeemReason` COMMENT 'Reason code for non-success outcomes. Renamed from `[etoro - RedeemReason]`. FK to Dictionary.RedeemReason. NULL for successfully completed redemptions (which is the only case present in this view, but the column can still be NULL). (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroRedeemAmount` COMMENT 'Crypto quantity to redeem (decimal precision for crypto amounts). Renamed from `[etoro - RedeemAmount]`. XBT correction for CryptoID=228: value multiplied by 1,000,000 in base table SP. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroRedeemFee` COMMENT 'eToro platform fee on the redemption. Renamed from `[etoro - RedeemFee]`. XBT correction for CryptoID=228: value multiplied by 1,000,000. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroBlockchainFee` COMMENT 'On-chain network fee (gas fee) for the blockchain transfer. Renamed from `[etoro - BlockchainFee]`. Populated for Bitcoin and certain other instruments; NULL where blockchain fees are absorbed or not applicable. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroAmountOnRequestUSD` COMMENT 'Fiat value of the redemption as calculated when the customer submitted the request. Renamed from `[etoro - AmountOnRequestUSD]`. Reflects the crypto price at request time. May differ from EtoroAmountOnCloseUSD if price moved before position closed. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroAmountOnCloseUSD` COMMENT 'Fiat value realized when the position was actually closed. Renamed from `[eToro - AmountOnCloseUSD]` (note capital-T in base table column name). Set when status transitions to PositionClosed (6). (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `FundingID` COMMENT 'The payment method funding record. Renamed from `[etoro - FundingID]`. FK to Billing.Funding(FundingID). Identifies which funding method will receive the fiat payout. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `InstrumentID` COMMENT 'The trading instrument being redeemed. Renamed from `[etoro - InstrumentID]`. FK to Trade.InstrumentMetaData(InstrumentID). (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `RequestDate` COMMENT 'UTC timestamp when the customer submitted the redemption request. Renamed from `[etoro - RequestDate]`. Set to GETUTCDATE() on INSERT by Billing.Redeem_Add. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `ModificationDate` COMMENT 'UTC timestamp of the most recent status change or update. Renamed from `[etoro - ModificationDate]`. Updated on every status change by RedeemStatusUpdate. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `RequestDateID` COMMENT 'Date integer key (YYYYMMDD) derived from `etoro - RequestDate`. Renamed from `[etoro - RequestDateID]`. Computed: CAST(CONVERT(VARCHAR(8), RequestDate, 112) AS INT). Used for partition-windowed 60-day re-run in SP. (Tier 2 - SP_EXW_RedeemReconciliation)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `ModificationDateID` COMMENT 'Date integer key (YYYYMMDD) derived from `etoro - ModificationDate`. Renamed from `[etoro - ModificationDateID]`. Computed: CAST(CONVERT(VARCHAR(8), LastModificationDate, 112) AS INT). (Tier 2 - SP_EXW_RedeemReconciliation)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WithdrawToFundingID` COMMENT 'Link to the withdrawal record. Renamed from `[etoro - WithdrawToFundingID]`. FK to Billing.WithdrawToFunding(ID). Set when the redemption payout is linked to a specific withdrawal-to-funding process. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WithdrawID` COMMENT 'Billing.Withdraw primary key for the withdrawal leg. Renamed from `[etoro - WithdrawID]`. Sourced from Billing.vWithdrawToFunding.WithdrawID via WithdrawToFundingID join. NULL when no withdrawal leg exists. (Tier 2 - SP_EXW_RedeemReconciliation)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroAmount` COMMENT 'Withdrawal amount from Billing.vWithdrawToFunding.Amount. Renamed from `[etoro - Amount]`. Represents the fiat amount in the withdrawal leg. NULL when no WithdrawToFunding record exists. (Tier 2 - SP_EXW_RedeemReconciliation)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroCashoutType` COMMENT 'Cashout type name from Dictionary.CashoutType. Renamed from `[etoro - CashoutType]`. Lookup via Billing.vWithdrawToFunding.CashoutTypeID. NULL when no WithdrawToFunding record exists. (Tier 2 - SP_EXW_RedeemReconciliation)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroProcessorValueDate` COMMENT 'Date when the payment processor credited/debited the funds. Renamed from `[etoro - ProcessorValueDate]`. From Billing.vWithdrawToFunding.ProcessorValueDate. NULL when no WithdrawToFunding record exists. (Tier 2 - SP_EXW_RedeemReconciliation)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroDepotID` COMMENT 'Depot identifier from Billing.vWithdrawToFunding.DepotID. Renamed from `[etoro - DepotID]`. Identifies the payment depot used for fiat settlement. NULL when no WithdrawToFunding record exists. (Tier 2 - SP_EXW_RedeemReconciliation)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroApproved` COMMENT 'Whether the withdrawal has received required approval: 1=Approved, 0=Pending approval. Renamed from `[etoro - Approved]`. DEFAULT=0. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroCashoutStatus` COMMENT 'Current withdrawal status. Renamed from `[etoro - CashoutStatus]`. FK to Dictionary.CashoutStatus. 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled, 5/7/8/14/16/17=specialized states. NULL when no Billing.Withdraw record exists. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroCashoutReason` COMMENT 'Internal reason code for the withdrawal decision. Renamed from `[etoro - CashoutReason]`. References Dictionary.CashoutReason catalog. NULL when no Billing.Withdraw record exists or no reason assigned. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletSendingWalletID` COMMENT 'The source wallet this transaction was sent from. Renamed from `[Wallet - SendingWalletID]`. FK to Wallet.Wallets.WalletId. For redemptions, this is the system''s omnibus/redeem wallet. Always populated in this view. (Tier 1 - WalletDB.Wallet.SentTransactions)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletRedeemID` COMMENT 'Auto-incrementing surrogate PK from WalletDB.Wallet.Redemptions. Renamed from `[Wallet - RedeemID]`. Distribution key HASH(RedeemID) in EXW_FactRedeemTransactions. Always populated in this view. (Tier 1 - WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletPositionID` COMMENT 'Trading platform position being redeemed. Renamed from `[Wallet - PositionID]`. Unique constraint - each position can only be redeemed once. Always populated in this view. (Tier 1 - WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletRequestedAmount` COMMENT 'Gross amount of crypto requested for redemption in native units of CryptoId. Renamed from `[Wallet - RequestedAmount]`. Always populated in this view. (Tier 1 - WalletDB.Wallet.Redemptions)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletRedeemStatus` COMMENT 'Redemption lifecycle outcome derived from latest RequestStatuses record. Renamed from `[Wallet - RedeemStatus]`. Values: Completed (RequestStatusId=1), Error (RequestStatusId=2), Pending (any other status). (Tier 2 - SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletSentTransactionID` COMMENT 'Auto-incrementing PK from WalletDB.Wallet.SentTransactions. Renamed from `[Wallet - SentTransactionID]`. FK target for SentTransactionStatuses, SentTransactionOutputs, SentTransactionReplaces. Always populated in this view. (Tier 1 - WalletDB.Wallet.SentTransactions)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletBlockchainTransactionID` COMMENT 'The on-chain transaction hash/ID. Renamed from `[Wallet - BlockchainTransactionID]`. Format varies by blockchain (hex for ETH/BTC, base58 for SOL/XRP). Can be looked up on blockchain explorers. Always populated in this view. (Tier 1 - WalletDB.Wallet.SentTransactions)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletSenderAddress` COMMENT 'Blockchain address of the sending wallet (the eToro omnibus/redeem wallet). Renamed from `[Wallet - SenderAddress]`. Sourced from EXW_Wallet.CustomerWalletsView.Address joined on SentTransactions.WalletId. (Tier 2 - SP_EXW_RedeemReconciliation)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletReceiverAddress` COMMENT 'Destination blockchain address for this output. Renamed from `[Wallet - ReceiverAddress]`. Filtered by SourceId = PositionId to select the redemption-specific output. Always populated in this view. (Tier 1 - WalletDB.Wallet.SentTransactionOutputs)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletSentAmount` COMMENT 'Amount of crypto sent to this output address. Renamed from `[Wallet - SentAmount]`. Row with highest Amount per SentTransactionId selected via ROW_NUMBER. Always populated in this view. (Tier 1 - WalletDB.Wallet.SentTransactionOutputs)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletSentTXEtoroFees` COMMENT 'eToro service fee for this redemption. Renamed from `[Wallet - SentTXEtoroFees]`. Computed as CAST(EtoroFees × FeeExchangeRate AS NUMERIC(38,8)) in EXW_FactRedeemTransactions. (Tier 2 - SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletSentTTXBlockchainFees` COMMENT 'Network fee allocated to this redemption output. Renamed from `[Wallet - SentTTXBlockchainFees]` (double-T typo preserved from production DDL). Computed as SentTransactions.BlockchainFee / COUNT(outputs per SentTransactionId). (Tier 2 - SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletReceivedTransactionID` COMMENT 'Auto-incrementing PK of the matching ReceivedTransaction. Renamed from `[Wallet - ReceivedTransactionID]`. FK target for ReceivedTransactionStatuses. NULL if the received transaction has not yet been detected (can happen even for TransactionDone rows). (Tier 1 - WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletReceivedAmount` COMMENT 'Amount of crypto received in native units. Renamed from `[Wallet - ReceivedAmount]`. NULL for zero-value transactions or if received transaction not yet detected. Sourced from WalletDB.Wallet.ReceivedTransactions.Amount, matched by BlockchainTransactionId + ReceiverAddress. (Tier 1 - WalletDB.Wallet.ReceivedTransactions)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletEffectiveBlockchainFees` COMMENT 'Actual blockchain fee charged to the customer after any eToro subsidization. Renamed from `[Wallet - EffectiveBlockchainFees]`. Sourced from EXW_FactRedeemTransactions.EffectiveBlockchainFees. May differ from WalletSentTTXBlockchainFees. (Tier 2 - SP_EXW_RedeemReconciliation via EXW_FactRedeemTransactions)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `IsCFD` COMMENT 'Whether the redeemed position is a CFD position. Renamed from `isCFD`. Values: ''Y'' (PositionID found in DWH_dbo.Dim_Position with IsSettled=0 and CloseDateID >= 10 days before SP @date), ''No'' otherwise. Added 2020-10-14. (Tier 2 - SP_EXW_RedeemReconciliation)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `IsGermanBaFin` COMMENT 'German BaFin regulatory indicator. Always 0 - the source query (FROM BI_DB..V_GermanBaFin) is COMMENTED OUT in SP_EXW_RedeemReconciliation. Non-functional. (Tier 2 - SP_EXW_RedeemReconciliation)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `ManagerOpsID` COMMENT 'Operations team staff member ID who handled this redemption. Renamed from `[etoro - ManagerOpsID]`. Set by RedeemStatusUpdate via @ManagerOpsId. NULL for automated redemptions. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `ManagerID` COMMENT 'Manager staff member ID. Renamed from `[etoro - ManagerID]`. Set by RedeemStatusUpdate via @ManagerID. NULL for automated redemptions. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroRemark` COMMENT 'Free-text note added by operations staff. Renamed from `[etoro - Remark]`. Preserved across status updates (ISNULL(@Remark, Remark) pattern). NULL when no ops note was added. (Tier 1 - Billing.Redeem)';
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of when this row was loaded by SP_EXW_RedeemReconciliation. Set to GETDATE() at insert time. Reflects SP execution time, not redemption time. (Tier 2 - SP_EXW_RedeemReconciliation)';

-- ---- Column PII Tags ----
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `PositionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EntryAppears` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `IsTestAccount` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `RedeemID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `CID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `CryptoName` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `CryptoID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroRedeemStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroRedeemReason` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroRedeemAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroRedeemFee` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroBlockchainFee` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroAmountOnRequestUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroAmountOnCloseUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `FundingID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `InstrumentID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `RequestDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `ModificationDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `RequestDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `ModificationDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WithdrawToFundingID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WithdrawID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroCashoutType` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroProcessorValueDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroDepotID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroApproved` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroCashoutStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroCashoutReason` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletSendingWalletID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletRedeemID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletPositionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletRequestedAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletRedeemStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletSentTransactionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletBlockchainTransactionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletSenderAddress` SET TAGS ('pii' = 'direct');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletReceiverAddress` SET TAGS ('pii' = 'direct');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletSentAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletSentTXEtoroFees` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletSentTTXBlockchainFees` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletReceivedTransactionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletReceivedAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `WalletEffectiveBlockchainFees` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `IsCFD` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `IsGermanBaFin` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `ManagerOpsID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `ManagerID` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `EtoroRemark` SET TAGS ('pii' = 'none');
ALTER TABLE main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 06:37:26 UTC
-- Batch deploy resume: EXW_dbo deploy batch 1
-- Statements: 104/104 succeeded
-- ====================
