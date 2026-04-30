# Trade.CalculatePositionOvernightFee

> Calculates the overnight or end-of-week holding fee for a single position based on direction, leverage, settlement type, instrument fee configuration, and fee calculation method.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DECIMAL(16,8) - fee amount |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CalculatePositionOvernightFee computes the overnight holding fee (also called rollover or swap fee) for a single open position. Holding fees are charged daily for leveraged positions and some non-leveraged positions to reflect the cost of financing/borrowing. The fee varies by direction (buy/sell), leverage level (leveraged vs non-leveraged), settlement type (CFD vs real), and time period (daily overnight vs weekend/end-of-week).

This function exists because overnight fee calculation involves a complex matrix of 8 possible fee rates (2 directions x 2 leverage levels x 2 time periods) plus special rules for CFD non-leveraged buy positions and two different fee calculation methods. Centralizing this logic ensures consistent fee computation across the daily fee process, position projections, and close-time fee estimation.

All fee rate parameters come from Trade.InstrumentToFeeConfig, which the caller resolves before invoking this function. The function itself is a pure calculation with no table dependencies - it receives all data as parameters.

---

## 2. Business Logic

### 2.1 Fee Rate Selection Matrix

**What**: Selects the appropriate fee rate from 8 possible rates based on position characteristics.

**Columns/Parameters Involved**: `@IsBuy`, `@Leverage`, `@FeeType`, `@LeveragedBuyOverNightFee`, `@LeveragedSellOverNightFee`, `@LeveragedBuyEndOfWeekFee`, `@LeveragedSellEndOfWeekFee`, `@NonLeveragedBuyOverNightFee`, `@NonLeveragedSellOverNightFee`, `@NonLeveragedBuyEndOfWeekFee`, `@NonLeveragedSellEndOfWeekFee`

**Rules**:
- Sell positions: `Leverage=1 -> NonLeveragedSell*Fee`, `Leverage>1 -> LeveragedSell*Fee`
- Buy positions with `Leverage>1`: `LeveragedBuy*Fee`
- Buy positions with `Leverage=1 AND SettlementTypeID=0 (CFD) AND ExcludeFromNonLeverageBuyCfdFee=1`: fee = 0 (exempt)
- Buy positions with `Leverage=1` (all other cases): `NonLeveragedBuy*Fee`
- @FeeType selects the time period: 1=Overnight (daily), 2=EndOfWeek (weekend)

**Diagram**:
```
@IsBuy=0 (Sell)?
  ├── Leverage=1 -> NonLeveragedSell[Overnight|EndOfWeek]Fee
  └── Leverage>1 -> LeveragedSell[Overnight|EndOfWeek]Fee

@IsBuy=1 (Buy)?
  ├── Leverage>1 -> LeveragedBuy[Overnight|EndOfWeek]Fee
  └── Leverage=1
        ├── SettlementTypeID=0 (CFD) AND Exclude=1 -> 0 (exempt)
        └── Otherwise -> NonLeveragedBuy[Overnight|EndOfWeek]Fee
```

### 2.2 Dual Fee Calculation Methods

**What**: Two different formulas based on FeeCalculationTypeID determine how the fee rate is applied.

**Columns/Parameters Involved**: `@FeeCalculationTypeID`, `@FeeRate`, `@AmountInUnitsDecimal`, `@InitForexRate`, `@InitConversionRate`, `@InvestedAmount`, `@WeekendFeePercentage`

**Rules**:
- **Type 1 (margin-based)**: Fee = (InitRate x InitConvRate x Units - InvestedAmount) x FeeRate x WeekendPct / 100. This charges based on the BORROWED portion only (total position value minus invested amount = margin loan).
- **Type 2 (unit-based)**: Fee = FeeRate x Units x WeekendPct / 100. Simple per-unit fee regardless of leverage or margin.
- WeekendFeePercentage multiplier: typically 1.0 for weekdays, 3.0 for Fridays (covers Saturday + Sunday)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsBuy | TINYINT | NO | - | CODE-BACKED | Trade direction: 1 = Buy, 0 = Sell. Determines which fee rate column to use. |
| 2 | @Leverage | INT | NO | - | CODE-BACKED | Position leverage. 1 = non-leveraged, >1 = leveraged. Selects leveraged vs non-leveraged fee rates. |
| 3 | @SettlementTypeID | INT | NO | - | CODE-BACKED | Settlement type: 0=CFD, 1=REAL, etc. Combined with leverage and ExcludeFlag for CFD buy exemption. |
| 4 | @FeeType | INT | NO | - | CODE-BACKED | Time period: 1 = Overnight (daily), 2 = EndOfWeek (typically Friday). |
| 5 | @LeveragedBuyOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Overnight fee rate for leveraged buy positions. From Trade.InstrumentToFeeConfig. |
| 6 | @LeveragedSellOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Overnight fee rate for leveraged sell positions. |
| 7 | @LeveragedBuyEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | End-of-week fee rate for leveraged buy positions. |
| 8 | @LeveragedSellEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | End-of-week fee rate for leveraged sell positions. |
| 9 | @NonLeveragedBuyOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Overnight fee rate for non-leveraged buy positions. |
| 10 | @NonLeveragedSellOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Overnight fee rate for non-leveraged sell positions. |
| 11 | @NonLeveragedBuyEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | End-of-week fee rate for non-leveraged buy positions. |
| 12 | @NonLeveragedSellEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | End-of-week fee rate for non-leveraged sell positions. |
| 13 | @FeeCalculationTypeID | TINYINT | NO | - | CODE-BACKED | Calculation method: 1 = margin-based (fee on borrowed portion), 2 = unit-based (fee per unit). |
| 14 | @AmountInUnitsDecimal | DECIMAL(16,8) | NO | - | CODE-BACKED | Position size in units. |
| 15 | @InitForexRate | dtPrice | NO | - | CODE-BACKED | Opening price rate. Used in Type 1 to compute total position value. |
| 16 | @InitConversionRate | dtPrice | NO | - | CODE-BACKED | Opening conversion rate. Used in Type 1 to compute position value in account currency. |
| 17 | @InvestedAmount | MONEY | NO | - | CODE-BACKED | Customer's invested amount. Type 1 subtracts this from total value to get the borrowed/margin portion. |
| 18 | @WeekendFeePercentage | DECIMAL(16,8) | NO | - | CODE-BACKED | Multiplier for weekend accrual: typically 1.0 (weekday) or 3.0 (Friday, covers Sat+Sun). |
| 19 | @ExcludeFromNonLeverageBuyCfdFee | BIT | NO | - | CODE-BACKED | 1 = exempt this position from non-leveraged buy CFD overnight fees. Used for specific instrument exclusions. |
| 20 | Return value | DECIMAL(16,8) | NO | - | CODE-BACKED | Calculated overnight/weekend fee amount in account currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Pure calculation function - all data provided as parameters.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Fee process procedures) | Scalar call | Various | Called during nightly fee processing with data from Trade.InstrumentToFeeConfig |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CalculatePositionOvernightFee (function)
(no dependencies - leaf node, pure calculation)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Overnight fee processing procedures) | Procedures | Scalar call with InstrumentToFeeConfig data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS DECIMAL(16,8) | Return type | Scalar function returning fee amount |

---

## 8. Sample Queries

### 8.1 Calculate overnight fee for a leveraged buy position

```sql
SELECT Trade.CalculatePositionOvernightFee(
    1,      -- @IsBuy = Buy
    5,      -- @Leverage = 5x
    0,      -- @SettlementTypeID = CFD
    1,      -- @FeeType = Overnight
    0.0685, -- @LeveragedBuyOverNightFee
    0.0685, -- @LeveragedSellOverNightFee
    0.0685, -- @LeveragedBuyEndOfWeekFee
    0.0685, -- @LeveragedSellEndOfWeekFee
    0.0,    -- @NonLeveragedBuyOverNightFee
    0.0,    -- @NonLeveragedSellOverNightFee
    0.0,    -- @NonLeveragedBuyEndOfWeekFee
    0.0,    -- @NonLeveragedSellEndOfWeekFee
    2,      -- @FeeCalculationTypeID = unit-based
    100.0,  -- @AmountInUnitsDecimal
    150.50, -- @InitForexRate
    1.0,    -- @InitConversionRate
    1000.0, -- @InvestedAmount
    1.0,    -- @WeekendFeePercentage = weekday
    0       -- @ExcludeFromNonLeverageBuyCfdFee
) AS OvernightFee;
```

### 8.2 Compare weekday vs weekend fee

```sql
SELECT  Trade.CalculatePositionOvernightFee(1, 5, 0, 1, 0.07, 0.07, 0.07, 0.07, 0, 0, 0, 0, 2, 100.0, 150.50, 1.0, 1000.0, 1.0, 0) AS WeekdayFee,
        Trade.CalculatePositionOvernightFee(1, 5, 0, 2, 0.07, 0.07, 0.07, 0.07, 0, 0, 0, 0, 2, 100.0, 150.50, 1.0, 1000.0, 3.0, 0) AS WeekendFee;
```

### 8.3 Show fee = 0 for exempt non-leveraged CFD buy

```sql
SELECT Trade.CalculatePositionOvernightFee(
    1, 1, 0, 1,
    0.07, 0.07, 0.07, 0.07,
    0.03, 0.03, 0.03, 0.03,
    2, 100.0, 150.50, 1.0, 1000.0, 1.0,
    1  -- ExcludeFromNonLeverageBuyCfdFee = 1 -> fee = 0
) AS ExemptFee;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CalculatePositionOvernightFee | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.CalculatePositionOvernightFee.sql*
