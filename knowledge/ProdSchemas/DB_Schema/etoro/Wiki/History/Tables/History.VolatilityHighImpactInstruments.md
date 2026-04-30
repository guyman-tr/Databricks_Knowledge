# History.VolatilityHighImpactInstruments

> SQL Server system-versioned temporal history table for Trade.VolatilityHighImpactInstruments - stores superseded records of instruments flagged as high-volatility/high-impact, enabling point-in-time auditing of when instruments were placed under or removed from volatility restrictions.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No - stored on [PRIMARY] with PAGE compression |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.VolatilityHighImpactInstruments is the temporal history backing table for Trade.VolatilityHighImpactInstruments, which is a simple allowlist of instruments that are currently classified as high-volatility or high-impact. Being on this list may trigger special trading restrictions, wider spreads, reduced leverage limits, or suspension of position opening during extreme market events (e.g., earnings announcements, index rebalances, major geopolitical events).

When an instrument is added to or removed from the high-volatility list, SQL Server system-versioning archives the old row here. This allows compliance and risk teams to reconstruct the list at any point in time - for example, to demonstrate that an instrument was restricted during a specific market event when a customer complaint arises.

Trade.VolatilityHighImpactInstruments has only InstrumentID as a business column (single-column table with no metadata beyond the temporal audit fields), making it a pure boolean flag list: if InstrumentID is in the table, it is currently high-impact.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Each addition or removal of an instrument from the high-volatility list produces a history row.

**Columns/Parameters Involved**: `InstrumentID`, `SysStartTime`, `SysEndTime`

**Rules**:
- A row in Trade.VolatilityHighImpactInstruments = instrument IS currently high-impact
- Absence = not high-impact
- History rows capture: when an instrument was added (SysStartTime) and when it was removed (SysEndTime)
- Multiple history rows for the same InstrumentID show it was flagged, removed, and re-flagged over time
- DbLoginName and AppLoginName capture who made the volatility list change

---

## 3. Data Overview

Table is typically empty in non-production environments. Production accumulates rows each time instruments are added or removed from the volatility list.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | The instrument that was flagged as (or removed from) high-volatility/high-impact classification. PK in source table (single-column PK = boolean flag list). |
| 2 | DbLoginName | NVARCHAR(128) | YES | NULL | CODE-BACKED | SQL Server login that made the volatility list change (suser_name() at DML time). Captured for audit/risk attribution. |
| 3 | AppLoginName | VARCHAR(500) | YES | NULL | CODE-BACKED | Application login from context_info() at DML time. Identifies which risk management tool or service added/removed the instrument. |
| 4 | SysStartTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this instrument was added to the high-volatility list. SQL Server system-versioning managed. |
| 5 | SysEndTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this instrument was removed from the high-volatility list. Clustered index leading column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Temporal (inherited) | Historical snapshot of which instrument was on the high-volatility list. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.VolatilityHighImpactInstruments | SYSTEM_VERSIONING | Temporal parent | Writes superseded volatility flag records here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.VolatilityHighImpactInstruments (table)
  (leaf - temporal history table)
```

### 6.1 Objects This Depends On

No hard DDL dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.VolatilityHighImpactInstruments | Table | Temporal parent - writes superseded flag records automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_VolatilityHighImpactInstruments | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

None. Temporal history tables have no PK, FK, or CHECK constraints.

---

## 8. Sample Queries

### 8.1 View currently high-impact instruments
```sql
SELECT v.InstrumentID, v.SysStartTime AS FlaggedSince, v.DbLoginName
FROM Trade.VolatilityHighImpactInstruments v WITH (NOLOCK)
ORDER BY v.InstrumentID;
```

### 8.2 View which instruments were flagged at a specific time
```sql
SELECT v.InstrumentID, v.SysStartTime, v.SysEndTime
FROM Trade.VolatilityHighImpactInstruments
FOR SYSTEM_TIME AS OF '2024-01-15T14:00:00'
ORDER BY v.InstrumentID;
```

### 8.3 Audit the volatility flag history for a specific instrument
```sql
SELECT h.InstrumentID, h.SysStartTime AS FlaggedAt, h.SysEndTime AS RemovedAt,
       h.DbLoginName, h.AppLoginName
FROM History.VolatilityHighImpactInstruments h WITH (NOLOCK)
WHERE h.InstrumentID = 7
ORDER BY h.SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 (temporal - SQL Server managed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.VolatilityHighImpactInstruments | Type: Table | Source: etoro/etoro/History/Tables/History.VolatilityHighImpactInstruments.sql*
