# History.TradeInstrumentGroups

> SQL Server system-versioned temporal history table for Trade.InstrumentGroups - stores superseded provider/instrument/group membership records, enabling point-in-time auditing of instrument group assignments.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No - stored on [DICTIONARY] filegroup with PAGE compression |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.TradeInstrumentGroups is the temporal history backing table for Trade.InstrumentGroups, which maps instruments to trading groups (Dictionary.TradingInstrumentGroups) for each liquidity provider. When an instrument's group assignment is added, changed, or removed in Trade.InstrumentGroups, SQL Server's system-versioning automatically archives the old row version here with SysStartTime/SysEndTime period columns indicating when that assignment was active.

Instrument groups are used to categorize instruments for the purpose of applying shared trading rules, fee schedules, or leverage tiers. The history table allows auditing: which group was an instrument in at a given point in time, and when were group assignments changed.

Trade.InstrumentGroups has FKs to Dictionary.TradingInstrumentGroups and Trade.ProviderToInstrument - both relationships are preserved in the history row for full context at time of change.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Each change to Trade.InstrumentGroups produces a history row with SysStartTime/SysEndTime capturing when the group assignment was active.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ProviderID`, `InstrumentID`, `GroupID`

**Rules**:
- SysStartTime = when this row version became active in Trade.InstrumentGroups
- SysEndTime = when this row version was superseded (by update or delete)
- SysEndTime leading the clustered index optimizes point-in-time range queries
- DbLoginName and AppLoginName are computed columns captured at DML time and preserved in the history row
- SQL Server writes here automatically - no direct INSERT by application code

---

## 3. Data Overview

Table is typically empty or sparsely populated in non-production environments. Rows accumulate in production each time an instrument's group membership changes.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | INT | NO | - | CODE-BACKED | Liquidity provider identifier. Part of the composite key in Trade.InstrumentGroups (FK to Trade.ProviderToInstrument). Identifies which provider's instrument assignment changed. |
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. Part of composite FK to Trade.ProviderToInstrument(ProviderID, InstrumentID). Identifies which instrument's group membership was changed. |
| 3 | GroupID | INT | NO | - | CODE-BACKED | Trading group identifier. FK to Dictionary.TradingInstrumentGroups in the source table. Identifies the instrument group that was assigned at time SysStartTime. |
| 4 | SysStartTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this group assignment became active in Trade.InstrumentGroups. Set automatically by SQL Server system-versioning. |
| 5 | SysEndTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this group assignment was superseded. Clustered index leading column for efficient temporal range queries. Set automatically by SQL Server. |
| 6 | DbLoginName | NVARCHAR(128) | YES | NULL | CODE-BACKED | SQL Server login name of the session that made the change, captured via suser_name() computed column in Trade.InstrumentGroups. Preserved in history for change attribution. |
| 7 | AppLoginName | VARCHAR(500) | YES | NULL | CODE-BACKED | Application-level login name captured from context_info() at DML time. Application code sets context_info before executing DML to identify the calling service or user. Preserved for change attribution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID + InstrumentID | Trade.ProviderToInstrument | Temporal (inherited) | Historical snapshot of which provider/instrument combination had this group assignment. |
| GroupID | Dictionary.TradingInstrumentGroups | Temporal (inherited) | Historical snapshot of the group that was assigned. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InstrumentGroups | SYSTEM_VERSIONING | Temporal parent | Automatically writes superseded rows here on every change. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.TradeInstrumentGroups (table)
  (leaf - temporal history table; no DDL-level code dependencies)
```

### 6.1 Objects This Depends On

No hard DDL dependencies. Temporal relationship managed by SQL Server system-versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentGroups | Table | Temporal parent - writes superseded row versions here automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_TradeInstrumentGroups | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

None. Temporal history tables have no PK, FK, or CHECK constraints.

---

## 8. Sample Queries

### 8.1 View instrument group assignments as of a specific date
```sql
SELECT ig.ProviderID, ig.InstrumentID, ig.GroupID, ig.SysStartTime, ig.SysEndTime
FROM Trade.InstrumentGroups
FOR SYSTEM_TIME AS OF '2024-01-01T00:00:00'
ORDER BY ig.InstrumentID;
```

### 8.2 Audit history of group changes for a specific instrument
```sql
SELECT h.ProviderID, h.InstrumentID, h.GroupID, h.SysStartTime, h.SysEndTime, h.DbLoginName, h.AppLoginName
FROM History.TradeInstrumentGroups h WITH (NOLOCK)
WHERE h.InstrumentID = 7
ORDER BY h.SysStartTime;
```

### 8.3 Find all instruments that were ever in a specific group
```sql
SELECT DISTINCT h.InstrumentID, h.GroupID, h.SysStartTime, h.SysEndTime
FROM History.TradeInstrumentGroups h WITH (NOLOCK)
WHERE h.GroupID = 5
ORDER BY h.InstrumentID, h.SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 (temporal - SQL Server managed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.TradeInstrumentGroups | Type: Table | Source: etoro/etoro/History/Tables/History.TradeInstrumentGroups.sql*
