# Trade.ActivateSplit_Inner

> Executes the core logic of a stock split: adjusts price/amount ratios in History.SplitRatio, splits open orders and positions, recalculates holding fees, optionally splits historical closed positions/orders, and updates Trade.CurrencyPrice to reflect the new price level.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SplitID (references History.SplitRatio.ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ActivateSplit_Inner is the inner engine that processes a stock split (or reverse split) across all affected positions, orders, and pricing. Stock splits change the number of shares and price proportionally (e.g., a 2:1 split doubles shares and halves the price). This procedure ensures all open positions, pending orders, holding fees, historical records, and live currency prices are adjusted consistently.

The procedure uses completion flags in History.SplitRatio (IsCompletedOpenPositions, IsCompletedOpenOrders, etc.) to track progress, allowing re-runs via @IsReRun=1 if the split fails partway through. Each step is idempotent — it checks the flag before executing.

Key processing steps (in order):
1. **Price/Amount ratio normalization**: Cascades the split ratio to all prior splits for the same instrument
2. **Open orders split**: Routes to Trade.OpenOrdersSplit or Stocks.OpenOrdersSplit based on ProviderToInstrument.Enabled
3. **Open positions split**: Flushes pending TSL via Trade.FlushTSLForInstrumentID, then calls Trade.SplitOpenPositions
4. **Holding fees split**: Adjusts holding fee calculations via Trade.SplitHoldingFees
5. **Historical splits** (optional): Adjusts closed positions/orders when @ShouldSplitHistory=1
6. **CurrencyPrice update**: Adjusts live prices (Ask, Bid, AskDiscounted, BidDiscounted, UnitMargin, LastPrice) by the PriceRatio

The procedure runs with SET DEADLOCK_PRIORITY HIGH to minimize the risk of deadlock during this critical operation.

---

## 2. Business Logic

### 2.1 Ratio Cascade

**What**: When a new split is activated, all prior splits for the same instrument are renormalized.

**Rules**:
- The current split's PriceRatio and AmountRatio are reset to 1
- All prior splits (ID <= @SplitID, same InstrumentID) have their ratios multiplied by the new split's ratios
- Uses ISNULL(PriceRatioUnAdjustedFull, PriceRatioUnAdjusted) for the actual ratio values
- Only runs if IsCompletedPricAndAmount = 0

### 2.2 Provider-Based Order Routing

**What**: Routes order splitting to different procedures based on whether the instrument is CFD-enabled.

**Rules**:
- If Trade.ProviderToInstrument.Enabled = 0: uses Stocks.OpenOrdersSplit (stock-specific logic)
- If Enabled ≠ 0: uses Trade.OpenOrdersSplit (standard CFD logic)
- Same routing applies for close orders split

### 2.3 CurrencyPrice Adjustment

**What**: Updates live trading prices to reflect the split-adjusted price level.

**Rules**:
- All price columns multiplied by @PriceRatio: Ask, Bid, AskDiscounted, BidDiscounted, UnitMargin, LastPrice
- Runs within its own transaction (nested BEGIN TRAN / COMMIT TRAN)
- Also sets IsCurrencyPriceChanged = 1 on History.SplitRatio
- Only runs if IsCurrencyPriceChanged = 0

### 2.4 Re-run Safety

**What**: Each step is gated by a completion flag, allowing safe re-execution.

**Rules**:
- @IsReRun = 0: fails if all steps already completed
- @IsReRun = 1: skips already-completed steps, retries incomplete ones
- Flags: IsCompletedPricAndAmount, IsCompletedOpenOrders, IsCompletedOpenPositions, IsCompleteHoldingFees, IsCompletedClosePositions, IsCompletedCloseOrders, IsCurrencyPriceChanged

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SplitID | INT | NO | - | VERIFIED | References History.SplitRatio.ID. Identifies which stock split to activate. |
| 2 | @ShouldSplitHistory | TINYINT | YES | 0 | CODE-BACKED | When 1, also adjusts historical closed positions and close orders. When 0, only open positions/orders are split. |
| 3 | @IsReRun | TINYINT | YES | 0 | CODE-BACKED | When 1, allows re-execution of a partially completed split, skipping already-completed steps. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM/UPDATE | History.SplitRatio | SELECT/UPDATE | Reads split ratios and updates completion flags |
| FROM | Trade.ProviderToInstrument | SELECT | Checks instrument enabled status for order routing |
| UPDATE | Trade.CurrencyPrice | UPDATE | Adjusts live prices by PriceRatio |
| EXEC | Trade.FlushTSLForInstrumentID | EXEC | Flushes pending TSL before position split |
| EXEC | Trade.SplitOpenPositions | EXEC | Splits open positions |
| EXEC | Trade.OpenOrdersSplit | EXEC | Splits open orders (CFD) |
| EXEC | Stocks.OpenOrdersSplit | EXEC | Splits open orders (stocks) |
| EXEC | Trade.SplitHoldingFees | EXEC | Adjusts holding fees |
| EXEC | History.SplitClosePositions | EXEC | Splits closed positions (optional) |
| EXEC | Trade.CloseOrdersSplit | EXEC | Splits close orders (CFD) |
| EXEC | Stocks.CloseOrdersSplit | EXEC | Splits close orders (stocks) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ActivateSplit | (batch #22) | EXEC | Wrapper that manages BSL job coordination before/after split |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ActivateSplit_Inner (procedure)
+-- History.SplitRatio (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.CurrencyPrice (table)
+-- Trade.FlushTSLForInstrumentID (procedure)
+-- Trade.SplitOpenPositions (procedure)
+-- Trade.OpenOrdersSplit (procedure)
+-- Stocks.OpenOrdersSplit (procedure)
+-- Trade.SplitHoldingFees (procedure)
+-- History.SplitClosePositions (procedure)
+-- Trade.CloseOrdersSplit (procedure)
+-- Stocks.CloseOrdersSplit (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SplitRatio | Table | SELECT/UPDATE - split ratios and completion tracking |
| Trade.ProviderToInstrument | Table | SELECT - instrument enabled status |
| Trade.CurrencyPrice | Table | UPDATE - live price adjustment |
| Trade.FlushTSLForInstrumentID | Procedure | EXEC - flush pending TSL |
| Trade.SplitOpenPositions | Procedure | EXEC - split open positions |
| Trade.OpenOrdersSplit | Procedure | EXEC - split open orders |
| Trade.SplitHoldingFees | Procedure | EXEC - split holding fees |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ActivateSplit | Procedure | EXEC - orchestration wrapper |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DEADLOCK_PRIORITY HIGH | Concurrency | Protects split from being chosen as deadlock victim |
| SplitID validation | Validation | @@ROWCOUNT = 0 → RAISERROR |
| Already completed | Validation | @IsReRun=0 + all flags=1 → RAISERROR |
| CurrencyPrice transaction | Isolation | Price update runs in its own nested transaction |

---

## 8. Sample Queries

### 8.1 View split status

```sql
SELECT  ID, InstrumentID, PriceRatio, AmountRatio,
        IsCompletedPricAndAmount, IsCompletedOpenOrders, IsCompletedOpenPositions,
        IsCompleteHoldingFees, IsCompletedClosePositions, IsCompletedCloseOrders,
        IsCurrencyPriceChanged
FROM    History.SplitRatio
WHERE   ID = 42;
```

### 8.2 Execute a split (inner)

```sql
EXEC Trade.ActivateSplit_Inner @SplitID = 42, @ShouldSplitHistory = 1, @IsReRun = 0;
```

---

## 9. Atlassian Knowledge Sources

- TRAD-2815 (Jira): Referenced in code comments — Added SET DEADLOCK_PRIORITY HIGH to prevent split from being chosen as deadlock victim.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 9.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ActivateSplit_Inner | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ActivateSplit_Inner.sql*
