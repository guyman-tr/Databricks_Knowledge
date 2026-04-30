# History.CalendarProviderExchanges

> Temporal history table storing prior versions of Market.CalendarProviderExchanges rows - tracks all changes to provider-exchange registrations over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime, SysStartTime) via clustered index |
| **Partition** | No |
| **Indexes** | 1 active (Clustered on temporal columns) |

---

## 1. Business Meaning

This table is the temporal history companion of `Market.CalendarProviderExchanges`. SQL Server automatically moves superseded row versions here whenever a provider-exchange registration is updated or deleted. Each row preserves a prior version of the mapping between a calendar provider and an exchange, with exact validity timestamps.

This enables auditing which exchanges were registered for which providers at any point in time. Currently contains 550 rows, reflecting historical changes to the 27 current Xignite exchange registrations (the bulk registration on 2026-03-05 generated initial history entries via the INSERT trigger's self-update pattern).

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Standard History schema pattern - system-versioned temporal history target.

**Rules**:
- Row moved here on UPDATE/DELETE of parent table row
- SysStartTime/SysEndTime define the validity period
- Clustered index on (SysEndTime, SysStartTime) for temporal range queries
- PAGE compression for storage efficiency
- DbLoginName/AppLoginName materialized (not computed)

---

## 3. Data Overview

550 rows. Reflects changes to provider-exchange registrations, including the initial bulk load history entries.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | Calendar data provider ID at time of this version. 0=eToro, 1=Xignite. |
| 2 | ExchangeID | int | NO | - | CODE-BACKED | Exchange identifier at time of this version. |
| 3 | ExchangeName | varchar(250) | NO | - | CODE-BACKED | ISO MIC code at time of this version (e.g., XNAS, XNYS, XLON). |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that made the change. Materialized. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application session identity at time of change. Materialized. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | When this row version became active. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | When this row version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.CalendarProviderExchanges | SYSTEM_VERSIONING | Temporal History | Parent temporal table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.CalendarProviderExchanges | Table | Parent temporal table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_CalendarProviderExchanges | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Reduces storage for historical data |

---

## 8. Sample Queries

### 8.1 View registration history for an exchange

```sql
SELECT ProviderID, ExchangeID, ExchangeName, SysStartTime, SysEndTime
FROM History.CalendarProviderExchanges WITH (NOLOCK)
WHERE ExchangeID = 4
ORDER BY SysStartTime;
```

### 8.2 Point-in-time: what exchanges were registered on a specific date

```sql
SELECT ProviderID, ExchangeID, ExchangeName
FROM Market.CalendarProviderExchanges
FOR SYSTEM_TIME AS OF '2025-01-01T00:00:00'
ORDER BY ExchangeID;
```

### 8.3 Find exchanges that were removed (exist in history but not current)

```sql
SELECT DISTINCT h.ProviderID, h.ExchangeID, h.ExchangeName
FROM History.CalendarProviderExchanges h WITH (NOLOCK)
LEFT JOIN Market.CalendarProviderExchanges c WITH (NOLOCK) ON h.ProviderID = c.ProviderID AND h.ExchangeID = c.ExchangeID
WHERE c.ProviderID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. See [Market.CalendarProviderExchanges](../../Market/Tables/Market.CalendarProviderExchanges.md) for business context.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CalendarProviderExchanges | Type: Table | Source: CalendarDB/CalendarDB/History/Tables/History.CalendarProviderExchanges.sql*
