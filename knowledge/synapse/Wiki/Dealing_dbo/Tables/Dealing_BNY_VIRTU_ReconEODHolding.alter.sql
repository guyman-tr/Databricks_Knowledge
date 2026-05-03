-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_BNY_VIRTU_ReconEODHolding
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding SET TBLPROPERTIES (
    'comment' = '**Daily end-of-day holdings reconciliation** comparing BNY Mellon''s custodian position for each instrument against eToro''s internal hedge position (eToro_Units) and client NOP (Clients_Units). Each row represents one instrument position for one date, with diff columns exposing discrepancies between the LP and eToro views. **Row grain**: `Date` + `InstrumentID` (+ implicit BNY account scope via LP mapping).'
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN Date COMMENT 'Report date (EOD snapshot date).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN Account_Number COMMENT 'BNY custodian sub-account number. NULL for eToro-only rows.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN InstrumentID COMMENT 'eToro instrument identifier. FK -> DWH_dbo.Dim_Instrument.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN InstrumentDisplayName COMMENT 'Instrument display name.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN Symbol COMMENT 'Ticker symbol.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN ISINCode COMMENT 'ISIN - primary join key between BNY and eToro sides.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN CurrencyPrimary COMMENT 'Local currency (GBX normalised to GBP).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN Exchange COMMENT 'Trading venue.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN BNY_Units COMMENT 'EOD position units reported by BNY custodian. (Tier 2 - LP_BNY_Custody_Valuation)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN eToro_Units COMMENT 'EOD hedge units from eToro''s internal hedge position. (Tier 1 - Dealing_Duco_EODRecon.eToro_Units)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN Clients_Units COMMENT 'Aggregated client NOP units. (Tier 1 - Dealing_Duco_EODRecon.ClientUnits)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN `BNY-eToro_Units` COMMENT '**Reconciliation diff**: BNY_Units - eToro_Units. Non-zero = recon break to investigate.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN `BNY-Clients_Units` COMMENT 'BNY_Units - Clients_Units. LP vs client position comparison.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN BNY_LocalAmount COMMENT 'Position market value in local currency (BNY reported).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN eToro_LocalAmount COMMENT 'eToro''s local amount valuation. GBX normalised ÷100.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN `BNY-eToro_LocalAmount` COMMENT 'BNY_LocalAmount - eToro_LocalAmount.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN BNY_AmountUSD COMMENT 'Position value in USD (BNY reported).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN eToro_AmountUSD COMMENT 'eToro position value in USD.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN Clients_AmountUSD COMMENT 'Client NOP value in USD.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN `BNY-eToro_AmountUSD` COMMENT 'BNY_AmountUSD - eToro_AmountUSD. Dollar value of the recon break.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN `BNY-Clients_AmountUSD` COMMENT 'BNY_AmountUSD - Clients_AmountUSD.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN BNY_Rate COMMENT 'BNY''s price per unit in local currency.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN eToro_Rate COMMENT 'eToro''s price per unit.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN `BNY-eToro_Rate` COMMENT 'BNY_Rate - eToro_Rate. Price discrepancy.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN BNY_FXRate COMMENT 'BNY''s FX rate (local -> USD).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN eToro_FXRate COMMENT 'eToro''s FX rate.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN activity COMMENT 'Product type tag (''Stocks - Real'', ''Stocks - CFDs''). From Fivetran LP mapping.';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN Account_Number SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN Symbol SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN ISINCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN CurrencyPrimary SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN BNY_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN eToro_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN Clients_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN `BNY-eToro_Units` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN `BNY-Clients_Units` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN BNY_LocalAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN eToro_LocalAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN `BNY-eToro_LocalAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN BNY_AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN eToro_AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN Clients_AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN `BNY-eToro_AmountUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN `BNY-Clients_AmountUSD` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN BNY_Rate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN eToro_Rate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN `BNY-eToro_Rate` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN BNY_FXRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN eToro_FXRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding ALTER COLUMN activity SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 06:05:29 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 2
-- Statements: 58/58 succeeded
-- ====================
