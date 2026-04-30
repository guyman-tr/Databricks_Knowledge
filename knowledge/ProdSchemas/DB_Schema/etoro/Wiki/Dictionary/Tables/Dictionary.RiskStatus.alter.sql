-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.RiskStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_riskstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_riskstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_riskstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining specific risk flags/reasons that can be attached to a customer account. Each status has an IsActive flag and optionally maps to a RiskCategoryID for grouping (velocity, country conflicts, fraud, multiple accounts, etc.). Source: etoro.Dictionary.RiskStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_riskstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'RiskStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_riskstatus ALTER COLUMN RiskStatusID COMMENT 'Primary key identifying the risk flag/reason. NOT FOR REPLICATION. 89 rows in live data. Referenced by BackOffice.Customer, History.BackOfficeCustomer, Billing.FundingCustomerRisk, History.RiskStatus. Set via BackOffice.SetRiskStatus, BackOffice.CusotmerSetRiskStatus, Maintenance.JOB_AffiliateMultipleAccounts. (Tier 1 - upstream wiki, etoro.Dictionary.RiskStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_riskstatus ALTER COLUMN Name COMMENT 'Human-readable risk reason label. Used for reporting, UI, and audit. Values like OverTheLimit, TooManyCreditCards, BinToRegCountryConflict, Affiliate Multiple Accounts. (Tier 1 - upstream wiki, etoro.Dictionary.RiskStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_riskstatus ALTER COLUMN IsActive COMMENT 'Indicates whether the status is active. Inactive (0) = legacy, typically not applied to new customers. Used for filtering in risk reports and assignment logic. (Tier 1 - upstream wiki, etoro.Dictionary.RiskStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_riskstatus ALTER COLUMN RiskCategoryID COMMENT 'Foreign key to Dictionary.RiskCategories. Groups risk statuses (velocity, country, fraud, multiple accounts). NULL for baseline statuses (None, Normal). (Tier 1 - upstream wiki, etoro.Dictionary.RiskStatus)';

