-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DailyPanel_Copy
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DailyPanel_Copy > 12.7M-row daily panel table tracking every active Popular Investor (PI), Smart Portfolio, and formerly-removed PI on the eToro platform -- capturing demographic attributes, equity/liability positions, copy-trading metrics (AUC, copiers, MIMO), portfolio composition, risk scores, and multi-horizon performance gains for each CID per snapshot date. Data spans Oct 2021 to present (~15,975 CIDs/day). Refreshed daily by SP_DailyPanel_Copy via DELETE+INSERT by DateID. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | ETL-computed by SP_DailyPanel_Copy from 15+ DWH/BI_DB source tables | | **Refresh** | Daily -- DELETE WHERE DateID = @date_int, then INSERT from #final temp table | | | | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | HEAP | | | | | **UC Target** | _Not_Migra'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Date COMMENT 'Snapshot calendar date for this panel row. Set to @date SP parameter. (Tier 2 - SP_DailyPanel_Copy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN DateID COMMENT 'Snapshot date as YYYYMMDD integer. CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). Used as DELETE+INSERT key. (Tier 2 - SP_DailyPanel_Copy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN CID COMMENT 'Customer ID of the Popular Investor, Smart Portfolio, or Removed PI. From Fact_SnapshotCustomer.RealCID. (Tier 2 - Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN UserName COMMENT 'Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Gender COMMENT 'Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Passthrough from Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Manager COMMENT 'Account manager full name (FirstName + '' '' + LastName from Dim_Manager). Concatenated in the SP. (Tier 2 - Dim_Manager)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Country COMMENT 'Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 - Dictionary.Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Region COMMENT 'Manual override name for the marketing region, from Ext_Dim_Country. May differ from the automated MarketingRegion label (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. Passthrough from Dim_Country.MarketingRegionManualName. (Tier 1 - Ext_Dim_Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Language COMMENT 'Language display name. UNIQUE constraint. Used in back-office language selectors and reporting. Passthrough from Dim_Language. (Tier 1 - Dictionary.Language)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Club COMMENT 'Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel. (Tier 1 - Dictionary.PlayerLevel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Regulation COMMENT 'Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation. (Tier 1 - Dictionary.Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Seniority COMMENT 'Months since first deposit, computed as DATEDIFF(MONTH, FirstDepositDate, first-of-month(@date)). NULL if customer never deposited. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN DaysAsPI COMMENT 'Days since the customer first achieved any PI status (GuruStatusID >= 2). Computed from MIN(Fact_SnapshotCustomer FromDate where GuruStatusID >= 2). NULL for Portfolio accounts. (Tier 2 - Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN CopyType COMMENT 'Population classification: ''PI'' = active Popular Investor (GuruStatusID 2-6, IsValidCustomer=1), ''Portfolio'' = Smart Portfolio fund (AccountTypeID=9), ''RemovedPI'' = former PI no longer in active PI status. (Tier 2 - Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN PortfolioType COMMENT 'Human-readable label for the fund type. Used in the platform UI, fund details pages, and management reporting. Describes the fundamental strategy approach of the fund category. 1=TopTraders, 2=Partners, 3=Market. NULL for PI and RemovedPI CopyTypes. Passthrough from Dim_FundType.FundTypeName via Dim_Fund. (Tier 1 - Dictionary.FundType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN GuruStatusID COMMENT 'Popular Investor program status code from the snapshot date. 0=No (non-PI), 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro. Passthrough from Fact_SnapshotCustomer. (Tier 2 - Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN GuruStatus COMMENT 'Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Passthrough from Dim_GuruStatus. (Tier 1 - Dictionary.GuruStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN PreviousGuruStatus COMMENT 'The GuruStatusID of the most recent different guru status for this CID. Determined via ROW_NUMBER over Fact_SnapshotCustomer history, filtering rows where GuruStatusID differs from the current status, ordered by ToDateID DESC. NULL if no previous status change found. Stored as the raw GuruStatusID integer (not the name). (Tier 2 - Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN TotalDaysInCurrentStatus COMMENT 'Total calendar days the PI has held their current GuruStatusID, summed across potentially non-contiguous SCD2 date ranges. Only computed for CopyType=''PI''. NULL for Portfolio and RemovedPI. (Tier 2 - Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN BIO_Len COMMENT 'Character length of the PI''s "About Me" biography text from their public profile. Source: LEN(AboutMe) from External_UserApiDB_dbo_Publications. NULL if no biography published. (Tier 2 - External_UserApiDB_dbo_Publications)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN IsPrivate COMMENT 'Whether the PI''s profile is set to private. 0 if PrivacyPolicyID=2 (public), 1 otherwise (private). Derived from Dim_Customer.PrivacyPolicyID. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN AllowDisplayFullName COMMENT 'Whether the PI allows their full legal name to be displayed publicly. From External_etoroGeneral_Customer_Settings, windowed by ValidFrom/ValidTo to the snapshot date. (Tier 2 - External_etoroGeneral_Customer_Settings)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN HasAvatar COMMENT 'Whether customer has uploaded a custom avatar. Updated post-load from Avatars staging (excludes default/avatoros images). Passthrough from Dim_Customer. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN RiskScore COMMENT 'Discrete portfolio risk score (typically 1-10) derived from mapping the daily portfolio standard deviation (AvgSTD from DWH_CIDsDailyRisk) to risk buckets defined in External_etoro_Internal_RiskScore. Higher values = more volatile portfolio. MAX per CID. (Tier 2 - DWH_CIDsDailyRisk)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN PlayerStatus COMMENT 'Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Passthrough from Dim_PlayerStatus. (Tier 1 - Dictionary.PlayerStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN LastBlockedDate COMMENT 'Most recent date when copy-trading operations were blocked for this CID. Source: MAX(Occurred/BlockStart) from External_etoro_Customer_BlockedCustomerOperations and External_etoro_History_BlockedCustomerOperations where OperationTypeID=2. NULL if never blocked. (Tier 2 - External_etoro_Customer_BlockedCustomerOperations)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN BlockReason COMMENT 'Human-readable reason for the most recent copy block event. Looked up from External_etoro_Dictionary_BlockUnBlockReason via BlockReasonID. NULL if never blocked. (Tier 2 - External_etoro_Dictionary_BlockUnBlockReason)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN TotalEquity COMMENT 'Customer total balance on the snapshot date: ISNULL(Liabilities, 0) + ISNULL(ActualNWA, 0) from V_Liabilities. Equals RealizedEquity + PositionPnL. (Tier 2 - V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN RealizedEquity COMMENT 'Realized equity (cash + credit + in-process cashouts) on the snapshot date. Direct passthrough from V_Liabilities.RealizedEquity. (Tier 1 - Fact_SnapshotEquity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN TotalPositionsAmount COMMENT 'Total invested amount across all open positions on the snapshot date. Direct passthrough from V_Liabilities.TotalPositionsAmount. (Tier 1 - Fact_SnapshotEquity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN PositionPnL COMMENT 'Unrealized position profit/loss on the snapshot date. Direct passthrough from V_Liabilities.PositionPnL. (Tier 1 - Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Credit COMMENT 'Available credit balance on the snapshot date. Direct passthrough from V_Liabilities.Credit. (Tier 1 - Fact_SnapshotEquity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN NumOfCopiers COMMENT 'Count of valid depositor customers currently copying this PI/Portfolio, from etoroGeneral_History_GuruCopiers where Timestamp = day-after-@date. Only counts IsValidCustomer=1 AND IsDepositor=1 copiers. (Tier 2 - etoroGeneral_History_GuruCopiers)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN CopyAUC COMMENT 'Total Assets Under Copy -- sum of Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL across all valid copiers of this PI/Portfolio. (Tier 2 - etoroGeneral_History_GuruCopiers)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN CopyPnL COMMENT 'Total copy PnL -- sum of PnL + DetachedPosInvestment + Dit_PnL across all valid copiers of this PI/Portfolio. (Tier 2 - etoroGeneral_History_GuruCopiers)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN MI COMMENT 'Mirror In -- daily inflow of funds into copy relationships where this CID is the copied person. SUM(-Amount) for ActionTypeID IN (15=Account-to-Mirror, 17=Register New Mirror) from Fact_CustomerAction on the snapshot date. (Tier 2 - Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN MO COMMENT 'Mirror Out -- daily outflow of funds from copy relationships where this CID is the copied person. SUM(Amount) for ActionTypeID IN (16=Mirror-to-Account, 18=Unregister Mirror) from Fact_CustomerAction on the snapshot date. (Tier 2 - Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN NetMI COMMENT 'Net Mirror In -- net daily money flow into copy relationships. SUM(-Amount) for all mirror ActionTypeIDs (15,16,17,18). Positive = net inflow, negative = net outflow. (Tier 2 - Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Trades COMMENT 'Count of manual (non-copy) positions opened by this CID on the snapshot date. Source: COUNT from Dim_Position WHERE MirrorID=0 AND ISNULL(IsPartialCloseChild,0)=0 AND OpenDateID=@date_int. (Tier 2 - Dim_Position)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Top_3_Traded_Instruments COMMENT 'Comma-separated list of the top 3 instrument symbols by invested amount among open positions. Determined by ranking open positions by SUM(Amount) DESC per InstrumentID, then STRING_AGG of top 3 Symbol values. NULL if no open positions. (Tier 2 - Dim_Position / Dim_Instrument)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Top3TradedIndustries COMMENT 'Comma-separated list of the top 3 industries by invested amount among open positions. Ranked by SUM(Amount) DESC per Industry, then STRING_AGG of top 3. NULL if no open positions. (Tier 2 - Dim_Position / Dim_Instrument)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Lev_weighted_average COMMENT 'Amount-weighted average leverage across all open positions on the snapshot date. Formula: SUM(Leverage * Amount) / NULLIF(SUM(Amount), 0). Source: BI_DB_PositionPnL for the snapshot DateID. (Tier 2 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN BuyPercent COMMENT 'Sell percentage among high-leverage positions held >30 days (Leverage >= 5, opened > 30 days ago). NOTE: despite the column name "BuyPercent", the SP actually stores the SELL ratio here (IsBuy=0 count / total count). NULL if no qualifying high-lev positions exist. (Tier 2 - Dim_Position)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN SellPercent COMMENT 'Buy percentage among high-leverage positions held >30 days. Computed as 1 - BuyPercent. Despite the name "SellPercent", this is actually the BUY ratio (since BuyPercent stores the sell ratio). NULL if no qualifying high-lev positions. (Tier 2 - Dim_Position)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN HoldsHighLevPosition COMMENT '1 if the CID holds any position open >30 days with leverage exceeding asset-class thresholds (Stocks/ETF >= 5x, Indices >= 10x, Currencies/Commodities >= 20x). 0 otherwise. (Tier 2 - Dim_Position)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Classification COMMENT 'Portfolio asset allocation category based on open position volumes. Values: ''Long Equity'' (>=70% equity, >80% buy), ''Long/Short Equity'' (>=70% equity, >=20% buy AND >=20% short), ''Currencies'', ''Commodities'', ''Crypto'', ''ETF'' (each >=70%), ''100% cash balance'' (no positions), ''Multi-Asset'' (default). (Tier 2 - Dim_Position)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Largest_Asset_Class COMMENT 'The single asset class (InstrumentType) with the highest total invested amount among open positions. Values: Stocks, Currencies, Commodities, Indices, ETF, Crypto Currencies. NULL if no open positions. (Tier 2 - Dim_Position / Dim_Instrument)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN AvgerageHoldingTime COMMENT 'Average holding time in days across all positions and mirrors opened/closed within the last 2 years. Includes both trading positions (Dim_Position) and copy relationships (Dim_Mirror). Open positions use @date as the close proxy. Note: column name has a typo ("Avgerageee" instead of "Average"). (Tier 2 - Dim_Position / Dim_Mirror)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN TraderType COMMENT 'Classification of the PI by average holding time. ''Short term investor'' if AvgerageHoldingTime < 22 days, ''Long term investor'' otherwise. (Tier 2 - SP_DailyPanel_Copy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN HighLevHoldingDetail COMMENT 'Comma-separated list of "Leverage-InstrumentType" strings for all high-leverage positions held >30 days (same criteria as HoldsHighLevPosition). E.g., "5-Stocks, 10-Indices". NULL if no qualifying positions. (Tier 2 - Dim_Position / Dim_Instrument)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Value_percenet COMMENT 'Top position value as a fraction of total portfolio (positions + credit). Formula: ROUND(Position_Value / NULLIF(Total_Position_Value + Credit, 0), 3). Measures portfolio concentration. Note: column name has a typo ("percenet" instead of "percent"). (Tier 2 - BI_DB_PositionPnL / V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() when SP_DailyPanel_Copy runs. (Tier 2 - SP_DailyPanel_Copy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Last_Day_Performance COMMENT 'Daily compound portfolio return as a decimal. ISNULL(Gain_d, 0) from DWH_GainDaily for the snapshot date. 0.05 = 5% gain. (Tier 2 - DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Gain_YTD COMMENT 'Year-to-date compound portfolio return as a decimal. ISNULL(Gain_YTD, 0) from DWH_GainDaily. From Jan 1 to snapshot date. (Tier 2 - DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Gain_QTD COMMENT 'Quarter-to-date compound portfolio return as a decimal. ISNULL(Gain_QTD, 0) from DWH_GainDaily. From first of current quarter to snapshot date. (Tier 2 - DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Gain_MTD COMMENT 'Month-to-date compound portfolio return as a decimal. ISNULL(Gain_MTD, 0) from DWH_GainDaily. From first of current month to snapshot date. (Tier 2 - DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN MonthsSinceFirstOpen COMMENT 'Months since the customer''s first trading action (position open or mirror registration). DATEDIFF(Month, MIN(FirstOccurred), @date) from Fact_FirstCustomerAction WHERE ActionTypeID IN (1=ManualOpen, 2=CopyOpen, 17=RegisterMirror). (Tier 2 - Fact_FirstCustomerAction)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN UserName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Gender SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Manager SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Language SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Seniority SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN DaysAsPI SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN CopyType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN PortfolioType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN GuruStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN GuruStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN PreviousGuruStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN TotalDaysInCurrentStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN BIO_Len SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN IsPrivate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN AllowDisplayFullName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN HasAvatar SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN RiskScore SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN LastBlockedDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN BlockReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN TotalEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN RealizedEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN TotalPositionsAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN PositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Credit SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN NumOfCopiers SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN CopyAUC SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN CopyPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN MI SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN MO SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN NetMI SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Trades SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Top_3_Traded_Instruments SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Top3TradedIndustries SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Lev_weighted_average SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN BuyPercent SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN SellPercent SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN HoldsHighLevPosition SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Classification SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Largest_Asset_Class SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN AvgerageHoldingTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN TraderType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN HighLevHoldingDetail SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Value_percenet SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Last_Day_Performance SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Gain_YTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Gain_QTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN Gain_MTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN MonthsSinceFirstOpen SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:36:22 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 116/116 succeeded
-- ====================
