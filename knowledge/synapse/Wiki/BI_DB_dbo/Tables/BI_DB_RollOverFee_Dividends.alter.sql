-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_RollOverFee_Dividends
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_RollOverFee_Dividends'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN DateID COMMENT 'Business date as `YYYYMMDD` integer for actions/dividends loaded. (Tier 2 -- SP_RollOverFee_Dividends, Fact_CustomerAction.DateID / BI_DB_DailyDividendsByPosition.DateID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN PaymentDate COMMENT 'Dividend payment date from index dividends; null for roll-over fee rows. (Tier 2 -- SP_RollOverFee_Dividends, etoro_Trade_IndexDividends.PaymentDate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN InstrumentID COMMENT 'Instrument key. (Tier 2 -- SP_RollOverFee_Dividends, Dim_Position.InstrumentID / BI_DB_DailyDividendsByPosition.InstrumentID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN InstrumentName COMMENT 'Instrument display name. (Tier 2 -- SP_RollOverFee_Dividends, Dim_Instrument.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN IsSettled COMMENT 'Settlement bucket: **Real** when `Dim_Position.IsSettled=1` (with optional `Dim_PositionChangeLog` override), else **CFD**. (Tier 2 -- SP_RollOverFee_Dividends, CASE on Dim_Position.IsSettled / log)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN PaymentType COMMENT '**RollOverFee** or **Dividend** to distinguish the two UNION branches. (Tier 2 -- SP_RollOverFee_Dividends, literal in #FCA)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN EventType COMMENT '**RollOverFee** for fee branch; dividend branch uses classified `etoro_Trade_IndexDividends.EventType`. (Tier 2 -- SP_RollOverFee_Dividends, CASE on etoro_Trade_IndexDividends.EventType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN Amount COMMENT 'Sum of **negated** position-level amounts (`SUM(-Amount)`) from FCA or daily dividends. (Tier 2 -- SP_RollOverFee_Dividends, Fact_CustomerAction.Amount / BI_DB_DailyDividendsByPosition.Amount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN DividendValueInCurrency COMMENT 'Per-share dividend value in currency for dividend rows; null for roll-over. (Tier 2 -- SP_RollOverFee_Dividends, etoro_Trade_IndexDividends.DividendValueInCurrency)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN UpdateDate COMMENT 'Row load timestamp. (Tier 3 -- SP_RollOverFee_Dividends, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN InstrumentType COMMENT 'Asset class from dimension. (Tier 2 -- SP_RollOverFee_Dividends, Dim_Instrument.InstrumentType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN HedgeServerID COMMENT 'Hedge server on the action date: `ISNULL(Dim_PositionHedgeServerChangeLog_Snapshot.HedgeServerID, Dim_Position.HedgeServerID)`. (Tier 2 -- SP_RollOverFee_Dividends, snapshot / Dim_Position.HedgeServerID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN DividendID COMMENT 'Corporate action dividend id for dividend rows; null for roll-over. (Tier 2 -- SP_RollOverFee_Dividends, BI_DB_DailyDividendsByPosition.DividendID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN CountCIDs COMMENT '**Average** of pre-grouped distinct `RealCID` counts for the instrument/settlement or dividend/settlement slice (not a simple COUNT on the final grain). (Tier 2 -- SP_RollOverFee_Dividends, AVG from #DistinctCIDs_RollOver / #DistinctCIDs_Div)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN Date COMMENT 'Calendar date parameter `@Date` stored for readability. (Tier 2 -- SP_RollOverFee_Dividends, @Date)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN AmountOfUnits COMMENT 'Sum of eligible or roll-over units (`AmountInUnitsDecimal`) from `BI_DB_PositionPnL` / `Dim_Position` logic. (Tier 2 -- SP_RollOverFee_Dividends, #ROF_Units / #Div_EligibleUnits)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN ExDate COMMENT 'Dividend ex-date; null for roll-over. (Tier 2 -- SP_RollOverFee_Dividends, etoro_Trade_IndexDividends.ExDate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN IsValidCustomer COMMENT 'Customer validity flag from `Dim_Customer` / daily dividends feed. (Tier 2 -- SP_RollOverFee_Dividends, Dim_Customer.IsValidCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN PlayerLevel COMMENT '**BVI** for hard-coded CIDs, **Internal** when `PlayerLevelID=4`, else **Other**. (Tier 2 -- SP_RollOverFee_Dividends, CASE on Dim_Customer / daily dividends)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN PlayerStatus COMMENT '**Deposit Blocked** when `PlayerStatusID=10`, else **Other**. (Tier 2 -- SP_RollOverFee_Dividends, CASE on Dim_Customer / daily dividends)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN IsComputeForHedge COMMENT 'Whether position is included in hedge computation (`Dim_Position.IsComputeForHedge`). (Tier 2 -- SP_RollOverFee_Dividends, Dim_Position.IsComputeForHedge)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN PaymentDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN PaymentType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN EventType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN DividendValueInCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN DividendID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN CountCIDs SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN AmountOfUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN ExDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN PlayerLevel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN IsComputeForHedge SET TAGS ('pii' = 'none');
