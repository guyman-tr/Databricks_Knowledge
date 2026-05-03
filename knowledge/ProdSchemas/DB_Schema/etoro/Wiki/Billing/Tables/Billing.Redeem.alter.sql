-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.Redeem
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_redeem
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_redeem (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_redeem SET TBLPROPERTIES (
    'comment' = 'Core crypto redemption request table tracking each customer''s request to convert a crypto position back to fiat currency, from initial submission through position closure, blockchain transfer, and final settlement. Source: etoro.Billing.Redeem on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_redeem SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'Redeem',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN RedeemID COMMENT 'Surrogate PK, auto-increment. Output parameter in Billing.Redeem_Add (SET @RedeemID = SCOPE_IDENTITY()). (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN CID COMMENT 'Customer ID. No FK constraint but standard eToro CID referencing the customer who submitted the redemption request. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN PositionID COMMENT 'The trading position being redeemed. No FK constraint (BIGINT, references Trade.PositionTbl). Indexed with RedeemID (IX_PositionID_RedeemID). Used in idempotency guard: only one active redeem allowed per PositionID. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN RedeemStatusID COMMENT 'Current state in the redemption state machine. FK to Dictionary.RedeemStatus. Transitions validated by Dictionary.RedeemStatusStateMachine in RedeemStatusUpdate. Values: 1=PositionPending, 2=Rejected, 3=Approved, 4=ReadyToRedeem, 5=PositionClosing, 6=PositionClosed, 7=TransactionInProcess, 8=TransactionDone, 20=Terminated, 21=FailedToCancel, 25=TransferNegativeBalance, 100=New. Distribution: 20=Terminated (60%), 1=PositionPending (32%). (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN RedeemReasonID COMMENT 'Reason code for non-success outcomes. FK to Dictionary.RedeemReason. Set by RedeemStatusUpdate when redemption fails or is cancelled. Values: 1=RreTradeBlocked, 2=RreFundingBlocked, 7=RejectedByOps, 8=FailedByTrading, 9=FailedByWallet, 10=CanceledByOps, 11-14=ServerErrors, 15=CanceledByUser, etc. NULL for successfully completed redemptions (status=8). (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN Units COMMENT 'Crypto quantity to redeem (decimal precision for crypto amounts). Set on INSERT via @Units. May be updated to actual closed amount when status=6: Units = IIF(@RedeemStatusID = 6, ISNULL(@Units, Units), Units) in RedeemStatusUpdate. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN RedeemFee COMMENT 'eToro platform fee on the redemption. Set on INSERT via @Fee (maps to column RedeemFee). Approximately 2% of the redemption amount based on observed data. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN WalletFee COMMENT 'Fee for the crypto wallet service. Currently always NULL in production data - either not charged separately, deducted from AmountOnClose, or reserved for future use. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN BlockchainFee COMMENT 'On-chain network fee (gas fee) for the blockchain transfer. Populated for Bitcoin (e.g., 0.000256 BTC) and certain other instruments. NULL for instruments where blockchain fees are absorbed or not applicable. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN AmountOnRequest COMMENT 'Fiat value of the redemption as calculated when the customer submitted the request. Set on INSERT via @Amount. Reflects the crypto price at request time. May differ from AmountOnClose if price moves before the position closes. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN AmountOnClose COMMENT 'Fiat value realized when the position was actually closed. Set by RedeemStatusUpdate when status transitions to 6 (PositionClosed): AmountOnClose = IIF(@RedeemStatusID = 6, @Amount, AmountOnClose). NULL until PositionClosed state is reached. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN FundingID COMMENT 'The payment method funding record. FK to Billing.Funding(FundingID). Indexed (IX_BillingRedeem_FundingID). Identifies which funding method will receive the fiat payout. Set on INSERT. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN InstrumentID COMMENT 'The trading instrument being redeemed. FK to Trade.InstrumentMetaData(InstrumentID). Examples: 100001=Bitcoin, 100017=another crypto. Used by multiple procedures for instrument-specific business logic. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN RequestDate COMMENT 'UTC timestamp when the customer submitted the redemption request. Set to GETUTCDATE() on INSERT by Billing.Redeem_Add. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN LastModificationDate COMMENT 'UTC timestamp of the most recent status change or update. Set to GETUTCDATE() on INSERT and updated on every status change by RedeemStatusUpdate. Part of covering index (ix_BillingRedeem_Covering). (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN WithdrawToFundingID COMMENT 'Link to the withdrawal record. FK to Billing.WithdrawToFunding(ID). Set when the redemption payout is linked to a specific withdrawal-to-funding process. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN ManagerOpsID COMMENT 'Operations team staff member ID who handled this redemption. Set by RedeemStatusUpdate via @ManagerOpsId. NULL for automated redemptions. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN ManagerID COMMENT 'Manager staff member ID. Set by RedeemStatusUpdate via @ManagerID. NULL for automated redemptions. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN Remark COMMENT 'Free-text note added by operations staff. Set by RedeemStatusUpdate via @Remark. Preserved across updates (ISNULL(@Remark, Remark) pattern). (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN CryptoID COMMENT 'Crypto-wallet-system identifier for the crypto asset. Set on INSERT. Distinct from InstrumentID: CryptoID is the wallet/exchange identifier (e.g., 2=Bitcoin, 18=another asset) while InstrumentID is the trading system identifier. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN IPAddress COMMENT 'Client IP address at the time the redemption was submitted. Set on INSERT via @IPAddress. Used for fraud/compliance audit. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN NetProfit COMMENT 'Net profit on the redemption after fees. Default=0. Populated by the settlement process. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN RedeemTypeID COMMENT 'Redemption type: 0=Standard crypto-to-fiat (DEFAULT, 99.9% of records), 1=Special type (21 rows, appears to be NFT or internal transfer per procedures GetNFTRedeemDetailsByOperationID). Added in PTL-76 (June 2022). (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
ALTER TABLE main.billing.bronze_etoro_billing_redeem ALTER COLUMN OperationID COMMENT 'External operation reference GUID. Added in PTL-76 alongside RedeemTypeID. Used for NFT redemptions and cross-system operation tracking. (Tier 1 - upstream wiki, etoro.Billing.Redeem)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
