# Trade.ChangeTreePropertiesPerInstrument

> Batch-adjusts stop-loss, take-profit, and trailing-stop-loss settings for all position trees of a given instrument by applying percentage-based adjustments calculated by Trade.ChangeTreeInfoPerInstrument, filtering by minimum change threshold, and routing each update through Trade.UpdateTree.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID (instrument whose trees are adjusted) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ChangeTreePropertiesPerInstrument is an operational tool that batch-adjusts risk-management settings (stop-loss, take-profit, trailing stop loss) for all position trees on a specific instrument. This is used when market conditions change and multiple trees need their SL/TP rates adjusted by a given percentage.

The procedure uses the Trade.ChangeTreeInfoPerInstrument table-valued function to calculate new SL/TP/TSL values for each tree. It then filters by a minimum percentage change threshold (@MinPercentageChange) and directional safety (buy positions can only widen SL down / widen TP up; sell positions the reverse), before calling Trade.UpdateTree for each qualifying tree. Each modification is logged to History.LogTreesManualModifications.

Uses a CURSOR to iterate through trees, which is necessary because each tree update must be processed individually through Trade.UpdateTree (which handles partition elimination, change logging, and child position broadcasting).

---

## 2. Business Logic

### 2.1 New Rate Calculation

**What**: Uses Trade.ChangeTreeInfoPerInstrument TVF to compute new SL/TP/TSL values.

**Rules**:
- Input: @InstrumentID, @TPPercentage, @SLPercentage, @NewTSL
- Output: CurrentRate, OrigTakeProfit, NewTakeProfit, OrigStopLoss, NewStopLoss, IsTslEnabled per tree
- NewTakeProfit/NewStopLoss are floored to minimum precision (1/10^Precision) if ≤ 0

### 2.2 Directional Safety Filter

**What**: Prevents widening stops in the wrong direction.

**Rules**:
- **Buy positions**: NewStopLoss must be < OrigStopLoss (lower = safer); NewTakeProfit must be > OrigTakeProfit (higher = more profit)
- **Sell positions**: NewStopLoss must be > OrigStopLoss (higher = safer for short); NewTakeProfit must be < OrigTakeProfit (lower = more profit for short)
- If the new value goes in the wrong direction, it's set to NULL (skipped)

### 2.3 Minimum Change Threshold

**What**: Only applies updates that exceed a minimum percentage change.

**Rules**:
- |OrigValue - NewValue| / OrigValue × 100 >= @MinPercentageChange (default: 1%)
- Also requires both OrigStopLoss > 0 and OrigTakeProfit > 0 (excludes trees with no SL/TP)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | VERIFIED | Instrument whose position trees will be adjusted. |
| 2 | @SLPercentage | INT | NO | - | CODE-BACKED | Percentage to adjust stop-loss rates by. Applied via Trade.ChangeTreeInfoPerInstrument. |
| 3 | @TPPercentage | INT | NO | - | CODE-BACKED | Percentage to adjust take-profit rates by. Applied via Trade.ChangeTreeInfoPerInstrument. |
| 4 | @NewTSL | INT | YES | NULL | CODE-BACKED | New trailing stop loss setting to apply. NULL means don't change TSL. |
| 5 | @MinPercentageChange | TINYINT | YES | 1 | CODE-BACKED | Minimum percentage change required before applying the update. Filters out insignificant changes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.ProviderToInstrument | SELECT | Gets instrument Precision for rate flooring |
| FROM | Trade.ChangeTreeInfoPerInstrument | TVF | Calculates new SL/TP/TSL values per tree |
| EXEC | Trade.UpdateTree | EXEC | Applies the update to each individual tree |
| INSERT | History.LogTreesManualModifications | INSERT | Logs each modification for audit |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found in SSDT) | - | - | Called from admin tools or scheduled jobs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ChangeTreePropertiesPerInstrument (procedure)
+-- Trade.ProviderToInstrument (table)
+-- Trade.ChangeTreeInfoPerInstrument (function)
+-- Trade.UpdateTree (procedure)
+-- History.LogTreesManualModifications (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | SELECT - instrument precision |
| Trade.ChangeTreeInfoPerInstrument | TVF | SELECT - calculates adjusted values |
| Trade.UpdateTree | Procedure | EXEC - applies updates per tree |
| History.LogTreesManualModifications | Table | INSERT - audit log |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found in SSDT) | - | Called from application/admin layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Rate flooring | Safety | New rates floored to 1/10^Precision if ≤ 0 |
| Directional filter | Safety | Prevents widening stops in wrong direction for buy/sell |
| Min change threshold | Filter | Skips trees with < @MinPercentageChange% difference |

---

## 8. Sample Queries

### 8.1 Preview what would be changed

```sql
SELECT  TreeID, CurrentRate, OrigTakeProfit, NewTakeProfit, OrigStopLoss, NewStopLoss, IsTslEnabled
FROM    Trade.ChangeTreeInfoPerInstrument(1001, 10, 10, NULL)
WHERE   ABS(OrigStopLoss - NewStopLoss) * 100 / OrigStopLoss >= 1
        AND OrigStopLoss > 0 AND OrigTakeProfit > 0;
```

### 8.2 Execute batch adjustment

```sql
EXEC Trade.ChangeTreePropertiesPerInstrument
    @InstrumentID = 1001,
    @SLPercentage = 10,
    @TPPercentage = 10,
    @NewTSL = NULL,
    @MinPercentageChange = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ChangeTreePropertiesPerInstrument | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ChangeTreePropertiesPerInstrument.sql*
