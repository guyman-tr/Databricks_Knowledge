# History.ExchangeTimeZones

> Temporal history table storing prior versions of Market.ExchangeTimeZones rows - tracks all changes to exchange timezone assignments over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime, SysStartTime) via clustered index |
| **Partition** | No |
| **Indexes** | 1 active (Clustered on temporal columns) |

---

## 1. Business Meaning

This table is the temporal history companion of `Market.ExchangeTimeZones`. SQL Server automatically moves superseded row versions here whenever an exchange's timezone assignment is changed. Each row preserves a prior timezone-to-exchange mapping with exact validity timestamps.

This is critical for debugging timezone-related schedule issues: if an exchange's timezone was incorrectly configured and later corrected, this table shows exactly when the change occurred and what the old value was. Currently contains 4 rows, reflecting a small number of timezone corrections to the 31 current exchange timezone entries.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Standard History schema pattern - system-versioned temporal history target.

**Rules**:
- Row moved here on UPDATE/DELETE of parent table row
- Clustered index on (SysEndTime, SysStartTime), PAGE compression
- DbLoginName/AppLoginName materialized (not computed)

---

## 3. Data Overview

4 rows. Reflects a small number of timezone corrections since initial setup.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID | int | NO | - | CODE-BACKED | Exchange identifier at time of this version. |
| 2 | TimeZone | varchar(1000) | NO | - | CODE-BACKED | Windows timezone identifier at time of this version. Shows what timezone the exchange was assigned before the change. |
| 3 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that made the change. |
| 4 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application session identity at time of change. |
| 5 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | When this row version became active. |
| 6 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | When this row version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.ExchangeTimeZones | SYSTEM_VERSIONING | Temporal History | Parent temporal table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.ExchangeTimeZones | Table | Parent temporal table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ExchangeTimeZones | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Reduces storage for historical data |

---

## 8. Sample Queries

### 8.1 View timezone change history for an exchange

```sql
SELECT ExchangeID, TimeZone, SysStartTime, SysEndTime
FROM History.ExchangeTimeZones WITH (NOLOCK)
WHERE ExchangeID = 9
ORDER BY SysStartTime;
```

### 8.2 What timezone did an exchange use on a specific date

```sql
SELECT ExchangeID, TimeZone
FROM Market.ExchangeTimeZones
FOR SYSTEM_TIME AS OF '2023-06-15T00:00:00'
WHERE ExchangeID = 9;
```

### 8.3 Find all timezone changes across all exchanges

```sql
SELECT h.ExchangeID, h.TimeZone AS OldTimeZone, h.SysStartTime, h.SysEndTime, c.TimeZone AS CurrentTimeZone
FROM History.ExchangeTimeZones h WITH (NOLOCK)
JOIN Market.ExchangeTimeZones c WITH (NOLOCK) ON h.ExchangeID = c.ExchangeID
ORDER BY h.ExchangeID, h.SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. See [Market.ExchangeTimeZones](../../Market/Tables/Market.ExchangeTimeZones.md) for business context.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ExchangeTimeZones | Type: Table | Source: CalendarDB/CalendarDB/History/Tables/History.ExchangeTimeZones.sql*
