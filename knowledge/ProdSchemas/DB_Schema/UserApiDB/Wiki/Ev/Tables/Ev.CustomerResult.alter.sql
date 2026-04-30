-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Ev.CustomerResult
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Ev/Tables/Ev.CustomerResult.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_ev_customerresult
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_ev_customerresult (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_ev_customerresult SET TBLPROPERTIES (
    'comment' = 'Stores the outcome of each Electronic Verification attempt per user, including provider, status, and transaction details. Source: UserApiDB.Ev.CustomerResult on the UserApiDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Ev/Tables/Ev.CustomerResult.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_ev_customerresult SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Ev',
    'source_table' = 'CustomerResult',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_ev_customerresult ALTER COLUMN CustomerEvResultId COMMENT 'Primary key. EV result record ID. Referenced by History.EvRequest. (Tier 1 - upstream wiki, UserApiDB.Ev.CustomerResult)';
ALTER TABLE main.compliance.bronze_userapidb_ev_customerresult ALTER COLUMN GCID COMMENT 'User who was verified. Multiple results per user. (Tier 1 - upstream wiki, UserApiDB.Ev.CustomerResult)';
ALTER TABLE main.compliance.bronze_userapidb_ev_customerresult ALTER COLUMN EvStatusId COMMENT 'FK to Dictionary.EvStatus. Outcome: 0=None, 1=One Source, 2=Two Sources, 5=Approved, 6=Rejected. See EV Status. (Tier 1 - upstream wiki, UserApiDB.Ev.CustomerResult)';
ALTER TABLE main.compliance.bronze_userapidb_ev_customerresult ALTER COLUMN EvProviderId COMMENT 'FK to Dictionary.EvProvider. Which provider performed this verification. See EV Provider. (Tier 1 - upstream wiki, UserApiDB.Ev.CustomerResult)';
ALTER TABLE main.compliance.bronze_userapidb_ev_customerresult ALTER COLUMN TransactionID COMMENT 'Provider''s transaction/reference ID for this verification attempt. (Tier 1 - upstream wiki, UserApiDB.Ev.CustomerResult)';
ALTER TABLE main.compliance.bronze_userapidb_ev_customerresult ALTER COLUMN TransactionDate COMMENT 'When the verification transaction occurred. (Tier 1 - upstream wiki, UserApiDB.Ev.CustomerResult)';
ALTER TABLE main.compliance.bronze_userapidb_ev_customerresult ALTER COLUMN VerificationType COMMENT 'Type of verification performed. (Tier 1 - upstream wiki, UserApiDB.Ev.CustomerResult)';

