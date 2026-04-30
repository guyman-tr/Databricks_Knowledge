# Trade.SplitHoldingFees

> Adjusts all holding fee configurations for an instrument after a stock split, multiplying every fee rate by the split PriceRatio and persisting via Trade.UpdateInstrumentToFeeConfigTableV2.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SplitID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a stock undergoes a split, all fee rates denominated in price-per-unit terms must be adjusted proportionally. An overnight fee that was $0.01/unit before a 2-for-1 split should become $0.005/unit after, because each unit is now worth half as much. This procedure handles that adjustment for all eight holding-fee categories (non-leveraged buy/sell end-of-week and overnight, leveraged buy/sell end-of-week and overnight).

The procedure reads the split's PriceRatio from `History.SplitRatio`, multiplies every current fee value for the affected instrument by that ratio, and updates the fee config table via the standard `Trade.UpdateInstrumentToFeeConfigTableV2` procedure. It also marks the split as complete (`IsCompleteHoldingFees = 1`) so re-runs are idempotent.

---

## 2. Business Logic

### 2.1 Idempotency Guard

**What**: The procedure only processes splits that have not already been fee-adjusted.

**Columns/Parameters Involved**: `History.SplitRatio.IsCompleteHoldingFees`

**Rules**:
- WHERE ID = @SplitID AND IsCompleteHoldingFees = 0
- If @@ROWCOUNT = 0 -> RAISERROR ('The split does not exist or was already done', 16, 1)
- On success: UPDATE History.SplitRatio SET IsCompleteHoldingFees = 1 WHERE ID = @SplitID

### 2.2 PriceRatio Selection

**What**: Uses the unadjusted-full ratio if available, falling back to the standard unadjusted ratio.

**Columns/Parameters Involved**: `History.SplitRatio.PriceRatioUnAdjustedFull`, `History.SplitRatio.PriceRatioUnAdjusted`

**Rules**:
- @PriceRatio = ISNULL(PriceRatioUnAdjustedFull, PriceRatioUnAdjusted)
- `PriceRatioUnAdjustedFull` is used when available (more precise, not adjusted for dividend effects)

### 2.3 Fee Rate Scaling

**What**: All eight fee rates from Trade.InstrumentToFeeConfigV2 are multiplied by PriceRatio.

**Columns/Parameters Involved**: All fee columns in Trade.InstrumentToFeeConfigV2

**Rules**:
- All fees are multiplied: `fee * @PriceRatio`
- For a 2-for-1 split: PriceRatio ~ 0.5 -> fees halved (each unit worth half as much)
- SettlementTypeID and FeeCalculationTypeID pass through unchanged (not rate-based)
- The new values are inserted into a table-valued parameter `@FeeValuesTbl` (type `Trade.InstrumentToFeeConfigTypeV2`)
- `Trade.UpdateInstrumentToFeeConfigTableV2` is then called with `@UpdatedByUser='split'` for audit trail

### 2.4 Error Handling

**What**: Nested transaction handling distinguishes between top-level and nested transaction states.

**Columns/Parameters Involved**: `@TranFlag`, `@@TRANCOUNT`

**Rules**:
- @TranFlag = 0 before BEGIN TRANSACTION; = 1 after -> catches errors before the transaction even starts
- @@TRANCOUNT = 1: this is the outermost transaction -> ROLLBACK
- @@TRANCOUNT > 1: nested inside another transaction -> COMMIT (let outer handle rollback)
- THROW re-raises the error to the caller

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SplitID | int | NO | - | CODE-BACKED | Identifier of the split event in History.SplitRatio. Must correspond to a row where IsCompleteHoldingFees = 0, otherwise the procedure raises an error. |

**Fee rates adjusted (read from Trade.InstrumentToFeeConfigV2, written via UpdateInstrumentToFeeConfigTableV2):**

| Fee Column | Description |
|-----------|-------------|
| NonLeveragedSellEndOfWeekFee | Fee for non-leveraged short positions held over the weekend |
| NonLeveragedBuyEndOfWeekFee | Fee for non-leveraged long positions held over the weekend |
| NonLeveragedBuyOverNightFee | Overnight fee for non-leveraged long positions |
| NonLeveragedSellOverNightFee | Overnight fee for non-leveraged short positions |
| LeveragedBuyEndOfWeekFee | Fee for leveraged long positions held over the weekend |
| LeveragedSellEndOfWeekFee | Fee for leveraged short positions held over the weekend |
| LeveragedBuyOverNightFee | Overnight fee for leveraged long positions |
| LeveragedSellOverNightFee | Overnight fee for leveraged short positions |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SplitID | History.SplitRatio | Reader + Writer | Reads PriceRatio and InstrumentID; marks IsCompleteHoldingFees=1 on completion |
| @InstrumentID | Trade.InstrumentToFeeConfigV2 | Reader | Reads current fee rates to multiply by PriceRatio |
| @FeeValuesTbl | Trade.UpdateInstrumentToFeeConfigTableV2 | Executor | Called with scaled fees and UpdatedByUser='split' |
| Trade.InstrumentToFeeConfigTypeV2 | User Defined Type | TVP type for @FeeValuesTbl parameter |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| Trade.ActivateSplit_Inner | Stored Procedure | Calls SplitHoldingFees as part of the full split activation sequence |
| Trade.RolloverFeesAlertIfNeeded | Stored Procedure | Calls SplitHoldingFees to adjust fees before alerting (called twice - for holding fee adjustment) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SplitHoldingFees (procedure)
+-- History.SplitRatio (table) [read PriceRatio + mark complete]
+-- Trade.InstrumentToFeeConfigV2 (table) [read current fee rates]
+-- Trade.UpdateInstrumentToFeeConfigTableV2 (procedure) [write scaled fees]
+-- Trade.InstrumentToFeeConfigTypeV2 (UDT) [TVP type for fee batch]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SplitRatio | Table | Source for PriceRatio and InstrumentID; completion flag updated here |
| Trade.InstrumentToFeeConfigV2 | Table | Source for current fee rates to be scaled |
| Trade.UpdateInstrumentToFeeConfigTableV2 | Stored Procedure | Target for persisting scaled fee values |
| Trade.InstrumentToFeeConfigTypeV2 | User Defined Type | Table-valued parameter type for fee batch |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ActivateSplit_Inner | Stored Procedure | Called as part of stock split activation pipeline |
| Trade.RolloverFeesAlertIfNeeded | Stored Procedure | Called to adjust holding fees during rollover fee alert process |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IsCompleteHoldingFees guard | Idempotency | Prevents re-processing an already-adjusted split; raises error if split not found or already done |
| SET NOCOUNT ON | Performance | Suppresses row-count messages during fee loading |

---

## 8. Sample Queries

### 8.1 Execute fee adjustment for a specific split

```sql
EXEC Trade.SplitHoldingFees @SplitID = 42;
```

### 8.2 Check pending fee adjustments

```sql
SELECT ID, InstrumentID, PriceRatioUnAdjusted, PriceRatioUnAdjustedFull,
       IsCompleteHoldingFees, IsComplete
FROM History.SplitRatio WITH (NOLOCK)
WHERE IsCompleteHoldingFees = 0
ORDER BY ID DESC;
```

### 8.3 View current fee config before and after

```sql
SELECT InstrumentID,
       NonLeveragedBuyEndOfWeekFee, NonLeveragedBuyOverNightFee,
       LeveragedBuyEndOfWeekFee, LeveragedBuyOverNightFee
FROM Trade.InstrumentToFeeConfigV2 WITH (NOLOCK)
WHERE InstrumentID = 1234;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SplitHoldingFees | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SplitHoldingFees.sql*
