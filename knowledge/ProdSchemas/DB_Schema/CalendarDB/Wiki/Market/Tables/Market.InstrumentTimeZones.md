# Market.InstrumentTimeZones

> Configuration table mapping specific instruments to their local timezone, overriding the exchange-level timezone when an instrument trades in a different timezone than its parent exchange.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

This table stores instrument-specific timezone overrides. Most instruments inherit their timezone from the exchange they belong to (via Market.ExchangeTimeZones), but some instruments trade in a timezone different from their parent exchange. For example, an ETF listed on a US exchange that tracks a Hong Kong index may have its trading hours defined in Hong Kong time.

Without this table, all instruments on a given exchange would share the same timezone, making it impossible to correctly schedule instruments whose effective trading hours are driven by a different market's timezone.

Data is configured through Configuration Manager (CM) by eToro dealers. Currently contains 15 instrument-level timezone overrides. The ProvideCalendar and MarketCalendar Azure Functions check this table for instrument-specific timezones; if no entry exists for an instrument, the exchange-level timezone from Market.ExchangeTimeZones is used as fallback.

---

## 2. Business Logic

### 2.1 Instrument Timezone Override Hierarchy

**What**: Instrument timezones override exchange timezones for specific instruments.

**Columns/Parameters Involved**: `InstrumentID`, `TimeZone`

**Rules**:
- If InstrumentID exists in this table, its timezone is used for local-to-UTC conversion
- If InstrumentID does NOT exist here, the exchange-level timezone from ExchangeTimeZones applies
- This enables instruments like indices or ETFs to have timezone-appropriate schedule calculations even when listed on a different exchange

---

## 3. Data Overview

| InstrumentID | TimeZone | Meaning |
|---|---|---|
| 25 | Eastern Standard Time | Instrument 25 trades on US Eastern time, likely a US-listed instrument that needs its own timezone assignment rather than inheriting from its parent exchange. |
| 26 | North Asia East Standard Time | Instrument 26 uses Irkutsk/East Asia timezone (UTC+8). Likely an instrument tracking an Asian market (e.g., China/Hong Kong index) that needs Asian trading hours despite being on a non-Asian exchange. |
| 33 | AUS Eastern Standard Time | Instrument 33 uses Australian Eastern timezone. Likely an Australian market tracker needing AEST/AEDT schedule calculations. |
| 36 | Yakutsk Standard Time | Instrument 36 uses Yakutsk timezone (UTC+9). Likely an instrument tracking the Japanese market (Tokyo Standard Time). |
| 458 | GMT Standard Time | Instrument 458 uses UK timezone. A recently added override (2025-12-17) for an instrument that needs UK-aligned schedule. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | Primary key. eToro internal instrument identifier from the main etoro database (Trade.InstrumentMetaData). Each instrument can have at most one timezone override. If absent, the instrument inherits its exchange's timezone from Market.ExchangeTimeZones. |
| 2 | TimeZone | varchar(1000) | NO | - | VERIFIED | Windows timezone identifier string compatible with .NET TimeZoneInfo. Same format as ExchangeTimeZones.TimeZone. Used by ProvideCalendar and MarketCalendar functions for instrument-specific local-to-UTC conversion with DST handling. |
| 3 | DbLoginName | computed(suser_name()) | NO | - | CODE-BACKED | Computed audit column capturing the SQL Server login of the session that last modified this row. |
| 4 | AppLoginName | computed(CONVERT(varchar(500),context_info())) | NO | - | CODE-BACKED | Computed audit column capturing the application context info (session GUID). |
| 5 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | Temporal ROW START. UTC timestamp when this timezone override became active. |
| 6 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | Temporal ROW END. 9999-12-31 for active records. History in History.InstrumentTimeZones. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.DefaultWeeklyCalendars | InstrumentID | Implicit FK | Instruments with timezone overrides may also have specific weekly default schedules |
| Market.MergedDailySchedules | InstrumentID | Implicit FK | Merged schedules for these instruments use the overridden timezone |
| Market.ProvidersInstrumentDailySchedules | InstrumentID | Implicit FK | Provider instrument schedules reference these instrument IDs |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ProvideCalendar Azure Function | External Service | Reads instrument timezone for instrument-specific UTC conversion |
| MarketCalendar Azure Function | External Service | Reads instrument timezone for merge calculations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| pk_instrumentTimeZones | CLUSTERED PK | InstrumentID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_InstrumentTimeZones_SysStart | DEFAULT | getutcdate() for SysStartTime |
| DF_InstrumentTimeZones_SysEnd | DEFAULT | '9999-12-31 23:59:59.9999999' for SysEndTime |

**Trigger**: `TRG_T_InstrumentTimeZones` - fires FOR INSERT. Self-referential UPDATE to force temporal versioning audit on INSERT.

---

## 8. Sample Queries

### 8.1 List all instrument timezone overrides

```sql
SELECT InstrumentID, TimeZone
FROM Market.InstrumentTimeZones WITH (NOLOCK)
ORDER BY InstrumentID;
```

### 8.2 Find instruments with timezone different from their exchange

```sql
SELECT itz.InstrumentID, itz.TimeZone AS InstrumentTZ, etz.TimeZone AS ExchangeTZ
FROM Market.InstrumentTimeZones itz WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 dwc.ExchangeID
    FROM Market.DefaultWeeklyCalendars dwc WITH (NOLOCK)
    WHERE dwc.InstrumentID = itz.InstrumentID
) x
JOIN Market.ExchangeTimeZones etz WITH (NOLOCK) ON x.ExchangeID = etz.ExchangeID
WHERE itz.TimeZone <> etz.TimeZone;
```

### 8.3 View timezone override change history

```sql
SELECT InstrumentID, TimeZone, SysStartTime, SysEndTime
FROM Market.InstrumentTimeZones
FOR SYSTEM_TIME ALL
WHERE InstrumentID = 458
ORDER BY SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | "To tell in which timezone instruments are in provider." Written by CM, read by ProvideCalendar and MarketCalendar functions. |
| [DB (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11766628406) | Confluence | "Holds timezones of exchanges / instruments. Used when calculating market hours. Data is configured from Tradonomi Configuration Manager." |
| [Database tables and Logic](https://etoro-jira.atlassian.net/wiki/spaces/view/12185961371) | Confluence | "SELECT InstrumentID,TimeZone FROM Market.InstrumentTimeZones WITH (NOLOCK)" - confirms read pattern |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.InstrumentTimeZones | Type: Table | Source: CalendarDB/CalendarDB/Market/Tables/Market.InstrumentTimeZones.sql*
