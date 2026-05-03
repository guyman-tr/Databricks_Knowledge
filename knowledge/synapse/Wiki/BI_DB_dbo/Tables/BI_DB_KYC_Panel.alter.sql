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
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN RealCID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN GCID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN IsFTD COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN IsFirstAction COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FunnelName COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Reg_Date COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Reg_Month COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FTD_Date COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FTD_Month COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q3_Trading_Knowledge COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q3_Is_Professional_Knowledge COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q3_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q23_Assessment COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q23_Is_Assessment_Pass COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q23_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Experience_Level COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q33_Experience_Equities COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q33_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q34_Experience_Crypto COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q34_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q35_Experience_CFDs COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q35_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q2_Experience COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q2_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q10_Annual_Income COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q10_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q11_Liquid_Assets COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q11_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q9_Risk_Reward_Scenario COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q9_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q14_Planned_Invested_Amount COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q14_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q27_Planned_Investment_Instrument COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Is_PI_Stocks COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Is_PI_Crypto COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Is_PI_FX COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Total_PI_Answers COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q5_Trading_Strategy COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q5_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q8_Trading_Primary_Purpose COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q8_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q15_Sources_of_Income COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q15_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q26_Sources_of_Funds COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q26_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q18_Occupation COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q18_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN GapInDays_Reg_to_FTD_Group COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN DaysFromFTD_Group COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN VerificationLevelID COMMENT 'T1';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CountryID COMMENT 'T1';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CountryName COMMENT 'T1';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Region COMMENT 'T1';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN EU COMMENT 'T1';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN RegulationID COMMENT 'T1';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN RegulatgionName COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Club COMMENT 'T1';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Gender COMMENT 'T1';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Age_Curr COMMENT 'T1';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Age_On_Reg COMMENT 'T3';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_Status COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_BlockDate COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_BlockReasonDesc COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_ReleaseDate COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN CFD_ReleaseReasonDesc COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN DateDiffBlockRelease COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstDepositAmount COMMENT 'T1';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstAction_Date COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstAction_Month COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstAction COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstAction_Detailed COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN FirstInstrument COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Deposit7days COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Deposit14days COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Deposit30days COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Revenue7days COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Revenue14days COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Revenue30days COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Equity7days COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Equity14days COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Equity30days COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q23_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q33_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q34_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q35_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q2_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q10_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q11_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q9_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q14_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q5_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q8_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q18_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN UpdateDate COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN KYC_LastUpdateDate COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q29_Time_Frame_Investing COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q29_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q29_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q36_US_Permanent_Resident COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q36_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q36_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q40_W9_Certification COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q40_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q40_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_FINRA COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_Is_Shareholder COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_Is_Employed_By_Broker COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_Is_Public_Official COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q30_Is_None_Apply_To_Me COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_PEP_MM_Question COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_Is_Shareholder COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_Is_Employed_By_Broker COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_Is_Public_Official COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q32_Is_None_Apply_To_Me COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q50_Is_Vulnerable_Client COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q50_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q50_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q45_Invested_Amount_CFDs COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q45_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q45_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q47_Invested_Amount_Equities COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q47_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q47_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q48_Invested_Amount_Crypto COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q48_AnswerID COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Q48_AnswerText COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Assessment_Type COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_panel ALTER COLUMN Total_Points_Assessment_142_146 COMMENT 'T2';

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
-- Timestamp: 2026-05-03 12:58:22 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 258/258 succeeded
-- ====================
