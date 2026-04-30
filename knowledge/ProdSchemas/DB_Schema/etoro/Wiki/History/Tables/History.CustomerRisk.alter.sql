-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.CustomerRisk
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CustomerRisk.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_customerrisk
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_customerrisk (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_customerrisk SET TBLPROPERTIES (
    'comment' = 'Audit log table recording previous states of customer risk flag events - each row captures the "before" state of a risk classification whenever its event status changes in BackOffice.CustomerRisk. Source: etoro.History.CustomerRisk on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CustomerRisk.md).'
);

ALTER TABLE main.general.bronze_etoro_history_customerrisk SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'CustomerRisk',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_customerrisk ALTER COLUMN ID COMMENT 'Surrogate primary key, auto-incremented. NOT FOR REPLICATION prevents identity synchronization in replication topologies. Uniquely identifies each history record. (Tier 1 - upstream wiki, etoro.History.CustomerRisk)';
ALTER TABLE main.general.bronze_etoro_history_customerrisk ALTER COLUMN GCID COMMENT 'Global Customer ID. Identifies the customer whose risk flag is being logged. FK to Customer.CustomerStatic (GCID column). The BackOffice.SetRiskStatus procedure joins via Customer.CustomerStatic to translate CID->GCID before writing. (Tier 1 - upstream wiki, etoro.History.CustomerRisk)';
ALTER TABLE main.general.bronze_etoro_history_customerrisk ALTER COLUMN RiskStatusID COMMENT 'The type of risk flag. FK to Dictionary.RiskStatus. Active values include: 1=Normal, 2=OverTheLimit, 3=FTDOverDailyLimit, 4=TooManyCreditCards, 6=BinToRegCountryConflict, 7=DepositNameConflict, 26=AggressiveTrading, 28=NameConflict, 37=FraudRequestResponseMismatch, 38=OverTheLimitSingleDeposit, 42=CreditCardBruteForce, 63=BinInBlackList, 64=SuspiciousDepositPattern, 67=IPBlackList, 69=RafDeclineFundingAlreadyExists, and many more. 90 total values; many legacy statuses are inactive (IsActive=false). (Tier 1 - upstream wiki, etoro.History.CustomerRisk)';
ALTER TABLE main.general.bronze_etoro_history_customerrisk ALTER COLUMN RiskStatusID (see 3) COMMENT '(see above - full value list in Dictionary.RiskStatus) (Tier 1 - upstream wiki, etoro.History.CustomerRisk)';
ALTER TABLE main.general.bronze_etoro_history_customerrisk ALTER COLUMN Occurred COMMENT 'The UTC timestamp when the risk flag was originally raised (carried from BackOffice.CustomerRisk at the time this history row was written). This is NOT the time when this history row was written - use ModifiedDate for that. Enables reconstructing when a risk event first occurred. (Tier 1 - upstream wiki, etoro.History.CustomerRisk)';
ALTER TABLE main.general.bronze_etoro_history_customerrisk ALTER COLUMN ModifiedDate COMMENT 'The UTC timestamp when this history row was written - i.e., when BackOffice.SetRiskStatus executed the INSERT to this table. Represents the exact moment the risk status changed. Defaults to getutcdate() at insert time. (Tier 1 - upstream wiki, etoro.History.CustomerRisk)';
ALTER TABLE main.general.bronze_etoro_history_customerrisk ALTER COLUMN Remark COMMENT 'Free-text note explaining the reason for the risk flag, entered by the back-office agent. NULL for system-automated risk flags. Carries over from BackOffice.CustomerRisk at the time the history row is written. (Tier 1 - upstream wiki, etoro.History.CustomerRisk)';
ALTER TABLE main.general.bronze_etoro_history_customerrisk ALTER COLUMN RiskEventStatusID COMMENT 'The event status of the risk flag at the time this history row was written (i.e., the "before" state). FK to Dictionary.RiskEventStatus: 1=On (risk actively flagged), 2=InProcess (under investigation), 3=Off (deprecated). After this history row is written, BackOffice.CustomerRisk is updated to the new status. (Tier 1 - upstream wiki, etoro.History.CustomerRisk)';
ALTER TABLE main.general.bronze_etoro_history_customerrisk ALTER COLUMN ManagerID COMMENT 'The back-office manager ID who set this risk status, carried from BackOffice.CustomerRisk. 0 = system-automated (no human agent). NULL = not recorded. Non-zero values reference BackOffice.Manager. Enables accountability tracking for manual risk decisions. (Tier 1 - upstream wiki, etoro.History.CustomerRisk)';

