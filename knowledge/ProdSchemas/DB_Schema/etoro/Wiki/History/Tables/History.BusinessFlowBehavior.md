# History.BusinessFlowBehavior

> Temporal history table automatically maintained by SQL Server for Hedge.BusinessFlowBehavior; each row captures one past version of a hedge business flow configuration with its validity interval.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime, SysStartTime) - clustered index (no PK; temporal managed by SQL Server) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.BusinessFlowBehavior is the auto-managed temporal history table for Hedge.BusinessFlowBehavior. SQL Server's SYSTEM_VERSIONING feature writes here automatically whenever a business flow configuration row is updated or deleted. The 10 rows in this history table confirm that configuration changes have occurred since system versioning was set up (May 2024).

Hedge.BusinessFlowBehavior defines the behavioral characteristics of each order execution pathway in eToro's hedging system. Each BusinessFlowID represents a distinct route an order can take through the trading infrastructure (Legacy broker, EMS, OMS for CFDs, OMS for real stocks, Virtu liquidity provider, DLT path, futures). The configuration flags control which validations apply and how the hedge server processes orders for that flow. Tracking history matters for post-trade analysis, debugging hedge behavior discrepancies, and auditing configuration changes.

---

## 2. Business Logic

### 2.1 Business Flow Types and Their Configurations

**What**: Each BusinessFlowID represents a distinct execution pathway with its own set of validation and processing rules.

**Columns/Parameters Involved**: `BusinessFlowID`, `BusinessFlowName`, all BIT/smallint flags

**Rules**:
- BusinessFlowID=1 (Legacy): All validations enabled - the original full-validation execution path
- BusinessFlowID=2 (EMS): Identical to Legacy - Execution Management System with full validations
- BusinessFlowID=3 (OMS_CFDs): OMS path for CFD instruments - no leverage factor, no market range, no circuit breakers; SpreadLogic=1, netting enabled
- BusinessFlowID=4 (PathToVirtu): Real stock path via Virtu liquidity provider - circuit breakers only, SpreadLogic=0, netting enabled
- BusinessFlowID=5 (PathToDLT): DLT (Distributed Ledger Technology) path - circuit breakers, HBC execution, SpreadLogic=2, netting enabled
- BusinessFlowID=6 (OMS_REAL): OMS for real stock positions - rounding, SpreadLogic=1, NO netting, HBC failover enabled
- BusinessFlowID=7 (RealFutures): Futures execution path - circuit breakers, HBC execution, SpreadLogic=0, netting, SLTPBehavior=1

### 2.2 Temporal System Versioning

**What**: SQL Server automatically moves old configuration versions here on UPDATE/DELETE.

**Rules**:
- Same pattern as History.BoundariesConfiguration - temporal history with PAGE compression on MAIN filegroup
- Trigger Tr_T_BusinessFlowBehavior_INSERT on the parent table performs self-join UPDATE to force SysStartTime refresh
- Use `FOR SYSTEM_TIME AS OF` on Hedge.BusinessFlowBehavior for point-in-time queries

---

## 3. Data Overview

Current Hedge.BusinessFlowBehavior state (for context on what changes are tracked in history):

| BusinessFlowID | BusinessFlowName | ApplyFactor | ValidateCircuitBreakers | SpreadLogic | UpdateNetting | SLTPBehavior | Meaning |
|---|---|---|---|---|---|---|---|
| 1 | Legacy | true | true | 1 | true | 0 | Original execution path with all validations - full hedge pipeline |
| 2 | EMS | true | true | 1 | true | 0 | Execution Management System - same full-validation profile as Legacy |
| 3 | OMS_CFDs | false | false | 1 | true | 0 | OMS route for CFD instruments - lighter validation, netting active |
| 4 | PathToVirtu | false | true | 0 | true | 0 | Real stock execution via Virtu liquidity provider |
| 5 | PathToDLT | false | true | 2 | true | 0 | DLT execution path with HBC validation |
| 6 | OMS_REAL | false | false | 1 | false | 0 | OMS for real stock positions - no netting, HBC failover allowed |
| 7 | RealFutures | false | true | 0 | true | 1 | Futures position execution - SLTP behavior differs (SLTPBehavior=1) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BusinessFlowID | smallint | NO | - | VERIFIED | Identifies the order execution pathway. PK in parent Hedge.BusinessFlowBehavior. Values: 1=Legacy, 2=EMS, 3=OMS_CFDs, 4=PathToVirtu, 5=PathToDLT, 6=OMS_REAL, 7=RealFutures. |
| 2 | BusinessFlowName | varchar(50) | YES | - | VERIFIED | Human-readable name of the execution flow. Examples: Legacy, EMS, OMS_CFDs, PathToVirtu, PathToDLT, OMS_REAL, RealFutures. Nullable but always populated in practice. |
| 3 | ApplyFactor | bit | NO | - | CODE-BACKED | Whether to apply the leverage/margin factor to orders in this flow. true for Legacy and EMS (traditional leveraged flows); false for OMS and direct market access flows. |
| 4 | ValidateMinOrderSize | bit | NO | - | CODE-BACKED | Whether to validate that the order meets the minimum size requirement. false for Virtu, DLT, and Futures paths (direct market access where min size validation is handled externally). |
| 5 | ValidateMaxDealSize | bit | NO | - | CODE-BACKED | Whether to validate that the order does not exceed the maximum deal size. true for all flows - always enforced regardless of execution path. |
| 6 | ValidateMarketRange | bit | NO | - | CODE-BACKED | Whether to validate the order against market range (price sanity check). true only for Legacy and EMS; false for all OMS and direct market access paths. |
| 7 | ValidateCircuitBreakers | bit | NO | - | CODE-BACKED | Whether to apply circuit breaker checks. true for Legacy, EMS, PathToVirtu, PathToDLT, and RealFutures; false for OMS paths. |
| 8 | ApplySplitLogic | bit | NO | - | CODE-BACKED | Whether to apply order splitting logic for large positions. true only for Legacy and EMS. |
| 9 | ApplyRounding | bit | NO | - | CODE-BACKED | Whether to apply price rounding. true for Legacy, EMS, and OMS_REAL; false for direct market access paths. |
| 10 | SpreadLogic | smallint | NO | - | CODE-BACKED | Spread calculation method: 0=no spread (direct price, used by PathToVirtu and RealFutures), 1=standard spread (Legacy, EMS, OMS flows), 2=DLT spread logic (PathToDLT). |
| 11 | UpdateNetting | bit | NO | - | CODE-BACKED | Whether to update the netting calculation after order execution. false only for OMS_REAL (real stock positions do not participate in netting). |
| 12 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that modified the configuration row. Captured via suser_name() computed column in parent table. Audit trail - historical rows show "TRAD\eladav", "CICD_DB", "TRAD\bonniegr". |
| 13 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level identity at time of change from context_info(). Always NULL in observed historical data. |
| 14 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this configuration version became active. Managed by SQL Server temporal engine. |
| 15 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. Clustered index leads with SysEndTime for efficient point-in-time queries. |
| 16 | ValidateHBCExecution | bit | NO | 0 | CODE-BACKED | Whether to validate Hedge Business Condition (HBC) execution rules for this flow. true for PathToDLT and RealFutures. |
| 17 | AllowHBCFailover | bit | NO | 0 | CODE-BACKED | Whether to allow fallback to alternative execution if HBC validation fails. true for OMS_CFDs and OMS_REAL in current config. |
| 18 | SLTPBehavior | smallint | NO | 0 | CODE-BACKED | Stop Loss / Take Profit behavior variant: 0=standard SLTP handling, 1=futures SLTP behavior (RealFutures only). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BusinessFlowID | Hedge.BusinessFlowBehavior | Temporal | This row is a past version of a parent table row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.BusinessFlowBehavior | HISTORY_TABLE | Temporal system | Parent table - SQL Server writes here automatically |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BusinessFlowBehavior (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.BusinessFlowBehavior | Table | Parent temporal table |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.BusinessFlowBehavior | Table | SQL Server temporal engine writes here automatically on UPDATE/DELETE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_BusinessFlowBehavior | Clustered | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

No constraints. Temporal history tables have no constraints - integrity enforced by SQL Server temporal engine.

Storage: ON [MAIN] filegroup with PAGE compression.

---

## 8. Sample Queries

### 8.1 View change history for a specific business flow
```sql
SELECT BusinessFlowID, BusinessFlowName, SpreadLogic, UpdateNetting,
       ValidateCircuitBreakers, SLTPBehavior, DbLoginName, SysStartTime, SysEndTime
FROM [History].[BusinessFlowBehavior] WITH (NOLOCK)
WHERE BusinessFlowID = @BusinessFlowID
ORDER BY SysStartTime DESC
```

### 8.2 Point-in-time query using temporal syntax (preferred)
```sql
SELECT BusinessFlowID, BusinessFlowName, SpreadLogic, ApplyFactor, ValidateCircuitBreakers
FROM [Hedge].[BusinessFlowBehavior] WITH (NOLOCK)
FOR SYSTEM_TIME AS OF '2024-06-01 00:00:00'
ORDER BY BusinessFlowID
```

### 8.3 Find all configuration changes in a date range
```sql
SELECT BusinessFlowID, BusinessFlowName, DbLoginName,
       SysStartTime AS ChangedAt, SysEndTime AS SupersededAt,
       SpreadLogic, ValidateCircuitBreakers
FROM [History].[BusinessFlowBehavior] WITH (NOLOCK)
WHERE SysEndTime BETWEEN @StartDate AND @EndDate
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (live data provided full value maps) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BusinessFlowBehavior | Type: Table | Source: etoro/etoro/History/Tables/History.BusinessFlowBehavior.sql*
