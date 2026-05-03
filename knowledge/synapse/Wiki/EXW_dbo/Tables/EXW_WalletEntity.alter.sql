-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_WalletEntity
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity SET TBLPROPERTIES (
    'comment' = 'EXW_WalletEntity provides a daily snapshot of the legal entity assignment for every eToro Wallet user. As eToro operates under multiple regulatory entities (eToroX, eToroEU, eToroDA, eToroSEY, eToroGermany, eToroUS), each wallet customer must be attributed to exactly one entity per day for regulatory, financial, and T&C compliance reporting. Each row answers: "Which legal entity governed this wallet user on this date, and what Terms and Conditions have they accepted?" The table is created by `SP_EXW_WalletEntity` which runs a 13-step pipeline across 13 temp tables. It reads the DWH customer snapshot (for regulatory/country attributes), the WalletDB T&C acceptance records (for T&C history), and the EXW_Settings system (for country-level entity configuration). The WalletEntity assignment follows a strict priority order - T&C acceptance always wins if a user has signed to a specific entity, with country/date-window rules as fallback. Synapse: HASH(GCID), CLUSTERED INDEX(DateID ASC).'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'EXW_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(GCID)',
    'synapse_index' = 'CLUSTERED INDEX(DateID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `Date` COMMENT 'Snapshot date for this row - the `@run` parameter passed to SP_EXW_WalletEntity. One snapshot per user per date. (Tier 2 - SP_EXW_WalletEntity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `DateID` COMMENT 'Snapshot date as YYYYMMDD integer. `CAST(CONVERT(VARCHAR(8), @run, 112) AS INT)`. CLUSTERED INDEX key enabling efficient date-range scans. (Tier 2 - SP_EXW_WalletEntity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `GCID` COMMENT 'Global Customer ID - the platform-wide unique customer identifier. References `Dim_Customer.GCID`. HASH distribution key for this table. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `WalletEntity` COMMENT 'Legal entity governing this wallet user on this date. Resolved via 8-branch CASE: T&C acceptance -> per-customer tag -> eToroDA/eToroEU date windows -> eToroSEY -> settings-based -> eToroGermany/eToroUS -> default eToroX. See Section 2.1. (Tier 2 - SP_EXW_WalletEntity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `TermsAndConditionDate` COMMENT 'Timestamp when the user accepted. Note: column name typo "Occured" preserved from original schema. DWH note: date portion (CAST AS DATE) of the MAX acceptance datetime for the user''s most recent T&C entity group. NULL if user has never accepted T&C. (Tier 1 - Wallet.CustomerTermsAndConditions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `TermsAndConditionTime` COMMENT 'Timestamp when the user accepted. Note: column name typo "Occured" preserved from original schema. DWH note: full datetime of MAX acceptance for the user''s most recent T&C entity group. Stored as datetime despite column name suggesting time-only. NULL if user has never accepted T&C. (Tier 1 - Wallet.CustomerTermsAndConditions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `RegulationID` COMMENT 'Regulatory entity governing this account. FK to Dictionary.Regulation. Changes trigger RegulationChangeDate update. Values in EXW: 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC & GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Passthrough from Fact_SnapshotCustomer. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `CountryID` COMMENT 'Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. Passthrough from Fact_SnapshotCustomer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `JoinDate` COMMENT 'First wallet activation date for this user. `MIN(EXW_Wallet.CustomerWalletsView.Occurred)` per Gcid, filtered to records before @end_date. Used in WalletEntity assignment rules (date-window branches). (Tier 2 - SP_EXW_WalletEntity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `TermsAndConditionTypeID` COMMENT 'Legal entity type identifier that scopes this T&C version. Different eToro entities (eToroX, eToroUS, eToroEU, etc.) may have jurisdiction-specific terms. Part of unique constraint with Version. Implicit reference to the eToro legal entity system. DWH note: renamed TypeId -> TermsAndConditionTypeID; reflects the user''s most recently accepted entity group. NULL if user has never accepted T&C. (Tier 1 - Wallet.TermsAndConditions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `TermsAndConditionVersions` COMMENT 'Version identifier string (e.g., "V1", "V2", "V3"). Combined with TypeId forms a unique business key. Sequential versioning allows easy comparison of acceptance currency. DWH note: `STRING_AGG(Version, '','')` - comma-separated list of all T&C versions accepted by this user within their most recent entity group. NULL if user has never accepted T&C. (Tier 1 - Wallet.TermsAndConditions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `TermsAndConditionIDs` COMMENT 'The T&C version accepted. FK to Wallet.TermsAndConditions.Id. Multiple rows per Gcid reflect acceptance of different versions over time. DWH note: `STRING_AGG(TermsAndConditionId, '','')` - comma-separated list of all T&C IDs accepted by this user within their most recent entity group. NULL if user has never accepted T&C. (Tier 1 - Wallet.CustomerTermsAndConditions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `UpdateDate` COMMENT 'ETL timestamp set to `GETDATE()` at INSERT time. Reflects when SP_EXW_WalletEntity last wrote this row. (Tier 2 - SP_EXW_WalletEntity)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `Date` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `DateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `RealCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `WalletEntity` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `TermsAndConditionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `TermsAndConditionTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `RegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `CountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `JoinDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `TermsAndConditionTypeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `TermsAndConditionVersions` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `TermsAndConditionIDs` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletentity ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 06:35:41 UTC
-- Batch deploy resume: EXW_dbo deploy batch 1
-- Statements: 30/30 succeeded
-- ====================
