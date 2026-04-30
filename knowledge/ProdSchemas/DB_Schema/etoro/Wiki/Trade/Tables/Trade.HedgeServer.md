# Trade.HedgeServer

> Configuration table for hedge execution servers that manage eToro's net market exposure by routing client CFD positions to liquidity providers for hedging.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | HedgeServerID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK, 1 NC on IsActive) |

---

## 1. Business Meaning

Trade.HedgeServer defines the set of hedge execution servers that eToro uses to manage counterparty risk. When clients open CFD positions, eToro takes the opposite side and must hedge aggregate exposure by opening offsetting positions at liquidity providers. Each hedge server is a configurable instance (IP:Port) that receives hedge requests, executes them via EMS (Execution Management System), and reports status back to the database.

This table exists because hedging is distributed across multiple servers for capacity, fault tolerance, and different execution strategies. Without it, the system could not route positions to the correct hedge server, apply per-server circuit breaker limits, or distinguish dummy/test servers from production ones.

Data flows: Hedge servers are provisioned via INSERT (external deployment). The Insert_Trade_Instrument trigger creates default HedgeFilter and HedgeServerToFilter entries and syncs to Hedge.HedgeServersModes. Positions reference HedgeServerID; Trade.ChangePositionsHedgeServer and Hedge.GetHedgeServerSettings read/write config. Trade.GetExposuresForAllHedgeServers JOINs HedgeServer to compute exposure including open requests (ConsiderOpenRequestsSec window).

---

## 2. Business Logic

### 2.1 Hedge Strategy Mode

**What**: Determines how the hedge server decides when and how much to hedge (fully, bounded, HBC, or periodic boundaries).

**Columns/Parameters Involved**: `HedgeStrategyModeID`

**Rules**:
- 0 = STRATEGY_FULLY: Hedge full exposure immediately
- 1 = STRATEGY_BOUNDARIES: Hedge within defined boundaries
- 2 = STRATEGY_HBC: Hedge-by-close (HBC) mode - used by Hedge.GetHBCHedgeServerIDs to identify HBC servers
- 3 = STRATEGY_PERIODIC_BOUNDARIES: Periodic boundary-based hedging

**Diagram**:
```
Dictionary.HedgeStrategyMode
     |
     v
Trade.HedgeServer.HedgeStrategyModeID --> 0/1/2/3
     |
     +-> Hedge.GetHBCHedgeServerIDs filters WHERE HedgeStrategyModeID = 2
```

### 2.2 Dummy vs Real Hedge Server

**What**: Dummy servers absorb positions for testing without executing real hedges.

**Columns/Parameters Involved**: `IsDummy`

**Rules**:
- IsDummy = 0: Real hedge server - when positions are moved here, EntryHedgeQuery is reset to -1 to trigger re-hedging
- IsDummy = 1: Dummy server - EntryHedgeQuery is NOT reset; positions are not re-hedged (Trade.ChangePositionsHedgeServer)

**Diagram**:
```
Trade.ChangePositionsHedgeServer @HedgeServerID
     |
     v
SELECT IsDummy FROM Trade.HedgeServer
     |
     +-> IsDummy = 0: UPDATE SET EntryHedgeQuery = -1 (re-hedge)
     +-> IsDummy = 1: leave EntryHedgeQuery unchanged (no re-hedge)
```

### 2.3 Circuit Breaker and Execution Factor

**What**: Risk limits that Monitor.AlertForDealingExecutionConfigurationManager validates.

**Columns/Parameters Involved**: `CircuitBreakerLimit`, `CircuitBreakerWarningLimit`, `ExecutionFactor`

**Rules**:
- CircuitBreakerLimit must be between 10,000,000 and 100,000,000
- ExecutionFactor must be between 0.75 and 1
- Violations trigger Datadog/monitor alerts

---

## 3. Data Overview

| HedgeServerID | IPAddress | Port | IsActive | HedgeStrategyModeID | OperationalMode | Meaning |
|---|---|---|---|---|---|---|
| 0 | 000.0.0.0 | 0 | 0 | 0 | 1 | Placeholder/disabled server - used when no specific hedge server is assigned. IsActive=0 excludes from normal routing. |
| 1 | 127.0.0.0 | 0 | 1 | 0 | 2 | Localhost hedge server with OperationalMode=2. StrategyGroup=1. Used for local/dev or specific strategy group. |
| 2 | 127.0.0.1 | 9999 | 1 | 1 | 1 | Active server with STRATEGY_BOUNDARIES. Port 9999. Boundaries-based hedging strategy. |
| 3 | 127.0.0.1 | 1003 | 1 | 0 | 1 | Active server on port 1003. StrategyGroup=1. STRATEGY_FULLY mode. |
| 4 | 127.0.0.1 | 1004 | 1 | 0 | 1 | Active server on port 1004. STRATEGY_FULLY mode. |

**Selection criteria for the 5 rows:**
- HedgeServerID 0 is the placeholder; 1-4 show active servers with varying config
- Mix of HedgeStrategyModeID 0 and 1
- OperationalMode 1 (default) and 2
- StrategyGroup NULL vs 1

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | Primary key. Unique identifier for the hedge server instance. 0 = placeholder. |
| 2 | IPAddress | varchar(15) | YES | '127.0.0.1' | CODE-BACKED | IP address where the hedge server process listens. Localhost for local deployments. |
| 3 | Port | int | NO | 0 | CODE-BACKED | TCP port for hedge server communication. 0 for placeholder; actual servers use 9999, 1003, 1004, etc. |
| 4 | IsActive | bit | YES | 1 | CODE-BACKED | 1 = server is active and receives hedge routing; 0 = inactive/disabled. Index Idx_Trade_HedgeServer_IsActive supports active-server lookups. |
| 5 | HedgingMode | int | YES | - | NAME-INFERRED | Hedging behavior mode. Observed values 0 in sample data. No explicit lookup table found. |
| 6 | IsDummy | int | YES | - | CODE-BACKED | 0 = real hedge server (positions are re-hedged when moved here); 1 = dummy server (positions are NOT re-hedged). Trade.ChangePositionsHedgeServer uses this to decide whether to reset EntryHedgeQuery. |
| 7 | ConsiderOpenRequestsSec | int | YES | 60 | CODE-BACKED | Seconds to look back when summing open hedge requests for exposure. Trade.GetExposuresForAllHedgeServers: WHERE Occurred >= dateadd(ss, 0-ConsiderOpenRequestsSec, getdate()). |
| 8 | HedgeStrategyModeID | int | YES | 0 | CODE-BACKED | FK to Dictionary.HedgeStrategyMode. 0=STRATEGY_FULLY, 1=STRATEGY_BOUNDARIES, 2=STRATEGY_HBC, 3=STRATEGY_PERIODIC_BOUNDARIES. |
| 9 | ExecutionFactor | decimal(16,8) | NO | 1 | CODE-BACKED | Multiplier for execution sizing. Must be 0.75-1 per Monitor.AlertForDealingExecutionConfigurationManager. |
| 10 | AllowMajor | bit | YES | 0 | NAME-INFERRED | Whether major/forex instruments are allowed. 0 = no, 1 = yes. |
| 11 | CircuitBreakerLimit | decimal(14,4) | YES | - | CODE-BACKED | Max exposure threshold. Monitor alerts if < 10,000,000 or > 100,000,000. |
| 12 | CircuitBreakerWarningLimit | decimal(12,4) | YES | - | CODE-BACKED | Warning threshold before circuit breaker trips. Read by Hedge.GetServerCircuitBreakerThresholds. |
| 13 | InstrumentIDToHedgeOn | int | YES | - | NAME-INFERRED | Optional Trade.Instrument.InstrumentID to use for hedge sizing/quoting. NULL = use position instrument. |
| 14 | DbLoginName | varchar(128) | - | AS suser_name() | CODE-BACKED | Computed: current SQL login. Audit. |
| 15 | AppLoginName | varchar(500) | - | AS CONVERT(varchar(500), context_info()) | CODE-BACKED | Computed: application context from context_info(). Audit. |
| 16 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning row start. Temporal table. |
| 17 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning row end. Temporal table. |
| 18 | HostName | nvarchar(128) | - | AS host_name() | CODE-BACKED | Computed: server hostname. Audit. |
| 19 | OperationalMode | smallint | NO | 1 | CODE-BACKED | Execution mode. Observed 1 and 2. Hedge.SSRS_Latency_Report groups by OperationalMode. |
| 20 | PriceSource | smallint | NO | 1 | CODE-BACKED | Price source for quoting. Maps to Dictionary.PriceSourceName (1=Xignite, etc). Hedge.GetHedgeServerSettings returns this. |
| 21 | PeriodicHedgeIntervalMinutes | int | YES | - | NAME-INFERRED | Minutes between periodic hedge runs when using STRATEGY_PERIODIC_BOUNDARIES. |
| 22 | PeriodicHedgeHours | varchar(50) | YES | - | NAME-INFERRED | Schedule for periodic hedging (e.g. market hours). |
| 23 | UnitRoundingMethod | tinyint | YES | - | CODE-BACKED | Rounding method for lot/unit quantities. Hedge.GetHedgeServerSettings returns this. |
| 24 | StrategyName | varchar(200) | YES | - | NAME-INFERRED | Human-readable strategy name. |
| 25 | StrategyGroup | smallint | YES | - | CODE-BACKED | References Dictionary.StrategyGroups.StrategyGroupID. Hedge.GetStrategyGroupsAndHedgeServerID JOINs by StrategyGroup. |
| 26 | SystemName | varchar(255) | NO | 'EMS' | CODE-BACKED | Execution system name. Default EMS (Execution Management System). |
| 27 | RequestedAlertIntervalSeconds | int | YES | 180 | NAME-INFERRED | Interval in seconds for requested/alert reporting. |
| 28 | ManagedExposurePeriodSec | int | YES | - | NAME-INFERRED | Period in seconds for managed exposure calculations. |
| 29 | AllowOMSPricingPartialFill | bit | NO | 0 | NAME-INFERRED | Whether OMS allows pricing on partial fills. 0 = no, 1 = yes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeStrategyModeID | Dictionary.HedgeStrategyMode | FK | Hedging strategy: FULLY, BOUNDARIES, HBC, PERIODIC_BOUNDARIES |
| StrategyGroup | Dictionary.StrategyGroups | Implicit | Strategy group for server grouping |
| InstrumentIDToHedgeOn | Trade.Instrument | Implicit | Optional instrument for hedge quoting |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionTbl | HedgeServerID | Lookup | Positions routed to this hedge server |
| Trade.HedgeRequest | HedgeServerID | Lookup | Open requests sent to this server |
| Trade.Hedge | HedgeServerID | Lookup | Executed hedges on this server |
| Trade.HedgeServerToFilter | HedgeServerID | FK | Filter associations (created by Insert trigger) |
| Hedge.HedgeServerToLiquidityAccount | HedgeServerID | Lookup | Liquidity account mappings |
| Hedge.HedgeServersModes | HedgeServerID | Lookup | HBC close limit state (trigger INSERT) |
| Trade.ChangePositionsHedgeServer | - | Reader | Reads IsDummy for position move logic |
| Trade.PostClosePositionActions | - | JOIN | Resolves HedgeServerID for position context |
| Hedge.GetExposuresForAllHedgeServers | - | JOIN | ConsiderOpenRequestsSec for request window |
| Hedge.GetHedgeServerSettings | - | Reader | Returns config for hedge services |
| Hedge.GetHBCHedgeServerIDs | - | Filter | WHERE HedgeStrategyModeID = 2 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeServer (table)
```

This object has no code-level dependencies (CREATE TABLE does not reference views/functions in FROM/JOIN). FK targets and trigger-referenced tables are structural only.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.HedgeStrategyMode | Table | FK HedgeStrategyModeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetExposuresForAllHedgeServers | View | JOIN for ConsiderOpenRequestsSec, HedgeServerID |
| Hedge.GetExposuresForAllHedgeServers | View | Same |
| Hedge.GetHedgeServersDetails | View | FROM Trade.HedgeServer |
| Hedge.GetHBCHedgeServerIDs | View | WHERE HedgeStrategyModeID = 2 |
| Trade.HedgeServerToFilter | Table | FK HedgeServerID |
| Hedge.GetHedgeServerSettings | Procedure | SELECT config |
| Hedge.GetStrategyGroupsAndHedgeServerID | Procedure | LEFT JOIN by StrategyGroup |
| Hedge.GetServerCircuitBreakerThresholds | Procedure | SELECT CircuitBreaker* |
| Trade.ChangePositionsHedgeServer | Procedure | Reads IsDummy |
| Trade.PostClosePositionActions | Procedure | LEFT JOIN for HedgeServer |
| Hedge.HedgeCostReport | Procedure | Seed rows |
| Monitor.AlertForDealingExecutionConfigurationManager | Procedure | Validates CircuitBreakerLimit, ExecutionFactor |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_THSR | CLUSTERED PK | HedgeServerID ASC | - | - | Active |
| Idx_Trade_HedgeServer_IsActive | NC | IsActive ASC | HedgeServerID, HedgeStrategyModeID | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Trade_HedgeServer_IPAdress | DEFAULT | IPAddress = '127.0.0.1' |
| DF_Trade_HedgeServer_Port | DEFAULT | Port = 0 |
| DF_Trade_HedgeServer_IsActive | DEFAULT | IsActive = 1 |
| DF_HedgeServer_ConsiderOpenRequestsSec | DEFAULT | ConsiderOpenRequestsSec = 60 |
| DF_Trade_HedgeServer_HedgeStrategyModeID | DEFAULT | HedgeStrategyModeID = 0 |
| DF_TradeHedgeServer_ExecutionFactor | DEFAULT | ExecutionFactor = 1 |
| DF_TradeHedgeServer_AllowMajor | DEFAULT | AllowMajor = 0 |
| DF_HedgeServer_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_HedgeServer_SysEnd | DEFAULT | SysEndTime = 9999-12-31 23:59:59.9999999 |
| DF_Trade_HedgeServer_SystemName | DEFAULT | SystemName = 'EMS' |
| DF_RequestedAlertIntervalSeconds | DEFAULT | RequestedAlertIntervalSeconds = 180 |
| DF_HedgeServer_AllowOMSPricingPartialFill | DEFAULT | AllowOMSPricingPartialFill = 0 |
| FK_THS_DHSM_HedgeStrategyModeID | FK | HedgeStrategyModeID -> Dictionary.HedgeStrategyMode |

---

## 8. Sample Queries

### 8.1 List active hedge servers with strategy mode
```sql
SELECT HedgeServerID, IPAddress, Port, IsActive, HedgeStrategyModeID,
       HSM.Description AS HedgeStrategyMode
FROM Trade.HedgeServer HS WITH (NOLOCK)
LEFT JOIN Dictionary.HedgeStrategyMode HSM WITH (NOLOCK)
  ON HS.HedgeStrategyModeID = HSM.HedgeStrategyModeID
WHERE HS.IsActive = 1
ORDER BY HedgeServerID;
```

### 8.2 Get hedge server settings (config for EMS)
```sql
SELECT HedgeServerID, OperationalMode, PriceSource, ExecutionFactor,
       CircuitBreakerWarningLimit, CircuitBreakerLimit,
       PeriodicHedgeIntervalMinutes, PeriodicHedgeHours, UnitRoundingMethod,
       RequestedAlertIntervalSeconds, ManagedExposurePeriodSec, AllowOMSPricingPartialFill
FROM Trade.HedgeServer WITH (NOLOCK)
WHERE IsActive = 1;
```

### 8.3 Hedge servers in HBC mode
```sql
SELECT HS.HedgeServerID, HS.IPAddress, HS.Port, HS.SystemName
FROM Trade.HedgeServer HS WITH (NOLOCK)
WHERE HS.HedgeStrategyModeID = 2 AND HS.IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.4/10 (Elements: 7.6/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 7 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15+ analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.HedgeServer | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.HedgeServer.sql*
