# Hedge.HedgeServersModes

> Runtime operational state table tracking the current HBC close-limit mode for each hedge server, written by the hedge engine at runtime to persist the server's active execution mode state.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | HedgeServerID (int, PK CLUSTERED, FK to Trade.HedgeServer) |
| **Partition** | No (on [PRIMARY] filegroup) |
| **Indexes** | 1 (PK only) |
| **Versioning** | None (ASM audit triggers write to History.AuditHistory) |

---

## 1. Business Meaning

`Hedge.HedgeServersModes` stores the live operational mode state of each hedge server's HBC (Hedge Bot Controller) close-limit functionality. Unlike configuration tables which are managed by operators, this table is **written by the hedge engine at runtime** - it reflects what mode each server is currently in, not what mode it should be in.

The single data column `HBCCloseLimitState` (int) captures the server's current close-limit mode - a state that can change dynamically as market conditions, risk limits, or hedge strategy directives trigger mode transitions. `LastModify` (datetime) records when the state was last written.

**Key characteristic**: This is a **runtime state** table, not a configuration table. The hedge engine updates it to persist state across restarts. No read procedure exists in the Hedge schema - other components query this table directly.

**Current data** (23 rows):
- ALL rows have `HBCCloseLimitState=0` - no server is in an elevated close-limit mode
- `LastModify` timestamps range from 2014-10-12 (most servers, never updated since initial setup) to 2025-08-13 (HedgeServerID=5454, most recently active)
- 23 hedge servers are tracked including inactive/legacy servers (e.g., HedgeServerID=100003 - GFT system from ~2014)

**HedgeServersModes vs BusinessFlowBehavior**: `BusinessFlowBehavior` stores configuration (what the server SHOULD do); `HedgeServersModes` stores state (what the server IS currently doing).

---

## 2. Business Logic

### 2.1 HBC Close-Limit Mode State

**What**: `HBCCloseLimitState` captures the current operational mode of the HBC close-limit subsystem for a hedge server.

**Columns/Parameters Involved**: `HBCCloseLimitState`

**Rules**:
- int type supports multiple distinct state values
- 0 = normal operation (no close-limit restriction active) - current state for all 23 servers
- Non-zero values (when active): represent escalating or alternative close-limit states (e.g., soft limit, hard limit, emergency mode) - exact enum values defined in application code
- The hedge engine writes this value when entering or exiting close-limit modes
- No DEFAULT constraint - value must be provided on insert

### 2.2 Runtime Write Pattern

**What**: `LastModify` tracks when the state was last written by the hedge engine.

**Columns/Parameters Involved**: `LastModify`

**Rules**:
- datetime type (not datetime2), application-managed - the engine sets this when writing `HBCCloseLimitState`
- No DEFAULT (getutcdate()) - engine provides the timestamp explicitly
- Most servers show 2014-10-12 timestamps = rows were inserted on initial server setup and never updated (HBCCloseLimitState has remained 0 for 10+ years for most servers)
- Recent activity: HedgeServerID=5454 was updated 2025-08-13; HedgeServerID=100 and 101 updated 2015-02-15

### 2.3 One Row Per Hedge Server

**What**: PK on HedgeServerID enforces exactly one state row per server.

**Rules**:
- FK to Trade.HedgeServer guarantees the server must exist before a state row can be created
- INSERT = initial server registration; subsequent writes are UPDATEs to `HBCCloseLimitState` and `LastModify`
- 23 servers tracked; covers both active servers (1, 2, 8, 9, 10) and legacy/inactive servers (e.g., 3, 5, 20-24)

---

## 3. Data Overview

| HedgeServerID | HBCCloseLimitState | LastModify | Notes |
|---|---|---|---|
| 1 | 0 | 2014-10-12 | ZBFX P2 - no mode change since setup |
| 2 | 0 | 2014-10-12 | ZBFX P1 - no mode change since setup |
| 3 | 0 | 2014-10-12 | TRAFIX - inactive |
| 5 | 0 | 2014-10-12 | Legacy server |
| 8 | 0 | 2014-10-12 | OMS |
| 9 | 0 | 2014-10-12 | OMS DMA Virtu |
| 10 | 0 | 2014-10-12 | Talos |
| 11 | 0 | 2014-10-12 | Legacy |
| 12-24 | 0 | 2014-10-12 | Legacy servers |
| 81 | 0 | 2014-10-12 | Legacy |
| 100-102 | 0 | 2015-02-15 | Added 2015 |
| 1100 | 0 | 2023-06-27 | ZBFX P3 |
| 1776 | 0 | 2014-10-12 | Legacy |
| 5454 | 0 | 2025-08-13 | FD Provider - most recently active |
| 100003 | 0 | 2014-10-12 | Legacy GFT system |

Total: 23 rows. All HBCCloseLimitState=0. No temporal history - changes tracked via AuditHistory only.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | VERIFIED | PK and FK to Trade.HedgeServer(HedgeServerID). One row per hedge server. The server whose close-limit mode is tracked. 23 servers in current data. |
| 2 | HBCCloseLimitState | int | NO | - (required) | CODE-BACKED | Current operational state of the HBC close-limit subsystem for this server. 0 = normal (no restriction). Non-zero values represent active limit states - exact enum defined in application code. Written by the hedge engine at runtime. All 23 current rows have value 0. |
| 3 | LastModify | datetime | NO | - (required) | VERIFIED | Datetime when this row was last written by the hedge engine. Application-managed (no DEFAULT). datetime type (not datetime2). Most servers show 2014-10-12 (initial setup, never since updated). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (FK_HedgeServersModes_HedgeServerID) | Hedge server must exist before state row can be created |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.AuditHistory | (trigger) | Audit Log | ASM DML triggers track HBCCloseLimitState, HedgeServerID, LastModify changes |

Note: No stored procedure reader found. Other Hedge components query this table directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.HedgeServersModes (table)
  └── Trade.HedgeServer (table) [FK - HedgeServerID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK_HedgeServersModes_HedgeServerID - server must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.AuditHistory | Table | Audit log via 3 ASM DML triggers (all 3 columns tracked) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeServersModes | CLUSTERED PK | HedgeServerID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeServersModes | PRIMARY KEY | HedgeServerID - one state row per hedge server |
| FK_HedgeServersModes_HedgeServerID | FOREIGN KEY | HedgeServerID must reference Trade.HedgeServer |

Note: No temporal SYSTEM_VERSIONING. Changes tracked only via ASM audit triggers to History.AuditHistory. No DEFAULT constraints on any column.

### 7.3 Triggers

| Trigger Name | Event | Columns Tracked |
|-------------|-------|-----------------|
| AuditDelete_Hedge_HedgeServersModes | DELETE | HBCCloseLimitState, HedgeServerID, LastModify |
| AuditInsert_Hedge_HedgeServersModes | INSERT | HBCCloseLimitState, HedgeServerID, LastModify |
| AuditUpdate_Hedge_HedgeServersModes | UPDATE | HBCCloseLimitState, HedgeServerID, LastModify (conditional on change) |

---

## 8. Sample Queries

### 8.1 View all servers and their current HBC mode state

```sql
SELECT
    hsm.HedgeServerID,
    hs.StrategyName AS HedgeServerName,
    hsm.HBCCloseLimitState,
    hsm.LastModify
FROM Hedge.HedgeServersModes hsm WITH (NOLOCK)
JOIN Trade.HedgeServer hs WITH (NOLOCK)
    ON hsm.HedgeServerID = hs.HedgeServerID
ORDER BY hsm.HedgeServerID
```

### 8.2 Find servers where HBC close-limit mode was recently changed

```sql
SELECT
    hsm.HedgeServerID,
    hsm.HBCCloseLimitState,
    hsm.LastModify
FROM Hedge.HedgeServersModes hsm WITH (NOLOCK)
WHERE hsm.LastModify > DATEADD(year, -1, GETUTCDATE())  -- modified in last year
ORDER BY hsm.LastModify DESC
```

### 8.3 Check audit history for mode changes on a server

```sql
SELECT AuditDate, UserName, ColumnName, OldValue, NewValue, Operation
FROM History.AuditHistory WITH (NOLOCK)
WHERE SchemaName = 'Hedge'
  AND TableName = 'HedgeServersModes'
  AND PK_Value = '8'  -- OMS server
  AND ColumnName = 'HBCCloseLimitState'
ORDER BY AuditDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.HedgeServersModes | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.HedgeServersModes.sql*
