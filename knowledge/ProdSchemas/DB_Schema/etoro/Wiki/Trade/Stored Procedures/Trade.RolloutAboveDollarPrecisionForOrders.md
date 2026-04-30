# Trade.RolloutAboveDollarPrecisionForOrders

> Updates pending orders for a specific instrument to replace the legacy "no stop-loss" sentinel rate (based on old precision) with the new sentinel rate (based on new precision) when migrating instruments to above-dollar pricing precision.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID, @OldPrecision, @NewNOSLPrecision - precision migration parameters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

For instruments priced above $1 (e.g., stocks like AAPL, AMZN), eToro uses a reduced decimal precision for rates. When an instrument's pricing precision changes (fewer decimal places, "above dollar precision"), existing orders that use the old precision's "no SL/TP" sentinel rate must be migrated to the new sentinel rate.

The "no SL" sentinel is a tiny non-zero value representing "customer has no stop-loss set" - it equals `1 / 10^precision` (one pip at the old precision). When precision changes from e.g. 4 to 2 decimal places, the old sentinel was `0.0001` and the new sentinel is `0.01`. Any order with `StopLosRate = 0.0001` needs to be updated to `StopLosRate = 0.01`.

This procedure handles the **orders** side of this migration (pending orders in `Trade.Orders`). Its counterpart `Trade.RolloutAboveDollarPrecisionForPositions` handles open positions. Both are called by the orchestrator `Trade.RolloutAboveDollarPrecision`.

---

## 2. Business Logic

### 2.1 Sentinel Rate Migration

**What**: Replaces the old-precision no-SL/TP sentinel with the new-precision sentinel in pending orders.

**Columns/Parameters Involved**: `Trade.Orders.StopLosRate`, `Trade.Orders.TakeProfitRate`, `Trade.Orders.InstrumentID`

**Rules**:
- @OnePip = 1.00 / POWER(10, @OldPrecision) - the old "no SL" sentinel value
- @NoStopRate = 1.00 / POWER(10, @NewNOSLPrecision) - the new "no SL" sentinel value
- Two UPDATE statements: one for StopLosRate, one for TakeProfitRate
- Only updates rows where the rate EXACTLY equals the old sentinel (@OnePip) - custom SL/TP rates are not touched
- On error: inserts into #Errors and returns the error set (does not throw)

**Diagram**:
```
OldPrecision=4: @OnePip = 1/10000 = 0.0001 (old no-SL sentinel)
NewNOSLPrecision=2: @NoStopRate = 1/100 = 0.01 (new no-SL sentinel)

Trade.Orders WHERE InstrumentID=@InstrumentID:
  StopLosRate = 0.0001 -> SET StopLosRate = 0.01
  TakeProfitRate = 0.0001 -> SET TakeProfitRate = 0.01
  (Any other rate value is left unchanged)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument being migrated to above-dollar precision. All orders for this instrument with the old sentinel rate will be updated. |
| 2 | @OldPrecision | INT | NO | - | CODE-BACKED | The current (old) decimal precision of the instrument. Used to calculate the old "no SL" sentinel rate as 1/10^OldPrecision. Example: 4 means old sentinel = 0.0001. |
| 3 | @NewNOSLPrecision | INT | NO | - | CODE-BACKED | The new decimal precision for the "no SL/TP" sentinel rate. Used to calculate the replacement value as 1/10^NewNOSLPrecision. Example: 2 means new sentinel = 0.01. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | Trade.Orders | Modifier | Updates StopLosRate and TakeProfitRate sentinel values for matching instrument orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.RolloutAboveDollarPrecision | EXEC call | Caller | Orchestrator that calls this for each instrument in a comma-separated list |
| Trade.RolloutAboveDollarPrecision_25102021_FixForDoneInstrument | EXEC call | Caller | Fix variant that calls this with hardcoded OldPrecision=2 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RolloutAboveDollarPrecisionForOrders (procedure)
|- Trade.Orders (table - update target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | Updated to replace old sentinel SL/TP rates with new precision sentinels |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.RolloutAboveDollarPrecision | Procedure | Calls this as part of instrument precision migration |
| Trade.RolloutAboveDollarPrecision_25102021_FixForDoneInstrument | Procedure | Calls this with hardcoded OldPrecision=2 for re-processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Exact match | Logic | Only rows where rate exactly equals @OnePip are updated - custom rates untouched |
| Error capture | Logic | TRY/CATCH captures UPDATE errors into #Errors table; SELECT returned at end if any |

---

## 8. Sample Queries

### 8.1 Migrate order sentinel rates for a specific instrument

```sql
EXEC Trade.RolloutAboveDollarPrecisionForOrders
    @InstrumentID = 1234,
    @OldPrecision = 4,
    @NewNOSLPrecision = 2
```

### 8.2 Preview orders that would be affected by the migration

```sql
DECLARE @OldPrecision INT = 4
DECLARE @OnePip DECIMAL(8,6) = 1.00 / POWER(10, @OldPrecision)

SELECT OrderID, InstrumentID, StopLosRate, TakeProfitRate
FROM Trade.Orders WITH (NOLOCK)
WHERE InstrumentID = 1234
    AND (StopLosRate = @OnePip OR TakeProfitRate = @OnePip)
```

### 8.3 Verify migration completed (count remaining old sentinel rates)

```sql
DECLARE @OnePip DECIMAL(8,6) = 1.00 / POWER(10, 4)  -- old precision
SELECT COUNT(*) AS RemainingOldSentinels
FROM Trade.Orders WITH (NOLOCK)
WHERE InstrumentID = 1234
    AND (StopLosRate = @OnePip OR TakeProfitRate = @OnePip)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RolloutAboveDollarPrecisionForOrders | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.RolloutAboveDollarPrecisionForOrders.sql*
