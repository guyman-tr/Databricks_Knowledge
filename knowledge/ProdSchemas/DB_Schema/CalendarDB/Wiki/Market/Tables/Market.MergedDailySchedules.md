# Market.MergedDailySchedules

> The authoritative, final market hours schedule table. Contains the merged result of defaults, provider data, and overrides for each exchange/instrument per date - the single source of truth for when instruments are open or closed for trading.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (1 NC PK + 2 NC) |

---

## 1. Business Meaning

This is the most important table in CalendarDB. It holds the final, consolidated market hours schedule - the result of merging default weekly configurations, external provider data (Xignite), and manual overrides into a single definitive calendar. Each row represents the trading schedule for one exchange/instrument on one specific date.

Without this table, the MarketHours Service would have no authoritative schedule to use for enabling/disabling instruments. The entire trading platform depends on this data to know when each instrument can be traded.

The MarketCalendar Azure Function calculates merged schedules by combining four sources in priority order: (1) eToro instrument overrides, (2) eToro exchange overrides, (3) Xignite provider data, (4) default weekly calendars. The function always recalculates for today + next 6 days. Data is bulk-inserted via `Market.SetMergedDailySchedulesDeltaSecondsBulk` (or the legacy `SetMergedDailySchedulesBulk`), which atomically deletes all existing rows for the affected dates and inserts the new merged result in a transaction.

The MarketHours Service loads this table on startup, sets timers for all open/close events, subscribes to RabbitMQ notifications (`Market.Calendar.Update`), and publishes instrument state changes to Price Server. The table uses system versioning with 6-month retention in `History.MergedDailySchedules`. Currently contains ~466K rows.

---

## 2. Business Logic

### 2.1 Merge Precedence

**What**: The four-source merge algorithm determines which schedule wins for each exchange/instrument/date.

**Columns/Parameters Involved**: `SourceProviderName`, `ExchangeID`, `InstrumentID`

**Rules**:
- Precedence (highest to lowest): InstrumentOverrides > ExchangeOverrides > ProviderCalendars (Xignite) > DefaultCalendars
- SourceProviderName records which source won: "eToro-Defaults", "Xignite", "eToro-Overrides"
- If an override exists for an exchange, Xignite data for that exchange is NOT used
- After all sources are merged, any missing exchanges/instruments (per the instrument-to-exchange mapping from Trade.InstrumentMetaData) are logged as warnings

**Diagram**:
```
[1] Instrument Overrides (ProviderID=0 in ProvidersInstrumentDailySchedules)
    ↓ if no instrument override
[2] Exchange Overrides (ProviderID=0 in ProvidersExchangeDailySchedules)
    ↓ if no exchange override
[3] Xignite Provider (ProviderID=1 in ProvidersExchangeDailySchedules)
    ↓ if no provider data
[4] Default Weekly Calendars (DefaultWeeklyCalendars)
    ↓
Result written to MergedDailySchedules
```

### 2.2 Continuous Session Sentinel Values

**What**: For instruments with HasDailyBreak=0, special sentinel datetime values indicate continuous multi-day sessions.

**Columns/Parameters Involved**: `OpenTime`, `CloseTime`, `OpenTimeUTC`, `CloseTimeUTC`, `HasDailyBreak`

**Rules**:
- Open day: OpenTime = actual open time, CloseTime = 9999-12-31 23:59:59.997 (max)
- Middle days: OpenTime = 1753-01-01 00:00:00 (min), CloseTime = 9999-12-31 23:59:59.997 (max)
- Close day: OpenTime = 1753-01-01 00:00:00 (min), CloseTime = actual close time
- This encoding allows the MarketHours Service to detect continuous sessions vs daily open/close

### 2.3 Atomic Date-Based Replacement

**What**: The SP deletes ALL existing rows for affected dates before inserting new merged data.

**Columns/Parameters Involved**: `Date`

**Rules**:
- `SetMergedDailySchedulesDeltaSecondsBulk` deletes WHERE Date IN (dates in TVP), then inserts
- This ensures no stale data remains when the merge recalculates
- Wrapped in a transaction - either all dates are updated or none are
- After update, `Market.Calendar.Update` RabbitMQ notification is published

---

## 3. Data Overview

| ID | SourceProviderName | ExchangeID | InstrumentID | Date | IsOpen | HasDailyBreak | Meaning |
|---|---|---|---|---|---|---|---|
| 14796603 | eToro-Defaults | 2 | 783 | 2026-04-17 | 1 | 0 | Instrument 783 on exchange 2, continuous session (no daily break). OpenTime is the session start, CloseTime is max sentinel value indicating the session continues past this day. Sourced from eToro's default weekly configuration. |
| 14796602 | eToro-Defaults | 2 | 783 | 2026-04-17 | 1 | 0 | Same instrument/date but the closing portion: OpenTime is min sentinel, CloseTime is the actual session end time (21:00 UTC). Two rows per day is common for continuous-session instruments. |
| 14796601 | eToro-Defaults | 3 | 687 | 2026-04-17 | 1 | 0 | Instrument 687 on exchange 3, another continuous-session instrument with eToro default schedule. |
| 14796599 | eToro-Defaults | 2 | 766 | 2026-04-17 | 1 | 1 | Instrument 766, daily break session. Single row per day with actual open and close times. HasDailyBreak=1 means standard daily open/close cycle. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-increment surrogate primary key. No business meaning - rows are identified by the composite of ExchangeID + InstrumentID + Date. |
| 2 | LogTime | datetime | NO | - | CODE-BACKED | Timestamp when this row was inserted, set to GETDATE() by the bulk insert SPs. Represents when the MarketCalendar function last calculated this schedule entry. |
| 3 | SourceProviderName | varchar(250) | YES | - | VERIFIED | Identifies which data source won the merge precedence for this entry. Known values: "eToro-Defaults" (from DefaultWeeklyCalendars), "Xignite" (from Xignite provider data), "eToro-Overrides" (from manual CM overrides). NULL should not occur in practice. |
| 4 | ExchangeID | int | NO | - | VERIFIED | eToro internal exchange identifier. Determines which exchange this schedule applies to. Maps to ExchangeTimeZones for timezone, CalendarProviderExchanges for MIC code. |
| 5 | InstrumentID | int | YES | - | VERIFIED | eToro internal instrument identifier. NULL = exchange-level schedule (applies to all instruments without specific entries). Non-NULL = instrument-specific schedule. |
| 6 | Date | date | NO | - | VERIFIED | The specific calendar date this schedule applies to. The MarketCalendar function always writes 7 days (today + 6). The bulk SP deletes all existing rows for these dates before inserting. Clustered index column for range queries. |
| 7 | IsOpen | bit | NO | - | VERIFIED | Whether trading is open on this date. 0 = closed (holiday, weekend), 1 = open. When 0, OpenTime/CloseTime may still be populated but are not used. When IsManual=1, this is directly controlled by dealers. |
| 8 | OpenTime | datetime | NO | - | VERIFIED | Market open time in local timezone. For HasDailyBreak=0 middle/close days, uses sentinel 1753-01-01 00:00:00 (datetime min). |
| 9 | CloseTime | datetime | NO | - | VERIFIED | Market close time in local timezone. For HasDailyBreak=0 open/middle days, uses sentinel 9999-12-31 23:59:59.997 (datetime max). |
| 10 | OpenTimeUTC | datetime | NO | - | VERIFIED | Market open time in UTC. Used by MarketHours Service for setting enable timers. DST-adjusted via timezone tables. |
| 11 | CloseTimeUTC | datetime | NO | - | VERIFIED | Market close time in UTC. Used by MarketHours Service for setting disable timers. |
| 12 | DeltaOpenMins | int | YES | - | CODE-BACKED | Legacy minute-level open time offset. Populated by SetMergedDailySchedulesBulk (minutes variant). NULL when populated by the seconds variant. |
| 13 | DeltaCloseMins | int | YES | - | CODE-BACKED | Legacy minute-level close time offset. NULL when populated by seconds variant. |
| 14 | IsManual | bit | NO | 0 | VERIFIED | Whether this entry was manually configured. 1 = dealers control instrument state directly via CM; 0 = automated from provider/default data. In CM Calendar Configuration view: red rows indicate manual entries. |
| 15 | HasDailyBreak | bit | NO | 1 | VERIFIED | Whether the trading session breaks daily. 1 = standard daily open/close, times apply per-day. 0 = continuous session spanning multiple days, uses min/max datetime sentinels for intermediate days. In CM: yellow rows indicate no daily break. |
| 16 | DeltaOpenSecs | decimal(8,3) | YES | - | CODE-BACKED | Seconds-precision open time offset. Populated by SetMergedDailySchedulesDeltaSecondsBulk (current primary path). |
| 17 | DeltaCloseSecs | decimal(8,3) | YES | - | CODE-BACKED | Seconds-precision close time offset. |
| 18 | ValidFrom | datetime2(7) | NO | sysutcdatetime() | CODE-BACKED | Temporal ROW START (named ValidFrom instead of SysStartTime). Auto-set on insert/update. |
| 19 | ValidTo | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | Temporal ROW END. History retained for 6 months in History.MergedDailySchedules (HISTORY_RETENTION_PERIOD = 6 MONTH). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExchangeID | Market.ExchangeTimeZones | Implicit FK | Exchange timezone used during merge calculation |
| InstrumentID | Market.InstrumentTimeZones | Implicit FK | Instrument timezone override (when applicable) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.SetMergedDailySchedulesBulk | N/A | WRITER | Bulk deletes + inserts for affected dates (minutes precision) |
| Market.SetMergedDailySchedulesDeltaSecondsBulk | N/A | WRITER | Bulk deletes + inserts for affected dates (seconds precision, primary path) |
| Market.GetMergedDailySchedulesFromDate | N/A | READER | Returns all schedules from a given date onward |
| MarketHours Service | N/A | READER | Loads on startup, subscribes to change notifications |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.SetMergedDailySchedulesBulk | Stored Procedure | WRITER - bulk delete + insert (minutes) |
| Market.SetMergedDailySchedulesDeltaSecondsBulk | Stored Procedure | WRITER - bulk delete + insert (seconds, primary) |
| Market.GetMergedDailySchedulesFromDate | Stored Procedure | READER - returns schedules from date |
| Market.MergedDailySchedules_ss | Table | Snapshot variant of this table |
| MarketHours Service | External Service | Primary consumer - loads schedules, sets timers |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MarketMergedDailySchedules | NC PK | ID | - | - | Active |
| IX_MergedDailySchedules_Date | CLUSTERED | Date | - | - | Active |
| IX_MergedDailySchedules_Date_InstrumentID | NC | Date | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF__MergedDai__IsMan__01142BA1 | DEFAULT | 0 for IsManual |
| (unnamed) | DEFAULT | 1 for HasDailyBreak |
| (unnamed) | DEFAULT | sysutcdatetime() for ValidFrom |
| (unnamed) | DEFAULT | 9999-12-31 for ValidTo |

**Temporal**: SYSTEM_VERSIONING ON, HISTORY_TABLE = History.MergedDailySchedules, HISTORY_RETENTION_PERIOD = 6 MONTH.

---

## 8. Sample Queries

### 8.1 Get upcoming schedules for an exchange

```sql
SELECT Date, ExchangeID, InstrumentID, IsOpen, OpenTimeUTC, CloseTimeUTC,
       SourceProviderName, IsManual, HasDailyBreak
FROM Market.MergedDailySchedules WITH (NOLOCK)
WHERE ExchangeID = 4 AND Date >= CAST(GETUTCDATE() AS date)
ORDER BY Date, InstrumentID;
```

### 8.2 Find closed days (holidays) for an exchange

```sql
SELECT Date, ExchangeID, InstrumentID, SourceProviderName
FROM Market.MergedDailySchedules WITH (NOLOCK)
WHERE ExchangeID = 5 AND IsOpen = 0 AND Date >= '2026-01-01'
ORDER BY Date;
```

### 8.3 Compare merged schedule sources

```sql
SELECT SourceProviderName, COUNT(*) AS EntryCount
FROM Market.MergedDailySchedules WITH (NOLOCK)
WHERE Date >= CAST(GETUTCDATE() AS date)
GROUP BY SourceProviderName
ORDER BY EntryCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | "The final, merged market hours. Result of MarketCalendar function. Based on DefaultWeeklyCalendars, ProviderExchangeDailySchedules, ProviderInstrumentDailySchedules." Written by MarketCalendar function, read by MarketHours Service. HasDailyBreak=false encoding: open=OpenTime close=max, middle=min/max, close=min/CloseTime. |
| [DB (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11766628406) | Confluence | "Holds summary of market hours configuration from all sources." |
| [Database tables and Logic](https://etoro-jira.atlassian.net/wiki/spaces/view/12185961371) | Confluence | Full merge algorithm: InstrumentOverrides -> ExchangeOverrides -> ProviderCalendars -> DefaultCalendars. SP SetMergedDailySchedulesDeltaSecondsBulk deletes dates then inserts. MarketCalendar publishes to RabbitMQ Market.Calendar.Update. MarketHours Service holds in-memory copy. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.6/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.MergedDailySchedules | Type: Table | Source: CalendarDB/CalendarDB/Market/Tables/Market.MergedDailySchedules.sql*
