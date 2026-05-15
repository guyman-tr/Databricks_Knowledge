-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Outliers_New
-- Generated: 2026-05-14 | speckit stub + regen_alter_from_wiki.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Outliers_New > daily credit-report validity outlier fact (IsCreditReportValidCB day-over-day change) with cumulative lifetime money components and sign flip for newly invalid customers. Writer SP_Outliers_New (FinanceReportSPS P99). See wiki knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_Outliers_New.md.'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'speckit-2026-05-14'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN RealCID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Regulation COMMENT 'Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN CreditReportValid COMMENT 'Post-transition `IsCreditReportValidCB`, stored as `''0''`/`''1''`. Determines sign flip envelope. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Transition COMMENT 'Directional narration: `''Invalid to Valid''` or `''Valid To Invalid''`; CASE fallback `''NA''` is unreachable once DLT path removed (verified zero rows MCP 2026-05-14). (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Deposit_Amounts COMMENT 'Lifetime gross deposits (`ActionTypeID = 7`, `DateID <= @ld_t2`) multiplied by  - 1 when `CreditReportValid=''0''`. NULL absent deposit history. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation_Deposit COMMENT 'Lifetime compensation bucket `ActionTypeID=36 ∧ CompensationReasonID=7`; sign flipped for invalid cohort. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN GivenBonus COMMENT 'Lifetime `ActionTypeID=9`; sign flipped for invalid cohort. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation COMMENT 'Residual ReasonID != {7,8,11,17,18,22,30,31,32,33,34,36,37,38,40,41,51,52} subset of compensation actions; mirrored logic from SP temp `#Compensation`. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation_PI COMMENT '`ActionTypeID=36 ∧ CompensationReasonID=41`. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation_To_Affiliates COMMENT '`ActionTypeID=36 ∧ CompensationReasonID IN (8,51,52)`. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Cashout_Amounts COMMENT 'Lifetime `ActionTypeID=8`; flipped for invalid rows. NULL when untouched. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation_Cashouts COMMENT '`CompensationReasonID=33`. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Cashout_Fee COMMENT '`ActionTypeID=30` commission rollups (SP pre-multiplies  - 1 internally, then participates in invalid-row outer negation exactly once). (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Chargeback COMMENT '`ActionTypeID IN (11,13)`. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Refund COMMENT '`ActionTypeID=12`. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN ClientBalanceCommission COMMENT 'Closed-trade commission leakage (`ActionTypeID IN (4,5,6,28,40)` on `CommissionOnClose` ×  - 1 before outer flip). (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Over_The_Weekend_Fee COMMENT 'Overnight fee (`ActionTypeID=35`). (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Chargeback_Loss COMMENT 'From `V_Liabilities`: negative balances with exotic `PlayerStatusID` exclusions {1,3,5,7}. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Other_Negative COMMENT 'Complimentary slice of liabilities rows with standard statuses in {1,3,5,7}. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation_PnL_Adjustment COMMENT '`CompensationReasonID=22`. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation_DormantFee COMMENT '`CompensationReasonID=30`. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN ClientBalance_Realized_PnL COMMENT '`NetProfit` for close events (`ActionTypeID IN (4,5,6,28,40)`). (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Unrealized_Commission_Change COMMENT 'Planned home for unrealized commission delta (CommissionOnOpen) but INSERT now hard-nulls column; surviving non-null tails correspond to archived CommissionOnOpen runs (42 rows MCP 2026-05-14). (Tier 2 - BI_DB_dbo.SP_Outliers_New + live Synapse distribution)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Cycle_Calculation COMMENT 'Net of the nineteen enumerated component columns respecting NULL arithmetic; inherits sign flip envelope. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Foreclosure COMMENT '`CompensationReasonID=32`. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Lost_Debt COMMENT '`CompensationReasonID=31`. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Date COMMENT 'Business detection date `@ld`. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN DateID COMMENT '`YYYYMMDD(@ld)`. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Negative_Refill_Compensation COMMENT '`CompensationReasonID=11`; physically last money column (`ORDINAL_POSITION=29`). (Tier 2 - BI_DB_dbo.SP_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN UpdateDate COMMENT 'Stringified warehouse load audit (`GETDATE()` at SP runtime). Not SQL `datetime`. (Tier 2 - BI_DB_dbo.SP_Outliers_New)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN _placeholder_ SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN CreditReportValid SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Transition SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN GivenBonus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Chargeback SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Refund SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN ClientBalanceCommission SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Foreclosure SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Deposit_Amounts SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation_Deposit SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation_PI SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation_To_Affiliates SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Cashout_Amounts SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation_Cashouts SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Cashout_Fee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Over_The_Weekend_Fee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Chargeback_Loss SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Other_Negative SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation_PnL_Adjustment SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Compensation_DormantFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN ClientBalance_Realized_PnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Unrealized_Commission_Change SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Cycle_Calculation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Lost_Debt SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new ALTER COLUMN Negative_Refill_Compensation SET TAGS ('pii' = 'none');

