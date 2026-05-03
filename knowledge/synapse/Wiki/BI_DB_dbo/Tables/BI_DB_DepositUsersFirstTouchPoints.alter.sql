-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints SET TBLPROPERTIES (
    'comment' = 'BI_DB_DepositUsersFirstTouchPoints > Customer onboarding funnel tracker. Records each milestone event (install, registration, verification steps, first deposit, first trade, first asset-class cross) as a dated row per customer. The grain is (Date, CID) where Date is the date of a specific milestone - one customer can have multiple rows, each on a different milestone date. Covers customers with any milestone in the rolling 2-year lookback from the last @date run. Used for funnel conversion analysis and activation reporting. **Schema**: BI_DB_dbo | **Object Type**: Table | **Quality**: 8.8/10 ---'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN AffiliateID COMMENT 'Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN SubAffiliateID COMMENT 'Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. (Tier 1 - Customer.CustomerStatic, originally Dim_Customer.SubSerialID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Channel COMMENT 'Marketing acquisition channel. From BI_DB_CIDFirstDates.Channel. ISNULL(,''Direct''). Values: Direct, Affiliate, SEM, etc.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN SubChannel COMMENT 'Marketing sub-channel. From BI_DB_CIDFirstDates.SubChannel. ISNULL(,''Direct''). Values: Direct, Google Brand, Affiliate, etc.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Region COMMENT 'Marketing region at registration. From BI_DB_CIDFirstDates.Region (Dim_Country.Region). Values: North Europe, French, Eastern Europe, LATAM, etc.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Country COMMENT 'Country of residence name in English. From BI_DB_CIDFirstDates.Country (Dim_Country.Name).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN State COMMENT 'US state or province name. From BI_DB_CIDFirstDates.State (Dim_State_and_Province.Name for US customers). NULL for non-US.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Desk COMMENT 'Sales/support desk assignment. From Dim_Country.Desk (joined via Country=Name). Examples: "ROW", "Other EU", "Arabic", "USA". NULL if no mapping.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Regulation COMMENT 'Regulatory entity governing this customer. From Dim_Regulation.Name via RegulationID. Values: ASIC, CySEC, FCA, FSAS, etc.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN DesignatedRegulation COMMENT 'Designated (target/assigned) regulatory entity. From Dim_Regulation.Name via DesignatedRegulationID. May differ from Regulation when a customer is being migrated between entities.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FunnelFrom COMMENT 'Funnel origin identifier. From BI_DB_CIDFirstDates.FunnelFromName. Indicates which funnel/product brought the customer.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Platform COMMENT 'Funnel platform name. From BI_DB_CIDFirstDates.FunnelName. Indicates the product platform the customer entered through.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Platform_fromAction_Regs COMMENT 'Platform used at the time of registration. Resolved from Fact_CustomerAction WHERE ActionTypeID=41 (Registration), PlatformID mapped: 105=Android_App, 111=iOS_App, 104=Android_Web, 110=iOS_Web, 117=Desktop_Web. NULL if PlatformID not in this set.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Platform_fromAction_FTD COMMENT 'Platform used at the time of first deposit. Resolved from Fact_CustomerAction WHERE ActionTypeID=7 AND IsFTD=1, same PlatformID mapping. NULL if not in set.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Install COMMENT '1 on the row for the customer''s first install date. PIVOT count of Action=''Install'' from CIDFirstDates.FirstInstallDate.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Registration COMMENT '1 on the row for the customer''s registration date. PIVOT count of Action=''Registration''. 9.5M rows with this flag set.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN VerificationLevel1 COMMENT '1 on the row for the date the customer completed first-level ID verification.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN VerificationLevel2 COMMENT '1 on the row for second-level verification completion date.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN VerificationLevel3 COMMENT '1 on the row for third-level (full) verification completion date.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN EvMatchStatus COMMENT '1 on the row for the date the customer''s eV identity match status was achieved (from CIDFirstDates.EvMatchStatusDate).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN DepositAttDB COMMENT '1 on the row for the customer''s first deposit attempt date (from CIDFirstDates.FirstDepositAttempt).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FTD COMMENT '1 on the row for the customer''s first successful deposit date. 977K rows with this flag set.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN OpenTrade COMMENT '1 on the row for the customer''s first position open date (from CIDFirstDates.FirstPosOpenDate). 1M rows.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FirstNewFunded COMMENT '1 on the row for the customer''s first new-funded event date (from CIDFirstDates.FirstNewFundedDate).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FirstAction COMMENT '1 on the row for the customer''s first trading action date (from BI_DB_First5Actions.FirstActionDate).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN SecondAction COMMENT '1 on the row for the customer''s second trading action date (from BI_DB_First5Actions.SecondActionDate).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FirstCross COMMENT '1 on the row for the customer''s first cross-asset-class trade date (from BI_DB_First5Actions.FirstCrossDate).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FirstDemoTrade COMMENT '**DISABLED** - hardcoded ''19000101'' sentinel in SP. Always 0. Demo table (BI_DB_Demo_CID_Panel) disconnected since 2024-01-15.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN EmailVerification COMMENT '**DISABLED** - always NULL. Removed from SP logic but DDL column remains. 100% NULL in live data.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN DepositView COMMENT '**DISABLED** - always NULL. Was intended for deposit page view events. 100% NULL.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN DepositSubmits COMMENT '**DISABLED** - always NULL. Was intended for deposit form submit events. 100% NULL.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN DepositSubmitClick COMMENT '**DISABLED** - always NULL. 100% NULL.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN PhoneVerification COMMENT '**DISABLED** - always NULL. Removed 2021-12-27. 100% NULL.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN KYCFlow COMMENT '**DISABLED** - always NULL. Removed 2022-07-03 to prevent duplicate records. 100% NULL.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FirstActionType COMMENT 'Detailed asset class of the customer''s first trade. From BI_DB_First5Actions.FirstAction_Detailed. Values (among non-NULL): Real Stocks/ETFs (43.8%), Crypto (33.8%), Copy (10.4%), FX/Commodities/Indices (7.7%), CFD Stocks/ETFs (3.2%), Copy Fund (1.2%). NULL for customers who never traded.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Date COMMENT 'Date of the milestone event for this row. Each customer appears once per distinct milestone date. Multiple milestones on the same date result in one row with multiple flags set. Drives the CLUSTERED INDEX.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN UpdateDate COMMENT 'Timestamp of SP execution. GETDATE() at INSERT time.';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN AffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN SubAffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Channel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN SubChannel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN State SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Desk SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN DesignatedRegulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FunnelFrom SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Platform SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Platform_fromAction_Regs SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Platform_fromAction_FTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Install SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Registration SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN VerificationLevel1 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN VerificationLevel2 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN VerificationLevel3 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN EvMatchStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN DepositAttDB SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN OpenTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FirstNewFunded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FirstAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN SecondAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FirstCross SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FirstDemoTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN EmailVerification SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN DepositView SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN DepositSubmits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN DepositSubmitClick SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN PhoneVerification SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN KYCFlow SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN FirstActionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:47:56 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 78/78 succeeded
-- ====================
