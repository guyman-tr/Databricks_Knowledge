# History.InstrumentTimeZones

> Temporal history table storing prior versions of Market.InstrumentTimeZones rows - tracks all changes to instrument-specific timezone overrides over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime, SysStartTime) via clustered index |
| **Partition** | No |
| **Indexes** | 1 active (Clustered on temporal columns) |

---

## 1. Business Meaning

This table is the temporal history companion of `Market.InstrumentTimeZones`. Superseded instrument timezone override versions are automatically archived here by SQL Server system versioning. Currently contains 9 rows, reflecting a small number of changes to the 15 current instrument timezone overrides.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Standard History schema pattern - system-versioned temporal history target with PAGE compression and clustered index on (SysEndTime, SysStartTime).

---

## 3. Data Overview

9 rows. Reflects timezone corrections for specific instruments.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier at time of this version. |
| 2 | TimeZone | varchar(1000) | NO | - | CODE-BACKED | Windows timezone identifier at time of this version. |
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
| Market.InstrumentTimeZones | SYSTEM_VERSIONING | Temporal History | Parent temporal table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.InstrumentTimeZones | Table | Parent temporal table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InstrumentTimeZones | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Reduces storage for historical data |

---

## 8. Sample Queries

### 8.1 View timezone change history for an instrument

```sql
SELECT InstrumentID, TimeZone, SysStartTime, SysEndTime
FROM History.InstrumentTimeZones WITH (NOLOCK)
ORDER BY InstrumentID, SysStartTime;
```

### 8.2 Point-in-time query

```sql
SELECT InstrumentID, TimeZone
FROM Market.InstrumentTimeZones
FOR SYSTEM_TIME AS OF '2024-01-01T00:00:00';
```

### 8.3 Find instruments whose timezone was changed

```sql
SELECT DISTINCT h.InstrumentID, h.TimeZone AS OldTZ, c.TimeZone AS CurrentTZ
FROM History.InstrumentTimeZones h WITH (NOLOCK)
JOIN Market.InstrumentTimeZones c WITH (NOLOCK) ON h.InstrumentID = c.InstrumentID
WHERE h.TimeZone <> c.TimeZone;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. See [Market.InstrumentTimeZones](../../Market/Tables/Market.InstrumentTimeZones.md) for business context.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstrumentTimeZones | Type: Table | Source: CalendarDB/CalendarDB/History/Tables/History.InstrumentTimeZones.sql*
