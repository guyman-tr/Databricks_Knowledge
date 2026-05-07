-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Dim_Revenue_Metrics
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.Dim_Revenue_Metrics > 18-row revenue-metric dimension that catalogs every fee/revenue type tracked in the eToro DDR pipeline and groups them into 5 categories: TradeTransactional, Overnight, MIMO, RevShare, Other. The `IncludedInTotalRevenue` boolean drives the canonical "Total Revenue" rollup - metrics with `IncludedInTotalRevenue = false` (e.g., raw `Commission` before discounts, `Dividends`, `SDRT`) are tracked but excluded from the published top-line total to avoid double-counting or non-revenue items. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | Manually curated within DWH (no external upstream) | | **Refresh** | Effectively static - only changes when a new fee type is added (last addition `Options_PFOF` on 2025-10-22) | | **Row Count** | 18 | | **Grain** | One row per revenue metric | | | | | **'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics ALTER COLUMN Metric COMMENT 'Human-readable metric name. Examples: FullCommission, RollOverFee, CashoutFeeExclRedeem, ShareLending, DormantFee, Options_PFOF. The label used in DDR fact-table column names and Tableau views. (Tier 1 - UC sample)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics ALTER COLUMN IncludedInTotalRevenue COMMENT 'True if this metric contributes to the canonical "Total Revenue" rollup; False for raw/pass-through entries (`Commission`, `Dividends`, `SDRT`). Filter on this when computing top-line revenue to avoid double-counting. (Tier 1 - UC sample, 14 of 18 rows true)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics ALTER COLUMN RevenueMetricID COMMENT 'Surrogate key. Stable integer 1-18 (with new entries appended). FK target from DDR fact tables when revenue is stored long-form. (Tier 1 - UC sample)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics ALTER COLUMN RevenueMetricCategoryID COMMENT 'Category surrogate key 1-5. 1=TradeTransactional, 2=Overnight, 3=MIMO, 4=RevShare, 5=Other. (Tier 1 - UC sample)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics ALTER COLUMN RevenueMetricCategory COMMENT 'Category label (1:1 with RevenueMetricCategoryID). Used for high-level revenue rollups in the DDR. (Tier 1 - UC sample)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics ALTER COLUMN UpdateDate COMMENT 'Timestamp of the most recent ETL touch. The 17 original metrics share `2025-07-30 09:16:17.703`; `Options_PFOF` was added later (`2025-10-22 12:50:09.737`). (Tier 1 - UC sample)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics ALTER COLUMN Metric SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics ALTER COLUMN IncludedInTotalRevenue SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics ALTER COLUMN RevenueMetricID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics ALTER COLUMN RevenueMetricCategoryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics ALTER COLUMN RevenueMetricCategory SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 10:46:13 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 13
-- Statements: 14/14 succeeded
-- ====================
