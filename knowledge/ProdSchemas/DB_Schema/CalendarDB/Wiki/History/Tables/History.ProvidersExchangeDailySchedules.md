# History.ProvidersExchangeDailySchedules

> Temporal history table storing prior versions of Market.ProvidersExchangeDailySchedules rows - tracks all changes to provider-sourced and override exchange daily schedules.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime, SysStartTime) via clustered index |
| **Partition** | No |
| **Indexes** | 1 active (Clustered on temporal columns) |

---

## 1. Business Meaning

This table is the temporal history companion of `Market.ProvidersExchangeDailySchedules`. Every time the ProvideCalendar Azure Function refreshes Xignite data (via `SetProviderExchangeCalendarBulk`), or a dealer saves exchange overrides in CM, superseded schedule versions are automatically archived here.

This is a high-volume history table containing ~323,828 rows. The `SetProviderExchangeCalendarBulk` SP deletes and re-inserts data for affected dates on each provider refresh, generating history entries for every replaced row. With daily Xignite refreshes across 27 exchanges for 7 days each, history accumulates rapidly.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Standard History schema pattern. High volume due to daily provider refresh cycle.

**Rules**:
- Each Xignite daily refresh replaces 7 days x 27 exchanges = ~189 rows, generating ~189 history entries
- Override changes from CM also generate history
- No retention period configured (unlike MergedDailySchedules) - keeps all history indefinitely

---

## 3. Data Overview

~323,828 rows. Contains all superseded provider exchange schedule versions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Surrogate key from parent table. |
| 2 | LogTime | datetime | NO | - | CODE-BACKED | When this version was inserted into the parent table. |
| 3 | ProviderID | int | NO | - | CODE-BACKED | Provider: 0=eToro overrides, 1=Xignite. |
| 4 | ExchangeID | int | NO | - | CODE-BACKED | Exchange identifier. |
| 5 | Date | date | NO | - | CODE-BACKED | Schedule date. |
| 6 | IsOpen | bit | NO | - | CODE-BACKED | Whether the exchange was open in this version. |
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
| Market.ProvidersExchangeDailySchedules | SYSTEM_VERSIONING | Temporal History | Parent temporal table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.ProvidersExchangeDailySchedules | Table | Parent temporal table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ProvidersExchangeDailySchedules | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Reduces storage for high-volume historical data |

---

## 8. Sample Queries

### 8.1 View recent provider data changes for an exchange

```sql
SELECT TOP 20 ProviderID, ExchangeID, Date, IsOpen, OpenTimeUTC, CloseTimeUTC, SysStartTime, SysEndTime
FROM History.ProvidersExchangeDailySchedules WITH (NOLOCK)
WHERE ExchangeID = 4
ORDER BY SysEndTime DESC;
```

### 8.2 Point-in-time: what Xignite reported a week ago

```sql
SELECT ProviderID, ExchangeID, Date, IsOpen, OpenTimeUTC, CloseTimeUTC
FROM Market.ProvidersExchangeDailySchedules
FOR SYSTEM_TIME AS OF '2026-04-04T12:00:00'
WHERE ProviderID = 1 AND ExchangeID = 4
ORDER BY Date;
```

### 8.3 Track override changes over time

```sql
SELECT ExchangeID, Date, IsOpen, OpenTimeUTC, CloseTimeUTC, SysStartTime, SysEndTime
FROM History.ProvidersExchangeDailySchedules WITH (NOLOCK)
WHERE ProviderID = 0
ORDER BY SysEndTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. See [Market.ProvidersExchangeDailySchedules](../../Market/Tables/Market.ProvidersExchangeDailySchedules.md) for business context.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ProvidersExchangeDailySchedules | Type: Table | Source: CalendarDB/CalendarDB/History/Tables/History.ProvidersExchangeDailySchedules.sql*
