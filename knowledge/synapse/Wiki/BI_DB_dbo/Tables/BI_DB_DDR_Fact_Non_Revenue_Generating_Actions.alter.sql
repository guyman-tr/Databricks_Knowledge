-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions
-- Generated: 2026-05-14 14:29:17 UTC | _tmp_create_missing_alters.py
-- Target: Unity Catalog column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions
-- =============================================================================

-- ---- Table Comment ----
-- (table-level comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN DateID COMMENT '**`Occurred`** -> `YYYYMMDD` int (nonclustered index driver). (Tier 2 - SP_Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN Date COMMENT 'Calendar **`@date`** parameter surfaced as a column (`@date AS [Date]`). (Tier 2 - SP_DDR_Fact_Non_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN ActionType COMMENT 'DDR business bucket - `CASE` on `ActionTypeID` + `CompensationReasonID` + depositor cohort; unmapped combos become **`NA`** and are filtered out before insert (see section 2.1). (Tier 2 - SP_DDR_Fact_Non_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN Amount COMMENT 'Aggregated `Fact_CustomerAction.Amount` with SP sign / zero rules per `ActionType` (see `#fcaBizPrep`). (Tier 2 - Fact_CustomerAction via SP_DDR_Fact_Non_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN CountActions COMMENT 'Count of underlying actions in bucket - first-stage `COUNT(RealCID)`, then summed. (Tier 2 - SP_DDR_Fact_Non_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN UpdateDate COMMENT 'ETL load watermark - **`GETDATE()`** at insert. (Tier 2 - SP_DDR_Fact_Non_Revenue_Generating_Actions)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN IsCopyFund COMMENT '**`1`** when mirrored as Smart Portfolio / copy fund via **`Dim_Mirror.MirrorTypeID = 4`** (`COALESCE` position-path and fact-path `MirrorID`); **`0`** otherwise. (Tier 2 - Dim_Position / Dim_Mirror via SP_DDR_Fact_Non_Revenue_Generating_Actions)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN ActionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN CountActions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions ALTER COLUMN IsCopyFund SET TAGS ('pii' = 'none');

