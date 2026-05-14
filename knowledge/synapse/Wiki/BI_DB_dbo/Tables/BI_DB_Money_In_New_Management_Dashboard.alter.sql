-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Money_In_New_Management_Dashboard
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Money_In_New_Management_Dashboard > 6.23M-row deposit transaction table for the management dashboard, containing every deposit attempt (Approved, Declined, or Excluded) with customer geography, regulation, payment method, first-attempt indicators, eMoney eligibility, conversion fee revenue, and club tier - sourced from Fact_BillingDeposit enriched with 9 dimension tables. Rolling 7-month window. Refreshed daily via SP_Money_In_New_Management_Dashboard (Artyom Bogomolsky, 2022-03-27). SB_Daily, Priority 0. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | DWH_dbo.Fact_BillingDeposit + 9 dimension tables via SP_Money_In_New_Management_Dashboard | | **Refresh** | Daily DELETE+INSERT by DepositID+CID, plus DELETE older than 7 months. SB_Daily, Priority 0 | | **Synapse Distribution** | ROUND_ROBIN | | **S'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositID COMMENT 'Unique deposit transaction identifier from Fact_BillingDeposit. One row per deposit. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN AmountUSD COMMENT 'Deposit amount in USD. From Fact_BillingDeposit.AmountUSD. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN Country COMMENT 'Customer''s country name at the time of deposit. From Dim_Country.Name via Fact_SnapshotCustomer.CountryID. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN Region COMMENT 'Marketing region name. From Dim_Country.MarketingRegionManualName. E.g., UK, German, French, Italian, CEE, Latam, Spain. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN Regulation COMMENT 'Regulatory jurisdiction. From Dim_Regulation.Name via Dim_Country.RegulationID. E.g., FCA, CySEC, FSA Seychelles. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN CID COMMENT 'Customer ID. From Fact_BillingDeposit.CID. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN PaymentDate COMMENT 'Payment date and time of the deposit. For WireTransfer, may be replaced with ProcessorValueDate if later. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositDate COMMENT 'Date-only portion of PaymentDate. CAST(PaymentDate AS Date). (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN ModificationDate COMMENT 'Last modification date of the deposit record. From Fact_BillingDeposit. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN PaymentStatusID COMMENT 'Payment status code from Fact_BillingDeposit. 2=Approved, 1/5/11/12=Refund, 6/13=conditional exclude based on FundingTypeID. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN IsFTD COMMENT 'First-time deposit flag. 1=this is the customer''s first-ever approved deposit. From Fact_BillingDeposit.IsFTD. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositStatus COMMENT 'Derived deposit status classification. Approved, Declined, or Exclude. See Business Logic 2.1 for CASE rules. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositMethod COMMENT 'Payment method name. From Dim_FundingType.Name. Top values: eToroMoney, CreditCard, PayPal, WireTransfer, GCCInstantBankTransfer, iDEAL, PWMB. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN PaymentStatus COMMENT 'Payment status label. From Dim_PaymentStatus.Name. E.g., Approved, InProcess, Declined. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositFundingType COMMENT 'Funding type classification. Manual (FundingTypeID=2, wire transfers), Error (FundingTypeID=0), Automatic (all others). 2 values in practice: Automatic, Manual. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN FirstAttempt_Ind COMMENT '1 if this deposit is the customer''s very first deposit attempt (MIN PaymentDate per CID in last 2 days), 0 otherwise. Lifetime per-CID, not per-window. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN FA_Approve_Rate COMMENT '1 if first attempt AND first approval (PaymentStatusID=2) occurred within 24 hours. 0 otherwise. Measures first-attempt-to-approval speed. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN ProcessorValueDate COMMENT 'Date the payment processor recorded the value. From Fact_BillingDeposit.ProcessorValueDate. For WireTransfer, used as PaymentDate if later than original PaymentDate. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN Currency COMMENT 'Deposit currency abbreviation. From Dim_Currency.Abbreviation. E.g., USD, EUR, GBP, MXN. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN CountryID COMMENT 'Country identifier from Fact_SnapshotCustomer.CountryID. FK to Dim_Country. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN Club COMMENT 'eToro Club tier at the time of deposit. From Dim_PlayerLevel.Name via Fact_SnapshotCustomer.PlayerLevelID. E.g., Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositDateID COMMENT 'Date key (YYYYMMDD int) for DepositDate. Computed from PaymentDate. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN ModificationDateID COMMENT 'Date key (YYYYMMDD int) for ModificationDate. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN ConversionFeeRevenue COMMENT 'FX conversion fee revenue. (BaseExchangeRate - ExchangeRate) * Amount. Positive when eToro earns a spread on the FX conversion. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN eMoneyEligible COMMENT '1 if customer meets all eMoney eligibility criteria at deposit time (>14d since FTD, verified L3, active status, country in eMoney rollout). 0 otherwise. (Tier 2 - SP_Money_In_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositProvider COMMENT 'Deposit processing provider name. From Dim_BillingDepot.Name. E.g., Tribe, IXOPAY-Nuvei, WorldPay, Wire(DeutscheBank). (Tier 2 - SP_Money_In_New_Management_Dashboard)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN PaymentDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN ModificationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN PaymentStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN IsFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositMethod SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN PaymentStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositFundingType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN FirstAttempt_Ind SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN FA_Approve_Rate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN ProcessorValueDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN ModificationDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN ConversionFeeRevenue SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN eMoneyEligible SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN DepositProvider SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:04:52 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 56/56 succeeded
-- ====================
