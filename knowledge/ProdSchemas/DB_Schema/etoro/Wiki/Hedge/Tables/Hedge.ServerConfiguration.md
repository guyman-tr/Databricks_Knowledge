# Hedge.ServerConfiguration

> Per-hedge-server operational configuration - one row per server storing execution mode, exposure strategy, major-currency conversion flag, and validated references to execution/exposure strategy Dictionary tables. Currently 1 row (ServerID=1, all defaults).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | ServerID - single column CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK only) |

---

## 1. Business Meaning

Hedge.ServerConfiguration stores the operational settings that control how a given hedge server instance behaves: how it executes hedge orders, how it calculates exposure, and whether minor currency pairs should be converted to major equivalents.

One row per hedge server (ServerID is the PK and implicit FK to Trade.HedgeServer). The configuration governs four independent behavioral dimensions:

1. **AutoExecutionMode**: Whether hedge orders are automatically submitted to the LP or held for manual approval
2. **ExposureStrategy**: How the server aggregates and calculates its exposure (no FK - numeric enum)
3. **ExposureMode**: The exposure calculation regime (FK validated: 0=Normal, 1=Major, 2=Portfolio, 3=SpotExposureMode)
4. **ExecutionStrategy**: The execution algorithm used for hedge orders (FK validated: 0=Normal, 1=Smart)
5. **ConvertToMajors**: Whether minor cross-currency pairs (e.g., EUR/JPY) should be decomposed into their major-pair components (EUR/USD, USD/JPY) for hedging

The table is written via an upsert SP (`UpdateServerConfiguration`): UPDATE if ServerID exists, INSERT with all-zero defaults if not. All parameters are optional (null = keep existing value) enabling individual field updates without touching other settings.

`GetServerConfiguration` is the read path but notably omits `ExecutionStrategy` from its SELECT - this column was added to the table after the SP was written and the SP has not been updated.

Current state: 1 row, ServerID=1, all values=0 (Normal/off defaults).

---

## 2. Business Logic

### 2.1 Upsert with Partial Update (UpdateServerConfiguration)

**What**: `UpdateServerConfiguration` does IF EXISTS -> UPDATE, ELSE -> INSERT. All parameters default to NULL, meaning "keep existing value."

**Columns/Parameters Involved**: All columns

**Rules**:
- Each parameter uses `CASE WHEN @Param IS NULL THEN ExistingValue ELSE @Param END` - NULL = no change, non-NULL = update
- INSERT defaults: all numeric fields = 0, ConvertToMajors = 0 (false) when NULL passed on insert
- Both UPDATE and INSERT paths handle all 5 configurable columns
- Note: ServerID is passed by the caller - there is no auto-assign

### 2.2 AutoExecutionMode (No FK - Implicit Enum)

**What**: Controls whether the hedge server automatically submits orders to the LP or requires manual intervention.

**Rules** (inferred from naming convention, no Dictionary FK):
- 0 (default): Automatic execution - hedge orders are sent to LP without manual approval
- Other values: Manual or semi-manual modes - orders may be queued for dealing desk review
- The specific non-zero values are not defined in any Dictionary table visible in the schema

### 2.3 ExposureMode (FK to Dictionary.HedgeServerExposureMode)

| ExposureModeID | Description | Meaning |
|---|---|---|
| 0 | Normal | Standard per-instrument net exposure calculation |
| 1 | Major | Exposure calculated using major currency pairs only (complements ConvertToMajors) |
| 2 | Portfolio | Exposure calculated at portfolio level, aggregating across instruments |
| 3 | SpotExposureMode | Spot-rate based exposure calculation (for FX spot instruments) |

### 2.4 ExecutionStrategy (FK to Dictionary.HedgeServerExecutionStrategy)

| ExecutionStartegyID | ExecutionStrategyName | Meaning |
|---|---|---|
| 0 | Normal | Standard order submission to LP |
| 1 | Smart | Smart execution - may use algorithms like TWAP, iceberg, or multi-LP routing |

Note: `GetServerConfiguration` SP does NOT return ExecutionStrategy (likely a schema evolution gap - column added after SP was written).

### 2.5 ConvertToMajors Flag

**What**: Controls whether cross-currency minor pairs are decomposed into their major-pair equivalents for hedging.

**Rules**:
- false (0, default): Each instrument hedged as-is, using its own InstrumentID
- true (1): Minor pairs (e.g., EUR/JPY) split into constituent major pairs (EUR/USD + USD/JPY) before hedging
- When true, interacts with PortfolioConversionConfigurations which maps synthetic/non-expiry instruments to their real underlying instruments

### 2.6 ExposureStrategy (No FK - Implicit Enum)

**What**: A numeric enum without FK constraint controlling the exposure aggregation algorithm.

**Rules** (inferred from naming):
- 0 (default): Standard strategy - exposure calculated per standard rules
- Specific non-zero strategies not documented in any visible Dictionary table

---

## 3. Data Overview

1 row in production:

| ServerID | AutoExecutionMode | ExposureStrategy | ConvertToMajors | ExposureMode | ExecutionStrategy |
|---|---|---|---|---|---|
| 1 | 0 | 0 | false | 0 (Normal) | 0 (Normal) |

All values are at their defaults (0/false). This represents a single hedge server configured in full-normal/automatic mode.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ServerID | int | NO | - | VERIFIED | PK. Implicit FK to Trade.HedgeServer.HedgeServerID. Identifies which hedge server this configuration row applies to. One row per hedge server. |
| 2 | AutoExecutionMode | int | NO | - | CODE-BACKED | Execution automation level. 0=auto-execute hedge orders without manual approval (current value). No Dictionary FK - values are implicit enum in application code. Controls whether the hedge server submits orders to the LP immediately or holds them for dealing desk review. |
| 3 | ExposureStrategy | int | NO | - | CODE-BACKED | Exposure aggregation strategy selector. No Dictionary FK - numeric enum in application code. 0=standard (current). Controls the algorithm used to aggregate and calculate exposure across positions. |
| 4 | ConvertToMajors | bit | NO | - | VERIFIED | Whether to convert non-major cross-currency pairs into their major-pair components before hedging. false=hedge instruments as-is (current). true=decompose minor pairs (e.g., EUR/JPY -> EUR/USD + USD/JPY). Works with PortfolioConversionConfigurations. |
| 5 | ExposureMode | int | NO | 0 | VERIFIED | Exposure calculation mode. FK to Dictionary.HedgeServerExposureMode (WITH CHECK). 0=Normal, 1=Major, 2=Portfolio, 3=SpotExposureMode. Current value: 0 (Normal). Default defined in DDL as 0. |
| 6 | ExecutionStrategy | int | NO | 0 | VERIFIED | Execution algorithm selector. FK to Dictionary.HedgeServerExecutionStrategy (WITH CHECK). 0=Normal, 1=Smart. Default=0. NOTE: Not returned by `GetServerConfiguration` SP - column added after SP was written (schema evolution gap). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ServerID | Trade.HedgeServer | Implicit | The hedge server this configuration applies to |
| ExecutionStrategy | Dictionary.HedgeServerExecutionStrategy | FK (explicit, WITH CHECK) | Constrains to valid execution strategies (0=Normal, 1=Smart) |
| ExposureMode | Dictionary.HedgeServerExposureMode | FK (explicit, WITH CHECK) | Constrains to valid exposure modes (0-3) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetServerConfiguration | ServerID | READER | Returns AutoExecutionMode, ExposureStrategy, ConvertToMajors, ExposureMode for a given ServerID (excludes ExecutionStrategy) |
| Hedge.UpdateServerConfiguration | ServerID | WRITER (upsert) | Creates or updates configuration; all fields individually optional |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ServerConfiguration (table)
+-- Trade.HedgeServer (table) [implicit FK target]
+-- Dictionary.HedgeServerExecutionStrategy (table) [FK target]
|     Values: 0=Normal, 1=Smart
+-- Dictionary.HedgeServerExposureMode (table) [FK target]
      Values: 0=Normal, 1=Major, 2=Portfolio, 3=SpotExposureMode
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | Implicit FK target for ServerID |
| Dictionary.HedgeServerExecutionStrategy | Table | FK target for ExecutionStrategy |
| Dictionary.HedgeServerExposureMode | Table | FK target for ExposureMode |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetServerConfiguration | Stored Procedure | READER - returns 4 of 5 configurable columns by ServerID |
| Hedge.UpdateServerConfiguration | Stored Procedure | WRITER - upsert with partial-update support |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ServerConfiguration | CLUSTERED PK | ServerID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ServerConfiguration | PRIMARY KEY | One configuration row per hedge server |
| HSC_HSEM_HSExecutionStrategy | FOREIGN KEY (WITH CHECK) | ExecutionStrategy must be a valid HedgeServerExecutionStrategy ID |
| HSC_HSEM_HSExposureMode | FOREIGN KEY (WITH CHECK) | ExposureMode must be a valid HedgeServerExposureMode ID |

Note: Constraint name `HSC_HSEM_HSExecutionStrategy` contains `HSEM` (HedgeServerExposureMode?) but references ExecutionStrategy. This appears to be a naming inconsistency in the constraint definition.

### 7.3 Schema Evolution Gap

`GetServerConfiguration` was written before `ExecutionStrategy` was added to the table. The SP selects AutoExecutionMode, ExposureStrategy, ConvertToMajors, ExposureMode but NOT ExecutionStrategy. Applications that need ExecutionStrategy must either call a different path or the SP needs to be updated.

---

## 8. Sample Queries

### 8.1 Current configuration for all servers with descriptive labels
```sql
SELECT  sc.ServerID,
        sc.AutoExecutionMode,
        sc.ExposureStrategy,
        CASE sc.ConvertToMajors WHEN 1 THEN 'Yes' ELSE 'No' END AS ConvertToMajors,
        em.Description AS ExposureMode,
        es.ExecutionStrategyName AS ExecutionStrategy
FROM    [Hedge].[ServerConfiguration] sc WITH (NOLOCK)
LEFT JOIN [Dictionary].[HedgeServerExposureMode] em WITH (NOLOCK)
        ON sc.ExposureMode = em.ExposureModeID
LEFT JOIN [Dictionary].[HedgeServerExecutionStrategy] es WITH (NOLOCK)
        ON sc.ExecutionStrategy = es.ExecutionStartegyID
ORDER BY sc.ServerID;
```

### 8.2 Check for the schema evolution gap (ExecutionStrategy not in GetServerConfiguration)
```sql
-- Use direct table query when ExecutionStrategy is needed
SELECT  sc.ServerID, sc.ExecutionStrategy, es.ExecutionStrategyName
FROM    [Hedge].[ServerConfiguration] sc WITH (NOLOCK)
INNER JOIN [Dictionary].[HedgeServerExecutionStrategy] es WITH (NOLOCK)
        ON sc.ExecutionStrategy = es.ExecutionStartegyID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for Hedge.ServerConfiguration. Confluence search returned no relevant results.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ServerConfiguration | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ServerConfiguration.sql*
