-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_KYC_Panel
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_KYC_Panel > Daily full-rebuild KYC questionnaire snapshot (21.7M rows) covering every valid eToro customer''s assessment-questionnaire answers, experience level, CFD eligibility, trading activity windows, and demographic enrichment - pivoted from UserApiDB.KYC.CustomerAnswers via an external table bridge and rebuilt from scratch every day. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | UserApiDB.dbo.V_CustomerAnswers_Range_KYC_Panel (external table) + Dim_Customer (population gate) + BI_DB_First5Actions + BI_DB_Scored_Appropriateness_Negative_Market | | **Refresh** | Daily - SP_KYC_Panel @Date; full TRUNCATE + INSERT; rows with all KYC answers NULL are deleted post-insert | | **Synapse Distribution** | HASH(GCID) | | **Synapse Index** | CLUSTERED INDEX (GCID ASC) | | **UC Target** | Not Migrated | '
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN RealCID COMMENT 'eToro production CID (RealCID from Dim_Customer). Join key to all DWH fact tables via CID=RealCID. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN GCID COMMENT 'Global Customer ID from UserApiDB. Distribution key. Join key to KYC source tables. Prefer RealCID for DWH joins. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN IsFTD COMMENT '1 if customer has made at least one deposit (Dim_Customer.IsDepositor=1). 0 for non-depositors. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN IsFirstAction COMMENT '1 if customer has performed at least one trading action (BI_DB_First5Actions.FirstAction IS NOT NULL). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FunnelName COMMENT 'Acquisition funnel segment: ''SocialCopy'' (came via copy trading), ''Copy'' (other copy), ''Direct'' (organic), ''None'' (unclassified). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Reg_Date COMMENT 'Registration date (YYYYMMDD char format cast to date). From Dim_Customer.RegisteredReal. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Reg_Month COMMENT 'Registration year-month as YYYYMM integer. Useful for monthly cohort aggregation. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FTD_Date COMMENT 'First Time Deposit date. ''1900-01-01'' for non-depositors. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FTD_Month COMMENT 'FTD year-month as YYYYMM integer. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q3_Trading_Knowledge COMMENT 'Q3 raw answer ID (trading knowledge: educational and professional background). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q3_Is_Professional_Knowledge COMMENT '1 if Q3 responses indicate professional trading knowledge (courses, experience, or academic degree). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q3_AnswerText COMMENT 'Composite STRING_AGG of Q3 credential flags (e.g., "Professional Experience, Academic Degree"). Not a single answer text. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q23_Assessment COMMENT 'Q23 raw answer ID. Q23 is the core appropriateness assessment question. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q23_Is_Assessment_Pass COMMENT '1 if Q23 answer ID meets the pass threshold. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q23_AnswerText COMMENT 'Answer text for Q23. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Experience_Level COMMENT 'Composite experience tier: MAX(Q33, Q34, Q35 tiers) -> ''Non'', ''Low'', ''Med'', ''High'', ''N/A''. See section 2.4. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q33_Experience_Equities COMMENT 'Q33 raw answer ID (equities trading experience). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q33_AnswerText COMMENT 'Answer text for Q33. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q34_Experience_Crypto COMMENT 'Q34 raw answer ID (crypto trading experience). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q34_AnswerText COMMENT 'Answer text for Q34. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q35_Experience_CFDs COMMENT 'Q35 raw answer ID (CFD trading experience). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q35_AnswerText COMMENT 'Answer text for Q35. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q2_Experience COMMENT 'Q2 raw answer ID (general trading experience years). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q2_AnswerText COMMENT 'Answer text for Q2. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q10_Annual_Income COMMENT 'Q10 raw answer ID (annual income bracket). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q10_AnswerText COMMENT 'Answer text for Q10. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q11_Liquid_Assets COMMENT 'Q11 raw answer ID (liquid assets bracket). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q11_AnswerText COMMENT 'Answer text for Q11. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q9_Risk_Reward_Scenario COMMENT 'Q9 raw answer ID (risk/reward scenario understanding). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q9_AnswerText COMMENT 'Answer text for Q9. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q14_Planned_Invested_Amount COMMENT 'Q14 raw answer ID (total planned investment amount bracket). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q14_AnswerText COMMENT 'Answer text for Q14. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q27_Planned_Investment_Instrument COMMENT 'Q27 raw answer ID (planned instrument types - multi-select). Prefer Is_PI_* flags for individual instrument checks. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Is_PI_Stocks COMMENT '1 if customer plans to invest in Stocks (from Q27 multi-select). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Is_PI_Crypto COMMENT '1 if customer plans to invest in Crypto (from Q27). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Is_PI_FX COMMENT '1 if customer plans to invest in FX/CFDs (from Q27). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Total_PI_Answers COMMENT 'Count of distinct instrument selections in Q27 (0 - 3). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q5_Trading_Strategy COMMENT 'Q5 raw answer ID (preferred trading strategy). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q5_AnswerText COMMENT 'Answer text for Q5. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q8_Trading_Primary_Purpose COMMENT 'Q8 raw answer ID (primary purpose for trading: income/growth/speculation/etc.). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q8_AnswerText COMMENT 'Answer text for Q8. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q15_Sources_of_Income COMMENT 'Q15 primary/last answer ID (sources of income - multi-select question). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q15_AnswerText COMMENT 'STRING_AGG of all selected income source answer texts (multi-select). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q26_Sources_of_Funds COMMENT 'Q26 primary/last answer ID (sources of funds for investment - multi-select). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q26_AnswerText COMMENT 'STRING_AGG of all selected fund source answer texts (multi-select). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q18_Occupation COMMENT 'Q18 raw answer ID (occupation category). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q18_AnswerText COMMENT 'Answer text for Q18. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN GapInDays_Reg_to_FTD_Group COMMENT 'Days from registration to FTD, bucketed: ''0'', ''1-3'', ''4-7'', ''8-14'', ''15-30'', ''31+'', ''N/A''. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN DaysFromFTD_Group COMMENT 'Days from FTD to yesterday, bucketed: ''0'', ''1-7'', ''8-14'', ''15-30'', ''31+'', ''N/A''. RECOMPUTED DAILY - not stable. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN VerificationLevelID COMMENT 'KYC verification tier ID. 1=Basic, 2=Verified, 3=Fully Verified, etc. From Dim_Customer. (Tier 1 - Upstream wiki verbatim; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CountryID COMMENT 'FK to Dim_Country. Customer''s registered country. (Tier 1 - Upstream wiki verbatim; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CountryName COMMENT 'Country name from Dim_Country. (Tier 1 - Upstream wiki verbatim; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Region COMMENT 'Marketing region label from Dim_Country (e.g., ''EMEA'', ''LatAm'', ''APAC''). (Tier 1 - Upstream wiki verbatim; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN EU COMMENT '1 if customer''s country is an EU member state. From Dim_Country. (Tier 1 - Upstream wiki verbatim; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN RegulationID COMMENT 'FK to Dim_Regulation. Regulatory jurisdiction governing this customer. (Tier 1 - Upstream wiki verbatim; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN RegulatgionName COMMENT 'Regulation name from Dim_Regulation. NOTE: column name contains typo ''RegulatgionName'' (extra ''g'') - matches SP code. Use square brackets when referencing. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Club COMMENT 'eToro Club loyalty tier name (Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond) from Dim_PlayerLevel. (Tier 1 - Upstream wiki verbatim; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Gender COMMENT 'Customer self-reported gender. From Dim_Customer. (Tier 1 - Upstream wiki verbatim; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Age_Curr COMMENT 'Current age in years. From Dim_Customer. (Tier 1 - Upstream wiki verbatim; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Age_On_Reg COMMENT 'Age at time of registration. From Dim_Customer. (Tier 3 - Live data sampling; INFERRED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_Status COMMENT 'CFD access status: ''CFD_Allowed'', ''CFD_Blocked'', or NULL (no assessment). From BI_DB_Scored_Appropriateness_Negative_Market. See section 2.6. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_BlockDate COMMENT 'Date CFD access was blocked. NULL if never blocked. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_BlockReasonDesc COMMENT 'Reason description for CFD block (e.g., ''Failed Appropriateness Test''). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_ReleaseDate COMMENT 'Date CFD access was restored after blocking. NULL if still blocked or never blocked. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_ReleaseReasonDesc COMMENT 'Reason description for CFD release. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN DateDiffBlockRelease COMMENT 'Days between CFD block date and release date. NULL if still blocked or never blocked. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstDepositAmount COMMENT 'First deposit amount in USD. From Dim_Customer.FirstDepositAmount. (Tier 1 - Upstream wiki verbatim; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstAction_Date COMMENT 'Date of customer''s first trading action. From BI_DB_First5Actions. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstAction_Month COMMENT 'First action year-month as YYYYMM. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstAction COMMENT 'Type of first trading action (e.g., ''Buy'', ''CopyTrade''). From BI_DB_First5Actions. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstAction_Detailed COMMENT 'More detailed first action description. From BI_DB_First5Actions. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstInstrument COMMENT 'First instrument traded (symbol or instrument name). From BI_DB_First5Actions. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Deposit7days COMMENT 'Total deposits in first 7 days after FTD. From BI_DB_First5Actions. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Deposit14days COMMENT 'Total deposits in first 14 days after FTD. From BI_DB_First5Actions. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Deposit30days COMMENT 'Total deposits in first 30 days after FTD. From BI_DB_First5Actions. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Revenue7days COMMENT 'Revenue generated in first 7 days after FTD. From BI_DB_First5Actions. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Revenue14days COMMENT 'Revenue in first 14 days after FTD. From BI_DB_First5Actions. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Revenue30days COMMENT 'Revenue in first 30 days after FTD. From BI_DB_First5Actions. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Equity7days COMMENT 'Customer account equity at 7 days after FTD. From BI_DB_First5Actions. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Equity14days COMMENT 'Customer equity at 14 days after FTD. From BI_DB_First5Actions. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Equity30days COMMENT 'Customer equity at 30 days after FTD. From BI_DB_First5Actions. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q23_AnswerID COMMENT 'Raw numeric answer ID for Q23 (appropriateness assessment). Used in Assessment_Type derivation. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q33_AnswerID COMMENT 'Raw numeric answer ID for Q33 (equities experience). Used in Experience_Level computation. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q34_AnswerID COMMENT 'Raw numeric answer ID for Q34 (crypto experience). Used in Experience_Level computation. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q35_AnswerID COMMENT 'Raw numeric answer ID for Q35 (CFD experience). Used in Experience_Level computation. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q2_AnswerID COMMENT 'Raw numeric answer ID for Q2. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q10_AnswerID COMMENT 'Raw numeric answer ID for Q10. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q11_AnswerID COMMENT 'Raw numeric answer ID for Q11. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q9_AnswerID COMMENT 'Raw numeric answer ID for Q9. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q14_AnswerID COMMENT 'Raw numeric answer ID for Q14. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q5_AnswerID COMMENT 'Raw numeric answer ID for Q5. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q8_AnswerID COMMENT 'Raw numeric answer ID for Q8. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q18_AnswerID COMMENT 'Raw numeric answer ID for Q18. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN KYC_LastUpdateDate COMMENT 'Latest KYC answer submission timestamp from UserApiDB (MAX OccurredAt per GCID). Reflects when customer last updated their questionnaire responses. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q29_Time_Frame_Investing COMMENT 'Q29 raw answer ID (intended investment time frame: short/medium/long term). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q29_AnswerID COMMENT 'Raw numeric answer ID for Q29. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q29_AnswerText COMMENT 'Answer text for Q29. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q36_US_Permanent_Resident COMMENT 'Q36 raw answer ID (US permanent residency status - FinCEN/NFA-regulated customers). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q36_AnswerID COMMENT 'Raw numeric answer ID for Q36. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q36_AnswerText COMMENT 'Answer text for Q36. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q40_W9_Certification COMMENT 'Q40 raw answer ID (W9 tax certification - US-specific compliance). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q40_AnswerID COMMENT 'Raw numeric answer ID for Q40. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q40_AnswerText COMMENT 'Answer text for Q40. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_FINRA COMMENT 'Q30 raw answer ID (FINRA/broker affiliation - multi-select, US-regulated customers). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_Is_Shareholder COMMENT '1 if Q30 includes "10%+ shareholder of a publicly traded company". (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_Is_Employed_By_Broker COMMENT '1 if Q30 includes "employed by a broker/dealer or FINRA member firm". (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_Is_Public_Official COMMENT '1 if Q30 includes "government official or public figure". (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_Is_None_Apply_To_Me COMMENT '1 if Q30 answer is "none of the above". (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_PEP_MM_Question COMMENT 'Q32 raw answer ID (PEP / money manager declaration - multi-select). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_Is_Shareholder COMMENT '1 if Q32 includes shareholder status. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_Is_Employed_By_Broker COMMENT '1 if Q32 includes broker/dealer employment. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_Is_Public_Official COMMENT '1 if Q32 includes public official / PEP status. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_Is_None_Apply_To_Me COMMENT '1 if Q32 is "none apply to me". (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q50_Is_Vulnerable_Client COMMENT 'Q50 raw answer ID (FCA Consumer Duty vulnerable client self-assessment - FCA-regulated only). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q50_AnswerID COMMENT 'Raw numeric answer ID for Q50. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q50_AnswerText COMMENT 'Answer text for Q50. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q45_Invested_Amount_CFDs COMMENT 'Q45 raw answer ID (total amount invested in CFDs historically). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q45_AnswerID COMMENT 'Raw numeric answer ID for Q45. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q45_AnswerText COMMENT 'Answer text for Q45. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q47_Invested_Amount_Equities COMMENT 'Q47 raw answer ID (total amount invested in equities historically). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q47_AnswerID COMMENT 'Raw numeric answer ID for Q47. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q47_AnswerText COMMENT 'Answer text for Q47. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q48_Invested_Amount_Crypto COMMENT 'Q48 raw answer ID (total amount invested in crypto historically). (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q48_AnswerID COMMENT 'Raw numeric answer ID for Q48. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q48_AnswerText COMMENT 'Answer text for Q48. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Assessment_Type COMMENT 'KYC assessment questionnaire version: ''AnswerID_84_87'' (legacy), ''AnswerID_101_104'', ''AnswerID_142_146'' (current), ''N/A''. See section 2.2. (Tier 2 - SP/DDL code; CODE-BACKED)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Total_Points_Assessment_142_146 COMMENT 'Appropriateness score for AnswerID_142_146 type (+2 correct/-2 wrong). -100 sentinel for all other Assessment_Type values. See section 2.3. (Tier 2 - SP/DDL code; CODE-BACKED)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN IsFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN IsFirstAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FunnelName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Reg_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Reg_Month SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FTD_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FTD_Month SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q3_Trading_Knowledge SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q3_Is_Professional_Knowledge SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q3_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q23_Assessment SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q23_Is_Assessment_Pass SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q23_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Experience_Level SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q33_Experience_Equities SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q33_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q34_Experience_Crypto SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q34_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q35_Experience_CFDs SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q35_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q2_Experience SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q2_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q10_Annual_Income SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q10_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q11_Liquid_Assets SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q11_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q9_Risk_Reward_Scenario SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q9_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q14_Planned_Invested_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q14_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q27_Planned_Investment_Instrument SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Is_PI_Stocks SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Is_PI_Crypto SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Is_PI_FX SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Total_PI_Answers SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q5_Trading_Strategy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q5_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q8_Trading_Primary_Purpose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q8_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q15_Sources_of_Income SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q15_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q26_Sources_of_Funds SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q26_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q18_Occupation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q18_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN GapInDays_Reg_to_FTD_Group SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN DaysFromFTD_Group SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN VerificationLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CountryName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN EU SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN RegulatgionName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Gender SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Age_Curr SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Age_On_Reg SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_Status SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_BlockDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_BlockReasonDesc SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_ReleaseDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_ReleaseReasonDesc SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN DateDiffBlockRelease SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstDepositAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstAction_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstAction_Month SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstAction_Detailed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstInstrument SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Deposit7days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Deposit14days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Deposit30days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Revenue7days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Revenue14days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Revenue30days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Equity7days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Equity14days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Equity30days SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q23_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q33_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q34_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q35_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q2_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q10_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q11_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q9_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q14_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q5_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q8_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q18_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN KYC_LastUpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q29_Time_Frame_Investing SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q29_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q29_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q36_US_Permanent_Resident SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q36_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q36_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q40_W9_Certification SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q40_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q40_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_FINRA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_Is_Shareholder SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_Is_Employed_By_Broker SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_Is_Public_Official SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_Is_None_Apply_To_Me SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_PEP_MM_Question SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_Is_Shareholder SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_Is_Employed_By_Broker SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_Is_Public_Official SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_Is_None_Apply_To_Me SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q50_Is_Vulnerable_Client SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q50_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q50_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q45_Invested_Amount_CFDs SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q45_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q45_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q47_Invested_Amount_Equities SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q47_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q47_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q48_Invested_Amount_Crypto SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q48_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q48_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Assessment_Type SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Total_Points_Assessment_142_146 SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 11:12:33 UTC
-- Batch: tier_drift_fix (2026-05-19 one-shot)
-- Statements: 258/258 succeeded
-- ====================
