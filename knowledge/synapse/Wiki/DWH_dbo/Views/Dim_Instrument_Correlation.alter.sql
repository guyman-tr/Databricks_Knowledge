-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Instrument_Correlation
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation SET TBLPROPERTIES (
    'comment' = 'DWH_dbo.Dim_Instrument_Correlation > Full symmetric Pearson correlation matrix between all tradeable instrument pairs, computed from 3-month rolling hourly price changes. Reconstructed from half-matrix storage across 20 physical partition tables plus an archive. | Property | Value | |----------|-------| | **Schema** | DWH_dbo | | **Object Type** | View | | **Production Source** | DWH-computed (no production equivalent) | | **Refresh** | Daily - correlations recomputed for current date from 3-month price window | | | | | **Synapse Distribution** | N/A (view over 20 ROUND_ROBIN tables + ROUND_ROBIN archive) | | **Synapse Index** | N/A (underlying tables: CLUSTERED INDEX DateID DESC, InstrumentID_a, InstrumentID_b) | | | | | **UC Target** | _Pending - resolved during write-objects_ | | **UC Format** | _Pending - resolved during write-objects_ | | **UC Partitioned By** | _Pending - resolved '
);

-- ---- Table Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation SET TAGS (
    'source_schema' = 'DWH_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN DateID COMMENT 'UnionedPartitions.DateID + Archive.DateID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN InstrumentID_a COMMENT 'UnionedPartitions.InstrumentID_a (+ swapped _b)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN InstrumentID_b COMMENT 'UnionedPartitions.InstrumentID_b (+ swapped _a)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN SampleSize COMMENT 'UnionedPartitions.SampleSize + Archive.SampleSize';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN StandardDeviation_a COMMENT 'UnionedPartitions.StandardDeviation_a (+ swapped _b)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN StandardDeviation_b COMMENT 'UnionedPartitions.StandardDeviation_b (+ swapped _a)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN Covariance COMMENT 'UnionedPartitions.Covariance + Archive.Covariance';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN PearsonCorrelation COMMENT 'UnionedPartitions.PearsonCorrelation + Archive.PearsonCorrelation';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN InsertDate COMMENT 'UnionedPartitions.InsertDate + Archive.InsertDate';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN UpdateDate COMMENT 'UnionedPartitions.UpdateDate + Archive.UpdateDate';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN InstrumentID_a SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN InstrumentID_b SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN SampleSize SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN StandardDeviation_a SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN StandardDeviation_b SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN Covariance SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN PearsonCorrelation SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:35:56 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 22/22 succeeded
-- ====================
