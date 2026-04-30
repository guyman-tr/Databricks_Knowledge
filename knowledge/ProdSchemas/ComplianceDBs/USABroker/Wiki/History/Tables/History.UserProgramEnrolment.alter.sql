-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.History.UserProgramEnrolment
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/History/Tables/History.UserProgramEnrolment.md
-- Layer: bronze
-- UC Target: main.general.bronze_usabroker_history_userprogramenrolment
-- =============================================================================

-- ---- UC Target: main.general.bronze_usabroker_history_userprogramenrolment (business_group=general) ----
ALTER TABLE main.general.bronze_usabroker_history_userprogramenrolment SET TBLPROPERTIES (
    'comment' = 'System-versioned temporal history table that automatically stores previous versions of Apex.UserProgramEnrolment rows when they are updated, providing a complete audit trail of customer opt-in and opt-out decisions for optional programs (FPSL, CryptoStaking, EthStaking, ProxyVoting). Source: USABroker.History.UserProgramEnrolment on the USABroker production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/History/Tables/History.UserProgramEnrolment.md).'
);

ALTER TABLE main.general.bronze_usabroker_history_userprogramenrolment SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'History',
    'source_table' = 'UserProgramEnrolment',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_usabroker_history_userprogramenrolment ALTER COLUMN GCID COMMENT 'Global Customer ID. Same value as Apex.UserProgramEnrolment.GCID at the time this version was active. (Tier 1 - upstream wiki, USABroker.History.UserProgramEnrolment)';
ALTER TABLE main.general.bronze_usabroker_history_userprogramenrolment ALTER COLUMN UserProgramEnrolmentStatusID COMMENT 'Enrollment decision AT THE TIME this version was active. 0=None, 1=OptIn, 2=OptOut. The transition from one status to the next creates a new history row. See User Program Enrolment Status. (Tier 1 - upstream wiki, USABroker.History.UserProgramEnrolment)';
ALTER TABLE main.general.bronze_usabroker_history_userprogramenrolment ALTER COLUMN UserProgramID COMMENT 'The program this enrollment decision applies to at the time this version was active. 0=None, 1=FPSL, 2=CryptoStaking, 3=EthStaking, 4=ProxyVotingManualPositions, 5=ProxyVotingCopiedPositions. See User Program. (Tier 1 - upstream wiki, USABroker.History.UserProgramEnrolment)';
ALTER TABLE main.general.bronze_usabroker_history_userprogramenrolment ALTER COLUMN BeginTime COMMENT 'When this enrollment version became active (was originally written to Apex.UserProgramEnrolment). Part of the temporal period. (Tier 1 - upstream wiki, USABroker.History.UserProgramEnrolment)';
ALTER TABLE main.general.bronze_usabroker_history_userprogramenrolment ALTER COLUMN EndTime COMMENT 'When this enrollment version was superseded by a newer decision. The update timestamp. Part of the temporal period. Clustered index key (EndTime, BeginTime). (Tier 1 - upstream wiki, USABroker.History.UserProgramEnrolment)';

