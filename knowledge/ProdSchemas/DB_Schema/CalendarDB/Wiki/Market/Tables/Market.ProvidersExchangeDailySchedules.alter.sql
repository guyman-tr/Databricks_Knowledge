-- =============================================================================
-- Databricks ALTER Script: bronze CalendarDB.Market.ProvidersExchangeDailySchedules
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/CalendarDB/Wiki/Market/Tables/Market.ProvidersExchangeDailySchedules.md
-- Layer: bronze
-- UC Target: main.general.bronze_calendardb_market_providersexchangedailyschedules
-- =============================================================================

-- ---- UC Target: main.general.bronze_calendardb_market_providersexchangedailyschedules (business_group=general) ----
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules SET TBLPROPERTIES (
    'comment' = 'Stores daily exchange-level trading schedules from both external providers (Xignite, ProviderID=1) and eToro manual overrides (ProviderID=0), used as input to the merged schedule calculation. Source: CalendarDB.Market.ProvidersExchangeDailySchedules on the CalendarDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/CalendarDB/Wiki/Market/Tables/Market.ProvidersExchangeDailySchedules.md).'
);

ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'CalendarDB',
    'source_schema' = 'Market',
    'source_table' = 'ProvidersExchangeDailySchedules',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN ID COMMENT 'Auto-increment surrogate primary key. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN LogTime COMMENT 'Timestamp when this row was inserted (GETDATE() in SP). (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN ProviderID COMMENT 'Calendar data provider. 0 = eToro overrides (from CM), 1 = Xignite (from ProvideCalendar function). Determines merge precedence: 0 > 1. Implicit FK to CalenderProviders. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN ExchangeID COMMENT 'eToro internal exchange identifier. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN Date COMMENT 'Calendar date. Clustered index for efficient date-range queries. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN IsOpen COMMENT 'Whether the exchange is open on this date per this provider/override. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN OpenTime COMMENT 'Exchange open time in local timezone. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN CloseTime COMMENT 'Exchange close time in local timezone. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN OpenTimeUTC COMMENT 'Exchange open time in UTC. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN CloseTimeUTC COMMENT 'Exchange close time in UTC. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN DeltaOpenMins COMMENT 'Minute-level open time offset. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN DeltaCloseMins COMMENT 'Minute-level close time offset. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN DeltaOpenSecs COMMENT 'Seconds-precision open time offset. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN DeltaCloseSecs COMMENT 'Seconds-precision close time offset. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN DbLoginName COMMENT 'Computed audit: SQL Server login. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN AppLoginName COMMENT 'Computed audit: application session identity. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN SysStartTime COMMENT 'Temporal ROW START. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';
ALTER TABLE main.general.bronze_calendardb_market_providersexchangedailyschedules ALTER COLUMN SysEndTime COMMENT 'Temporal ROW END. History in History.ProvidersExchangeDailySchedules. (Tier 1 - upstream wiki, CalendarDB.Market.ProvidersExchangeDailySchedules)';

