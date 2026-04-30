-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.vWithdrawToFundingAction
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.vWithdrawToFundingAction.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_vwithdrawtofundingaction
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_vwithdrawtofundingaction (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction SET TBLPROPERTIES (
    'comment' = 'Thin projection view over History.WithdrawToFundingAction exposing 12 of 25 columns with a built-in NOLOCK hint - provides a stable, lighter-weight interface for querying payment processing action history without exposing sensitive XML, FX, or provider-specific columns. Source: etoro.History.vWithdrawToFundingAction on the etoro production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.vWithdrawToFundingAction.md).'
);

ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'vWithdrawToFundingAction',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction ALTER COLUMN WithdrawToFundingActionID COMMENT 'Surrogate PK from History.WithdrawToFundingAction. Sequential action ID. (Tier 1 - upstream wiki, etoro.History.vWithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction ALTER COLUMN WithdrawID COMMENT 'The withdrawal request ID. Implicit FK to Billing.Withdraw. (Tier 1 - upstream wiki, etoro.History.vWithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction ALTER COLUMN FundingID COMMENT 'Customer payment instrument ID. Implicit FK to Billing.Funding. (Tier 1 - upstream wiki, etoro.History.vWithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction ALTER COLUMN CashoutStatusID COMMENT 'Status at time of action. FK to Dictionary.CashoutStatus. 8=RejectedByProvider dominates (62%). (Tier 1 - upstream wiki, etoro.History.vWithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction ALTER COLUMN CashoutActionStatusID COMMENT 'Action type: 0=legacy, 1=insert, 2=update. (Tier 1 - upstream wiki, etoro.History.vWithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction ALTER COLUMN ProcessCurrencyID COMMENT 'Currency in which payment was processed. FK to Dictionary.Currency. (Tier 1 - upstream wiki, etoro.History.vWithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction ALTER COLUMN ManagerID COMMENT 'Manager who triggered action. 0=automated. Implicit FK to BackOffice.Manager. (Tier 1 - upstream wiki, etoro.History.vWithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction ALTER COLUMN Amount COMMENT 'Withdrawal amount at time of action. (Tier 1 - upstream wiki, etoro.History.vWithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of this action. (Tier 1 - upstream wiki, etoro.History.vWithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction ALTER COLUMN Remark COMMENT 'Human-readable note (e.g., "Payout processed by provider"). (Tier 1 - upstream wiki, etoro.History.vWithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction ALTER COLUMN BW2F_ID COMMENT 'FK to Billing.WithdrawToFunding.ID - the payment order being tracked. (Tier 1 - upstream wiki, etoro.History.vWithdrawToFundingAction)';
ALTER TABLE main.general.bronze_etoro_history_vwithdrawtofundingaction ALTER COLUMN MatchStatusID COMMENT 'Reconciliation match state. 0=unmatched. (Tier 1 - upstream wiki, etoro.History.vWithdrawToFundingAction)';

