# Trade.ConvertUtcToLocal

> Converts a UTC datetime to a local datetime in the specified timezone using SQL Server's SWITCHOFFSET and sys.time_zone_info.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DATETIME2 - local datetime |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ConvertUtcToLocal converts a UTC datetime into the corresponding local datetime for a given timezone. This is the reverse of Trade.ConvertTimeLocalToUTC. The function is used when displaying or comparing times in local exchange timezones - for example, determining what local time corresponds to a UTC-stored event.

This function exists because the trading platform stores all timestamps in UTC, but market schedules, exchange hours, and reporting periods are defined in local timezones. Converting UTC to local is needed for schedule matching, exchange identification by time, and localized reporting.

The function looks up the UTC offset from sys.time_zone_info using the timezone name, then applies SWITCHOFFSET to convert. The result is truncated to minute precision via CONVERT(Char(16), ..., 20).

---

## 2. Business Logic

### 2.1 UTC to Local Conversion

**What**: Applies timezone offset to convert UTC to local time.

**Columns/Parameters Involved**: `@toDay`, `@timezoneinfo`

**Rules**:
- Looks up current_utc_offset from sys.time_zone_info for the given timezone name
- Applies SWITCHOFFSET to shift the datetime by the offset
- Returns result truncated to minute precision (YYYY-MM-DD HH:MM format)
- Note: Uses static offset lookup (not AT TIME ZONE), so DST handling depends on when the query runs

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @toDay | DATETIME | NO | - | CODE-BACKED | UTC datetime to convert. Despite the parameter name suggesting "today", any UTC datetime can be passed. |
| 2 | @timezoneinfo | NVARCHAR(128) | NO | - | CODE-BACKED | Windows timezone name (e.g., 'Eastern Standard Time'). Must match sys.time_zone_info.name. |
| 3 | Return value | DATETIME2 | YES | - | CODE-BACKED | Local datetime in the specified timezone, truncated to minute precision. NULL if timezone name not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing table references. Reads sys.time_zone_info (system view).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetExchangeIDsByTime | Scalar call | Function call | Converts UTC times to local for exchange schedule matching |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ConvertUtcToLocal (function)
(no dependencies - uses only system views)
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
| RETURNS DATETIME2 | Return type | Local datetime with minute precision |
| CONVERT(Char(16), ..., 20) | Truncation | Output truncated to 'YYYY-MM-DD HH:MM' format |

---

## 8. Sample Queries

### 8.1 Convert current UTC to Eastern time

```sql
SELECT Trade.ConvertUtcToLocal(GETUTCDATE(), 'Eastern Standard Time') AS EasternTime;
```

### 8.2 Convert a specific UTC timestamp to Tokyo time

```sql
SELECT Trade.ConvertUtcToLocal('2026-03-15 14:30:00', 'Tokyo Standard Time') AS TokyoTime;
```

### 8.3 Show current time in multiple timezones

```sql
SELECT  'UTC' AS TZ, GETUTCDATE() AS Time
UNION ALL
SELECT  'New York', Trade.ConvertUtcToLocal(GETUTCDATE(), 'Eastern Standard Time')
UNION ALL
SELECT  'London', Trade.ConvertUtcToLocal(GETUTCDATE(), 'GMT Standard Time')
UNION ALL
SELECT  'Tokyo', Trade.ConvertUtcToLocal(GETUTCDATE(), 'Tokyo Standard Time');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ConvertUtcToLocal | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.ConvertUtcToLocal.sql*
