# Trade.ConvertTimeLocalToUTC

> Converts a local time value to UTC datetime by combining the time with today's date and applying the specified timezone offset.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DATETIME - UTC datetime |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ConvertTimeLocalToUTC converts a time-of-day value from a specified local timezone into a full UTC datetime. The function uses today's date (via GETDATE()) combined with the provided time, then applies SQL Server's AT TIME ZONE conversion to translate from the local timezone to UTC.

This function exists because market schedules, trading windows, and exchange hours are typically defined in local exchange timezones, but the trading engine operates in UTC. Converting local schedule times to UTC is essential for determining when markets open/close, when to apply overnight fees, and when to trigger time-based operations.

The function uses a fixed reference date ('20140101') with DATEDIFF/DATEADD to strip time from today's date, then adds the input time. This pattern handles edge cases around midnight crossings. The output is used by GetExchangeIDsByTime and market schedule functions.

---

## 2. Business Logic

### 2.1 Time-to-UTC Conversion

**What**: Combines today's date with a local time and converts to UTC.

**Columns/Parameters Involved**: `@timezoneinfo`, `@time`

**Rules**:
- Gets today's date (date-only, no time) using DATEDIFF/DATEADD pattern with reference date '2014-01-01'
- Adds the provided @time to create a full local datetime
- Applies AT TIME ZONE @timezoneinfo to mark the timezone, then AT TIME ZONE 'UTC' to convert
- Returns a DATETIME representing the UTC equivalent

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @timezoneinfo | NVARCHAR(128) | NO | - | CODE-BACKED | Windows timezone name (e.g., 'Eastern Standard Time', 'Central European Standard Time'). Must match a value in sys.time_zone_info. |
| 2 | @time | time | NO | - | CODE-BACKED | Local time of day to convert (e.g., '09:30:00' for market open). |
| 3 | Return value | DATETIME | YES | - | CODE-BACKED | Full UTC datetime: today's date at the equivalent UTC time. NULL if timezone name is invalid. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing table references. Uses sys.time_zone_info indirectly via AT TIME ZONE.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetExchangeIDsByTime | Scalar call | Function call | Converts exchange local times to UTC for schedule matching |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ConvertTimeLocalToUTC (function)
(no dependencies - uses only built-in SQL Server timezone functions)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetExchangeIDsByTime | Function | Scalar call for timezone conversion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS DATETIME | Return type | UTC datetime result |
| AT TIME ZONE | Conversion | Uses SQL Server 2016+ AT TIME ZONE for DST-aware conversion |

---

## 8. Sample Queries

### 8.1 Convert NYSE open time to UTC

```sql
SELECT Trade.ConvertTimeLocalToUTC('Eastern Standard Time', '09:30:00') AS NYSEOpenUTC;
```

### 8.2 Convert London close time to UTC

```sql
SELECT Trade.ConvertTimeLocalToUTC('GMT Standard Time', '16:30:00') AS LondonCloseUTC;
```

### 8.3 Compare multiple timezone conversions

```sql
SELECT  'New York' AS Exchange, Trade.ConvertTimeLocalToUTC('Eastern Standard Time', '09:30:00') AS OpenUTC
UNION ALL
SELECT  'London', Trade.ConvertTimeLocalToUTC('GMT Standard Time', '08:00:00')
UNION ALL
SELECT  'Tokyo', Trade.ConvertTimeLocalToUTC('Tokyo Standard Time', '09:00:00');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ConvertTimeLocalToUTC | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.ConvertTimeLocalToUTC.sql*
