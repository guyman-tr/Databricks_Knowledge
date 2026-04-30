-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.InstrumentToFeeConfigV2
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentToFeeConfigV2.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_history_instrumenttofeeconfigv2
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_history_instrumenttofeeconfigv2 (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 SET TBLPROPERTIES (
    'comment' = 'Temporal history table capturing all changes to the per-instrument, per-settlement-type overnight and end-of-week fee configuration (V2), the current active fee config system that differentiates fee rates by settlement type (CFD, real stock, TRS, etc.). Source: etoro.History.InstrumentToFeeConfigV2 on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentToFeeConfigV2.md).'
);

ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'InstrumentToFeeConfigV2',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN InstrumentID COMMENT 'The trading instrument this fee configuration applies to. Part of composite PK (InstrumentID, SettlementTypeID) in the live table. FK to Trade.Instrument(InstrumentID). (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN SettlementTypeID COMMENT 'Specifies which settlement type this fee row applies to: 0=CFD (contract for difference, no real ownership), 1=REAL (customer owns actual shares), 2=TRS (total return swap), 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. (Dictionary.SettlementTypes). DEFAULT 0 = CFD. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN FeeCalculationTypeID COMMENT 'Determines how fee values are mathematically applied: 0=ExposureFormula (fee = units rate, rate is $/unit), 1=LoanFormula (fee = value rate/100, rate is daily %). (Dictionary.FeeCalculationTypes). DEFAULT 0 = ExposureFormula. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedSellEndOfWeekFee COMMENT 'End-of-week fee for non-leveraged short sell positions. Charged when position held over weekend (3 days). Unit determined by FeeCalculationTypeID. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedBuyEndOfWeekFee COMMENT 'End-of-week fee for non-leveraged long buy positions. Typically 0 for REAL settlement (no borrow cost for owning stock). (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedBuyOverNightFee COMMENT 'Overnight fee for non-leveraged long buy positions. Typically 0 for REAL settlement as customer owns the stock outright. Non-zero for CFD settlement where there is an implicit financing cost. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedSellOverNightFee COMMENT 'Overnight fee for non-leveraged short sell positions. Positive = customer pays; reflects stock borrowing cost for short positions. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN LeveragedSellEndOfWeekFee COMMENT 'End-of-week fee for leveraged short sell positions. Covers the 3-day weekend holding period. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN LeveragedBuyEndOfWeekFee COMMENT 'End-of-week fee for leveraged long buy positions. Approximately 3x the daily overnight rate for the weekend. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN LeveragedBuyOverNightFee COMMENT 'Overnight fee for leveraged long buy positions. Positive value = customer pays interest on borrowed capital for leveraged long. Example: 0.074666 in ExposureFormula = $0.074666 per unit of exposure per night. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN LeveragedSellOverNightFee COMMENT 'Overnight fee for leveraged short sell positions. Negative value (-1.0 in live data) means the customer RECEIVES this amount per unit when holding a leveraged short overnight (positive carry on short EUR/USD REAL positions). (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN Occurred COMMENT 'Business-layer timestamp when this fee configuration was calculated or updated. Set by the fee recalculation job or manual operator. Distinct from BeginTime which is the SQL Server temporal system timestamp. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN UpdatedByUser COMMENT 'Username of operator who set this configuration. NULL for automated fee recalculation jobs; populated for manual updates via the EtoroOps interface. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN BeginTime COMMENT 'UTC timestamp when this fee configuration row became active in Trade.InstrumentToFeeConfigV2 (non-standard name for SysStartTime). (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN EndTime COMMENT 'UTC timestamp when this fee configuration was superseded (non-standard name for SysEndTime). Rows with EndTime = ''9999-12-31'' are active in the live table. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfigV2)';

