-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_AML_Singapore_Risk_Classification
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_AML_Singapore_Risk_Classification **Generated**: 2026-04-22 **Schema**: BI_DB_dbo **Object Type**: Table **Writer SP**: SP_AML_Singapore_Risk_Classification **Load Pattern**: TRUNCATE + INSERT daily (@Date parameter) **Distribution**: ROUND_ROBIN **Index**: HEAP **Column Count**: 45 **Row Count**: 1,355 **Population**: MAS (Monetary Authority of Singapore) customers only **Priority**: 0 (OpsDB) **Frequency**: Daily **UC Migration**: Not Migrated ---'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN CID COMMENT 'DWH_dbo.Fact_SnapshotCustomer.RealCID';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN GCID COMMENT 'DWH_dbo.Dim_Customer.GCID';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Regulation COMMENT 'DWH_dbo.Dim_Regulation.Name (always ''MAS'')';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN PlayerStatus COMMENT 'DWH_dbo.Dim_PlayerStatus.Name';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Club COMMENT 'DWH_dbo.Dim_PlayerLevel.Name';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Country COMMENT 'DWH_dbo.Dim_Country.Name (via Fact_SnapshotCustomer.CountryID - snapshot country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Nationality_Country COMMENT 'DWH_dbo.Dim_Country.Name (via Dim_Customer.CitizenshipCountryID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN ScreeningStatus COMMENT 'Enriched from Dim_ScreeningStatus: ''No Match'' / ''Domestic PEP'' / ''Foreign PEP'' / other statuses';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN SOF_Answer_KYC COMMENT 'BI_DB_KYC_Panel.Q26_AnswerText (Source of Funds)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Occupation_KYC COMMENT 'BI_DB_KYC_Panel.Q18_AnswerText (Occupation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Annual_Income_Answer COMMENT 'BI_DB_KYC_Panel.Q10_AnswerText (Net Annual Income bracket)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Q11_Liquid_Assets_Answer COMMENT 'BI_DB_KYC_Panel.Q11_AnswerText (Total Cash and Liquid Assets bracket)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Net_Deposits COMMENT 'SUM(deposits) - SUM(cashouts) from DWH_dbo.Fact_CustomerAction';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN ScreeningStauts_Final_Score COMMENT 'Score: 0 (No Match), 50 (Domestic PEP), 200 (Foreign PEP or Risk Match)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Screening_Block_Final COMMENT '''Blocked'' if ScreeningStatusID=7 (Sanctions Match); NULL otherwise';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Occupation_Final_Score COMMENT 'Score per Q18 answer ID: 50 / 25 / 0';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Sources_of_funds_Final_Score COMMENT 'Score per Q26 answer: 0 / 50 / 100 (MAX when multiple answers)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Nationality_Final_Score COMMENT 'SG GRC score for Nationality_Country: 0 / 50 / 100 / 300';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN NationalityB_Final_Score COMMENT '''Blocked'' if Nationality_Country is Blocked-ranked in SG GRC sheet';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Annual_Income_Final_Score COMMENT 'Score per Q10: 50 if ''$1M-$5M''; 0 otherwise';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Liquid_Assets_Final_Score COMMENT 'Score per Q11: 50 if ''Over $1M'' or ''$1M-$5M''; 0 otherwise';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Net_Deposits_Final_Score COMMENT '100 if Net_Deposits > $1,000,000; 0 otherwise';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN UpdateDate COMMENT 'ETL metadata: GETDATE() at insert time';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN RegisteredReal COMMENT 'DWH_dbo.Dim_Customer.RegisteredReal';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN FirstDepositDate COMMENT 'DWH_dbo.Dim_Customer.FirstDepositDate';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Final_Score COMMENT 'Sum of all 10 score components (see Overview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Risk_Score COMMENT '''Blocked'' / ''High'' / ''Medium'' / ''Low'' classification';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Report_Date COMMENT 'Run date = @Date parameter value';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN POB_Final_Score COMMENT 'SG GRC score for POBCountry: 0 / 50 / 100 / 300';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN POB_B_Final_Score COMMENT '''Blocked'' if POBCountry is Blocked-ranked in SG GRC sheet';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN POBCountry COMMENT 'DWH_dbo.Dim_Country.Name (via Dim_Customer.POBCountryID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN TIN_CountryName COMMENT 'Tax country name from TIN declaration (External_UserApiDB_Customer_ExtendedUserField FieldId=6); ''()'' values converted to NULL';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN VerificationLevel3Date COMMENT 'BI_DB_dbo.BI_DB_CIDFirstDates.VerificationLevel3Date (date customer reached full KYC verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Redeem_Score COMMENT '100 if customer has a redemption cashout (ActionTypeID=8, IsRedeem=1); 0 otherwise';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Instrument_Risk_Score COMMENT '50 if customer has at least one settled crypto position (InstrumentTypeID=10, IsSettled=1); 0 otherwise';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN CountryIDByIP COMMENT 'DWH_dbo.Dim_Country.Name resolved from Dim_Customer.CountryIDByIP (country of last known login IP)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN KYC_Country_Final_Score COMMENT 'SG GRC score for Country (KYC/snapshot country): 0 / 50 / 100 / 300';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN KYC_Country_Final_Score_B_Final_Score COMMENT '''Blocked'' if KYC Country is Blocked-ranked in SG GRC sheet';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Employment_Status COMMENT 'KYC Q216 employment status answer text (from BI_DB_KYC_Questions_Answers_Row_Data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Employment_Status_Final_Score COMMENT '50 if Self-employed / Not Employed / Retired; 0 otherwise';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Citizenship_Sec_Final_Score COMMENT 'SG GRC score for Second_Citizenship country: 0 / 50 / 100 / 300';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Citizenship_Sec_Final_Score_B_Final_Score COMMENT '''Blocked'' if Second Citizenship country is Blocked-ranked';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Second_Citizenship COMMENT 'DWH_dbo.Dim_Country.Name (via External_UserApiDB_Customer_AdditionalCitizenship)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN VerificationLevelID COMMENT 'DWH_dbo.Fact_SnapshotCustomer.VerificationLevelID (snapshot value; >= 2 in all rows)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN VerificationLevel2Date COMMENT 'BI_DB_dbo.BI_DB_CIDFirstDates.VerificationLevel2Date (date customer reached partial KYC verification)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Nationality_Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN ScreeningStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN SOF_Answer_KYC SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Occupation_KYC SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Annual_Income_Answer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Q11_Liquid_Assets_Answer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Net_Deposits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN ScreeningStauts_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Screening_Block_Final SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Occupation_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Sources_of_funds_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Nationality_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN NationalityB_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Annual_Income_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Liquid_Assets_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Net_Deposits_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN RegisteredReal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Risk_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Report_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN POB_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN POB_B_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN POBCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN TIN_CountryName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN VerificationLevel3Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Redeem_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Instrument_Risk_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN CountryIDByIP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN KYC_Country_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN KYC_Country_Final_Score_B_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Employment_Status SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Employment_Status_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Citizenship_Sec_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Citizenship_Sec_Final_Score_B_Final_Score SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN Second_Citizenship SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN VerificationLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN VerificationLevel2Date SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:23:08 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 92/92 succeeded
-- ====================
