# Trade.RoundByPrecisions_ForDebug

> Debug variant of the rate rounding function that rounds prices using different precision levels for sub-dollar and above-dollar rates, with direction-aware ceiling/floor rounding for buy/sell scenarios.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DECIMAL(38,15) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.RoundByPrecisions_ForDebug is a debug/test version of the rate rounding function used throughout the eToro trading platform. It rounds a market rate (price) to the correct number of decimal places based on whether the rate is above or below $1.00, and whether the position is a buy or sell. This dual-precision rounding is necessary because low-priced assets (penny stocks, some crypto) need more decimal places than higher-priced assets.

The function exists because the trading platform must present consistent, correctly-rounded prices to users and internal systems. Different instruments have different precision requirements, and the rounding direction matters: BUY rates round UP (ceiling) to protect the platform from undercharging, while SELL rates round DOWN (floor) to avoid overpaying. The "_ForDebug" suffix indicates this is used for testing and debugging the rounding logic.

This is a pure mathematical function with no table dependencies. Called by Trade.SplitbyJob, which processes stock split operations where rates need re-rounding after split adjustments.

---

## 2. Business Logic

### 2.1 Dual-Precision Rate Rounding

**What**: Applies different precision levels based on the rate magnitude and rounds directionally based on buy/sell.

**Columns/Parameters Involved**: `@Rate`, `@Precision`, `@AboveDollarPrecision`, `@IsBuy`

**Rules**:
- If @Rate <= 1.00 (sub-dollar): use @Precision decimal places
- If @Rate > 1.00 (above-dollar): use @AboveDollarPrecision decimal places (typically fewer)
- If @IsBuy = 1: CEILING rounding (round up) - ensures platform does not sell to buyer at a rate lower than market
- If @IsBuy = 0: FLOOR rounding (round down) - ensures platform does not buy from seller at a rate higher than market
- Multiplier = POWER(10, CurrentPrecision): shifts decimal places for CEILING/FLOOR, then shifts back

**Diagram**:
```
  @Rate
    |
    v
  <= $1.00? --> Use @Precision (more decimal places, e.g., 4)
  >  $1.00? --> Use @AboveDollarPrecision (fewer decimal places, e.g., 2)
    |
    v
  @IsBuy = 1? --> CEILING(@Rate * 10^Prec) / 10^Prec  (round UP)
  @IsBuy = 0? --> FLOOR(@Rate * 10^Prec) / 10^Prec    (round DOWN)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Rate | DECIMAL(38,15) | NO | - | CODE-BACKED | The raw market rate (price) to be rounded. Can be any positive decimal value representing an instrument's price. |
| 2 | @Precision | INT | NO | - | CODE-BACKED | Number of decimal places to use when @Rate <= $1.00 (sub-dollar assets). Typically 4-8 for penny stocks and low-priced crypto. Sourced from Trade.ProviderToInstrument.Precision. |
| 3 | @AboveDollarPrecision | INT | NO | - | CODE-BACKED | Number of decimal places to use when @Rate > $1.00 (above-dollar assets). Typically 2-4. Fewer places are needed for higher-priced assets. |
| 4 | @IsBuy | BIT | NO | - | CODE-BACKED | Position direction: 1 = BUY (CEILING rounding - rounds up to protect platform), 0 = SELL (FLOOR rounding - rounds down to protect platform). |
| 5 | Return value | DECIMAL(38,15) | NO | - | CODE-BACKED | The rounded rate with the appropriate number of decimal places and directional rounding applied. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a pure mathematical function.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SplitbyJob | Function call | Called | Used during stock split processing to re-round rates after split ratio adjustments |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SplitbyJob | Stored Procedure | Calls this function to round adjusted rates during stock split processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Round a sub-dollar BUY rate with 4 decimal precision
```sql
SELECT Trade.RoundByPrecisions_ForDebug(0.34567, 4, 2, 1) AS RoundedBuyRate
```

### 8.2 Round an above-dollar SELL rate with 2 decimal precision
```sql
SELECT Trade.RoundByPrecisions_ForDebug(1.34567, 4, 2, 0) AS RoundedSellRate
```

### 8.3 Compare BUY vs SELL rounding
```sql
SELECT Trade.RoundByPrecisions_ForDebug(1.34567, 4, 2, 1) AS BuyRounded,
       Trade.RoundByPrecisions_ForDebug(1.34567, 4, 2, 0) AS SellRounded
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RoundByPrecisions_ForDebug | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.RoundByPrecisions_ForDebug.sql*
