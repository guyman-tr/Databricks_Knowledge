-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_CreditRiskMatrix
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_CreditRiskMatrix **Schema**: BI_DB_dbo | **UC Target**: `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix` **Row count**: ~480k (snapshot frozen at 2024-03-25 ~20:00 - 22:00 UTC) | **Refresh**: nominally hourly (Override) but **STALE since 2024-03-25** **Distribution**: ROUND_ROBIN | **Clustered Index**: HedgeServerID ---'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN PositionsTime COMMENT 'Timestamp of the position snapshot used to compute the matrix (e.g., 2024-03-25 21:00).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN HedgeServerID COMMENT 'LP/hedge server identifier - the eToro hedge book the positions belong to.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN InstrumentID COMMENT 'eToro instrument identifier. Joins to `DWH_dbo.Dim_Instrument`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN InstrumentName COMMENT 'Instrument display ticker (e.g., ''PII/USD'', ''KNEBV/EUR'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN InstrumentType COMMENT 'Instrument category - Stocks, ETF, Crypto, Currencies, Commodities, etc.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN IsBuy COMMENT 'Direction flag - 1 = Buy/long aggregated NOP, 0 = Sell/short aggregated NOP.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Leverage COMMENT 'Leverage tier of the position bucket (1, 2, 5, 10, 30, etc).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Regulation COMMENT 'Regulatory entity for the customer''s account (CySEC, FCA, FSA Seychelles, ASIC, etc).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Region COMMENT 'Geographic region grouping (often empty in sample).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Bid COMMENT 'Instrument bid price at `PositionsTime` in instrument trade currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Ask COMMENT 'Instrument ask price at `PositionsTime` in instrument trade currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN ConversionRate COMMENT 'FX rate from instrument trade currency to report currency (typically USD) at `PositionsTime`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN UnitsNOP COMMENT 'Aggregated client-side net-open-position in instrument units for this (Server, Instrument, IsBuy, Leverage, Regulation) group. Sign carries direction.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+1%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +1% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+2%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +2% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+3%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +3% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+4%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +4% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+5%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +5% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+6%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +6% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+7%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +7% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+8%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +8% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+9%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +9% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+10%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +10% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+15%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +15% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+20%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +20% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+25%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +25% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+30%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +30% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+40%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +40% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+50%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +50% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+60%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +60% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+70%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +70% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+80%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +80% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+90%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +90% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+100%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved +100% (price doubled) from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+200%` COMMENT 'Simulated post-shock NOP at +200% price shock.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+300%` COMMENT 'Simulated post-shock NOP at +300% price shock.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+400%` COMMENT 'Simulated post-shock NOP at +400% price shock.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+900%` COMMENT 'Simulated post-shock NOP at +900% price shock (extreme stress test).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-1%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved -1% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-2%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved -2% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-3%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved -3% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-4%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved -4% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-5%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved -5% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-6%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved -6% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-7%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved -7% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-8%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved -8% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-9%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved -9% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-10%` COMMENT 'Simulated post-shock NOP if Bid/Ask moved -10% from current.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-15%` COMMENT 'Simulated post-shock NOP at -15% price shock.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-20%` COMMENT 'Simulated post-shock NOP at -20% price shock.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-25%` COMMENT 'Simulated post-shock NOP at -25% price shock.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-30%` COMMENT 'Simulated post-shock NOP at -30% price shock.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-40%` COMMENT 'Simulated post-shock NOP at -40% price shock.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-50%` COMMENT 'Simulated post-shock NOP at -50% price shock.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-60%` COMMENT 'Simulated post-shock NOP at -60% price shock.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-70%` COMMENT 'Simulated post-shock NOP at -70% price shock.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-80%` COMMENT 'Simulated post-shock NOP at -80% price shock.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-90%` COMMENT 'Simulated post-shock NOP at -90% price shock.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-99%` COMMENT 'Simulated post-shock NOP at -99% price shock (near-total drop).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-100%` COMMENT 'Simulated post-shock NOP at -100% price shock (price -> 0).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN UpdateDate COMMENT 'Batch insert timestamp (GETDATE() at the time of writing).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN IsSettled COMMENT 'Flag - 1 = closed/settled positions, 0 = open positions. Sample shows all 0.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Min_BankruptcyRate COMMENT 'Minimum bankruptcy-trigger price rate across the underlying client positions in this group.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Max_BankruptcyRate COMMENT 'Maximum bankruptcy-trigger price rate across the underlying client positions in this group.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Mean_BankruptcyRate COMMENT 'Mean bankruptcy-trigger price rate across the underlying client positions.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Std_BankruptcyRate COMMENT 'Standard deviation of bankruptcy-trigger price rates (NULL when only one position).';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN PositionsTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Bid SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Ask SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN ConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN UnitsNOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+1%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+2%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+3%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+4%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+5%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+6%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+7%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+8%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+9%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+10%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+15%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+20%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+25%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+30%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+40%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+50%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+60%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+70%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+80%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+90%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+100%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+200%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+300%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+400%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP+900%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-1%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-2%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-3%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-4%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-5%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-6%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-7%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-8%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-9%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-10%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-15%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-20%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-25%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-30%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-40%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-50%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-60%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-70%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-80%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-90%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-99%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN `UnitsNOP-100%` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Min_BankruptcyRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Max_BankruptcyRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Mean_BankruptcyRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_creditriskmatrix ALTER COLUMN Std_BankruptcyRate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 11:25:48 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 5
-- Statements: 134/134 succeeded
-- ====================
