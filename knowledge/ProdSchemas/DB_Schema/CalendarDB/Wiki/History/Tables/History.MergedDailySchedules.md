# History.MergedDailySchedules

> Temporal history table storing prior versions of Market.MergedDailySchedules rows - the audit trail of all merged trading schedule changes, with 6-month automatic retention.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ValidTo, ValidFrom) via clustered index |
| **Partition** | No |
| **Indexes** | 1 active (Clustered on temporal columns) |

---

## 1. Business Meaning

This table is the temporal history companion of `Market.MergedDailySchedules` - the most important table in CalendarDB. Every time the MarketCalendar Azure Function recalculates and replaces merged schedules (via the atomic delete-and-insert SPs), the previous versions are automatically archived here.

This is the largest history table in CalendarDB with ~12.6 million rows. The parent table's `SetMergedDailySchedulesDeltaSecondsBulk` SP deletes all rows for affected dates and re-inserts, so every recalculation generates history entries for every affected exchange/instrument/date. With 7 days recalculated daily across hundreds of instruments, history grows rapidly.

**Important**: This table uses a 6-month retention period (`HISTORY_RETENTION_PERIOD = 6 MONTH`), meaning SQL Server automatically purges history rows older than 6 months. This prevents unbounded growth.

**Note**: The temporal columns are named `ValidFrom`/`ValidTo` (not `SysStartTime`/`SysEndTime`) to match the parent table's naming convention.

---

## 2. Business Logic

### 2.1 Temporal Versioning with Retention

**What**: Unlike other History tables, this one has automatic retention to manage size.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`

**Rules**:
- HISTORY_RETENTION_PERIOD = 6 MONTH (configured on parent table)
- SQL Server automatically purges rows where ValidTo < (now - 6 months)
- This balances audit capability with storage costs for the highest-volume history table
- Other History tables have no retention period (keep all history indefinitely)

---

## 3. Data Overview

~12.6 million rows. Contains all superseded merged schedule versions from the past 6 months.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Surrogate key from parent table. |
| 2 | LogTime | datetime | NO | - | CODE-BACKED | When the merge calculation produced this version. |
| 3 | SourceProviderName | varchar(250) | YES | - | CODE-BACKED | Data source that won the merge: "eToro-Defaults", "Xignite", "eToro-Overrides". |
| 4 | ExchangeID | int | NO | - | CODE-BACKED | Exchange identifier. |
| 5 | InstrumentID | int | YES | - | CODE-BACKED | Instrument identifier (NULL = exchange-level). |
| 6 | Date | date | NO | - | CODE-BACKED | Schedule date. |
| 7 | IsOpen | bit | NO | - | CODE-BACKED | Whether trading was open on this date in this version. |
| 8 | OpenTime | datetime | NO | - | CODE-BACKED | Open time in local timezone. |
| 9 | CloseTime | datetime | NO | - | CODE-BACKED | Close time in local timezone. |
| 10 | OpenTimeUTC | datetime | NO | - | CODE-BACKED | Open time in UTC. |
| 11 | CloseTimeUTC | datetime | NO | - | CODE-BACKED | Close time in UTC. |
| 12 | DeltaOpenMins | int | YES | - | CODE-BACKED | Open time offset in minutes (legacy). |
| 13 | DeltaCloseMins | int | YES | - | CODE-BACKED | Close time offset in minutes (legacy). |
| 14 | IsManual | bit | NO | - | CODE-BACKED | Manual control flag. |
| 15 | HasDailyBreak | bit | NO | - | CODE-BACKED | Daily break flag. |
| 16 | DeltaOpenSecs | decimal(8,3) | YES | - | CODE-BACKED | Open time offset in seconds. |
| 17 | DeltaCloseSecs | decimal(8,3) | YES | - | CODE-BACKED | Close time offset in seconds. |
| 18 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | When this row version became active (temporal ROW START). |
| 19 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | When this row version was superseded (temporal ROW END). Rows where ValidTo < (now - 6 months) are auto-purged. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.MergedDailySchedules | SYSTEM_VERSIONING | Temporal History | Parent temporal table with 6-month retention |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.MergedDailySchedules | Table | Parent temporal table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_MergedDailySchedules | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Reduces storage for high-volume historical data |
| HISTORY_RETENTION_PERIOD = 6 MONTH | Retention | Auto-purge rows older than 6 months (configured on parent) |

---

## 8. Sample Queries

### 8.1 View recent schedule changes for an exchange

```sql
SELECT TOP 20 ExchangeID, InstrumentID, Date, IsOpen, OpenTimeUTC, CloseTimeUTC, ValidFrom, ValidTo
FROM History.MergedDailySchedules WITH (NOLOCK)
WHERE ExchangeID = 4
ORDER BY ValidTo DESC;
```

### 8.2 Point-in-time: what was the schedule a week ago

```sql
SELECT ExchangeID, InstrumentID, Date, IsOpen, OpenTimeUTC, CloseTimeUTC
FROM Market.MergedDailySchedules
FOR SYSTEM_TIME AS OF '2026-04-04T12:00:00'
WHERE ExchangeID = 4 AND Date = '2026-04-07'
ORDER BY InstrumentID;
```

### 8.3 Count history volume by date range

```sql
SELECT CAST(ValidTo AS date) AS ChangeDate, COUNT(*) AS VersionsSuperseded
FROM History.MergedDailySchedules WITH (NOLOCK)
WHERE ValidTo >= DATEADD(day, -7, GETUTCDATE())
GROUP BY CAST(ValidTo AS date)
ORDER BY ChangeDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. See [Market.MergedDailySchedules](../../Market/Tables/Market.MergedDailySchedules.md) for business context.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.MergedDailySchedules | Type: Table | Source: CalendarDB/CalendarDB/History/Tables/History.MergedDailySchedules.sql*
