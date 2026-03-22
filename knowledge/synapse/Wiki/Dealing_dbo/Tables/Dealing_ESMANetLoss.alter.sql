-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_ESMANetLoss
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss SET TBLPROPERTIES (
    'comment' = ''
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss SET TAGS (
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
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN Date COMMENT 'Position close date';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN Regulation COMMENT 'Regulatory jurisdiction (CySEC, FCA, ASIC, etc.)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN MifID COMMENT 'MiFID categorization (Retail / Professional)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN PositionID COMMENT 'Position identifier';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN InstrumentType COMMENT 'Instrument asset class';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN InstrumentID COMMENT 'Instrument identifier';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN InstrumentName COMMENT 'Instrument display name';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN IsBuy COMMENT 'Position direction: 1=long, 0=short';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN AmountInUnitsDecimal COMMENT 'Position size in instrument units';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN CloseOccurred COMMENT 'Position close timestamp';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN Amount COMMENT 'Invested amount (USD) at open';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN NetProfit COMMENT 'Actual realized P&L with stop-loss protection (always negative here)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN NoRestrictionNetProfit COMMENT 'Hypothetical P&L without stop-loss protection';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN InitForexRate COMMENT 'Opening price of the position';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN EndForexRate COMMENT 'Closing price with protection applied';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN StopRate COMMENT 'Stop-loss rate that was active';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN NoProtectionRate COMMENT 'Market price at close time ignoring stop — what price would have been';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN LastOpConversionRate COMMENT 'USD conversion rate at position close';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN DeltaLoss COMMENT 'Additional loss prevented by stop-loss: NoRestrictionNetProfit − NetProfit (positive = client protected)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN UpdateDate COMMENT 'ETL metadata: row write timestamp';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN MifID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN AmountInUnitsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN CloseOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN NetProfit SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN NoRestrictionNetProfit SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN InitForexRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN EndForexRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN StopRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN NoProtectionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN LastOpConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN DeltaLoss SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
