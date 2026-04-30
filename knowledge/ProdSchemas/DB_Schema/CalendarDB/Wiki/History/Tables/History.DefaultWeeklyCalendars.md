# History.DefaultWeeklyCalendars

> Temporal history table storing prior versions of Market.DefaultWeeklyCalendars rows - tracks all changes to default weekly trading schedule configurations over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime, SysStartTime) via clustered index |
| **Partition** | No |
| **Indexes** | 1 active (Clustered on temporal columns) |

---

## 1. Business Meaning

This table is the temporal history companion of `Market.DefaultWeeklyCalendars`. Every time a dealer modifies a default weekly schedule in Configuration Manager (changing open/close times, day ranges, delta offsets, or IsManual/HasDailyBreak flags), the previous version is automatically archived here.

This is one of the most actively used history tables in CalendarDB, containing 22,669 rows. Default weekly schedules are frequently adjusted as exchanges change their trading hours, new instruments are added, or seasonal schedule changes occur. The history provides a complete audit trail of every schedule configuration change.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Standard History schema pattern with PAGE compression and temporal clustered index.

**Rules**:
- High-volume history: 22,669 prior versions vs 5,931 current rows indicates frequent configuration updates
- Preserves all schedule parameters (open/close times, day ranges, deltas, manual/break flags)
- Critical for investigating schedule-related incidents: "What was the default schedule for exchange X on date Y?"

---

## 3. Data Overview

22,669 rows. Active history reflecting frequent schedule configuration changes by dealers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Surrogate key from parent table. Not IDENTITY here (materialized from parent). |
| 2 | ExchangeID | int | NO | - | CODE-BACKED | Exchange identifier at time of this version. |
| 3 | InstrumentID | int | YES | - | CODE-BACKED | Instrument identifier (NULL = exchange-level default). |
| 4 | StartDayOfWeek | int | NO | - | CODE-BACKED | First day of week range (0=Sunday through 6=Saturday). |
| 5 | EndDayOfWeek | int | NO | - | CODE-BACKED | Last day of week range. |
| 6 | OpenTime | time(7) | NO | - | CODE-BACKED | Market open time in local timezone at time of this version. |
| 7 | CloseTime | time(7) | NO | - | CODE-BACKED | Market close time in local timezone at time of this version. |
| 8 | DeltaOpenMins | int | NO | - | CODE-BACKED | Open time offset in minutes at time of this version. |
| 9 | DeltaCloseMins | int | NO | - | CODE-BACKED | Close time offset in minutes at time of this version. |
| 10 | IsManual | bit | NO | - | CODE-BACKED | Manual control flag at time of this version. |
| 11 | HasDailyBreak | bit | NO | - | CODE-BACKED | Daily break flag at time of this version. |
| 12 | DeltaOpenSecs | decimal(8,3) | YES | - | CODE-BACKED | Open time offset in seconds (newer column, may be NULL in older history). |
| 13 | DeltaCloseSecs | decimal(8,3) | YES | - | CODE-BACKED | Close time offset in seconds (newer column, may be NULL in older history). |
| 14 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that made the change. |
| 15 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application session identity at time of change. |
| 16 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | When this row version became active. |
| 17 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | When this row version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.DefaultWeeklyCalendars | SYSTEM_VERSIONING | Temporal History | Parent temporal table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.DefaultWeeklyCalendars | Table | Parent temporal table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_DefaultWeeklyCalendars | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Reduces storage for historical data |

---

## 8. Sample Queries

### 8.1 View schedule change history for an exchange

```sql
SELECT ID, ExchangeID, InstrumentID, OpenTime, CloseTime, SysStartTime, SysEndTime
FROM History.DefaultWeeklyCalendars WITH (NOLOCK)
WHERE ExchangeID = 4 AND InstrumentID IS NULL
ORDER BY SysStartTime DESC;
```

### 8.2 What were the defaults for an exchange on a specific date

```sql
SELECT ExchangeID, InstrumentID, StartDayOfWeek, EndDayOfWeek, OpenTime, CloseTime
FROM Market.DefaultWeeklyCalendars
FOR SYSTEM_TIME AS OF '2024-06-15T00:00:00'
WHERE ExchangeID = 4
ORDER BY StartDayOfWeek;
```

### 8.3 Find most frequently changed exchanges

```sql
SELECT ExchangeID, COUNT(*) AS ChangeCount
FROM History.DefaultWeeklyCalendars WITH (NOLOCK)
GROUP BY ExchangeID
ORDER BY ChangeCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. See [Market.DefaultWeeklyCalendars](../../Market/Tables/Market.DefaultWeeklyCalendars.md) for business context.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.DefaultWeeklyCalendars | Type: Table | Source: CalendarDB/CalendarDB/History/Tables/History.DefaultWeeklyCalendars.sql*
