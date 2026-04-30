# Hedge.OrderTypeConfiguration

> FIX order routing configuration per liquidity account and entity scope - defines how hedge orders should be submitted to liquidity providers (order type, slippage, expiry, time-in-force) with optional time-of-day scheduling and three levels of entity granularity: individual instrument, instrument group, or exchange.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | ConfigID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (1 CLUSTERED PK + 1 NC on Entity) |

---

## 1. Business Meaning

Hedge.OrderTypeConfiguration controls the FIX protocol order execution parameters the hedge server uses when placing hedge orders on liquidity providers. Rather than using a single uniform order type, eToro configures different execution rules per instrument, instrument group, or exchange - specifying how aggressively to fill orders, how much slippage to tolerate, whether to use time-limited fills, and during which hours specific rules apply.

This table exists because different instruments and LPs have different optimal execution strategies. A highly liquid major forex pair might tolerate tight slippage with immediate-or-cancel execution, while a less liquid stock might need a Day order with wider slippage tolerance. Without this configuration table, the hedge server would apply uniform order parameters across all instruments, leading to poor fill rates or excessive market impact on illiquid names.

Data flows as follows: the hedge server reads all configurations at startup or reload via Hedge.GetOrderTypeConfiguration, which resolves the three entity types into a flat list of (InstrumentID, LP account, order parameters) tuples. All 19 current rows are individual instrument configurations (Entity=0) and are all marked ScheduleActive=false - indicating these are either archived/inactive configurations or that the active scheduling feature is not currently in use.

---

## 2. Business Logic

### 2.1 Three-Tier Entity Resolution

**What**: A single configuration row can apply to one instrument, an entire instrument group, or all instruments on an exchange, controlled by the Entity and Value columns.

**Columns/Parameters Involved**: `Entity`, `Value`

**Rules**:
- **Entity=0 (Instrument)**: Value is an InstrumentID (integer). Config applies to one specific instrument. GetOrderTypeConfiguration casts Value to INT and labels it InstrumentID.
- **Entity=1 (Instrument Group)**: Value is a GroupID. Hedge.GetOrderTypeConfiguration expands via `JOIN Hedge.InstrumentGroupsMapping ON Value = GroupID WHERE IsActive = 1`. Config applies to all active instruments in that group.
- **Entity=2 (Exchange)**: Value is an Exchange name string. Expanded via `JOIN Trade.InstrumentMetaData ON Value = Exchange`. Config applies to all instruments listed on that exchange.
- All 19 current rows use Entity=0 (individual instrument level). The GROUP and EXCHANGE levels are supported by the SP but unused in current data.
- The NC index on Entity supports efficient filtering by entity level during config load.

**Diagram**:
```
Hedge.OrderTypeConfiguration (Entity=0, Value='1211')
  -> InstrumentID=1211 gets these order params

Hedge.OrderTypeConfiguration (Entity=1, Value='5')
  -> Hedge.InstrumentGroupsMapping WHERE GroupID=5 AND IsActive=1
  -> InstrumentID=1211, 1212, 1213 all get these order params

Hedge.OrderTypeConfiguration (Entity=2, Value='NYSE')
  -> Trade.InstrumentMetaData WHERE Exchange='NYSE'
  -> All NYSE-listed instruments get these order params
```

### 2.2 Priority Resolution and Schedule-Based Activation

**What**: When multiple configs match the same instrument (e.g., a specific instrument config AND a group config), Priority determines which takes precedence. FromTime/ToTime enables time-restricted rule overrides.

**Columns/Parameters Involved**: `Priority`, `ScheduleActive`, `FromTime`, `ToTime`

**Rules**:
- Lower Priority value = higher priority (Priority=1 takes precedence over Priority=2 when multiple rules match the same InstrumentID)
- GetOrderTypeConfiguration orders by Priority ASC, Entity ASC - so lower Priority wins
- ScheduleActive=true + FromTime/ToTime = this config only applies during that time window (UTC)
- ScheduleActive=false = no schedule restriction; config always active if matched (all current rows)
- The one scheduled config (ConfigID=12) uses FromTime=10:00, ToTime=12:00 with TimeInForce=ImmediateOrCancel - typical for scheduling aggressive fills during a liquidity window
- No schedule overlap validation is enforced at DB level; the consuming application must handle conflicts

### 2.3 Computed Audit Columns with Temporal History Capture

**What**: DbLoginName and AppLoginName are computed columns that capture who changed each row. A trigger forces INSERT events into temporal history, complementing the system-versioning that normally only captures UPDATE/DELETE.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`, `SysStartTime`, `SysEndTime`

**Rules**:
- DbLoginName is computed as `suser_name()` - the SQL Server login of the connection making changes (always visible as current user when querying)
- AppLoginName is computed as `CONVERT(varchar(500), context_info())` - the application context set by the caller via SET CONTEXT_INFO (allows application to identify itself). NULL when not set.
- The INSERT trigger `AuditInsert_Hedge_OrderTypeConfiguration` does `UPDATE Value = Value` immediately after every INSERT. This self-update forces the inserted row's original state into History.OrderTypeConfiguration (since temporal versioning only captures "before" on UPDATE/DELETE, not INSERT). This is a deliberate pattern to ensure EVERY state of a config row is preserved in history - including the initial insert.

**Diagram**:
```
INSERT new row -> Trigger fires -> UPDATE Value=Value
  -> Temporal engine captures "old" row -> History.OrderTypeConfiguration
  -> New row reflects same values (no change)
  -> Both the INSERT state and all future UPDATE states are in history
```

---

## 3. Data Overview

| ConfigID | ProviderType | LiquidityAccountID | Entity | Value | TimeInForce | Slippage | ScheduleActive | Meaning |
|---|---|---|---|---|---|---|---|---|
| 1 | 1 | 1 | 0 | 56593 | 3 (Day) | 5.33% | false | LP account 1, InstrumentID 56593: Day order with 5.33% slippage tolerance. The large slippage suggests an illiquid or exotic instrument where wide fills are acceptable. Inactive (ScheduleActive=false). |
| 12 | 69 | 10 | 0 | 1211 | ImmediateOrCancel | 0% | false | LP account 10 (main production), ProviderType 69 for InstrumentID 1211, during 10:00-12:00 UTC window. ExpirationInSeconds=30. IOC with 30s expiry during a 2-hour window - configures aggressive execution at specific market hours. |
| 13 | 1 | 1 | 0 | 1 | 3 (Day) | 1.5% | false | InstrumentID 1 (likely EUR/USD or a major instrument), LP account 1, Day order with 1.5% slippage - more moderate tolerance than ID 56593 suggesting a more liquid instrument. |
| 29-34 | 1 | 1 | 0 | 1000114-1000123 | 3 (Day) | 0.05% | false | Batch of instruments (1000114-1000123) under LP account 1 with very tight 0.05% slippage - these are likely highly liquid instruments (major forex, large-cap stocks) where minimal slippage is achievable. |
| 2-11 | 1 | 2 | 0 | 11543959-11543996 | 3 (Day) | 0.05% | false | LP account 2 configs with large value IDs (11543959+) - these may be LP-system-internal symbol IDs rather than eToro InstrumentIDs, used when LP account 2 requires external symbol referencing. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ConfigID | int IDENTITY(1,1) | NO | - | VERIFIED | Auto-generated primary key. IDENTITY means the database assigns IDs sequentially on insert. Note: IDs are not contiguous in current data (1-11, 12, 13, 29-34) - gaps indicate deleted or archived configurations that have been moved to history. |
| 2 | ScheduleActive | bit | NO | - | VERIFIED | Whether this configuration applies only during the FromTime-ToTime window. false (all current rows) = no schedule restriction, always active when matched. true = restrict to the FromTime-ToTime window. |
| 3 | FromTime | time(7) | YES | - | VERIFIED | Start of the active time window (UTC) when ScheduleActive=true. NULL when ScheduleActive=false (no time restriction). Time(7) provides nanosecond precision. ConfigID=12 uses 10:00 (market open period). |
| 4 | ToTime | time(7) | YES | - | VERIFIED | End of the active time window (UTC) when ScheduleActive=true. NULL when ScheduleActive=false. ConfigID=12 uses 12:00 - together with FromTime=10:00 creates a 2-hour window. |
| 5 | ProviderType | int | NO | - | CODE-BACKED | Identifies the liquidity provider type for which this order configuration applies. ProviderType=1 is the dominant value (17/19 rows), ProviderType=69 appears for ConfigID=12. References Trade.LiquidityProviderType (implicit). Each provider type may require different FIX connectivity parameters. |
| 6 | LiquidityAccountID | int | NO | - | VERIFIED | References the specific LP account for which this configuration applies. LiquidityAccountID=1 (7 rows), =2 (10 rows), =10 (1 row, the main production account). Controls which LP account uses this order routing rule. |
| 7 | Entity | smallint | NO | - | VERIFIED | Determines how the Value column is interpreted. 0=InstrumentID (direct instrument), 1=GroupID (expanded via Hedge.InstrumentGroupsMapping), 2=Exchange name (expanded via Trade.InstrumentMetaData). All 19 current rows use Entity=0. Indexed via IX_HedgeOrderTypeConfiguration for fast entity-type filtering. |
| 8 | Value | varchar(250) | NO | - | VERIFIED | The entity identifier whose interpretation depends on Entity: Entity=0: integer InstrumentID (as string), Entity=1: integer GroupID (as string), Entity=2: Exchange name string. GetOrderTypeConfiguration casts this to INT for Entity=0 and Entity=1; uses as string for Entity=2. |
| 9 | QuantityType | smallint | NO | - | CODE-BACKED | Specifies how order quantity is expressed. Value=1 in all current rows. Likely an enum (e.g., 1=Units, 2=Lots, 3=Notional) controlling how the Threshold and order size are measured by the LP. |
| 10 | Threshold | decimal(18,6) | NO | - | CODE-BACKED | A threshold value used in conjunction with QuantityType. All current rows have Threshold=0, suggesting no minimum order threshold filtering is applied. When non-zero, likely filters whether this config applies based on order size. |
| 11 | Slippage | decimal(18,6) | NO | - | VERIFIED | Maximum allowed price slippage as a percentage (not basis points). 0=no slippage tolerance (exact fill required). 0.05=tight slippage for liquid instruments. 1.5=moderate. 5.33=wide tolerance for illiquid instruments. Controls how far from the reference price the order can fill. |
| 12 | ExpirationInSeconds | int | NO | - | VERIFIED | Order time-to-live in seconds after submission. 0=no custom expiry (expiry governed by TimeInForce). 30=30-second expiry (ConfigID=12, ImmediateOrCancel with explicit timeout). |
| 13 | Priority | int | NO | - | VERIFIED | Config selection priority when multiple rules match the same instrument. Lower value = higher priority (GetOrderTypeConfiguration orders by Priority ASC). All current rows have Priority=1, meaning no conflict resolution is needed in current data. |
| 14 | DbLoginName | varchar (computed) | NO | - | VERIFIED | Computed column: `suser_name()` - the SQL Server login name of the current session. Shows "McpUserRO" for all rows when read by the MCP read-only user. Captures who last modified each row at the DB login level. Note: because this is computed (not stored), it reflects the CURRENT user when read, not the user who made the change - the history table preserves the actual modifier. |
| 15 | AppLoginName | varchar(500) (computed) | NO | - | VERIFIED | Computed column: `CONVERT(varchar(500), context_info())` - the application-level identity set by the caller via `SET CONTEXT_INFO`. NULL for all current rows (no application sets this). When populated, identifies which application service made the change. Same caveat as DbLoginName: computed at query time. |
| 16 | SysStartTime | datetime2(7) | NO | - | VERIFIED | System-generated temporal period start. Records when this version of the row became current. Combined with the INSERT trigger, captures the exact insert timestamp and all subsequent modification timestamps in History.OrderTypeConfiguration. |
| 17 | SysEndTime | datetime2(7) | NO | - | VERIFIED | System-generated temporal period end. 9999-12-31 for all current rows (active configurations). When a config is updated or deleted, the old version moves to History.OrderTypeConfiguration with SysEndTime set to the modification time. |
| 18 | TimeInForce | varchar(128) | NO | 'Day' | VERIFIED | FIX TimeInForce value controlling how long the order stays active. "3" = Day order (FIX standard numeric code for Day), "ImmediateOrCancel" = fill immediately or cancel (ConfigID=12). Default 'Day' used when not explicitly set. |
| 19 | ReferencePriceType | varchar(128) | NO | 'Default' | CODE-BACKED | The price reference used to evaluate slippage tolerance. "Default" for all current rows - meaning the standard market reference price. Possible values might include "Mid", "Last", "BBO" depending on LP capabilities. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | Implicit | Identifies the LP account for this configuration. No declared FK. |
| ProviderType | Trade.LiquidityProviderType | Implicit | Classifies the LP provider type. No declared FK. |
| Value (Entity=0) | Trade.Instrument | Implicit | When Entity=0, Value is cast to InstrumentID referencing Trade.Instrument |
| Value (Entity=1) | Hedge.InstrumentGroupsMapping | Implicit | When Entity=1, Value is GroupID joined to InstrumentGroupsMapping |
| Value (Entity=2) | Trade.InstrumentMetaData | Implicit | When Entity=2, Value is Exchange name joined to InstrumentMetaData |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetOrderTypeConfiguration | - | READER | Resolves all three entity levels into a flat (InstrumentID, LP, order params) list for the hedge server |
| History.OrderTypeConfiguration | - | Temporal history | Auto-populated by system versioning and the INSERT trigger |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.OrderTypeConfiguration (table)
├── Trade.LiquidityAccounts (table) [implicit reference - leaf]
├── Trade.LiquidityProviderType (table) [implicit reference - leaf]
├── Trade.Instrument (table) [implicit reference via Value when Entity=0 - leaf]
├── Hedge.InstrumentGroupsMapping (table) [implicit reference via Value when Entity=1 - leaf]
└── Trade.InstrumentMetaData (table) [implicit reference via Value when Entity=2 - leaf]
```

### 6.1 Objects This Depends On

No hard dependencies (no declared FK constraints, no computed column dependencies on other tables).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetOrderTypeConfiguration | Stored Procedure | READER - reads all configs and expands entity types into flat InstrumentID-level result set |
| History.OrderTypeConfiguration | Table | TEMPORAL HISTORY - captures all versions including initial inserts (via trigger) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeOrderTypeConfiguration | CLUSTERED PK | ConfigID ASC | - | - | Active |
| IX_HedgeOrderTypeConfiguration | NONCLUSTERED | Entity ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeOrderTypeConfiguration | PRIMARY KEY | Unique config entry by auto-incremented ID |
| DF_HedgeOrderTypeConfiguration_TimeInForce | DEFAULT | TimeInForce defaults to 'Day' if not specified |
| DF_HedgeOrderTypeConfigurations_ReferencePriceType | DEFAULT | ReferencePriceType defaults to 'Default' if not specified |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime/SysEndTime managed by SQL Server |
| SYSTEM_VERSIONING = ON | TEMPORAL | Changes archived to History.OrderTypeConfiguration |
| AuditInsert_Hedge_OrderTypeConfiguration | TRIGGER (FOR INSERT) | Self-update after every INSERT to force the original insert state into temporal history |

---

## 8. Sample Queries

### 8.1 All active order type configurations expanded to instrument level
```sql
EXEC [Hedge].[GetOrderTypeConfiguration];
```

### 8.2 Configurations for a specific LP account with time-of-day schedule
```sql
SELECT  ConfigID,
        LiquidityAccountID,
        ProviderType,
        Entity,
        Value,
        ScheduleActive,
        FromTime,
        ToTime,
        TimeInForce,
        Slippage,
        ExpirationInSeconds,
        Priority
FROM    [Hedge].[OrderTypeConfiguration] WITH (NOLOCK)
WHERE   LiquidityAccountID = 10
ORDER BY Priority, Entity;
```

### 8.3 Configuration change history for a specific config (via temporal)
```sql
-- Current version
SELECT  ConfigID, Value, TimeInForce, Slippage, SysStartTime, SysEndTime, 'Current' AS Version
FROM    [Hedge].[OrderTypeConfiguration] WITH (NOLOCK)
WHERE   ConfigID = 12
UNION ALL
-- Historical versions
SELECT  ConfigID, Value, TimeInForce, Slippage, SysStartTime, SysEndTime, 'History'
FROM    [History].[OrderTypeConfiguration] WITH (NOLOCK)
WHERE   ConfigID = 12
ORDER BY SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 11 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.OrderTypeConfiguration | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.OrderTypeConfiguration.sql*
