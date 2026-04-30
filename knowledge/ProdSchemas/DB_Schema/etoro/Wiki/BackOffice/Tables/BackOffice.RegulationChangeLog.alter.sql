-- =============================================================================
-- Databricks ALTER Script: bronze etoro.BackOffice.RegulationChangeLog
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.RegulationChangeLog.md
-- Layer: bronze
-- UC Target: main.finance.bronze_etoro_backoffice_regulationchangelog
-- =============================================================================

-- ---- UC Target: main.finance.bronze_etoro_backoffice_regulationchangelog (business_group=finance) ----
ALTER TABLE main.finance.bronze_etoro_backoffice_regulationchangelog SET TBLPROPERTIES (
    'comment' = 'Audit log of every regulatory jurisdiction change applied to a customer account, recording the before/after regulation, unrealized P&L at the time of change, and related credit snapshot. Source: etoro.BackOffice.RegulationChangeLog on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.RegulationChangeLog.md).'
);

ALTER TABLE main.finance.bronze_etoro_backoffice_regulationchangelog SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'BackOffice',
    'source_table' = 'RegulationChangeLog',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_etoro_backoffice_regulationchangelog ALTER COLUMN RegulationChangeID COMMENT 'Surrogate primary key. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each regulation change event. (Tier 1 - upstream wiki, etoro.BackOffice.RegulationChangeLog)';
ALTER TABLE main.finance.bronze_etoro_backoffice_regulationchangelog ALTER COLUMN CID COMMENT 'Customer ID whose regulation was changed. References Customer.Customer.CID. Multiple rows per CID if customer has changed regulation multiple times. (Tier 1 - upstream wiki, etoro.BackOffice.RegulationChangeLog)';
ALTER TABLE main.finance.bronze_etoro_backoffice_regulationchangelog ALTER COLUMN Occurred COMMENT 'UTC timestamp when the regulation change was executed. Set at the time the ChangeCustomerRegulation procedure runs. (Tier 1 - upstream wiki, etoro.BackOffice.RegulationChangeLog)';
ALTER TABLE main.finance.bronze_etoro_backoffice_regulationchangelog ALTER COLUMN FromRegulationID COMMENT 'The regulation the customer was in before the change. FK to Dictionary.Regulation.ID. Values: 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 9=FSA Seychelles, 11=FSRA, 13=MAS. (Tier 1 - upstream wiki, etoro.BackOffice.RegulationChangeLog)';
ALTER TABLE main.finance.bronze_etoro_backoffice_regulationchangelog ALTER COLUMN ToRegulationID COMMENT 'The regulation the customer was moved to. FK to Dictionary.Regulation.ID. Same value set as FromRegulationID. (Tier 1 - upstream wiki, etoro.BackOffice.RegulationChangeLog)';
ALTER TABLE main.finance.bronze_etoro_backoffice_regulationchangelog ALTER COLUMN UnrealizedPnl COMMENT 'Total unrealized profit/loss across open positions at the moment of regulation change. NULL if customer had no open positions or if this data was not captured for this event type. (Tier 1 - upstream wiki, etoro.BackOffice.RegulationChangeLog)';
ALTER TABLE main.finance.bronze_etoro_backoffice_regulationchangelog ALTER COLUMN CurrentCreditID COMMENT 'Reference to the customer''s credit/account balance record at the time of the regulation change. Links to the History or Credit schema. NULL if not applicable. (Tier 1 - upstream wiki, etoro.BackOffice.RegulationChangeLog)';
ALTER TABLE main.finance.bronze_etoro_backoffice_regulationchangelog ALTER COLUMN DateID COMMENT 'Integer date key for data warehouse joins, likely in YYYYMMDD format. Corresponds to the date portion of Occurred. NULL if not populated. (Tier 1 - upstream wiki, etoro.BackOffice.RegulationChangeLog)';

