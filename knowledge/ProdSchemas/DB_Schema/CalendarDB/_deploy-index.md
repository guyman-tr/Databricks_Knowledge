---

## bronze: CalendarDB

db_key: DB_Schema/CalendarDB
total_deployable: 3
generated: 0
failed: 0
deployed: 3
last_generated: "2026-04-30"
last_deploy_batch: 1
last_deployed: "2026-05-03"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Market.MergedDailySchedules](Wiki/Market/Tables/Market.MergedDailySchedules.md) | `main.general.bronze_calendardb_market_mergeddailyschedules` | Deployed (Batch 1) - 2026-04-30 |
| [Market.ProvidersExchangeDailySchedules](Wiki/Market/Tables/Market.ProvidersExchangeDailySchedules.md) | `main.general.bronze_calendardb_market_providersexchangedailyschedules` | Deployed (Batch 1) - 2026-04-30 |
| [Market.DefaultWeeklyCalendars](Wiki/Market/Tables/Market.DefaultWeeklyCalendars.md) | `main.dealing.bronze_calendardb_market_defaultweeklycalendars` | Deployed (Batch 1) - 2026-05-03 |
