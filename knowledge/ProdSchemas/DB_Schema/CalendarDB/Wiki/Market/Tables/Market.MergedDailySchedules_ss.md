# Market.MergedDailySchedules_ss

> Snapshot/staging table for merged daily schedules, structurally similar to MergedDailySchedules but without temporal versioning. Used as an intermediate or archival copy of merged schedule data.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 NC PK + 1 Clustered on Date) |

---

## 1. Business Meaning

This table is a **legacy/abandoned** snapshot of `Market.MergedDailySchedules`. It has an identical column structure (minus the temporal versioning columns and the newer DeltaOpenSecs/DeltaCloseSecs columns) but is NOT a system-versioned temporal table. The "_ss" suffix indicates "snapshot."

Live data confirms this table is no longer actively used: all 7,185 rows have LogTime = 2021-05-13 (a single snapshot from May 2021) and dates only for 2021-05-19. This was likely a one-time snapshot taken during early system development or testing, before the system-versioned temporal history on MergedDailySchedules was established as the official audit mechanism. No new data has been written since.

The table lacks DeltaOpenSecs/DeltaCloseSecs columns (minutes-era schema), confirming it predates the seconds-precision migration. It also lacks computed audit columns (DbLoginName/AppLoginName) and temporal versioning, indicating it was created as a quick debugging/backup table rather than a production feature.

---

## 2. Business Logic

No complex business logic - this table mirrors MergedDailySchedules structure. See Market.MergedDailySchedules documentation for column semantics.

---

## 3. Data Overview

7,185 rows. Historical snapshot from May 2021 (data not actively updated):

| ID | SourceProviderName | ExchangeID | InstrumentID | Date | IsOpen | IsManual | HasDailyBreak | Meaning |
|---|---|---|---|---|---|---|---|---|
| 7185 | eToro-Defaults | 24 | NULL | 2021-05-19 | 1 | 0 | 1 | Saudi Exchange (24) exchange-level schedule. Open with daily break. |
| 7184 | eToro-Defaults | 2 | 128 | 2021-05-19 | 1 | 1 | 1 | Instrument 128 on exchange 2. IsManual=1 means dealer-controlled. |
| 7182 | eToro-Defaults | 2 | 100 | 2021-05-19 | 1 | 0 | 1 | Instrument 100 on exchange 2. Standard automated schedule. Open 00:00-18:00 UTC. |
| 7181 | eToro-Defaults | 3 | 36 | 2021-05-19 | 1 | 0 | 1 | Instrument 36 on exchange 3. Open 23:00-20:15 UTC (wraps across midnight). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-increment surrogate primary key. |
| 2 | LogTime | datetime | NO | - | CODE-BACKED | Timestamp when this snapshot row was inserted. |
| 3 | SourceProviderName | varchar(250) | YES | - | CODE-BACKED | Which data source won the merge precedence. Same values as MergedDailySchedules: "eToro-Defaults", "Xignite", "eToro-Overrides". |
| 4 | ExchangeID | int | NO | - | CODE-BACKED | eToro internal exchange identifier. |
| 5 | InstrumentID | int | YES | - | CODE-BACKED | eToro internal instrument identifier. NULL = exchange-level schedule. |
| 6 | Date | date | NO | - | CODE-BACKED | The specific calendar date. Clustered index column. |
| 7 | IsOpen | bit | NO | - | CODE-BACKED | Whether trading is open on this date. |
| 8 | OpenTime | datetime | NO | - | CODE-BACKED | Market open time in local timezone. |
| 9 | CloseTime | datetime | NO | - | CODE-BACKED | Market close time in local timezone. |
| 10 | OpenTimeUTC | datetime | NO | - | CODE-BACKED | Market open time in UTC. |
| 11 | CloseTimeUTC | datetime | NO | - | CODE-BACKED | Market close time in UTC. |
| 12 | DeltaOpenMins | int | YES | - | CODE-BACKED | Legacy minute-level open time offset. |
| 13 | DeltaCloseMins | int | YES | - | CODE-BACKED | Legacy minute-level close time offset. |
| 14 | IsManual | bit | NO | 0 | CODE-BACKED | Whether this entry was manually configured by dealers. |
| 15 | HasDailyBreak | bit | NO | 1 | CODE-BACKED | Whether the trading session breaks daily. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MarketMergedDailySchedules_ss | NC PK | ID | - | - | Active |
| IX_MergedDailySchedules_ss_Date | CLUSTERED | Date | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF__MergedDai__IsMan__01142BA1_ss | DEFAULT | 0 for IsManual |
| (unnamed) | DEFAULT | 1 for HasDailyBreak |

**Note**: No temporal versioning. No triggers. No DeltaOpenSecs/DeltaCloseSecs columns (minutes-era schema).

---

## 8. Sample Queries

### 8.1 Check snapshot row count and date range

```sql
SELECT COUNT(*) AS TotalRows, MIN(Date) AS EarliestDate, MAX(Date) AS LatestDate
FROM Market.MergedDailySchedules_ss WITH (NOLOCK);
```

### 8.2 Compare snapshot vs current merged for a date

```sql
SELECT 'Current' AS Source, COUNT(*) AS Rows FROM Market.MergedDailySchedules WITH (NOLOCK) WHERE Date = '2026-04-14'
UNION ALL
SELECT 'Snapshot', COUNT(*) FROM Market.MergedDailySchedules_ss WITH (NOLOCK) WHERE Date = '2026-04-14';
```

### 8.3 Browse snapshot data for a specific exchange

```sql
SELECT TOP 10 Date, ExchangeID, InstrumentID, IsOpen, OpenTimeUTC, CloseTimeUTC
FROM Market.MergedDailySchedules_ss WITH (NOLOCK)
WHERE ExchangeID = 4
ORDER BY Date DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.MergedDailySchedules_ss | Type: Table | Source: CalendarDB/CalendarDB/Market/Tables/Market.MergedDailySchedules_ss.sql*
