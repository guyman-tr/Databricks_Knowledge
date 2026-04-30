# Market.DefaultWeeklyCalendars

> Configuration table storing default weekly trading schedules (open/close times per day-of-week) for exchanges and instruments, set by eToro dealers via Configuration Manager.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

This table holds the default weekly market hours configurations made by eToro dealers. Each row defines a recurring trading schedule for a specific exchange (or instrument within an exchange), specifying which days of the week it applies to and the local open/close times. These are the baseline "fallback" schedules used when no provider data or manual override exists for a given date.

This table is critical because it defines the complete universe of exchanges and instruments that the market hours system supports. Per Confluence: "Must be configured for ALL exchanges/instruments that we want market hours to support." If an exchange/instrument is not configured here, it will not have any trading schedule in the system.

Data is written by dealers via the Configuration Manager's "Edit Defaults" screen. The MarketCalendar Azure Function reads this table to build default schedules, which are then merged with provider data and overrides. Defaults have the lowest merge precedence: override > provider > instrument default > exchange default. Note that instrument-specific defaults are stronger than exchange-level provider data. Currently contains 5,931 entries.

---

## 2. Business Logic

### 2.1 Day-of-Week Schedule Model

**What**: Schedules are defined as day-of-week ranges (e.g., Monday through Friday) with specific open/close times.

**Columns/Parameters Involved**: `StartDayOfWeek`, `EndDayOfWeek`, `OpenTime`, `CloseTime`

**Rules**:
- Day-of-week encoding: Sunday=0, Monday=1, Tuesday=2, ... Saturday=6
- Most standard exchanges use StartDayOfWeek=1, EndDayOfWeek=5 (Monday-Friday)
- An exchange can have multiple rows for the same day range to represent multiple trading sessions (e.g., Hong Kong exchange 21 has a morning session 09:30-12:00 and afternoon session 13:00-16:00)
- OpenTime and CloseTime are in the exchange/instrument's local timezone

### 2.2 Exchange vs Instrument Defaults

**What**: Defaults can be set at exchange level (apply to all instruments on that exchange) or instrument level (override the exchange default for a specific instrument).

**Columns/Parameters Involved**: `ExchangeID`, `InstrumentID`

**Rules**:
- When InstrumentID IS NULL: the row is an exchange-level default applying to all instruments on that exchange, EXCEPT instruments that have their own explicit configuration
- When InstrumentID IS NOT NULL: the row is an instrument-specific default that overrides the exchange-level default for that instrument
- Per Confluence: instrument default configuration is stronger than exchange provider data in the merge precedence

### 2.3 HasDailyBreak and Continuous Sessions

**What**: Controls whether open/close times apply per-day or span continuously across the day range.

**Columns/Parameters Involved**: `HasDailyBreak`, `OpenTime`, `CloseTime`

**Rules**:
- HasDailyBreak = 1 (true): Open/close times apply independently to each day within the StartDayOfWeek-EndDayOfWeek range. Each day opens and closes at the specified times.
- HasDailyBreak = 0 (false): The trading session spans continuously. In the database, the open day stores open=OpenTime close=max, middle days store open=min close=max, close day stores open=min close=CloseTime.

### 2.4 Delta Adjustments

**What**: Fine-tune open/close times with minute or second offsets.

**Columns/Parameters Involved**: `DeltaOpenMins`, `DeltaCloseMins`, `DeltaOpenSecs`, `DeltaCloseSecs`

**Rules**:
- DeltaOpenMins/DeltaCloseMins: legacy whole-minute offsets (default 0)
- DeltaOpenSecs/DeltaCloseSecs: newer sub-second precision offsets
- Both pairs shift the effective open/close time relative to the base OpenTime/CloseTime
- Common pattern: DeltaCloseMins=1 or DeltaCloseSecs=60 to extend close by 1 minute (seen in many European exchanges)

---

## 3. Data Overview

| ID | ExchangeID | InstrumentID | StartDayOfWeek | EndDayOfWeek | OpenTime | CloseTime | IsManual | HasDailyBreak | Meaning |
|---|---|---|---|---|---|---|---|---|---|
| 20 | 18 | NULL | 1 | 5 | 09:30 | 15:59 | 0 | 1 | Exchange 18, Mon-Fri, opens 09:30 closes 15:59 local time. Standard daily schedule with intraday break support. Exchange-level default (no specific instrument). |
| 39 | 21 | NULL | 1 | 5 | 09:30 | 12:00 | 0 | 1 | Hong Kong exchange (21), morning session Mon-Fri 09:30-12:00. First of two daily sessions (has intraday break). |
| 40 | 21 | NULL | 1 | 5 | 13:00 | 16:00 | 0 | 1 | Hong Kong exchange (21), afternoon session Mon-Fri 13:00-16:00. Second session after lunch break - demonstrates multi-session-per-day pattern. |
| 29 | 14 | NULL | 1 | 5 | 09:00 | 16:20 | 0 | 1 | Oslo exchange (14, XOSL), Mon-Fri 09:00-16:20 with 1 minute delta close offset. |
| 41 | 17 | NULL | 1 | 5 | 10:00 | 18:25 | 0 | 1 | Helsinki exchange (17, XHEL), Mon-Fri 10:00-18:25 with 1 minute delta close. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-increment surrogate primary key. No business meaning. |
| 2 | ExchangeID | int | NO | - | VERIFIED | eToro internal exchange identifier. Determines which exchange this schedule applies to. Maps to ExchangeTimeZones for timezone resolution. Every exchange that should have market hours MUST have at least one row here. |
| 3 | InstrumentID | int | YES | - | VERIFIED | eToro internal instrument identifier. NULL = exchange-level default (applies to all instruments on this exchange except those with explicit instrument configs). Non-NULL = instrument-specific override of the exchange default. Per Confluence: "If null - the row is relevant for all instruments in the exchange, except for instruments with explicit configurations." |
| 4 | StartDayOfWeek | int | NO | - | VERIFIED | First day of the week range this schedule applies to. Sunday=0, Monday=1, Tuesday=2, Wednesday=3, Thursday=4, Friday=5, Saturday=6. Most entries use 1 (Monday). |
| 5 | EndDayOfWeek | int | NO | - | VERIFIED | Last day of the week range. Most entries use 5 (Friday) for standard Mon-Fri trading. |
| 6 | OpenTime | time(7) | NO | - | CODE-BACKED | Market open time in the exchange/instrument's local timezone. Combined with StartDayOfWeek to determine when trading begins. |
| 7 | CloseTime | time(7) | NO | - | CODE-BACKED | Market close time in the exchange/instrument's local timezone. Combined with EndDayOfWeek to determine when trading ends. |
| 8 | DeltaOpenMins | int | NO | 0 | CODE-BACKED | Offset adjustment to open time in whole minutes. 0 = no adjustment. Legacy field - DeltaOpenSecs provides finer precision. |
| 9 | DeltaCloseMins | int | NO | 0 | CODE-BACKED | Offset adjustment to close time in whole minutes. Common value: 1 (extend close by 1 minute). Legacy field. |
| 10 | IsManual | bit | NO | 0 | VERIFIED | Whether this schedule entry is for a manually-controlled instrument. When 1, the IsOpen, OpenTime, CloseTime are set manually by dealers and the instrument state is managed directly rather than by timers. In CM: red-highlighted rows indicate manual entries. |
| 11 | HasDailyBreak | bit | NO | 1 | VERIFIED | Whether the session breaks at end of each day. When 1, times apply per-day. When 0, session spans continuously across the day range using min/max datetime sentinels. In CM: yellow-highlighted rows indicate no daily break. |
| 12 | DeltaOpenSecs | decimal(8,3) | YES | - | CODE-BACKED | Fine-grained offset to open time in seconds with millisecond precision. Supersedes DeltaOpenMins for sub-minute adjustments. |
| 13 | DeltaCloseSecs | decimal(8,3) | YES | - | CODE-BACKED | Fine-grained offset to close time in seconds. Supersedes DeltaCloseMins. Common value: 60.000 (1 minute extension). |
| 14 | DbLoginName | computed(suser_name()) | NO | - | CODE-BACKED | Computed audit column: SQL Server login name. |
| 15 | AppLoginName | computed(CONVERT(varchar(500),context_info())) | NO | - | CODE-BACKED | Computed audit column: application session identity. |
| 16 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | Temporal ROW START. |
| 17 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | Temporal ROW END. History in History.DefaultWeeklyCalendars. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExchangeID | Market.ExchangeTimeZones | Implicit FK | Exchange timezone used for local-to-UTC conversion |
| InstrumentID | Market.InstrumentTimeZones | Implicit FK | Instrument-specific timezone override (when exists) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MarketCalendar Azure Function | N/A | Read | Reads defaults as the lowest-precedence source for merged schedule calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MarketCalendar Azure Function | External Service | Reads all defaults for the weekly schedule merge |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MarketDefaultWeeklyCalenders | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_DefaultWeeklyCalendars_DeltaOpenMins | DEFAULT | 0 for DeltaOpenMins |
| DF_DefaultWeeklyCalendars_DeltaCloseMins | DEFAULT | 0 for DeltaCloseMins |
| DF_MarketDefaultWeeklyCalendars_IsManual | DEFAULT | 0 for IsManual (non-manual by default) |
| (unnamed) | DEFAULT | 1 for HasDailyBreak (daily break by default) |
| DF_DefaultWeeklyCalendars_SysStart | DEFAULT | getutcdate() for SysStartTime |
| DF_DefaultWeeklyCalendars_SysEnd | DEFAULT | '9999-12-31 23:59:59.9999999' for SysEndTime |

**Trigger**: `TRG_T_DefaultWeeklyCalendars` - fires FOR INSERT. Self-referential UPDATE for temporal audit.

---

## 8. Sample Queries

### 8.1 Find default schedule for a specific exchange

```sql
SELECT ExchangeID, InstrumentID, StartDayOfWeek, EndDayOfWeek,
       OpenTime, CloseTime, DeltaOpenSecs, DeltaCloseSecs, IsManual, HasDailyBreak
FROM Market.DefaultWeeklyCalendars WITH (NOLOCK)
WHERE ExchangeID = 4 AND InstrumentID IS NULL
ORDER BY StartDayOfWeek, OpenTime;
```

### 8.2 Find instrument-specific overrides

```sql
SELECT ExchangeID, InstrumentID, StartDayOfWeek, EndDayOfWeek,
       OpenTime, CloseTime, IsManual
FROM Market.DefaultWeeklyCalendars WITH (NOLOCK)
WHERE InstrumentID IS NOT NULL
ORDER BY ExchangeID, InstrumentID;
```

### 8.3 Find exchanges with multiple daily sessions (e.g., Asian markets with lunch break)

```sql
SELECT ExchangeID, COUNT(*) AS SessionCount
FROM Market.DefaultWeeklyCalendars WITH (NOLOCK)
WHERE InstrumentID IS NULL AND StartDayOfWeek = 1 AND EndDayOfWeek = 5
GROUP BY ExchangeID
HAVING COUNT(*) > 1
ORDER BY SessionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | "Default market hours for all exchanges/instruments (weaker than provider/overrides)." Written by CM, read by MarketCalendar function. Must be configured for ALL exchanges/instruments. Yellow=no daily break, Red=manual in CM. |
| [DB (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11766628406) | Confluence | "Market Hours Configuration that were made by eToro dealers. InstrumentID - Optional. If null - the row is relevant for all instruments in the exchange, except for instruments with explicit configurations. StartDayOfWeek / EndDayOfWeek - Sunday=0, Monday=1 etc." |
| [Database tables and Logic](https://etoro-jira.atlassian.net/wiki/spaces/view/12185961371) | Confluence | "The defaults are configured for an entire week for each day of the week, not for a specific date. Each instrument which has market hours has a default configuration. The IsManual and HasDailyBreak for the overrides is taken from the defaults table." |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.DefaultWeeklyCalendars | Type: Table | Source: CalendarDB/CalendarDB/Market/Tables/Market.DefaultWeeklyCalendars.sql*
