# Trade.OldAndNewTakeProfitPerInstrumentID

> Multi-statement TVF that calculates new capped take-profit rates for positions on a given instrument, comparing original TP rates with a maximum TP rate derived from current market prices and a configurable percentage limit.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table-Valued Function |
| **Key Identifier** | Returns TABLE(TreeID, CurrentRate, OrigTakeProfit, MaxTakeProfitRate, TpPNLDelta, ...) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OldAndNewTakeProfitPerInstrumentID identifies positions whose take-profit (TP) targets may need to be adjusted due to market price changes. For each non-mirror (manual) position on a given instrument, it computes a "maximum allowed take-profit rate" based on the current market price plus a configurable percentage cap (default 200%). If the original TP rate exceeds this cap, the function returns the capped value instead.

This function was created for scenarios where extreme take-profit values could pose risk - such as during Brexit or other high-volatility events where positions might have unrealistically high TP targets. The procedure Trade.UpdatePositionsTakeProfitByInstrumentID uses this function's output to programmatically adjust take-profit rates using Trade.PositionEditTakeProfit, logging each change to History.SystemUpdatePositionTakeProfit and History.BrexitModifiedPositions.

The function reads from Trade.Position (active positions), Trade.CurrencyPrice (current bid/ask), Trade.ProviderToInstrument (precision), and Customer.CustomerStatic (customer details). It also calls Trade.GetMinorConversionRate to convert amounts to base currency. Only positions where MirrorID=0 (manual, not copy-traded) are included.

---

## 2. Business Logic

### 2.1 Maximum Take-Profit Rate Calculation

**What**: Caps take-profit rates at a maximum distance from the current market price, expressed as a percentage of the position's invested amount.

**Columns/Parameters Involved**: `@RateDiffPercentage`, `CurrentRate`, `Amount`, `AmountInUnitsDecimal`, `@ConversionRate`, `IsBuy`, `LimitRate`

**Rules**:
- MaxTakeProfitRate formula for BUY: CurrentBid + (@RateDiffPercentage/100 * Amount) / (Units * ConversionRate)
- MaxTakeProfitRate formula for SELL: CurrentAsk - (@RateDiffPercentage/100 * Amount) / (Units * ConversionRate)
- If calculated MaxTP is more favorable than original TP (closer to current price), use the calculated cap
- If original TP is already within the cap, keep the original TP unchanged
- Division-by-zero protection: if (Units * ConversionRate) = 0, MaxTP = LimitRate (original TP preserved)
- All rates are rounded to the instrument's Precision (from ProviderToInstrument)
- Default @RateDiffPercentage = 200 means max TP at 200% of invested amount distance from current price

**Diagram**:
```
  BUY position:
  Current Bid ----[max distance = (200% * Amount)/(Units * ConvRate)]----> MaxTP
       |                                                                     |
       v                                                                     v
  If OrigTP > MaxTP --> return MaxTP (cap applied)
  If OrigTP <= MaxTP --> OrigTP = MaxTP (no change, filtered out)

  SELL position:
  MaxTP <----[max distance = (200% * Amount)/(Units * ConvRate)]---- Current Ask
       |                                                                     |
       v                                                                     v
  If OrigTP < MaxTP --> return MaxTP (cap applied)
  If OrigTP >= MaxTP --> OrigTP = MaxTP (no change, filtered out)
```

### 2.2 TpPNLDelta Calculation

**What**: Computes the P&L impact of changing the take-profit rate from original to capped value.

**Columns/Parameters Involved**: `OrigTakeProfit`, `MaxTakeProfitRate`, `AmountInUnitsDecimal`, `@ConversionRate`, `IsBuy`

**Rules**:
- For BUY: TpPNLDelta = (OrigTakeProfit - MaxTakeProfitRate) * (Units * ConversionRate)
- For SELL: TpPNLDelta = (MaxTakeProfitRate - OrigTakeProfit) * (Units * ConversionRate)
- Only positions where OrigTakeProfit != MaxTakeProfitRate are included in the final output
- Positive delta means the customer is giving up potential profit due to the cap

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument identifier to process. All open positions for this instrument where MirrorID=0 will be evaluated. FK to Trade.Instrument. |
| 2 | @RateDiffPercentage | DECIMAL(16,8) | NO | 200 | CODE-BACKED | Maximum allowed take-profit distance as a percentage of invested amount (Amount column). Default 200 means TP cannot exceed 200% of the position's invested dollar amount converted to rate distance. |
| 3 | @PositionID | BIGINT | YES | NULL | CODE-BACKED | Optional filter to evaluate a single position instead of all positions on the instrument. When NULL, all manual positions on the instrument are processed. |
| 4 | TreeID (return) | BIGINT | NO | - | CODE-BACKED | The position identifier (PositionID from Trade.Position). Used as the primary key for cursor processing in Trade.UpdatePositionsTakeProfitByInstrumentID. |
| 5 | CurrentRate (return) | dtPrice | NO | - | CODE-BACKED | Current market rate for this position: Bid for BUY positions, Ask for SELL positions. Retrieved from Trade.CurrencyPrice. |
| 6 | OrigTakeProfit (return) | dtPrice | NO | - | CODE-BACKED | The position's original take-profit rate (LimitRate from Trade.Position). This is the rate that would be compared against MaxTakeProfitRate. |
| 7 | MaxTakeProfitRate (return) | dtPrice | NO | - | CODE-BACKED | The capped maximum take-profit rate. If the original TP exceeds this, it will be reduced to this value. Rounded to instrument precision. |
| 8 | TpPNLDelta (return) | dtPrice | NO | - | CODE-BACKED | The P&L impact in account currency of reducing the TP from original to capped value. Positive = customer loses potential upside. |
| 9 | CID (return) | INT | NO | - | CODE-BACKED | Customer identifier from Trade.Position. Joined to Customer.CustomerStatic for contact details. |
| 10 | UserName (return) | VARCHAR(20) | YES | - | CODE-BACKED | Customer's username from Customer.CustomerStatic. Included for operational reporting and communication. |
| 11 | Email (return) | VARCHAR(50) | YES | - | CODE-BACKED | Customer's email from Customer.CustomerStatic. Included for notification purposes when TP is adjusted. |
| 12 | Units (return) | DECIMAL(16,6) | NO | - | CODE-BACKED | Position size in instrument units (AmountInUnitsDecimal from Trade.Position). Used in MaxTP rate calculation formula. |
| 13 | Amount (return) | MONEY | NO | - | CODE-BACKED | Position invested dollar amount from Trade.Position. The @RateDiffPercentage applies to this amount to determine max TP distance. |
| 14 | Leverage (return) | INT | NO | - | CODE-BACKED | Position leverage multiplier from Trade.Position. Included for reference/reporting. |
| 15 | Language (return) | VARCHAR(50) | YES | - | CODE-BACKED | Customer's preferred language name from Dictionary.Language (joined via CustomerStatic.LanguageID). Used for localized notifications. |
| 16 | FirstName (return) | NVARCHAR(100) | YES | - | CODE-BACKED | Customer's first name from Customer.CustomerStatic. Used for personalized communications about TP changes. |
| 17 | GCID (return) | INT | YES | - | CODE-BACKED | Global Customer ID from Customer.CustomerStatic. Cross-system customer identifier. |
| 18 | IsBuy (return) | INT | NO | - | CODE-BACKED | Position direction: 1 = BUY (long), 0 = SELL (short). Determines whether TP cap is applied above (BUY) or below (SELL) current market price. |
| 19 | InstrumentID (return) | INT | NO | - | CODE-BACKED | The instrument identifier (echoed from @InstrumentID parameter). Included for completeness in result set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.ProviderToInstrument | SELECT (WHERE) | Retrieves instrument precision for rate rounding |
| @InstrumentID | Trade.GetMinorConversionRate | Function call | Gets currency conversion rate from instrument currency to USD |
| PositionID | Trade.Position | FROM (WHERE) | Source of all open positions filtered by instrument and MirrorID=0 |
| InstrumentID | Trade.CurrencyPrice | INNER JOIN | Current Bid/Ask rates for the instrument |
| CID | Customer.CustomerStatic | INNER JOIN | Customer contact details for notification/reporting |
| LanguageID | Dictionary.Language | INNER JOIN | Language name lookup for customer's preferred language |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdatePositionsTakeProfitByInstrumentID | FROM clause | Function call | Primary consumer: iterates results via cursor to update each position's TP using Trade.PositionEditTakeProfit |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OldAndNewTakeProfitPerInstrumentID (function)
  +-- Trade.ProviderToInstrument (table)
  +-- Trade.GetMinorConversionRate (function)
  +-- Trade.Position (view)
  |     +-- Trade.PositionTbl (table)
  +-- Trade.CurrencyPrice (table)
  +-- Customer.CustomerStatic (table)
  +-- Dictionary.Language (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | SELECT Precision for rate rounding |
| Trade.GetMinorConversionRate | Scalar Function | Called to get currency conversion rate for P&L calculations |
| Trade.Position | View | FROM clause - source of open positions filtered by instrument |
| Trade.CurrencyPrice | Table | INNER JOIN to get current Bid/Ask market prices |
| Customer.CustomerStatic | Table | INNER JOIN for customer contact details (CID, UserName, Email, FirstName, GCID, LanguageID) |
| Dictionary.Language | Table | INNER JOIN to resolve LanguageID to language Name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdatePositionsTakeProfitByInstrumentID | Stored Procedure | Calls this function and iterates results to update take-profit rates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Preview TP adjustments for an instrument
```sql
SELECT TreeID, CurrentRate, OrigTakeProfit, MaxTakeProfitRate, TpPNLDelta, CID, UserName
FROM   Trade.OldAndNewTakeProfitPerInstrumentID(1001, DEFAULT, DEFAULT)
```

### 8.2 Check adjustments with a custom percentage cap
```sql
SELECT TreeID, OrigTakeProfit, MaxTakeProfitRate, TpPNLDelta
FROM   Trade.OldAndNewTakeProfitPerInstrumentID(1001, 150.00000000, NULL)
WHERE  OrigTakeProfit <> MaxTakeProfitRate
```

### 8.3 Review specific position's TP cap
```sql
SELECT T.TreeID,
       T.CurrentRate,
       T.OrigTakeProfit,
       T.MaxTakeProfitRate,
       T.TpPNLDelta,
       T.UserName,
       T.Email,
       T.Language
FROM   Trade.OldAndNewTakeProfitPerInstrumentID(1001, 200.00000000, 123456789) T
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Supporting Services - Multi-Currency Changes](https://etoro.atlassian.net) | Confluence | Context on conversion rate usage in take-profit calculations across multiple currencies |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OldAndNewTakeProfitPerInstrumentID | Type: Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.OldAndNewTakeProfitPerInstrumentID.sql*
