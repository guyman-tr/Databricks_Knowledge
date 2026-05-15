-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CostConfigurationId
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costconfigurationid
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costconfigurationid ALTER COLUMN CostConfigurationId COMMENT 'Primary key. Integer identifier for the cost configuration type. Maps to: 1=MarkupReal, 2=MarkupCfd, 3=TicketFee, 4=CurrencyConversionMarkup. DWH note: sourced from `Id` column in HistoryCosts staging (renamed to avoid collision with the name field). (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costconfigurationid ALTER COLUMN CostConfiguration COMMENT 'Human-readable name for the cost configuration type. Values observed: MarkupReal, MarkupCfd, TicketFee, CurrencyConversionMarkup. DWH note: sourced from the staging column also named `CostConfigurationId` (nvarchar) in HistoryCosts, renamed here to avoid collision with the integer PK. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costconfigurationid ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - set to GETDATE() on each full reload by SP_Dictionaries_DL_To_Synapse. Reflects when the batch SP last ran, not when the source data changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costconfigurationid ALTER COLUMN CostConfigurationId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costconfigurationid ALTER COLUMN CostConfiguration SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_costconfigurationid ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

