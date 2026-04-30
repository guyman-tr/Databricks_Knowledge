# Market.GetMergedDailySchedulesFromDate

> Retrieves all merged daily schedules from a given date onward, returning the complete trading calendar for upcoming days. Used by the MarketHours Service to load schedule data.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Date-filtered SELECT from MergedDailySchedules |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns all rows from `Market.MergedDailySchedules` where `Date >= @FromDate`, ordered by Date. It is the primary read path for the MarketHours Service, which calls this on startup to load the complete upcoming trading calendar into memory and set timers for instrument enable/disable events.

Uses NOLOCK and SET NOCOUNT ON for optimal read performance. Leverages the clustered index on Date for efficient range scans.

---

## 2. Business Logic

No complex logic. Date-range filter with ORDER BY Date. Returns all columns from MergedDailySchedules.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATE | NO | - | CODE-BACKED | Start date filter (inclusive). Typically today's date. Returns all schedules from this date forward. |

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Row identifier from MergedDailySchedules. |
| 2 | LogTime | datetime | NO | - | CODE-BACKED | When the merge calculation produced this entry. |
| 3 | SourceProviderName | varchar(250) | YES | - | CODE-BACKED | Which source won the merge: "eToro-Defaults", "Xignite", "eToro-Overrides". |
| 4 | ExchangeID | int | NO | - | CODE-BACKED | Exchange identifier. |
| 5 | InstrumentID | int | YES | - | CODE-BACKED | Instrument identifier (NULL = exchange-level). |
| 6 | Date | date | NO | - | CODE-BACKED | Schedule date. |
| 7 | IsOpen | bit | NO | - | CODE-BACKED | Whether trading is open. |
| 8 | OpenTime | datetime | NO | - | CODE-BACKED | Open time in local timezone. |
| 9 | CloseTime | datetime | NO | - | CODE-BACKED | Close time in local timezone. |
| 10 | OpenTimeUTC | datetime | NO | - | CODE-BACKED | Open time in UTC (used for timers). |
| 11 | CloseTimeUTC | datetime | NO | - | CODE-BACKED | Close time in UTC (used for timers). |
| 12 | DeltaOpenMins | int | YES | - | CODE-BACKED | Open time offset in minutes (legacy). |
| 13 | DeltaCloseMins | int | YES | - | CODE-BACKED | Close time offset in minutes (legacy). |
| 14 | IsManual | bit | NO | - | CODE-BACKED | Whether manually controlled by dealers. |
| 15 | HasDailyBreak | bit | NO | - | CODE-BACKED | Whether session has daily breaks. |
| 16 | DeltaOpenSecs | decimal(8,3) | YES | - | CODE-BACKED | Open time offset in seconds (current). |
| 17 | DeltaCloseSecs | decimal(8,3) | YES | - | CODE-BACKED | Close time offset in seconds (current). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| N/A | Market.MergedDailySchedules | Read | SELECT with date filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MarketHours Service | Startup | Caller | Loads upcoming schedule into memory |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Market.GetMergedDailySchedulesFromDate (procedure)
└── Market.MergedDailySchedules (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Market.MergedDailySchedules | Table | READER - date-range SELECT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MarketHours Service | External Service | Primary consumer on startup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Uses `IX_MergedDailySchedules_Date` clustered index on target table.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all upcoming schedules from today

```sql
EXEC Market.GetMergedDailySchedulesFromDate @FromDate = '2026-04-11';
```

### 8.2 Get schedules for next week only

```sql
EXEC Market.GetMergedDailySchedulesFromDate @FromDate = '2026-04-14';
```

### 8.3 Equivalent direct query

```sql
SELECT ID, LogTime, SourceProviderName, ExchangeID, InstrumentID, Date,
       IsOpen, OpenTime, CloseTime, OpenTimeUTC, CloseTimeUTC,
       DeltaOpenMins, DeltaCloseMins, IsManual, HasDailyBreak, DeltaOpenSecs, DeltaCloseSecs
FROM Market.MergedDailySchedules WITH (NOLOCK)
WHERE Date >= '2026-04-11'
ORDER BY Date;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Technical Summary (Market Hours)](https://etoro-jira.atlassian.net/wiki/spaces/view/11777474792) | Confluence | MarketHours Service "load MergedDailySchedules table from MarketData database" on startup. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.GetMergedDailySchedulesFromDate | Type: Stored Procedure | Source: CalendarDB/CalendarDB/Market/Stored Procedures/Market.GetMergedDailySchedulesFromDate.sql*
