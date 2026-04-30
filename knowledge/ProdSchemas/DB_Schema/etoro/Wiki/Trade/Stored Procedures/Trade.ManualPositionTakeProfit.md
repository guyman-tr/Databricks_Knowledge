# Trade.ManualPositionTakeProfit

> Manual-use utility procedure that applies a new take-profit (limit) rate to a single open position, resolving the USD conversion rate before delegating to the standard TP-edit routine.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (position to update), @LimitRate (new take-profit rate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a manual interface for setting or changing the take-profit (limit) rate on a specific open position. It mirrors the pattern of `Trade.ManualPositionStopLoss` but targets the take-profit level instead of stop-loss. Like its counterpart, it is designed for ad-hoc use by operations staff and is NOT called by application code.

The procedure exists so that operators can modify a position's TP rate without needing to separately compute the USD conversion rate. It encapsulates the currency-pair resolution logic and calls `Trade.PositionEditTakeProfit` with all required parameters pre-filled.

Data flow: The caller provides a @PositionID and target @LimitRate. The procedure reads the position's currency pair from `Trade.Position` + `Trade.Instrument`, resolves the appropriate USD conversion rate from `Trade.CurrencyPrice`, overrides @LastOpConversionRateID and @LastOpPriceRateID to 1 (regardless of what was found), then calls `Trade.PositionEditTakeProfit` with NetProfit=0 and IsInitiatedByUser=1.

---

## 2. Business Logic

### 2.1 USD Conversion Rate Resolution

**What**: Normalizes the instrument's settlement currency to USD for the PositionEditTakeProfit call.

**Columns/Parameters Involved**: `@SellCurrencyID`, `@BuyCurrencyID`, `@ProviderID`, `@LastOpConversionRate`, `@LastOpConversionRateID`

**Rules**:
- Identical logic to `Trade.ManualPositionStopLoss`:
  - USD on either side (SellCurrencyID=1 or BuyCurrencyID=1): ConversionRate = 1
  - Cross pair - inverse route found (BuyCurrencyID=1, SellCurrencyID=X): ConversionRate = 1/Bid
  - Cross pair - direct route (SellCurrencyID=1, BuyCurrencyID=X): ConversionRate = Bid
- Position query uses partition hint: `AND @PositionID%50=PartitionCol` (Trade.Position is partitioned by PositionID mod 50)
- After rate resolution: both @LastOpConversionRateID and @LastOpPriceRateID are hardcoded to 1 (overrides the fetched PriceRateID)

**Diagram**:
```
SellCurrencyID=1 OR BuyCurrencyID=1 -> ConversionRate = 1
Else: BuyCurrencyID=1, SellCurrencyID=X -> ConversionRate = 1/Bid (inverse)
      SellCurrencyID=1, BuyCurrencyID=X -> ConversionRate = Bid (direct)

Post-resolution: @LastOpConversionRateID = 1, @LastOpPriceRateID = 1 (hardcoded)
```

### 2.2 Zero-Delta TP Edit

**What**: Sets a new take-profit rate with no P&L change - pure level repositioning.

**Columns/Parameters Involved**: `@NetProfit` (= 0), `@IsInitiatedByUser` (= 1), `@ErrOut`

**Rules**:
- @NetProfit = 0: no P&L is recorded for the TP change itself
- @IsInitiatedByUser = 1: flagged as user-initiated (not system-triggered)
- @ErrOut is an OUTPUT parameter passed to Trade.PositionEditTakeProfit for any error message
- @Amount parameter does not exist in this SP (TP edits never require capital changes, unlike SL edits)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | The unique identifier of the open position whose take-profit rate is to be modified. Used to look up the position in Trade.Position with the partition hint `@PositionID%50=PartitionCol`. |
| 2 | @LimitRate | dtPrice | NO | - | CODE-BACKED | The new take-profit (limit) rate to apply, in the instrument's quote currency. Passed to Trade.PositionEditTakeProfit as the new TP level. dtPrice is a Trade-schema UDT for price precision. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.Position | JOIN (READ) | Gets InstrumentID, ProviderID, currency IDs for the target position; uses partition hint |
| Internal | Trade.Instrument | JOIN (READ) | Gets SellCurrencyID and BuyCurrencyID; also queried for cross-rate instrument lookup |
| Internal | Trade.CurrencyPrice | JOIN (READ) | Gets current Bid price for conversion rate, filtered by ProviderID |
| Internal | Trade.PositionEditTakeProfit | EXEC (CALL) | Core delegate: applies the new @LimitRate with NetProfit=0, IsInitiatedByUser=1, resolved conversion rate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| etoro/etoro/UsersPermissions/PROD_BIadmins.sql | GRANT EXECUTE | Permission | PROD_BIadmins role granted EXECUTE permission |

No application code callers found - ad-hoc manual utility only.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ManualPositionTakeProfit (procedure)
+-- Trade.Position (view) [READ - position + instrument currency data]
+-- Trade.Instrument (table) [READ - currency IDs, cross-rate instrument lookup]
+-- Trade.CurrencyPrice (table) [READ - current Bid price for conversion]
+-- Trade.PositionEditTakeProfit (procedure) [EXEC - actual TP level update]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT with partition hint to get InstrumentID, ProviderID, SellCurrencyID, BuyCurrencyID |
| Trade.Instrument | Table | Joined to Trade.Position for currency IDs; queried for cross-rate pair discovery |
| Trade.CurrencyPrice | Table | Joined for current Bid price, filtered by @ProviderID |
| Trade.PositionEditTakeProfit | Stored Procedure | Called with resolved conversion rate to apply the new limit rate |

### 6.2 Objects That Depend On This

No dependents found - standalone manual utility procedure.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Partition hint filter | Query optimization | `@PositionID%50=PartitionCol` routes the position lookup to the correct partition of Trade.Position (added 08/02/21) |
| @LastOpConversionRateID hardcoded | Behavior | Post-resolution, both @LastOpConversionRateID and @LastOpPriceRateID are set to 1 regardless of the actual PriceRateID fetched |

---

## 8. Sample Queries

### 8.1 Apply a new take-profit rate to a specific position
```sql
EXEC Trade.ManualPositionTakeProfit
    @PositionID = 123456789,
    @LimitRate  = 115.50;
```

### 8.2 Verify current TP level and instrument for a position
```sql
SELECT
    p.PositionID,
    p.InstrumentID,
    i.InstrumentDisplayName,
    p.LimitRate       AS CurrentTP,
    p.StopRate        AS CurrentSL,
    p.Amount,
    p.StatusID
FROM Trade.Position p WITH (NOLOCK)
INNER JOIN Trade.Instrument i WITH (NOLOCK) ON p.InstrumentID = i.InstrumentID
WHERE p.PositionID = 123456789;
```

### 8.3 Check conversion rates for cross-currency instruments
```sql
SELECT
    i.InstrumentDisplayName,
    i.SellCurrencyID,
    i.BuyCurrencyID,
    cp.Bid,
    cp.Ask,
    cp.PriceRateID
FROM Trade.CurrencyPrice cp WITH (NOLOCK)
INNER JOIN Trade.Instrument i WITH (NOLOCK) ON cp.InstrumentID = i.InstrumentID
WHERE (i.BuyCurrencyID = 1 OR i.SellCurrencyID = 1)
  AND cp.ProviderID = 1
ORDER BY i.InstrumentDisplayName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (PositionEditTakeProfit) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ManualPositionTakeProfit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ManualPositionTakeProfit.sql*
