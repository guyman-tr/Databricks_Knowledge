-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_MarketingDailyRawData
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_MarketingDailyRawData'
);

-- ---- Table Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN AffiliateID COMMENT 'Affiliate (partner) ID from DWH_dbo.Dim_Affiliate. Part of the AffiliateID × CountryID × DateID × Funnel grain key. FK concept to Dim_Affiliate.AffiliateID. (Tier 2 - Dim_Affiliate.AffiliateID)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN CountryID COMMENT 'Country ID from DWH_dbo.Dim_Country. Part of the grain key. All 249 countries appear in the CROSS JOIN scaffold. FK concept to Dim_Country.CountryID. (Tier 2 - Dim_Country.CountryID)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN DateID COMMENT 'Date as YYYYMMDD string from DWH_dbo.Dim_Date.DateKey. Leading clustered index column. Covers @StartOfLastMonth -> @Date. (Tier 2 - Dim_Date.DateKey)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Date COMMENT 'Calendar date from DWH_dbo.Dim_Date.FullDate. ISO date format of the same event date as DateID. (Tier 2 - Dim_Date.FullDate)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Funnel COMMENT 'Platform/funnel category from DWH_dbo.Dim_Platform.Platform. Part of grain key. Values: ''Web'', ''IOS'', ''Android'', ''Undefined''. Derived from customer''s FunnelFromID -> Dim_Funnel.PlatformID. Customers without a valid platform/funnel assignment get ''Undefined''. (Tier 2 - Dim_Platform.Platform)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN CountryName COMMENT 'Country display name from DWH_dbo.Dim_Country.Name. Denormalized from CountryID. (Tier 3 - Dim_Country.Name)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Region COMMENT 'Geographic region from DWH_dbo.Dim_Country.Region. Standard geographic grouping (not the marketing override - see NewMarketingRegion). (Tier 3 - Dim_Country.Region)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Desk COMMENT 'Country desk assignment from DWH_dbo.Dim_Country.Desk. Operational desk responsible for this country/region in the sales/support structure. (Tier 3 - Dim_Country.Desk)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN DateCreated COMMENT 'Affiliate account creation date from DWH_dbo.Dim_Affiliate.DateCreated. When the affiliate account was first registered in AffWizz/Fiktivo. (Tier 3 - Dim_Affiliate.DateCreated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Channel COMMENT 'Top-level marketing channel from DWH_dbo.Dim_Channel.Channel. Retroactively corrected for DateID  >=  2019-01-01 based on current Dim_Channel. Common values: Direct, SEM, SEO, Affiliate, Friend Referral, Media Performance, Mobile Acquisition. (Tier 3 - Dim_Channel.Channel)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN SubChannel COMMENT 'Granular sub-channel name from DWH_dbo.Dim_Channel.SubChannel. Retroactively corrected alongside Channel. (Tier 3 - Dim_Channel.SubChannel)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN `Organic/Paid` COMMENT 'Classification of whether acquisition is organic or paid from DWH_dbo.Dim_Channel.[Organic/Paid]. Values: ''Organic'' or ''Paid''. Retroactively corrected. (Tier 3 - Dim_Channel.[Organic/Paid])';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Contact COMMENT 'Affiliate contact or campaign identifier from DWH_dbo.Dim_Affiliate.Contact. (Tier 3 - Dim_Affiliate.Contact)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN ContractName COMMENT 'Affiliate contract name from DWH_dbo.Dim_Affiliate.ContractName. (Tier 3 - Dim_Affiliate.ContractName)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN ContractType COMMENT 'Contract type description from DWH_dbo.Dim_ContractType.Name via Dim_Affiliate.ContractType. (Tier 3 - Dim_ContractType.Name)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN AffiliatesGroupsName COMMENT 'Parent affiliate group/network name from DWH_dbo.Dim_Affiliate.AffiliatesGroupsName. Groups individual affiliate accounts into their parent network (e.g., "Adtraction"). (Tier 3 - Dim_Affiliate.AffiliatesGroupsName)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN AccountActivated COMMENT 'Whether the affiliate account is activated (accepting commissions). From DWH_dbo.Dim_Affiliate.AccountActivated. (Tier 3 - Dim_Affiliate.AccountActivated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN TotalCost COMMENT 'Total affiliate commission cost = sum of all commission types (RevShare + Chargebacks + CPA + CPL + eCost + Lead_Comm). Sourced from Fiktivo affiliate platform. NULL if no commissions for this combination. (Tier 2 - Fiktivo commission pipeline)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN RevShare_Comm COMMENT 'Revenue share commission paid to the affiliate for closed positions in the period. From Fiktivo AffiliateCommission_ClosedPosition. (Tier 2 - Fiktivo RevShare)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Chargebacks COMMENT 'Chargeback and Refund commission credits (CreditTypeID IN 4,5) from Fiktivo. Negative impact to TotalCost. (Tier 2 - Fiktivo AffiliateCommission_Credit)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN NumberOfChargebacks COMMENT 'Count of chargeback/refund events in the period for this affiliate × country. (Tier 2 - Fiktivo AffiliateCommission_Credit COUNT)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN CPA_Comm COMMENT 'Cost Per Acquisition commission (CreditTypeID=1, Valid != 0) from Fiktivo. Paid when a Tier-1 qualifying FTD occurs. (Tier 2 - Fiktivo CPA credits)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN CPL_Comm COMMENT 'Cost Per Lead commission from Fiktivo tblaff_Leads. Paid when a qualified lead (registration) is delivered by the affiliate. (Tier 2 - Fiktivo CPL leads)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN eCost COMMENT 'eCost affiliate commission from Fiktivo tblaff_eCost. A performance-based variable cost type. (Tier 2 - Fiktivo eCost)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Tier2Commition COMMENT 'Sub-affiliate Tier-2 commission amount. Paid to parent affiliates in multi-tier arrangements when their referred sub-affiliates generate activity. Note: column name has typo "Commition" (missing ''s''). (Tier 2 - Fiktivo Tier=2 commissions)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Tier3Commition COMMENT 'Sub-affiliate Tier-3 commission amount. Same as Tier2 but for third-level affiliate hierarchy. Note: typo "Commition". (Tier 2 - Fiktivo Tier=3 commissions)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Registration COMMENT 'Count of customer registrations attributed to this affiliate under this country × date × funnel combination. Sourced from Fiktivo registration tracking joined with DWH_dbo.Dim_Customer. (Tier 2 - Fiktivo Registration + Dim_Customer)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN SameDayFTD COMMENT 'Count of First-Time Deposits where the deposit date equals the registration date (converted on same calendar day). Subset of FTD. (Tier 2 - Fiktivo FTD matching, SameDayFTD CASE)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN FTD COMMENT 'Count of affiliate-attributed First-Time Deposits from Fiktivo AffiliateCommission_Credit. **Scope note**: This is ONLY affiliate-attributed FTDs tracked by Fiktivo - does NOT include all platform FTDs (direct customers, non-affiliate-credited FTDs). (Tier 2 - Fiktivo AffiliateCommission_Credit)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN EFTD COMMENT 'Count of Eligible FTDs: Fiktivo Tier-1 CPA-eligible FTDs where IsFirstDeposit=1 and Valid=1. A subset of FTD representing qualifying conversions for CPA commission payment. (Tier 2 - Fiktivo AffiliateCommission_Credit Tier=1 Valid=1)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN FTDA COMMENT 'Sum of FTD amounts in USD for Tier-1 CPA-eligible affiliate credits (cpa.Amount). **Scope note**: This is NOT total first-deposit revenue - it is only the deposit amount for CPA-eligible Tier-1 affiliate FTDs. (Tier 2 - Fiktivo AffiliateCommission_Credit Tier=1 Amount)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN NetRevenues COMMENT 'Net revenue generated by customers acquired through this affiliate: SALE.Revenues + SALE.USED_BONUS_GRAND_TOTAL + CHARGEBACK.Revenues. Sources include closed position revenues and bonus credits from the Fiktivo ClosedPosition pipeline. (Tier 2 - Fiktivo ClosedPosition revenue)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN VerificationLevelID2 COMMENT 'Count of customers who achieved KYC verification level 2 (document verification) under this affiliate attribution. Used to measure document submission quality of acquired customers. (Tier 2 - Dim_Customer.VerificationLevelID=2)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN VerificationLevelID3 COMMENT 'Count of customers who achieved KYC verification level 3 (full verification) under this affiliate attribution. Higher quality signal than level 2. (Tier 2 - Dim_Customer.VerificationLevelID=3)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Installs COMMENT 'Mobile app install events tracked via AppsFlyer, attributed to this affiliate × country × date × funnel combination. Source: BI_DB_AppFlyer_Reports. Column was disabled 2021-12 and restored/rewritten 2023-07. (Tier 2 - BI_DB_AppFlyer_Reports)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN TotalDeposit COMMENT 'Total deposit amount (all deposits, not just FTD) in USD for customers attributed to this affiliate in the period. Includes repeat deposits. (Tier 2 - Billing/DWH deposit pipeline)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN DBRev COMMENT 'Database Revenue - trading revenue (realized PnL + spreads + fees) generated by customers attributed to this affiliate in the period. (Tier 2 - DWH trading revenue pipeline)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN RAF_Comm COMMENT 'Refer-A-Friend commission cost for the affiliate. Cost incurred when referred customers meet RAF eligibility criteria. (Tier 2 - Fiktivo RAF commission)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN IsRev COMMENT 'Count of FTD customers (from past 3 months) who became revenue-generating: opened their first trading position after depositing. Computed via UPDATE pass on BI_DB_CIDFirstDates.FirstPosOpenDate IS NOT NULL. Inserted as 0, then updated. (Tier 2 - BI_DB_CIDFirstDates.FirstPosOpenDate)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Redeposits COMMENT 'Count of FTD customers who made at least one subsequent deposit (LastDepositDate != FirstDepositDate on BI_DB_CIDFirstDates). Inserted as 0, then updated by UPDATE pass. (Tier 2 - BI_DB_CIDFirstDates.LastDepositDate)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN PastGRevenue COMMENT 'Legacy Optimove Gross Revenue field. Always set to 0 by current SP (removed from Optimove integration 2020-05). Default value (0) from DDL. (Tier 3 - legacy field, always 0)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN GLTV COMMENT 'Gross Lifetime Value: projected total lifetime revenue from FTD customers acquired through this affiliate × country × date × funnel. Sourced from BI_DB_LTV_BI_Actual since 2020-05 (replaced BI_DB_Real_LTV). Default 0. (Tier 2 - BI_DB_LTV_BI_Actual)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN FTDfromLTV COMMENT 'Count of FTDs from the LTV model that are attributed to this combination. Used to normalize GLTV calculations. Default 0. (Tier 2 - BI_DB_LTV_BI_Actual)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Rev10 COMMENT 'Count of FTD customers who reached the "Rev10" revenue milestone (defined in BI_DB_FirstTimeRev10). Measures revenue quality of acquired customers beyond the initial deposit. Updated by UPDATE pass. (Tier 2 - BI_DB_FirstTimeRev10)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN UpdateDate COMMENT 'ETL metadata: SP execution timestamp. Set to GETDATE() at INSERT and updated at subsequent UPDATE passes for the same row. (Propagation - GETDATE())';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN LTV_NoExtreme COMMENT 'LTV excluding extreme outlier customers - high-value outliers that distort the mean LTV. Populated by a separate LTV SP (not SP_Marketing_Cube). Added 2020-05. Default 0. (Tier 2 - BI_DB_LTV_BI_Actual, separate LTV SP)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN NewMarketingRegion COMMENT 'Marketing team curated region override from DWH_dbo.Dim_Country.MarketingRegionManualName. Unlike Region (geographic), this is a manually maintained marketing taxonomy. Added 2021-02. (Tier 3 - Dim_Country.MarketingRegionManualName)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Lead_Comm COMMENT 'Lead commission: CPL cost from Fiktivo AffiliateCommission Registration table, added 2023-05 as a separate column (also included in TotalCost). (Tier 2 - Fiktivo Registration commission)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN totalGroupLTV COMMENT 'Group-level total LTV component from BI_DB_LTV_BI_Actual - measures the combined LTV of the acquisition group. (Tier 2 - BI_DB_LTV_BI_Actual.totalGroupLTV)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN totalExtLTV COMMENT 'External/extreme component of total LTV from BI_DB_LTV_BI_Actual - the portion attributable to extreme-value customers. (Tier 2 - BI_DB_LTV_BI_Actual.totalExtLTV)';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN AffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Funnel SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN CountryName SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Desk SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN DateCreated SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Channel SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN SubChannel SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN `Organic/Paid` SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Contact SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN ContractName SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN ContractType SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN AffiliatesGroupsName SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN AccountActivated SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN TotalCost SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN RevShare_Comm SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Chargebacks SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN NumberOfChargebacks SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN CPA_Comm SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN CPL_Comm SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN eCost SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Tier2Commition SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Tier3Commition SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Registration SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN SameDayFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN FTD SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN EFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN NetRevenues SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN VerificationLevelID2 SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN VerificationLevelID3 SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Installs SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN TotalDeposit SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN DBRev SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN RAF_Comm SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN IsRev SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Redeposits SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN PastGRevenue SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN GLTV SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN FTDfromLTV SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Rev10 SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN LTV_NoExtreme SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN NewMarketingRegion SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN Lead_Comm SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN totalGroupLTV SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN totalExtLTV SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:04:07 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 102/102 succeeded
-- ====================
