# Market.MergedCalendarDeltaSecondsTable

> Table-valued parameter type used to pass merged daily calendar schedule data (with delta in seconds precision) to the SetMergedDailySchedulesDeltaSecondsBulk stored procedure for bulk upsert into MergedDailySchedules.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | User Defined Type |
| **Key Identifier** | Composite: ExchangeID + InstrumentID + Date |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This UDT defines the shape of data passed to the `Market.SetMergedDailySchedulesDeltaSecondsBulk` stored procedure. It represents a batch of merged daily calendar entries - one row per exchange/instrument/date combination - carrying the final, consolidated trading schedule after the MarketCalendar Azure Function has merged defaults, provider data, and overrides.

Without this type, the bulk upsert procedure could not accept a table-valued parameter from the application layer. It serves as the contract between the MarketCalendar Azure Function (C#) and the database, ensuring type safety and enabling efficient set-based operations instead of row-by-row inserts.

The MarketCalendar Azure Function calculates the merged schedule for the upcoming 7 days, packages the results into this TVP structure, and calls `SetMergedDailySchedulesDeltaSecondsBulk` to atomically replace all schedule data for those dates. This is the seconds-precision variant - it uses `DeltaOpenSecs`/`DeltaCloseSecs` (decimal) instead of the older `DeltaOpenMins`/`DeltaCloseMins` (int) columns found in the companion `MergedCalendarTable` type.

---

## 2. Business Logic

### 2.1 Delta Seconds vs Delta Minutes Precision

**What**: This type provides sub-minute precision for open/close time adjustments, superseding the older minutes-based type.

**Columns/Parameters Involved**: `DeltaOpenSecs`, `DeltaCloseSecs`

**Rules**:
- DeltaOpenSecs and DeltaCloseSecs are decimal(8,3), allowing millisecond-level offset precision
- The older `MergedCalendarTable` type uses DeltaOpenMins/DeltaCloseMins (int) for minute-level precision
- The MarketCalendar function uses this seconds-precision variant as the primary path for updating MergedDailySchedules (per Confluence: "Updating Market.MergedDailySchedules table: SP [Market].[SetMergedDailySchedulesDeltaSecondsBulk]")

### 2.2 HasDailyBreak Semantics

**What**: Controls how open/close times span across multi-day sessions.

**Columns/Parameters Involved**: `HasDailyBreak`, `OpenTime`, `CloseTime`

**Rules**:
- When HasDailyBreak = 1 (true): open/close times apply to each individual day between start/end days
- When HasDailyBreak = 0 (false): the session spans continuously across days. In the DB: open day is saved as open=OpenTime close=max, middle days as open=min close=max, close day as open=min close=CloseTime
- The IsManual and HasDailyBreak values for overrides are inherited from the defaults table

---

## 3. Data Overview

N/A for User Defined Type. This type has no persisted data - it is used as a parameter shape for passing data to stored procedures.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SourceProviderName | varchar(250) | NO | - | CODE-BACKED | Name of the calendar data source that contributed this schedule entry. Known values: "eToro-Defaults" (from DefaultWeeklyCalendars), "Xignite" (from external provider via ProvideCalendar function), "eToro-Overrides" (manual overrides from CM with ProviderID=0). Written by MarketCalendar function during merge. |
| 2 | ExchangeID | int | NO | - | CODE-BACKED | eToro internal exchange identifier. Maps to an exchange in the main etoro database's Trade.InstrumentMetaData table. Used alongside InstrumentID to uniquely identify which market this schedule applies to. |
| 3 | InstrumentID | int | YES | - | CODE-BACKED | eToro internal instrument identifier. NULL when the schedule applies to the entire exchange (exchange-level schedule). Non-NULL when an instrument has a specific schedule that overrides the exchange default. Instrument-level config is stronger than exchange-level. |
| 4 | Date | date | NO | - | CODE-BACKED | The specific calendar date this schedule entry applies to. The MarketCalendar function always calculates schedules for today + next 6 days (7 days total). |
| 5 | IsOpen | bit | NO | - | CODE-BACKED | Whether the exchange/instrument is open for trading on this date. 0 = closed (holiday, weekend), 1 = open. When IsOpen = 0, OpenTime/CloseTime are not relevant. |
| 6 | OpenTime | datetime | NO | - | CODE-BACKED | Market open time in the exchange/instrument's local timezone. For continuous sessions with HasDailyBreak=0, middle days use datetime min value (1753-01-01 00:00:00). |
| 7 | CloseTime | datetime | NO | - | CODE-BACKED | Market close time in the exchange/instrument's local timezone. For continuous sessions with HasDailyBreak=0, middle days use datetime max value (9999-12-31 23:59:59.997). |
| 8 | OpenTimeUTC | datetime | NO | - | CODE-BACKED | Market open time converted to UTC. Used by the MarketHours Service for setting timers. Daylight saving time does not affect opening hours because they are stored in UTC. |
| 9 | CloseTimeUTC | datetime | NO | - | CODE-BACKED | Market close time converted to UTC. Used by the MarketHours Service for setting timers. |
| 10 | DeltaOpenSecs | decimal(8,3) | NO | - | CODE-BACKED | Offset adjustment to the open time in seconds. Provides sub-minute precision for fine-tuning when eToro enables/disables an instrument relative to the official exchange open. Positive = delay open, negative = open early. |
| 11 | DeltaCloseSecs | decimal(8,3) | NO | - | CODE-BACKED | Offset adjustment to the close time in seconds. Provides sub-minute precision for fine-tuning when eToro disables an instrument relative to the official exchange close. Positive = extend close, negative = close early. |
| 12 | IsManual | bit | NO | - | CODE-BACKED | Whether this schedule entry was manually configured by a dealer via Configuration Manager (CM), as opposed to being sourced from an external provider or default templates. When IsManual = 1, the IsOpen, OpenTime, and CloseTime fields are set manually by dealers and instrument state is controlled directly. |
| 13 | HasDailyBreak | bit | NO | - | CODE-BACKED | Whether the trading session has an intraday break (e.g., lunch break in Asian markets like Hong Kong Exchange 21). When true, open/close times apply per-day independently. When false, the session spans continuously and the DB uses min/max datetime values for intermediate days. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (it is a type definition, not a table with FKs).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.SetMergedDailySchedulesDeltaSecondsBulk | @SchedulesToUpdate parameter | TVP Parameter | This UDT defines the parameter shape for the bulk upsert procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.SetMergedDailySchedulesDeltaSecondsBulk | Stored Procedure | Accepts this type as @SchedulesToUpdate READONLY parameter |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate a TVP variable

```sql
DECLARE @schedules Market.MergedCalendarDeltaSecondsTable;

INSERT INTO @schedules (SourceProviderName, ExchangeID, InstrumentID, Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC, DeltaOpenSecs, DeltaCloseSecs, IsManual, HasDailyBreak)
VALUES ('eToro-Defaults', 4, NULL, '2026-04-14', 1, '2026-04-14 09:30:00', '2026-04-14 16:00:00', '2026-04-14 13:30:00', '2026-04-14 20:00:00', 0, 60, 0, 1);
```

### 8.2 Call the bulk upsert procedure

```sql
DECLARE @schedules Market.MergedCalendarDeltaSecondsTable;
-- ... populate @schedules ...
EXEC Market.SetMergedDailySchedulesDeltaSecondsBulk @SchedulesToUpdate = @schedules;
```

### 8.3 Inspect the TVP structure

```sql
SELECT c.name AS ColumnName, t.name AS DataType, c.max_length, c.precision, c.scale, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'MergedCalendarDeltaSecondsTable' AND tt.schema_id = SCHEMA_ID('Market')
ORDER BY c.column_id;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Database tables and Logic](https://etoro-jira.atlassian.net/wiki/spaces/view/12185961371) | Confluence | Confirms SetMergedDailySchedulesDeltaSecondsBulk is the SP used by MarketCalendar to update MergedDailySchedules; documents precedence logic and merge algorithm |
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | Architecture overview of the Market Hours system; confirms data flow from providers through merge to MergedDailySchedules; HasDailyBreak semantics |
| [DB (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11766628406) | Confluence | Table descriptions and query examples for CalendarDB Market schema |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.MergedCalendarDeltaSecondsTable | Type: User Defined Type | Source: CalendarDB/CalendarDB/Market/User Defined Types/Market.MergedCalendarDeltaSecondsTable.sql*
