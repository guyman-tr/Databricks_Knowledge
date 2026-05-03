-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_AMLPeriodicReview
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_AMLPeriodicReview > Cumulative daily AML periodic review workbook for all verified eToro depositors - triggering scheduled KYC reviews (3-year Medium Risk, annual High Risk/PEP, dormancy reactivation) and computing six alert dimensions across PII changes, login anomalies, high-risk transactions, document validity, economic profile, and jurisdiction risk. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Sources** | DWH_dbo.Dim_Customer + Fact_CustomerAction + Fact_SnapshotCustomer + 25+ source tables (see Section 5) | | **Refresh** | Daily (OpsDB P0) - DELETE+INSERT per review date | | | | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | HEAP | | **Writer SP** | SP_BI_AMLPeriodicReview | | | | | **UC Target** | pending | ---'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN RealCID COMMENT 'Customer ID (RealCID) - platform-internal primary key. Assigned at registration. May appear multiple times across different Review_Due_Dates and AlertCategories. (Tier 1 - DWH_dbo.Dim_Customer wiki, originally Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN FirstDepositDate COMMENT 'Date of first deposit. DEFAULT=''19000101''. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. Used as the anchor date for GROUP A 3-year review scheduling. (Tier 1 - DWH_dbo.Dim_Customer wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Review_Due_Date COMMENT 'The review trigger date - the date this customer''s review is due. For GROUP A: FirstDepositDate + 3n years. For GROUP B: @Date (day of reactivation). For GROUP C/D: day of classification/screening change or its annual anniversary. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Review_Due_DateID COMMENT 'Integer representation of Review_Due_Date in YYYYMMDD format. Used for OpsDB date-range operations. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN KYC_Country_ID COMMENT 'Country of residence ID (CountryID from Dim_Customer). FK to Dictionary.Country. Determines regulatory framework. (Tier 1 - DWH_dbo.Dim_Customer wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POBCountryID COMMENT 'Place of birth country ID. FK to Dictionary.Country. Added for enhanced KYC. (Tier 1 - DWH_dbo.Dim_Customer wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN CitizenshipCountryID COMMENT 'Country of citizenship ID. FK to Dictionary.Country. Added 2018 for enhanced KYC. (Tier 1 - DWH_dbo.Dim_Customer wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN KYC_Country COMMENT 'Country of residence name from Dim_Country. The primary KYC country for this customer. (Tier 1 - DWH_dbo.Dim_Customer wiki via Dim_Country JOIN)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POBCountry COMMENT 'Place of birth country name from Dim_Country (POBCountryID). May differ from KYC_Country. NULL if POBCountryID not set. (Tier 1 - DWH_dbo.Dim_Customer wiki via Dim_Country LEFT JOIN)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN CitizenshipCountry COMMENT 'Country of citizenship name from Dim_Country. May differ from KYC_Country. NULL if CitizenshipCountryID not set. (Tier 1 - DWH_dbo.Dim_Customer wiki via Dim_Country LEFT JOIN)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN KYC_Country_Rank COMMENT 'Risk group rank of the KYC country from Dim_Country.RiskGroupID. Lower values = higher risk (1,2 = high-risk jurisdictions). Used in RoutineMonitoringRedFlagsHRC alert logic. (Tier 2 - SP_BI_AMLPeriodicReview via Dim_Country.RiskGroupID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POBCountry_Rank COMMENT 'Risk group rank of the place of birth country. Used in high-risk jurisdiction alert checks. (Tier 2 - SP_BI_AMLPeriodicReview via Dim_Country.RiskGroupID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN CitizenshipCountry_Rank COMMENT 'Risk group rank of the citizenship country. Used in high-risk jurisdiction alert checks. (Tier 2 - SP_BI_AMLPeriodicReview via Dim_Country.RiskGroupID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN ScreeningStatus COMMENT 'Compliance screening status text name from Dim_ScreeningStatus. Updated from ScreeningService. GROUP D triggers when ScreeningStatusID=3 (PEP). Sample: NoMatch, PEP, Adverse Media. (Tier 1 - DWH_dbo.Dim_Customer wiki via Dim_ScreeningStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN PhoneVerified COMMENT 'Phone verification status text from Dim_PhoneVerified (PhoneVerifiedID). Indicates whether the customer''s phone number has been verified. (Tier 1 - DWH_dbo.Dim_Customer wiki via Dim_PhoneVerified)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN EvMatchStatusName COMMENT 'Electronic verification match status name from Dim_EvMatchStatus (EvMatchStatus). Decision from automated identity verification vendors (Onfido, Au10tix). Sample: Verified, NotVerified, NULL. (Tier 1 - DWH_dbo.Dim_Customer wiki via Dim_EvMatchStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN AlertCategory COMMENT 'Review trigger group: ''GROUP A: Periodic Review for Medium Risk Classification'', ''GROUP B: Dormancy and Reactivation'', ''GROUP C: Scheduled Reviews for High Risk Classification'', ''GROUP D: Scheduled Reviews for PEPs''. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN VerificationLevelID COMMENT 'KYC verification level. Always 3 in this table (population filter: VerificationLevelID=3 = fully verified). (Tier 1 - DWH_dbo.Dim_Customer wiki; always 3 here)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN PlayerStatus COMMENT 'Compliance and trading account status text from Dim_PlayerStatus. Population excludes PlayerStatusID IN (2,4). (Tier 1 - DWH_dbo.Dim_Customer wiki via Dim_PlayerStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN PlayerStatusReason COMMENT 'Reason code text for current PlayerStatus from Dim_PlayerStatusReasons. NULL if status is Normal/Active. (Tier 1 - DWH_dbo.Dim_Customer wiki via Dim_PlayerStatusReasons)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN PlayerStatusSubReason COMMENT 'Sub-reason text for PlayerStatus from Dim_PlayerStatusSubReasons. Added 2022. NULL for most records. (Tier 1 - DWH_dbo.Dim_Customer wiki via Dim_PlayerStatusSubReasons)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Club COMMENT 'Customer experience/permission level text from Dim_PlayerLevel (PlayerLevelID). Sample: Bronze, Silver, Platinum, Platinum Plus. (Tier 1 - DWH_dbo.Dim_Customer wiki via Dim_PlayerLevel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN RiskClassification COMMENT 'AML risk classification name from Dim_RiskClassification. Sample: Medium (GROUP A), High (GROUP C). NULL for some records (risk classification not assigned). (Tier 2 - SP_BI_AMLPeriodicReview via Dim_RiskClassification)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Regulation COMMENT 'Regulatory entity text from Dim_Regulation (RegulationID). Sample: CySEC, FCA, FinCEN+FINRA. (Tier 1 - DWH_dbo.Dim_Customer wiki via Dim_Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POI_ExpiryDate COMMENT 'Proof of Identity document expiry date from Dim_Customer.IsIDProofExpiryDate. NULL if no POI document on file. (Tier 2 - SP_BI_AMLPeriodicReview via Dim_Customer.IsIDProofExpiryDate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POA_ExpiryDate COMMENT 'Proof of Address document issue date from External_etoro_BackOffice_CustomerDocument (DocumentTypeID=1, MAX IssueDate). The POA is considered expired if IssueDate < 1 year ago AND the customer has flagged activity. NULL if no POA document. (Tier 2 - SP_BI_AMLPeriodicReview, new POA expiry policy 2025-10-30)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Is_POI_Expired COMMENT '1 if POI_ExpiryDate < today (ID proof is expired); 0 otherwise. NULL when POI_ExpiryDate is NULL. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Is_POA_Expired COMMENT '1 if POA_ExpiryDate (issue date) < 1 year ago AND customer has flagged activity (FlaggedCustomers); 0 otherwise. (Tier 2 - SP_BI_AMLPeriodicReview, 2025-10-30 policy update)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POI_IsMissing COMMENT '1 if POI_ExpiryDate IS NULL AND no EV date exists (EvMatchStatusDate IS NULL); 0 otherwise. Indicates no identity proof on file and no electronic verification. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POA_IsMissing COMMENT '1 if POA_ExpiryDate IS NULL AND no EV date exists; 0 otherwise. Indicates no address proof and no electronic verification. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TaxCountry COMMENT 'Comma-separated list of up to 3 TIN (Tax Identification Number) country names from External_UserApiDB_Customer_ExtendedUserField (FieldId=6). Represents where the customer declares tax residency. NULL if no TIN country declared. (Tier 2 - SP_BI_AMLPeriodicReview, UserApiDB)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN LastUpdatedDateTaxCountry COMMENT 'Date of the most recent TIN/tax country update in UserApiDB. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TaxCountryDiscrepancy COMMENT '1 if any TIN country differs from KYC_Country; 0 if all TIN countries match. Used in RoutineMonitoringRedFlagsOutdatedData alert. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN EVStatus COMMENT 'Electronic verification status name from Dim_EvMatchStatus (fresh lookup at #finalreport stage). Equivalent to EvMatchStatusName but re-joined at a later SP step. Sample: Verified, NotVerified. (Tier 2 - SP_BI_AMLPeriodicReview, same source as EvMatchStatusName)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN LastEVDate COMMENT 'Date of the most recent electronic verification run from BI_DB_CIDFirstDates.EvMatchStatusDate. NULL if no EV has been performed. (Tier 2 - SP_BI_AMLPeriodicReview via BI_DB_CIDFirstDates)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN EVReviewPending COMMENT 'EV staleness assessment: ''Re-runEV'' (EV > 3yr for Medium or > 1yr for High Risk), ''NotEVVerified'' (no EV date), ''EV ok'' (within validity window). (Tier 2 - SP_BI_AMLPeriodicReview, staleness logic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN KYC_LastUpdateDate COMMENT 'Date of the most recent KYC questionnaire update from BI_DB_KYC_Panel.KYC_LastUpdateDate. Used for EconomicProfileReviewPending staleness check. (Tier 2 - SP_BI_AMLPeriodicReview via BI_DB_KYC_Panel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN EconomicProfileReviewPending COMMENT 'Economic profile staleness: ''Pending'' if KYC update > 3yr old for Medium Risk or > 1yr for High Risk; ''Not Pending'' otherwise. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalDepositsLifetime COMMENT 'Cumulative total approved deposit amount (USD) from Fact_BillingDeposit (PaymentStatusID=2), all time up to @Date. (Tier 2 - SP_BI_AMLPeriodicReview via Fact_BillingDeposit)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalDepositsCurrentYear COMMENT 'Total approved deposits from Jan 1 of the current year to @Date. (Tier 2 - SP_BI_AMLPeriodicReview via Fact_BillingDeposit)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalDeposits12Months COMMENT 'Total approved deposits in the trailing 12 months from @Date. (Tier 2 - SP_BI_AMLPeriodicReview via Fact_BillingDeposit)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalDeposits6Months COMMENT 'Total approved deposits in the trailing 6 months from @Date. (Tier 2 - SP_BI_AMLPeriodicReview via Fact_BillingDeposit)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN LastEPUpdateDate COMMENT 'Duplicate of KYC_LastUpdateDate - SP assigns kyc.KYC_LastUpdateDate to both columns. (Tier 2 - SP duplicate of KYC_LastUpdateDate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN SourcesOfIncome COMMENT 'Customer''s declared sources of income text (KYC questionnaire Q15). Free-text answer. Examples: Employment, Pension, Savings, Inheritance. (Tier 2 - SP_BI_AMLPeriodicReview via BI_DB_KYC_Panel Q15)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN SourceOfIncomeAlert COMMENT '''Alert'' if SourcesOfIncome includes Inheritance/Lottery/Pension/Other/etc. AND TotalDepositsLifetime > $50K; ''No Alert'' otherwise. Contributes to RoutineMonitoringRedFlagsEP. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Occupation COMMENT 'Customer''s declared occupation text (KYC questionnaire Q18). Free-text answer. (Tier 2 - SP_BI_AMLPeriodicReview via BI_DB_KYC_Panel Q18)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN OccupationAlert COMMENT '''Alert'' if Occupation contains None/Unemployed/Student AND TotalDepositsLifetime > $50K; ''No Alert'' otherwise. Contributes to RoutineMonitoringRedFlagsEP. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN AnnualIncome COMMENT 'Customer''s declared annual income (KYC Q10 bracket midpoint in USD). Converted from text range (e.g., ''$50K-100K'' -> 100000). NULL if no Q10 answer. (Tier 2 - SP_BI_AMLPeriodicReview via BI_DB_KYC_Panel Q10)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalCashAndLiquidAssets COMMENT 'Customer''s declared total cash and liquid assets (KYC Q11 bracket midpoint in USD). NULL if no Q11 answer. (Tier 2 - SP_BI_AMLPeriodicReview via BI_DB_KYC_Panel Q11)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN DeclaredAmountforIncomeAssets COMMENT 'AnnualIncome + TotalCashAndLiquidAssets - the total declared financial resources. Compared against TotalDepositsCurrentYear for DeclaredIncomeANDAssetsAlert. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN DeclaredIncomeANDAssetsAlert COMMENT '''Alert'' if TotalDepositsCurrentYear > DeclaredAmountforIncomeAssets; ''No Alert'' otherwise. Deposits exceed declared financial capacity. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN PlannedInvestmentAmount COMMENT 'Customer''s planned investment amount for the year (KYC Q14 bracket midpoint in USD). NULL if no Q14 answer. (Tier 2 - SP_BI_AMLPeriodicReview via BI_DB_KYC_Panel Q14)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN PlannedInvestmentAlert COMMENT '''Alert'' if TotalDepositsCurrentYear > PlannedInvestmentAmount AND TotalDepositsCurrentYear > $10K AND PlannedInvestmentAmount > 0; ''No Alert'' otherwise. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN LastScreeningStatusChange COMMENT 'Date of the most recent screening status change from External_ScreeningService_Screening_UserScreening. NULL if no recent change. (Tier 2 - SP_BI_AMLPeriodicReview via External_ScreeningService)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalAlerts COMMENT 'Sum of the six binary alert flags (MaterialChangePII + MaterialChangeLogins + MaterialChangeMIMO + RoutineMonitoringRedFlagsOutdatedData + RoutineMonitoringRedFlagsEP + RoutineMonitoringRedFlagsHRC). Range: 0 - 6. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN AlertsSummary COMMENT 'Human-readable concatenated summary of triggered alert categories. Starts with ''Total Alerts: N'' followed by bullet lines for each triggered flag. AML analyst-facing text. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN CheckAlertSummary COMMENT 'Detailed action-oriented review checklist - specific documents or actions required for each alert. E.g. ''Request new POI as part of full re-KYC'', ''Re-run EV required''. AML analyst action guide. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalCheckAlerts COMMENT 'Count of specific check items (more granular than TotalAlerts). Counts individual sub-checks: each expired document, each EV issue, each EP flag separately. Range: 0+. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN RiskAlertSummary COMMENT 'STRING_AGG of RAMT (Risk Alert Management Tool) alerts for this customer - AlertType, StatusReason, Status, AlertCount. Pipe-delimited. NULL if no RAMT alerts. Source: BI_DB_RiskAlertManagementTool. (Tier 2 - SP_BI_AMLPeriodicReview via BI_DB_RiskAlertManagementTool)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN LatestRiskAlertDateReview COMMENT 'Date of the most recent RAMT alert modification for this customer. (Tier 2 - SP_BI_AMLPeriodicReview via BI_DB_RiskAlertManagementTool)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN BIAMLAlerts COMMENT 'STRING_AGG of BI AML alerts for this customer from BI_DB_AML_BI_Alerts_New - AlertType and count. Pipe-delimited. NULL if no BI AML alerts. (Tier 2 - SP_BI_AMLPeriodicReview via BI_DB_AML_BI_Alerts_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN LatestBIAlertDate COMMENT 'Date of the most recent BI AML alert for this customer from BI_DB_AML_BI_Alerts_New. (Tier 2 - SP_BI_AMLPeriodicReview via BI_DB_AML_BI_Alerts_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN APU_Gaps_Summary COMMENT 'Completed: date';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp set to GETDATE() by SP_BI_AMLPeriodicReview. Does NOT reflect production event time. (Tier 5 - ETL metadata propagation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN MaterialChangePII COMMENT 'Binary flag (0/1): 1 if customer had a material change in PII (name, address, city, zip, email, or phone) within the 3-year lookback window. Source: DWH_dbo.Fact_SnapshotCustomer historical delta. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN MaterialChangeLogins COMMENT 'Binary flag (0/1): 1 if  >= 25% of login days used a non-KYC country IP (excl. EEA) with  >= 30 qualifying days, OR  >= 25% VPN/proxy logins with  >= 30 VPN days. Uses Fact_CustomerAction (ActionTypeID=14 Login). (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN MaterialChangeMIMO COMMENT 'Binary flag (0/1): 1 if any deposits (Fact_BillingDeposit) or withdrawals (Fact_BillingWithdraw) originated from a non-KYC, non-POB, non-citizenship country that is not in the EEA list. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN RoutineMonitoringRedFlagsOutdatedData COMMENT 'Binary flag (0/1): 1 if (expired/missing POI or POA AND EV not Verified) OR tax country != KYC country. Triggers ''Outdated or inconsistent client data'' alert. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN RoutineMonitoringRedFlagsEP COMMENT 'Binary flag (0/1): 1 if any economic profile violation - deposits > declared income/assets, unusual source of income, suspicious occupation + activity, or deposits > planned investment. (Tier 2 - SP_BI_AMLPeriodicReview)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN RoutineMonitoringRedFlagsHRC COMMENT 'Binary flag (0/1): 1 if customer had deposits, logins, or country changes involving a RiskGroupID IN (1,2) country (high-risk jurisdiction) within 3-year lookback. (Tier 2 - SP_BI_AMLPeriodicReview)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Review_Due_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Review_Due_DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN KYC_Country_ID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POBCountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN CitizenshipCountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN KYC_Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POBCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN CitizenshipCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN KYC_Country_Rank SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POBCountry_Rank SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN CitizenshipCountry_Rank SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN ScreeningStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN PhoneVerified SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN EvMatchStatusName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN AlertCategory SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN VerificationLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN PlayerStatusReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN PlayerStatusSubReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN RiskClassification SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POI_ExpiryDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POA_ExpiryDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Is_POI_Expired SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Is_POA_Expired SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POI_IsMissing SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN POA_IsMissing SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TaxCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN LastUpdatedDateTaxCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TaxCountryDiscrepancy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN EVStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN LastEVDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN EVReviewPending SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN KYC_LastUpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN EconomicProfileReviewPending SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalDepositsLifetime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalDepositsCurrentYear SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalDeposits12Months SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalDeposits6Months SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN LastEPUpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN SourcesOfIncome SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN SourceOfIncomeAlert SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN Occupation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN OccupationAlert SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN AnnualIncome SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalCashAndLiquidAssets SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN DeclaredAmountforIncomeAssets SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN DeclaredIncomeANDAssetsAlert SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN PlannedInvestmentAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN PlannedInvestmentAlert SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN LastScreeningStatusChange SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalAlerts SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN AlertsSummary SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN CheckAlertSummary SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN TotalCheckAlerts SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN RiskAlertSummary SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN LatestRiskAlertDateReview SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN BIAMLAlerts SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN LatestBIAlertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN APU_Gaps_Summary SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN MaterialChangePII SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN MaterialChangeLogins SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN MaterialChangeMIMO SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN RoutineMonitoringRedFlagsOutdatedData SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN RoutineMonitoringRedFlagsEP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN RoutineMonitoringRedFlagsHRC SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:24:57 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 142/142 succeeded
-- ====================
