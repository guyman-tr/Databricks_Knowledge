# Trade.ExposuresForAllHedgeServers_Update

> Incrementally updates the materialized hedge exposure table when a position opens or closes, handling self-only and hierarchical (parent + children) close action types.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID with @Open_Close direction |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the real-time incremental update mechanism for the `Trade.ExposuresForAllHedgeServers` materialized exposure table. Every time a position opens or closes, this procedure is called to adjust the buy/sell lot count aggregates for the affected customer/provider/instrument/hedge server combination.

The procedure is critical for the hedge server exposure tracking system. Hedge servers need to know their current exposure per instrument in real-time for risk management. Rather than recalculating from all open positions each time (expensive), this procedure maintains a running total that is adjusted incrementally. The companion `_Check` procedure periodically reconciles this table to catch any drift.

The procedure handles three distinct scenarios based on the action type: (1) Open - adds lots to exposure, (2) Close Self Only (SL, TP, EOW, Contract Rollover) - removes only the position's own lots, and (3) Close with 1st Generation Children (Customer, BackOffice, CloseAll, Mirror SL, Manual Copy Close) - removes lots from the parent position AND all direct child positions. Some action types (SL/TP via trade server, Return to Market, Join Demo) do nothing.

---

## 2. Business Logic

### 2.1 Action Type Classification

**What**: Different close action types determine whether only the position itself or also its children affect exposures.

**Columns/Parameters Involved**: `@ActionType`, `@Open_Close`

**Rules**:
- **Do Nothing** (action types 3, 4, 6, 11 and any unknown): Return immediately, no exposure change
  - 3 = Stop Loss (via trade server), 4 = Return to Market, 6 = Take Profit (via trade server), 11 = Join Demo Challenge
- **Decrease ONLY self** (action types 1, 2, 5, 7): Subtract only this position's LotCountDecimal
  - 1 = Stop Loss, 2 = End of Week, 5 = Take Profit, 7 = Contract Rollover
  - If LotCountDecimal = 0, also do nothing
- **Decrease self AND 1st generation children** (action types 0, 8, 9, 10, 12, 13, 14):
  - 0 = Customer, 8 = BackOffice User, 12 = Close All, 13 = Mirror SL, 14 = Manual close of copied position
  - 9 = Hierarchical Close (children ONLY, not self), 10 = Hierarchical close by recovery (children ONLY)

**Diagram**:
```
ActionType Classification:
  DO NOTHING:     3, 4, 6, 11, unknown -> RETURN 0
  SELF ONLY:      1, 2, 5, 7           -> decrease position lots only
  SELF+CHILDREN:  0, 8, 12, 13, 14     -> decrease position + child lots
  CHILDREN ONLY:  9, 10                 -> decrease child lots (not parent)
```

### 2.2 Exposure Update Logic

**What**: Adjusts OpenedBuy or OpenedSell based on trade direction and operation type.

**Columns/Parameters Involved**: `OpenedBuy`, `OpenedSell`, `@IsBuy`, `@LotCountDecimal`, `@Open_Close`

**Rules**:
- For Opens: Add LotCountDecimal to OpenedBuy (if IsBuy=1) or OpenedSell (if IsBuy=0)
- For Closes: Subtract LotCountDecimal from the appropriate column
- Upsert pattern: UPDATE first, if @@ROWCOUNT=0 then INSERT (new exposure row)
- For hierarchical closes with children on different hedge servers: SUM child lots per hedge server and update each separately

### 2.3 Optional Change Logging

**What**: Detailed before/after logging using OUTPUT clause (currently disabled).

**Columns/Parameters Involved**: `@LogChanges`, `#OutputExp`

**Rules**:
- @LogChanges is hardcoded to 0 (disabled since FB 22182/22183 in 2014)
- When enabled: captures INSERTED/DELETED values via OUTPUT clause and writes to Trade.ExposuresForAllHedgeServersLOG with full parameter context
- If no rows affected, logs a "miss" record with NULL before/after values

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Open_Close | bit | NO | - | CODE-BACKED | Operation direction: 0 = Open (add lots to exposure), 1 = Close (subtract lots from exposure). |
| 2 | @CID | int | NO | - | CODE-BACKED | Customer ID whose exposure is being updated. Part of the composite key for ExposuresForAllHedgeServers. |
| 3 | @ActionType | int | NO | - | CODE-BACKED | Close action type that determines scope (self-only vs hierarchical). See Section 2.1 for full classification. Only used when @Open_Close=1. |
| 4 | @PositionID | bigint | NO | - | CODE-BACKED | Position being opened or closed. For hierarchical closes, used to find child positions via ParentPositionID. |
| 5 | @ParentPositionID | bigint | NO | - | CODE-BACKED | Parent position ID in copy-trading hierarchy. Used for logging context. |
| 6 | @ProviderID | int | NO | - | CODE-BACKED | Liquidity provider ID. Part of the composite key for ExposuresForAllHedgeServers. |
| 7 | @InstrumentID | int | NO | - | CODE-BACKED | Financial instrument ID. Part of the composite key for ExposuresForAllHedgeServers. |
| 8 | @HedgeServerID | int | NO | - | CODE-BACKED | Hedge server ID the position is assigned to. Part of the composite key for ExposuresForAllHedgeServers. Children may have different hedge servers than parent. |
| 9 | @IsBuy | bit | NO | - | CODE-BACKED | Trade direction: 1 = Buy/Long (adjusts OpenedBuy), 0 = Sell/Short (adjusts OpenedSell). |
| 10 | @LotCountDecimal | decimal(16,6) | NO | - | CODE-BACKED | Position size in lots. The amount to add (open) or subtract (close) from the exposure aggregate. If 0, procedure returns early for self-only closes and opens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE/INSERT | Trade.ExposuresForAllHedgeServers | MODIFIER/WRITER | Adjusts or creates exposure records based on position open/close |
| SELECT | Trade.Position (view) | READER | Reads child positions for hierarchical close (ParentPositionID = @PositionID, IsComputeForHedge=1) |
| INSERT | Trade.ExposuresForAllHedgeServersLOG | WRITER (disabled) | Logs before/after exposure values when @LogChanges=1 (currently hardcoded to 0) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Position open/close pipeline | EXEC | Caller | Called during every position open and close operation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ExposuresForAllHedgeServers_Update (procedure)
+-- Trade.ExposuresForAllHedgeServers (table)
+-- Trade.Position (view)
+-- Trade.ExposuresForAllHedgeServersLOG (table, disabled)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExposuresForAllHedgeServers | Table | UPDATE/INSERT - adjusts exposure aggregates |
| Trade.Position | View | SELECT - reads child positions for hierarchical closes |
| Trade.ExposuresForAllHedgeServersLOG | Table | INSERT (disabled) - change logging |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExposuresForAllHedgeServers_Check | Stored Procedure | Companion - periodically reconciles exposures against live data |
| Trade.ExposuresForAllHedgeServers_WeekendCleanup | Stored Procedure | Companion - purges zero-exposure records weekly |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Error Handling**: TRY/CATCH with THROW. Returns 0 on success, -1 on error.

---

## 8. Sample Queries

### 8.1 Simulate a Position Open Update

```sql
EXEC Trade.ExposuresForAllHedgeServers_Update
    @Open_Close = 0,       -- Open
    @CID = 12345,
    @ActionType = 0,
    @PositionID = 999999,
    @ParentPositionID = 0,
    @ProviderID = 1,
    @InstrumentID = 1001,
    @HedgeServerID = 5,
    @IsBuy = 1,
    @LotCountDecimal = 10.5
```

### 8.2 Check Current Exposure for a Customer

```sql
SELECT CID, ProviderID, InstrumentID, HedgeServerID,
       OpenedBuy, OpenedSell
  FROM Trade.ExposuresForAllHedgeServers WITH (NOLOCK)
 WHERE CID = 12345
 ORDER BY InstrumentID, HedgeServerID
```

### 8.3 View Change Log (When Logging Enabled)

```sql
SELECT TOP 50
       CID, InstrumentID, HedgeServerID,
       OpenedBuyInserted, OpenedBuyDeleted,
       OpenedSellInserted, OpenedSellDeleted,
       Open_Close, ActionType, PositionID
  FROM Trade.ExposuresForAllHedgeServersLOG WITH (NOLOCK)
 ORDER BY ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.6/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ExposuresForAllHedgeServers_Update | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ExposuresForAllHedgeServers_Update.sql*
