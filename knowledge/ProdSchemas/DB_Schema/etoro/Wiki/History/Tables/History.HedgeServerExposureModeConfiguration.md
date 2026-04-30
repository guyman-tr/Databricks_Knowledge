# History.HedgeServerExposureModeConfiguration

> SQL Server system-versioned temporal history table for Hedge.HedgeServerExposureModeConfiguration, recording every change to the mapping between hedge servers and the exposure modes they support.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ServerID, ExposureModeID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [PRIMARY] filegroup) |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Hedge.HedgeServerExposureModeConfiguration`. SQL Server's system-versioning manages this table transparently: whenever a row in `Hedge.HedgeServerExposureModeConfiguration` is inserted, updated, or deleted, the previous row state is written here with SysStartTime/SysEndTime bracketing the validity window.

`Hedge.HedgeServerExposureModeConfiguration` defines which exposure modes each hedge server supports. An "exposure mode" governs how the hedging engine calculates and manages net exposure - the strategy used to aggregate, offset, or route positions to liquidity providers. A hedge server may support multiple exposure modes simultaneously, making this a many-to-many association table between hedge servers and their exposure calculation strategies.

The four exposure modes (from `Dictionary.HedgeServerExposureMode`):

| ExposureModeID | Description | Meaning |
|---|---|---|
| 0 | Normal | Standard per-instrument exposure hedging mode |
| 1 | Major | Major instrument/currency hedging mode - potentially different aggregation rules |
| 2 | Portfolio | Portfolio-level hedging - netting positions across instruments before routing |
| 3 | SpotExposureMode | Spot/immediate execution exposure mode |

The INSERT trigger fires a no-op UPDATE to capture newly inserted rows in temporal history. 0 rows in this environment.

---

## 2. Business Logic

### 2.1 Hedge Server Exposure Mode Assignment

**What**: Each hedge server is assigned one or more exposure modes. The configuration determines which exposure calculation strategies are active for a given server.

**Columns/Parameters Involved**: `ServerID`, `ExposureModeID`

**Rules**:
- Composite PK: (ServerID, ExposureModeID) - a server can have multiple exposure modes; an exposure mode can be assigned to multiple servers
- FK: ServerID -> Trade.HedgeServer(HedgeServerID)
- FK: ExposureModeID -> Dictionary.HedgeServerExposureMode(ExposureModeID): 0=Normal, 1=Major, 2=Portfolio, 3=SpotExposureMode
- FILLFACTOR=95 on source PK: appropriate for a small, near-static configuration table
- Rows are added when a new exposure mode is enabled for a server; rows are deleted (captured in history) when a mode is deactivated

### 2.2 INSERT Trigger Capture Pattern

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- INSERT trigger `TRG_T_HedgeServerExposureModeConfiguration` fires a no-op UPDATE (SET ServerID=ServerID) joining on (ServerID, ExposureModeID) to force SQL Server to write the newly inserted row into temporal history
- Zero-duration rows (SysStartTime = SysEndTime) mark INSERT captures
- DbLoginName: suser_name() computed column in source, materialized in history
- AppLoginName: CONVERT(varchar(500), context_info()) computed column in source, materialized in history

---

## 3. Data Overview

| Scale | Value |
|-------|-------|
| Total rows | 0 (dev environment - table not deployed) |
| Source table | Hedge.HedgeServerExposureModeConfiguration |
| Exposure modes | 4 (0=Normal, 1=Major, 2=Portfolio, 3=SpotExposureMode) |
| Filegroup | [PRIMARY] |

In production, this table has one row per active (server, exposure mode) pair. Given the small number of hedge servers and 4 exposure modes, the total row count is small. Changes are rare operational configuration events.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ServerID | int | NO | - | CODE-BACKED | The hedge server assigned this exposure mode. Part of the composite PK. FK to Trade.HedgeServer(HedgeServerID). Identifies which hedging engine instance supports this exposure calculation strategy. |
| 2 | ExposureModeID | int | NO | - | VERIFIED | The exposure mode enabled for this server. Part of the composite PK. FK to Dictionary.HedgeServerExposureMode(ExposureModeID): 0=Normal, 1=Major, 2=Portfolio, 3=SpotExposureMode. |
| 3 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login (suser_name()) at time of change. Computed column in source, materialized in history. |
| 4 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context from context_info() at time of change. May contain operator email or service identifier. |
| 5 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this server-exposure mode assignment became active. Source DEFAULT=getutcdate(). For INSERT-trigger-captured rows, equals SysEndTime. |
| 6 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this assignment was superseded (mode deactivated for this server). CLUSTERED index leading column. Source DEFAULT='9999-12-31'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ServerID | Trade.HedgeServer | Implicit | Hedge server that supports this exposure mode. FK enforced on source as FK_HSEMC_HS_HedgeServerID. |
| ExposureModeID | Dictionary.HedgeServerExposureMode | Implicit | Exposure calculation strategy. FK enforced on source as FK_HSEMC_HSEM_ExposureModeID. 0=Normal, 1=Major, 2=Portfolio, 3=SpotExposureMode. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.HedgeServerExposureModeConfiguration | SYSTEM_VERSIONING | Temporal history source | All superseded row versions routed here; INSERT trigger captures creations. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.HedgeServerExposureModeConfiguration (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerExposureModeConfiguration | Table | Source temporal table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_HedgeServerExposureModeConfiguration | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [PRIMARY] filegroup) |

### 7.2 Constraints

None on history table. Source table has:
- CLUSTERED PK on (ServerID, ExposureModeID) (FILLFACTOR=95, DATA_COMPRESSION=PAGE)
- FK_HSEMC_HS_HedgeServerID: ServerID -> Trade.HedgeServer(HedgeServerID)
- FK_HSEMC_HSEM_ExposureModeID: ExposureModeID -> Dictionary.HedgeServerExposureMode(ExposureModeID)

---

## 8. Sample Queries

### 8.1 Current exposure mode assignments per server

```sql
SELECT
    semc.ServerID,
    hs.Name AS HedgeServerName,
    semc.ExposureModeID,
    hsem.Description AS ExposureModeName
FROM Hedge.HedgeServerExposureModeConfiguration semc WITH (NOLOCK)
JOIN Trade.HedgeServer hs WITH (NOLOCK) ON hs.HedgeServerID = semc.ServerID
JOIN Dictionary.HedgeServerExposureMode hsem WITH (NOLOCK) ON hsem.ExposureModeID = semc.ExposureModeID
ORDER BY semc.ServerID, semc.ExposureModeID;
```

### 8.2 History of exposure mode changes per server

```sql
SELECT
    h.ServerID,
    h.ExposureModeID,
    hsem.Description AS ExposureModeName,
    h.DbLoginName AS ChangedBy,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    DATEDIFF(DAY, h.SysStartTime, h.SysEndTime) AS DaysActive
FROM History.HedgeServerExposureModeConfiguration h WITH (NOLOCK)
JOIN Dictionary.HedgeServerExposureMode hsem WITH (NOLOCK) ON hsem.ExposureModeID = h.ExposureModeID
WHERE h.ServerID = @ServerID
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100
ORDER BY h.SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.HedgeServerExposureModeConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.HedgeServerExposureModeConfiguration.sql*
