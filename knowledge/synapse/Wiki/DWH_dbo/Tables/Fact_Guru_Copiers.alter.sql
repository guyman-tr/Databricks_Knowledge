-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_Guru_Copiers
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers SET TBLPROPERTIES (
    'comment' = '`Fact_Guru_Copiers` is the daily financial snapshot of eToro''s CopyTrader ecosystem, aggregated per copier. Each row represents one customer (CID) on one day (DateID), showing the total value of their copy-trading portfolio: how much cash they have allocated, how much is invested in open positions, their unrealized PnL, and the value of detached positions. The table answers: "On any given day, what is the total Assets Under Copy (AUC) for each copier, broken down by cash, investment, PnL, and detached positions?" In eToro''s social trading model: - A **copier** allocates funds to copy a **Popular Investor (PI/Guru)** - The platform automatically mirrors the PI''s trades proportionally - **CopyFundAUM** is the total value: Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL The data is aggregated from individual copy relationships (CID → ParentCID pairs in `Ext_FGC_Guru_Copiers`) and filtered to `AccountTypeID = 9` (CopyFund accounts) via `Fact_SnapshotCustomer`. Synapse: HASH(CID), CLUSTERED COLUMNSTOR...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers SET TAGS (
    'domain' = 'trading',
    'object_type' = 'fact',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(CID)',
    'synapse_index' = 'CLUSTERED COLUMNSTORE INDEX',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN Column COMMENT 'Description';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN CID COMMENT 'Customer ID of the copier — the person allocating funds to copy a Popular Investor. This is the copier''s RealCID, not the guru''s. Distribution key. (Tier 2 — SP_Fact_Guru_Copiers)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN DateID COMMENT 'Date key in YYYYMMDD format for the snapshot day. Part of composite PK. (Tier 2 — SP_Fact_Guru_Copiers)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN Cash COMMENT 'Sum of available cash across all active copy relationships for this copier on this day. Cash not yet deployed into positions. (Tier 2 — Ext_FGC_Guru_Copiers / AUM Life Cycle confluence)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN Investment COMMENT 'Sum of open position investment amounts across all copy relationships. Represents capital actively deployed in mirrored trades. Source: aggregated `Trade.Position.Amount`. (Tier 2 — SP_Fact_Guru_Copiers / AUM Life Cycle confluence)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN PnL COMMENT 'Sum of unrealized profit/loss across all open copy positions. Fluctuates with market movements. (Tier 2 — SP_Fact_Guru_Copiers)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN DetachedPosInvestment COMMENT 'Sum of investment in positions that have been detached from the copy relationship but remain open. Detachment occurs when a copier manually takes control of an individual position. (Tier 2 — SP_Fact_Guru_Copiers)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN Dit_PnL COMMENT 'Unrealized PnL on detached positions. Separate from PnL because detached positions are no longer managed by the copy relationship. (Tier 2 — SP_Fact_Guru_Copiers)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN CopyFundAUM COMMENT 'Total Assets Under Copy: `Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL`. Computed in the SP, not stored at source. This is the headline metric for copy-trading portfolio value. (Tier 2 — SP_Fact_Guru_Copiers)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN UpdateDate COMMENT 'Timestamp when this row was loaded into the DWH via `GETDATE()`. (Tier 2 — SP_Fact_Guru_Copiers)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN Column SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN Cash SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN Investment SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN PnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN DetachedPosInvestment SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN Dit_PnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN CopyFundAUM SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
