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
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN CID COMMENT 'Tier 1';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN AffiliateID COMMENT 'Tier 1';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Channel COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SubChannel COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Region COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Country COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN NewMarketingRegion COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstDepositDate COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstDepositAmount COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstAction COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstActionDate COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstInstrument COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondAction COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondInstrument COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdAction COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdInstrument COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthAction COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthInstrument COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthAction COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthInstrument COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstLeverage COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondActionDate COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdActionDate COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthActionDate COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthActionDate COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondLeverage COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdLeverage COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthLeverage COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthLeverage COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstAction_Detailed COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondAction_Detailed COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdAction_Detailed COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthAction_Detailed COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthAction_Detailed COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstActionTypeNew COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN `Traded_FX/Commodities/Indices` COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN `Traded_Stocks/ETFs` COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN TradedCrypto COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN TradedCopy COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN TradedCopyFund COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstCross COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstCrossDate COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondCross COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondCrossDate COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdCross COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdCrossDate COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthCross COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthCrossDate COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthCross COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthCrossDate COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstCrossNew COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FirstCrossDateNew COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondCrossNew COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN SecondCrossDateNew COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdCrossNew COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN ThirdCrossDateNew COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthCrossNew COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FourthCrossDateNew COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthCrossNew COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN FifthCrossDateNew COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue1day COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue7days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue14days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue30days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue60days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue90days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue180days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Revenue360days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit1day COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit7days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit14days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit30days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit60days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit90days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit180days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Deposit360days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity1day COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity7days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity14days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity30days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity60days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity90days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity180days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN Equity360days COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN UpdateDate COMMENT 'Tier 2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN LTV COMMENT 'Tier 2';

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

