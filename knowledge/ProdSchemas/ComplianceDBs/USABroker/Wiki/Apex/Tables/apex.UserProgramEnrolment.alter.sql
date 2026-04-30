-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.apex.UserProgramEnrolment
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.UserProgramEnrolment.md
-- Layer: bronze
-- UC Target: main.general.bronze_usabroker_apex_userprogramenrolment
-- =============================================================================

-- ---- UC Target: main.general.bronze_usabroker_apex_userprogramenrolment (business_group=general) ----
ALTER TABLE main.general.bronze_usabroker_apex_userprogramenrolment SET TBLPROPERTIES (
    'comment' = 'Tracks customer opt-in/opt-out status for optional programs (FPSL, CryptoStaking, EthStaking, ProxyVoting), with composite PK allowing one enrollment record per customer per program. Source: USABroker.apex.UserProgramEnrolment on the USABroker production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.UserProgramEnrolment.md).'
);

ALTER TABLE main.general.bronze_usabroker_apex_userprogramenrolment SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'apex',
    'source_table' = 'UserProgramEnrolment',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_usabroker_apex_userprogramenrolment ALTER COLUMN GCID COMMENT 'Global Customer ID. Part of composite PK with UserProgramID. (Tier 1 - upstream wiki, USABroker.apex.UserProgramEnrolment)';
ALTER TABLE main.general.bronze_usabroker_apex_userprogramenrolment ALTER COLUMN UserProgramEnrolmentStatusID COMMENT 'Enrollment decision. FK to Dictionary.UserProgramEnrolmentStatus: 0=None, 1=OptIn, 2=OptOut. See User Program Enrolment Status. (Dictionary.UserProgramEnrolmentStatus) (Tier 1 - upstream wiki, USABroker.apex.UserProgramEnrolment)';
ALTER TABLE main.general.bronze_usabroker_apex_userprogramenrolment ALTER COLUMN UserProgramID COMMENT 'The program being enrolled in. FK to Dictionary.UserProgram: 0=None, 1=FPSL, 2=CryptoStaking, 3=EthStaking, 4=ProxyVotingManualPositions, 5=ProxyVotingCopiedPositions. See User Program. (Dictionary.UserProgram) (Tier 1 - upstream wiki, USABroker.apex.UserProgramEnrolment)';
ALTER TABLE main.general.bronze_usabroker_apex_userprogramenrolment ALTER COLUMN BeginTime COMMENT 'System versioning row start time. Part of SYSTEM_TIME period for History.UserProgramEnrolment. (Tier 1 - upstream wiki, USABroker.apex.UserProgramEnrolment)';
ALTER TABLE main.general.bronze_usabroker_apex_userprogramenrolment ALTER COLUMN EndTime COMMENT 'System versioning row end time. Part of SYSTEM_TIME period. (Tier 1 - upstream wiki, USABroker.apex.UserProgramEnrolment)';

