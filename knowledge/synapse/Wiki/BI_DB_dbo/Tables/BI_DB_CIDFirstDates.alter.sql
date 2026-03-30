-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_CIDFirstDates
-- Generated: 2026-03-15 | 14-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates
-- Resolved via: mapping view (main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables)
-- Downstream propagation: see BI_DB_CIDFirstDates.downstream.alter.sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates SET TBLPROPERTIES (
    'comment' = 'Customer lifecycle milestone table - one row per CID. Tracks registration, first/last dates for deposit, login, position open, copy-trade, cashout, verification. Includes demographics, acquisition channel, regulation, funded status. Source: Multiple DWH tables (Dim_Customer, Fact_CustomerAction, Fact_BillingDeposit) via SP_CIDFirstDates. Refresh: Daily. Synapse: HASH(CID), CLUSTERED INDEX on CID. UC: Delta, unpartitioned. Gotchas: 1900-01-01 = sentinel (no event), Verified is 0-3 not boolean, ~16 deprecated columns (KYC, PEP, RiskGroup). FirstMenualPosOpenDate is typo for Manual.'
);

-- ---- Table Tags ----
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates SET TAGS (
    'domain' = 'customer',
    'object_type' = 'fact',
    'source_schema' = 'BI_DB_dbo',
    'source_server' = 'Synapse',
    'refresh_frequency' = 'daily',
    'sla' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(CID)',
    'synapse_index' = 'CLUSTERED INDEX',
    'uc_format' = 'delta',
    'uc_partitioned_by' = 'none',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase',
    'semantic_grade' = '4'
);

-- ---- Column Comments ----
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN CID COMMENT 'Customer ID - primary identifier for a customer in the eToro platform. Maps to Dim_Customer.RealCID. Distribution key; always filter/join on CID. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN GCID COMMENT 'Global Customer ID - globally unique customer identifier across all eToro entities. From Dim_Customer.GCID. Used for cross-system joins (e.g., ComplianceStateDB uses GCID). (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN OriginalCID COMMENT 'Original CID before account merge or migration. From Dim_Customer.OriginalCID. Useful for tracking merged accounts. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN UserName COMMENT 'Customer''s eToro username (display name on the platform). PII. From Dim_Customer.UserName. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Club COMMENT 'Customer''s eToro Club tier level. Resolved from Dim_PlayerLevel.Name via PlayerLevelID. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Updated daily. (Tier 2 - SP code, Dim_PlayerLevel)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SerialID COMMENT 'Affiliate serial ID. From Dim_Customer.AffiliateID. Identifies the affiliate partner who referred this customer. 0 = no affiliate. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Channel COMMENT 'Marketing acquisition channel. Resolved from Dim_Channel via Dim_Affiliate.SubChannelID. Values: Direct, Affiliate, SEM, SEO, Mobile Acquisition, Media Performance, Friend Referral, etc. Default ''Direct'' when NULL. (Tier 2 - SP code, Dim_Channel)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SubChannel COMMENT 'Sub-channel within the acquisition channel. Resolved from Dim_Channel. Values: Direct Mobile, Affiliate, Direct, SEO, Mobile CPA, Google UAC, Google Brand, FB, YT, ASA, etc. Default ''Direct'' when NULL. (Tier 2 - SP code, Dim_Channel)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LabelName COMMENT 'Platform brand/label the customer registered under. Resolved from Dim_Label.Name via LabelID. Values: eToro (~97%), eToroRussia, ICMarkets, eToroChina, Royal-CM, eToroUSA, etc. (Tier 2 - SP code, Dim_Label)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Country COMMENT 'Customer''s country of registration. Resolved from Dim_Country.Name via CountryID. (Tier 2 - SP code, Dim_Country)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Language COMMENT 'Customer''s platform language preference. Resolved from Dim_Language.Name via LanguageID. (Tier 2 - SP code, Dim_Language)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Region COMMENT 'Geographic region for business reporting. Resolved from Dim_Country.Region. Values: UK, French, German, Italian, Other Asia, USA, Spanish, Eastern Europe, etc. (Tier 2 - SP code, Dim_Country)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PotentialDesk COMMENT 'Sales desk assignment. Resolved from Dim_Country.Desk. Indicates which sales/support desk handles this customer''s region. (Tier 2 - SP code, Dim_Country)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Email COMMENT 'Customer''s email address. PII - use masked UC table for non-privileged access. From Dim_Customer.Email. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Credit COMMENT 'Current credit balance (USD). From V_Liabilities. Updated only when @date = yesterday. Represents available trading credit including bonuses. (Tier 2 - SP code, V_Liabilities)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN RealizedEquity COMMENT 'Current realized equity (USD). From V_Liabilities. Updated only when @date = yesterday. Represents deposits + realized P&L - withdrawals. (Tier 2 - SP code, V_Liabilities)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SocialConnect COMMENT 'DEPRECATED - Whether customer connected a social account. 1 = connected, NULL = not. Source table not updated since Sep 2018. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Verified COMMENT 'Customer verification level ID. Resolved via Dim_VerificationLevel. Values: 0=Unverified, 1=Level 1, 2=Level 2, 3=Fully Verified. NOT a boolean - do not treat as 0/1. (Tier 2 - SP code, Dim_VerificationLevel)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN KYC COMMENT 'DEPRECATED - KYC status. Nullified 2022-02-22. All values are NULL. Do not use. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN DocsOK COMMENT 'Whether customer''s documents have been approved. 1 = approved, NULL = not yet approved. Mostly NULL (~99.9%). (Tier 3 - live data)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Blocked COMMENT 'Whether customer account is blocked/restricted. 0 = active, 1 = blocked. Computed from PlayerStatusID IN (2,4,6,7,8,9). Blocked != closed - check Dim_Customer.PendingClosureStatusID for closure. (Tier 2 - SP code, Dim_PlayerStatus)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN IsSales COMMENT 'Whether customer is flagged as a sales account. 0 = not sales, 1 = sales. Mostly NULL (~94%). (Tier 3 - live data)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN HasPic COMMENT 'Whether customer has a profile picture. 1 = has picture, 0 = no picture. Mostly NULL (~98.6%). (Tier 3 - live data)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Bankruptcy COMMENT 'DEPRECATED - Bankruptcy flag. Nullified 2022-02-22. All values are NULL. Do not use. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FunnelName COMMENT 'Registration funnel name. Resolved from Dim_Funnel.Name via FunnelID. Values: Retoro, reToroiOS, reToroAndroid, Web Trader, etc. Indicates which app/platform was used for registration. (Tier 2 - SP code, Dim_Funnel)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN DownloadID COMMENT 'Download tracking ID from customer acquisition. From Dim_Customer.DownloadID. Typically 0. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN registered COMMENT 'Customer registration date - the earlier of RegisteredDemo and RegisteredReal from Dim_Customer. First-ever interaction with the platform. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstTimeUser COMMENT '[UNVERIFIED] First time the user engaged with the platform as a new user. Rarely populated - not updated by current SP. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstLoggedIn COMMENT 'First real-money login timestamp. From Fact_CustomerAction where ActionTypeID=14. Set once, never overwritten (MIN logic). (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDemoLoggedIn COMMENT '[UNVERIFIED] First demo account login timestamp. Not updated by current SP code. May contain historical values only. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDemoPosOpenDate COMMENT '[UNVERIFIED] First demo position open date. Not updated by current SP code. May contain historical values only. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDemoMirrorRegistrationDate COMMENT '[UNVERIFIED] First demo copy-trade registration date. Not updated by current SP code. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDemoMirrorRegistrationDate COMMENT '[UNVERIFIED] Last demo copy-trade registration date. Not updated by current SP code. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDemoMirrorPosOpenDate COMMENT '[UNVERIFIED] First demo copy-trade position open date. Not updated by current SP code. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstCashierLogin COMMENT 'First cashier page login. From Fact_CustomerAction where ActionTypeID=29 (MIN). First time customer visited the deposit/cashier page. (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositAttempt COMMENT 'First deposit attempt timestamp (regardless of success). From Fact_FirstCustomerAction where ActionTypeID=27. (Tier 2 - SP code, Fact_FirstCustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositAttemptAmount COMMENT 'Amount of the first deposit attempt in USD. Computed as Amount * ExchangeRate. (Tier 2 - SP code)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositAttemptProcessor COMMENT 'Payment processor for the first deposit attempt. Currently set to ''NA'' (not available from current data source). (Tier 2 - SP code)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositAttemptFundingType COMMENT 'Funding type for the first deposit attempt. Currently set to ''NA'' (not available from current data source). (Tier 2 - SP code)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositDate COMMENT 'First successful deposit date. From Dim_Customer.FirstDepositDate via Fact_BillingDeposit. 1900-01-01 = no deposit (sentinel). Filter with YEAR(FirstDepositDate) != 1900. (Tier 2 - SP code, Fact_BillingDeposit)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositProcessor COMMENT 'Payment processor for the first deposit. Resolved from Dim_BillingDepot.Name via DepotID. (Tier 2 - SP code, Dim_BillingDepot)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositFundingType COMMENT 'Funding type for the first deposit. Resolved from Dim_FundingType.Name via FundingTypeID. Values: CreditCard, Wire, PayPal, eToroMoney, IXOPAY-Nuvei, etc. (Tier 2 - SP code, Dim_FundingType)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositAmount COMMENT 'Amount of the first successful deposit in USD. Default 0. From Dim_Customer.FirstDepositAmount. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstEngagementDate COMMENT 'DEPRECATED - First social engagement date. ETL section commented out. May contain historical values. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstPosOpenDate COMMENT 'First position open date (manual or copy-trade). From Fact_CustomerAction where ActionTypeID IN (1,2). Uses MIN logic. (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstMirrorRegistrationDate COMMENT 'First copy-trade (mirror) registration date. From Fact_CustomerAction where ActionTypeID=17. (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastMirrorRegistrationDate COMMENT 'Most recent copy-trade registration date. From Fact_CustomerAction where ActionTypeID=17 (MAX). (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstMirrorPosOpenDate COMMENT 'First copy-trade position open date. From Fact_CustomerAction where ActionTypeID=2. (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstLeadDate COMMENT 'DEPRECATED - First lead date. Nullified 2022-02-22. 1900-01-01 = sentinel for older records. Do not use. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositAmountExtended COMMENT '[UNVERIFIED] Extended first deposit amount - may include bonuses or promotions. Not updated by current SP. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN ReferralID COMMENT 'CID of the customer who referred this customer. 0 = no referral. From Dim_Customer.ReferralID. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDemoLoggedIn COMMENT '[UNVERIFIED] Last demo login date. Not updated by current SP. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDemoMirrorPosOpenDate COMMENT '[UNVERIFIED] Last demo copy-trade position date. Not updated by current SP. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDemoPosOpenDate COMMENT '[UNVERIFIED] Last demo position open date. Not updated by current SP. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastEngagementDate COMMENT 'DEPRECATED - Last social engagement date. ETL section commented out. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastLoggedIn COMMENT 'Most recent real-money login timestamp. From Fact_CustomerAction where ActionTypeID=14 (MAX). (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastMirrorPosOpenDate COMMENT 'Most recent copy-trade position open date. From Fact_CustomerAction where ActionTypeID=2 (MAX). (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastPosOpenDate COMMENT 'Most recent position open date (manual or copy). From Fact_CustomerAction where ActionTypeID IN (1,2) (MAX). (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN CertifiedGuru COMMENT 'Whether the customer is a certified Popular Investor (guru). 1 = certified, NULL = not certified. Very rare (~515 out of 45M). (Tier 3 - live data)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstTimeBeingCopied COMMENT 'First time another customer copied this customer''s trades. From Dim_Mirror.OpenOccurred (MIN for this CID as ParentCID). (Tier 2 - SP code, Dim_Mirror)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastTimeBeingCopied COMMENT 'Most recent time another customer copied this customer''s trades. From Dim_Mirror.OpenOccurred (MAX for this CID as ParentCID). (Tier 2 - SP code, Dim_Mirror)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Gender COMMENT 'Customer gender. M=Male, F=Female, U=Unknown, NULL=not provided. From Dim_Customer.Gender. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN CountryID COMMENT 'Country ID - FK to Dim_Country.CountryID. Use Dim_Country for country name, region, regulation mapping, and risk group. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstMenualPosOpenDate COMMENT 'First manually opened position date (NOT copy-trade). From Fact_CustomerAction where ActionTypeID=1. Note: "Menual" is a typo for "Manual." (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN BirthDate COMMENT 'Customer''s date of birth. PII. 1900-01-02 = unknown/not provided. From Dim_Customer.BirthDate. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN CommunicationLanguage COMMENT 'Customer''s preferred communication language (emails, notifications). Resolved from Dim_Language.Name via CommunicationLanguageID. May differ from platform Language. (Tier 2 - SP code, Dim_Language)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastMenualPosOpenDate COMMENT 'Most recent manually opened position date. From Fact_CustomerAction where ActionTypeID=1 (MAX). Note: "Menual" is a typo for "Manual." (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstTimeSocialConnect COMMENT 'DEPRECATED - First social account connection date. Source not updated since 2018. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastCashierLogin COMMENT 'Most recent cashier page login. From Fact_CustomerAction where ActionTypeID=29 (MAX). (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstCashoutDate COMMENT 'First withdrawal/cashout date. From Fact_CustomerAction where ActionTypeID=8 (MIN). (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FunnelFromName COMMENT 'Name of the originating marketing funnel. Resolved from Dim_Funnel.Name via FunnelFromID. Shows specific landing page/campaign funnel (eToro Homepage, Stocks Offering, reToroiOS, etc.). (Tier 2 - SP code, Dim_Funnel)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN BannerID COMMENT 'Affiliate banner ID. From Dim_Customer.BannerID. 0 = no banner/direct. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SubAffiliateID COMMENT 'Sub-affiliate tracking ID. From Dim_Customer.SubSerialID. Can contain URLs, campaign tags, or partner codes. Free-text. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstCampaignID COMMENT 'ID of the first marketing campaign the customer received. From History.Credit.CampaignID (via External_etoro_History_Credit). (Tier 2 - SP code, History.Credit)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstCampaignDate COMMENT 'Date of the first marketing campaign received. (Tier 2 - SP code, History.Credit)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstCampaignAmount COMMENT 'Amount of the first campaign payment/credit received (USD). (Tier 2 - SP code, History.Credit)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstStocksOpenDate COMMENT 'First date the customer opened a real stocks position. From Fact_CustomerAction where ActionTypeID=34. (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SevenDayRetained COMMENT '[UNVERIFIED] Whether customer was retained at day 7 after first deposit. 1 = retained, 0 = not retained, NULL = not yet evaluated. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstToSevenDayRetained COMMENT '[UNVERIFIED] Whether customer was retained between first deposit and day 7. 1 = retained, 0 = not retained, NULL = not yet evaluated. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDateRetained COMMENT '[UNVERIFIED] Whether customer was retained on first-date basis. 1 = retained, 0 = not retained, NULL = not yet evaluated. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastContactAttemptDate_ByPhone COMMENT 'Most recent phone contact attempt date. From BI_DB_UsageTracking_SF - Salesforce usage tracking. (Tier 2 - SP code, BI_DB_UsageTracking_SF)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastContactDate COMMENT 'Most recent successful contact date (any channel). From BI_DB_UsageTracking_SF where ActionName IN (''Completed_Contact_Email__c'', ''Phone_Call_Succeed__c''). (Tier 2 - SP code, BI_DB_UsageTracking_SF)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastContactAttemptDate COMMENT 'Most recent contact attempt date (any channel). From BI_DB_UsageTracking_SF. (Tier 2 - SP code, BI_DB_UsageTracking_SF)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastContactDate_ByPhone COMMENT 'Most recent successful phone contact date. From BI_DB_UsageTracking_SF where ActionName = ''Phone_Call_Succeed__c''. (Tier 2 - SP code, BI_DB_UsageTracking_SF)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstContactAttemptDate COMMENT 'First contact attempt date (any channel). From BI_DB_UsageTracking_SF (MIN). (Tier 2 - SP code, BI_DB_UsageTracking_SF)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstContactAttemptDate_ByPhone COMMENT '[UNVERIFIED] First phone contact attempt date. Not explicitly set in current SP code. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstContactDate COMMENT 'First successful contact date (any channel). From BI_DB_UsageTracking_SF (MIN). (Tier 2 - SP code, BI_DB_UsageTracking_SF)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstContactDate_ByPhone COMMENT '[UNVERIFIED] First successful phone contact date. Not explicitly set in current SP code. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PremiumAccount COMMENT '[UNVERIFIED] Whether customer has a premium account type. Entirely NULL in current data - not populated. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Evangelist COMMENT 'Whether customer is an eToro evangelist/ambassador. 1 = evangelist, NULL = not. Very rare (~208). (Tier 3 - live data)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstToThirtyDayRetained COMMENT '[UNVERIFIED] Whether customer was retained between first deposit and day 30. 1 = retained, 0 = not retained, NULL = not yet evaluated. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstWallEngagement COMMENT 'DEPRECATED - First social wall engagement date. ETL section commented out. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FeedUnBlocked COMMENT '[UNVERIFIED] Whether the customer''s social feed is unblocked. Entirely NULL - not populated by current SP. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PrivacyPolicyID COMMENT 'Privacy policy version accepted by the customer. Values: 1 (~47%), 2 (~53%). From Dim_Customer.PrivacyPolicyID. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN IP COMMENT 'Customer''s IP address (as numeric). PII. From Dim_Customer.IP. Mostly NULL in recent records. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FeedUnlocked COMMENT 'Whether the customer has unlocked their social feed. 0 = locked, 1 = unlocked, NULL = not evaluated. (Tier 3 - live data)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Follow5UsersDate COMMENT '[UNVERIFIED] Date when the customer followed 5 users (social onboarding milestone). Not populated in current data. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN NumberOfUsersFollowed COMMENT '[UNVERIFIED] Number of users this customer is following on the social feed. Not populated in current data. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PopularInvestor COMMENT 'Whether customer is part of the Popular Investor program. 1 = yes, NULL = no. Very rare (~360). (Tier 3 - live data)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Manager COMMENT 'Account manager''s full name (FirstName + LastName). Resolved from Dim_Manager via AccountManagerID. ''System'' = no assigned manager. (Tier 2 - SP code, Dim_Manager)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SuitabilityTestCompletedAt COMMENT 'DEPRECATED - Suitability test completion date. Nullified 2022-02-22. 1900-01-01 = sentinel in older records. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PassedSuitabilityTest COMMENT 'DEPRECATED - Whether customer passed the suitability test. Nullified 2022-02-22. All NULL. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Model_FTDsOTDs COMMENT '[UNVERIFIED] ML model score predicting FTD (First Time Deposit) / OTD conversion probability. Not populated by current SP. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Model_Leads COMMENT '[UNVERIFIED] ML model score for lead quality/conversion. Not populated by current SP. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDepositDate COMMENT 'Most recent deposit date. From Fact_BillingDeposit via #fundingLast (ModificationDate). Updated daily for new deposits. (Tier 2 - SP code, Fact_BillingDeposit)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDepositAmount COMMENT 'Amount of the most recent deposit in USD. From Fact_BillingDeposit (Amount * ExchangeRate). (Tier 2 - SP code, Fact_BillingDeposit)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDepositFundingType COMMENT 'Funding type of the most recent deposit. Resolved from Dim_FundingType.Name. Values: CreditCard, Wire, PayPal, eToroMoney, etc. (Tier 2 - SP code, Dim_FundingType)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Model_ReDepositor COMMENT '[UNVERIFIED] ML model score predicting re-deposit probability. Not populated by current SP. (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN RegulationID COMMENT 'Regulatory entity ID. FK to Dim_Regulation.ID. Values: 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI (~80%), 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. (Tier 2 - SP code, Dim_Regulation)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN RiskGroup COMMENT 'DEPRECATED - Customer risk classification. A/B/C. ETL disabled 2023-05-09. Historical values only. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN DepositGroup COMMENT 'DEPRECATED - Customer deposit tier. Low/Mid/High. ETL disabled 2023-05-09. Historical values only. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN UpdateDate COMMENT 'Last ETL update timestamp for this row. Set to GETDATE() on every INSERT or UPDATE. Use to verify data freshness. (Tier 2 - SP code)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN VerificationLevel1Date COMMENT 'Date customer first reached Verification Level 1. From Fact_SnapshotCustomer (MIN date where VerificationLevelID=1). May be backfilled from higher levels. (Tier 2 - SP code, Fact_SnapshotCustomer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN VerificationLevel2Date COMMENT 'Date customer first reached Verification Level 2. From Fact_SnapshotCustomer (MIN date where VerificationLevelID=2). Backfilled from Level 3 if NULL. (Tier 2 - SP code, Fact_SnapshotCustomer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN VerificationLevel3Date COMMENT 'Date customer first reached Verification Level 3 (fully verified). From Fact_SnapshotCustomer (MIN date where VerificationLevelID=3). (Tier 2 - SP code, Fact_SnapshotCustomer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN EmailVerifiedDate COMMENT 'Date customer''s email was verified. From Fact_SnapshotCustomer (MIN date where IsEmailVerified=1). (Tier 2 - SP code, Fact_SnapshotCustomer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstInstallDate COMMENT 'First mobile app install date. From BI_DB_AppFlyer_Reports (EventName=''install'') via AppsFlyer tracking. (Tier 2 - SP code, BI_DB_AppFlyer_Reports)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN EvMatchStatusDate COMMENT 'Date customer reached EvMatchStatus=2 (Verified) for electronic verification. From Fact_SnapshotCustomer. (Tier 2 - SP code, Fact_SnapshotCustomer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN State COMMENT 'Customer''s state/province. Resolved from Dim_State_and_Province.Name via RegionByIP_ID. Populated for US, Italy, and select countries. (Tier 2 - SP code, Dim_State_and_Province)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PhoneVerifiedDate COMMENT 'Date customer''s phone was verified. From History.BackOfficeCustomer where PhoneVerifiedID IN (1=AutomaticallyVerified, 2=ManuallyVerified). (Tier 2 - SP code, History.BackOfficeCustomer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN KycModeID COMMENT 'KYC verification mode. Values: 1 (~48%), 2 (~9%), 3 (~0.3%), 4 (~6%), NULL (~37%). From ComplianceStateDB.Compliance.CustomerKycMode. Joined on GCID. (Tier 2 - SP code, ComplianceStateDB)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PEPCreatedTime COMMENT 'DEPRECATED - PEP (Politically Exposed Person) check creation time. Nullified 2022-02-22. 1900-01-01 = sentinel. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PEPStatusUpdatedDate COMMENT 'DEPRECATED - PEP status last update date. Nullified 2022-02-22. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN isPassedPEP COMMENT 'DEPRECATED - Whether customer passed PEP screening. Nullified 2022-02-22. All NULL. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PEPStatusID COMMENT 'DEPRECATED - PEP screening status ID. Nullified 2022-02-22. All NULL. (Tier 2 - SP code, deprecated)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN EvMatchStatus COMMENT 'Electronic verification match status. FK to Dim_EvMatchStatus.EvMatchStatusID. Values: 0=None, 1=PartiallyVerified, 2=Verified, 3=NotVerified. From Dim_Customer.EvMatchStatus. (Tier 2 - SP code, Dim_EvMatchStatus)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FTDIsLessThanAWeek COMMENT 'Whether first deposit occurred within 7 days of registration AND deposit > 0. 1 = fast depositor, 0 = slower or no deposit. Computed: DATEDIFF(DAY, registered, FirstDepositDate) < 8 AND FirstDepositAmount > 0. (Tier 2 - SP code)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN DesignatedRegulationID COMMENT 'Designated regulation entity ID. FK to Dim_Regulation.ID. Same value map as RegulationID. May differ when designated regulation differs from operating regulation. From Dim_Customer.DesignatedRegulationID. (Tier 2 - SP code, Dim_Customer)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN ProfessionalApplicationDate COMMENT 'Date the customer applied for professional (non-retail) classification. From ComplianceStateDB.Compliance.CustomerProfessionalQuestionnaireResult. (Tier 2 - SP code, ComplianceStateDB)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastCampaignSentDate COMMENT 'Date of the most recent marketing campaign sent to this customer. (Tier 2 - SP code)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN NewMarketingRegion COMMENT 'Updated marketing region classification. From Dim_Country.MarketingRegionManualName. Values: SEA, UK, French, Latam, German, CEE, Arabic, USA, Italian, ROW, Nordics, Spain, Australia. (Tier 2 - SP code, Dim_Country)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN IsFundedNew COMMENT 'Whether customer is currently "funded" - meeting active depositor criteria. 1 = funded, 0 = not funded. Determined by Function_Population_Funded. (Tier 2 - SP code, Function_Population_Funded)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstNewFundedDate COMMENT 'First date the customer became "funded." From Function_Population_First_Time_Funded. Set once, never overwritten. (Tier 2 - SP code, Function_Population_First_Time_Funded)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastNewFundedDate COMMENT 'Most recent date the customer was in "funded" status. From DDR daily status and Function_Population_Funded. Updated daily. (Tier 2 - SP code)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN IsAirDropBefore COMMENT 'Whether customer received a crypto airdrop in the last 30 days AND has deposited. 1 = received airdrop. From Fact_CustomerAction (ActionTypeID=1, IsAirDrop=1, InstrumentTypeID=5). (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SignedW8Date COMMENT '[UNVERIFIED] Date the customer signed the W-8BEN tax form (for non-US customers trading US securities). Not populated by current SP (section disabled). (Tier 4 - column name inference)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastCashoutDate COMMENT 'Most recent withdrawal/cashout date. From Fact_CustomerAction where ActionTypeID=8 (MAX). (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastPublishedPostDate COMMENT 'Most recent date the customer published a post on the social feed. From Fact_CustomerAction where ActionTypeID=21. (Tier 2 - SP code, Fact_CustomerAction)';
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastActionDateForLifeStage COMMENT 'Most recent "life stage" action date (manual pos open, mirror pos open, mirror registration, or cashout). From Fact_CustomerAction where ActionTypeID IN (1,15,17). Used for lifecycle stage classification. (Tier 2 - SP code, Fact_CustomerAction)';

-- ---- Column PII Tags ----
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN OriginalCID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN UserName SET TAGS ('pii' = 'direct');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SerialID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Channel SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SubChannel SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LabelName SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Language SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PotentialDesk SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Email SET TAGS ('pii' = 'direct');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Credit SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN RealizedEquity SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SocialConnect SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Verified SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN KYC SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN DocsOK SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Blocked SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN IsSales SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN HasPic SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Bankruptcy SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FunnelName SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN DownloadID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN registered SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstTimeUser SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstLoggedIn SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDemoLoggedIn SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDemoPosOpenDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDemoMirrorRegistrationDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDemoMirrorRegistrationDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDemoMirrorPosOpenDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstCashierLogin SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositAttempt SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositAttemptAmount SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositAttemptProcessor SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositAttemptFundingType SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositProcessor SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositFundingType SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositAmount SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstEngagementDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstPosOpenDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstMirrorRegistrationDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastMirrorRegistrationDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstMirrorPosOpenDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstLeadDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDepositAmountExtended SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN ReferralID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDemoLoggedIn SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDemoMirrorPosOpenDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDemoPosOpenDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastEngagementDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastLoggedIn SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastMirrorPosOpenDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastPosOpenDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN CertifiedGuru SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstTimeBeingCopied SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastTimeBeingCopied SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Gender SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstMenualPosOpenDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN BirthDate SET TAGS ('pii' = 'direct');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN CommunicationLanguage SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastMenualPosOpenDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstTimeSocialConnect SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastCashierLogin SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstCashoutDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FunnelFromName SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN BannerID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SubAffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstCampaignID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstCampaignDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstCampaignAmount SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstStocksOpenDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SevenDayRetained SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstToSevenDayRetained SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstDateRetained SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastContactAttemptDate_ByPhone SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastContactDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastContactAttemptDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastContactDate_ByPhone SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstContactAttemptDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstContactAttemptDate_ByPhone SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstContactDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstContactDate_ByPhone SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PremiumAccount SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Evangelist SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstToThirtyDayRetained SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstWallEngagement SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FeedUnBlocked SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PrivacyPolicyID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN IP SET TAGS ('pii' = 'direct');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FeedUnlocked SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Follow5UsersDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN NumberOfUsersFollowed SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PopularInvestor SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Manager SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SuitabilityTestCompletedAt SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PassedSuitabilityTest SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Model_FTDsOTDs SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Model_Leads SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDepositAmount SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastDepositFundingType SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN Model_ReDepositor SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN RiskGroup SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN DepositGroup SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN VerificationLevel1Date SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN VerificationLevel2Date SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN VerificationLevel3Date SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN EmailVerifiedDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstInstallDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN EvMatchStatusDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN State SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PhoneVerifiedDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN KycModeID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PEPCreatedTime SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PEPStatusUpdatedDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN isPassedPEP SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN PEPStatusID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN EvMatchStatus SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FTDIsLessThanAWeek SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN DesignatedRegulationID SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN ProfessionalApplicationDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastCampaignSentDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN NewMarketingRegion SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN IsFundedNew SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN FirstNewFundedDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastNewFundedDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN IsAirDropBefore SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN SignedW8Date SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastCashoutDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastPublishedPostDate SET TAGS ('pii' = 'none');
ALTER TABLE pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN LastActionDateForLifeStage SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-15 22:00
-- Main: 141/141 succeeded | Downstream: 515/515 succeeded
-- Failures: 0
-- Main breakdown:
--   Table comment:    OK
--   Table tags:       OK
--   Column comments:  139/139 succeeded
--   PII tags:         139/139 succeeded
-- Downstream breakdown:
--   Tables:  139/139 statements across 1 table (main.bi_db...masked)
--   Views:   376/376 statements across 5 views
--   Skipped: 2 (METRIC_VIEWs)
-- ====================
