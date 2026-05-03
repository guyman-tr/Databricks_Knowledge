-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_AML_SAR_Report_FCA
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_AML_SAR_Report_FCA > Daily point-in-time snapshot of 1,414,989 FCA-regulated eToro UK customers for Suspicious Activity Report (SAR) compliance under the Proceeds of Crime Act 2002 - capturing full KYC identity, address, document proof status, lifetime deposit/cashout activity, and SAR risk classification code (XXS99XX/XXGVTXX based on GBP equity > £3,000 threshold). Refreshed daily via TRUNCATE+INSERT by SP_AML_SAR_Report. No historical rows - SARDate is always the run date. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | DWH_dbo.Dim_Customer (FCA only, via SP_AML_SAR_Report) | | **Refresh** | Daily TRUNCATE+INSERT - SP_AML_SAR_Report @Date (Priority 20, SB_Daily) | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | HEAP | | **UC Target** | `_Not_Migrated` | | **UC Format** | N/A | |'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. DWH note: mapped from Dim_Customer.RealCID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN GCID COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN AccountType COMMENT 'Account type name from Dim_AccountType. Values: Private (99.9%), Corporate, Joint Account, Funded Employee Account, Administrated Account, Affiliate Corporate Account, Analyst. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN BirthDate COMMENT 'Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Age COMMENT 'Customer age in whole years as of run date: DATEDIFF(YEAR, BirthDate, GETDATE()). NULL if YEAR(BirthDate) = 1900 (sentinel for unknown date of birth). (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Regulation COMMENT 'Regulation name. Always ''FCA'' in this table - population is filtered to DWHRegulationID=2. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN FirstName COMMENT 'Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN LastName COMMENT 'Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN MiddleName COMMENT 'Middle name in Unicode. Added 2018. Included in CustomerVersionUpdate history tracking. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN FullName COMMENT 'Concatenated full name: FirstName + '' '' + MiddleName + '' '' + LastName. Will include extra spaces when MiddleName is empty. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Gender COMMENT 'Gender expanded to full word: ''Female'' (source=''F''), ''Male'' (source=''M''), ''Unknown'' (source=''U'' or other). DWH note: Dim_Customer stores single-char ''M''/''F''/''U''. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Zip COMMENT 'Postal code. Used in LinkedAccountHash1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Address COMMENT 'Street address in Unicode. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN AddressType COMMENT 'Hardcoded ''Home Address'' for all rows - SP treats all customer addresses as home addresses. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN CurrentAddress COMMENT 'Hardcoded ''Y'' for all rows - SP assumes all on-file addresses are current. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN BuildingNumber COMMENT 'Building/apartment number. Separate from Address for structured address storage. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN City COMMENT 'City in Unicode. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Country COMMENT 'Country name resolved from Dim_Country (JOIN on dc.CountryID = dc1.DWHCountryID). (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN IsIDProof COMMENT 'Whether ID proof document is on file (1=yes, 0=no). NULL for ~56% of customers who have no proof record. Updated from BackOffice.CustomerDocument via SP_Dim_Customer. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN POI_Expiry_Date COMMENT 'Proof of Identity document expiry date. Renamed from Dim_Customer.IsIDProofExpiryDate. NULL if no ID proof on file. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN IsAddressProof COMMENT 'Whether address proof document is on file (1=yes, 0=no). Updated from BackOffice.CustomerDocument. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN POA_Expiry_Date COMMENT 'Proof of Address document expiry date. Renamed from Dim_Customer.IsAddressProofExpiryDate. NULL if no address proof on file. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN RegisteredReal COMMENT 'Account registration date (renamed from Registered). Default=getdate(). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN FirstDepositDate COMMENT 'Date of first deposit. DEFAULT=''19000101''. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN FirstDepositAmount COMMENT 'Amount of first deposit (in USD). Updated from FTDAmountInUsd. (Tier 2 - SP_Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN PlayerStatus COMMENT 'Customer account status from Dim_PlayerStatus. Values: Normal (86%), Blocked (8%), Blocked Upon Request (4%), Pending Verification (0.8%), Block Deposit & Trading (0.7%), Trade & MIMO Blocked (0.2%), Deposit Blocked (0.1%), Warning (0.07%), Copy Block (<0.1%). (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Club COMMENT 'Customer loyalty tier (PlayerLevel) from Dim_PlayerLevel. Values: Bronze (85%), Silver (5%), Gold (5%), Platinum (3%), Platinum Plus (2%), Diamond (<1%). (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Occupation COMMENT 'Customer-stated occupation from KYC questionnaire question 18 (free-text). LEFT JOIN on BI_DB_KYC_Panel.Q18_AnswerText - NULL if customer did not complete question 18. (Tier 4 - BI_DB_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN SourceRef COMMENT 'Regulatory reference field - same value as CID (dc.RealCID). Used in SAR submission forms as the source reference number identifying the eToro account. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN SARDate COMMENT 'Date of the SAR report. Always equals CAST(GETDATE() AS DATE) at SP execution time - the run date, not a business event date. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Currency COMMENT 'Hardcoded reporting currency. Always ''GBP (POUND STERLING)'' for FCA regulatory submissions. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN DisclosedAccountName COMMENT 'Full name repeated for regulatory disclosure form: FirstName + '' '' + MiddleName + '' '' + LastName. Identical to FullName computation. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Consent_Required COMMENT 'Hardcoded regulatory placeholder ''Y / N'' - indicates that consent status must be determined per SAR submission. Not a per-row flag. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Disclosure_Type COMMENT 'Legal framework citation. Always ''Proceeds of Crime Act 2002'' - the UK statute requiring SAR filing. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN SourceOutlet COMMENT 'Hardcoded office location. Always ''London'' - the FCA''s jurisdiction location for eToro UK. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN NumOfMOP_CO COMMENT 'Count of approved cashout transactions by method of payment for this CID (all time, CashoutStatusID=3). (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN TypeCO COMMENT 'Hardcoded cashout transaction type. Always ''Debit''. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN MOP_CO COMMENT 'Most frequently used cashout method of payment name (from Dim_FundingType). Selected by ROW_NUMBER OVER (PARTITION BY CID ORDER BY NumOfMOP DESC) = 1. NULL if no cashouts. Common values: eToroMoney, CreditCard, etc. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN TotalCO COMMENT 'Total approved cashout amount (all time). SUM(DISTINCT ISNULL(Amount_WithdrawToFunding, Amount_Withdraw)) from Fact_BillingWithdraw where CashoutStatusID=3. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN NumOfMOP_Deposit COMMENT 'Count of approved deposit transactions by method of payment for this CID (all time, PaymentStatusID=2). (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN TypeDep COMMENT 'Hardcoded deposit transaction type. Always ''Credit''. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN MOP_Dep COMMENT 'Most frequently used deposit method of payment name (from Dim_FundingType). Selected by ROW_NUMBER OVER (PARTITION BY CID ORDER BY NumOfMOP_Deposit DESC) = 1. NULL if no deposits. Common values: CreditCard, eToroMoney, etc. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN TotalDeposit_POUND COMMENT 'Total approved deposit amount (all time). SUM(fbd.Amount) where PaymentStatusID=2 from Fact_BillingDeposit. NOTE: Amount is in USD despite the column name "POUND" - naming is a legacy inconsistency. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN UpdateDate COMMENT 'ETL metadata: GETDATE() at SP execution time. Same value for all rows in a given run. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Phone COMMENT 'Phone number from production Customer.CustomerStatic. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Email COMMENT 'Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN SarCode COMMENT 'SAR risk tier code: ''XXS99XX'' = GBP_Equity > £3,000 (136,261 customers); ''XXGVTXX'' = GBP_Equity <= £3,000 (1,269,741 customers); NULL = no equity record for @DateID (~8,987 customers). (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN TotalEquity COMMENT 'Total equity at run date: ISNULL(V_Liabilities.Liabilities, 0) + ISNULL(V_Liabilities.ActualNWA, 0). In USD. NULL if CID not found in V_Liabilities for @DateID. (Tier 2 - SP_AML_SAR_Report)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN GBP_Equity COMMENT 'TotalEquity converted to GBP: TotalEquity × (1 / GBP_USD bid price from Fact_CurrencyPriceWithSplit where InstrumentID=2 and OccurredDateID = @DateID). Used to determine SarCode threshold. (Tier 2 - SP_AML_SAR_Report)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN AccountType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN BirthDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Age SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN FirstName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN LastName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN MiddleName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN FullName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Gender SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Zip SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Address SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN AddressType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN CurrentAddress SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN BuildingNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN City SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN IsIDProof SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN POI_Expiry_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN IsAddressProof SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN POA_Expiry_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN RegisteredReal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN FirstDepositAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Occupation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN SourceRef SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN SARDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN DisclosedAccountName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Consent_Required SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Disclosure_Type SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN SourceOutlet SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN NumOfMOP_CO SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN TypeCO SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN MOP_CO SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN TotalCO SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN NumOfMOP_Deposit SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN TypeDep SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN MOP_Dep SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN TotalDeposit_POUND SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Phone SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN Email SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN SarCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN TotalEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN GBP_Equity SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:22:09 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 100/100 succeeded
-- ====================
