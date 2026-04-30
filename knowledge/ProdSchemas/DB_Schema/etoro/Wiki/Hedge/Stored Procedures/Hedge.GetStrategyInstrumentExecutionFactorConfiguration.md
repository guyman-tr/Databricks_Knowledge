# Hedge.GetStrategyInstrumentExecutionFactorConfiguration

> Returns the active per-instrument per-strategy execution factor overrides, allowing the hedge engine to apply instrument-specific and strategy-specific order sizing multipliers that override the server-level execution factor.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns all active overrides from Hedge.ExecutionFactorConfiguration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetStrategyInstrumentExecutionFactorConfiguration` loads the granular execution factor override table. While `Hedge.GetStrategyExecutionFactorConfiguration` returns a server-level execution factor (one value per hedge server), this procedure returns instrument-and-strategy-level overrides that provide more precise control.

The `ExecutionFactor` here is the same concept - a multiplier on the computed exposure delta before order sizing - but applied at the (StrategyID, InstrumentID) granularity. This allows the hedge engine to use a different execution aggressiveness for, say, EUR/USD under the copy-trading strategy compared to EUR/USD under the manual-trading strategy, or to use a different factor for a volatile instrument compared to a stable one.

The `IsActive=1` filter ensures only currently active overrides are returned. Deactivated overrides (IsActive=0) remain in the table for historical reference but are not applied in execution.

Data flows as follows: on startup, the hedge engine calls this procedure to load instrument-strategy overrides. When computing hedge order size for a (StrategyID, InstrumentID) pair, the engine first checks this override table. If a matching active row exists, its ExecutionFactor takes precedence over the server-level factor from GetStrategyExecutionFactorConfiguration. If no override exists, the server-level default applies.

**Current state**: The underlying `Hedge.ExecutionFactorConfiguration` table currently has 0 rows. The override layer is architecturally supported but not actively used.

---

## 2. Business Logic

### 2.1 Active Override Load with IsActive Filter

**What**: Returns all rows from Hedge.ExecutionFactorConfiguration where IsActive=1. Full result set - no per-strategy or per-instrument filtering.

**Columns/Parameters Involved**: `IsActive`, `InstrumentID`, `StrategyID`, `ExecutionFactor`

**Rules**:
- WHERE IsActive=1: excludes deactivated overrides; only active rules affect order sizing
- No additional filters: all active (StrategyID, InstrumentID) combinations returned
- WITH (NOLOCK): avoids blocking during the startup configuration load
- (StrategyID, InstrumentID) is the effective composite key in the result set

**Diagram**:
```
Hedge order sizing precedence (per StrategyID + InstrumentID):
  1. Check GetStrategyInstrumentExecutionFactorConfiguration() cache:
     - Found (StrategyID=2, InstrumentID=1, ExecutionFactor=0.3, IsActive=1)?
       -> Order size = exposure_delta * 0.3 (strategy-instrument override)
     - Not found?
  2. Fall back to GetStrategyExecutionFactorConfiguration():
       -> Order size = exposure_delta * server_level_ExecutionFactor (server default)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

*No input parameters.*

**Output columns** (from Hedge.ExecutionFactorConfiguration WHERE IsActive=1):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | The financial instrument this override applies to. Part of the (StrategyID, InstrumentID) composite key. FK to Trade.Instrument. |
| 2 | StrategyID | int | NO | - | VERIFIED | The trading strategy context for this override. Part of the (StrategyID, InstrumentID) composite key. Allows different execution factors for the same instrument under different strategies (e.g., copy trading vs manual trading). |
| 3 | ExecutionFactor | decimal | YES | - | VERIFIED | Instrument-and-strategy-specific execution multiplier. Overrides the server-level factor from GetStrategyExecutionFactorConfiguration for this (StrategyID, InstrumentID) combination. 1.0=full hedge, <1.0=partial hedge per cycle, >1.0=aggressive/over-hedge. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.ExecutionFactorConfiguration | SELECT | Source of instrument-strategy execution factor overrides; filtered to IsActive=1 only. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called on startup to load the instrument-strategy execution factor override cache. Higher precision than the server-level factor from GetStrategyExecutionFactorConfiguration. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetStrategyInstrumentExecutionFactorConfiguration (procedure)
└── Hedge.ExecutionFactorConfiguration (table)
      - PK: (StrategyID, InstrumentID)
      - IsActive filter: only active overrides returned
      - Currently: 0 rows (no active overrides configured)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionFactorConfiguration | Table | SELECTed with NOLOCK WHERE IsActive=1 - source of instrument-strategy execution factor overrides |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - loads at startup for fine-grained execution factor overrides per instrument and strategy |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Hedge.ExecutionFactorConfiguration has a PK on (StrategyID, InstrumentID). With IsActive=1 filter, a non-clustered index on IsActive would benefit this query if many deactivated rows exist. Currently 0 rows - no performance concern.

### 7.2 Constraints

N/A for Stored Procedure. This is the most granular of three execution factor configuration procedures: GetStrategyExecutionFactorConfiguration (server level) < GetStrategyInstrumentExecutionFactorConfiguration (instrument + strategy level). The hedge engine applies them in reverse granularity order: most specific override wins. The IsActive=1 filter allows soft-delete semantics: deactivated overrides are preserved for audit without affecting execution.

---

## 8. Sample Queries

### 8.1 Load all active execution factor overrides
```sql
EXEC [Hedge].[GetStrategyInstrumentExecutionFactorConfiguration];
```

### 8.2 Direct query including deactivated overrides for audit
```sql
SELECT  InstrumentID,
        StrategyID,
        ExecutionFactor,
        IsActive
FROM    [Hedge].[ExecutionFactorConfiguration] WITH (NOLOCK)
ORDER BY StrategyID, InstrumentID;
```

### 8.3 Compare server-level vs instrument-level execution factors
```sql
-- Server level (from GetStrategyExecutionFactorConfiguration):
SELECT  HedgeServerID, ExecutionFactor AS ServerFactor
FROM    [Trade].[HedgeServer] WITH (NOLOCK);

-- Instrument level (from this procedure):
SELECT  InstrumentID, StrategyID, ExecutionFactor AS InstrumentFactor
FROM    [Hedge].[ExecutionFactorConfiguration] WITH (NOLOCK)
WHERE   IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetStrategyInstrumentExecutionFactorConfiguration | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetStrategyInstrumentExecutionFactorConfiguration.sql*
