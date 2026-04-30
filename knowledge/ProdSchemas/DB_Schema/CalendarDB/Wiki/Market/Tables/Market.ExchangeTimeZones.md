# Market.ExchangeTimeZones

> Configuration table mapping each exchange to its local timezone, used for converting provider-reported local trading hours to UTC.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Table |
| **Key Identifier** | ExchangeID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

This table stores the timezone assignment for each exchange in the market hours system. When the ProvideCalendar Azure Function receives trading hours from Xignite (which reports times in the exchange's local timezone), it needs to convert those times to UTC for storage and timer calculations. This table provides the timezone identifier needed for that conversion.

Without this table, the system could not correctly convert local trading hours to UTC, and the MarketHours Service would set incorrect enable/disable timers for instruments. This is especially critical because daylight saving time shifts the UTC offset seasonally - the timezone name (not a fixed offset) is stored so that .NET's timezone conversion library handles DST transitions automatically.

Data is configured through Configuration Manager (CM) by eToro dealers. The table is read by both the ProvideCalendar Azure Function (for converting provider data to UTC) and the MarketCalendar Azure Function (for timezone-aware merge calculations). Currently contains 31 entries covering exchanges across Americas, Europe, Middle East, and Asia-Pacific.

---

## 2. Business Logic

### 2.1 Windows Timezone Identifiers

**What**: Timezone values use Windows timezone IDs (not IANA/Olson names), compatible with .NET's TimeZoneInfo class.

**Columns/Parameters Involved**: `TimeZone`

**Rules**:
- Values are Windows timezone identifiers (e.g., "Eastern Standard Time", "W. Europe Standard Time", "GMT Standard Time")
- These map to .NET's `TimeZoneInfo.FindSystemTimeZoneById()` for automatic DST handling
- "Eastern Standard Time" covers both EST (UTC-5) and EDT (UTC-4) depending on date
- Per Confluence: "Daylight saving time is not affecting the opening hours because they're in UTC" - meaning the conversion FROM local TO UTC accounts for DST, so the stored UTC times are always correct

### 2.2 Exchange vs Instrument Timezone Precedence

**What**: Exchange timezones apply to providers only; defaults and overrides have their own per-record timezone configuration.

**Columns/Parameters Involved**: `ExchangeID`, `TimeZone`

**Rules**:
- Per Confluence: Exchange timezones tell "in which timezone exchanges are in provider only"
- Default and override schedules have different timezone handling (per-record in DefaultWeeklyCalendars)
- If an instrument has a specific timezone in InstrumentTimeZones, it overrides the exchange-level timezone for that instrument

---

## 3. Data Overview

| ExchangeID | TimeZone | Meaning |
|---|---|---|
| 1 | Eastern Standard Time | US Eastern timezone (UTC-5/UTC-4). Used for crypto/commodities exchange. |
| 4 | Eastern Standard Time | NASDAQ (XNAS). US Eastern timezone for standard US stock market hours 09:30-16:00 ET. |
| 7 | GMT Standard Time | London Stock Exchange (XLON). UK timezone (UTC+0/UTC+1 BST). |
| 24 | Arabic Standard Time | Saudi Exchange/Tadawul (XSAU). UTC+3 (no DST). |
| 31 | AUS Eastern Standard Time | ASX Australia (XASX). Australian Eastern timezone (UTC+10/UTC+11 AEDT). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID | int | NO | - | VERIFIED | Primary key. eToro internal exchange identifier. Each exchange has exactly one timezone assignment. Maps to the same ExchangeID used in CalendarProviderExchanges, ProvidersExchangeDailySchedules, DefaultWeeklyCalendars, and MergedDailySchedules. |
| 2 | TimeZone | varchar(1000) | NO | - | VERIFIED | Windows timezone identifier string compatible with .NET TimeZoneInfo. Examples: "Eastern Standard Time" (US East Coast), "W. Europe Standard Time" (Western Europe CET/CEST), "GMT Standard Time" (UK), "Arabic Standard Time" (Saudi Arabia UTC+3), "AUS Eastern Standard Time" (Australia). Used by ProvideCalendar and MarketCalendar Azure Functions for local-to-UTC conversion with automatic DST handling. |
| 3 | DbLoginName | computed(suser_name()) | NO | - | CODE-BACKED | Computed audit column capturing the SQL Server login of the session that last modified this row. |
| 4 | AppLoginName | computed(CONVERT(varchar(500),context_info())) | NO | - | CODE-BACKED | Computed audit column capturing the application context info (session GUID) of the modifying service. |
| 5 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | Temporal ROW START. UTC timestamp when this timezone assignment became active. |
| 6 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | Temporal ROW END. 9999-12-31 for current/active records. History in History.ExchangeTimeZones. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.CalendarProviderExchanges | ExchangeID | Implicit FK | Registered provider exchanges should have timezone entries here |
| Market.ProvidersExchangeDailySchedules | ExchangeID | Implicit FK | Exchange schedules use this timezone for local-to-UTC conversion |
| Market.DefaultWeeklyCalendars | ExchangeID | Implicit FK | Default weekly schedules reference the exchange whose timezone applies |
| Market.MergedDailySchedules | ExchangeID | Implicit FK | Merged schedules carry the ExchangeID whose timezone was used for conversion |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ProvideCalendar Azure Function | External Service | Reads timezone to convert Xignite local times to UTC |
| MarketCalendar Azure Function | External Service | Reads timezone for merge calculations |
| Market.CalendarProviderExchanges | Table | Shares ExchangeID space |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| pk_ExchangeTimeZones | CLUSTERED PK | ExchangeID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_ExchangeTimeZones_SysStart | DEFAULT | getutcdate() for SysStartTime |
| DF_ExchangeTimeZones_SysEnd | DEFAULT | '9999-12-31 23:59:59.9999999' for SysEndTime |

---

## 8. Sample Queries

### 8.1 List all exchange timezone assignments

```sql
SELECT ExchangeID, TimeZone
FROM Market.ExchangeTimeZones WITH (NOLOCK)
ORDER BY ExchangeID;
```

### 8.2 Join exchanges with their provider MIC codes and timezones

```sql
SELECT cpe.ExchangeID, cpe.ExchangeName AS MICCode, etz.TimeZone
FROM Market.CalendarProviderExchanges cpe WITH (NOLOCK)
JOIN Market.ExchangeTimeZones etz WITH (NOLOCK) ON cpe.ExchangeID = etz.ExchangeID
ORDER BY cpe.ExchangeName;
```

### 8.3 Find exchanges in a specific timezone

```sql
SELECT ExchangeID, TimeZone
FROM Market.ExchangeTimeZones WITH (NOLOCK)
WHERE TimeZone = 'Eastern Standard Time'
ORDER BY ExchangeID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | "To tell in which timezone exchanges are in provider only, (defaults and overrides have different timezone per record)." Written by CM, read by ProvideCalendar and MarketCalendar functions. |
| [DB (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11766628406) | Confluence | "Holds timezones of exchanges / instruments. Used when calculating market hours. Data is configured from Tradonomi Configuration Manager." |
| [Database tables and Logic](https://etoro-jira.atlassian.net/wiki/spaces/view/12185961371) | Confluence | "SELECT ExchangeID,TimeZone FROM Market.ExchangeTimeZones WITH (NOLOCK)" - confirms read pattern used by MarketCalendar service |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.ExchangeTimeZones | Type: Table | Source: CalendarDB/CalendarDB/Market/Tables/Market.ExchangeTimeZones.sql*
