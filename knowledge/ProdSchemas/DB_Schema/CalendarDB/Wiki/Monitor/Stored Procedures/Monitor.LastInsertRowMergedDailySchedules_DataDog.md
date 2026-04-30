# Monitor.LastInsertRowMergedDailySchedules_DataDog

> Monitoring procedure that returns the number of days since the last insert into Market.MergedDailySchedules, used as a DataDog health check metric to detect stale calendar data.

| Property | Value |
|----------|-------|
| **Schema** | Monitor |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single integer value (days since last insert) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a health check for the Market Hours calendar pipeline. It calculates the number of days between the most recent `LogTime` in `Market.MergedDailySchedules` and the current UTC time. The result is consumed by DataDog monitoring to trigger alerts if the merged calendar data becomes stale.

If the MarketCalendar Azure Function stops running (due to failure, misconfiguration, or infrastructure issues), merged schedule data will not be refreshed. This procedure detects that scenario: under normal operations, `LogTime` should be within the last day (value = 0). A value of 1+ indicates the calendar pipeline has not run for at least a full day, signaling a potential outage.

The procedure uses NOLOCK on `MergedDailySchedules` for non-blocking reads, and returns a single column named `value` matching DataDog's expected metric format.

---

## 2. Business Logic

### 2.1 Staleness Detection

**What**: Measures days since last calendar merge to detect pipeline failures.

**Columns/Parameters Involved**: `LogTime` (from MergedDailySchedules), `GETUTCDATE()`

**Rules**:
- `DATEDIFF(DAY, MAX(LogTime), GETUTCDATE())` returns 0 when last insert was today
- Returns 1 when last insert was yesterday (pipeline missed today's run)
- Returns N when pipeline has been down for N days
- Expected healthy value: 0 (calendar recalculated daily)
- Alert threshold: typically >= 1 (should trigger DataDog alert)

**Diagram**:
```
Normal operation:
  MAX(LogTime) = today -> DATEDIFF = 0 -> DataDog: OK

Pipeline down 1 day:
  MAX(LogTime) = yesterday -> DATEDIFF = 1 -> DataDog: ALERT

Pipeline down N days:
  MAX(LogTime) = N days ago -> DATEDIFF = N -> DataDog: CRITICAL
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no parameters.

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | value | int | NO | - | CODE-BACKED | Number of whole days since the last insert into Market.MergedDailySchedules. 0 = healthy (merged today), 1+ = stale (pipeline may be down). Named `value` to match DataDog's expected metric column format. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| N/A | Market.MergedDailySchedules | Read | SELECT MAX(LogTime) to determine last insert time |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DataDog | Scheduled check | Caller | Periodically executes this SP and ingests the `value` as a metric |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitor.LastInsertRowMergedDailySchedules_DataDog (procedure)
└── Market.MergedDailySchedules (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Market.MergedDailySchedules | Table | READER - SELECT MAX(LogTime) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DataDog monitoring | External Service | Scheduled execution for health metric |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. The query benefits from the clustered index on Date in MergedDailySchedules, though MAX(LogTime) requires a scan since LogTime is not indexed.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the monitoring check

```sql
EXEC Monitor.LastInsertRowMergedDailySchedules_DataDog;
```

### 8.2 Equivalent inline query

```sql
SELECT DATEDIFF(DAY, MAX(LogTime), GETUTCDATE()) AS value
FROM Market.MergedDailySchedules WITH (NOLOCK);
```

### 8.3 More detailed staleness check with timestamp

```sql
SELECT MAX(LogTime) AS LastInsertTime,
       GETUTCDATE() AS CurrentUTC,
       DATEDIFF(DAY, MAX(LogTime), GETUTCDATE()) AS DaysSinceLastInsert,
       DATEDIFF(HOUR, MAX(LogTime), GETUTCDATE()) AS HoursSinceLastInsert
FROM Market.MergedDailySchedules WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. The "_DataDog" suffix in the procedure name indicates this is a DataDog integration point for infrastructure monitoring.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitor.LastInsertRowMergedDailySchedules_DataDog | Type: Stored Procedure | Source: CalendarDB/CalendarDB/Monitor/Stored Procedures/Monitor.LastInsertRowMergedDailySchedules_DataDog.sql*
