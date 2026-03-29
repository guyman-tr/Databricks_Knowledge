-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Instrument_Correlation
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation SET TBLPROPERTIES (
    'comment' = 'DWH_dbo.Dim_Instrument_Correlation > Full symmetric Pearson correlation matrix between all tradeable instrument pairs, computed from 3-month rolling hourly price changes. Reconstructed from half-matrix storage across 20 physical partition tables plus an archive. | Property | Value | |----------|-------| | **Schema** | DWH_dbo | | **Object Type** | View | | **Production Source** | DWH-computed (no production equivalent) | | **Refresh** | Daily — correlations recomputed for current date from 3-month price window | | | | | **Synapse Distribution** | N/A (view over 20 ROUND_ROBIN tables + ROUND_ROBIN archive) | | **Synapse Index** | N/A (underlying tables: CLUSTERED INDEX DateID DESC, InstrumentID_a, InstrumentID_b) | | | | | **UC Target** | _Pending — resolved during write-objects_ | | **UC Format** | _Pending — resolved during write-objects_ | | **UC Partitioned By** | _Pending — resolved '
);

-- ---- Table Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation SET TAGS (
    'source_schema' = 'DWH_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN DateID COMMENT 'Date the correlation was computed for, in YYYYMMDD format. The correlation uses price data from 3 months before this date. (Tier 2 — SP_Dim_Instrument_Correlation_FilterByInstrumentID)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN InstrumentID_a COMMENT 'First instrument in the correlation pair. In the underlying storage, this is always <= InstrumentID_b; the view reconstructs both orderings. JOINs to Dim_Instrument.InstrumentID. (Tier 2 — SP_Dim_Instrument_Correlation_FilterByInstrumentID)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN InstrumentID_b COMMENT 'Second instrument in the correlation pair. Swapped with InstrumentID_a in the view''s second UNION ALL leg. JOINs to Dim_Instrument.InstrumentID. (Tier 2 — SP_Dim_Instrument_Correlation_FilterByInstrumentID)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN SampleSize COMMENT 'Number of matching hourly price candle pairs used for the correlation computation. Higher = more statistically robust. Typically 2000+ for liquid instruments over 3 months. (Tier 2 — SP_Dim_Instrument_Correlation_FilterByInstrumentID)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN StandardDeviation_a COMMENT 'Population standard deviation of hourly price changes for instrument A over the 3-month window. STDEVP(PriceChange_a). Swapped with StandardDeviation_b in the symmetric reconstruction. (Tier 2 — SP_Dim_Instrument_Correlation_FilterByInstrumentID)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN StandardDeviation_b COMMENT 'Population standard deviation of hourly price changes for instrument B over the 3-month window. STDEVP(PriceChange_b). Swapped with StandardDeviation_a in the symmetric reconstruction. (Tier 2 — SP_Dim_Instrument_Correlation_FilterByInstrumentID)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN Covariance COMMENT 'Sample covariance between price changes of instruments A and B. Formula: `SUM(a*b)/N - SUM(a)*SUM(b)/N²`. Positive = instruments move together; negative = opposite directions. (Tier 2 — SP_Dim_Instrument_Correlation_FilterByInstrumentID)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN PearsonCorrelation COMMENT 'Pearson correlation coefficient: `Covariance / (StdDev_a * StdDev_b)`. Range: -1.0 (perfect inverse) to +1.0 (perfect correlation). NULL when either StdDev is zero (flat price). (Tier 2 — SP_Dim_Instrument_Correlation_FilterByInstrumentID)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN InsertDate COMMENT 'Timestamp when the correlation row was first computed and inserted. Set to GETDATE() during ETL. (Tier 2 — SP_Dim_Instrument_Correlation_FilterByInstrumentID)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation ALTER COLUMN UpdateDate COMMENT 'Timestamp when the row was last updated. In practice, same as InsertDate since correlations are DELETE+INSERT per date, not MERGE. (Tier 2 — SP_Dim_Instrument_Correlation_FilterByInstrumentID)';

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
