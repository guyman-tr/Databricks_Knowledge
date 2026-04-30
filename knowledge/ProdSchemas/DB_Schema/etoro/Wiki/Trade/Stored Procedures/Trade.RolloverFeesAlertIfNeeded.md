# Trade.RolloverFeesAlertIfNeeded

> Detects suspicious rollover/overnight fee changes by comparing current InstrumentToFeeConfigV2 values against the previous configuration, alerting when a fee changes by more than the instrument-type threshold and cross-checking against price movement to distinguish fee adjustments from errors.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsAlertTriggered BIT OUTPUT - indicates whether any fee anomalies were detected |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Rollover fees (overnight fees and end-of-week fees) are the cost charged to leveraged positions for holding them beyond daily/weekly market close. These fees are set per instrument and are regularly updated based on underlying asset borrowing costs. However, if a fee update is incorrect - too large a change - it could cause excessive charges to customers or risk miscalculation.

This procedure monitors every fee update in `Trade.InstrumentToFeeConfigV2` by comparing each new record against its immediate predecessor (via the BeginTime/EndTime temporal chain). When ANY of the 8 fee columns changes by more than the configured threshold percentage (`Trade.RolloverFeeAlertThreshold`), an alert is triggered.

A sophisticated cross-check feature compares the fee change percentage against the underlying instrument's price change percentage over the same period (using `dbo.HistoryClosingPrices`). If fee change approximately equals price change (within 1%), the `CheckResult` column shows 'OK' - meaning the fee change was expected and proportional to market movement. Otherwise ' - ' flags it for human review.

The email recipient list is dynamically read from `Maintenance.Feature` FeatureID=113. The procedure was updated in 2022 to use Azure PriceLog for better performance.

---

## 2. Business Logic

### 2.1 Fee Change Threshold Detection

**What**: Compares current vs previous fee records and flags changes exceeding the per-instrument-type threshold.

**Columns/Parameters Involved**: `Trade.InstrumentToFeeConfigV2`, `History.InstrumentToFeeConfigV2`, `Trade.RolloverFeeAlertThreshold.RolloverFeeThreshold`, `Trade.InstrumentMetaData.InstrumentTypeID`

**Rules**:
- Joins current (Trade) and previous (History) fee records via `curr.BeginTime = prev.EndTime` (temporal chain)
- Calculates change% using `Trade.GetChangePercent(current, previous)` for all 8 fee types
- Threshold is per-InstrumentTypeID from RolloverFeeAlertThreshold
- Only InstrumentTypeID 5 and 6 are checked (ETFs/stocks - comment indicates this filter)
- Ignores updates where UpdatedByUser = 'split' (automated split process updates are excluded)
- Ignores non-tradable instruments and instruments VisibleInternallyOnly=1

### 2.2 Price Change Cross-Validation

**What**: Validates that a fee change is justified by comparing it against the underlying price movement.

**Columns/Parameters Involved**: `dbo.HistoryClosingPrices.Bid`, `CheckResult`

**Rules**:
- Gets current price (TOP 1 most recent from HistoryClosingPrices) and previous price (OFFSET 1 from same)
- `PriceDiffPercent` = Trade.GetChangePercent(CurrentPrice, PreviousPrice)
- `CheckResult` = 'OK' if ABS(ABS(PriceDiffPercent) - ABS(FeeChangePercent)) <= 1
- 'OK' means fee change is proportional to price change (expected behavior)
- ' - ' means fee change cannot be explained by price movement (potential error)

**Diagram**:
```
Fee changed by +15%? Check:
  Price also changed by ~15%? -> CheckResult = 'OK' (proportional, expected)
  Price changed by +2%?       -> CheckResult = ' - ' (suspicious, needs review)
```

### 2.3 Dynamic Email Recipients

**What**: Email recipient list is configurable without code changes via Maintenance.Feature.

**Rules**:
- Recipients read from Maintenance.Feature WHERE FeatureID=113 (cast to VARCHAR)
- If recipients list is NULL or empty -> no email sent (procedure returns without error)
- Email subject includes server name, database name, and timestamp for environment identification

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsAlertTriggered | BIT OUTPUT | NO | - | CODE-BACKED | Returns 1 if any fee anomalies were detected and the alert was sent; 0 if all fees are within threshold and no email was sent. Allows the caller to know whether action was taken. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| curr | Trade.InstrumentToFeeConfigV2 | Lookup | Current (active) fee configuration records |
| prev | History.InstrumentToFeeConfigV2 | Lookup | Previous fee records, joined via BeginTime=EndTime temporal link |
| meta | Trade.InstrumentMetaData | Lookup | Provides InstrumentTypeID and InstrumentDisplayName |
| thresh | Trade.RolloverFeeAlertThreshold | Lookup | Per-instrument-type alert threshold percentage |
| pti | Trade.ProviderToInstrument | Lookup | Filters to externally-visible, tradable instruments |
| prices | dbo.HistoryClosingPrices | Lookup | Historical bid prices for price-change cross-validation |
| recipients | Maintenance.Feature | Lookup | FeatureID=113: email recipient list |
| function | Trade.GetChangePercent | Callee | Calculates percentage change between two values |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RolloverFeesAlertIfNeeded (procedure)
|- Trade.InstrumentToFeeConfigV2 (table)
|- History.InstrumentToFeeConfigV2 (table)
|- Trade.InstrumentMetaData (view/table)
|- Trade.RolloverFeeAlertThreshold (table)
|- Trade.ProviderToInstrument (table)
|- dbo.HistoryClosingPrices (table)
|- Maintenance.Feature (table)
|- Trade.GetChangePercent (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentToFeeConfigV2 | Table | Current fee values (curr alias) |
| History.InstrumentToFeeConfigV2 | Table | Previous fee values (prev alias) via temporal join |
| Trade.InstrumentMetaData | Table/View | InstrumentTypeID and display name |
| Trade.RolloverFeeAlertThreshold | Table | Alert threshold percentage per instrument type |
| Trade.ProviderToInstrument | Table | Filters to tradable, externally visible instruments |
| dbo.HistoryClosingPrices | Table | Historical price data for cross-validation |
| Maintenance.Feature | Table | FeatureID=113: dynamic email recipient configuration |
| Trade.GetChangePercent | Function | Computes percentage change between fee/price values |

### 6.2 Objects That Depend On This

No dependents found - called by SQL Agent job for monitoring.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Split exclusion | Logic | UpdatedByUser != 'split' - fee changes from split process are excluded from monitoring |
| Tradable filter | Logic | VisibleInternallyOnly=0 AND Tradable=1 - only customer-facing instruments |
| InstrumentType filter | Logic | thresh.InstrumentTypeID IN (5, 6) - only specific instrument types checked |
| CheckResult tolerance | Logic | ABS difference between price% and fee% <= 1 = 'OK', else ' - ' |

---

## 8. Sample Queries

### 8.1 Execute the rollover fee alert check

```sql
DECLARE @AlertTriggered BIT
EXEC Trade.RolloverFeesAlertIfNeeded @IsAlertTriggered = @AlertTriggered OUTPUT
SELECT @AlertTriggered AS WasAlertSent
```

### 8.2 Check current fee change percentages vs thresholds

```sql
SELECT curr.InstrumentID,
    meta.InstrumentDisplayName,
    thresh.RolloverFeeThreshold AS Threshold,
    Trade.GetChangePercent(curr.LeveragedBuyOverNightFee, prev.LeveragedBuyOverNightFee) AS BuyONFee_ChangePercent,
    Trade.GetChangePercent(curr.LeveragedSellOverNightFee, prev.LeveragedSellOverNightFee) AS SellONFee_ChangePercent
FROM Trade.InstrumentToFeeConfigV2 curr WITH (NOLOCK)
INNER JOIN History.InstrumentToFeeConfigV2 prev WITH (NOLOCK)
    ON curr.InstrumentID = prev.InstrumentID AND curr.BeginTime = prev.EndTime
    AND curr.SettlementTypeID = prev.SettlementTypeID
INNER JOIN Trade.InstrumentMetaData meta WITH (NOLOCK) ON meta.InstrumentID = curr.InstrumentID
INNER JOIN Trade.RolloverFeeAlertThreshold thresh WITH (NOLOCK) ON thresh.InstrumentTypeID = meta.InstrumentTypeID
WHERE curr.UpdatedByUser != 'split'
ORDER BY ABS(Trade.GetChangePercent(curr.LeveragedBuyOverNightFee, prev.LeveragedBuyOverNightFee)) DESC
```

### 8.3 Check current rollover fee alert threshold configuration

```sql
SELECT InstrumentTypeID, RolloverFeeThreshold
FROM Trade.RolloverFeeAlertThreshold WITH (NOLOCK)
ORDER BY InstrumentTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RolloverFeesAlertIfNeeded | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.RolloverFeesAlertIfNeeded.sql*
