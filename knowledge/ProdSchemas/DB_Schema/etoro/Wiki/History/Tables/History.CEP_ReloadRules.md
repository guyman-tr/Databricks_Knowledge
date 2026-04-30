# History.CEP_ReloadRules

> Audit log of CEP rules engine reload events; each row records who triggered a rules reload and when, providing a chronological record of when the in-memory CEP rule cache was refreshed from the database.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID - IDENTITY PK (no explicit PK constraint; heap) |
| **Partition** | No |
| **Indexes** | 0 (heap - no indexes defined) |

---

## 1. Business Meaning

History.CEP_ReloadRules records each time the CEP (Complex Event Processing) rules engine was signaled to reload its rule configuration from the database. The CEP engine caches its rules in memory for performance; when rules are added, modified, or deleted (causing entries in the CEP_LOG_* tables), the engine needs an explicit reload signal to pick up the new configuration. This table serves as the audit trail for those reload events.

Each reload is triggered via the stored procedure History.CEP_LogReloadRules, called by the application layer. The DBUserName captures the SQL Server login making the call, while AppUserName captures the application-level identity passed by the caller.

With 54 rows and IDENTITY(1,2) stride, this table was written by one server (odd IDs only). A companion server would use IDENTITY(2,2) for even IDs - this is eToro's standard pattern for distributing IDENTITY ranges across multiple application server instances to avoid collisions. The most recent reload was 2026-02-11 by TRAD\Noah.

---

## 2. Business Logic

### 2.1 Rules Engine Reload Signal

**What**: Each row represents one explicit reload of the CEP rules engine.

**Columns/Parameters Involved**: `ID`, `Occurred`, `DBUserName`, `AppUserName`

**Writer procedure**:
```sql
History.CEP_LogReloadRules(@AppUserName nvarchar(255))
  -> INSERT History.CEP_ReloadRules (DBUserName, AppUserName)
     VALUES (SUSER_NAME(), @AppUserName)
     -- Occurred defaults to getutcdate()
```

**Rules**:
- The procedure is called by the application after modifying CEP rules - this entry tells operations when each reload happened and who initiated it
- DBUserName = SQL Server login of the database connection (TRAD domain Windows accounts observed: Noah, dotanva, rivkaya, yardenmo)
- AppUserName = application-layer username passed by the caller (matches the short login name)
- IDENTITY(1,2) stride: this server writes odd IDs (1, 3, 5... 107). A second server would have been configured with IDENTITY(2,2) for even IDs to avoid PK conflicts in a multi-server deployment
- 54 total rows over the observed period indicates infrequent manual reloads (typically triggered by rule configuration deployments)

---

## 3. Data Overview

54 rows. IDENTITY stride of 2; max ID = 107 (last reload: 2026-02-11).

| ID | Occurred | DBUserName | AppUserName |
|---|---|---|---|
| 107 | 2026-02-11 12:28 UTC | TRAD\Noah | noah |
| 105 | 2025-09-28 10:24 UTC | TRAD\dotanva | dotanva |
| 103 | 2025-09-14 09:04 UTC | TRAD\dotanva | dotanva |
| 101 | 2025-06-05 07:23 UTC | TRAD\rivkaya | rivkaya |
| 99 | 2025-06-04 13:31 UTC | TRAD\yardenmo | yardenmo |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | YES | IDENTITY(1,2) | CODE-BACKED | Surrogate identifier. IDENTITY with start=1, increment=2 (odd IDs only for this server). Bigint allows for very long-term logging. No explicit PK constraint in DDL - heap table. |
| 2 | Occurred | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp when the reload was triggered. Defaults to getutcdate() via constraint DF_HistoryCEP_ReloadRules. |
| 3 | DBUserName | nvarchar(255) | YES | - | CODE-BACKED | SQL Server login (SUSER_NAME()) of the connection that called History.CEP_LogReloadRules. Observed values: TRAD domain Windows accounts (TRAD\Noah, TRAD\dotanva, etc.). |
| 4 | AppUserName | nvarchar(255) | YES | - | CODE-BACKED | Application-level username passed by the caller to the stored procedure. Typically the short login name without domain prefix (e.g., "noah", "dotanva"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

No formal references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.CEP_LogReloadRules | DBUserName, AppUserName | Writer | Inserts reload event on CEP engine signal |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CEP_ReloadRules (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.CEP_LogReloadRules | Stored Procedure | Writer - inserts one row per reload event |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. Heap table.

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (none) | - | - | - | - | - |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_HistoryCEP_ReloadRules | DEFAULT | Occurred = getutcdate() |

Storage: ON [DICTIONARY] filegroup. No PK constraint defined.

---

## 8. Sample Queries

### 8.1 Recent reload events
```sql
SELECT TOP 20 ID, Occurred, DBUserName, AppUserName
FROM [History].[CEP_ReloadRules]
ORDER BY Occurred DESC
```

### 8.2 Reloads by user
```sql
SELECT AppUserName, COUNT(*) AS ReloadCount, MAX(Occurred) AS LastReload
FROM [History].[CEP_ReloadRules]
GROUP BY AppUserName
ORDER BY ReloadCount DESC
```

### 8.3 Reload frequency over time
```sql
SELECT CAST(FLOOR(CAST(Occurred AS float)) AS datetime) AS ReloadDay,
       COUNT(*) AS ReloadCount
FROM [History].[CEP_ReloadRules]
GROUP BY CAST(FLOOR(CAST(Occurred AS float)) AS datetime)
ORDER BY ReloadDay DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (History.CEP_LogReloadRules) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CEP_ReloadRules | Type: Table | Source: etoro/etoro/History/Tables/History.CEP_ReloadRules.sql*
