-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DailyDividendsByPosition
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DailyDividendsByPosition'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN DateID COMMENT 'YYYYMMDD key for the dividend action day. (Tier 2 -- SP_DailyDividendsByPosition, Fact_CustomerAction.DateID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN Date COMMENT 'Calendar date from `CAST(fca.Occurred AS DATE)`. (Tier 2 -- SP_DailyDividendsByPosition, Fact_CustomerAction.Occurred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN HedgeServerID COMMENT 'Effective hedge server: snapshot override when active for `@DateID`, else `Dim_Position.HedgeServerID`. (Tier 2 -- SP_DailyDividendsByPosition, Dim_PositionHedgeServerChangeLog_Snapshot.HedgeServerID / Dim_Position.HedgeServerID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN PositionID COMMENT 'Position identifier. (Tier 2 -- SP_DailyDividendsByPosition, Dim_Position.PositionID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN RealCID COMMENT 'Customer identifier on the action. (Tier 2 -- SP_DailyDividendsByPosition, Fact_CustomerAction.RealCID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN IsBuy COMMENT 'Position side flag from `Dim_Position`. (Tier 2 -- SP_DailyDividendsByPosition, Dim_Position.IsBuy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN InstrumentID COMMENT 'Instrument on the position. (Tier 2 -- SP_DailyDividendsByPosition, Dim_Position.InstrumentID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN Amount COMMENT 'Dividend amount credited (customer action amount). (Tier 2 -- SP_DailyDividendsByPosition, Fact_CustomerAction.Amount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN IsValidCustomer COMMENT 'From snapshot for report date. (Tier 2 -- SP_DailyDividendsByPosition, Fact_SnapshotCustomer.IsValidCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN IsCreditReportValidCB COMMENT 'Credit-report validity for CB reporting. (Tier 2 -- SP_DailyDividendsByPosition, Fact_SnapshotCustomer.IsCreditReportValidCB)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN IsSettled COMMENT '1 = real asset, 0 = CFD asset. (Tier 5 - Expert Review)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN Regulation COMMENT 'Regulation name. (Tier 2 -- SP_DailyDividendsByPosition, Dim_Regulation.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN DividendID COMMENT 'Corporate action / index dividend id on the action. (Tier 2 -- SP_DailyDividendsByPosition, Fact_CustomerAction.DividendID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN Status COMMENT 'Index dividend processing status from `#IndexDiv` when matched (`etoro_Trade_IndexDividends.Status`); NULL when no index-dividend join. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_IndexDividends.Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN EventType COMMENT 'Raw event type string from index dividends when matched; NULL otherwise. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_IndexDividends.EventType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN TaxCode COMMENT 'Tax code from index dividends when matched. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_IndexDividends.TaxCode)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN BuyTax COMMENT 'Buy-side tax from processed row or dividend default `ISNULL(p.BuyTax, d.BuyTax)`. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_PositionsProcessedForIndexDividnds.BuyTax / etoro_Trade_IndexDividends.BuyTax)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN SellTax COMMENT 'Sell-side tax, same coalesce pattern. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_PositionsProcessedForIndexDividnds.SellTax / etoro_Trade_IndexDividends.SellTax)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN PositionType COMMENT 'Dividend position type from index dividends when matched. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_IndexDividends.PositionType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN DividendValueInCurrency COMMENT 'Dividend value in dividend currency from index master. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_IndexDividends.DividendValueInCurrency)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN DividendCurrencyID COMMENT 'Currency id for dividend denomination. (Tier 2 -- SP_DailyDividendsByPosition, etoro_Trade_IndexDividends.DividendCurrencyID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN Currency COMMENT 'Display currency code: `Dim_Instrument.SellCurrency` for type 5/6 instruments matching `DividendCurrencyID`. (Tier 2 -- SP_DailyDividendsByPosition, Dim_Instrument.SellCurrency)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN UpdateDate COMMENT 'Batch timestamp `GETDATE()` in `#Final`. (Tier 3 -- SP_DailyDividendsByPosition, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN PlayerLevelID COMMENT 'Snapshot player level. (Tier 2 -- SP_DailyDividendsByPosition, Fact_SnapshotCustomer.PlayerLevelID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN PlayerStatusID COMMENT 'Snapshot player status. (Tier 2 -- SP_DailyDividendsByPosition, Fact_SnapshotCustomer.PlayerStatusID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN IsComputeForHedge COMMENT 'Hedge computation flag from position. (Tier 2 -- SP_DailyDividendsByPosition, Dim_Position.IsComputeForHedge)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN DividendID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN Status SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN EventType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN TaxCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN BuyTax SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN SellTax SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN PositionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN DividendValueInCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN DividendCurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN PlayerStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN IsComputeForHedge SET TAGS ('pii' = 'none');
