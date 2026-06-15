-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_First5Actions
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions SET TBLPROPERTIES (
    'comment' = 'BI_DB_First5Actions > Customer onboarding behavior profile. One row per depositor. Records the first five trading actions each customer took, the asset classes they touched, key revenue/deposit/equity milestones at 1/7/14/30/60/90/180/360-day windows post-FTD, and demographics from registration. The primary analytical use case is understanding "what did this customer do first after depositing?" - a critical input for activation and retention analysis. Used directly by SP_DepositUsersFirstTouchPoints. **Schema**: BI_DB_dbo | **Object Type**: Table | **Quality**: 8.8/10 ---'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN AffiliateID COMMENT 'Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Channel COMMENT 'Marketing acquisition channel. Passed through from BI_DB_CIDFirstDates.Channel (resolved via Dim_Affiliate -> Dim_Channel). ISNULL(,''Direct''). Values: Direct, Affiliate, SEM, etc.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SubChannel COMMENT 'Marketing sub-channel. Passed through from BI_DB_CIDFirstDates.SubChannel. ISNULL(,''Direct''). Values: Direct, Google Brand, Affiliate, etc.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Region COMMENT 'Marketing region at time of registration. From BI_DB_CIDFirstDates.Region (Dim_Country.Region). Values: North Europe, French, Eastern Europe, LATAM, etc.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Country COMMENT 'Country of residence name in English. From BI_DB_CIDFirstDates.Country (Dim_Country.Name via CountryID).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN NewMarketingRegion COMMENT 'Updated marketing region grouping. From BI_DB_CIDFirstDates.NewMarketingRegion (Dim_Country.MarketingRegionManualName). Introduced 2021-02-10. Preferred over Region for current segmentation.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstDepositDate COMMENT 'Date and time of customer''s first successful deposit. From BI_DB_CIDFirstDates.FirstDepositDate (Dim_Customer.FirstDepositDate ← CustomerFinanceDB.FirstTimeDeposits). 1900-01-01 = no deposit (sentinel - these rows exist in CIDFirstDates but are filtered out by this SP).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstDepositAmount COMMENT 'Amount in USD of customer''s first deposit. From BI_DB_CIDFirstDates.FirstDepositAmount (Dim_Customer.FirstDepositAmount ← CustomerFinanceDB.FirstTimeDeposits). YTD avg ~$696. Default 0 for $0 deposits.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstAction COMMENT 'Asset class of the customer''s 1st open position. CASE on InstrumentTypeID+MirrorID: ''Crypto'' (typeID=10), ''FX/Commodities/Indices'' (1/2/4), ''Stocks/ETFs'' (5/6), ''Copy Fund'' (CopyFund manager), ''Copy''. NULL if no position opened (~88.3%). Distribution: Crypto 5.3%, Stocks/ETFs 3.6%, Copy 1.4%, FX/Commodities/Indices 1.3%, Copy Fund 0.1%.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstActionDate COMMENT 'Datetime of 1st open position. From BI_DB_CustomerCross PIVOT (rn=1, MAX(Occurred)).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstInstrument COMMENT 'Display name of the first traded instrument. ISNULL(ParentUserName, InstrumentName): for Copy positions, shows the copied trader''s username; for direct trades, shows Dim_Instrument.Name.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondAction COMMENT 'Asset class of 2nd open position. Same CASE as FirstAction. NULL if fewer than 2 positions.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondInstrument COMMENT 'Display name for 2nd position (same pattern as FirstInstrument).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdAction COMMENT 'Asset class of 3rd open position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdInstrument COMMENT 'Display name for 3rd position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthAction COMMENT 'Asset class of 4th open position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthInstrument COMMENT 'Display name for 4th position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthAction COMMENT 'Asset class of 5th open position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthInstrument COMMENT 'Display name for 5th position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstLeverage COMMENT 'Leverage used for 1st open position. From BI_DB_CustomerFirst5OpenPositions.Leverage, rank=1. 1 = real (unlevered) stock purchase. >1 = CFD/leveraged position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondActionDate COMMENT 'Date of 2nd open position (Occurred, rank=2).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdActionDate COMMENT 'Date of 3rd open position (rank=3).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthActionDate COMMENT 'Date of 4th open position (rank=4).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthActionDate COMMENT 'Date of 5th open position (rank=5).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondLeverage COMMENT 'Leverage for 2nd position (rank=2).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdLeverage COMMENT 'Leverage for 3rd position (rank=3).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthLeverage COMMENT 'Leverage for 4th position (rank=4).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthLeverage COMMENT 'Leverage for 5th position (rank=5).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstAction_Detailed COMMENT 'Granular asset class for 1st position. Distinguishes ''Real Stocks/ETFs'' (Leverage=1, IsBuy=1) from ''CFD Stocks/ETFs'' (Leverage>1 or IsBuy=0). Values: Crypto, FX/Commodities/Indices, Real Stocks/ETFs, CFD Stocks/ETFs, Copy, Copy Fund.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondAction_Detailed COMMENT 'Granular asset class for 2nd position (same schema as FirstAction_Detailed).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdAction_Detailed COMMENT 'Granular asset class for 3rd position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthAction_Detailed COMMENT 'Granular asset class for 4th position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthAction_Detailed COMMENT 'Granular asset class for 5th position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstActionTypeNew COMMENT 'First position asset class using the new 3-way taxonomy. CASE on ActionTypeNew: ''Crypto'', ''FX/Commodities'' (typeID 1/2), ''Stocks/ETFs/Indices'' (typeID 4/5/6), ''Copy Fund'', ''Copy''. Merges Indices into Stocks bucket vs. legacy.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN `Traded_FX/Commodities/Indices` COMMENT '1 if FirstAction or any of the 5 cross positions = ''FX/Commodities/Indices''. 0 otherwise. Useful for "ever touched FX" segmentation.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN `Traded_Stocks/ETFs` COMMENT '1 if FirstAction or any cross = ''Stocks/ETFs'', ''Real Stocks/ETFs'', or ''CFD Stocks/ETFs''. 0 otherwise.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN TradedCrypto COMMENT '1 if FirstAction or any cross = ''Crypto''. 0 otherwise.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN TradedCopy COMMENT '1 if FirstAction or any cross = ''Copy''. 0 otherwise.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN TradedCopyFund COMMENT '1 if FirstAction or any cross = ''Copy Fund''. 0 otherwise.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstCross COMMENT 'Detailed asset class of 1st position (legacy). From BI_DB_CustomerCross PIVOT (ActionType_Detailed, rn=1). Same values as FirstAction_Detailed. ~6.5% non-NULL.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstCrossDate COMMENT 'Datetime of 1st cross event (from BI_DB_CustomerCross.Occurred, rn=1).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondCross COMMENT 'Detailed asset class of 2nd cross position (rn=2).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondCrossDate COMMENT 'Datetime of 2nd cross (rn=2).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdCross COMMENT 'Detailed asset class of 3rd cross (rn=3).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdCrossDate COMMENT 'Datetime of 3rd cross (rn=3).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthCross COMMENT 'Detailed asset class of 4th cross (rn=4).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthCrossDate COMMENT 'Datetime of 4th cross (rn=4).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthCross COMMENT 'Detailed asset class of 5th cross (rn=5).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthCrossDate COMMENT 'Datetime of 5th cross (rn=5).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstCrossNew COMMENT 'Asset class of 1st position using new ActionTypeNew taxonomy (BI_DB_CustomerCross_New, rn=1). Values: Crypto, FX/Commodities, Stocks/ETFs/Indices, Copy, Copy Fund. Preferred over FirstCross for new analyses.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstCrossDateNew COMMENT 'Date of 1st new-taxonomy cross (BI_DB_CustomerCross_New.Occurred, rn=1).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondCrossNew COMMENT '2nd cross position (new taxonomy, rn=2).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondCrossDateNew COMMENT 'Date of 2nd new cross (rn=2).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdCrossNew COMMENT '3rd cross position (rn=3).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdCrossDateNew COMMENT 'Date of 3rd new cross (rn=3).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthCrossNew COMMENT '4th cross position (rn=4).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthCrossDateNew COMMENT 'Date of 4th new cross (rn=4).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthCrossNew COMMENT '5th cross position (rn=5).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthCrossDateNew COMMENT 'Date of 5th new cross (rn=5).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue1day COMMENT 'Company revenue from this customer in the 1 day following FTD. From BI_DB_CID_BalanceDays. NULL if elapsed days since FTD < 0.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue7days COMMENT 'Revenue in 7 days post-FTD. NULL if < 6 days elapsed.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue14days COMMENT 'Revenue in 14 days post-FTD. NULL if < 13 days elapsed.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue30days COMMENT 'Revenue in 30 days post-FTD. NULL if < 29 days elapsed. ~10% populated; min=-$15,567, max=$1.54M, avg=$68.80.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue60days COMMENT 'Revenue in 60 days post-FTD. NULL if < 59 days.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue90days COMMENT 'Revenue in 90 days post-FTD. NULL if < 89 days.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue180days COMMENT 'Revenue in 180 days post-FTD. NULL if < 179 days.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue360days COMMENT 'Revenue in 360 days post-FTD. Sourced from BI_DB_CID_BalanceDays.Revenue365days (column name mismatch). NULL if < 364 days elapsed.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit1day COMMENT 'Total deposit amount in 1 day post-FTD. From BI_DB_CID_BalanceDays.Deposit1day.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit7days COMMENT 'Total deposits in 7 days post-FTD (includes FTD itself). NULL if < 6 days elapsed.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit14days COMMENT 'Total deposits in 14 days post-FTD.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit30days COMMENT 'Total deposits in 30 days post-FTD. ~12.6% populated.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit60days COMMENT 'Total deposits in 60 days post-FTD.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit90days COMMENT 'Total deposits in 90 days post-FTD.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit180days COMMENT 'Total deposits in 180 days post-FTD.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit360days COMMENT 'Total deposits in 360 days post-FTD. Sourced from BI_DB_CID_BalanceDays.Deposit365days.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity1day COMMENT 'Account equity snapshot 1 day post-FTD. From BI_DB_CID_BalanceDays.Equity1day.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity7days COMMENT 'Equity 7 days post-FTD. NULL if < 6 days elapsed.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity14days COMMENT 'Equity 14 days post-FTD.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity30days COMMENT 'Equity 30 days post-FTD. ~12.6% populated.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity60days COMMENT 'Equity 60 days post-FTD.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity90days COMMENT 'Equity 90 days post-FTD.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity180days COMMENT 'Equity 180 days post-FTD.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity360days COMMENT 'Equity 360 days post-FTD. Sourced from BI_DB_CID_BalanceDays.Equity365days.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN UpdateDate COMMENT 'Timestamp of SP execution that wrote this row. GETDATE() at INSERT time.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN LTV COMMENT '**DISABLED** - hardcoded to 0 for all rows since 2022-06-02 (Jan change). Previously intended to store lifetime value. Do not use.';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN AffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Channel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SubChannel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN NewMarketingRegion SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstDepositAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstActionDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstInstrument SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondInstrument SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdInstrument SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthInstrument SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthInstrument SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstLeverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondActionDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdActionDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthActionDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthActionDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondLeverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdLeverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthLeverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthLeverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstAction_Detailed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondAction_Detailed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdAction_Detailed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthAction_Detailed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthAction_Detailed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstActionTypeNew SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN TradedCrypto SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN TradedCopy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN TradedCopyFund SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstCross SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstCrossDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondCross SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondCrossDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdCross SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdCrossDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthCross SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthCrossDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthCross SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthCrossDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstCrossNew SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstCrossDateNew SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondCrossNew SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondCrossDateNew SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdCrossNew SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdCrossDateNew SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthCrossNew SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthCrossDateNew SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthCrossNew SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthCrossDateNew SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue1day SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue7days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue14days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue30days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue60days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue90days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue180days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue360days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit1day SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit7days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit14days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit30days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit60days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit90days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit180days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit360days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity1day SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity7days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity14days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity30days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity60days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity90days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity180days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity360days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN LTV SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN `Traded_FX/Commodities/Indices` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN `Traded_Stocks/ETFs` SET TAGS ('pii' = 'none');

