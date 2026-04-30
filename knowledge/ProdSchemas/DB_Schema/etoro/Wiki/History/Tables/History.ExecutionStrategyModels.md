# History.ExecutionStrategyModels

> Temporal system-versioned history table storing all past versions of hedge execution strategy model registrations - recording every change to the .NET assembly and class definitions that implement each execution strategy (LimitOrderBid, LimitOrderMid, LimitOrderAsk, MarketOrder).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; rows identified by (ModelID) + SysStartTime + SysEndTime |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

This table is the **SQL Server temporal history store** for `Hedge.ExecutionStrategyModels`. SQL Server automatically moves rows here whenever a strategy model definition is updated or deleted.

`Hedge.ExecutionStrategyModels` is the **execution strategy registry** for eToro's hedging execution layer. It defines which .NET plugin class to load for each named execution strategy. The hedging application uses this table to dynamically instantiate the correct strategy implementation at runtime by loading the specified DLL assembly and class.

**All 4 active strategy models** (unchanged since initial population on 2022-03-28 by TRAD\shanyso):

| ModelID | Name | Assembly | Class | Strategy Behavior |
|---|---|---|---|---|
| 1 | LimitOrderBid | ExecutionStrategyManager.Models.dll | ExecutionStrategyManager.Models.LimitBid | Submit a limit order at the bid price - buys at bid, lower fill probability but better price |
| 2 | LimitOrderMid | ExecutionStrategyManager.Models.dll | ExecutionStrategyManager.Models.LimitMid | Submit a limit order at the mid price - buys at mid, balanced probability vs price |
| 3 | LimitOrderAsk | ExecutionStrategyManager.Models.dll | ExecutionStrategyManager.Models.LimitAsk | Submit a limit order at the ask price - buys at ask, highest fill probability |
| 4 | MarketOrder | ExecutionStrategyManager.Models.dll | ExecutionStrategyManager.Models.Market | Submit a market order - immediate fill at current market price, no price guarantee |

These ModelIDs are referenced by:
- `Hedge.ExecutionStrategyModelConfigurations` (#25 in this batch) - assigns a model to each instrument/account combination
- `Hedge.ExecutionFactorConfiguration` (#24 in this batch) - links factor configurations to models

The history table has **4 rows** - all zero-duration INSERT artifacts from the initial data load (SysStartTime = SysEndTime = 2022-03-28), meaning none of the 4 strategy models have ever been updated or deleted.

---

## 2. Business Logic

### 2.1 Temporal Versioning - How History Is Recorded

**What**: SQL Server automatically populates this table via system-versioning whenever a strategy model definition is updated or deleted.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ModelID`

**Rules**:
- When a row is **updated**: SQL Server moves the old version here with `SysEndTime` = moment of update.
- When a row is **deleted**: SQL Server moves the row here with `SysEndTime` = deletion timestamp.
- Active rows in `Hedge.ExecutionStrategyModels` have `SysEndTime = '9999-12-31...'` and are NOT in this history table.
- CLUSTERED index on `(SysEndTime, SysStartTime)` enables efficient `FOR SYSTEM_TIME AS OF` temporal queries.

### 2.2 INSERT Trigger Creates Zero-Duration History Rows

**What**: `Tr_T_ExecutionStrategyModels_INSERT` fires a no-op UPDATE after every INSERT, generating a zero-duration history row for each new model.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ModelID`, `Name`

**Rules**:
- After INSERT, trigger executes: `UPDATE A SET A.Name = A.Name` (no-op self-update joined on ModelID).
- SQL Server temporal treats this as an UPDATE, moving the just-inserted row to history with `SysStartTime = SysEndTime = T` (zero-duration).
- This ensures every strategy model ever registered has a history record even if immediately deleted.
- All 4 current history rows are zero-duration INSERT artifacts (SysStartTime = SysEndTime = 2022-03-28T14:44:49.375Z) - none of the models have been modified or removed since initial setup.

### 2.3 Plugin Architecture - Assembly/Class Registry

**What**: The Assembly and Class columns implement a plugin pattern for strategy loading.

**Columns/Parameters Involved**: `Assembly`, `Class`

**Rules**:
- All 4 current strategies use the same DLL: `ExecutionStrategyManager.Models.dll`.
- The hedging application dynamically loads this DLL and instantiates the class specified in `Class` at runtime.
- Strategy selection per instrument is configured separately in `Hedge.ExecutionStrategyModelConfigurations`.
- If a new execution strategy is needed (e.g., TWAP, VWAP), a new row is INSERTed with the new DLL path and class name - no code deployment required for the database layer.
- The 4 limit variants (Bid, Mid, Ask) represent aggressive-to-passive ordering spectrum: Bid = most passive (best price, lowest fill probability), Ask = most aggressive (worst price, highest fill probability for buys).

### 2.4 Audit Attribution via DbLoginName and AppLoginName

**What**: Two computed columns capture who made each change.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- `DbLoginName = suser_name()` - SQL Server login that executed the DML. The 4 initial rows were inserted by `TRAD\shanyso` (developer account).
- `AppLoginName = CONVERT(varchar(500), context_info())` - application user identity, padded with null bytes. NULL when not set.
- The current source table shows `DbLoginName = McpUserRO` (read-only MCP query user) - this is the login reading the table, not the one that modified it.

---

## 3. Data Overview

| ModelID | Name | Assembly | Class | DbLoginName | SysStartTime | SysEndTime | Notes |
|---|---|---|---|---|---|---|---|
| 1 | LimitOrderBid | ExecutionStrategyManager.Models.dll | ExecutionStrategyManager.Models.LimitBid | TRAD\shanyso | 2022-03-28 14:44:49.375 | 2022-03-28 14:44:49.375 | Zero-duration INSERT artifact |
| 2 | LimitOrderMid | ExecutionStrategyManager.Models.dll | ExecutionStrategyManager.Models.LimitMid | TRAD\shanyso | 2022-03-28 14:44:49.375 | 2022-03-28 14:44:49.375 | Zero-duration INSERT artifact |
| 3 | LimitOrderAsk | ExecutionStrategyManager.Models.dll | ExecutionStrategyManager.Models.LimitAsk | TRAD\shanyso | 2022-03-28 14:44:49.375 | 2022-03-28 14:44:49.375 | Zero-duration INSERT artifact |
| 4 | MarketOrder | ExecutionStrategyManager.Models.dll | ExecutionStrategyManager.Models.Market | TRAD\shanyso | 2022-03-28 14:44:49.375 | 2022-03-28 14:44:49.375 | Zero-duration INSERT artifact |

All 4 history rows are zero-duration INSERT artifacts from the initial data population on 2022-03-28. This confirms all 4 strategy models have remained unchanged since they were created. The same 4 ModelIDs are currently active in `Hedge.ExecutionStrategyModels`.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ModelID | int | NO | - | VERIFIED | Surrogate PK from source table (IDENTITY in Hedge.ExecutionStrategyModels). Identifies the execution strategy model. Known values: 1=LimitOrderBid, 2=LimitOrderMid, 3=LimitOrderAsk, 4=MarketOrder. Referenced by Hedge.ExecutionStrategyModelConfigurations and Hedge.ExecutionFactorConfiguration. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | The strategy model's display name. Known values: "LimitOrderBid", "LimitOrderMid", "LimitOrderAsk", "MarketOrder". Used by the hedging application to identify strategies in configuration and reporting. |
| 3 | Assembly | varchar(100) | NO | - | VERIFIED | The .NET DLL filename containing the strategy implementation. Current value: "ExecutionStrategyManager.Models.dll". The hedging application loads this assembly at runtime. If changed, points to a different plugin file. |
| 4 | Class | varchar(100) | NO | - | VERIFIED | The fully-qualified .NET class name to instantiate. Known values: "ExecutionStrategyManager.Models.LimitBid", "ExecutionStrategyManager.Models.LimitMid", "ExecutionStrategyManager.Models.LimitAsk", "ExecutionStrategyManager.Models.Market". The hedging application uses reflection to instantiate this class from the Assembly. |
| 5 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login that performed the DML, captured via `suser_name()` computed column on source. Initial population by `TRAD\shanyso`. NULL if unavailable. |
| 6 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application user identity captured via `CONVERT(varchar(500), context_info())` computed column. Contains email padded with null bytes when set. NULL for all current history rows (initial load done directly). Must be trimmed with REPLACE/RTRIM. |
| 7 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this model version became active. All current rows = 2022-03-28T14:44:49.375Z (initial load). Equal to SysEndTime for INSERT-triggered zero-duration rows. |
| 8 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version was superseded. All current rows = 2022-03-28T14:44:49.375Z (zero-duration - equal to SysStartTime). Clustered index leading column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | Hedge.ExecutionStrategyModels | Temporal | This row is a historical version of the source table row with matching ModelID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ExecutionStrategyModels | (all columns) | Temporal (SYSTEM_VERSIONING) | Source table - SQL Server writes superseded rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ExecutionStrategyModels (table)
- Temporal history leaf node - no code-level dependencies
- Populated automatically from Hedge.ExecutionStrategyModels (table)
- INSERT trigger on source (Tr_T_ExecutionStrategyModels_INSERT) creates additional zero-duration history rows

Hedge.ExecutionStrategyModels (source) is referenced by:
- Hedge.ExecutionFactorConfiguration (FK on ModelID) -> History.ExecutionFactorConfiguration
- Hedge.ExecutionStrategyModelConfigurations (FK on ModelID) -> History.ExecutionStrategyModelConfigurations
```

### 6.1 Objects This Depends On

No dependencies. Temporal history table populated automatically by SQL Server.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionStrategyModels | Table | Source table - SQL Server writes old row versions here automatically on UPDATE/DELETE; INSERT trigger also generates zero-duration rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ExecutionStrategyModels | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

**Filegroup**: [DICTIONARY] - matching source table, consistent with reference/configuration data classification.
**Storage**: DATA_COMPRESSION = PAGE (table-level and index-level).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | Temporal history tables cannot have PK, UNIQUE, FK, or CHECK constraints in SQL Server |

---

## 8. Sample Queries

### 8.1 Full change history for a specific model
```sql
SELECT ModelID, Name, Assembly, Class, DbLoginName,
       REPLACE(RTRIM(AppLoginName), CHAR(0), '') AS AppLoginName_Clean,
       SysStartTime, SysEndTime,
       DATEDIFF(SECOND, SysStartTime, SysEndTime) AS DurationSeconds
FROM [History].[ExecutionStrategyModels]
WHERE ModelID = 4  -- MarketOrder
ORDER BY SysStartTime
UNION ALL
SELECT ModelID, Name, Assembly, Class, DbLoginName,
       REPLACE(RTRIM(CONVERT(varchar(500), context_info())), CHAR(0), ''),
       SysStartTime, SysEndTime, NULL
FROM [Hedge].[ExecutionStrategyModels]
WHERE ModelID = 4
```

### 8.2 Any non-trivial changes (excluding INSERT artifacts)
```sql
SELECT ModelID, Name, Assembly, Class, DbLoginName, SysStartTime, SysEndTime
FROM [History].[ExecutionStrategyModels]
WHERE SysStartTime < SysEndTime  -- exclude zero-duration INSERT artifacts
ORDER BY SysStartTime DESC
-- Empty result = no models have ever been modified or deleted
```

### 8.3 Cross-reference: models currently in use by configurations
```sql
SELECT esm.ModelID, esm.Name, esm.Assembly, esm.Class,
       COUNT(DISTINCT esmc.ConfigurationID) AS ConfigurationCount
FROM [Hedge].[ExecutionStrategyModels] esm
LEFT JOIN [Hedge].[ExecutionStrategyModelConfigurations] esmc ON esm.ModelID = esmc.ModelID
GROUP BY esm.ModelID, esm.Name, esm.Assembly, esm.Class
ORDER BY esm.ModelID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9/10, Relationships: 8.5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ExecutionStrategyModels | Type: Table | Source: etoro/etoro/History/Tables/History.ExecutionStrategyModels.sql*
