# History.ExecutionStrategyModelConfigurations

> Temporal system-versioned history table storing all past versions of smart execution escalation configurations - recording every change to how the hedging layer sequences order placement attempts by strategy model, direction (buy/sell), priority, and delay before escalating to a more aggressive execution strategy.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; rows identified by (ModelID, IsBuy) + SysStartTime + SysEndTime |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

This table is the **SQL Server temporal history store** for `Hedge.ExecutionStrategyModelConfigurations`. SQL Server automatically moves rows here whenever an execution strategy configuration is updated or deleted.

`Hedge.ExecutionStrategyModelConfigurations` defines the **smart execution escalation ladder** for eToro's hedge execution layer. For each strategy model and each trade direction (buy or sell), it specifies:
- **Priority**: the order in which strategies are tried (1 = first attempt)
- **ExecutionDelaySeconds**: how long to wait before escalating to the next strategy in the ladder
- **SlippageInPercentage**: acceptable slippage tolerance for this strategy
- **IsBuy**: whether this configuration applies to buy or sell hedge orders

**The escalation logic**: The hedging application attempts execution using Priority=1 first. If the order is not filled within `ExecutionDelaySeconds`, it escalates to Priority=2, then Priority=3, and finally Priority=4 (market order as the last resort).

**Buy order escalation** (start passive, escalate to aggressive):

| Priority | ModelID | Strategy | Delay Before This | Rationale |
|----------|---------|----------|-------------------|-----------|
| 1 | 1 | LimitOrderBid | 0s (immediate) | Best price (bid = lowest ask for buyer) - try passive first |
| 2 | 2 | LimitOrderMid | 3s | Mid price - moderate aggressiveness if bid didn't fill |
| 3 | 3 | LimitOrderAsk | 6s | Ask price - aggressive, highest fill probability |
| 4 | 4 | MarketOrder | 3s after ask | Market order - guaranteed fill, no price limit |

**Sell order escalation** (priority inverted - ask first is best for seller):

| Priority | ModelID | Strategy | Delay Before This | Rationale |
|----------|---------|----------|-------------------|-----------|
| 1 | 3 | LimitOrderAsk | 0s (immediate) | Best price for seller (ask = highest price) |
| 2 | 2 | LimitOrderMid | 3s | Mid price - step down if ask didn't fill |
| 3 | 1 | LimitOrderBid | 6s | Bid price - lowest price the seller accepts, most likely to fill |
| 4 | 4 | MarketOrder | 3s after bid | Market order - last resort guaranteed fill |

This mirrors standard institutional smart order routing (SOR) practice: buy orders start at bid to minimize cost, sell orders start at ask to maximize proceeds; both escalate toward the market if limit orders are not filled.

**Read by**: `Hedge.GetSmartExecutionConfigurations` - returns all 8 rows `(ModelID, Priority, ExecutionDelaySeconds, IsBuy, SlippageInPercentage)` for the hedging application to load its execution ladder at startup.

**History**: 8 rows - all zero-duration INSERT artifacts from 2022-03-28 by TRAD\shanyso (the same user who set up `Hedge.ExecutionStrategyModels`). No modifications have been made to the execution escalation configuration since initial setup.

---

## 2. Business Logic

### 2.1 Temporal Versioning - How History Is Recorded

**What**: SQL Server automatically populates this table via system-versioning whenever a strategy configuration is updated or deleted.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ModelID`, `IsBuy`

**Rules**:
- When a row is **updated**: SQL Server moves the old version here with `SysEndTime` = moment of update.
- When a row is **deleted**: SQL Server moves the row here with `SysEndTime` = deletion timestamp.
- Active rows in `Hedge.ExecutionStrategyModelConfigurations` have `SysEndTime = '9999-12-31...'` and are NOT in this history table.
- CLUSTERED index on `(SysEndTime, SysStartTime)` enables efficient `FOR SYSTEM_TIME AS OF` temporal queries.

### 2.2 INSERT Trigger Creates Zero-Duration History Rows

**What**: `Tr_T_ExecutionStrategyModelConfiguration_INSERT` fires a no-op UPDATE after every INSERT.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ModelID`

**Rules**:
- After INSERT, trigger executes: `UPDATE A SET A.ModelID = A.ModelID` (no-op self-update joined on ModelID).
- SQL Server temporal moves the just-inserted row to history with `SysStartTime = SysEndTime = T` (zero-duration).
- Note: The trigger joins only on ModelID (not on IsBuy), meaning it matches ALL rows for that ModelID - this is a potential over-update affecting both the buy and sell rows for the same ModelID simultaneously when only one is inserted. However since both directions are always inserted together as pairs, this is functionally equivalent.
- All 8 current history rows are zero-duration INSERT artifacts from 2022-03-28T14:44:48.556Z - identical timestamp to Hedge.ExecutionStrategyModels history rows.

### 2.3 Smart Execution Priority Ladder

**What**: The Priority and ExecutionDelaySeconds columns together define a time-sequenced escalation ladder for order placement.

**Columns/Parameters Involved**: `Priority`, `ExecutionDelaySeconds`, `ModelID`, `IsBuy`

**Rules**:
- Priority is unique per direction (IsBuy=0 and IsBuy=1 form separate independent ladders).
- Priority=1 is attempted first with 0 seconds delay (immediate).
- Each subsequent priority is attempted after waiting `ExecutionDelaySeconds` from the previous attempt.
- The total time to reach market order (priority=4) for a buy: 0s (bid) + 3s delay + 6s delay = 9 seconds before MarketOrder.
- For sell: 0s (ask) + 3s delay + 6s delay = 9 seconds before MarketOrder.
- SlippageInPercentage = 0 for all current rows, meaning no slippage tolerance is applied (orders must execute at or better than the target price).

### 2.4 Buy vs Sell Asymmetry

**What**: Buy and sell orders use opposite priority assignments for limit strategy models, reflecting market structure.

**Columns/Parameters Involved**: `IsBuy`, `ModelID`, `Priority`

**Rules**:
- For **buys** (`IsBuy=1`): LimitOrderBid (ModelID=1) has Priority=1 because it tries to buy at the bid price - cheapest for the buyer.
- For **sells** (`IsBuy=0`): LimitOrderAsk (ModelID=3) has Priority=1 because it tries to sell at the ask price - most revenue for the seller.
- MarketOrder (ModelID=4) always has Priority=4 regardless of direction - it is the guaranteed-fill fallback regardless of whether buying or selling.
- LimitOrderMid (ModelID=2) always has Priority=2 in both directions - it is the middle step in both escalation ladders.

---

## 3. Data Overview

**History**: 8 rows, all zero-duration INSERT artifacts (SysStartTime = SysEndTime = 2022-03-28T14:44:48.556Z). No non-trivial history.

**Current** (Hedge.ExecutionStrategyModelConfigurations): 8 rows, unchanged since 2022-03-28.

| ModelID | Strategy | IsBuy | Priority | Delay (s) | Slippage% |
|---------|----------|-------|----------|-----------|-----------|
| 1 | LimitOrderBid | 1 (buy) | 1 | 0 | 0 |
| 2 | LimitOrderMid | 1 (buy) | 2 | 3 | 0 |
| 3 | LimitOrderAsk | 1 (buy) | 3 | 6 | 0 |
| 4 | MarketOrder | 1 (buy) | 4 | 3 | 0 |
| 3 | LimitOrderAsk | 0 (sell) | 1 | 0 | 0 |
| 2 | LimitOrderMid | 0 (sell) | 2 | 3 | 0 |
| 1 | LimitOrderBid | 0 (sell) | 3 | 6 | 0 |
| 4 | MarketOrder | 0 (sell) | 4 | 3 | 0 |

**Interpretation of delay column**: `ExecutionDelaySeconds` represents how long to wait at this strategy before escalating. Priority=1 has 0 delay (try immediately). The next step is tried after the delay of the CURRENT step. So for buys: try Bid immediately; if not filled after 0s advance to Mid (but wait 3s there); if not filled advance to Ask (wait 6s there); if still not filled advance to MarketOrder.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ModelID | int | NO | - | VERIFIED | The execution strategy model. Composite PK with IsBuy in source table. FK to Hedge.ExecutionStrategyModels (ModelID). Values: 1=LimitOrderBid, 2=LimitOrderMid, 3=LimitOrderAsk, 4=MarketOrder. Each model has a separate row per direction (buy/sell). |
| 2 | Priority | int | NO | - | VERIFIED | Execution attempt order for this direction. Lower number = tried first. 1=first attempt (passive), 2/3=escalation, 4=last resort. For buys: 1=Bid, 2=Mid, 3=Ask, 4=Market. For sells: 1=Ask, 2=Mid, 3=Bid, 4=Market. Priority is independent between buy and sell directions. |
| 3 | ExecutionDelaySeconds | int | NO | - | VERIFIED | Seconds to wait at this strategy before escalating to the next priority level. 0 = attempt immediately (Priority=1 rows). 3 = wait 3 seconds. 6 = wait 6 seconds. Current values: 0s (first attempt), 3s or 6s (escalation delays). Total time to market order = sum of delays across previous priorities = 9 seconds for both buy and sell. |
| 4 | IsBuy | bit | NO | - | VERIFIED | Trade direction this configuration governs. 1 = applies to buy hedge orders. 0 = applies to sell hedge orders. Buy and sell have separate independent escalation ladders with inverted priority assignments for limit strategies. Composite PK with ModelID. |
| 5 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login captured via suser_name() computed column on source. Initial setup by TRAD\shanyso (2022-03-28). NULL if login unavailable. |
| 6 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application user identity captured via context_info() computed column. Contains email padded with null bytes when set. NULL for all current history rows (initial setup done directly, not via application). Must be trimmed with REPLACE/RTRIM. |
| 7 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this configuration version became active. All current rows = 2022-03-28T14:44:48.556Z (zero-duration INSERT artifacts from initial setup). |
| 8 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version was superseded. Clustered index leading column. All current rows = 2022-03-28T14:44:48.556Z (zero-duration). Actual changes would produce rows with SysEndTime > SysStartTime. |
| 9 | SlippageInPercentage | decimal(8, 2) | NO | 0 | VERIFIED | Acceptable slippage tolerance as a percentage for this strategy and direction. Default 0 = no slippage tolerance (order must execute at or better than the target price). If set to e.g. 0.5, the hedge system accepts fills up to 0.5% worse than the target price. All current rows are 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ModelID | Hedge.ExecutionStrategyModels | Implicit (FK on source) | The execution strategy model being configured (1=LimitOrderBid, 2=LimitOrderMid, 3=LimitOrderAsk, 4=MarketOrder) |
| (all columns) | Hedge.ExecutionStrategyModelConfigurations | Temporal | This row is a historical version of the source table row with matching (ModelID, IsBuy) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ExecutionStrategyModelConfigurations | (all columns) | Temporal (SYSTEM_VERSIONING) | Source table - SQL Server writes superseded rows here automatically on UPDATE/DELETE |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ExecutionStrategyModelConfigurations (table)
- Temporal history leaf node - no code-level dependencies
- Populated automatically from Hedge.ExecutionStrategyModelConfigurations (table)
- INSERT trigger Tr_T_ExecutionStrategyModelConfiguration_INSERT on source creates zero-duration rows

Hedge.ExecutionStrategyModelConfigurations (source) is:
- Read by: Hedge.GetSmartExecutionConfigurations (SP)
  -> SELECT ModelID, Priority, ExecutionDelaySeconds, IsBuy, SlippageInPercentage
  -> All rows (no filter) - hedging app loads complete escalation ladder at startup
- FK dependency: Hedge.ExecutionStrategyModels (ModelID)
  -> History: History.ExecutionStrategyModels (temporal history)
```

### 6.1 Objects This Depends On

No dependencies. Temporal history table populated automatically by SQL Server.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionStrategyModelConfigurations | Table | Source table - SQL Server writes old row versions here on UPDATE/DELETE; INSERT trigger also generates zero-duration rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ExecutionStrategyModelConfigurations | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

**Filegroup**: [DICTIONARY] - same as Hedge.ExecutionStrategyModels and History.ExecutionStrategyModels; consistent with reference/configuration data classification.
**Storage**: DATA_COMPRESSION = PAGE (table-level and index-level).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | Temporal history tables cannot have PK, UNIQUE, FK, or CHECK constraints in SQL Server |

**Source table constraints** (Hedge.ExecutionStrategyModelConfigurations):

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ExecStrategyConfigs | PRIMARY KEY (CLUSTERED) | Uniqueness on (ModelID, IsBuy) |
| DF_SlippageInPercentage | DEFAULT | SlippageInPercentage = 0 |

---

## 8. Sample Queries

### 8.1 Full escalation ladder as-of a specific date
```sql
SELECT h.ModelID, h.Priority, h.ExecutionDelaySeconds, h.IsBuy, h.SlippageInPercentage,
       h.DbLoginName, h.SysStartTime, h.SysEndTime
FROM [History].[ExecutionStrategyModelConfigurations] h
WHERE '2023-06-01' BETWEEN h.SysStartTime AND h.SysEndTime
  AND h.SysStartTime < h.SysEndTime  -- exclude zero-duration INSERT artifacts
ORDER BY h.IsBuy DESC, h.Priority
```

### 8.2 Current escalation ladder with strategy names (what hedging app sees)
```sql
-- Mirrors Hedge.GetSmartExecutionConfigurations with strategy names
SELECT c.ModelID, m.Name AS StrategyName, c.Priority, c.ExecutionDelaySeconds,
       CASE WHEN c.IsBuy = 1 THEN 'Buy' ELSE 'Sell' END AS Direction,
       c.SlippageInPercentage
FROM [Hedge].[ExecutionStrategyModelConfigurations] c
JOIN [Hedge].[ExecutionStrategyModels] m ON c.ModelID = m.ModelID
ORDER BY c.IsBuy DESC, c.Priority
```

### 8.3 Check if escalation ladder has ever changed
```sql
SELECT ModelID, IsBuy, Priority, ExecutionDelaySeconds, SlippageInPercentage, DbLoginName, SysStartTime, SysEndTime
FROM [History].[ExecutionStrategyModelConfigurations]
WHERE SysStartTime < SysEndTime  -- exclude zero-duration INSERT artifacts
ORDER BY SysStartTime DESC
-- Empty result = no escalation configuration changes since initial 2022 setup
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ExecutionStrategyModelConfigurations | Type: Table | Source: etoro/etoro/History/Tables/History.ExecutionStrategyModelConfigurations.sql*
