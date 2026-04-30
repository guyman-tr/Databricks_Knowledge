# Market.MergedCalendarTable

> Table-valued parameter type used to pass merged daily calendar schedule data (with delta in minutes precision) to the SetMergedDailySchedulesBulk stored procedure for bulk upsert into MergedDailySchedules.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | User Defined Type |
| **Key Identifier** | Composite: ExchangeID + InstrumentID + Date |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This UDT defines the shape of data passed to the `Market.SetMergedDailySchedulesBulk` stored procedure. It represents a batch of merged daily calendar entries - one row per exchange/instrument/date combination - carrying the final, consolidated trading schedule.

This is the **legacy minutes-precision variant** of the merged calendar TVP. It uses `DeltaOpenMins`/`DeltaCloseMins` (int) for open/close time offset adjustments, which provides only whole-minute granularity. The newer `MergedCalendarDeltaSecondsTable` type supersedes this with decimal(8,3) seconds-precision deltas. Per Confluence, the current MarketCalendar function uses the seconds-precision variant (`SetMergedDailySchedulesDeltaSecondsBulk`) as its primary path.

The MarketCalendar Azure Function calculates the merged schedule for the upcoming 7 days by combining defaults, provider data (Xignite), and manual overrides with a defined precedence: override > provider > instrument default > exchange default. The results are packaged into this TVP and bulk-inserted into MergedDailySchedules.

---

## 2. Business Logic

### 2.1 Minutes vs Seconds Precision

**What**: This type uses minute-level delta precision, while the newer MergedCalendarDeltaSecondsTable uses sub-second precision.

**Columns/Parameters Involved**: `DeltaOpenMins`, `DeltaCloseMins`

**Rules**:
- DeltaOpenMins and DeltaCloseMins are integers, limiting offsets to whole-minute granularity
- The seconds-precision variant (MergedCalendarDeltaSecondsTable) is now the primary path per Confluence documentation
- Both types insert into the same target table (MergedDailySchedules) but into different columns (Mins vs Secs)

---

## 3. Data Overview

N/A for User Defined Type. This type has no persisted data - it is used as a parameter shape for passing data to stored procedures.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SourceProviderName | varchar(250) | NO | - | CODE-BACKED | Name of the calendar data source that contributed this schedule entry. Known values: "eToro-Defaults", "Xignite", "eToro-Overrides". Identifies which source won the merge precedence for this particular date/exchange/instrument. |
| 2 | ExchangeID | int | NO | - | CODE-BACKED | eToro internal exchange identifier. Maps to an exchange in the main etoro database. Used alongside InstrumentID to uniquely identify which market this schedule applies to. |
| 3 | InstrumentID | int | YES | - | CODE-BACKED | eToro internal instrument identifier. NULL when the schedule applies to the entire exchange. Non-NULL when the instrument has a specific schedule overriding the exchange default. |
| 4 | Date | date | NO | - | CODE-BACKED | The specific calendar date this schedule entry applies to. The function calculates 7 days ahead (today + 6). |
| 5 | IsOpen | bit | NO | - | CODE-BACKED | Whether the exchange/instrument is open for trading on this date. 0 = closed (holiday, weekend), 1 = open. |
| 6 | OpenTime | datetime | NO | - | CODE-BACKED | Market open time in the exchange/instrument's local timezone. |
| 7 | CloseTime | datetime | NO | - | CODE-BACKED | Market close time in the exchange/instrument's local timezone. |
| 8 | OpenTimeUTC | datetime | NO | - | CODE-BACKED | Market open time converted to UTC for timer-based enable/disable. |
| 9 | CloseTimeUTC | datetime | NO | - | CODE-BACKED | Market close time converted to UTC for timer-based enable/disable. |
| 10 | DeltaOpenMins | int | NO | - | CODE-BACKED | Offset adjustment to the open time in whole minutes. Positive = delay open, negative = open early. Legacy precision - see DeltaOpenSecs in MergedCalendarDeltaSecondsTable for sub-minute precision. |
| 11 | DeltaCloseMins | int | NO | - | CODE-BACKED | Offset adjustment to the close time in whole minutes. Positive = extend close, negative = close early. Legacy precision. |
| 12 | IsManual | bit | NO | - | CODE-BACKED | Whether this entry was manually configured by a dealer via Configuration Manager. When 1, instrument state is controlled directly by dealers. |
| 13 | HasDailyBreak | bit | NO | - | CODE-BACKED | Whether the trading session has an intraday break. When true, open/close times apply per-day. When false, the session spans continuously across days using min/max datetime sentinel values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.SetMergedDailySchedulesBulk | @SchedulesToUpdate parameter | TVP Parameter | This UDT defines the parameter shape for the legacy minutes-precision bulk upsert procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.SetMergedDailySchedulesBulk | Stored Procedure | Accepts this type as @SchedulesToUpdate READONLY parameter |

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
DECLARE @schedules Market.MergedCalendarTable;

INSERT INTO @schedules (SourceProviderName, ExchangeID, InstrumentID, Date, IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC, DeltaOpenMins, DeltaCloseMins, IsManual, HasDailyBreak)
VALUES ('eToro-Defaults', 5, NULL, '2026-04-14', 1, '2026-04-14 09:30:00', '2026-04-14 16:00:00', '2026-04-14 13:30:00', '2026-04-14 20:00:00', 0, 1, 0, 1);
```

### 8.2 Call the bulk upsert procedure

```sql
DECLARE @schedules Market.MergedCalendarTable;
-- ... populate @schedules ...
EXEC Market.SetMergedDailySchedulesBulk @SchedulesToUpdate = @schedules;
```

### 8.3 Compare TVP types for precision differences

```sql
SELECT tt.name AS TypeName, c.name AS ColumnName, t.name AS DataType, c.precision, c.scale
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.schema_id = SCHEMA_ID('Market') AND tt.name IN ('MergedCalendarTable', 'MergedCalendarDeltaSecondsTable')
ORDER BY tt.name, c.column_id;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Database tables and Logic](https://etoro-jira.atlassian.net/wiki/spaces/view/12185961371) | Confluence | Confirms SetMergedDailySchedulesDeltaSecondsBulk is the current primary SP; this minutes-precision variant is the legacy path |
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | Architecture and merge precedence logic: override > provider > instrument default > exchange default |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.MergedCalendarTable | Type: User Defined Type | Source: CalendarDB/CalendarDB/Market/User Defined Types/Market.MergedCalendarTable.sql*
