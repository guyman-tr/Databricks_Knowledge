-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | Property | Value | |----------|-------| | **Object Type** | TABLE | | **Schema** | BI_DB_dbo | | **Row Count** | ~17,860,000 | | **Synapse Distribution** | HASH ( [GCID] ) | | **Synapse Index** | CLUSTERED INDEX ( [GCID] ASC ) | | **Source System** | ComplianceStateDB (production) via external tables | | **Writer SP** | `SP_BI_DB_Scored_Appropriateness_Negative_Market` | | **ETL Pattern** | TRUNCATE-INSERT (daily full reload) | | **Refresh** | Daily (SB_Daily, Priority 20) |'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN RealCID COMMENT 'Customer Real account ID. Maps to Dim_Customer.RealCID. (Tier 1 - etoro.Account.Customer.RealCID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN GCID COMMENT 'Global Customer ID. Distribution key and clustered index column. Maps to Dim_Customer.GCID. (Tier 1 - Account.Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN IsDepositor COMMENT 'Whether the customer has ever deposited (1=yes, 0=no). From Dim_Customer.IsDepositor. (Tier 1 - CustomerStatic.IsDepositor)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN FTD_Date COMMENT 'First Time Deposit date. Renamed from Dim_Customer.FirstDepositDate. (Tier 1 - Fact_BillingDeposit.MIN(DateTimeUTC))';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN FTDDateID COMMENT 'Integer date key for FTD_Date. `CAST(CONVERT(CHAR(8), FirstDepositDate, 112) AS INT)` -> YYYYMMDD format. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN EOW_FTD COMMENT 'End-of-week date containing the FTD. `DATEADD(dd, -(DATEPART(dw, FirstDepositDate) - 7), FirstDepositDate)`. Used for weekly FTD cohort grouping. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN EOM_FTD COMMENT 'End-of-month date containing the FTD. `EOMONTH(FirstDepositDate)`. Used for monthly FTD cohort grouping. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN FTD_Amount COMMENT 'First deposit amount in USD. Renamed from Dim_Customer.FirstDepositAmount. (Tier 1 - Fact_BillingDeposit.Amount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN RegulationID COMMENT 'Current regulation ID. From Dim_Customer.RegulationID. JOINs to Dim_Regulation.DWHRegulationID. (Tier 1 - Dictionary.Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN RegulationName COMMENT 'Current regulation name. Decoded from Dim_Regulation.Name via RegulationID. Example values: CySEC, FCA, ASIC, BVI. (Tier 1 - Dictionary.Regulation, join-enriched via Dim_Customer.RegulationID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN RegionID COMMENT 'Marketing region ID. Renamed from Dim_Country.MarketingRegionID via Dim_Customer.CountryID. (Tier 1 - Dictionary.MarketingRegion, join-enriched)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN RegionName COMMENT 'Marketing region name (manual override). Renamed from Dim_Country.MarketingRegionManualName. May differ from standard Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). (Tier 1 - Ext_Dim_Country manual override, join-enriched)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN CountryID COMMENT 'Country of residence ID. From Dim_Customer.CountryID. JOINs to Dim_Country.CountryID. (Tier 1 - Dictionary.Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN CountryName COMMENT 'Country name. Decoded from Dim_Country.Name via CountryID. (Tier 1 - Dictionary.Country, join-enriched)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN IsKYC_NM_Trading_Experience COMMENT '**VESTIGIAL** - always `-1`. Originally intended for KYC negative-market trading experience score. Scoring logic in SP is commented out. (Tier 2 - SP hardcoded, VESTIGIAL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN IsKYC_NM_Risk_Factor COMMENT '**VESTIGIAL** - always `-1`. Originally intended for KYC negative-market risk factor score. Scoring logic in SP is commented out. (Tier 2 - SP hardcoded, VESTIGIAL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN IsKYC_NM COMMENT '**VESTIGIAL** - always `-1`. Originally intended for combined KYC negative-market pass/fail flag. Scoring logic in SP is commented out. (Tier 2 - SP hardcoded, VESTIGIAL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN AT_Total_Score_KYC COMMENT '**VESTIGIAL** - always `-1`. Originally intended for Appropriateness Test total KYC score. Scoring logic in SP is commented out. (Tier 2 - SP hardcoded, VESTIGIAL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN AT_Total_Max_Potential_Score COMMENT '**VESTIGIAL** - always `-1`. Originally intended for maximum possible AT score. Scoring logic in SP is commented out. (Tier 2 - SP hardcoded, VESTIGIAL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN IsKYC_AT_Passed COMMENT '**VESTIGIAL** - always `-1`. Originally intended for whether customer passed KYC-based AT. Scoring logic in SP is commented out. (Tier 2 - SP hardcoded, VESTIGIAL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN RestrictionStatusDesc COMMENT 'Current CFD restriction status description. From ComplianceStateDB Dictionary.RestrictionStatus.Name. NULL defaults to "Passed" via `ISNULL`. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN CFD_Status COMMENT 'Derived CFD trading status. `CASE WHEN CFDRestrictionStatusID=1 THEN ''CFD_Blocked'' ELSE ''CFD_Allowed''`. 2-value enum: "CFD_Blocked" (20%, 3.6M), "CFD_Allowed" (80%, 14.3M). (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN BlockDate COMMENT 'Date when CFD trading was blocked. From ComplianceStateDB UserTradingData. NULL if never blocked. Source depends on current status: if currently blocked -> current.ReasonDate; if released -> history.ReasonDate. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN BlockReasonID COMMENT 'Block reason FK. Points to ComplianceStateDB Dictionary.RestrictionStatusReason. NULL if never blocked. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN BlockReasonDesc COMMENT 'Block reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusReason.Name. NULL if never blocked. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN ReleaseDate COMMENT 'Date when CFD block was released. Only populated when `CFDRestrictionStatusID = 2` (currently allowed after prior block). NULL if still blocked or never blocked. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN ReleaseReasonID COMMENT 'Release reason FK. Points to ComplianceStateDB Dictionary.RestrictionStatusReason. NULL if not released. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN ReleaseReasonDesc COMMENT 'Release reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusReason.Name. NULL if not released. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN DateDiffBlockRelease COMMENT 'Days between block and release. `DATEDIFF(d, BlockDate, ReleaseDate)`. NULL if not yet released or never blocked. Useful for measuring restriction duration. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN AT_Date COMMENT 'Date the Appropriateness Test was taken. From ComplianceStateDB.Compliance.CustomerRestrictions.BeginTime. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN ApproprietnessScore_Status COMMENT 'Appropriateness test outcome. From ComplianceStateDB Dictionary.RestrictionStatus.Name, filtered to RestrictionStatusReasonID=14. Distribution: "Failed" 75% (13.4M), "Passed" 24% (4.2M), blank 1%, "Borderline Pass" <0.1%. Note: column name contains typo ("Approprietness" vs "Appropriateness"). (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN UpdateDate COMMENT 'ETL execution timestamp. `GETDATE()` - identical across all rows for a given daily load. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market, ETL-computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN DesignatedRegulationName COMMENT 'Designated (target) regulation name. Decoded from Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID. May differ from current RegulationName when a customer is being migrated between regulations. (Tier 1 - Dictionary.Regulation, join-enriched via Dim_Customer.DesignatedRegulationID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN BlockSubReasonID COMMENT 'Block sub-reason FK. Points to ComplianceStateDB Dictionary.RestrictionStatusSubreason. Provides granular classification of why CFD was blocked. NULL if not blocked. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN BlockSubReasonDesc COMMENT 'Block sub-reason name. Decoded from ComplianceStateDB Dictionary.RestrictionStatusSubreason.Name. NULL if not blocked. (Tier 2 - SP_BI_DB_Scored_Appropriateness_Negative_Market, join-enriched)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN IsDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN FTD_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN FTDDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN EOW_FTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN EOM_FTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN FTD_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN RegulationName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN RegionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN RegionName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN CountryName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN IsKYC_NM_Trading_Experience SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN IsKYC_NM_Risk_Factor SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN IsKYC_NM SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN AT_Total_Score_KYC SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN AT_Total_Max_Potential_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN IsKYC_AT_Passed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN RestrictionStatusDesc SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN CFD_Status SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN BlockDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN BlockReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN BlockReasonDesc SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN ReleaseDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN ReleaseReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN ReleaseReasonDesc SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN DateDiffBlockRelease SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN AT_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN ApproprietnessScore_Status SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN DesignatedRegulationName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN BlockSubReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market ALTER COLUMN BlockSubReasonDesc SET TAGS ('pii' = 'none');
