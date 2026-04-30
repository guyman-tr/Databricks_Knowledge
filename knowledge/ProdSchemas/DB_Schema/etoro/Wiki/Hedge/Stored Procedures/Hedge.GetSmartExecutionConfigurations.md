# Hedge.GetSmartExecutionConfigurations

> Returns the smart execution escalation schedule - the sequence of execution attempts with increasing delay and slippage tolerance - used by the hedge engine to progressively fill large hedge orders over time.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full escalation schedule for all models |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetSmartExecutionConfigurations` loads the smart execution escalation schedule for hedge order placement. "Smart execution" refers to the hedge engine's strategy for filling large hedge orders without excessive market impact: instead of placing one large order immediately, it splits the fill over multiple attempts with increasing time delays and slippage tolerance.

Each row in the result represents one step in the escalation sequence for a specific execution model. The `Priority` column determines the order of attempts (lower priority = earlier attempt). `ExecutionDelaySeconds` defines how long to wait before this attempt. `SlippageInPercentage` defines how much price deviation is acceptable at this step - early attempts are tight (low slippage), later attempts are more relaxed (higher slippage tolerance), ensuring the order eventually fills even in volatile markets.

The `IsBuy` column allows different escalation parameters for buy orders vs sell orders, as execution dynamics differ by direction (buying into an ask may behave differently than selling into a bid in certain market conditions).

Data flows as follows: on startup, the hedge engine calls this procedure to load the smart execution schedule into its order management system. When the ExposureStrategy mode selects "smart execution" (controlled by the server's ExposureStrategy configuration from `Hedge.GetServerConfiguration`), the order management module uses this schedule to time and parameterize its sequential fill attempts.

---

## 2. Business Logic

### 2.1 Full Schedule Load for All Models

**What**: Returns the complete escalation schedule for all execution models without filtering. The hedge engine loads all models and selects the applicable one based on the active ExposureStrategy.

**Columns/Parameters Involved**: `ModelID`, `Priority`, `ExecutionDelaySeconds`, `IsBuy`, `SlippageInPercentage`

**Rules**:
- No WHERE clause - all rows returned across all ModelIDs and both IsBuy values
- SET TRAN ISOLATION LEVEL READ UNCOMMITTED: avoids blocking during the schedule load
- (ModelID, IsBuy) is the PK - one escalation schedule per model per direction
- Priority within each (ModelID, IsBuy) group defines the execution sequence
- The hedge engine selects the relevant ModelID based on its configured ExposureStrategy

**Diagram**:
```
Smart Execution for a large buy order (ModelID=1, IsBuy=1):
  Attempt 1 (Priority=1): Wait 0s, SlippageInPercentage=0.001  -> tight limit, quick attempt
  Attempt 2 (Priority=2): Wait 30s, SlippageInPercentage=0.003 -> slight relaxation
  Attempt 3 (Priority=3): Wait 60s, SlippageInPercentage=0.01  -> wider, almost certain fill
  Attempt 4 (Priority=4): Wait 120s, SlippageInPercentage=0.05 -> market order equivalent

  If attempt N fills -> done
  If attempt N times out -> proceed to attempt N+1 with wider parameters
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

*No input parameters.*

**Output columns** (from Hedge.ExecutionStrategyModelConfigurations):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ModelID | int | NO | - | VERIFIED | The smart execution model identifier. Groups all Priority rows into a named escalation sequence. The hedge engine selects the ModelID matching its configured ExposureStrategy. |
| 2 | Priority | int | NO | - | VERIFIED | Execution sequence number within this (ModelID, IsBuy) schedule. Lower number = attempted first. Defines the order: attempt 1 before attempt 2, etc. The engine moves to the next priority after the previous attempt times out or is rejected. |
| 3 | ExecutionDelaySeconds | int | YES | - | VERIFIED | Seconds to wait before submitting this escalation attempt. 0 = immediate submission. Increasing delays allow time for the market to absorb previous attempts or for price to return to a favorable level. |
| 4 | IsBuy | bit | NO | - | VERIFIED | Direction of the hedge order this row applies to. 1=Buy attempts, 0=Sell attempts. Separate escalation parameters for each direction allow asymmetric execution strategies. |
| 5 | SlippageInPercentage | decimal | YES | - | VERIFIED | Maximum acceptable price deviation as a percentage for this attempt. Early attempts: tight (e.g., 0.001 = 0.1%). Later attempts: relaxed (e.g., 0.05 = 5%). The escalation ensures the order eventually fills at the cost of increasing price tolerance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.ExecutionStrategyModelConfigurations | SELECT | Source of the smart execution escalation schedule for all models and directions. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called on startup when smart execution strategy is active, to load the order fill escalation schedule. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetSmartExecutionConfigurations (procedure)
└── Hedge.ExecutionStrategyModelConfigurations (table)
      - PK: (ModelID, IsBuy)
      - Smart execution escalation schedule
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionStrategyModelConfigurations | Table | SELECTed at READ UNCOMMITTED - source of all smart execution model escalation steps |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - called at startup to configure the smart execution order fill escalation engine |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Hedge.ExecutionStrategyModelConfigurations has a PK on (ModelID, IsBuy). Full-table scan returns all rows - appropriate for a startup configuration load where all models are needed.

### 7.2 Constraints

N/A for Stored Procedure. The smart execution schedule interacts with `Hedge.GetServerConfiguration`: when `ExposureStrategy` from GetServerConfiguration selects a smart execution mode, the hedge engine uses the ModelID corresponding to that strategy from the schedule returned by this procedure. SET TRAN ISOLATION LEVEL READ UNCOMMITTED is set session-wide.

---

## 8. Sample Queries

### 8.1 Load the full smart execution schedule
```sql
EXEC [Hedge].[GetSmartExecutionConfigurations];
```

### 8.2 View the escalation sequence for a specific model and direction
```sql
SELECT  ModelID,
        Priority,
        ExecutionDelaySeconds,
        IsBuy,
        SlippageInPercentage
FROM    [Hedge].[ExecutionStrategyModelConfigurations] WITH (NOLOCK)
WHERE   ModelID = 1
ORDER BY IsBuy DESC, Priority ASC;
```

### 8.3 Compare buy vs sell escalation for the same model
```sql
SELECT  Priority,
        IsBuy,
        ExecutionDelaySeconds,
        SlippageInPercentage,
        SUM(ExecutionDelaySeconds) OVER (
            PARTITION BY IsBuy ORDER BY Priority) AS CumulativeDelaySeconds
FROM    [Hedge].[ExecutionStrategyModelConfigurations] WITH (NOLOCK)
WHERE   ModelID = 1
ORDER BY IsBuy, Priority;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetSmartExecutionConfigurations | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetSmartExecutionConfigurations.sql*
