-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.WithdrawToFundingAction
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawToFundingAction.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_withdrawtofundingaction
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_withdrawtofundingaction (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction SET TBLPROPERTIES (
    'comment' = 'High-volume append-only audit log of every insert and update to Billing.WithdrawToFunding - captures the full payment processing pipeline history for each withdrawal-to-funding-method transaction, including payment provider responses, exchange rates, and routing XML. Source: etoro.History.WithdrawToFundingAction on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawToFundingAction.md).'
);

ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'WithdrawToFundingAction',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN WithdrawToFundingActionID COMMENT 'Auto-incrementing surrogate PK. IDENTITY NOT FOR REPLICATION. Sequential action identifier across all payment orders. CLUSTERED PK with PAGE compression on HISTORY filegroup. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN WithdrawID COMMENT 'The withdrawal request this payment action belongs to. Implicit FK to Billing.Withdraw. Multiple rows per WithdrawID if the withdrawal has multiple payment attempts or status transitions. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN FundingID COMMENT 'The customer''s payment method (funding instrument) used in this action. Implicit FK to Billing.Funding. NC index ix_HistoryWithdrawToFundingAction_FundingID supports lookup of all actions for a funding method. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN CashoutStatusID COMMENT 'The cashout status at the time of this action. Implicit FK to Dictionary.CashoutStatus. 8=RejectedByProvider dominates at 62%. See Section 2.3 for full distribution. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN CashoutActionStatusID COMMENT 'Type of operation that produced this row: 0=legacy, 1=insert (new BW2F), 2=update (status change). See Section 2.2. Used in NC indexes as leading column for INSERT vs UPDATE partitioning. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN ProcessCurrencyID COMMENT 'Currency in which the payment was processed. Implicit FK to Dictionary.Currency. 1=USD most common. Drives FX conversion logic (BaseExchangeRate, ExchangeRate, ExchangeFee). (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN ManagerID COMMENT 'Back-office manager who triggered this action. Implicit FK to BackOffice.Manager. 0=automated system action. NULL for some legacy rows. NC index ix_HistoryWithdrawToFundingAction_ModificationDate INCLUDES ManagerID. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN Amount COMMENT 'Withdrawal amount at the time of this action in the withdrawal''s currency. May differ from original request amount for partial or reversed withdrawals. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of this action. Leading column in IX_WTFA_ModDate_Withdraw_Funding (time-range queries) and IX_WTFA_Withdraw_Funding_Latest (latest-state lookup). (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN Remark COMMENT 'Human-readable note about this action. Example: "Payout processed by provider". Often NULL for automated actions. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN WithdrawData COMMENT 'Payment-method-specific XML blob containing routing details (IBAN, BIC, sort code, account number, country, etc.) required by the payment provider. Schema varies by FundingType. See Section 2.4 for examples. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN BW2F_ID COMMENT 'The PK of the Billing.WithdrawToFunding record this action tracks. Central link to the payment order. NC index on (CashoutActionStatusID, BW2F_ID, ModDate) and (BW2F_ID, CashoutActionStatusID) for efficient payment-order lookups. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN MatchStatusID COMMENT 'Reconciliation match status for this payment action. Default NULL. 0=unmatched, other values indicate match state with provider records. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN ProtocolMIDSettingsID COMMENT 'Payment protocol/merchant settings identifier. Default 0. Implicit FK to History.ProtocolMIDSettings. Identifies which payment protocol configuration was used. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN AdditionalInformation COMMENT 'Supplemental provider-specific information about this payment action. Often empty string ("") for automated actions. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN MerchantAccountID COMMENT 'Payment processing merchant account used for this action. NULL for actions not requiring a merchant account (e.g., internal routing steps). (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN BaseExchangeRate COMMENT 'Raw market exchange rate at time of payment. NULL when no FX conversion needed. Uses dbo.dtPrice precision type (numeric(16,8)). (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN ExchangeFee COMMENT 'FX fee in basis points applied to the base exchange rate. 100 = 1% fee. NULL when no FX conversion. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN ExchangeRate COMMENT 'Effective exchange rate applied (BaseExchangeRate + ExchangeFee adjustment). NULL when no FX conversion. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN RefundAmountInDepositCurrency COMMENT 'The withdrawal amount expressed in the customer''s original deposit currency after FX conversion. Used for refund/reversal reconciliation. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN CashoutTypeID COMMENT 'Classification of the cashout processing type: 1=automatic/standard. NULL for legacy or manual flow records. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN CashoutModeID COMMENT 'Processing mode identifier: 1=standard mode. NULL for legacy records. Determines which processing pathway was used. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN SchemeId COMMENT 'Payment scheme identifier (added 2021, PAYUS-3900). Identifies the payment network or scheme used by the provider. NULL for older records or flows not using scheme routing. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN ResponseID COMMENT 'External payment provider response/transaction identifier (added 2021, PAYUA-2822). Links to provider''s response record for reconciliation. NULL for older records. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_withdrawtofundingaction ALTER COLUMN RequestExecuteEntryMethodId COMMENT 'Method identifier for how the payment request was executed. 1=standard. NULL for older records or alternate flows. (Tier 1 - upstream wiki, etoro.History.WithdrawToFundingAction)';

