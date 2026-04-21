-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Reports_AcquisitionFunnelAggregated
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated
-- Resolved via: information_schema bulk query
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated SET TBLPROPERTIES (
    'comment' = '`eMoney_Reports_AcquisitionFunnelAggregated` is the pre-aggregated, dashboard-ready companion to `eMoney_Reports_AcquisitionFunnel`. Rather than one row per customer, it provides one row per (FunnelStage, Country, Club) combination - making it efficient for reporting queries that would otherwise require GROUP BY on the 3.67M-row customer table. As of 2026-04-12 there are **1,863 rows** = 9 funnel stages × 207 distinct Country+Club combinations. All 9 stages and their total counts mirror the customer-grain table exactly (e.g., VerifiedFTD total = 3,672,801 matching the row count of the customer table). This table is generated in the same SP run as `eMoney_Reports_AcquisitionFunnel` using a shared intermediate `#funnel` temp table, so both are always consistent with each other. Synapse: REPLICATE, HEAP.'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated SET TAGS (
    'domain' = 'marketing',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated ALTER COLUMN `FunnelStage` COMMENT 'Acquisition funnel milestone label. 9 values: VerifiedFTD (3,672,801), IsVerifiedFTDPlus2Weeks (3,659,851), IseMoneyAccount (1,726,054), IsFMI (1,201,484), IsFMO (1,160,237), IsActiveMIMO (449,123), IsCardCreated (89,823), IsCardActivated (26,079), IsCardFirstTx (23,690). Hardcoded strings in SP_eMoney_Reports_Daily. Names match corresponding boolean column names in eMoney_Reports_AcquisitionFunnel. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated ALTER COLUMN `Country` COMMENT 'Customer''s eMoney-registered country name. Same derivation as eMoney_Reports_AcquisitionFunnel.Country - ISNULL(RegCountry, rollout CountryName). GROUP BY key for aggregation. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated ALTER COLUMN `Club` COMMENT 'Customer''s current eToro loyalty club tier at time of refresh. Same derivation as eMoney_Reports_AcquisitionFunnel.Club. GROUP BY key for aggregation. 6 values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated ALTER COLUMN `FunnelCount` COMMENT 'Count of customers in the given (FunnelStage, Country, Club) group. Computed as SUM(ISNULL(boolean_flag, 0)) from the #funnel intermediate table in SP_eMoney_Reports_Daily. For VerifiedFTD, total across all groups equals the full row count of eMoney_Reports_AcquisitionFunnel. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of the most recent SP refresh. Set to GETDATE() at insert time; all rows share the same value per daily refresh. Last observed: 2026-04-12 06:50:03. (Tier 2 - SP_eMoney_Reports_Daily)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated ALTER COLUMN `FunnelStage` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated ALTER COLUMN `Club` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated ALTER COLUMN `FunnelCount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
