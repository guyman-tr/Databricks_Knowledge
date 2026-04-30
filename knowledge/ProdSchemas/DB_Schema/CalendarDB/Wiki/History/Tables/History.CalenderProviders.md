# History.CalenderProviders

> Temporal history table automatically managed by SQL Server system versioning, storing prior versions of Market.CalenderProviders rows for audit trail and point-in-time queries.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime, SysStartTime) via clustered index |
| **Partition** | No |
| **Indexes** | 1 active (Clustered on temporal columns) |

---

## 1. Business Meaning

This table is the temporal history companion of `Market.CalenderProviders`. SQL Server's system versioning feature automatically moves superseded row versions here whenever a row in the parent table is updated or deleted. Each row represents a prior version of a provider record, with `SysStartTime` and `SysEndTime` defining the validity period.

This enables full audit trail of provider configuration changes and point-in-time queries using `FOR SYSTEM_TIME AS OF` syntax. For example, if a provider name was changed, the old name is preserved here with exact timestamps.

The table is never written to directly by application code - SQL Server manages it automatically. Currently contains 0 rows (the 2 providers in Market.CalenderProviders have never been modified since initial creation on 2021-09-13).

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: All History schema tables follow the same pattern - they are the system-versioned history target for their corresponding Market schema table.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- When a row in Market.CalenderProviders is UPDATED, the old version is moved here with SysEndTime set to the update timestamp
- When a row is DELETED, the final version is moved here
- SysStartTime = when this version became active, SysEndTime = when it was superseded
- The clustered index on (SysEndTime, SysStartTime) optimizes temporal range queries
- PAGE compression reduces storage for historical data
- Unlike the parent table, DbLoginName and AppLoginName are materialized columns (not computed) since computed columns cannot exist in history tables

---

## 3. Data Overview

Table is currently empty (0 rows). The 2 providers (eToro=0, Xignite=1) have never been modified since initial creation.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | Calendar data provider identifier. Mirrors Market.CalenderProviders.ProviderID. 0=eToro, 1=Xignite. |
| 2 | ProviderName | varchar(250) | NO | - | CODE-BACKED | Provider name at the time this version was active. |
| 3 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that made the change. Materialized (not computed) - captures the value at the time of the change. NULL if not set. |
| 4 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application session identity at time of change. Materialized from context_info(). NULL if not set. |
| 5 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version became active in the parent table. |
| 6 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version was superseded (replaced by a newer version or deleted). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.CalenderProviders | SYSTEM_VERSIONING | Temporal History | SQL Server automatically manages this table as the history target |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.CalenderProviders | Table | Parent temporal table - system versioning writes history here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_CalenderProviders | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Reduces storage footprint for historical data |

---

## 8. Sample Queries

### 8.1 View all historical versions of providers

```sql
SELECT ProviderID, ProviderName, SysStartTime, SysEndTime
FROM History.CalenderProviders WITH (NOLOCK)
ORDER BY ProviderID, SysStartTime;
```

### 8.2 Point-in-time query via parent table

```sql
SELECT ProviderID, ProviderName
FROM Market.CalenderProviders
FOR SYSTEM_TIME AS OF '2023-01-01T00:00:00'
ORDER BY ProviderID;
```

### 8.3 View all versions (current + history) for a provider

```sql
SELECT ProviderID, ProviderName, SysStartTime, SysEndTime, 'Current' AS Source
FROM Market.CalenderProviders WITH (NOLOCK)
WHERE ProviderID = 0
UNION ALL
SELECT ProviderID, ProviderName, SysStartTime, SysEndTime, 'History'
FROM History.CalenderProviders WITH (NOLOCK)
WHERE ProviderID = 0
ORDER BY SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. See [Market.CalenderProviders](../Market/Tables/Market.CalenderProviders.md) for business context.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CalenderProviders | Type: Table | Source: CalendarDB/CalendarDB/History/Tables/History.CalenderProviders.sql*
