-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.RiskManagementStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskManagementStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_riskmanagementstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_riskmanagementstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_riskmanagementstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table for the outcome/result status of deposit risk management checks. Status 1 (Success) means the deposit passed; all other IDs indicate a specific reason for flagging or blocking the deposit. Source: etoro.Dictionary.RiskManagementStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskManagementStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_riskmanagementstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'RiskManagementStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_riskmanagementstatus ALTER COLUMN RiskManagementStatusID COMMENT 'Primary key identifying the risk check outcome. 1=Success, 2 - 69=block/decline reason. Referenced by Billing.Deposit, Billing.CreditCardAuthentication, Billing.RiskManagementCheck, Billing.RiskManagementConfiguration, Billing.WithdrawToRiskManagementStatus. Set via Billing.DepositSetRiskManagementStatus, Billing.RiskManagementCheckAdd. (Tier 1 - upstream wiki, etoro.Dictionary.RiskManagementStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_riskmanagementstatus ALTER COLUMN Name COMMENT 'Human-readable status label. UNIQUE (DRMS_NAME). Used for reporting, UI, and audit. 68 distinct values in live data (e.g., Success, CardIsBlocked, BinInBlackList, KYCLevel0, ML, BusinessRuleRisk). (Tier 1 - upstream wiki, etoro.Dictionary.RiskManagementStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
