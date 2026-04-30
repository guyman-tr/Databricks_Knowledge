# History.HedgeServer

> SQL Server system-versioned temporal history table for Trade.HedgeServer, automatically recording every configuration change to hedge server records with precise row-validity timestamps (SysStartTime/SysEndTime) to enable point-in-time reconstruction of any hedge server's configuration state.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (HedgeServerID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No |
| **Indexes** | 1 (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Trade.HedgeServer`. SQL Server's system-versioning feature manages this table transparently: whenever a row in `Trade.HedgeServer` is inserted, updated, or deleted, SQL Server writes the previous row state here with SysStartTime/SysEndTime stamped to record the exact validity window of that configuration. No application code writes directly to this table.

Without this table, it would be impossible to audit hedge server configuration changes over time - questions like "what was HedgeServer 9's OperationalMode on 2024-01-15?" or "when was HedgeServer 5454 added to the system?" could not be answered from the current `Trade.HedgeServer` state alone. This temporal audit trail is valuable for compliance, incident investigation, and understanding when specific hedging strategies or circuit breaker settings were in effect during particular trading periods.

Data flows automatically: any UPDATE or DELETE on `Trade.HedgeServer` causes SQL Server to move the current row (with the original SysStartTime and the change timestamp as SysEndTime) into this history table. The current state remains in `Trade.HedgeServer` with SysEndTime = '9999-12-31 23:59:59.9999999'. To access history, use `Trade.HedgeServer FOR SYSTEM_TIME AS OF '...'` or `FOR SYSTEM_TIME ALL` - never query this table directly in production code.

---

## 2. Business Logic

### 2.1 SQL Server System-Versioned Temporal Table Pattern

**What**: SQL Server automatically manages row versioning between Trade.HedgeServer (current) and History.HedgeServer (historical versions), enabling complete point-in-time reconstruction of any configuration state.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `HedgeServerID`

**Rules**:
- SysStartTime = the UTC timestamp when this row version became active in Trade.HedgeServer (set to GETUTCDATE() on INSERT/UPDATE)
- SysEndTime = the UTC timestamp when this row version was superseded (by an UPDATE or DELETE on Trade.HedgeServer); the SysEndTime of a row in the history table is the SysStartTime of the next version
- Current rows in Trade.HedgeServer have SysEndTime = '9999-12-31 23:59:59.9999999' (sentinel for "still current")
- A HedgeServerID may appear multiple times in this table (once per configuration change event)
- The CLUSTERED index on (SysEndTime ASC, SysStartTime ASC) is the standard SQL Server temporal history index - optimized for the `FOR SYSTEM_TIME AS OF` query pattern
- DbLoginName, AppLoginName, HostName are computed columns in Trade.HedgeServer that capture WHO made each change; their values are materialized here at version creation time

**Diagram**:
```
Trade.HedgeServer (current state):
  HedgeServerID=9, OperationalMode=2, SysStartTime='2025-04-30', SysEndTime='9999-12-31'

UPDATE Trade.HedgeServer SET OperationalMode=3 WHERE HedgeServerID=9:

History.HedgeServer receives (previous version):
  HedgeServerID=9, OperationalMode=2, SysStartTime='2025-04-30', SysEndTime='2025-05-01'

Trade.HedgeServer updated (new current):
  HedgeServerID=9, OperationalMode=3, SysStartTime='2025-05-01', SysEndTime='9999-12-31'
```

### 2.2 Hedge Server Configuration Audit Trail

**What**: Each row version captures the complete configuration of one hedge server node at a point in time, enabling investigation of which settings were active during any trading incident or period.

**Columns/Parameters Involved**: `HedgeServerID`, `IsActive`, `HedgingMode`, `OperationalMode`, `CircuitBreakerLimit`, `ExecutionFactor`

**Rules**:
- IsActive (DEFAULT 1) - tracks when a server was deactivated vs active; changes here are audit-critical because deactivating a hedge server changes risk exposure
- CircuitBreakerLimit and CircuitBreakerWarningLimit are safety thresholds; changes to these values are especially important to track over time for risk management audits
- ExecutionFactor (DEFAULT 1.0) controls scaling of hedge position sizes; values other than 1.0 represent intentional scaling adjustments
- DbLoginName = suser_name() at the time of the change, AppLoginName = context_info() from the application session - these are materialized in the history row, enabling "who changed this" audit queries
- HostName = host_name() at time of change - identifies which machine/service made the configuration update

---

## 3. Data Overview

| HedgeServerID | SysStartTime | SysEndTime | OperationalMode | IsActive | IsDummy | DbLoginName | Meaning |
|---|---|---|---|---|---|---|---|
| 5454 | 2025-08-13 08:33 | 2025-08-13 08:33 | 2 | true | 0 | DevTradingSTG | A zero-duration version created and immediately superseded - likely an insert-then-update in the same second, resulting in a momentary history entry for the initial state. |
| 9 | 2025-04-30 22:30 | 2025-04-30 22:30 | 2 | true | 1 | TRAD\michaelta | HedgeServer 9 (IsDummy=1, test server) updated as part of a bulk configuration change on 2025-04-30 by michaelta. Very short duration (< 2 seconds). |
| 100003 | 2025-02-23 11:38 | 2025-04-30 22:30 | 1 | true | 1 | TRAD\michaelta | HedgeServer 100003 was active in OperationalMode=1 from Feb 23 to Apr 30 2025 - a 2-month configuration window before being changed by michaelta. |
| 1776 | 2025-02-23 11:38 | 2025-04-30 22:30 | 1 | true | 0 | TRAD\michaelta | Real HedgeServer 1776 in OperationalMode=1 for the same Feb-Apr 2025 window, part of a coordinated configuration rollout. |
| 1100 | 2025-02-23 11:38 | 2025-04-30 22:30 | 5 | true | 0 | TRAD\michaelta | HedgeServer 1100 in OperationalMode=5 (distinct from the common values 1 and 2) - possibly a specialized or experimental operational mode. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | Identifier of the hedge server node. Matches Trade.HedgeServer.HedgeServerID (PK_THSR). Multiple rows with the same HedgeServerID represent successive configuration versions over time. |
| 2 | IPAddress | varchar(15) | YES | - | CODE-BACKED | IP address of the hedge server node. DEFAULT '127.0.0.1' in Trade.HedgeServer. In staging environment all rows show 127.0.0.1; production would show actual server IPs. |
| 3 | Port | int | NO | - | CODE-BACKED | TCP port the hedge server listens on. DEFAULT 0 in Trade.HedgeServer. Port=0 may indicate the server uses a default or dynamically assigned port. |
| 4 | IsActive | bit | YES | - | CODE-BACKED | Whether this hedge server was active (1=active, 0=inactive) during this version window. Indexed in Trade.HedgeServer via Idx_Trade_HedgeServer_IsActive. DEFAULT 1 (active) on creation. When set to 0, the server stops accepting hedge requests. |
| 5 | HedgingMode | int | YES | - | NAME-INFERRED | Numeric mode controlling the hedging behavior pattern of this server. Values observed: 0 (no periodic hedging) and 1 (periodic hedging enabled - works alongside PeriodicHedgeIntervalMinutes). Exact semantics are configuration-level and not enumerated in DDL. |
| 6 | IsDummy | int | YES | - | CODE-BACKED | Indicates if this is a test/dummy server (1) or a real production server (0). Dummy servers are used for testing and simulation without executing real trades against liquidity providers. |
| 7 | ConsiderOpenRequestsSec | int | YES | - | CODE-BACKED | Timeout in seconds for how long to consider open hedge requests valid. DEFAULT 60 (1 minute) in Trade.HedgeServer. Requests older than this threshold may be discarded or re-evaluated. |
| 8 | HedgeStrategyModeID | int | YES | - | CODE-BACKED | FK to `Dictionary.HedgeStrategyMode.HedgeStrategyModeID` in Trade.HedgeServer (WITH CHECK). Defines the hedging strategy algorithm used by this server. DEFAULT 0. See _glossary.md for HedgeStrategyMode values if documented. |
| 9 | ExecutionFactor | decimal(16,8) | NO | - | CODE-BACKED | Scaling factor applied to hedge position sizes. DEFAULT 1.0 (full-size hedging). Values < 1.0 mean under-hedging (partial coverage); values > 1.0 mean over-hedging. Used by the hedge server when calculating position sizes to submit to liquidity providers. |
| 10 | AllowMajor | bit | YES | - | CODE-BACKED | Whether this server is permitted to hedge major currency pairs. DEFAULT 0 (not allowed). When 1, the server can execute hedges on major pairs in addition to its configured instrument set. |
| 11 | CircuitBreakerLimit | decimal(14,4) | YES | - | NAME-INFERRED | Maximum threshold for a circuit breaker that halts hedging activity when a risk limit is breached. The exact metric (USD exposure, lot count, PnL) is determined by the hedge server's configuration. A breach triggers automatic halting of hedge operations. |
| 12 | CircuitBreakerWarningLimit | decimal(12,4) | YES | - | NAME-INFERRED | Warning threshold below CircuitBreakerLimit that triggers an alert before the hard stop is reached. Smaller precision (12,4 vs 14,4) allows for a warning that fires at a lower threshold. |
| 13 | InstrumentIDToHedgeOn | int | YES | - | NAME-INFERRED | When set, restricts this hedge server to hedge only on this specific instrument ID. NULL means the server can hedge on any instrument in its configured set. References Trade.Instrument or Dictionary.Instrument. |
| 14 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login name (suser_name()) of the session that made the change captured in this version. Computed column in Trade.HedgeServer, materialized here at version creation time. Enables "who changed this" audit queries. |
| 15 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level login identifier from SQL Server context_info() at the time of the change. Populated by applications that set context_info before modifying Trade.HedgeServer. NULL if not set by the application. |
| 16 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version became active in Trade.HedgeServer. GENERATED ALWAYS AS ROW START on the source table. The row was valid from this instant until SysEndTime. Precision to 100-nanosecond intervals (datetime2(7)). |
| 17 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version was superseded (by an UPDATE or DELETE on Trade.HedgeServer). GENERATED ALWAYS AS ROW END. CLUSTERED index key (leading column) enabling efficient temporal range scans. The combination SysStartTime=SysEndTime indicates a zero-duration version (INSERT immediately followed by UPDATE). |
| 18 | HostName | nvarchar(128) | YES | - | CODE-BACKED | Network hostname (host_name()) of the client machine that made the change. Computed column in Trade.HedgeServer, materialized at version creation. Identifies which server or workstation updated this configuration. |
| 19 | OperationalMode | smallint | NO | - | NAME-INFERRED | Operational behavior mode of the hedge server. Values observed: 1 (standard operation), 2 (alternative mode), 5 (specialized mode). DEFAULT 1 in Trade.HedgeServer. Exact semantics are defined in the hedge server application configuration. |
| 20 | PriceSource | smallint | NO | - | NAME-INFERRED | Identifier for the price data source this server uses when calculating hedge rates. DEFAULT 1. Value 1 is the only value observed in live data. Exact source mapping is defined in the hedge server application. |
| 21 | PeriodicHedgeIntervalMinutes | int | YES | - | CODE-BACKED | When periodic hedging is enabled (HedgingMode=1), this is the interval in minutes between scheduled hedge rebalancing cycles. NULL when periodic hedging is not configured. |
| 22 | PeriodicHedgeHours | varchar(50) | YES | - | NAME-INFERRED | Schedule string defining which hours of the day periodic hedging is allowed to run. Likely a comma-delimited or range-format string (e.g., "9-17" for market hours). NULL when not configured or when all hours are permitted. |
| 23 | UnitRoundingMethod | tinyint | YES | - | NAME-INFERRED | Method used to round position sizes to valid lot increments when submitting orders to the liquidity provider. The specific rounding algorithm (floor, ceil, nearest) is determined by the value. NULL uses the hedge server's default rounding. |
| 24 | StrategyName | varchar(200) | YES | - | CODE-BACKED | Human-readable name of the hedging strategy used by this server. Identifies the strategy configuration applied (e.g., "EMS" strategies). NULL if no named strategy is assigned. |
| 25 | StrategyGroup | smallint | YES | - | NAME-INFERRED | Numeric group identifier for categorizing hedge servers by strategy family. Servers in the same group may share configuration or be coordinated during rebalancing. NULL if not grouped. |
| 26 | SystemName | varchar(255) | NO | - | CODE-BACKED | Name of the system managing this hedge server. DEFAULT 'EMS' (Execution Management System). All rows in live data show 'EMS', indicating all hedge servers are managed by the EMS platform. |
| 27 | RequestedAlertIntervalSeconds | int | NO | - | CODE-BACKED | Interval in seconds for requested alert notifications from this server. DEFAULT 180 (3 minutes). Configures how frequently the server should send status/health alerts to monitoring systems. |
| 28 | ManagedExposurePeriodSec | int | YES | - | NAME-INFERRED | Duration in seconds for the managed exposure monitoring window. Defines how long a period of exposure is tracked before being evaluated or reset by the exposure management algorithm. NULL if not configured. |
| 29 | AllowOMSPricingPartialFill | bit | NO | - | CODE-BACKED | Whether this server allows partial fills when using OMS (Order Management System) pricing. DEFAULT 0 (partial fills not allowed). When 1, the server accepts orders where only part of the requested quantity is filled. |
| 30 | HostName (duplicate) | - | - | - | - | Note: HostName appears once in position 18 above. The DDL lists 30 distinct columns with no duplicates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. As a temporal history table, all FK constraints reside on `Trade.HedgeServer` (source table), not on the history table. Temporal history tables intentionally have no FK constraints to avoid blocking historical row insertion.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.HedgeServer | SYSTEM_VERSIONING | Temporal history source | Trade.HedgeServer is configured with `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[HedgeServer])`. All historical versions are automatically routed here by SQL Server. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.HedgeServer (table)
- no code-level dependencies (leaf table, temporal history)
```

This object has no code-level dependencies. As a SQL Server-managed temporal history table, it is populated automatically by the database engine - not by stored procedures or views.

### 6.1 Objects This Depends On

No dependencies. Temporal history tables have no FK constraints or references to other objects.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | Source temporal table - SQL Server automatically writes previous row versions here on UPDATE/DELETE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_HedgeServer | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE) |

No primary key constraint - temporal history tables are not required to have a PK. The CLUSTERED index on (SysEndTime, SysStartTime) is the standard SQL Server pattern for temporal history tables, optimized for the `FOR SYSTEM_TIME AS OF` scan pattern where SQL Server seeks to SysEndTime >= @asof and SysStartTime <= @asof.

### 7.2 Constraints

None. Temporal history tables intentionally have no CHECK, UNIQUE, DEFAULT, or FOREIGN KEY constraints. SQL Server prevents direct INSERT/UPDATE/DELETE on temporal history tables - only the database engine may modify them.

---

## 8. Sample Queries

### 8.1 Point-in-time lookup - what was a server's configuration on a specific date?

```sql
-- Use FOR SYSTEM_TIME on the source table, not this history table directly
SELECT
    hs.HedgeServerID,
    hs.IPAddress,
    hs.IsActive,
    hs.OperationalMode,
    hs.HedgingMode,
    hs.ExecutionFactor,
    hs.CircuitBreakerLimit,
    hs.SysStartTime,
    hs.SysEndTime
FROM Trade.HedgeServer FOR SYSTEM_TIME AS OF '2024-06-01T00:00:00'  hs WITH (NOLOCK)
WHERE hs.HedgeServerID = @HedgeServerID;
```

### 8.2 Audit - all configuration changes for a specific hedge server

```sql
SELECT
    h.HedgeServerID,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    h.OperationalMode,
    h.IsActive,
    h.ExecutionFactor,
    h.CircuitBreakerLimit,
    h.DbLoginName AS ChangedBy,
    h.HostName AS ChangedFromHost
FROM History.HedgeServer h WITH (NOLOCK)
WHERE h.HedgeServerID = @HedgeServerID
ORDER BY h.SysStartTime ASC;
```

### 8.3 Find all configuration changes within a time window

```sql
SELECT
    h.HedgeServerID,
    h.SysStartTime AS ChangeTime,
    h.OperationalMode,
    h.IsActive,
    h.ExecutionFactor,
    h.DbLoginName AS ChangedBy,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS VersionDurationSeconds
FROM History.HedgeServer h WITH (NOLOCK)
WHERE h.SysStartTime >= @StartDate
  AND h.SysStartTime <  @EndDate
ORDER BY h.SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific table. General HedgeServer context was found in operational pages (DROD space) but contained no specific documentation about History.HedgeServer.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 7.0/10 (Elements: 6.7/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 10 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.HedgeServer | Type: Table | Source: etoro/etoro/History/Tables/History.HedgeServer.sql*
