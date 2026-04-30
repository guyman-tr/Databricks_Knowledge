# Hedge.GetBoundariesConfiguration

> Returns the full band-based hedge rebalancing configuration - trigger thresholds and desired target exposure bands per strategy and instrument. Currently returns 0 rows as the BoundariesConfiguration table has never been populated in this environment.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns all rows from Hedge.BoundariesConfiguration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the dedicated bulk reader for `Hedge.BoundariesConfiguration` - the configuration table for a band-based hedge rebalancing strategy. It returns six columns that together define the trigger dead-band and the desired rebalancing target for each (StrategyID, InstrumentID) combination.

The band-based rebalancing model works as follows:
- While hedge exposure stays within the **trigger band** (`LowerThresholdUSD` to `UpperThresholdUSD`), no rebalancing action is taken.
- When exposure drifts below `LowerThresholdUSD`, the hedge engine rebalances toward `LowerBoundaryDesiredExposureUSD`.
- When exposure drifts above `UpperThresholdUSD`, the hedge engine rebalances toward `UpperBoundaryDesiredExposureUSD`.

This procedure loads the full configuration matrix for all configured strategy/instrument pairs in a single read, supporting hedge engine startup or refresh.

**Current state**: `Hedge.BoundariesConfiguration` has 0 rows - this boundary-based strategy has never been deployed in this environment. The procedure will return an empty result set until the table is populated.

---

## 2. Business Logic

### 2.1 Full Boundary Configuration Bulk Load

**What**: Returns all rows from `Hedge.BoundariesConfiguration` without filtering - the complete set of strategy/instrument boundary rules.

**Columns/Parameters Involved**: All 6 returned columns from `Hedge.BoundariesConfiguration`

**Rules**:
- No WHERE clause - entire boundary configuration table is returned
- All values are USD-denominated (`int` type)
- StrategyID has no FK constraint - application manages strategy ID lifecycle
- WITH (NOLOCK) applied for read performance
- Currently returns 0 rows - table is unpopulated in this environment

### 2.2 Band Rebalancing Logic (When Populated)

**What**: Each row defines when to trigger rebalancing and what exposure to target.

**Diagram**:
```
Current exposure comparison:
  < LowerThresholdUSD   -> REBALANCE UP to LowerBoundaryDesiredExposureUSD
  within [Lower, Upper] -> NO ACTION
  > UpperThresholdUSD   -> REBALANCE DOWN to UpperBoundaryDesiredExposureUSD
```

**Rules**:
- Trigger thresholds define the acceptable drift range before action is required
- Desired exposure values define where to rebalance to (not just direction but magnitude)
- Multiple strategies can have different boundary rules for the same instrument

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Returns all rows from `Hedge.BoundariesConfiguration`. Currently returns 0 rows as the table has never been populated in this environment. |

**Output Columns**:

| Column | Source | Description |
|--------|--------|-------------|
| InstrumentID | Hedge.BoundariesConfiguration | The trading instrument this boundary rule governs. Implicit reference to Trade.Instrument (no FK constraint). |
| StrategyID | Hedge.BoundariesConfiguration | Identifies the hedge strategy this boundary rule applies to. Application-managed (no FK constraint). Multiple strategies can have different rules for the same instrument. |
| LowerThresholdUSD | Hedge.BoundariesConfiguration | Lower bound of the rebalancing dead-band in USD. Exposure below this value triggers rebalancing toward LowerBoundaryDesiredExposureUSD. DEFAULT 0. |
| UpperThresholdUSD | Hedge.BoundariesConfiguration | Upper bound of the rebalancing dead-band in USD. Exposure above this value triggers rebalancing toward UpperBoundaryDesiredExposureUSD. DEFAULT 0. |
| LowerBoundaryDesiredExposureUSD | Hedge.BoundariesConfiguration | Target USD exposure to rebalance toward when exposure is too low (below LowerThresholdUSD). Defines the desired floor for this strategy/instrument pair. |
| UpperBoundaryDesiredExposureUSD | Hedge.BoundariesConfiguration | Target USD exposure to rebalance toward when exposure is too high (above UpperThresholdUSD). Defines the desired ceiling for this strategy/instrument pair. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.BoundariesConfiguration | Direct read | Returns 6 columns for all strategy/instrument boundary rules; no filter |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by the hedge engine to load boundary configuration for band-based rebalancing strategies.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetBoundariesConfiguration (procedure)
└── Hedge.BoundariesConfiguration (table) - SELECT source (currently 0 rows)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.BoundariesConfiguration | Table | SELECT 6 columns (InstrumentID, StrategyID, thresholds, desired boundaries) - all rows, no filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No filter | Design | Returns ALL rows - full boundary configuration load. Currently returns 0 rows (table unpopulated). |
| WITH (NOLOCK) | Isolation | Applied to Hedge.BoundariesConfiguration - dirty reads accepted for configuration data |
| Empty table note | State | Hedge.BoundariesConfiguration has 0 rows in current environment - this procedure always returns empty result set until populated |

---

## 8. Sample Queries

### 8.1 View current boundary configuration state

```sql
SELECT InstrumentID, StrategyID,
       LowerThresholdUSD, UpperThresholdUSD,
       LowerBoundaryDesiredExposureUSD, UpperBoundaryDesiredExposureUSD
FROM Hedge.BoundariesConfiguration WITH (NOLOCK)
ORDER BY StrategyID, InstrumentID
```

### 8.2 Check if boundaries are configured for a specific instrument

```sql
SELECT InstrumentID, StrategyID,
       LowerThresholdUSD, UpperThresholdUSD,
       LowerBoundaryDesiredExposureUSD, UpperBoundaryDesiredExposureUSD
FROM Hedge.BoundariesConfiguration WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY StrategyID
```

### 8.3 Find strategies with tight trigger bands (low drift tolerance)

```sql
SELECT StrategyID,
       COUNT(*) AS InstrumentCount,
       AVG(UpperThresholdUSD - LowerThresholdUSD) AS AvgBandWidthUSD
FROM Hedge.BoundariesConfiguration WITH (NOLOCK)
GROUP BY StrategyID
ORDER BY AvgBandWidthUSD ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetBoundariesConfiguration | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetBoundariesConfiguration.sql*
