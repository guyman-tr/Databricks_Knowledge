# Market Schema - CalendarDB

> Trading calendar and market schedule management. Stores exchange/instrument daily schedules from multiple providers, merges them into authoritative calendars, and manages halt configurations.

## Metrics

| Metric | Value |
|--------|-------|
| **Total Objects** | 23 |
| **Documented** | 23 (100%) |
| **Pending** | 0 |
| **Last Updated** | 2026-04-11 |

---

## User Defined Types (4)

| Object | Quality | Status |
|--------|---------|--------|
| [Market.MergedCalendarDeltaSecondsTable](User%20Defined%20Types/Market.MergedCalendarDeltaSecondsTable.md) | 8.8 | Done (Batch 1) |
| [Market.MergedCalendarTable](User%20Defined%20Types/Market.MergedCalendarTable.md) | 8.6 | Done (Batch 1) |
| [Market.ProviderExchangeCalendarTable](User%20Defined%20Types/Market.ProviderExchangeCalendarTable.md) | 8.4 | Done (Batch 1) |
| [Market.PureProviderExchangeCalendarTable](User%20Defined%20Types/Market.PureProviderExchangeCalendarTable.md) | 8.6 | Done (Batch 1) |

## Tables (11)

| Object | Quality | Status |
|--------|---------|--------|
| [Market.CalenderProviders](Tables/Market.CalenderProviders.md) | 6.9 | Done (Prior) |
| [Market.ExchangeTimeZones](Tables/Market.ExchangeTimeZones.md) | 9.0 | Done (Batch 1) |
| [Market.InstrumentTimeZones](Tables/Market.InstrumentTimeZones.md) | 9.0 | Done (Batch 1) |
| [Market.DefaultWeeklyCalendars](Tables/Market.DefaultWeeklyCalendars.md) | 9.4 | Done (Batch 1) |
| [Market.CalendarProviderExchanges](Tables/Market.CalendarProviderExchanges.md) | 7.5 | Done (Prior) |
| [Market.HaltConfiguration](Tables/Market.HaltConfiguration.md) | 9.4 | Done (Batch 1) |
| [Market.MergedDailySchedules](Tables/Market.MergedDailySchedules.md) | 9.6 | Done (Batch 1) |
| [Market.MergedDailySchedules_ss](Tables/Market.MergedDailySchedules_ss.md) | 7.2 | Done (Batch 1) |
| [Market.ProvidersExchangeDailySchedules](Tables/Market.ProvidersExchangeDailySchedules.md) | 9.0 | Done (Batch 1) |
| [Market.ProvidersInstrumentDailySchedules](Tables/Market.ProvidersInstrumentDailySchedules.md) | 8.8 | Done (Batch 1) |
| [Market.PureProvidersExchangeDailySchedules](Tables/Market.PureProvidersExchangeDailySchedules.md) | 8.6 | Done (Batch 1) |

## Views (0)

(none)

## Functions (0)

(none)

## Stored Procedures (8)

| Object | Quality | Status |
|--------|---------|--------|
| [Market.GetAllHaltConfigurations](Stored%20Procedures/Market.GetAllHaltConfigurations.md) | 8.4 | Done (Batch 1) |
| [Market.GetHaltConfigurationsByIdTypeAndId](Stored%20Procedures/Market.GetHaltConfigurationsByIdTypeAndId.md) | 8.4 | Done (Batch 1) |
| [Market.GetHaltConfigurationsByProviderAndAccount](Stored%20Procedures/Market.GetHaltConfigurationsByProviderAndAccount.md) | 8.4 | Done (Batch 1) |
| [Market.GetMergedDailySchedulesFromDate](Stored%20Procedures/Market.GetMergedDailySchedulesFromDate.md) | 8.2 | Done (Batch 1) |
| [Market.SetMergedDailySchedulesBulk](Stored%20Procedures/Market.SetMergedDailySchedulesBulk.md) | 8.6 | Done (Batch 1) |
| [Market.SetMergedDailySchedulesDeltaSecondsBulk](Stored%20Procedures/Market.SetMergedDailySchedulesDeltaSecondsBulk.md) | 9.0 | Done (Batch 1) |
| [Market.SetProviderExchangeCalendarBulk](Stored%20Procedures/Market.SetProviderExchangeCalendarBulk.md) | 8.8 | Done (Batch 1) |
| [Market.SetPureProviderExchangeCalendarBulk](Stored%20Procedures/Market.SetPureProviderExchangeCalendarBulk.md) | 8.6 | Done (Batch 1) |

## Synonyms (0)

(none)
