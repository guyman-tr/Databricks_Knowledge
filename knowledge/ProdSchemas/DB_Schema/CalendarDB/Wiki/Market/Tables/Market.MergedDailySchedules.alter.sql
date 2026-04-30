-- =============================================================================
-- Databricks ALTER Script: bronze CalendarDB.Market.MergedDailySchedules
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/CalendarDB/Wiki/Market/Tables/Market.MergedDailySchedules.md
-- Layer: bronze
-- UC Target: main.general.bronze_calendardb_market_mergeddailyschedules
-- =============================================================================

-- ---- UC Target: main.general.bronze_calendardb_market_mergeddailyschedules (business_group=general) ----
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules SET TBLPROPERTIES (
    'comment' = 'The authoritative, final market hours schedule table. Contains the merged result of defaults, provider data, and overrides for each exchange/instrument per date - the single source of truth for when instruments are open or closed for trading. Source: CalendarDB.Market.MergedDailySchedules on the CalendarDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/CalendarDB/Wiki/Market/Tables/Market.MergedDailySchedules.md).'
);

ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'CalendarDB',
    'source_schema' = 'Market',
    'source_table' = 'MergedDailySchedules',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN ID COMMENT 'Auto-increment surrogate primary key. No business meaning - rows are identified by the composite of ExchangeID + InstrumentID + Date. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN LogTime COMMENT 'Timestamp when this row was inserted, set to GETDATE() by the bulk insert SPs. Represents when the MarketCalendar function last calculated this schedule entry. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN SourceProviderName COMMENT 'Identifies which data source won the merge precedence for this entry. Known values: "eToro-Defaults" (from DefaultWeeklyCalendars), "Xignite" (from Xignite provider data), "eToro-Overrides" (from manual CM overrides). NULL should not occur in practice. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN ExchangeID COMMENT 'eToro internal exchange identifier. Determines which exchange this schedule applies to. Maps to ExchangeTimeZones for timezone, CalendarProviderExchanges for MIC code. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN InstrumentID COMMENT 'eToro internal instrument identifier. NULL = exchange-level schedule (applies to all instruments without specific entries). Non-NULL = instrument-specific schedule. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN Date COMMENT 'The specific calendar date this schedule applies to. The MarketCalendar function always writes 7 days (today + 6). The bulk SP deletes all existing rows for these dates before inserting. Clustered index column for range queries. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN IsOpen COMMENT 'Whether trading is open on this date. 0 = closed (holiday, weekend), 1 = open. When 0, OpenTime/CloseTime may still be populated but are not used. When IsManual=1, this is directly controlled by dealers. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN OpenTime COMMENT 'Market open time in local timezone. For HasDailyBreak=0 middle/close days, uses sentinel 1753-01-01 00:00:00 (datetime min). (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN CloseTime COMMENT 'Market close time in local timezone. For HasDailyBreak=0 open/middle days, uses sentinel 9999-12-31 23:59:59.997 (datetime max). (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN OpenTimeUTC COMMENT 'Market open time in UTC. Used by MarketHours Service for setting enable timers. DST-adjusted via timezone tables. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN CloseTimeUTC COMMENT 'Market close time in UTC. Used by MarketHours Service for setting disable timers. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN DeltaOpenMins COMMENT 'Legacy minute-level open time offset. Populated by SetMergedDailySchedulesBulk (minutes variant). NULL when populated by the seconds variant. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN DeltaCloseMins COMMENT 'Legacy minute-level close time offset. NULL when populated by seconds variant. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN IsManual COMMENT 'Whether this entry was manually configured. 1 = dealers control instrument state directly via CM; 0 = automated from provider/default data. In CM Calendar Configuration view: red rows indicate manual entries. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN HasDailyBreak COMMENT 'Whether the trading session breaks daily. 1 = standard daily open/close, times apply per-day. 0 = continuous session spanning multiple days, uses min/max datetime sentinels for intermediate days. In CM: yellow rows indicate no daily break. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN DeltaOpenSecs COMMENT 'Seconds-precision open time offset. Populated by SetMergedDailySchedulesDeltaSecondsBulk (current primary path). (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN DeltaCloseSecs COMMENT 'Seconds-precision close time offset. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN ValidFrom COMMENT 'Temporal ROW START (named ValidFrom instead of SysStartTime). Auto-set on insert/update. (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_mergeddailyschedules ALTER COLUMN ValidTo COMMENT 'Temporal ROW END. History retained for 6 months in History.MergedDailySchedules (HISTORY_RETENTION_PERIOD = 6 MONTH). (Tier 1 - upstream wiki, CalendarDB.Market.MergedDailySchedules)';

