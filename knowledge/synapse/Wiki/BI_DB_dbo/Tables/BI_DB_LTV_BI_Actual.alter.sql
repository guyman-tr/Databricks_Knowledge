-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_LTV_BI_Actual
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_LTV_BI_Actual > Canonical customer-level Lifetime Value (LTV) output table. One row per depositor (~5.84M rows); consolidates three LTV model families: (1) multiplier-model predictions at 1Y/3Y/8Y horizons with volatility smoothing, (2) new-methodology 8Y Revenue LTV variants (with/without group supplement and outlier exclusion), and (3) behavioral segmentation inputs (cluster, equity tier, seniority). Refreshed daily by SP_LTV_BI_Actual (P0, SB_Daily). Primary upstream of BI_DB_LTV_BI_Actual_Daily_Snapshot (4.54B row archive) and LTV_FromDB_ToBigQuery export. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | BI_DB_LTV_Predictions, BI_DB_CIDFirstDates, BI_DB_CID_DailyCluster, Fact_SnapshotEquity, Revenue8Y model | | **Refresh** | Daily; SP_LTV_BI_Actual, Priority 0, SB_Daily process (full replace) | '
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within eToro DB. NOT NULL; hash distribution key. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN GCID COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NOT NULL. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN NewMarketingRegion COMMENT 'Marketing region label. Matches Region in BI_DB_LTV_Predictions (DWH_dbo.Dim_Country.Region via Dictionary.MarketingRegion). Examples: UK (19%), German (15%), French (10%), CEE (8%), Italian (7%), USA (7%). Used as cohort dimension in LTV grouping. (Tier 2 - BI_DB_LTV_Predictions wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN FirstDepositDate COMMENT 'Date of customer''s first deposit. Range: 2007-08-29 to 2026-03-12. NULL for customers without deposit. (Tier 2 - BI_DB_CIDFirstDates context + data evidence)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN FirstFundedMonth COMMENT 'Month-end date of the customer''s first funded month: EOMONTH(FirstNewFundedDate). Cohort anchor for group-level LTV averaging and VolFix rolling window. NULL for customers without FirstNewFundedDate (legacy depositors). (Tier 2 - BI_DB_LTV_Predictions wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Seniority COMMENT 'Months from FirstFundedMonth to the current SP run date. Key LTV model input. Avg 57 months (4.8 years); max 164 months (13.7 years). Drives the predicted-vs-actual crossover at 12/36/96 months. (Tier 2 - BI_DB_LTV_Predictions wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN ClusterDetail COMMENT 'Customer behavioral cluster at the SP run date, from BI_DB_CID_DailyCluster. 7 values: Crypto (26%), Equities Traders (16%), Equities Crypto (14%), NoCluster (18%), Leveraged Traders (11%), Equities Investors (9%), Diversified Traders (6%). LTV model segmentation dimension. (Tier 2 - BI_DB_LTV_Predictions wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN EquityTier COMMENT 'Equity tier from most recent Fact_SnapshotEquity: 1=RealizedEquity<$100 (67%), 2=$100-$500 (10%), 3= >= $500 (22%). NULL for <0.2% where no equity snapshot exists. LTV model segmentation dimension. (Tier 2 - BI_DB_LTV_Predictions wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN MonthsSinceLastPosOpen COMMENT 'Months since this customer last opened a trading position. Inactivity indicator. Avg 37 months; value = 0 for currently active customers. Used in LTV model as recency signal. (Tier 2 - naming + data evidence)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Current_ACC_Revenue COMMENT 'Cumulative revenue this customer has generated for eToro to date. The base value for multiplier-model LTV calculation: LTV_nY = Current_ACC_Revenue / RatioSnapshotTo_nY. Adjusted for underestimation at low seniority (Seniority=1 -> ÷0.80, Seniority=2 -> ÷0.90, Seniority=3 -> ÷0.95). (Tier 2 - BI_DB_LTV_Predictions wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN DaysFromFTD COMMENT 'Days from FirstDepositDate to the SP run date. Parallel to Seniority (which is in months from funded date); this is in calendar days from first deposit. Avg 1,809 days (~5 years). (Tier 2 - naming + data evidence)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_1Y COMMENT '1-year LTV: predicted cumulative broker revenue at 12 months from first funding. Switches to actual revenue at month 12 once Seniority  >=  12. Pre-milestone: multiplier-model prediction. (Tier 2 - BI_DB_LTV_Predictions wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_3Y COMMENT '3-year LTV: same hybrid predicted/actual pattern, crossover at Seniority  >=  36 months. (Tier 2 - BI_DB_LTV_Predictions wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_8Y COMMENT '8-year LTV: crossover at Seniority  >=  96 months. Avg $1,266; max $46.5M; 13% zero. (Tier 2 - BI_DB_LTV_Predictions wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_1Y_VolFix COMMENT '1Y LTV with 12-month rolling group average volatility smoothing. Clamped to [0.5, 2.0] × LTV_1Y. Preferred for revenue modelling. (Tier 2 - BI_DB_LTV_Predictions wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_3Y_VolFix COMMENT '3Y LTV with volatility smoothing. Same clamping logic as LTV_1Y_VolFix. (Tier 2 - BI_DB_LTV_Predictions wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_8Y_VolFix COMMENT '8Y LTV with volatility smoothing. **Preferred multiplier-model variant** for downstream analytics. Base for LTV_8Y_GroupLevel computation. (Tier 2 - BI_DB_LTV_Predictions wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_8Y_GroupLevel COMMENT 'Post-INSERT group average: AVG(LTV_8Y_VolFix) across all customers in the same (FirstFundedMonth × NewMarketingRegion × ClusterDetail × EquityTier) cohort. All cohort members share the same value. Better for inactive/new customers where individual history is thin. (Tier 2 - BI_DB_LTV_Predictions wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_New COMMENT '8-year cumulative broker revenue prediction, new methodology (2023+). Individual prediction only - may be low for inactive customers. See Section 2.4 for variant selection guide. (Tier 2 - BI_DB_LTV_BI_Actual_Daily_Snapshot wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_NoExtreme_New COMMENT '8Y LTV (new methodology) with statistical outliers excluded. Conservative lower bound for individual planning. (Tier 2 - BI_DB_LTV_BI_Actual_Daily_Snapshot wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when SP_LTV_BI_Actual last calculated this customer''s LTV. NOT NULL. Note: In BI_DB_LTV_BI_Actual_Daily_Snapshot, this column reflects the LTV model refresh time, not the snapshot time - use Snapshot_UpdateDate there. (P)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_New_WO_Group_LTV COMMENT 'Individual 8Y LTV without group-level supplement. **Zero** (not NULL) where group-level assignment was applied. Use Revenue8Y_LTV_New_Group_LTV for complete aggregations. (Tier 2 - BI_DB_LTV_BI_Actual_Daily_Snapshot wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_NoExtreme_New_WO_Group_LTV COMMENT 'Outlier-trimmed individual 8Y LTV without group supplement. Most conservative individual estimate. Zero where group LTV applied. (Tier 2 - BI_DB_LTV_BI_Actual_Daily_Snapshot wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN First_Month_Equity_Tier COMMENT 'Customer''s equity tier (1/2/3) during their first funded month. Frozen at cohort entry for cohort stability. Distribution: Tier 1 (35%), Tier 2 (28%), Tier 3 (37%). (Tier 2 - BI_DB_LTV_BI_Actual_Daily_Snapshot wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN First_Month_Cluster COMMENT 'Customer''s behavioral cluster in their first funded month. Frozen at cohort entry. Enables first-month cohort analysis alongside current ClusterDetail. (Tier 2 - BI_DB_LTV_BI_Actual_Daily_Snapshot wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Currency COMMENT 'Customer account currency classification. Binary values: ''Non_USD'' (~67%), ''USD'' (~32%), '''' empty (~1%). Does NOT store the actual currency code - is a USD vs. non-USD flag used in LTV model calibration. (Tier 2 - BI_DB_LTV_BI_Actual_Daily_Snapshot wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue_Change_Percentage_Fixed COMMENT 'Fixed calibration multiplier applied to base LTV prediction to adjust for known revenue projection bias. Small positive value (~0.02 - 0.05 observed). (Tier 2 - BI_DB_LTV_BI_Actual_Daily_Snapshot wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_New_Group_LTV COMMENT 'Blended 8Y LTV: individual prediction where history is sufficient; group-level supplement applied otherwise. **Recommended for most downstream use cases.** (Tier 2 - BI_DB_LTV_BI_Actual_Daily_Snapshot wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_NoExtreme_New_Group_LTV COMMENT 'Blended 8Y LTV without outliers. Conservative version of Revenue8Y_LTV_New_Group_LTV. (Tier 2 - BI_DB_LTV_BI_Actual_Daily_Snapshot wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_All_Conv_Old COMMENT 'Legacy 8Y LTV prediction from pre-2023 methodology. Retained for historical comparison only; not recommended for new analyses. (Tier 2 - naming + data evidence)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN NewMarketingRegion SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN FirstFundedMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Seniority SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN ClusterDetail SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN EquityTier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN MonthsSinceLastPosOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Current_ACC_Revenue SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN DaysFromFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_1Y SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_3Y SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_8Y SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_1Y_VolFix SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_3Y_VolFix SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_8Y_VolFix SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN LTV_8Y_GroupLevel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_New SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_NoExtreme_New SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_New_WO_Group_LTV SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_NoExtreme_New_WO_Group_LTV SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN First_Month_Equity_Tier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN First_Month_Cluster SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue_Change_Percentage_Fixed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_New_Group_LTV SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_NoExtreme_New_Group_LTV SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN Revenue8Y_LTV_All_Conv_Old SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:59:20 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 62/62 succeeded
-- ====================
