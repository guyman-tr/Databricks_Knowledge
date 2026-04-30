# Trade.GetMarketTimes

> Returns the market schedule (open/close times, open status) for a given exchange, with optional instrument-level override support via priority-based row selection from MergedDailySchedules.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with IsOpen, Date, OpenTimeUTC, CloseTimeUTC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMarketTimes returns the daily market open/close schedule for a given exchange, optionally overridden at the instrument level. Markets have regular schedules but some instruments have custom trading hours (e.g., extended hours, early close). This function resolves the effective schedule by prioritizing instrument-specific schedules over exchange-level defaults.

This function exists because trading operations (order validation, fee timing, settlement windows) need to know when a market is open or closed. The function reads from Trade.MergedDailySchedules (a synonym pointing to a cross-schema schedule table) which contains both exchange-level and instrument-level schedule entries, and uses priority-based deduplication to return one row per date.

The function is consumed by Trade.GetMarketCloseTimeByExDate and other schedule-dependent functions and procedures.

---

## 2. Business Logic

### 2.1 Priority-Based Schedule Resolution

**What**: Instrument-specific schedules override exchange-level defaults.

**Columns/Parameters Involved**: `@ExchangeID`, `@InstrumentID`, `MergedDailySchedules.InstrumentID`

**Rules**:
- **Priority 0** (highest): Schedule row with matching InstrumentID (instrument-specific override)
- **Priority 1**: Schedule row with InstrumentID = NULL (exchange-level default)
- **Priority 2** (lowest): Schedule row with non-matching InstrumentID (filtered out by WHERE)
- Per date, only the highest-priority row is returned (ROW_NUMBER partitioned by Date, ordered by priority ASC, ID DESC)
- Rows with year(CloseTimeUTC) = 9999 are excluded (sentinel values)
- If @InstrumentID is NULL, only exchange-level rows (InstrumentID IS NULL) are returned

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExchangeID | INT | NO | - | CODE-BACKED | Exchange identifier. Filters MergedDailySchedules to the target exchange. |
| 2 | @InstrumentID | INT | YES | NULL | CODE-BACKED | Optional instrument for instrument-specific schedule overrides. When NULL, only exchange-level schedules are returned. |
| 3 | IsOpen (return) | BIT | NO | - | CODE-BACKED | Whether the market is open on this date. 0 = closed (holiday, weekend), 1 = open. |
| 4 | Date (return) | DATE | NO | - | CODE-BACKED | Calendar date for the schedule entry. |
| 5 | OpenTimeUTC (return) | DATETIME | NO | - | CODE-BACKED | Market open time in UTC for this date. |
| 6 | CloseTimeUTC (return) | DATETIME | NO | - | CODE-BACKED | Market close time in UTC for this date. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MDS | Trade.MergedDailySchedules | FROM/WHERE | Synonym pointing to the daily schedule source table. Filtered by ExchangeID and optionally InstrumentID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetMarketCloseTimeByExDate | CROSS APPLY | Function call | Gets close time for a specific exchange date |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMarketTimes (function)
  └── Trade.MergedDailySchedules (synonym -> cross-schema schedule table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.MergedDailySchedules | Synonym | FROM: reads daily schedule entries filtered by ExchangeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetMarketCloseTimeByExDate | Function | CROSS APPLY for specific date close time |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning schedule rows |
| ROW_NUMBER() OVER (PARTITION BY Date ORDER BY priority, ID DESC) | Dedup | One row per date, highest priority wins, latest ID breaks ties |
| DATEPART(year, CloseTimeUTC) != 9999 | Filter | Excludes sentinel/placeholder rows |

---

## 8. Sample Queries

### 8.1 Get market schedule for NYSE (ExchangeID known)

```sql
SELECT  IsOpen, Date, OpenTimeUTC, CloseTimeUTC
FROM    Trade.GetMarketTimes(1, NULL)
WHERE   Date >= CAST(GETDATE() AS DATE)
ORDER BY Date;
```

### 8.2 Get instrument-specific schedule (extended hours)

```sql
SELECT  IsOpen, Date, OpenTimeUTC, CloseTimeUTC
FROM    Trade.GetMarketTimes(1, 1001)
WHERE   Date = CAST(GETDATE() AS DATE);
```

### 8.3 Find upcoming market holidays

```sql
SELECT  Date, OpenTimeUTC, CloseTimeUTC
FROM    Trade.GetMarketTimes(1, NULL)
WHERE   IsOpen = 0
        AND Date >= CAST(GETDATE() AS DATE)
        AND Date <= DATEADD(MONTH, 3, GETDATE())
ORDER BY Date;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMarketTimes | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.GetMarketTimes.sql*
