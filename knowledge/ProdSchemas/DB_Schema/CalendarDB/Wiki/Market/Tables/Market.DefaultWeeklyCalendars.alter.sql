-- =============================================================================
-- Databricks ALTER Script: bronze CalendarDB.Market.DefaultWeeklyCalendars
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/CalendarDB/Wiki/Market/Tables/Market.DefaultWeeklyCalendars.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_calendardb_market_defaultweeklycalendars
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_calendardb_market_defaultweeklycalendars (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars SET TBLPROPERTIES (
    'comment' = 'Configuration table storing default weekly trading schedules (open/close times per day-of-week) for exchanges and instruments, set by eToro dealers via Configuration Manager. Source: CalendarDB.Market.DefaultWeeklyCalendars on the CalendarDB production database, ingested via the Generic Pipeline (Override strategy, 30-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/CalendarDB/Wiki/Market/Tables/Market.DefaultWeeklyCalendars.md).'
);

ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'CalendarDB',
    'source_schema' = 'Market',
    'source_table' = 'DefaultWeeklyCalendars',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '30'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN ID COMMENT 'Auto-increment surrogate primary key. No business meaning. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN ExchangeID COMMENT 'eToro internal exchange identifier. Determines which exchange this schedule applies to. Maps to ExchangeTimeZones for timezone resolution. Every exchange that should have market hours MUST have at least one row here. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN InstrumentID COMMENT 'eToro internal instrument identifier. NULL = exchange-level default (applies to all instruments on this exchange except those with explicit instrument configs). Non-NULL = instrument-specific override of the exchange default. Per Confluence: "If null - the row is relevant for all instruments in the exchange, except for instruments with explicit configurations." (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN StartDayOfWeek COMMENT 'First day of the week range this schedule applies to. Sunday=0, Monday=1, Tuesday=2, Wednesday=3, Thursday=4, Friday=5, Saturday=6. Most entries use 1 (Monday). (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN EndDayOfWeek COMMENT 'Last day of the week range. Most entries use 5 (Friday) for standard Mon-Fri trading. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN OpenTime COMMENT 'Market open time in the exchange/instrument''s local timezone. Combined with StartDayOfWeek to determine when trading begins. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN CloseTime COMMENT 'Market close time in the exchange/instrument''s local timezone. Combined with EndDayOfWeek to determine when trading ends. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN DeltaOpenMins COMMENT 'Offset adjustment to open time in whole minutes. 0 = no adjustment. Legacy field - DeltaOpenSecs provides finer precision. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN DeltaCloseMins COMMENT 'Offset adjustment to close time in whole minutes. Common value: 1 (extend close by 1 minute). Legacy field. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN IsManual COMMENT 'Whether this schedule entry is for a manually-controlled instrument. When 1, the IsOpen, OpenTime, CloseTime are set manually by dealers and the instrument state is managed directly rather than by timers. In CM: red-highlighted rows indicate manual entries. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN HasDailyBreak COMMENT 'Whether the session breaks at end of each day. When 1, times apply per-day. When 0, session spans continuously across the day range using min/max datetime sentinels. In CM: yellow-highlighted rows indicate no daily break. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN DeltaOpenSecs COMMENT 'Fine-grained offset to open time in seconds with millisecond precision. Supersedes DeltaOpenMins for sub-minute adjustments. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN DeltaCloseSecs COMMENT 'Fine-grained offset to close time in seconds. Supersedes DeltaCloseMins. Common value: 60.000 (1 minute extension). (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN DbLoginName COMMENT 'Computed audit column: SQL Server login name. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN AppLoginName COMMENT 'Computed audit column: application session identity. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN SysStartTime COMMENT 'Temporal ROW START. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';
ALTER TABLE main.dealing.bronze_calendardb_market_defaultweeklycalendars ALTER COLUMN SysEndTime COMMENT 'Temporal ROW END. History in History.DefaultWeeklyCalendars. (Tier 1 - upstream wiki, CalendarDB.Market.DefaultWeeklyCalendars)';

