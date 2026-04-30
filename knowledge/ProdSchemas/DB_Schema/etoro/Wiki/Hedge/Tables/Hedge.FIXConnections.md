# Hedge.FIXConnections

> FIX protocol connection registry: one row per liquidity provider connection, storing the display name, linked liquidity account, and trading schedule; versioned via SQL Server temporal tables with an INSERT trigger workaround to ensure SysStartTime is captured on row creation.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | ConnectionID (manual int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED PK on ConnectionID, NONCLUSTERED on LiquidityAccountID) |
| **Temporal** | Yes - SYSTEM_VERSIONING ON (HISTORY_TABLE = History.FIXConnections) |

---

## 1. Business Meaning

Hedge.FIXConnections is the master configuration registry for FIX protocol connections to liquidity providers. Each row represents one named connection endpoint, linking a display name (e.g., "ZBFX Price1 Execution") to a specific LiquidityAccountID (the Hedge.Accounts entry for that provider) and a trading schedule (ScheduleID referencing Hedge.FIXSchedules - when the connection is active).

The table drives three consumers:
1. **Hedge.GetFIXConnections**: The hedge server reads FIX connection config by ConnectionID to initialize sessions.
2. **Hedge.GetHedgeServerInfo**: Resolves which LiquidityAccount (and thus which FIX connection) a HedgeServer is using - used for monitoring and routing.
3. **Monitor.CheckOutOfSyncLiquidityProviders**: Validates that every active liquidity account in Trade.LiquidityAccounts has a matching FIX connection in this table (detects missing/orphaned configurations).

Connection types observed in this environment:
- **Real-time price feeds**: "ZBFX Price1/2 Execution" (ScheduleID="AllWeekExample") - 24/7 live connections
- **OMS UAT connections**: IM3, IM4, Virtu, Marex, JPM (ScheduleID="OMS") - for OMS-routed orders
- **Staging/test connections**: Trafix UAT, DLT STG, EMSX Citadel, Talos, MarketMakerDirectSTG

The full FIX session parameters (Host, Port, SenderCompID, TargetCompID, heartbeat interval, TLS certificates) are stored per-connection in the child table Hedge.FIXConnectionDetails.

**Temporal table**: All changes to connection configuration are automatically versioned into History.FIXConnections. A FOR INSERT trigger (TRG_T_FIXConnections) fires on every INSERT, performing a no-op UPDATE (SET ConnectionID = ConnectionID) that forces the SQL Server temporal engine to record a SysStartTime for the new row - this is a workaround because SQL Server temporal system versioning only captures version records on UPDATE, not INSERT.

---

## 2. Business Logic

### 2.1 Connection Identity and Manual IDs

**What**: ConnectionID is a manually assigned int (no IDENTITY), allowing stable IDs that can be referenced by external systems without auto-increment drift.

**Columns/Parameters Involved**: `ConnectionID`, `Name`

**Rules**:
- ConnectionID must be provided by the inserting code; it is not auto-generated.
- Name is a human-readable label (varchar(256), nullable) identifying the provider and purpose. E.g., "ZBFX Price1 Execution", "OMS UAT IM3".
- ConnectionID gaps exist in data (1,2,3,4,5,6,7,8,10,18,47,48,49,12555,...) indicating historical deletes or non-sequential provisioning.

### 2.2 Schedule-Based Availability

**What**: ScheduleID determines when the FIX connection should be active (trading hours, 24/7, OMS-only windows).

**Columns/Parameters Involved**: `ScheduleID`

**Rules**:
- ScheduleID is a varchar(256) reference to Hedge.FIXSchedules (no DDL FK exists; no Hedge.FIXSchedules table found in this environment - may be a different DB or was removed).
- Observed values: "AllWeekExample" (24/7 including weekends), "OMS" (OMS-gated schedule), "Default" (standard trading hours).
- The hedge server uses ScheduleID to determine connection up/down windows without manual intervention.

### 2.3 Temporal Versioning with INSERT Trigger

**What**: Every configuration change is versioned; the INSERT trigger ensures new rows also get a proper SysStartTime.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `TRG_T_FIXConnections`

**Rules**:
- SQL Server SYSTEM_VERSIONING records a history row in History.FIXConnections whenever a row is UPDATED or DELETED (not on INSERT).
- The FOR INSERT trigger performs `UPDATE A SET A.ConnectionID = A.ConnectionID` on the newly inserted row - this converts the INSERT into an UPDATE event from the temporal engine's perspective, forcing it to record the SysStartTime of initial row creation.
- Without this trigger, the SysStartTime would only be populated when the first UPDATE occurs, losing the initial insertion timestamp.
- SysStartTime and SysEndTime use datetime2(7) precision (100ns).

### 2.4 Computed Audit Columns

**What**: DbLoginName and AppLoginName are computed columns capturing who made the change.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- `DbLoginName = suser_name()`: Captures the SQL Server login name of the session performing the write.
- `AppLoginName = CONVERT(varchar(500), context_info())`: Captures the application-set context_info() value, which application code sets to identify the calling app/user before DML operations.
- Both are computed (not stored) - evaluated at read time.

---

## 3. Data Overview

18 rows | Temporal (current) | History in History.FIXConnections

| ConnectionID | Name | LiquidityAccountID | ScheduleID | SysStartTime |
|---|---|---|---|---|
| 1 | ZBFX Price1 Execution | 8 | AllWeekExample | 2023-12-13 |
| 2 | OMS UAT IM3 | 2147 | OMS | 2024-01-15 |
| 3 | OMS UAT IM4 | 2148 | OMS | 2024-01-31 |
| 4 | OMS UAT Virtu | 2150 | OMS | 2024-08-14 |
| 5 | OMS UAT Marex | 2151 | OMS | 2024-11-01 |
| 6 | OMS UAT JPM | (varies) | OMS | (varies) |
| 10 | ZBFX Price2 Execution | 10 | AllWeekExample | (varies) |
| 47 | EMSX Citadel | (varies) | (varies) | (varies) |
| 48 | Talos Hidden Road | (varies) | (varies) | (varies) |
| 49 | Talos | (varies) | (varies) | (varies) |
| 12555 | MarketMakerDirectSTG | (varies) | (varies) | (varies) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ConnectionID | int | NO | - | CODE-BACKED | Manual (non-IDENTITY) primary key for the FIX connection. CLUSTERED PK. Assigned by the inserting application, not auto-generated. Stable ID used by Hedge.GetFIXConnections and Hedge.GetHedgeServerInfo to reference this connection configuration. |
| 2 | Name | varchar(256) | YES | - | CODE-BACKED | Human-readable display name for the connection. Identifies the provider and purpose: "ZBFX Price1 Execution", "OMS UAT IM3", "MarketMakerDirectSTG", etc. Nullable but populated for all active connections. |
| 3 | LiquidityAccountID | int | YES | - | CODE-BACKED | FK (implicit) to Hedge.Accounts.ID. The liquidity account this FIX connection belongs to. Hedge.GetHedgeServerInfo joins on this to resolve the provider name and type for a given HedgeServer. Monitor.CheckOutOfSyncLiquidityProviders uses this to validate alignment between Hedge.Accounts and Trade.LiquidityAccounts. NC index on this column for lookup performance. |
| 4 | ScheduleID | varchar(256) | NO | - | CODE-BACKED | Reference to Hedge.FIXSchedules (implicit, no DDL FK). Controls when this FIX connection should be active. Observed values: "AllWeekExample" (24/7), "OMS" (OMS-gated), "Default" (standard trading hours). The hedge server uses this to manage connect/disconnect automatically. |
| 5 | DbLoginName | varchar(computed) | - | suser_name() | CODE-BACKED | Computed column: SQL Server login name of the session that last wrote this row. Captured via suser_name(). Used for audit - identifies the DB account (e.g., application service account) that modified the connection config. |
| 6 | AppLoginName | varchar(500, computed) | - | context_info() | CODE-BACKED | Computed column: Application identity from session context_info(), set by the caller before DML. Complements DbLoginName with an application-level user or service name. Nullable if context_info() not set. |
| 7 | SysStartTime | datetime2(7) | NO | GENERATED ALWAYS | CODE-BACKED | Temporal row start time (UTC). Set by SQL Server when a row is inserted or updated. The FOR INSERT trigger forces this to be populated on initial INSERT. Datetime2(7) provides 100ns precision. |
| 8 | SysEndTime | datetime2(7) | NO | GENERATED ALWAYS | CODE-BACKED | Temporal row end time (UTC). Set to 9999-12-31 23:59:59.9999999 for current rows; set to actual end time in History.FIXConnections for superseded versions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Hedge.Accounts | Implicit (no DDL FK) | The liquidity account this FIX connection belongs to |
| ScheduleID | Hedge.FIXSchedules | Implicit (no DDL FK) | Trading schedule controlling connection active hours |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.FIXConnectionDetails | ConnectionID | FK (implicit) | Child key-value store for FIX session parameters |
| Hedge.GetFIXConnections | @ConnectionID | Reader | Returns connection config by ConnectionID |
| Hedge.GetHedgeServerInfo | fc.LiquidityAccountID | Reader | Joins to resolve provider name and type for a HedgeServer |
| Monitor.CheckOutOfSyncLiquidityProviders | fix.LiquidityAccountID | Reader | Validates sync between Hedge.Accounts and Trade.LiquidityAccounts |
| History.FIXConnections | - | Temporal history | Stores superseded versions of rows (SYSTEM_VERSIONING) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.FIXConnections (temporal table)
  - Implicit FK: Hedge.Accounts (LiquidityAccountID)
  - Implicit FK: Hedge.FIXSchedules (ScheduleID) [not in SSDT]
  - Child: Hedge.FIXConnectionDetails (per-connection FIX settings)
  - History: History.FIXConnections (temporal versioning)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.Accounts | Table | LiquidityAccountID references the provider account |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.FIXConnectionDetails | Table | Child table storing FIX session key-value parameters |
| Hedge.GetFIXConnections | Procedure | Reads connection config by ConnectionID |
| Hedge.GetHedgeServerInfo | Procedure | Joins to resolve provider info for a HedgeServer |
| Monitor.CheckOutOfSyncLiquidityProviders | Procedure | Validates provider config sync |
| History.FIXConnections | Table | Temporal history table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Hedge_FIXConnections | CLUSTERED PK | ConnectionID ASC | - | - | Active (FILLFACTOR=90, PAGE compression, MAIN filegroup) |
| IX_LiquidityAccountID | NONCLUSTERED | LiquidityAccountID ASC | - | - | Active (FILLFACTOR=100, MAIN filegroup) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Hedge_FIXConnections | PRIMARY KEY (CLUSTERED) | ConnectionID - unique per FIX connection |

### 7.3 Triggers

| Trigger Name | Event | Purpose |
|-------------|-------|---------|
| TRG_T_FIXConnections | FOR INSERT | No-op UPDATE (SET ConnectionID = ConnectionID) forces SQL Server temporal engine to record SysStartTime on row creation. Without this, temporal versioning only starts on the first UPDATE. |

---

## 8. Sample Queries

### 8.1 All current FIX connections with their settings count
```sql
SELECT fc.ConnectionID, fc.Name, fc.LiquidityAccountID, fc.ScheduleID,
       COUNT(fd.ID) AS SettingCount, fc.SysStartTime
FROM Hedge.FIXConnections fc WITH (NOLOCK)
LEFT JOIN Hedge.FIXConnectionDetails fd WITH (NOLOCK) ON fd.ConnectionID = fc.ConnectionID
GROUP BY fc.ConnectionID, fc.Name, fc.LiquidityAccountID, fc.ScheduleID, fc.SysStartTime
ORDER BY fc.ConnectionID;
```

### 8.2 FIX connection history (all versions)
```sql
SELECT ConnectionID, Name, LiquidityAccountID, ScheduleID, SysStartTime, SysEndTime
FROM Hedge.FIXConnections FOR SYSTEM_TIME ALL
ORDER BY ConnectionID, SysStartTime;
```

### 8.3 Connections per schedule
```sql
SELECT ScheduleID, COUNT(1) AS ConnectionCount
FROM Hedge.FIXConnections WITH (NOLOCK)
GROUP BY ScheduleID
ORDER BY ConnectionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for Hedge.FIXConnections.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.FIXConnections | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.FIXConnections.sql*
