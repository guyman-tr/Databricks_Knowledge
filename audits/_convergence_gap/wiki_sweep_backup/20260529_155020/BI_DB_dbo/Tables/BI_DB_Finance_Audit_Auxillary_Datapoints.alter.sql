-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Finance_Audit_Auxillary_Datapoints
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Finance_Audit_Auxillary_Datapoints > Monthly finance audit table in tall/unpivot format: 12.9M rows (Jan 2023 - Mar 2026), 22 metric types × customer dimension combinations aggregated by YearMonth/Regulation/PlayerLevel/PlayerStatus/MifidCategory/Country/InstrumentType/IsCreditReportValidCB/IsSettled; consolidates 8 ETL inputs (commissions, overnight fees, dividends, conversion fees, cashout/dormant/interest fees, ticket fees, stock margin) via SP_M_Finance_Audit_Auxillary_Datapoints. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | BI_DB_DepositWithdrawFee, DWH_dbo.Fact_CustomerAction, BI_DB_Client_Balance_Breakdown_Instrument_Level, BI_DB_DDR_Daily_Aggregated, BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics, Function_Revenue_TicketFee, Function_Revenue_TicketFeeByPercent, BI_DB_Fact_Customer_Action_P'
);

-- ---- Table Tags ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN YearMonth COMMENT 'Reporting period in YYYYMM string format. Computed as `convert(VARCHAR(6), @date, 112)` in SP_M_Finance_Audit_Auxillary_Datapoints. Used as the DELETE key - all rows for this YearMonth are deleted before re-insertion. (Tier 2 - SP_M_Finance_Audit_Auxillary_Datapoints)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN InstrumentType COMMENT 'Instrument type name from DWH_dbo.Dim_Instrument (e.g., ''Stocks'', ''CFDs'', ''Crypto Currencies''). Set to ''NA'' for metrics that have no instrument breakdown: TotalDormantFee, TotalCashoutFee, TotalInterestFees, TotalConversionFees, TransferCoinFee, DividendPaid, SDRT. (Tier 2 - SP_M_Finance_Audit_Auxillary_Datapoints)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN Regulation COMMENT 'Regulatory jurisdiction name from DWH_dbo.Dim_Regulation (e.g., ''FCA'', ''CySEC'', ''ASIC''). Passed through as a GROUP BY dimension - this table covers all regulations unlike BI_DB_FCA_Liabilities. (Tier 2 - SP_M_Finance_Audit_Auxillary_Datapoints)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN PlayerLevel COMMENT 'Customer club/tier name from DWH_dbo.Dim_PlayerLevel (e.g., ''Diamond'', ''Platinum''). Maps to Club column in source temp tables. GROUP BY dimension. (Tier 2 - SP_M_Finance_Audit_Auxillary_Datapoints)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN PlayerStatus COMMENT 'Customer status name from DWH_dbo.Dim_PlayerStatus (e.g., ''Real'', ''Demo''). GROUP BY dimension for all 22 metric types. (Tier 2 - SP_M_Finance_Audit_Auxillary_Datapoints)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN IsCreditReportValidCB COMMENT '1 if customer is eligible for CreditBureau credit report validation. ETL-computed. (Tier 1 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN MifidCategory COMMENT 'MiFID II categorization name from DWH_dbo.Dim_MifidCategorization (e.g., ''Retail'', ''Professional'', ''Eligible Counterparty''). GROUP BY dimension. (Tier 2 - SP_M_Finance_Audit_Auxillary_Datapoints)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN Country COMMENT 'Customer country name from DWH_dbo.Dim_Country. GROUP BY dimension for all 22 metric types. (Tier 2 - SP_M_Finance_Audit_Auxillary_Datapoints)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN Metric COMMENT 'Hardcoded metric name identifying the UNION ALL branch (one of 22 values). See Metric Catalogue in Section 5. Never NULL - always explicitly set in each SP branch. (Tier 2 - SP_M_Finance_Audit_Auxillary_Datapoints)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN Amount COMMENT 'Numeric metric value for this dimension combination. ISNULL(SUM(source), 0) - never NULL. Negative for TicketFee and TicketFeeByPercent (sign-flipped in SP). All other metrics are positive or zero. (Tier 2 - SP_M_Finance_Audit_Auxillary_Datapoints)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN UpdateDate COMMENT 'ETL metadata: GETDATE() timestamp at INSERT time. Records when this row was last refreshed by the SP. Not the business date. (Tier 2 - SP_M_Finance_Audit_Auxillary_Datapoints)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN IsRealFutures COMMENT '1 if instrument is a real futures contract (IsFuture=1 in Dim_Instrument), 0 otherwise. NULL (not 0) for metrics with no instrument breakdown: TotalDormantFee, TotalCashoutFee, TotalInterestFees, TotalConversionFees, TransferCoinFee, DividendPaid, SDRT. Distinguish NULL (not applicable) from 0 (non-futures instrument). (Tier 2 - SP_M_Finance_Audit_Auxillary_Datapoints)';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN IsSettled COMMENT 'Position settlement flag for commission and overnight-fee metrics: 1 = settled/real position (stocks), 0 = open/CFD position. For non-instrument fee metrics (TotalConversionFees, TotalCashoutFee, TotalDormantFee, TotalInterestFees, TransferCoinFee, DividendPaid, SDRT), SP inserts `''''` which converts to 0 - not meaningful for these rows. Use `Metric` to distinguish commission/overnight rows (where IsSettled is interpretable) from fee rows. (Tier 2 - SP_M_Finance_Audit_Auxillary_Datapoints)';

-- ---- Column PII Tags ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN YearMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN PlayerLevel SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN MifidCategory SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN Metric SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN IsRealFutures SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:50:22 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 28/28 succeeded
-- ====================
