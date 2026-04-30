# Hedge.BoundariesConfiguration

> Per-strategy, per-instrument boundary configuration table defining USD-denominated exposure thresholds and desired target exposure bands for a band-based hedge rebalancing strategy.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (StrategyID, InstrumentID) - composite PK CLUSTERED |
| **Partition** | No (on [DICTIONARY] filegroup, FILLFACTOR=100) |
| **Indexes** | 1 (composite PK only) |

---

## 1. Business Meaning

`Hedge.BoundariesConfiguration` defines the trigger thresholds and target exposure bands for a band-based hedge rebalancing strategy. For each combination of strategy and instrument, it specifies:

- A **trigger band** (`LowerThresholdUSD` / `UpperThresholdUSD`): the USD exposure range within which no rebalancing action is taken. When hedge exposure drifts outside this band, a rebalancing is triggered.
- A **target band** (`LowerBoundaryDesiredExposureUSD` / `UpperBoundaryDesiredExposureUSD`): the desired exposure range the engine targets when rebalancing is triggered.

The `StrategyID` column (no FK constraint) ties each row to a named hedge strategy, allowing different strategies to have different boundary rules for the same instrument - for example, an aggressive strategy might have tight boundaries while a passive strategy allows wider drift.

**Current state**: The table has 0 rows in both current and history tables - this rebalancing strategy has never been configured in this environment. The design and its dedicated reader procedure (`Hedge.GetBoundariesConfiguration`) remain intact in the schema.

---

## 2. Business Logic

### 2.1 Band-Based Rebalancing Trigger

**What**: Defines the dead-band within which no hedge action is required, plus the target band to rebalance toward when exposure drifts outside the dead-band.

**Columns/Parameters Involved**: `StrategyID`, `InstrumentID`, `LowerThresholdUSD`, `UpperThresholdUSD`, `LowerBoundaryDesiredExposureUSD`, `UpperBoundaryDesiredExposureUSD`

**Rules**:
- If current exposure is within [LowerThresholdUSD, UpperThresholdUSD]: no rebalancing needed
- If current exposure < LowerThresholdUSD: exposure too low, rebalance toward LowerBoundaryDesiredExposureUSD target
- If current exposure > UpperThresholdUSD: exposure too high, rebalance toward UpperBoundaryDesiredExposureUSD target
- All values in USD denomination
- All DEFAULT values are 0, meaning unconfigured rows would have no effective boundaries
- StrategyID has no FK constraint - strategy IDs are application-managed

**Diagram**:
```
Exposure:  [--- too low ---][LowerThreshold...UpperThreshold][--- too high ---]
Action:    Rebalance up    |    No action required          | Rebalance down
Target:    LowerBoundary   |                                | UpperBoundary
```

---

## 3. Data Overview

| StrategyID | InstrumentID | LowerThreshold | UpperThreshold | LowerBoundary | UpperBoundary | Meaning |
|---|---|---|---|---|---|---|
| (no rows) | (no rows) | - | - | - | - | Table is currently empty - no boundary configurations are active |

Both current table and history table have 0 rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StrategyID | int | NO | - | CODE-BACKED | Identifies the hedge strategy this boundary rule applies to. Part of the composite PK. No FK constraint - strategy IDs are managed by the application. One strategy can have different boundary rules per instrument. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Identifies the instrument this boundary rule applies to. Part of the composite PK. No FK constraint in DDL (implicit reference to Trade.Instrument). |
| 3 | LowerThresholdUSD | int | NO | 0 | VERIFIED | Lower bound of the dead-band (in USD). When current exposure falls below this value, rebalancing is triggered toward LowerBoundaryDesiredExposureUSD. DEFAULT 0. |
| 4 | UpperThresholdUSD | int | NO | 0 | VERIFIED | Upper bound of the dead-band (in USD). When current exposure exceeds this value, rebalancing is triggered toward UpperBoundaryDesiredExposureUSD. DEFAULT 0. |
| 5 | LowerBoundaryDesiredExposureUSD | int | NO | 0 | VERIFIED | Target exposure (in USD) to rebalance toward when exposure is too low (below LowerThresholdUSD). Defines the desired floor for this strategy/instrument pair. DEFAULT 0. |
| 6 | UpperBoundaryDesiredExposureUSD | int | NO | 0 | VERIFIED | Target exposure (in USD) to rebalance toward when exposure is too high (above UpperThresholdUSD). Defines the desired ceiling for this strategy/instrument pair. DEFAULT 0. |
| 7 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 8 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 9 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 10 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.BoundariesConfiguration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no FK constraints. StrategyID and InstrumentID are application-managed without explicit FK enforcement.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetBoundariesConfiguration | (table ref) | READER | SELECTs all columns; returns boundary rules to the hedge engine |
| History.BoundariesConfiguration | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.BoundariesConfiguration (table)
  (no FK dependencies - leaf table)
```

---

### 6.1 Objects This Depends On

No FK dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetBoundariesConfiguration | Stored Procedure | READER - returns full boundary configuration to hedge engine |
| History.BoundariesConfiguration | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_boundariesConfiguration | CLUSTERED PK | StrategyID ASC, InstrumentID ASC | - | - | Active (FILLFACTOR=100) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_boundariesConfiguration | PRIMARY KEY | (StrategyID, InstrumentID) - one boundary rule per strategy/instrument pair |
| DEFAULT LowerThresholdUSD | DEFAULT | LowerThresholdUSD = 0 |
| DEFAULT UpperThresholdUSD | DEFAULT | UpperThresholdUSD = 0 |
| DEFAULT LowerBoundaryDesiredExposureUSD | DEFAULT | LowerBoundaryDesiredExposureUSD = 0 |
| DEFAULT UpperBoundaryDesiredExposureUSD | DEFAULT | UpperBoundaryDesiredExposureUSD = 0 |
| DF_BoundariesConfiguration_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_BoundariesConfiguration_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.BoundariesConfiguration |

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| Tr_T_BoundariesConfiguration_INSERT | INSERT | No-op self-UPDATE (UPDATE A SET A.StrategyID=A.StrategyID, A.InstrumentID=A.InstrumentID) to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 View all boundary configurations

```sql
SELECT
    bc.StrategyID,
    bc.InstrumentID,
    bc.LowerThresholdUSD,
    bc.UpperThresholdUSD,
    bc.LowerBoundaryDesiredExposureUSD,
    bc.UpperBoundaryDesiredExposureUSD
FROM Hedge.BoundariesConfiguration bc WITH (NOLOCK)
ORDER BY bc.StrategyID, bc.InstrumentID
```

### 8.2 Find instruments where current exposure falls outside configured bounds

```sql
-- Example: join to a hypothetical current exposure source
SELECT
    bc.InstrumentID,
    bc.StrategyID,
    bc.LowerThresholdUSD,
    bc.UpperThresholdUSD
FROM Hedge.BoundariesConfiguration bc WITH (NOLOCK)
-- WHERE exposure < bc.LowerThresholdUSD OR exposure > bc.UpperThresholdUSD
ORDER BY bc.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.BoundariesConfiguration | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.BoundariesConfiguration.sql*
