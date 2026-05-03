-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_UserSettingsWalletAllowance
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance SET TBLPROPERTIES (
    'comment' = 'EXW_UserSettingsWalletAllowance holds the resolved Wallet access decision for every EXW user. Each row answers one question: **can this customer use their eToro Wallet right now?** The three possible answers are `Allowed`, `ReadOnly`, and `NotAllowed`. As of April 2026: 604,796 users are Allowed (86.4%), 15,028 are ReadOnly (2.1%), and 79,868 are NotAllowed (11.4%). The resolution logic applies a five-level priority system. Country + Regulation rules take highest precedence; customer-level individual overrides from the Settings database take second highest. The SP evaluates all applicable rules and selects the one with the highest `RestrictionWeight`, recording the winning tag and raw value alongside the resolved allowance string. Compensation and compliance closure columns surface two compliance-driven overlays: whether the user was financially compensated as part of a Wallet closure project (Compensated, CompensationDate, Project), and whether the user''s country of residence has ever had a Wallet closure...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'EXW_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(GCID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `GCID` COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. HASH distribution key for this table. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `RealCID` COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `UserWalletAllowance` COMMENT 'Resolved Wallet access decision. Values: ''Allowed'' (86.4% - 604,796 users), ''NotAllowed'' (11.4% - 79,868 users), ''ReadOnly'' (2.1% - 15,028 users). Derived from SelectedValue CASE: 0 -> NotAllowed, 1 -> ReadOnly, 2 or 3 -> Allowed, else -> NotAllowed. (Tier 2 - SP_EXW_UserSettingsWalletAllowance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `TagType` COMMENT 'Tag type of the winning settings rule. Identifies the dimension (geography tier or individual) that produced the allowance decision. Values: CountryAndRegion (87.5%), CustomerData (10.4%), DynamicGroup (1.1%), CountryAndRegulation, CountryRegionAndRegulation. (Tier 2 - SP_EXW_UserSettingsWalletAllowance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `TagValue` COMMENT 'Tag value of the winning settings rule. Lowercase country name, regulation name, group name, or GCID string depending on TagType. Example: ''israel'', ''united kingdom'', ''fca'', or a GCID numeric string for CustomerData overrides. (Tier 2 - SP_EXW_UserSettingsWalletAllowance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `SelectedValue` COMMENT 'Raw integer value from the winning EXW_Settings.SystemRestrictions rule. 0=NotAllowed, 1=ReadOnly, 2=Allowed, 3=AllowedForExistingUsers. Source of UserWalletAllowance before CASE mapping. (Tier 2 - SP_EXW_UserSettingsWalletAllowance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `AllowanceBeginDate` COMMENT 'BeginDate of the winning settings restriction from EXW_Settings.SystemRestrictions. NULL for approximately 1,672 users where the winning rule has no BeginDate. (Tier 2 - SP_EXW_UserSettingsWalletAllowance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `Compensated` COMMENT '1 if the user''s GCID appears in EXW_CompensationClosingCountries with a qualifying CompensationDate; 0 otherwise. 51,895 users (7.4%) are compensated. (Tier 2 - SP_EXW_UserSettingsWalletAllowance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `ComplianceClosureEvent` COMMENT '1 if the user''s CountryID (optionally RegulationID) is found in EXW_WalletClosedCountryProjects, indicating the user is in a country that has had a Wallet closure event. 18,690 users (2.7%). (Tier 2 - SP_EXW_UserSettingsWalletAllowance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `CompensationDate` COMMENT 'Date the user was compensated. TOP 1 per GCID ordered by DateClosure DESC (most recent closure event). NULL when Compensated=0. (Tier 2 - SP_EXW_UserSettingsWalletAllowance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `Project` COMMENT 'Closure project identifier for the compensation event. TOP 1 per GCID ordered by DateClosure DESC. Project letters map to country-closure batches (A=31, B=35, C=15, D=4, E=1, F=2, H=1 rows in EXW_WalletClosedCountryProjects). NULL when Compensated=0. (Tier 2 - SP_EXW_UserSettingsWalletAllowance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `UpdateDate` COMMENT 'ETL timestamp set to GETDATE() at INSERT. Reflects the last TRUNCATE+INSERT cycle. All rows share the same UpdateDate per daily run. Current value: 2026-04-13. (Tier 2 - SP_EXW_UserSettingsWalletAllowance)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `RealCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `UserWalletAllowance` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `TagType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `TagValue` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `SelectedValue` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `AllowanceBeginDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `Compensated` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `ComplianceClosureEvent` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `CompensationDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `Project` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 06:35:19 UTC
-- Batch deploy resume: EXW_dbo deploy batch 1
-- Statements: 26/26 succeeded
-- ====================
