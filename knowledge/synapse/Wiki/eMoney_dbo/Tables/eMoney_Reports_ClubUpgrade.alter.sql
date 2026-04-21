-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Reports_ClubUpgrade
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade
-- Resolved via: information_schema bulk query
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade SET TBLPROPERTIES (
    'comment' = '`eMoney_Reports_ClubUpgrade` records every eToro Club tier upgrade event for customers eligible for eToro Money, starting from 2023-01-01. Each row represents a single upgrade event for a single customer - the moment when their club tier moved upward (e.g., Bronze to Silver, Silver to Gold). Upgrades-only: tier downgrades or lateral moves are excluded (`WHERE sort_current > sort_previous`). The table contains 1,178,170 upgrade events across ~1.178M records. The distribution shows Silver as the most common upgrade destination (371K), followed by Bronze-entry (first tier assignment, 296K), Gold (284K), Platinum (144K), Platinum Plus (75K), and Diamond (7.5K). UK accounts represent ~24% (281K), EU ~76% (897K). **Customer eligibility filter**: Only depositors who are valid customers, fully KYC-verified (VerificationLevelID=3), and whose PlayerStatusID is not in (2=Internal, 4=Blocked, 14=Pending Delete, 15=Deleted) are included. This means the table captures the eToro Club upgrade lifecycle specifically for el...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(CID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `CID` COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. DWH note: column renamed from RealCID (Dim_Customer) for eMoney context; joins back via CID=RealCID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `GCID` COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Club` COMMENT 'Current club tier name after the upgrade event (e.g., ''Bronze'', ''Silver'', ''Gold'', ''Platinum'', ''Platinum Plus'', ''Diamond''). Resolved from DWH_dbo.Dim_PlayerLevel.Name using the current PlayerLevelID. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Previous_Club` COMMENT 'Club tier name immediately before the upgrade event (e.g., ''N/A'', ''Bronze'', ''Silver'', ''Gold''). ''N/A'' indicates the customer''s first tier assignment (Previous_ClubID=0). Resolved from Dim_PlayerLevel.Name using the LAG-computed Previous_PlayerLevelID. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Club_ID` COMMENT 'PlayerLevelID of the upgraded-to tier: 0=N/A, 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond. FK to DWH_dbo.Dim_PlayerLevel. Note: IDs are NOT in rank order - use Dim_PlayerLevel.Sort for ranking. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Previous_ClubID` COMMENT 'PlayerLevelID of the tier before the upgrade: 0=N/A (first assignment), 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond. ETL-computed via LAG window function on Fact_SnapshotCustomer. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Club_Upgrade_Date` COMMENT 'Calendar date when the club upgrade event occurred, derived from DWH_dbo.Dim_Date.FullDate. Corresponds to the FromDate of the Fact_SnapshotCustomer period where the tier change was detected. Range: 2023-01-01 to present (SP hardcodes 20230101 lower bound). (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Is_eTM` COMMENT 'Binary flag: 1 if the customer has an active valid eToro Money account at SP execution time (eMoney_Dim_Account.IsValidETM=1 AND GCID_Unique_Count=1), 0 otherwise. 74.5% = 1; 25.5% = 0. Not the eTM status at time of upgrade - reflects current account state. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `UK/EU` COMMENT 'Geographic segment: ''UK'' if DWH_dbo.Dim_Customer.CountryID = 218 (United Kingdom), ''EU'' for all other eToro Money rollout countries (including Norway, Denmark, Australia). Not a strict EU regulatory classification. Distribution: EU=76%, UK=24%. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Country` COMMENT 'Country name for the customer at upgrade time, from eMoney_dbo.eMoney_Dim_Country_Rollout.CountryName. Only eToro Money rollout countries are included (inner join scope). Examples: ''Spain'', ''France'', ''Germany'', ''United Kingdom''. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `AccountProgram` COMMENT 'eToro Money product type for the customer''s account: ''card'' (debit card) or ''iban'' (IBAN banking). Passthrough from eMoney_Dim_Account.AccountProgram (IsValidETM=1, GCID_Unique_Count=1 filter). NULL if Is_eTM=0 (no qualifying eTM account). (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `AccountSubProgram` COMMENT 'Specific sub-program variant for the customer''s eTM account (e.g., ''IBAN EU Green'', ''IBAN Standard UK'', ''Card Standard UK'', ''Card Black EU'', ''Card Premium UK''). Passthrough from eMoney_Dim_Account.AccountSubProgram. NULL if Is_eTM=0. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `UpdateDate` COMMENT 'ETL execution timestamp set to GETDATE() when SP_eMoney_Reports_Daily ran. Reflects data freshness, not event timing. Use Club_Upgrade_Date for when the upgrade occurred. (Tier 2 - SP_eMoney_Reports_Daily)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `CID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Club` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Previous_Club` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Club_ID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Previous_ClubID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Club_Upgrade_Date` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Is_eTM` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `UK/EU` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `AccountProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `AccountSubProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
