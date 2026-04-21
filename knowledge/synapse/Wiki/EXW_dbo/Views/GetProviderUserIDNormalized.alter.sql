-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.GetProviderUserIDNormalized
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized SET TBLPROPERTIES (
    'comment' = 'GetProviderUserIDNormalized is an AML analyst-facing view that surfaces each AML compliance provider submission event alongside the corresponding user''s DWH-resolved country, regulation entity, player status, and wallet allowance decision. Each row represents one AML provider submission event for a Wallet user (one row per GCID × AMLProviderID × date in EXW_AMLProviderID). The view is named after its key column: ProviderUserIDNormalized - the base64-encoded GCID string with trailing `=` padding stripped, which is the form expected by external AML systems for cross-platform user identity matching. INNER JOINs on Dim_Country and Dim_Regulation ensure only users with valid DWH dimension coverage appear. The row count parity with EXW_AMLProviderID (206,407) confirms that 100% of AML submissions have valid DWH customer records. UserWalletAllowance distribution in this AML-scoped population: Allowed=167,720 (81.2%), NotAllowed=30,961 (15.0%), ReadOnly=7,726 (3.7%) - a higher NotAllowed rate than the overall wall...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'EXW_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A (view)',
    'synapse_index' = 'N/A (view)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `CID` COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Enriched by JOIN to EXW_DimUser on GCID. Aliased from EXW_AMLProviderID.RealCID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `GCID` COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Source: AmlProviderUsers.Gcid. Passthrough from EXW_AMLProviderID. (Tier 2 - SP_EXW_AMLProviderID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `Country` COMMENT 'Country name resolved from Dim_Country via Dim_Customer.CountryID. INNER JOIN guarantees non-NULL. 14 regulation groups observed (CySEC=93,792, FCA=60,898, FinCEN+FINRA=15,169, FSA Seychelles=9,228, BVI=8,375, others). (Tier 3 - Dim_Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `Regulation` COMMENT 'Regulation entity name resolved from Dim_Regulation via Dim_Customer.RegulationID. INNER JOIN guarantees non-NULL. 14 values observed (CySEC=45%, FCA=29%, US-regulated combined=12%). (Tier 3 - Dim_Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `ProviderUserIDNormalized` COMMENT 'Normalized ProviderUserID with base64 trailing ''='' padding stripped. Used for JOIN matching in external KYT systems that expect unpadded identifiers. Logic: CASE WHEN LIKE ''%='' THEN SUBSTRING(…, 0, CHARINDEX(''='', …)) ELSE passthrough END. Passthrough from EXW_AMLProviderID. (Tier 2 - SP_EXW_AMLProviderID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `PlayerStatus` COMMENT 'Player status name resolved from Dim_PlayerStatus via Dim_Customer.PlayerStatusID. LEFT JOIN - NULL if Dim_Customer not matched. 9 values: Normal (162,057), Blocked (25,893), Blocked Upon Request (10,369), Trade & MIMO Blocked (5,038), Block Deposit & Trading (2,308), Deposit Blocked (422), Warning (220), Copy Block (94), Pending Verification (6). (Tier 3 - Dim_PlayerStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `UserWalletAllowance` COMMENT 'Resolved Wallet access decision. Values: ''Allowed'', ''NotAllowed'', ''ReadOnly''. Derived from SelectedValue CASE: 0 -> NotAllowed, 1 -> ReadOnly, 2 or 3 -> Allowed, else -> NotAllowed. Passthrough from EXW_UserSettingsWalletAllowance. In this AML-scoped population: Allowed=167,720, NotAllowed=30,961, ReadOnly=7,726. (Tier 2 - SP_EXW_UserSettingsWalletAllowance)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `CID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `Regulation` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `ProviderUserIDNormalized` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `PlayerStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `UserWalletAllowance` SET TAGS ('pii' = 'none');
