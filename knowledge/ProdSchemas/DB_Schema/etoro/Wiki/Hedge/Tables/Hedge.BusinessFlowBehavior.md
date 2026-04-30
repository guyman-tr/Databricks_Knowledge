# Hedge.BusinessFlowBehavior

> Configuration table that defines the set of execution behavior flags for each named hedging business flow, controlling which validations, processing steps, and provider-specific features are active when the hedge engine routes an order.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | BusinessFlowID (smallint, PK CLUSTERED) |
| **Partition** | No (on [MAIN] filegroup) |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

`Hedge.BusinessFlowBehavior` is the master configuration table for execution pathway behavior in the eToro hedge engine. A "business flow" represents a distinct order routing pathway - for example, the legacy hedging system, the Order Management System for CFDs, or a direct provider path to a named market maker (Virtu, DLT). Each row is a behavioral profile: a set of boolean flags and mode values that tell the hedge engine exactly which validation checks to run and which processing steps to apply when executing through that pathway.

This table exists because different execution pathways have fundamentally different capabilities and requirements. A direct provider path to Virtu (a market maker) handles min-order validation internally, so the hedge engine should not duplicate that check. The OMS for real stocks does not update netting tables, because real stock positions are tracked differently. Without this table, the hedge engine would need hard-coded pathway logic; this config table makes pathway behavior data-driven and auditable.

Data flows through this table as follows: `Hedge.GetBusinessFlowBehaviorSettings` reads all rows on startup and the application caches the full set of profiles. When the hedge engine needs to execute an order, it looks up the BusinessFlowID for the relevant server/instrument configuration and applies the corresponding behavior flags to determine which validation pipeline stages to invoke and which optional processing steps to enable.

---

## 2. Business Logic

### 2.1 Execution Validation Pipeline

**What**: Four validation flags control which pre-execution checks the hedge engine runs before sending an order to a liquidity provider.

**Columns/Parameters Involved**: `ValidateMinOrderSize`, `ValidateMaxDealSize`, `ValidateMarketRange`, `ValidateCircuitBreakers`

**Rules**:
- When TRUE, the hedge engine enforces the check; when FALSE, the check is bypassed (the provider handles it or it is not applicable)
- `ValidateMaxDealSize` is TRUE for all 7 flows - maximum deal size is always enforced by the hedge engine regardless of provider
- `ValidateMarketRange` is only enabled for Legacy and EMS flows - OMS and direct-path flows bypass market range checking
- `ValidateCircuitBreakers` is disabled only for OMS_CFDs and OMS_REAL - those flows rely on the OMS infrastructure
- `ValidateMinOrderSize` is disabled for PathToVirtu, PathToDLT, and RealFutures - direct provider paths where the provider enforces this

**Diagram**:
```
Order Arrives
     |
     v
[ValidateMinOrderSize] -> skip if FALSE
     |
     v
[ValidateMaxDealSize]  -> always runs (TRUE for all flows)
     |
     v
[ValidateMarketRange]  -> skip if FALSE (OMS, direct-path flows)
     |
     v
[ValidateCircuitBreakers] -> skip if FALSE (OMS flows)
     |
     v
Order Submitted to Provider
```

### 2.2 Execution Flow Profiles

**What**: The 7 named business flows fall into four logical groups with distinct behavior profiles.

**Columns/Parameters Involved**: `BusinessFlowName`, `ApplyFactor`, `ApplySplitLogic`, `ApplyRounding`, `SpreadLogic`, `UpdateNetting`, `AllowHBCFailover`, `ValidateHBCExecution`, `SLTPBehavior`

**Rules**:
- **Traditional flows** (Legacy=1, EMS=2): Full validation suite, factor multiplication, split logic, and rounding all active. SpreadLogic=1 (standard spread). These represent the original hedge system behavior.
- **OMS flows** (OMS_CFDs=3, OMS_REAL=6): Stripped-back validation (no factor, no split). HBC failover allowed. OMS_REAL also skips netting updates because real stock positions are not tracked in netting tables.
- **Direct provider paths** (PathToVirtu=4, PathToDLT=5): No factor/split/rounding; the provider executes at exact sizes. PathToDLT uses SpreadLogic=2 (alternative mode) and enables HBC execution validation. PathToVirtu uses SpreadLogic=0 (no spread management).
- **Futures** (RealFutures=7): SpreadLogic=0, SLTPBehavior=1 (alternative SL/TP handling for futures semantics), HBC execution required.

**Diagram**:
```
BusinessFlowID  Name            Factor  Split  SpreadLogic  Netting  HBC
1               Legacy          Y       Y       1 (std)      Y        -
2               EMS             Y       Y       1 (std)      Y        -
3               OMS_CFDs        N       N       1 (std)      Y        Failover
4               PathToVirtu     N       N       0 (none)     Y        -
5               PathToDLT       N       N       2 (alt)      Y        Validate
6               OMS_REAL        N       N       1 (std)      N        Failover
7               RealFutures     N       N       0 (none)     Y        Validate+SLTPalt
```

### 2.3 Temporal Versioning + Audit

**What**: Full change history is maintained automatically via SQL Server system versioning.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- Every change to any row is captured in `History.BusinessFlowBehavior` with the old values and the exact time range they were valid
- `DbLoginName` captures the SQL Server login (via `suser_name()`); `AppLoginName` captures application context (via `CONTEXT_INFO()`)
- The INSERT trigger `Tr_T_BusinessFlowBehavior_INSERT` performs a no-op self-update after every INSERT; this forces the temporal engine to record the initial row version in the history table
- `SysEndTime = 9999-12-31 23:59:59.999` for all currently active rows

---

## 3. Data Overview

| BusinessFlowID | BusinessFlowName | ApplyFactor | SpreadLogic | SLTPBehavior | Meaning |
|---|---|---|---|---|---|
| 1 | Legacy | 1 (true) | 1 | 0 | The original hedge system flow with full validation and factor-based order sizing. Used for instruments before dedicated OMS/provider paths existed. |
| 2 | EMS | 1 (true) | 1 | 0 | Execution Management System flow - mirrors Legacy behavior but routes through the EMS component for improved execution tracking. |
| 3 | OMS_CFDs | 0 (false) | 1 | 0 | Order Management System path for CFD instruments. Reduced validation; allows HBC failover when the primary OMS path is unavailable. |
| 5 | PathToDLT | 0 (false) | 2 | 0 | Direct routing to DLT (a specific liquidity provider) using alternative spread logic (SpreadLogic=2). HBC execution validation required before sending. |
| 7 | RealFutures | 0 (false) | 0 | 1 | Futures instruments with no spread management and alternative SL/TP processing (SLTPBehavior=1) to handle the different order semantics of futures contracts. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BusinessFlowID | smallint | NO | - | VERIFIED | Primary key. Identifies the execution business flow: 1=Legacy, 2=EMS, 3=OMS_CFDs, 4=PathToVirtu, 5=PathToDLT, 6=OMS_REAL, 7=RealFutures. The hedge engine uses this ID to look up the behavior profile for a given execution pathway. |
| 2 | BusinessFlowName | varchar(50) | YES | - | CODE-BACKED | Human-readable name for the flow (e.g., "Legacy", "OMS_CFDs", "PathToVirtu"). Used for display and logging purposes. NULL allowed but always populated in practice. |
| 3 | ApplyFactor | bit | NO | - | CODE-BACKED | Whether to multiply the hedge order size by an instrument-specific hedge factor before sending to the provider. 1=apply factor scaling, 0=send exact requested size. TRUE for Legacy and EMS only; disabled for OMS and direct-provider flows where the provider expects exact quantities. |
| 4 | ValidateMinOrderSize | bit | NO | - | CODE-BACKED | Whether to check that the order meets the minimum order size threshold for the instrument/provider before execution. 1=validate, 0=skip. Disabled for PathToVirtu, PathToDLT, and RealFutures where the provider enforces this constraint directly. |
| 5 | ValidateMaxDealSize | bit | NO | - | VERIFIED | Whether to check that the order does not exceed the maximum deal size limit. 1=validate, 0=skip. TRUE for all 7 flows - max deal size is always enforced by the hedge engine. |
| 6 | ValidateMarketRange | bit | NO | - | CODE-BACKED | Whether to verify that the execution price falls within the acceptable market range (bid-ask spread tolerance). 1=validate, 0=skip. Only enabled for Legacy (1) and EMS (2); bypassed by OMS and direct-path flows. |
| 7 | ValidateCircuitBreakers | bit | NO | - | CODE-BACKED | Whether to check exposure circuit breaker thresholds before submitting the order. 1=validate, 0=skip. Disabled for OMS_CFDs and OMS_REAL (OMS infrastructure manages this); enabled for all other flows including direct-provider paths. |
| 8 | ApplySplitLogic | bit | NO | - | CODE-BACKED | Whether to split large orders into multiple smaller orders for execution. 1=split when needed, 0=send as single order. Only enabled for Legacy (1) and EMS (2). Direct-provider paths and OMS flows send unsplit orders. |
| 9 | ApplyRounding | bit | NO | - | CODE-BACKED | Whether to apply lot/unit rounding to the order quantity before sending. 1=round to lot size, 0=send exact decimal quantity. TRUE for Legacy, EMS, and OMS_REAL; FALSE for direct-provider paths (Virtu, DLT, RealFutures) where exact fractional quantities are accepted. |
| 10 | SpreadLogic | smallint | NO | - | CODE-BACKED | Controls bid/ask spread management during execution. 0=no spread management (raw market prices, for PathToVirtu and RealFutures), 1=standard spread logic (Legacy, EMS, OMS flows), 2=alternative spread mode (PathToDLT only). |
| 11 | UpdateNetting | bit | NO | - | CODE-BACKED | Whether to update the netting tables (Hedge.Netting / Hedge.NettingDaily) after successful execution. 1=update netting, 0=skip. FALSE only for OMS_REAL (real stock positions are not tracked in the netting system). TRUE for all other flows. |
| 12 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. Captures the SQL Server login name executing the DML statement via `suser_name()`. Always populated for direct DB writes; shows "McpUserRO" for read-only MCP queries. Not queryable in WHERE clauses. |
| 13 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Captures the application-level identity passed via `CONTEXT_INFO()` as a VARCHAR(500). NULL when CONTEXT_INFO is not set (e.g., direct DB tools). Populated by services that set context before writes. |
| 14 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Temporal period start. UTC timestamp when this row version became active. Managed automatically by SQL Server SYSTEM_VERSIONING. All rows show 2024-05-28 or later as their initial creation date. |
| 15 | SysEndTime | datetime2(7) | NO | - | VERIFIED | Temporal period end. UTC timestamp when this row version was superseded. Value is 9999-12-31 23:59:59.999 for all currently active rows. Historical versions in History.BusinessFlowBehavior have real end timestamps. |
| 16 | ValidateHBCExecution | bit | NO | 0 | CODE-BACKED | Whether HBC (Hedge Business Component) execution validation is required before submitting the order. 1=validate HBC, 0=no HBC validation. TRUE only for PathToDLT (5) and RealFutures (7) - the flows that route through HBC-managed providers. DEFAULT 0. |
| 17 | AllowHBCFailover | bit | NO | 0 | CODE-BACKED | Whether execution may fail over to the HBC path if the primary execution route is unavailable. 1=allow failover, 0=no failover. TRUE for OMS_CFDs (3) and OMS_REAL (6). DEFAULT 0. |
| 18 | SLTPBehavior | smallint | NO | 0 | CODE-BACKED | Controls how Stop Loss and Take Profit orders are processed during execution. 0=standard SL/TP handling (all flows except RealFutures), 1=alternative SL/TP processing for futures contracts (RealFutures only, where futures order semantics differ from spot). DEFAULT 0. Constraint: D_BusinessFlowBehavior_SLTPBehavior. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetBusinessFlowBehaviorSettings | (table ref) | Lookup | Reads all rows to return the full set of business flow behavior profiles to the application cache |
| History.BusinessFlowBehavior | (temporal) | Temporal History | Stores all previous versions of rows; automatically populated by SQL Server SYSTEM_VERSIONING |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetBusinessFlowBehaviorSettings | Stored Procedure | READER - SELECTs all columns to return the full behavior profile table to the application |
| History.BusinessFlowBehavior | Table | Temporal shadow - stores historical row versions automatically via SYSTEM_VERSIONING |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Hedge_BusinessFlowBehavior | CLUSTERED PK | BusinessFlowID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Hedge_BusinessFlowBehavior | PRIMARY KEY | BusinessFlowID - enforces uniqueness of each flow definition |
| D_BusinessFlowBehavior_SLTPBehavior | DEFAULT | SLTPBehavior = 0 (standard SL/TP behavior is the default for new flows) |
| DEFAULT (unnamed) | DEFAULT | ValidateHBCExecution = 0 (HBC execution validation off by default) |
| DEFAULT (unnamed) | DEFAULT | AllowHBCFailover = 0 (HBC failover off by default) |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime - defines the temporal period columns |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.BusinessFlowBehavior |
| Tr_T_BusinessFlowBehavior_INSERT | TRIGGER | No-op self-UPDATE on INSERT; forces SQL Server temporal engine to record the initial row in the history table |

---

## 8. Sample Queries

### 8.1 Retrieve all business flow behavior profiles

```sql
SELECT
    bfb.BusinessFlowID,
    bfb.BusinessFlowName,
    bfb.ApplyFactor,
    bfb.ValidateMinOrderSize,
    bfb.ValidateMaxDealSize,
    bfb.ValidateMarketRange,
    bfb.ValidateCircuitBreakers,
    bfb.ApplySplitLogic,
    bfb.ApplyRounding,
    bfb.SpreadLogic,
    bfb.UpdateNetting,
    bfb.ValidateHBCExecution,
    bfb.AllowHBCFailover,
    bfb.SLTPBehavior
FROM Hedge.BusinessFlowBehavior bfb WITH (NOLOCK)
ORDER BY bfb.BusinessFlowID
```

### 8.2 Compare validation flags across all flows

```sql
SELECT
    bfb.BusinessFlowID,
    bfb.BusinessFlowName,
    CAST(bfb.ValidateMinOrderSize AS int)    AS ChkMinSize,
    CAST(bfb.ValidateMaxDealSize AS int)     AS ChkMaxSize,
    CAST(bfb.ValidateMarketRange AS int)     AS ChkMktRange,
    CAST(bfb.ValidateCircuitBreakers AS int) AS ChkCircuitBreaker,
    CAST(bfb.ValidateHBCExecution AS int)    AS ChkHBC,
    CAST(bfb.AllowHBCFailover AS int)        AS HBCFailover,
    bfb.SpreadLogic,
    bfb.SLTPBehavior
FROM Hedge.BusinessFlowBehavior bfb WITH (NOLOCK)
ORDER BY bfb.BusinessFlowID
```

### 8.3 Check the change history for a specific flow

```sql
SELECT
    h.BusinessFlowID,
    h.BusinessFlowName,
    h.SysStartTime,
    h.SysEndTime,
    h.SpreadLogic,
    h.SLTPBehavior,
    h.ValidateHBCExecution,
    h.AllowHBCFailover,
    h.DbLoginName,
    h.AppLoginName
FROM History.BusinessFlowBehavior h WITH (NOLOCK)
WHERE h.BusinessFlowID = 7  -- RealFutures
ORDER BY h.SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED (5 elements), 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.BusinessFlowBehavior | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.BusinessFlowBehavior.sql*
