# Hedge.HedgeServerExposureModeConfiguration

> CBH exposure mode subscription table: defines which exposure streams each hedge server subscribes to (Normal, Majors, Portfolio, Spot); a server with multiple rows handles multiple exposure modes concurrently; versioned via SQL Server temporal tables.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (ServerID, ExposureModeID) composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on ServerID + ExposureModeID) |
| **Temporal** | Yes - SYSTEM_VERSIONING ON (HISTORY_TABLE = History.HedgeServerExposureModeConfiguration) |

---

## 1. Business Meaning

Hedge.HedgeServerExposureModeConfiguration defines the **CBH (Customer Based Hedging) exposure mode subscriptions** for each hedge server. In CBH, the HedgeServer subscribes to CES (Central Exposure Service) exposure notifications on specific "exposure streams" - Normal, Majors, Portfolio, or Spot. This table tells the HedgeServer which stream(s) to subscribe to.

**CBH Exposure Modes** (from HedgeServer Overview Confluence):
- **Normal (0)**: HedgeServer subscribes to Normal Exposure notifications and hedges according to them. The default for almost all servers.
- **Majors (1)**: HedgeServer subscribes to Majors Exposure notifications. Used for major/liquid instruments with tighter hedging thresholds.
- **Portfolio (2)**: HedgeServer subscribes to Portfolio Exposure notifications (basket-level hedging). Not observed in this environment.
- **Spot (3)**: HedgeServer subscribes to Spot Exposure notifications (immediate pass-through hedging). Not observed in this environment.

Most hedge servers have exactly one row (ExposureModeID=0, Normal). Two servers - ServerID=5 and ServerID=82 - have two rows each (Normal + Majors), indicating they handle both standard and major-instrument exposure streams concurrently.

The composite PK (ServerID, ExposureModeID) means the same server can appear multiple times with different ExposureModeIDs - one row per subscription.

No stored procedures read this table - the HedgeServer application reads it directly at startup to configure its exposure stream subscriptions.

**48 rows** | All created 2021-09-13 (initial population) | 47 unique ServerIDs | 2 servers with dual mode (0+1)

---

## 2. Business Logic

### 2.1 Multi-Mode Servers

**What**: A hedge server can subscribe to multiple exposure streams simultaneously.

**Columns/Parameters Involved**: `ServerID`, `ExposureModeID`

**Rules**:
- The PK allows (ServerID=5, ExposureModeID=0) AND (ServerID=5, ExposureModeID=1) to coexist.
- ServerID=5 and ServerID=82 both have ExposureModeID 0 (Normal) AND 1 (Majors).
- All other 45 servers have only ExposureModeID=0 (Normal).
- When a server processes multiple modes, it subscribes to both CES streams and applies the appropriate hedging strategy for each.

### 2.2 ServerID=0 (Virtual/Global Server)

**What**: ServerID=0 appears as a row with ExposureModeID=0, though ServerID=0 is not a standard physical hedge server.

**Columns/Parameters Involved**: `ServerID`

**Rules**:
- ServerID=0 may represent a global or virtual server entry, or a legacy configuration row from the initial bulk load.
- FK to Trade.HedgeServer validates that ServerID=0 exists in the HedgeServer table.

### 2.3 Temporal Versioning with INSERT Trigger

**What**: Configuration changes are versioned; the INSERT trigger ensures initial rows get a proper SysStartTime.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `TRG_T_HedgeServerExposureModeConfiguration`

**Rules**:
- Same pattern as FIXConnections/FIXConnectionDetails: FOR INSERT trigger performs a no-op UPDATE on (ServerID, ExposureModeID) to force temporal engine to capture SysStartTime on INSERT.
- All 48 current rows have SysStartTime = 2021-09-13 05:26:06 (the initial bulk load date).
- Changes are tracked in History.HedgeServerExposureModeConfiguration.
- Explicit DEFAULT constraints for SysStartTime (GETUTCDATE()) and SysEndTime ('9999-12-31 23:59:59.9999999').

---

## 3. Data Overview

48 rows | All SysStartTime = 2021-09-13 | 47 distinct ServerIDs | 2 dual-mode servers

| ServerID | ExposureModeID | Mode Name |
|---|---|---|
| 0 | 0 | Normal |
| 1 | 0 | Normal |
| 2 | 0 | Normal |
| 3 | 0 | Normal |
| 5 | 0 | Normal |
| 5 | 1 | Majors |
| 82 | 0 | Normal |
| 82 | 1 | Majors |
| 100003 | 0 | Normal |
| ... (all others) | 0 | Normal |

All ExposureModeID=2 (Portfolio) and ExposureModeID=3 (Spot) have zero rows in this environment.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). The hedge server instance that subscribes to this exposure mode. Part of composite PK. A server can appear multiple times if it subscribes to multiple modes. |
| 2 | ExposureModeID | int | NO | - | CODE-BACKED | FK to Dictionary.HedgeServerExposureMode. The exposure stream this server subscribes to: 0=Normal, 1=Majors, 2=Portfolio, 3=Spot. Part of composite PK. In this environment only 0 (Normal) and 1 (Majors) are used. |
| 3 | DbLoginName | varchar(computed) | - | suser_name() | CODE-BACKED | Computed column: SQL Server login name of the session that last wrote this row. Audit trail for configuration changes. |
| 4 | AppLoginName | varchar(500, computed) | - | context_info() | CODE-BACKED | Computed column: Application identity from session context_info(). Complements DbLoginName. |
| 5 | SysStartTime | datetime2(7) | NO | GETUTCDATE() | CODE-BACKED | Temporal row start time (UTC). Explicit DEFAULT GETUTCDATE(). Populated on INSERT via FOR INSERT trigger. All current rows: 2021-09-13 (initial load). |
| 6 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | Temporal row end time (UTC). Explicit DEFAULT '9999-12-31 23:59:59.9999999'. Set to actual end time in History table for superseded rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExposureModeID | Dictionary.HedgeServerExposureMode | FK (WITH CHECK) | FK_HSEMC_HSEM_ExposureModeID |
| ServerID | Trade.HedgeServer | FK (WITH CHECK) | FK_HSEMC_HS_HedgeServerID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| HedgeServer application | Direct SQL read | Reader | Reads at startup to configure CBH exposure stream subscriptions |
| History.HedgeServerExposureModeConfiguration | - | Temporal history | Stores superseded configuration versions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.HedgeServerExposureModeConfiguration (temporal table)
  - FK: Dictionary.HedgeServerExposureMode (ExposureModeID)
  - FK: Trade.HedgeServer (ServerID)
  - History: History.HedgeServerExposureModeConfiguration
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.HedgeServerExposureMode | Table | FK target: validates ExposureModeID (0=Normal, 1=Majors, 2=Portfolio, 3=Spot) |
| Trade.HedgeServer | Table | FK target: validates ServerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.HedgeServerExposureModeConfiguration | Table | Temporal history table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeServerExposureMode | CLUSTERED PK | ServerID ASC, ExposureModeID ASC | - | - | Active (FILLFACTOR=95, PAGE compression, PRIMARY filegroup) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeServerExposureMode | PRIMARY KEY (CLUSTERED) | (ServerID, ExposureModeID) - unique server+mode combination |
| FK_HSEMC_HSEM_ExposureModeID | FOREIGN KEY (WITH CHECK) | ExposureModeID -> Dictionary.HedgeServerExposureMode |
| FK_HSEMC_HS_HedgeServerID | FOREIGN KEY (WITH CHECK) | ServerID -> Trade.HedgeServer |
| DF_HedgeServerExposureModeConfiguration_SysStart | DEFAULT | SysStartTime = GETUTCDATE() |
| DF_HedgeServerExposureModeConfiguration_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |

### 7.3 Triggers

| Trigger Name | Event | Purpose |
|-------------|-------|---------|
| TRG_T_HedgeServerExposureModeConfiguration | FOR INSERT | No-op UPDATE on (ServerID, ExposureModeID) forces temporal engine to record SysStartTime on INSERT. Same pattern as FIXConnections. |

---

## 8. Sample Queries

### 8.1 All servers with their exposure mode subscriptions
```sql
SELECT hsem.ServerID, em.ExposureModeID, em.Description AS ExposureMode,
       hsem.SysStartTime
FROM Hedge.HedgeServerExposureModeConfiguration hsem WITH (NOLOCK)
JOIN Dictionary.HedgeServerExposureMode em WITH (NOLOCK)
    ON em.ExposureModeID = hsem.ExposureModeID
ORDER BY hsem.ServerID, hsem.ExposureModeID;
```

### 8.2 Servers subscribed to multiple modes
```sql
SELECT ServerID, COUNT(1) AS ModeCount,
       STRING_AGG(CAST(ExposureModeID AS varchar), ',') AS Modes
FROM Hedge.HedgeServerExposureModeConfiguration WITH (NOLOCK)
GROUP BY ServerID
HAVING COUNT(1) > 1;
```

### 8.3 Configuration history for a server
```sql
SELECT ServerID, ExposureModeID, SysStartTime, SysEndTime
FROM Hedge.HedgeServerExposureModeConfiguration FOR SYSTEM_TIME ALL
WHERE ServerID = 5
ORDER BY SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Findings |
|--------|------|-------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | CBH Exposure Modes: Normal (subscribes to Normal Exposure notifications), Majors (Majors Exposure), Portfolio (Portfolio Exposure), Spot (Spot Exposure). The mode determines which CES stream the HedgeServer subscribes to. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.HedgeServerExposureModeConfiguration | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.HedgeServerExposureModeConfiguration.sql*
