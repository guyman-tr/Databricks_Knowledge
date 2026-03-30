-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status > 12.7B-row DDR customer periodic pre-aggregation - rolls up the daily customer status into ThisWeek, ThisMonth, ThisQuarter, and ThisYear snapshots for each customer, eliminating expensive on-the-fly aggregations from the DDR dashboard layer. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table (Dimension - DDR periodic customer status) | | **Production Source** | Pre-aggregation of `BI_DB_DDR_Customer_Daily_Status` via `SP_DDR_Customer_Periodic_Status` | | **Refresh** | Daily - `DELETE WHERE DateID = @dateID` + `INSERT` per business date | | | | | **Synapse Distribution** | HASH(RealCID) | | **Synapse Index** | CLUSTERED COLUMNSTORE INDEX | | | | | **UC Target** | _Pending - resolved during write-objects_ | | **UC Format** | _Pending - resolved during write-objects_ | | **UC Partitioned By** | _Pendi'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN RealCID COMMENT 'Real customer ID. HASH distribution key. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN Date COMMENT 'Calendar date - equals parameter `@date`. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN DateID COMMENT 'Business date as YYYYMMDD integer. Delete/replace key. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN FirstActionType_ThisWeek COMMENT 'First trading action type on latest day of the week (rn=1). From Daily_Status.FirstActionType. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN RegulationID_ThisWeek COMMENT 'Regulation ID on latest day of the week (rn=1). From Daily_Status.RegulationID. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN IsCreditReportValidCB_ThisWeek COMMENT 'Credit report valid on latest day of the week. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN IsValidCustomer_ThisWeek COMMENT 'Valid customer on latest day of the week. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN MifidCategorizationID_ThisWeek COMMENT 'MiFID categorization on latest day. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN PlayerLevelID_ThisWeek COMMENT 'Player level on latest day. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN CountryID_ThisWeek COMMENT 'Country ID on latest day. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN MarketingRegion_ThisWeek COMMENT 'Marketing region on latest day. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN IsFunded_ThisWeek COMMENT 'Funded on last day of week (rn=1). Changed Nov 2025 from any-day to last-day. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN FirstTimeFunded_ThisWeek COMMENT 'Count of days first-time-funded occurred this week. SUM across period. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN ActiveTraded_ThisWeek COMMENT 'Count of days actively traded this week. SUM across period. >0 means "active this week." (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN Portfolio_Only_ThisWeek COMMENT 'Portfolio-only days this week (excl ActiveTraded days). COUNT with conditional hierarchy. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN BalanceOnlyAccount_ThisWeek COMMENT 'Balance-only days this week (excl ActiveTraded and Portfolio_Only). COUNT with conditional hierarchy. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN TPFirstDeposited_ThisWeek COMMENT 'TP first deposit occurred this week. SUM(flag). (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN IBANFirstDeposited_ThisWeek COMMENT 'IBAN first deposit occurred this week. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN TPExternalFirstDeposited_ThisWeek COMMENT 'TP external first deposit this week (excl internal). (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN GlobalFirstDeposited_ThisWeek COMMENT 'Global first deposit (any platform) this week. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN GlobalDeposited_ThisWeek COMMENT 'Deposited on any platform this week (excl internal). (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN GlobalRedeposited_ThisWeek COMMENT 'Redeposited (not FTD, not internal) this week. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN GlobalCashedOut_ThisWeek COMMENT 'Withdrew on any platform this week. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN Redeemed_ThisWeek COMMENT 'Billing redeem this week. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN DepositedTP_ThisWeek COMMENT 'Deposited on TP this week. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN DepositedIBAN_ThisWeek COMMENT 'Deposited on IBAN this week. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN ReDepositedTP_ThisWeek COMMENT 'Redeposited on TP this week. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN ReDepositedIBAN_ThisWeek COMMENT 'Redeposited on IBAN this week. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - GETDATE(). (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN WeekStart COMMENT 'Week start date (Sunday). Computed from @date. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN MonthStart COMMENT 'Month start date (1st). (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN QuarterStart COMMENT 'Quarter start date (1st). (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN YearStart COMMENT 'Year start date (Jan 1). (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN WeekStartDateID COMMENT 'Week start as YYYYMMDD. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN MonthStartDateID COMMENT 'Month start as YYYYMMDD. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN QuarterStartDateID COMMENT 'Quarter start as YYYYMMDD. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN YearStartDateID COMMENT 'Year start as YYYYMMDD. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN OptionsFirstDeposited_ThisWeek COMMENT 'Options first deposit this week. Added Oct 2025. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN DepositedOptions_ThisWeek COMMENT 'Deposited on Options this week. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN ReDepositedOptions_ThisWeek COMMENT 'Redeposited on Options this week. (Tier 2 - SP_DDR_Customer_Periodic_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN MoneyFarmFirstDeposited_ThisWeek COMMENT 'MoneyFarm first deposit this week. Added Nov 2025. (Tier 2 - SP_DDR_Customer_Periodic_Status)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN FirstActionType_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN RegulationID_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN IsCreditReportValidCB_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN IsValidCustomer_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN MifidCategorizationID_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN PlayerLevelID_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN CountryID_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN MarketingRegion_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN IsFunded_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN FirstTimeFunded_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN ActiveTraded_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN Portfolio_Only_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN BalanceOnlyAccount_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN TPFirstDeposited_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN IBANFirstDeposited_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN TPExternalFirstDeposited_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN GlobalFirstDeposited_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN GlobalDeposited_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN GlobalRedeposited_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN GlobalCashedOut_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN Redeemed_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN DepositedTP_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN DepositedIBAN_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN ReDepositedTP_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN ReDepositedIBAN_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN WeekStart SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN MonthStart SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN QuarterStart SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN YearStart SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN WeekStartDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN MonthStartDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN QuarterStartDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN YearStartDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN OptionsFirstDeposited_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN DepositedOptions_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN ReDepositedOptions_ThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN MoneyFarmFirstDeposited_ThisWeek SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 16:02:52 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 1
-- Statements: 84/84 succeeded
-- ====================
