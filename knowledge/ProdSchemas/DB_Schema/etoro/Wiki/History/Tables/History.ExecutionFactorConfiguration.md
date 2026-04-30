# History.ExecutionFactorConfiguration

> Temporal system-versioned history table storing all past versions of per-instrument execution factor configurations - recording every change to the sizing multipliers applied when the hedge execution layer places orders for specific (strategy, instrument) combinations.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; rows identified by (StrategyID, InstrumentID) + SysStartTime + SysEndTime |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

This table is the **SQL Server temporal history store** for `Hedge.ExecutionFactorConfiguration`. SQL Server automatically moves rows here whenever an execution factor configuration is updated or deleted.

`Hedge.ExecutionFactorConfiguration` provides **per-instrument execution sizing multipliers** for the hedge execution layer. Each row binds a specific (StrategyID, InstrumentID) pair to an `ExecutionFactor` decimal value that scales the calculated hedge order size at execution time. This allows the hedging system to fine-tune order sizing for individual instruments beyond the exchange-level or strategy-level defaults.

**Relationship to execution strategy architecture**:
- `Hedge.ExecutionStrategyModels` (documented) - defines the plugin classes (LimitOrderBid/Mid/Ask, MarketOrder)
- `Hedge.ExecutionFactorConfiguration` - assigns a size multiplier to specific (strategy + instrument) pairs
- `Hedge.ExecutionStrategyModelConfigurations` (next batch) - maps strategies to account/instrument combinations

**Read by**: `Hedge.GetStrategyInstrumentExecutionFactorConfiguration` - returns all active (IsActive=1) rows as `(InstrumentID, StrategyID, ExecutionFactor)` for the hedging application to load at startup.

**Contrast with server-level factor**: `Hedge.GetStrategyExecutionFactorConfiguration` reads `Trade.HedgeServer.ExecutionFactor` (not this table) - providing the server-wide default. `ExecutionFactorConfiguration` provides instrument-specific overrides on top of that server default.

**Both tables are empty** (0 rows in History and Hedge schema in staging). The table structure and SPs are in place but no instrument-level factor overrides have been configured. All hedge sizing uses the server-level `Trade.HedgeServer.ExecutionFactor` default.

---

## 2. Business Logic

### 2.1 Temporal Versioning - How History Is Recorded

**What**: SQL Server automatically populates this table via system-versioning whenever an execution factor configuration is updated or deleted.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `StrategyID`, `InstrumentID`

**Rules**:
- When a row is **updated**: SQL Server moves the old version here with `SysEndTime` = moment of update.
- When a row is **deleted**: SQL Server moves the row here with `SysEndTime` = deletion timestamp.
- Active rows in `Hedge.ExecutionFactorConfiguration` have `SysEndTime = '9999-12-31...'` and are NOT in this history table.
- CLUSTERED index on `(SysEndTime, SysStartTime)` enables efficient `FOR SYSTEM_TIME AS OF` temporal queries.

### 2.2 INSERT Trigger Creates Zero-Duration History Rows

**What**: `Tr_T_ExecutionFactorConfiguration_INSERT` fires a no-op UPDATE after every INSERT, generating a zero-duration history row for each new configuration.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `StrategyID`, `InstrumentID`

**Rules**:
- After INSERT, trigger executes: `UPDATE A SET A.StrategyID = A.StrategyID, A.InstrumentID = A.InstrumentID` (no-op self-update joined on StrategyID + InstrumentID).
- SQL Server temporal treats this as an UPDATE, moving the just-inserted row to history with `SysStartTime = SysEndTime = T` (zero-duration).
- Same INSERT trigger pattern as `Hedge.ExecutionStrategyModels` (Tr_T_ExecutionStrategyModels_INSERT) and `Hedge.ExecutionErrorMapping`.

### 2.3 IsActive Flag - Soft Enable/Disable

**What**: Each configuration row can be enabled or disabled without deletion, preserving history.

**Columns/Parameters Involved**: `IsActive`, `StrategyID`, `InstrumentID`

**Rules**:
- `IsActive = 1`: This factor override is active - returned by `Hedge.GetStrategyInstrumentExecutionFactorConfiguration`.
- `IsActive = 0` (default): Row exists but is inactive - NOT returned by the SP. Allows pre-staging configurations before enabling them.
- Setting `IsActive = 0` instead of deleting is the preferred way to disable a factor override; the history table will record the change as an UPDATE (via temporal versioning) rather than a DELETE, preserving the audit trail.
- Default value = 0 means newly inserted rows are inactive until explicitly activated.

### 2.4 Execution Factor Semantics

**What**: `ExecutionFactor` is a decimal(16,8) sizing multiplier applied to hedge order calculations.

**Columns/Parameters Involved**: `ExecutionFactor`, `StrategyID`, `InstrumentID`

**Rules**:
- A value of `1.0` = 100% of calculated size (no adjustment).
- A value of `0.5` = 50% of calculated size (half-sizing for this instrument/strategy).
- A value of `2.0` = 200% of calculated size (double-sizing, e.g., for instruments with high slip tolerance).
- 8 decimal places of precision for fine-grained control.
- Provides per-instrument control layered on top of the server-level `Trade.HedgeServer.ExecutionFactor`.

---

## 3. Data Overview

Both `History.ExecutionFactorConfiguration` and `Hedge.ExecutionFactorConfiguration` have **0 rows** in staging. The table structure and associated SPs (`Hedge.GetStrategyInstrumentExecutionFactorConfiguration`) are in place, but no instrument-level execution factor overrides are currently configured.

This means the hedge execution layer is operating purely on the server-level `Trade.HedgeServer.ExecutionFactor` for all instruments, without any per-(strategy, instrument) customization.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StrategyID | int | NO | - | VERIFIED | The execution strategy model. Composite PK with InstrumentID in source table. FK to Hedge.ExecutionStrategyModels (ModelID). Known values: 1=LimitOrderBid, 2=LimitOrderMid, 3=LimitOrderAsk, 4=MarketOrder. Determines which order placement strategy this factor applies to. |
| 2 | InstrumentID | int | NO | - | VERIFIED | The instrument for which this execution factor applies. Composite PK with StrategyID. Implicit FK to Trade.Instrument. A specific InstrumentID row allows per-instrument sizing control for the given strategy. |
| 3 | ExecutionFactor | decimal(16, 8) | NO | - | VERIFIED | The sizing multiplier applied to hedge order calculations for this (StrategyID, InstrumentID) pair. 1.0 = no adjustment. < 1.0 = smaller orders. > 1.0 = larger orders. 8 decimal places for precision. Overrides the server-level Trade.HedgeServer.ExecutionFactor for this specific combination. |
| 4 | IsActive | bit | YES | 0 | VERIFIED | Soft enable/disable flag. 1 = active, returned by Hedge.GetStrategyInstrumentExecutionFactorConfiguration. 0 (default) = inactive, ignored by hedging application. Allows pre-staging or disabling overrides without deleting the row (preserving history). |
| 5 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login captured via suser_name() computed column on source (AS suser_name()). Identifies who changed the configuration at the database level. NULL if login unavailable. |
| 6 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application user identity captured via context_info() computed column (AS CONVERT(varchar(500), context_info())). Contains email padded with null bytes when set. Must be trimmed with REPLACE/RTRIM to use. NULL when not set (most direct DB changes). |
| 7 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this configuration version became active. Managed by SQL Server temporal system-versioning. Equal to SysEndTime for INSERT-triggered zero-duration rows. |
| 8 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version was superseded. Clustered index leading column. Equal to SysStartTime for INSERT-triggered zero-duration rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| StrategyID | Hedge.ExecutionStrategyModels | Implicit (FK on source) | The execution strategy model (1=LimitOrderBid, 2=LimitOrderMid, 3=LimitOrderAsk, 4=MarketOrder) |
| InstrumentID | Trade.Instrument | Implicit | The instrument for which this factor applies |
| (all columns) | Hedge.ExecutionFactorConfiguration | Temporal | This row is a historical version of the source table row with matching (StrategyID, InstrumentID) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ExecutionFactorConfiguration | (all columns) | Temporal (SYSTEM_VERSIONING) | Source table - SQL Server writes superseded rows here automatically on UPDATE/DELETE |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ExecutionFactorConfiguration (table)
- Temporal history leaf node - no code-level dependencies
- Populated automatically from Hedge.ExecutionFactorConfiguration (table)
- INSERT trigger Tr_T_ExecutionFactorConfiguration_INSERT on source creates zero-duration rows

Hedge.ExecutionFactorConfiguration (source) is read by:
- Hedge.GetStrategyInstrumentExecutionFactorConfiguration (SP)
  -> SELECT InstrumentID, StrategyID, ExecutionFactor WHERE IsActive=1
  -> Called by hedging application to load active factor overrides at startup

Related (server-level factor, different grain):
- Hedge.GetStrategyExecutionFactorConfiguration (SP)
  -> SELECT HedgeServerID, ExecutionFactor FROM Trade.HedgeServer
  -> Server-wide default (not per-instrument)
```

### 6.1 Objects This Depends On

No dependencies. Temporal history table populated automatically by SQL Server.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionFactorConfiguration | Table | Source table - SQL Server writes old row versions here on UPDATE/DELETE; INSERT trigger also generates zero-duration rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ExecutionFactorConfiguration | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

**Filegroup**: [DICTIONARY] - same as source table and History.ExecutionStrategyModels; consistent classification as reference/configuration data.
**Storage**: DATA_COMPRESSION = PAGE (table-level and index-level).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | Temporal history tables cannot have PK, UNIQUE, FK, or CHECK constraints in SQL Server |

**Source table constraints** (Hedge.ExecutionFactorConfiguration):

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_executionFactorConfiguration | PRIMARY KEY (CLUSTERED) | Uniqueness on (StrategyID, InstrumentID) |
| DF...IsActive | DEFAULT | IsActive = 0 (inactive by default) |

---

## 8. Sample Queries

### 8.1 Full change history for a specific (strategy, instrument)
```sql
-- Historical versions
SELECT StrategyID, InstrumentID, ExecutionFactor, IsActive, DbLoginName,
       REPLACE(RTRIM(AppLoginName), CHAR(0), '') AS AppLoginName_Clean,
       SysStartTime, SysEndTime,
       DATEDIFF(SECOND, SysStartTime, SysEndTime) AS DurationSeconds
FROM [History].[ExecutionFactorConfiguration]
WHERE StrategyID = 3  -- LimitOrderAsk
  AND InstrumentID = 4  -- NASDAQ
ORDER BY SysStartTime
UNION ALL
SELECT StrategyID, InstrumentID, ExecutionFactor, IsActive, DbLoginName,
       NULL, SysStartTime, SysEndTime, NULL
FROM [Hedge].[ExecutionFactorConfiguration]
WHERE StrategyID = 3 AND InstrumentID = 4
```

### 8.2 What factors were active at a specific point in time
```sql
SELECT StrategyID, InstrumentID, ExecutionFactor, IsActive, DbLoginName, SysStartTime, SysEndTime
FROM [History].[ExecutionFactorConfiguration]
WHERE '2024-01-15' BETWEEN SysStartTime AND SysEndTime
  AND IsActive = 1
  AND SysStartTime < SysEndTime  -- exclude zero-duration INSERT artifacts
ORDER BY StrategyID, InstrumentID
```

### 8.3 Current active factor overrides (what the hedging app loads)
```sql
-- Mirrors Hedge.GetStrategyInstrumentExecutionFactorConfiguration
SELECT InstrumentID, StrategyID, ExecutionFactor
FROM [Hedge].[ExecutionFactorConfiguration]
WHERE IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8.5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Note: Both History and Hedge tables have 0 rows in staging - feature is configured but not in use.*
*Object: History.ExecutionFactorConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.ExecutionFactorConfiguration.sql*
