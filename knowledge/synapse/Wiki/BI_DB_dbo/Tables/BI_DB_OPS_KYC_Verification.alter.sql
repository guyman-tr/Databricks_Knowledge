-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_OPS_KYC_Verification
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_OPS_KYC_Verification > 1.76M-row KYC verification SLA tracking table covering customers who reached VerificationLevel >= 2 within the last year. Measures time-to-verify (days, hours, minutes), first-touch SLA (document upload to first review), verification method (EV=50%, Docs=18%, NA=31%), and KYC flow type from ComplianceStateDB. Sourced from DWH_dbo.Dim_Customer + History.BackOfficeCustomer + BackOffice documents + ComplianceStateDB KYC flow. Daily TRUNCATE+INSERT via SP_OPS_KYC_Verification. Only IsValidCustomer=1, RiskGroupID NOT IN (1,2). | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Key Identifier** | RealCID (not enforced - no PK in DDL) | | **Production Source** | SP_OPS_KYC_Verification (Pavlina Masoura, 2025-02-07) | | **Refresh** | Daily (1440 min), TRUNCATE+INSERT, 1-year rolling window (VL2 date >= Jan 1'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN RealCID COMMENT 'Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN FirstDepositDate COMMENT 'Date of first deposit. DEFAULT=''19000101''. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. Passthrough from Dim_Customer. (Tier 2 -- SP_Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN VerificationLevelID COMMENT 'KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. Filtered to > 1 in output. Passthrough from Dim_Customer. (Tier 1 -- BackOffice.Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN PlayerStatusID COMMENT 'Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered; other values indicate restricted, closed, banned, or special states. Default=0. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN PendingClosureStatusID COMMENT 'Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN PlayerStatusReasonID COMMENT 'Reason code for current PlayerStatusID. Provides the why behind a non-Active status. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN EvMatchStatus COMMENT 'Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. Passthrough from Dim_Customer. (Tier 1 -- BackOffice.Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN Region COMMENT 'Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. Dim-lookup passthrough from Dim_Country.Region via Dim_Customer.CountryID. (Tier 2 -- SP_Dictionaries_Country_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN Regulation COMMENT 'Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup passthrough from Dim_Regulation.Name via Dim_Customer.RegulationID. (Tier 1 -- Dictionary.Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN VerificationDate COMMENT 'Earliest timestamp when the customer reached VerificationLevelID=3 (fully verified). From MIN(ValidFrom) in History.BackOfficeCustomer. NULL if never reached VL3. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN DaysToVerify COMMENT 'Days from effective start date to VL3 verification. DATEDIFF(day, EffectiveDate, VerificationDate). 0 when EVMatchStatusDate > VerificationDate. Floor at 0 (negative values corrected). NULL for VL2-only customers. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN IsDepositor COMMENT '1 when FirstDepositDate is between 2000-01-01 and 2099-01-01 (has real deposit). 0 when sentinel (1900-01-01) - no deposit. Not the same as Dim_Customer.IsDepositor. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN EffectiveAddDate COMMENT 'Effective SLA start date. Priority waterfall: EVMatchStatusDate (if EV-verified) -> DateAdded (if no deposit or deposit-then-docs) -> FirstDepositDate (otherwise). Used as denominator for DaysToVerify and FirstTouch calculations. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN EvMatchStatusDate COMMENT 'Earliest timestamp when the customer reached EvMatchStatus=2 (Verified). From MIN(ValidFrom) in History.BackOfficeCustomer. NULL if never EV-verified. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN RiskGroupID COMMENT 'Granular country risk classification. 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. More nuanced than binary IsHighRiskCountry. Dim-lookup passthrough from Dim_Country.RiskGroupID via Dim_Customer.CountryID. (Tier 1 -- Dictionary.Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN VerificationMethod COMMENT 'How the customer was verified: ''EV'' (electronic verification, EvMatchStatus=2 + VL3), ''Docs'' (document review, VL3 without EV or with docs), ''NA'' (not yet VL3). (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN HoursToVerify COMMENT 'Hours from effective start date to VL3 verification. DATEDIFF(hour, EffectiveDate, VerificationDate). 0 when EVMatchStatusDate > VerificationDate. Floor at 0. NULL for VL2-only. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN MinutesToVerify COMMENT 'Minutes from effective start date to VL3 verification. DATEDIFF(minute, EffectiveDate, VerificationDate). 0 when EVMatchStatusDate > VerificationDate. Floor at 0. NULL for VL2-only. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN KYCFlow COMMENT 'KYC flow type name from ComplianceStateDB. Resolved via GCID: current flow preferred, fallback to latest historical when current KYCFlowTypeID=0. Example: "Verify Before Deposit". NULL when GCID not found in ComplianceStateDB. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN RegisteredDate COMMENT 'Account registration date (renamed from RegisteredReal in Dim_Customer). Default=getdate(). Passthrough from Dim_Customer.RegisteredReal. (Tier 1 -- Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. GETDATE() at SP execution time. Uniform across all rows (TRUNCATE+INSERT). (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN VerificationLevel1Date COMMENT 'Earliest timestamp when the customer reached VerificationLevelID=1 (partial). From MIN(ValidFrom) in History.BackOfficeCustomer. NULL if never reached VL1. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN VerificationLevel2Date COMMENT 'Earliest timestamp when the customer reached VerificationLevelID=2 (intermediate). From MIN(ValidFrom) in History.BackOfficeCustomer. Must be >= @6month for inclusion. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN DateAdded COMMENT 'Most recent KYC document upload date for this customer. From External_etoro_BackOffice_CustomerDocument, ROW_NUMBER DESC by DateAdded. Only documents with SuggestedDocumentTypeID IN (1,2,13,15,6,18,23). Excludes documents uploaded after VL3 date. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN Occurred COMMENT 'Document review occurred timestamp from BackOffice.CustomerDocumentToDocumentType. Sentinel ''3000-01-01'' when NULL in source (no review occurred yet). Used in FirstTouch SLA calculation. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN FirstReviewed COMMENT 'Effective first document review date. EVMatchStatusDate if EV-verified; Occurred if docs; conditional logic based on deposit/document/verification ordering. Used as endpoint for FirstTouch SLA. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN FirstTouch COMMENT 'Days from SLA start to first operations review. Complex CASE logic: 0 for instant EV, DATEDIFF from VL2/DateAdded/EffectiveAddDate to EVMatchStatusDate/Occurred/FirstReviewed depending on verification path. NULL when no touch point exists. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN FirstTouchHour COMMENT 'Hours from SLA start to first operations review. Same logic as FirstTouch but DATEDIFF in hours. (Tier 2 -- SP_OPS_KYC_Verification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN FirstTouchMinute COMMENT 'Minutes from SLA start to first operations review. Same logic as FirstTouch but DATEDIFF in minutes. (Tier 2 -- SP_OPS_KYC_Verification)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN VerificationLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN PlayerStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN PendingClosureStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN PlayerStatusReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN EvMatchStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN VerificationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN DaysToVerify SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN IsDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN EffectiveAddDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN EvMatchStatusDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN RiskGroupID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN VerificationMethod SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN HoursToVerify SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN MinutesToVerify SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN KYCFlow SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN RegisteredDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN VerificationLevel1Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN VerificationLevel2Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN DateAdded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN FirstReviewed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN FirstTouch SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN FirstTouchHour SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_kyc_verification ALTER COLUMN FirstTouchMinute SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:10:37 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 60/60 succeeded
-- ====================
