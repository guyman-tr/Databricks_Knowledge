-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_ManipulationReport_RealStocks
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks SET TBLPROPERTIES (
    'comment' = '`Dealing_ManipulationReport_RealStocks` is a **daily market manipulation surveillance report** for real (settled) stock and ETF positions at eToro. It identifies instruments where client trading activity exhibits patterns associated with potential market manipulation, based on multiple KPI flags computed by `SP_ManipulationReport_RealStocks`. **Scope**: Real assets only (`IsSettled=1`), Stocks and ETFs (`InstrumentTypeID IN 5,6`), manual positions only (not copy-trading, `MirrorID=0`), valid customers in regulated jurisdictions (RegulationID IN 1,2,4 = CySEC, FCA, ASIC-equivalent). Data is filtered to weekdays only. Each row represents an **instrument flagged under a specific KPI** for the reporting date. The same instrument can appear multiple times with different KPI values if it triggers multiple manipulation signals. The data is used by the Dealing/Compliance team for regulatory surveillance, with results typically reviewed the following morning. **Related table**: `Dealing_ManipulationReport_RealStocks_C'
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN ★★★ COMMENT '`(Tier 2 — SP_ManipulationReport_RealStocks)`';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN ★★ COMMENT '`(Tier 3 — live data)`';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN Date COMMENT 'The reporting date (weekdays only). All rows in a batch share the same Date. Clustered index key. Corresponds to `@dd` SP parameter. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN KPI COMMENT 'The manipulation signal category. Values: `First10Minutes`, `Last10Minutes`, `Flag2`, `Top20_Volume`, `Top20_Volume_LowMktCap`, `Top20_Volume_20Min`, `Top20_Volume_20Min_LowMktCap`, `AvgVolume`. Each KPI detects a different behavioral pattern. An instrument may appear in multiple KPI rows for the same date. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN InstrumentID COMMENT 'Instrument identifier for the flagged stock or ETF. FK to DWH_dbo.Dim_Instrument. Only real stocks/ETFs (InstrumentTypeID 5,6, IsSettled=1). (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN InstrumentDisplayName COMMENT 'User-facing display name of the instrument from Dim_Instrument.InstrumentDisplayName (e.g., ''Apple Inc.'', ''Implanet SA''). Used for reporting and review. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN InstrumentType COMMENT 'Text category: ''Stocks'' or ''ETF''. From Dim_Instrument.InstrumentType. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN Regulation COMMENT 'Regulatory entity overseeing the flagged activity. From Dim_Regulation.Name. Values: ''CySEC'', ''FCA'', or related regulators (RegulationID IN 1,2,4). The report is segmented by regulation since different regulators have different reporting obligations. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN RN COMMENT 'Rank number within the KPI segment, ordered by Volume descending (within Regulation × IsLowMktCap grouping). Populated for Top20_Volume* KPIs (1–20); NULL for other KPIs (First10Minutes, Last10Minutes, Flag2, AvgVolume). (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN Volume COMMENT 'Total client USD trading volume (opens + closes) for this instrument on `Date`, from Dim_Position (Volume + VolumeOnClose). Cast to BIGINT. Represents the size of client activity in this stock. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN Units COMMENT 'Total client position units (shares) traded for this instrument on `Date` (AmountInUnitsDecimal summed across opens and closes). Represents the number of shares, not USD value. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN Last30DaysAvgVolume COMMENT 'Average daily client USD volume over the trailing 30 working days, computed from Dim_Position. Used as baseline for volume anomaly detection. The ratio `Volume / Last30DaysAvgVolume` indicates how unusual today''s activity is. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN ExchangeUnitsVolume COMMENT 'Official exchange-reported daily trading volume in shares (units), sourced from `CopyFromLake.Rankings_StockInfo_DailyInstrumentInfo` MetadataID=8708. Represents total market activity for this stock on this exchange. Used to compute `Units / ExchangeUnitsVolume` = eToro''s share of exchange volume (potential market impact signal). (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN MA_10Days COMMENT '10-day moving average of exchange daily volume (in shares), computed from 90-day trailing window of Rankings StockInfo data. Used for trend-adjusted comparison: an instrument with Volume well above MA_10Days suggests unusually active market conditions. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN MaxToMinChange COMMENT 'Maximum intraday price range: `(MAX(BidMax) / MIN(BidMin)) - 1` across all 60-minute candles for the day, from Dim_GetSpreadedPriceCandle60MinSplitted. Expressed as a decimal fraction (e.g., 0.025 = 2.5% intraday range). High values (≥0.20 = 20%) indicate significant price volatility, which in combination with large eToro client volume may indicate manipulative trading. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN UpdateDate COMMENT 'ETL metadata: `GETDATE()` at time SP ran. Not a business timestamp. (Tier 2 — SP_ManipulationReport_RealStocks)';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN ★★★ SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN ★★ SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN KPI SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN RN SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN Volume SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN Last30DaysAvgVolume SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN ExchangeUnitsVolume SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN MA_10Days SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN MaxToMinChange SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
