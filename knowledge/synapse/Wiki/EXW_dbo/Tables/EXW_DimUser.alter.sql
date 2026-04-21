-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_DimUser
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser SET TBLPROPERTIES (
    'comment' = 'EXW_DimUser is the primary customer dimension for the eToro Wallet (EXW) analytics schema. It contains one row per Wallet user - a customer who has an active Wallet account as identified by EXW_Wallet.CustomerWalletsView. As of April 2026 it holds 699,692 users, with daily incremental refreshes by SP_DimUser. The table is populated by joining the Wallet user list (CustomerWalletsView) to DWH_dbo.Dim_Customer, enriching each user with country, regulation, player level, and state/province attributes from DWH dimension tables. Two EXW-specific flags are computed: **IsTestAccount** (from EXW_TestUsers) and **ComplianceClosureEvent** (from EXW_WalletClosedCountryProjects - 1 if the user''s country has had its Wallet service closed/compensated). SP_DimUser uses a three-step merge pattern: 1. Identify new GCIDs (in CustomerWalletsView but not yet in EXW_DimUser) -> INSERT 2. Identify changed attributes for existing users -> UPDATE (triggers UpdateDate = GETDATE()) 3. Previously deleted wallet users are NOT removed (...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'EXW_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(GCID)',
    'synapse_index' = 'CLUSTERED INDEX (GCID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `GCID` COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. HASH distribution key and CLUSTERED INDEX key for this table. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `RealCID` COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `Username` COMMENT 'Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `FirstName` COMMENT 'Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `LastName` COMMENT 'Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `PlayerLevelID` COMMENT 'Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard; 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `VerificationLevelID` COMMENT 'KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `CountryID` COMMENT 'Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `Country` COMMENT 'Denormalized country name from DWH_dbo.Dim_Country.Name, joined on CountryID. Use CountryID for joins; this is a readability label. (Tier 2 - SP_DimUser)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `RegionID` COMMENT 'Marketing region ID from DWH_dbo.Dim_Country.MarketingRegionID, derived from the user''s CountryID. Corresponds to geographic marketing groupings (Africa, UK, North Europe, Arabic GCC, etc.). (Tier 2 - SP_DimUser)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `Region` COMMENT 'Marketing region name from DWH_dbo.Dim_Country.Region, derived from CountryID. Text label corresponding to RegionID. Use RegionID for aggregation. (Tier 2 - SP_DimUser)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `IsTestAccount` COMMENT '1 if this user''s GCID appears in EXW_dbo.EXW_TestUsers (internal/beta test accounts); 0 otherwise. Computed by SP_DimUser via LEFT JOIN. Always filter IsTestAccount=0 in production analytics. (Tier 2 - SP_DimUser)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `CreditReportValid` COMMENT 'DWH-computed: similar to IsValidCustomer but with additional AccountTypeID != 2 exclusion and specific CID exceptions for CountryID=250. Renamed from Dim_Customer.IsCreditReportValidCB. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `UpdateDate` COMMENT 'ETL timestamp set to GETDATE() at INSERT time and refreshed on UPDATE when any tracked attribute changes. Reflects last SP_DimUser write for this row. Range: 2021-05-24 to 2026-04-12. (Tier 2 - SP_DimUser)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `IsValidCustomer` COMMENT 'DWH-computed: 1 when not Popular Investor (PlayerLevelID != 4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `RegulationID` COMMENT 'Regulatory entity governing this account. FK to Dictionary.Regulation. Changes trigger RegulationChangeDate update. Values in EXW: 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC & GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `Regulation` COMMENT 'Denormalized regulation name from DWH_dbo.Dim_Regulation.Name, joined on RegulationID. Use RegulationID for joins. (Tier 2 - SP_DimUser)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `UserRegionID` COMMENT 'Geographic region ID (GeoIP-derived or set). Used alongside CountryID for more granular regional regulation. DWH note: mapped from Dim_Customer.RegionID (state/province region by IP). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `UserRegion_State` COMMENT 'State or province name from DWH_dbo.Dim_State_and_Province, joined on Dim_Customer.RegionID = RegionByIP_ID. Populated mainly for US, Canada, and Australian users. NULL for most non-US users. (Tier 2 - SP_DimUser)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `Club` COMMENT 'Player level club label from DWH_dbo.Dim_PlayerLevel.Name, joined on PlayerLevelID. Common values: Bronze, Silver, Gold, Platinum, Diamond. COLLATE Latin1_General_100_BIN applied on UPDATE to handle Unicode comparisons. (Tier 2 - SP_DimUser)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `ComplianceClosureEvent` COMMENT '1 if this user''s CountryID (and optionally RegulationID) appears in EXW_dbo.EXW_WalletClosedCountryProjects (country had Wallet service closed); 0 otherwise. Computed by SP_DimUser via LEFT JOIN on CountryID with NULL-coalesce on RegulationID. (Tier 2 - SP_DimUser)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `RealCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `Username` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `FirstName` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `LastName` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `PlayerLevelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `VerificationLevelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `CountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `RegionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `Region` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `IsTestAccount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `CreditReportValid` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `IsValidCustomer` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `RegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `Regulation` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `UserRegionID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `UserRegion_State` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `Club` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser ALTER COLUMN `ComplianceClosureEvent` SET TAGS ('pii' = 'none');
