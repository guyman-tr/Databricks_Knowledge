-- =============================================================================
-- Databricks ALTER Script: main.etoro_kpi_prep.v_population_active_traders_lite  (VIEW)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/UC_generated/etoro_kpi_prep/Views/v_population_active_traders_lite.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.GCID IS 'Direct passthrough from upstream. Formula: `GCID`. (Tier 2 - from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`)';
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.RealCID IS 'Direct passthrough from upstream. Formula: `RealCID`. (Tier 2 - from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`)';
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.DateID IS 'Direct passthrough from upstream. Formula: `DateID`. (Tier 2 - from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`)';
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.ActiveTraded IS 'Literal constant set in this object. Formula: `1`. (Tier 2 - literal)';
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.ActiveTradedManual IS 'Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 THEN 1 ELSE 0 END)`. (Tier 2 - from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+3 more))';
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.ActiveTradedCFD IS 'Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (1, 2, 4) THEN 1 ELSE 0 END)`. (Tier 2 - from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+3 more))';
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.ActiveTradedCryptoCFD IS 'Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (10) AND IsSettled = 0 THEN 1 ELSE 0 END)`. (Tier 2 - from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+3 more))';
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.ActiveTradedCryptoReal IS 'Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (10) AND IsSettled = 1 THEN 1 ELSE 0 END)`. (Tier 2 - from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+3 more))';
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.ActiveTradedStocksCFD IS 'Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (5) AND IsSettled = 0 THEN 1 ELSE 0 END)`. (Tier 2 - from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+3 more))';
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.ActiveTradedStocksReal IS 'Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (5) AND IsSettled = 1 THEN 1 ELSE 0 END)`. (Tier 2 - from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+3 more))';
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.ActiveTradedETFCFD IS 'Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (6) AND IsSettled = 0 THEN 1 ELSE 0 END)`. (Tier 2 - from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+3 more))';
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.ActiveTradedETFReal IS 'Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (6) AND IsSettled = 1 THEN 1 ELSE 0 END)`. (Tier 2 - from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+3 more))';
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.ActiveTradedCopy IS 'Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN MirrorID > 0 AND ActionTypeID IN (15, 17) THEN 1 ELSE 0 END)`. (Tier 2 - from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+3 more))';
COMMENT ON COLUMN main.etoro_kpi_prep.v_population_active_traders_lite.ActiveTradedOptions IS 'Computed flag (CASE expression in source). Formula: `MAX(CASE WHEN InstrumentTypeID = 9 THEN 1 ELSE 0 END)`. (Tier 2 - from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` (+3 more))';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:25:26 UTC
-- Statements: 14/14 succeeded
-- ====================
