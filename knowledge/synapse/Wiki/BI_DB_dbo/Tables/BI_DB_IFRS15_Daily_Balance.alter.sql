-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_IFRS15_Daily_Balance
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_IFRS15_Daily_Balance | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Distribution** | ROUND_ROBIN | | **Index** | CLUSTERED INDEX (Date ASC) | | **Writer SP** | BI_DB_dbo.SP_IFRS_15_Balance | | **ETL Pattern** | DELETE WHERE Date + ExcelOrder scope + INSERT (within WHILE loop for 2 days) | | **OpsDB Priority** | 20 | | **Frequency** | Daily | | **Row Estimate** | ~600 - 800 rows/day (20+ metric rows × N instruments × dimension combinations) | | **UC Target** | Not Migrated |'
);

-- ---- Table Tags ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----

ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN ExcelOrder COMMENT 'Display ordering key mapping rows to specific positions in the IFRS 15 reconciliation spreadsheet. Values 1 - 29 (loop body) + 32, 33 (DLT section, outside loop). ExcelOrder 15 is intentionally absent (metric removed; gap preserved for Tableau compatibility).';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Metric COMMENT 'Named IFRS 15 metric category. See Metric Taxonomy table below for all values and their IFRS meaning. Determines which financial flow or balance component this row represents.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN PositionType COMMENT 'Metric subcategory describing the position''s settlement status at open and/or close. For balance rows: ''NA''. For flow rows: e.g., ''OpenReal'', ''OpenRealLatestCFD'', ''ClosedReal'', ''ConvertedCFDToReal''.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Date COMMENT 'Report date - the date this metric row represents. Within the WHILE loop, this is @startDate (which ranges from @date-1 to @date). For DLT rows (ExcelOrder 32,33): @DLTEndDate = @date.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN YearMonth COMMENT 'YYYYMM format period identifier derived from Date. Used for monthly aggregation in Tableau/Excel reporting.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Name COMMENT 'Crypto instrument name - specifically the BuyCurrency name from Dim_Instrument (e.g., ''BTC'', ''ETH'', ''XRP'', ''SOL''). Identifies which crypto asset this row refers to.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN PositionTiming COMMENT 'Position lifecycle timing relative to the report period. For flow metrics: ''Opened_In_Period_Not_Closed'' (opened today, still open), ''Opened_And_Closed_In_Period'' (day trade), ''Opened_Before_Period_Closed_InPeriod'' (previous open, closed today). ''NA'' for balance and conversion metrics.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN TotalUnits COMMENT 'Total position size in crypto units (number of tokens). For long positions: positive; for short positions: negative (multiplied by -1 in CASE). For commission and fee metrics: 0. Sourced from AmountInUnitsDecimal (closing balance) or InitialUnits (opening/flow).';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN USDValue COMMENT 'Total USD value for this metric row. Semantic depends on Metric: (a) Balance rows: SUM(TotalNOP) = net open position at market price; (b) Flow rows: SUM(ComputedVolumeOpen) or SUM(ComputedVolumeClose) = notional traded volume; (c) Commission rows: SUM(-FullCommission) = negative of commission charged; (d) Zero metrics: SUM(TotalZero) = uncommitted balance; (e) DLT rows: SUM(Amount + PositionPnL) = custodied crypto value.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last inserted by the ETL pipeline (GETDATE() at INSERT time).';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsValidCustomer COMMENT 'Customer validity flag at report date. From Fact_SnapshotCustomer: 1 = valid customer; 0 = invalid. Used to separate valid vs. invalid customer book in IFRS reconciliation.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsCreditReportValidCB COMMENT 'Client_Balance validity flag at report date. From Fact_SnapshotCustomer: 1 = customer has valid Client_Balance check; 0 = invalid. Separates credit-valid from credit-invalid sub-books in IFRS reports.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsOutlier COMMENT 'Statistical outlier flag. From BI_DB_Outliers_New: 1 = customer is a position-size outlier (large unusual position that could distort aggregate metrics); 0 = normal customer. NULL for DLT balance rows (ExcelOrder 32, 33).';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN OutlierTransition COMMENT 'Outlier transition description from BI_DB_Outliers_New.Transition. ''NoTransition'' = customer is not an outlier or has no transition. Specific transition names describe what kind of outlier event occurred. NULL for DLT balance rows.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN TanganyStatus COMMENT 'Crypto custody status from BI_DB_Client_Balance_CID_Level_New. Tangany is eToro''s crypto custody provider. MAX(TanganyStatus) per CID at the report date. Distinguishes how the customer''s real crypto is held (e.g., ''Internal'' = eToro internal custody, ''Customer'' = Tangany customer custody).';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsDLTUser COMMENT 'Distributed Ledger Technology user flag from BI_DB_Client_Balance_CID_Level_New. MAX(IsDLTUser) per CID at report date. 1 = customer holds real crypto in DLT/blockchain custody (Fact_SnapshotCustomer.DltStatusID=4); 0 = standard crypto position. DLT users appear or disappear from balance aggregations when their DLT status changes - the ExcelOrder 32/33 rows compensate for these gaps.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN TicketFeeVolume COMMENT 'Volume-weighted ticket fee percentage commission. Computed by Function_Revenue_TicketFeeByPercent(@startDateInt, @endDateInt, 0). SUM of TicketFeeByPercent per position grouped into each IFRS metric row. 0.0 for balance rows, zero metrics, and commission rows. Non-zero for BuyReal, SellReal, BuyCFD, SellCFD, Redeem, and Staking flow rows.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsC2P COMMENT 'Copy-to-Portfolio flag: 1 = position was opened as a copy/mirror trade (identified via CompensationReasonID=134 in External_Bronze_etoro_Trade_AdminPositionLog); 0 = direct trade. "C2P" = Copy to Portfolio.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsTransferOut COMMENT 'Transfer-out flag: 1 = position was closed due to an account transfer out (ClosePositionReasonID=22 in Dim_Position); 0 = normal position close. NULL for DLT balance rows (ExcelOrder 32,33) and for Zero metrics where NULL is passed explicitly.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Regulation COMMENT 'Customer regulation name at the time of the action. Joined from Dim_Regulation via Fact_SnapshotCustomer.RegulationID at the SCD-valid date range. Represents the regulatory jurisdiction of the customer''s positions (e.g., ''ASIC'', ''CySEC'', ''FCA'').';

-- ---- Column PII Tags ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN ExcelOrder SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Metric SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN PositionType SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN YearMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN PositionTiming SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN TotalUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN USDValue SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsOutlier SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN OutlierTransition SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN TanganyStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsDLTUser SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN TicketFeeVolume SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsC2P SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsTransferOut SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Regulation SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:32:26 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 10
-- Statements: 42/42 succeeded
-- ====================
