-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_KYC_Knowledge_Assessment
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_KYC_Knowledge_Assessment > 15.56M-row KYC knowledge assessment results table tracking customer responses to Question 23 ("Trading Knowledge Assessment") across three assessment versions: 142-146 (new, 5-question scored), 101-104 (old, single correct answer), and 84-87 (oldest, 4-answer boolean). 76% of customers passed at least one version. One row per GCID. Incremental DELETE+INSERT by GCID via SP_KYC_Panel. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table (KYC Knowledge Assessment Results) | | **Production Source** | BI_DB_KYC_Questions_Answers_Row_Data aggregated by SP_KYC_Panel | | **Refresh** | Daily incremental DELETE+INSERT by GCID (SB_Daily) | | **Synapse Distribution** | HASH(GCID) | | **Synapse Index** | CLUSTERED INDEX (GCID ASC) | | **UC Target** | `_Not_Migrated` | | **UC Format** | -- | | **UC Partitioned By** | '
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN GCID COMMENT 'Global customer ID. One row per GCID. JOIN to Dim_Customer on GCID = RealCID. Distribution and clustering key. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Q23_Assessment COMMENT 'Question text for Question 23. Typically ''Trading Knowledge Assessment''. From BI_DB_KYC_Questions_Answers_Row_Data.QuestionText. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Q23_Is_Assessment_Pass COMMENT 'Overall knowledge assessment pass flag. 1=passed at least one version, 0=attempted but failed all, -1=never attempted. 76% pass rate. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Assessment_142_146_Ind COMMENT 'Indicator for 142-146 assessment version. 1=customer took this version (7.1M), -1=did not. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Is_Assessment_142_146_Pass COMMENT 'Pass flag for 142-146 version. 1=passed (total points > -3), 0=failed, -1=version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Total_Points_Assessment_142_146 COMMENT 'Total score for 142-146 version. Range: -10 to +10. Each of 5 questions contributes +2 or -2. -100 sentinel if version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN P_AnswerId_142 COMMENT 'Point score for answer 142. +2 if selected (correct), -2 if not. -100 sentinel if 142-146 version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN P_AnswerId_143 COMMENT 'Point score for answer 143. -2 if selected (wrong), +2 if not selected (correct). -100 sentinel if 142-146 version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN P_AnswerId_144 COMMENT 'Point score for answer 144. +2 if selected (correct), -2 if not. -100 sentinel if 142-146 version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN P_AnswerId_145 COMMENT 'Point score for answer 145. -2 if selected (wrong), +2 if not selected (correct). -100 sentinel if 142-146 version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN P_AnswerId_146 COMMENT 'Point score for answer 146. -2 if selected (wrong), +2 if not selected (correct). -100 sentinel if 142-146 version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN OccurredAt_Assessment_142_146 COMMENT 'Timestamp of most recent 142-146 assessment attempt. MAX(OccurredAt) from raw Q&A data. 1900-01-01 sentinel if version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Assessment_101_104_Ind COMMENT 'Indicator for 101-104 assessment version. 1=customer took this version (8.4M), -1=did not. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Is_Assessment_101_104_Pass COMMENT 'Pass flag for 101-104 version. 1=selected AnswerID 102 (correct), 0=selected wrong answer, -1=version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Q23_AnswerID_101_104 COMMENT 'Selected answer ID for the 101-104 version. 101-104 or 127. -1 sentinel if version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Q23_AnswerText_101_104 COMMENT 'Selected answer text for 101-104 version. e.g. ''Opening a trade With $100 and 20x leverage will equate To a $2000 investment'' (correct). ''N/A'' sentinel if version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN OccurredAt_Assessment_101_104 COMMENT 'Timestamp of most recent 101-104 assessment attempt. 1900-01-01 sentinel if version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Assessment_84_87_Ind COMMENT 'Indicator for 84-87 assessment version. 1=customer took this version (32K), -1=did not. Legacy version, rare. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Is_Assessment_84_87_Pass COMMENT 'Pass flag for 84-87 version. 1=AnswerID 84 AND 87 selected AND 85 AND 86 not selected, 0=failed, -1=version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN OccurredAt_Assessment_84_87 COMMENT 'Timestamp of most recent 84-87 assessment attempt. 1900-01-01 sentinel if version not taken. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Q23_AnswerText COMMENT 'Legacy consolidated answer text. ''N/A'' for virtually all rows. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Q23_AnswerID COMMENT 'Legacy consolidated answer ID. -1 for virtually all rows. (Tier 2 -- SP_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last inserted/updated by SP_KYC_Panel. Set to GETDATE(). (Tier 5 -- SP_KYC_Panel)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Q23_Assessment SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Q23_Is_Assessment_Pass SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Assessment_142_146_Ind SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Is_Assessment_142_146_Pass SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Total_Points_Assessment_142_146 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN P_AnswerId_142 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN P_AnswerId_143 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN P_AnswerId_144 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN P_AnswerId_145 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN P_AnswerId_146 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN OccurredAt_Assessment_142_146 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Assessment_101_104_Ind SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Is_Assessment_101_104_Pass SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Q23_AnswerID_101_104 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Q23_AnswerText_101_104 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN OccurredAt_Assessment_101_104 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Assessment_84_87_Ind SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Is_Assessment_84_87_Pass SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN OccurredAt_Assessment_84_87 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Q23_AnswerText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN Q23_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_kyc_knowledge_assessment ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:33:01 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 10
-- Statements: 48/48 succeeded
-- ====================
