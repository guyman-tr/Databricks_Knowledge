# CalendarDB Glossary

> Business terms, abbreviations, and domain concepts used across CalendarDB schemas.
> Built from schema analysis (no Dictionary schema exists in CalendarDB).

---

## Market / Trading Calendar Domain

| Term | Definition | Used By |
|------|-----------|---------|
| **Exchange** | A financial exchange or market venue where instruments are traded. Identified by ExchangeID (integer, sourced from external master data). | Most Market schema tables |
| **Instrument** | A tradable financial instrument (stock, crypto, commodity, etc.). Identified by InstrumentID (integer, sourced from external master data). | DefaultWeeklyCalendars, MergedDailySchedules, InstrumentTimeZones, ProvidersInstrumentDailySchedules |
| **Provider** | A calendar data provider - an external source that supplies exchange/instrument trading schedule data. Identified by ProviderID. | CalenderProviders, CalendarProviderExchanges, ProvidersExchangeDailySchedules, ProvidersInstrumentDailySchedules, HaltConfiguration |
| **Daily Schedule** | A record defining whether an exchange/instrument is open or closed on a specific date, including open/close times in local and UTC. | MergedDailySchedules, ProvidersExchangeDailySchedules, ProvidersInstrumentDailySchedules |
| **Merged Schedule** | The final, consolidated daily schedule produced by merging data from multiple providers. The authoritative trading calendar. | MergedDailySchedules, MergedDailySchedules_ss |
| **Weekly Calendar** | A recurring weekly template defining default open/close times per day-of-week for an exchange or instrument. | DefaultWeeklyCalendars |
| **Delta (Open/Close)** | The offset adjustment applied to open or close times, in minutes (DeltaOpenMins/DeltaCloseMins) or seconds (DeltaOpenSecs/DeltaCloseSecs). Used to fine-tune schedule boundaries. | DefaultWeeklyCalendars, MergedDailySchedules, ProvidersExchangeDailySchedules, ProvidersInstrumentDailySchedules |
| **Halt Configuration** | Configuration defining trading halt rules per exchange/instrument and provider/account combination. | HaltConfiguration |
| **ConfigurationIdType** | An integer type classifier for HaltConfiguration records, indicating whether the ID column refers to an ExchangeID, InstrumentID, or other entity type. | HaltConfiguration |
| **IsManual** | Boolean flag indicating a schedule entry was manually overridden rather than sourced from a provider. | DefaultWeeklyCalendars, MergedDailySchedules |
| **HasDailyBreak** | Boolean flag indicating whether a trading session has an intraday break (e.g., lunch break in Asian markets). | DefaultWeeklyCalendars, MergedDailySchedules |
| **System Versioning (Temporal)** | SQL Server temporal table feature. Most Market tables use SYSTEM_VERSIONING with corresponding History schema tables to track all changes over time. | Most Market tables |
| **Pure Provider Schedule** | Raw, unprocessed exchange schedule data from a single provider source before merging. | PureProvidersExchangeDailySchedules |

---

## Abbreviations

| Abbreviation | Meaning |
|-------------|---------|
| **UTC** | Coordinated Universal Time |
| **SP** | Stored Procedure |
| **UDT** | User Defined Type (table-valued parameter type) |
| **TVP** | Table-Valued Parameter (same as UDT in this context) |
| **FK** | Foreign Key |
| **PK** | Primary Key |
| **ss** | Snapshot (as in MergedDailySchedules_ss) |
