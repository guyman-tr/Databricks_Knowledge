# Hedge.ExecutionStrategyModelConfigurations

> Per-direction execution parameters for Smart Execution strategy models, defining the priority ordering, attempt delay, and slippage tolerance for each limit order strategy separately for buy and sell orders.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (ModelID, IsBuy) - composite PK CLUSTERED |
| **Partition** | No (on [DICTIONARY] filegroup) |
| **Indexes** | 1 (composite PK only) |

---

## 1. Business Meaning

`Hedge.ExecutionStrategyModelConfigurations` configures the Smart Execution engine's strategy escalation schedule. For each execution strategy model (registered in `Hedge.ExecutionStrategyModels`), it stores two rows - one for buy orders and one for sell orders - defining when and how aggressively each strategy should be attempted.

This table exists because Smart Execution uses an asymmetric escalation approach: for **buy orders**, the engine tries the most seller-favorable price first (bid) and escalates toward less favorable prices; for **sell orders**, it starts at the most buyer-favorable price (ask) and escalates toward bid. The direction-specific rows allow this asymmetric ordering to be configured in data rather than code.

Data flow: `Hedge.GetSmartExecutionConfigurations` reads all rows from this table on startup. The Smart Execution engine caches the schedule and, when executing an order, builds a sequence of strategies ordered by `Priority` for the relevant `IsBuy` direction. Each strategy is attempted after its `ExecutionDelaySeconds` has elapsed since the previous attempt, with a slippage tolerance of `SlippageInPercentage`.

---

## 2. Business Logic

### 2.1 Smart Execution Escalation Schedule

**What**: The data encodes a direction-aware price escalation ladder: attempts start at the most price-favorable limit and progressively relax until a fill is achieved or the market order fallback triggers.

**Columns/Parameters Involved**: `ModelID`, `IsBuy`, `Priority`, `ExecutionDelaySeconds`

**Rules**:
- Lower Priority number = tried first (Priority 1 is the first attempt)
- `ExecutionDelaySeconds` is the wait time after the PREVIOUS strategy before trying this one (not absolute time from order start)
- For **buy orders (IsBuy=1)**: LimitBid (priority 1, 0s) -> LimitMid (priority 2, 3s) -> LimitAsk (priority 3, 6s) -> Market (priority 4, 3s)
- For **sell orders (IsBuy=0)**: LimitAsk (priority 1, 0s) -> LimitMid (priority 2, 3s) -> LimitBid (priority 3, 6s) -> Market (priority 4, 3s)
- The asymmetry reflects best-price logic: buyers want low prices (start at bid), sellers want high prices (start at ask)
- MarketOrder is always last (Priority 4) for both directions - it is the guaranteed-fill fallback

**Diagram**:
```
BUY ORDER execution timeline:
t=0s  -> Try LimitBid  (Priority 1) - cheapest for buyer
t=3s  -> Try LimitMid  (Priority 2) - mid spread
t=9s  -> Try LimitAsk  (Priority 3) - most expensive limit
t=15s -> Try Market    (Priority 4) - guaranteed fill

SELL ORDER execution timeline:
t=0s  -> Try LimitAsk  (Priority 1) - highest price for seller
t=3s  -> Try LimitMid  (Priority 2) - mid spread
t=9s  -> Try LimitBid  (Priority 3) - lowest limit price
t=15s -> Try Market    (Priority 4) - guaranteed fill
```

### 2.2 Slippage Tolerance

**What**: `SlippageInPercentage` allows the strategy to accept fills slightly away from its target price.

**Columns/Parameters Involved**: `SlippageInPercentage`, `ModelID`

**Rules**:
- Currently 0.00 for all strategies - no slippage tolerance configured; strategies execute at exact target prices only
- The field exists for future fine-tuning: a value of 0.5 would allow execution up to 0.5% away from the strategy's target price
- DEFAULT constraint ensures new strategies start with zero slippage tolerance

---

## 3. Data Overview

| ModelID | IsBuy | Priority | ExecutionDelaySeconds | SlippageInPercentage | Meaning |
|---|---|---|---|---|---|
| 1 (LimitBid) | 1 (Buy) | 1 | 0 | 0.00 | For buy orders, LimitBid is the FIRST strategy tried immediately - attempts to fill at the bid price, the most favorable price for the buyer. |
| 3 (LimitAsk) | 0 (Sell) | 1 | 0 | 0.00 | For sell orders, LimitAsk is the FIRST strategy tried immediately - attempts to fill at the ask price, the most favorable price for the seller. |
| 2 (LimitMid) | 1 (Buy) | 2 | 3 | 0.00 | Mid-price fallback for buys: if bid price did not fill within 3 seconds, try the spread midpoint. |
| 2 (LimitMid) | 0 (Sell) | 2 | 3 | 0.00 | Mid-price fallback for sells: symmetric - same delay and priority as the buy-side mid attempt. |
| 4 (MarketOrder) | 1 (Buy) | 4 | 3 | 0.00 | Final fallback for all buy orders: market order guarantees a fill at current market price after all limit strategies have been exhausted. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ModelID | int | NO | - | VERIFIED | FK to `Hedge.ExecutionStrategyModels.ModelID`. Identifies which execution strategy this configuration row applies to: 1=LimitOrderBid, 2=LimitOrderMid, 3=LimitOrderAsk, 4=MarketOrder. Part of the composite PK (ModelID, IsBuy). |
| 2 | Priority | int | NO | - | VERIFIED | Execution order within the strategy schedule for this direction (IsBuy). Lower value = tried first. Priority 1 is attempted immediately at order receipt; higher priorities are attempted after their respective delays. All 4 strategies have unique priorities (1-4) per direction. |
| 3 | ExecutionDelaySeconds | int | NO | - | VERIFIED | Seconds to wait after the PREVIOUS strategy attempt before trying this one. Priority-1 strategies always use 0 (immediate). Subsequent strategies use 3 or 6 seconds. Cumulative: LimitAsk/LimitBid at Priority 3 runs ~9 seconds after order start (0 + 3 + 6). |
| 4 | IsBuy | bit | NO | - | VERIFIED | Order direction this configuration row applies to. 1=buy order strategy schedule, 0=sell order strategy schedule. Together with ModelID forms the composite PK, allowing asymmetric strategy parameters per direction. |
| 5 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML via `suser_name()`. |
| 6 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from `CONTEXT_INFO()`. NULL when not set. |
| 7 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. All rows date from 2022-03-28 (original Smart Execution deployment). |
| 8 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for all current rows; past values stored in History.ExecutionStrategyModelConfigurations. |
| 9 | SlippageInPercentage | decimal(8,2) | NO | 0 | CODE-BACKED | Maximum allowable price deviation from the strategy's target price, expressed as a percentage. Currently 0.00 for all strategies - exact price execution only. Constraint: DF_SlippageInPercentage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ModelID | Hedge.ExecutionStrategyModels | Implicit FK | Links each configuration to the strategy model it configures. No explicit FK constraint but enforced by application. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetSmartExecutionConfigurations | (table ref) | READER | SELECTs all columns to return the full strategy schedule to the Smart Execution engine on startup |
| History.ExecutionStrategyModelConfigurations | (temporal) | Temporal History | Stores historical configuration versions via SYSTEM_VERSIONING |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ExecutionStrategyModelConfigurations (table)
  (no code-level dependencies; Hedge.ExecutionStrategyModels is a relational dependency via implicit FK)
```

---

### 6.1 Objects This Depends On

No hard code-level dependencies (CREATE TABLE has no FK constraints).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetSmartExecutionConfigurations | Stored Procedure | READER - SELECTs ModelID, Priority, ExecutionDelaySeconds, IsBuy, SlippageInPercentage for the Smart Execution engine |
| History.ExecutionStrategyModelConfigurations | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ExecStrategyConfigs | CLUSTERED PK | ModelID ASC, IsBuy ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ExecStrategyConfigs | PRIMARY KEY | (ModelID, IsBuy) - one configuration row per strategy per direction |
| DF_SlippageInPercentage | DEFAULT | SlippageInPercentage = 0 (no slippage tolerance by default) |
| DF_ExecutionStrategyModelConfigurations_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_ExecutionStrategyModelConfigurations_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.ExecutionStrategyModelConfigurations |
| Tr_T_ExecutionStrategyModelConfiguration_INSERT | TRIGGER | No-op INSERT trigger to force temporal history capture |

---

## 8. Sample Queries

### 8.1 View the full Smart Execution strategy schedule per direction

```sql
SELECT
    esmc.IsBuy,
    esmc.Priority,
    esm.Name         AS StrategyName,
    esmc.ExecutionDelaySeconds,
    esmc.SlippageInPercentage
FROM Hedge.ExecutionStrategyModelConfigurations esmc WITH (NOLOCK)
JOIN Hedge.ExecutionStrategyModels esm WITH (NOLOCK)
    ON esmc.ModelID = esm.ModelID
ORDER BY esmc.IsBuy DESC, esmc.Priority ASC
```

### 8.2 View cumulative timing for the execution cascade

```sql
SELECT
    esmc.IsBuy,
    esmc.Priority,
    esm.Name AS StrategyName,
    esmc.ExecutionDelaySeconds,
    SUM(esmc.ExecutionDelaySeconds) OVER (
        PARTITION BY esmc.IsBuy
        ORDER BY esmc.Priority
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeSecondsFromOrderStart
FROM Hedge.ExecutionStrategyModelConfigurations esmc WITH (NOLOCK)
JOIN Hedge.ExecutionStrategyModels esm WITH (NOLOCK)
    ON esmc.ModelID = esm.ModelID
ORDER BY esmc.IsBuy DESC, esmc.Priority
```

### 8.3 Check configuration change history

```sql
SELECT
    h.ModelID,
    h.IsBuy,
    h.Priority,
    h.ExecutionDelaySeconds,
    h.SlippageInPercentage,
    h.SysStartTime,
    h.SysEndTime,
    h.DbLoginName
FROM History.ExecutionStrategyModelConfigurations h WITH (NOLOCK)
ORDER BY h.ModelID, h.IsBuy, h.SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Two Confluence pages about Smart Execution were found in DROD space but were inaccessible.)

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ExecutionStrategyModelConfigurations | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ExecutionStrategyModelConfigurations.sql*
