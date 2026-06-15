-- =============================================================================
-- Databricks ALTER Script: main.trading.bronze_etoro_history_instrumenttofeeconfigv2  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentToFeeConfigV2.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN InstrumentID COMMENT 'The trading instrument this fee configuration applies to. Part of composite PK (InstrumentID, SettlementTypeID) in the live table. FK to Trade.Instrument(InstrumentID).';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN SettlementTypeID COMMENT 'Specifies which settlement type this fee row applies to: 0=CFD (contract for difference, no real ownership), 1=REAL (customer owns actual shares), 2=TRS (total return swap), 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. (Dictionary.SettlementTypes). DEFAULT 0 = CFD.';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN FeeCalculationTypeID COMMENT 'Determines how fee values are mathematically applied: 0=ExposureFormula (fee = units * rate, rate is $/unit), 1=LoanFormula (fee = value * rate/100, rate is daily %). (Dictionary.FeeCalculationTypes). DEFAULT 0 = ExposureFormula.';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedSellEndOfWeekFee COMMENT 'End-of-week fee for non-leveraged short sell positions. Charged when position held over weekend (3 days). Unit determined by FeeCalculationTypeID.';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedBuyEndOfWeekFee COMMENT 'End-of-week fee for non-leveraged long buy positions. Typically 0 for REAL settlement (no borrow cost for owning stock).';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedBuyOverNightFee COMMENT 'Overnight fee for non-leveraged long buy positions. Typically 0 for REAL settlement as customer owns the stock outright. Non-zero for CFD settlement where there is an implicit financing cost.';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN NonLeveragedSellOverNightFee COMMENT 'Overnight fee for non-leveraged short sell positions. Positive = customer pays; reflects stock borrowing cost for short positions.';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN LeveragedSellEndOfWeekFee COMMENT 'End-of-week fee for leveraged short sell positions. Covers the 3-day weekend holding period.';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN LeveragedBuyEndOfWeekFee COMMENT 'End-of-week fee for leveraged long buy positions. Approximately 3x the daily overnight rate for the weekend.';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN LeveragedBuyOverNightFee COMMENT 'Overnight fee for leveraged long buy positions. Positive value = customer pays interest on borrowed capital for leveraged long. Example: 0.074666 in ExposureFormula = $0.074666 per unit of exposure per night.';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN LeveragedSellOverNightFee COMMENT 'Overnight fee for leveraged short sell positions. Negative value (-1.0 in live data) means the customer RECEIVES this amount per unit when holding a leveraged short overnight (positive carry on short EUR/USD REAL positions).';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN Occurred COMMENT 'Business-layer timestamp when this fee configuration was calculated or updated. Set by the fee recalculation job or manual operator. Distinct from BeginTime which is the SQL Server temporal system timestamp.';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN UpdatedByUser COMMENT 'Username of operator who set this configuration. NULL for automated fee recalculation jobs; populated for manual updates via the EtoroOps interface.';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN BeginTime COMMENT 'UTC timestamp when this fee configuration row became active in Trade.InstrumentToFeeConfigV2 (non-standard name for SysStartTime).';
ALTER TABLE main.trading.bronze_etoro_history_instrumenttofeeconfigv2 ALTER COLUMN EndTime COMMENT 'UTC timestamp when this fee configuration was superseded (non-standard name for SysEndTime). Rows with EndTime = ''9999-12-31'' are active in the live table.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:24:33 UTC
-- Statements: 15/15 succeeded
-- ====================
