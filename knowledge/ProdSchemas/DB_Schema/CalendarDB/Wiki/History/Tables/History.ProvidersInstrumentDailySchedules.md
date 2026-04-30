# History.ProvidersInstrumentDailySchedules

> Temporal history table storing prior versions of Market.ProvidersInstrumentDailySchedules rows - tracks all changes to instrument-level daily schedule overrides.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime, SysStartTime) via clustered index |
| **Partition** | No |
| **Indexes** | 1 active (Clustered on temporal columns) |

---

## 1. Business Meaning

This table is the temporal history companion of `Market.ProvidersInstrumentDailySchedules`. Every time a dealer modifies an instrument-level schedule override in Configuration Manager, the previous version is automatically archived here.

Contains 8,609 rows. Since the parent table currently holds only eToro overrides (ProviderID=0, as Xignite provides only exchange-level data), all history rows are also from eToro override changes.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Standard History schema pattern. Moderate volume from CM override changes.

**Rules**:
- Each CM override save replaces instrument-level schedules, generating history entries
- All rows have ProviderID=0 (eToro overrides only)
- No retention period - keeps all history indefinitely

---

## 3. Data Overview

8,609 rows. Reflects dealer override changes to instrument-level schedules.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Surrogate key from parent table. |
| 2 | LogTime | datetime | NO | - | CODE-BACKED | When this version was inserted into the parent. |
| 3 | ProviderID | int | NO | - | CODE-BACKED | Provider: always 0 (eToro overrides) in current data. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier. |
| 5 | Date | date | NO | - | CODE-BACKED | Schedule date. |
| 6 | IsOpen | bit | NO | - | CODE-BACKED | Whether the instrument was open in this version. |
| 7 | OpenTime | datetime | NO | - | CODE-BACKED | Open time in local timezone. |
| 8 | CloseTime | datetime | NO | - | CODE-BACKED | Close time in local timezone. |
| 9 | OpenTimeUTC | datetime | NO | - | CODE-BACKED | Open time in UTC. |
| 10 | CloseTimeUTC | datetime | NO | - | CODE-BACKED | Close time in UTC. |
| 11 | DeltaOpenMins | int | YES | - | CODE-BACKED | Open time offset in minutes (legacy). |
| 12 | DeltaCloseMins | int | YES | - | CODE-BACKED | Close time offset in minutes (legacy). |
| 13 | DeltaOpenSecs | decimal(8,3) | YES | - | CODE-BACKED | Open time offset in seconds. |
| 14 | DeltaCloseSecs | decimal(8,3) | YES | - | CODE-BACKED | Close time offset in seconds. |
| 15 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that made the change. |
| 16 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application session identity. |
| 17 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | When this row version became active. |
| 18 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | When this row version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.ProvidersInstrumentDailySchedules | SYSTEM_VERSIONING | Temporal History | Parent temporal table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.ProvidersInstrumentDailySchedules | Table | Parent temporal table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ProvidersInstrumentDailySchedules | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Reduces storage for historical data |

---

## 8. Sample Queries

### 8.1 View override change history for an instrument

```sql
SELECT InstrumentID, Date, IsOpen, OpenTimeUTC, CloseTimeUTC, SysStartTime, SysEndTime
FROM History.ProvidersInstrumentDailySchedules WITH (NOLOCK)
WHERE InstrumentID = 25
ORDER BY SysEndTime DESC;
```

### 8.2 What instrument overrides existed on a past date

```sql
SELECT InstrumentID, Date, IsOpen, OpenTimeUTC, CloseTimeUTC
FROM Market.ProvidersInstrumentDailySchedules
FOR SYSTEM_TIME AS OF '2025-06-01T00:00:00'
WHERE ProviderID = 0
ORDER BY InstrumentID, Date;
```

### 8.3 Find instruments with most override changes

```sql
SELECT InstrumentID, COUNT(*) AS ChangeCount
FROM History.ProvidersInstrumentDailySchedules WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY ChangeCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. See [Market.ProvidersInstrumentDailySchedules](../../Market/Tables/Market.ProvidersInstrumentDailySchedules.md) for business context.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ProvidersInstrumentDailySchedules | Type: Table | Source: CalendarDB/CalendarDB/History/Tables/History.ProvidersInstrumentDailySchedules.sql*
