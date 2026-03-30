-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status > 13.3B-row DDR customer daily status dimension - full daily snapshot of every customer''s deposit status, account segmentation, FTD dates across all platforms (TP, IBAN, Options, MoneyFarm), regulation, login activity, and funded/active trading flags, providing the segmentation backbone for the entire DDR framework. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table (Dimension - DDR daily customer status snapshot) | | **Production Source** | Derived from 15+ sources via `SP_DDR_Customer_Daily_Status` - `BI_DB_Client_Balance_CID_Level_New`, `Dim_Customer`, `Fact_SnapshotCustomer`, `Fact_CustomerAction`, `eMoney_Fact_Transaction_Status`, `MIMO_AllPlatforms`, plus 5 population functions | | **Refresh** | Daily - `DELETE WHERE DateID = @dateID` + `INSERT` per business date | | | | | **Synapse Distribution**'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Date COMMENT 'Calendar date - equals parameter `@date`. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DateID COMMENT 'Business date as YYYYMMDD integer. Delete/replace key. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN RealCID COMMENT 'Real customer ID. Population from 5-layer waterfall (TP -> IBAN -> Options -> OptionsMIMO -> MoneyFarm). HASH distribution key. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_FTD_DateID COMMENT 'Trading Platform first-time deposit date (YYYYMMDD). From Dim_Customer where FTDPlatformID=1. NULL if no TP FTD. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_FTD_Date COMMENT 'Trading Platform first-time deposit datetime. From Dim_Customer.FirstDepositDate where FTDPlatformID=1. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_FTDA COMMENT 'Trading Platform first-time deposit amount in USD. From Dim_Customer.FirstDepositAmount where FTDPlatformID=1. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBAN_FTD_DateID COMMENT 'IBAN (eMoney) first-time deposit date (YYYYMMDD). From Dim_Customer where FTDPlatformID=3. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBAN_FTD_Date COMMENT 'IBAN first-time deposit datetime. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBAN_FTDA COMMENT 'IBAN first-time deposit amount in USD. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_External_FTDA COMMENT 'TP external FTD amount - excludes internal transfers (FundingTypeID != 33). From MIMO aggregation. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Global_FTD_DateID COMMENT 'Global first-time deposit date (YYYYMMDD) - earliest across all platforms. MIN(TP, IBAN, Options, MoneyFarm). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Global_FTD_Date COMMENT 'Global first-time deposit datetime - earliest across all platforms. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Global_FTDA COMMENT 'Global first-time deposit amount in USD - amount of the earliest deposit. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsDepositorGlobal COMMENT 'Global depositor flag. 1 when Dim_Customer.FirstDepositDate > ''1900-01-01''. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalDeposited COMMENT 'Deposited today on any platform (excluding internal transfers). ISNULL(0). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalFirstDeposited COMMENT 'First deposit ever on any platform today. From MIMO IsGlobalFTD flag. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalRedeposited COMMENT 'Redeposited today (not FTD, not internal). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalCashedOut COMMENT 'Withdrew today on any platform (excluding internal transfers). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Redeemed COMMENT 'Billing redeem withdrawal today. From MIMO IsRedeem flag. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DepositedTP COMMENT 'Deposited today on Trading Platform (excl internal). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DepositedIBAN COMMENT 'Deposited today on IBAN/eMoney (excl internal). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ReDepositedTP COMMENT 'Redeposited today on TP (not platform FTD, not internal). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ReDepositedIBAN COMMENT 'Redeposited today on IBAN (not platform FTD, not internal). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TPFirstDeposited COMMENT 'First deposit on Trading Platform today. From MIMO IsPlatformFTD. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBANFirstDeposited COMMENT 'First deposit on IBAN/eMoney today. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TPExternalFirstDeposited COMMENT 'First external TP deposit today (excl FundingTypeID=33 internal). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ActiveTraded COMMENT 'Actively traded on this date. From Function_Population_Active_Traders. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN BalanceOnlyAccount COMMENT 'Balance-only account (has balance, no trading/portfolio). From Function_Population_Balance_Only_Accounts. Returns equity value, not 0/1. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Portfolio_Only COMMENT 'Portfolio-only (has portfolio, not actively trading). From Function_Population_Portfolio_Only. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN AccountActive COMMENT 'Account is active. CASE WHEN ActiveTraded=1 OR Portfolio_Only=1 THEN 1 ELSE 0. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN AccountInActive COMMENT 'Account is completely inactive (not in any of the 3 active segments). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN RegulationID COMMENT 'Regulation ID from Fact_SnapshotCustomer for the date range. FK -> DWH_dbo.Dim_Regulation. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DesignatedRegulationID COMMENT 'Designated regulation ID from Fact_SnapshotCustomer. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN PlayerStatusID COMMENT 'Player status ID from Fact_SnapshotCustomer. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsCreditReportValidCB COMMENT 'Credit report valid flag from Fact_SnapshotCustomer. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsValidCustomer COMMENT 'Valid customer flag from Fact_SnapshotCustomer. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN AccountTypeID COMMENT 'Account type ID from Fact_SnapshotCustomer. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN CountryID COMMENT 'Country ID from Fact_SnapshotCustomer. FK -> DWH_dbo.Dim_Country. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MarketingRegion COMMENT 'Marketing region name. From Dim_Country.MarketingRegionManualName joined via CountryID. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MifidCategorizationID COMMENT 'MiFID categorization ID from Fact_SnapshotCustomer. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN PlayerLevelID COMMENT 'Player level ID from Fact_SnapshotCustomer. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsDepositor COMMENT 'TP depositor flag from Fact_SnapshotCustomer (SCD-based). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsFunded COMMENT 'Currently funded. 1 when customer appears in Function_Population_Funded. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstTimeFunded COMMENT 'First time funded today. CASE WHEN FirstFundedDateID = @dateID THEN 1. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstFundedDateID COMMENT 'Date of first funding (YYYYMMDD). From Function_Population_First_Time_Funded. Sentinel 30000101 = never funded. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstActionType COMMENT 'First trading action type (e.g., ''Crypto'', ''Forex'', ''Stocks''). From Function_Population_First_Trading_Action. ''NoAction'' if none or future. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstActionDateID COMMENT 'Date of first trading action (YYYYMMDD). Sentinel 30000101 = no action. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedIn COMMENT 'Logged in today. 1 when ActionTypeID=14 in Fact_CustomerAction. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedInTPDepositor COMMENT 'Logged in today AND is a TP depositor. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedInIBANDepositor COMMENT 'Logged in today AND is an IBAN depositor. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedInGlobalDepositor COMMENT 'Logged in today AND is a global depositor (any platform). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - GETDATE() at insert time. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstIOBDateID COMMENT 'First Instrument Open Balance date (YYYYMMDD). From Function_Population_First_Time_Funded. Added Aug 2025. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstIOBTime COMMENT 'First IOB timestamp. From Function_Population_First_Time_Funded. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Options_FTD_DateID COMMENT 'Options platform first-time deposit date (YYYYMMDD). From Dim_Customer where FTDPlatformID=2. Added Oct 2025. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Options_FTD_Date COMMENT 'Options platform first-time deposit datetime. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Options_FTDA COMMENT 'Options platform first-time deposit amount in USD. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN OptionsFirstDeposited COMMENT 'First deposit on Options platform today. May be set by post-insert UPDATE when MIMO data missing. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DepositedOptions COMMENT 'Deposited today on Options platform (excl internal). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ReDepositedOptions COMMENT 'Redeposited today on Options (not platform FTD, not internal). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarm_FTD_DateID COMMENT 'MoneyFarm first-time deposit date (YYYYMMDD). From Dim_Customer where FTDPlatformID=4. Added Nov 2025. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarm_FTD_Date COMMENT 'MoneyFarm first-time deposit datetime. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarm_FTDA COMMENT 'MoneyFarm first-time deposit amount in USD. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarmFirstDeposited COMMENT 'First deposit on MoneyFarm platform today. CASE WHEN MoneyFarm_FTD_DateID = @dateID THEN 1. (Tier 2 - SP_DDR_Customer_Daily_Status)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_FTD_DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_FTD_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBAN_FTD_DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBAN_FTD_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBAN_FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_External_FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Global_FTD_DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Global_FTD_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Global_FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsDepositorGlobal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalDeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalFirstDeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalRedeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalCashedOut SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Redeemed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DepositedTP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DepositedIBAN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ReDepositedTP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ReDepositedIBAN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TPFirstDeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBANFirstDeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TPExternalFirstDeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ActiveTraded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN BalanceOnlyAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Portfolio_Only SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN AccountActive SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN AccountInActive SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DesignatedRegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN PlayerStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN AccountTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MarketingRegion SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MifidCategorizationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsFunded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstTimeFunded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstFundedDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstActionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstActionDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedIn SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedInTPDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedInIBANDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedInGlobalDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstIOBDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstIOBTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Options_FTD_DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Options_FTD_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Options_FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN OptionsFirstDeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DepositedOptions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ReDepositedOptions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarm_FTD_DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarm_FTD_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarm_FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarmFirstDeposited SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 16:01:52 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 1
-- Statements: 130/130 succeeded
-- ====================
