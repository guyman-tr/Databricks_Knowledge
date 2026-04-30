-- =============================================================================
-- Databricks ALTER Script: bronze etoro.BackOffice.CustomerRisk
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_backoffice_customerrisk
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_backoffice_customerrisk (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_backoffice_customerrisk SET TBLPROPERTIES (
    'comment' = 'Active risk flag registry tracking all risk alerts raised against customers, used by Risk team to monitor fraud indicators, AML triggers, deposit velocity, document quality, and behavioral anomalies. Source: etoro.BackOffice.CustomerRisk on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md).'
);

ALTER TABLE main.billing.bronze_etoro_backoffice_customerrisk SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'BackOffice',
    'source_table' = 'CustomerRisk',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_backoffice_customerrisk ALTER COLUMN GCID COMMENT 'Group Customer ID - person-level identifier spanning all accounts across regulatory jurisdictions. Part of composite PK. A customer can have multiple risk flags (different RiskStatusIDs for same GCID). See BackOffice.CustomerDocument for GCID description. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerRisk)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerrisk ALTER COLUMN RiskStatusID COMMENT 'The specific risk alert type. Part of composite PK. FK to Dictionary.RiskStatus. 90 defined types (0=None, 1=Normal, 2-90=specific risk flags). Active types include: velocity checks (2,3,38-42,61,66,68,74,88), country/geo conflicts (6,7,8,17,28,32,72,87), fraud indicators (12,31,37,42,63,64,69,73,89,90), document quality (30,43,45,46,48-50,62,71), affiliate abuse (10,11,60), AML/behavior (26,29,70,82,83). Inactive types (IsActive=false) represent deprecated risk categories. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerRisk)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerrisk ALTER COLUMN Occurred COMMENT 'Timestamp when the risk event originally occurred. Defaults to current UTC time on INSERT. Historical rows with ''1900-01-01'' indicate legacy imports where the original event time was unknown. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerRisk)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerrisk ALTER COLUMN ModifiedDate COMMENT 'Timestamp of the last status change or update to this risk flag. Always reflects the most recent modification. Used for risk queue ordering and SLA tracking. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerRisk)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerrisk ALTER COLUMN Remark COMMENT 'Free-text note by the Risk agent explaining the risk situation, investigation findings, or resolution rationale. Optional - may be NULL for automatically-generated flags before agent review. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerRisk)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerrisk ALTER COLUMN RiskEventStatusID COMMENT 'Current lifecycle status of the risk flag. FK to Dictionary.RiskEventStatus. Values: 1=On (active, requires attention), 2=InProcess (under investigation), 3=Off (resolved/cleared, dictionary IsActive=false). 1.37M rows are On, 97K are InProcess or Off. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerRisk)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customerrisk ALTER COLUMN ManagerID COMMENT 'BackOffice Risk agent who last modified this flag. NULL for system-generated flags not yet reviewed. FK to BackOffice.Manager (no constraint). (Tier 1 - upstream wiki, etoro.BackOffice.CustomerRisk)';

