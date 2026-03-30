-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Client_New_CompensationBreakdown
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Client_New_CompensationBreakdown'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN CID COMMENT 'Customer ID who received the compensation. From Fact_CustomerAction.RealCID filtered to ActionTypeID = 36. (Tier 2 - SP_Client_Balance_New, Fact_CustomerAction.RealCID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN TransferDirection COMMENT 'Direction of regulation transfer. 1 = incoming (to regulation). The classification columns are from the destination regulation only. (Tier 2 - SP_Client_Balance_New, #CIDAgg)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN CompensationType COMMENT 'Compensation category name from Dim_CompensationReason.Name. Values: "Interest Payment", "Special Promotion", "Promotion - Leads", "Referral Bonus", etc. (Tier 2 - SP_Client_Balance_New, Dim_CompensationReason.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN AccountType COMMENT 'Account type: "Private" or "Corporate". From customer classification dimensions via #CIDAgg. (Tier 2 - SP_Client_Balance_New, Dim_AccountType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN Country COMMENT 'Customer country (full name). From Dim_Country via Fact_SnapshotCustomer. (Tier 2 - SP_Client_Balance_New, Dim_Country.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN MifidCategory COMMENT 'MiFID II client categorization. Values: "Retail", "Retail Pending", "Professional". (Tier 2 - SP_Client_Balance_New, Dim_MifidCategorization)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN PlayerStatus COMMENT 'Customer account status. Values: "Normal", "Block Deposit & Trading", "Deposit Blocked", etc. (Tier 2 - SP_Client_Balance_New, Dim_PlayerStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN Regulation COMMENT 'Customer''s current regulation. Values: "CySEC", "FCA", "ASIC", "FinCEN+FINRA", "BVI", "FSA", etc. (Tier 2 - SP_Client_Balance_New, Dim_Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN IsCreditReportValidCB COMMENT 'Credit report validity flag for CB reporting. 1 = valid. (Tier 2 - SP_Client_Balance_New, Fact_SnapshotCustomer.IsCreditReportValidCB)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN DidRegulationTransfer COMMENT 'Flag: 1 if CID transferred regulation on this date. From Fact_RegulationTransfer. (Tier 2 - SP_Client_Balance_New, Fact_RegulationTransfer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN DidCBValidTransfer COMMENT 'Flag: 1 if CID''s CB validity status changed on this date. (Tier 2 - SP_Client_Balance_New, #CIDAgg)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN FromRegulation COMMENT 'Source regulation before transfer. Equals Regulation if no transfer occurred. (Tier 2 - SP_Client_Balance_New, Dim_Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN ToRegulation COMMENT 'Target regulation after transfer. Equals Regulation if no transfer occurred. (Tier 2 - SP_Client_Balance_New, Dim_Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN IsEtoroTradingCID COMMENT 'Flag: 1 if this is an eToro internal trading/test account. Used to exclude from external reporting. (Tier 2 - SP_Client_Balance_New, #CIDAgg)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN eToroTradingGroupUser COMMENT 'eToro group user classification. "NotEtoroGroupAccount" for regular customers. Internal accounts have specific group names. (Tier 2 - SP_Client_Balance_New, #CIDAgg)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN IsGlenEagleAccount COMMENT 'Flag: 1 if this is a Glen Eagle (partner/white-label) account. (Tier 2 - SP_Client_Balance_New, #CIDAgg)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN CompensationAmount COMMENT 'Total compensation amount paid to this CID for this compensation type on this date in USD. SUM(CAST(Fact_CustomerAction.Amount AS DECIMAL(18,4))). (Tier 2 - SP_Client_Balance_New, Fact_CustomerAction.Amount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN DateID COMMENT 'YYYYMMDD integer date. Clustered index column. SP @dateID parameter. (Tier 2 - SP_Client_Balance_New, @dateID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN UpdateDate COMMENT 'SP execution timestamp. GETDATE(). (Tier 3 - SP_Client_Balance_New, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN IsGermanBaFin COMMENT 'German BaFin regulatory flag. 1 if CID in V_GermanBaFin for this date. (Tier 2 - SP_Client_Balance_New, V_GermanBaFin)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN Date COMMENT 'Calendar date. SP @date parameter. (Tier 2 - SP_Client_Balance_New, @date)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN YearMonth COMMENT 'YYYYMM integer for month-level aggregation. Computed: CONVERT(VARCHAR(6),@date,112). (Tier 2 - SP_Client_Balance_New, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN YearQuarter COMMENT 'YYYYQQ integer for quarter-level aggregation. Computed: YEAR(@date) * 100 + DATEPART(qq, @date). E.g., 202202 = Q2 2022. (Tier 2 - SP_Client_Balance_New, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN Year COMMENT 'Calendar year. YEAR(@date). (Tier 2 - SP_Client_Balance_New, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN IsValidCustomer COMMENT 'Legacy valid customer flag. From #CIDAgg. (Tier 2 - SP_Client_Balance_New, #CIDAgg)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN MoveMoneyReason COMMENT 'Reason for the money movement from Dim_MoveMoneyReason. LEFT JOIN - may be NULL. (Tier 2 - SP_Client_Balance_New, Dim_MoveMoneyReason.MoveMoneyReason)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN CompensationReasonID COMMENT 'FK to Dim_CompensationReason. Numeric ID corresponding to CompensationType. Values: 57 (Interest Payment), 20 (Special Promotion), 94 (Promotion - Leads), etc. (Tier 2 - SP_Client_Balance_New, Fact_CustomerAction.CompensationReasonID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN TanganyStatus COMMENT 'Tangany crypto custody wallet status. From External_UserApiDB_Dictionary_TanganyStatus.Name via Dim_Customer.TanganyStatusID. NULL if customer has no Tangany integration. (Tier 2 - SP_Client_Balance_New, External_UserApiDB_Dictionary_TanganyStatus.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN IsDLTUser COMMENT 'Flag: 1 if CID is a DLT (Digital Ledger Technology / blockchain) platform user. From #findDiffsDLT temp table. (Tier 2 - SP_Client_Balance_New, #findDiffsDLT)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN DidDLTTransfer COMMENT 'Flag: 1 if CID performed a DLT platform transfer on this date. (Tier 2 - SP_Client_Balance_New, #findDiffsDLT)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN US_State COMMENT 'US state code (2 characters). Only populated for US customers (CountryID = 219). From Dim_State_and_Province.ShortName via Dim_Customer.RegionID. NULL for non-US. (Tier 2 - SP_Client_Balance_New, Dim_State_and_Province.ShortName)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN TransferDirection SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN CompensationType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN AccountType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN MifidCategory SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN DidRegulationTransfer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN DidCBValidTransfer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN FromRegulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN ToRegulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN IsEtoroTradingCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN eToroTradingGroupUser SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN IsGlenEagleAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN CompensationAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN IsGermanBaFin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN YearMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN YearQuarter SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN Year SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN MoveMoneyReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN CompensationReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN TanganyStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN IsDLTUser SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN DidDLTTransfer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN US_State SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 15:57:50 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 1
-- Statements: 64/64 succeeded
-- ====================
