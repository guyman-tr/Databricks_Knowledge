# Trade.FnGetCurrentClosingRate

> Returns the current live closing rate, opening rate, and PriceRateID for a position based on direction (buy/sell) and real/CFD classification, selecting the appropriate bid/ask and discounted/standard price.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with CurrentClosingRate, CurrentOpeningRate, PriceRateID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FnGetCurrentClosingRate returns the live market rate at which a position would close right now. The closing rate depends on the position direction (buy positions close at bid, sell positions close at ask) and whether the position is real or CFD (real positions use discounted rates, CFD positions use standard rates). The function also returns the opposite-direction rate (opening rate) and the PriceRateID for audit trails.

This function is critical for live PnL calculation. It feeds directly into Trade.FnCalculateCurrentPnL (as the @EndRate parameter) and indirectly into the Trade.PnL view. Without it, the platform cannot display accurate real-time profit/loss for open positions.

The function calls Trade.FnIsRealPosition to classify the position, then reads the appropriate price column from Trade.CurrencyPrice based on the direction/classification matrix.

---

## 2. Business Logic

### 2.1 Price Selection Matrix

**What**: Selects the correct price from CurrencyPrice based on direction and real/CFD classification.

**Columns/Parameters Involved**: `@IsBuy`, `@IsSettled`, `@InstrumentID`, `CurrencyPrice.Bid/Ask/BidDiscounted/AskDiscounted`

**Rules**:

| Direction | Classification | Closing Rate | Opening Rate |
|-----------|---------------|-------------|-------------|
| Buy (1) | CFD (IsRealPosition=0) | Bid | Ask |
| Buy (1) | Real (IsRealPosition=1) | BidDiscounted | AskDiscounted |
| Sell (0) | CFD (IsRealPosition=0) | Ask | Bid |
| Sell (0) | Real (IsRealPosition=1) | AskDiscounted | BidDiscounted |

- Buy positions close at bid (sell to market), sell positions close at ask (buy from market)
- Real positions use discounted rates (narrower spread for actual asset ownership)
- @EstimatedClosingMarkups parameter is accepted but not used in the current implementation

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsBuy | BIT | NO | - | VERIFIED | Position direction: 1 = Buy (closes at bid), 0 = Sell (closes at ask). |
| 2 | @IsSettled | BIT | NO | - | VERIFIED | Legacy settlement flag. Passed to FnIsRealPosition to determine if real or CFD. 1 = real stock, 0 = CFD. |
| 3 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument to get pricing for. Used to filter CurrencyPrice and passed to FnIsRealPosition. |
| 4 | @EstimatedClosingMarkups | decimal | NO | - | CODE-BACKED | Estimated closing markups. Accepted but not used in current implementation. |
| 5 | CurrentClosingRate (return) | dbo.dtPrice | NO | - | VERIFIED | Live rate at which the position would close now. Bid for buys, Ask for sells. Discounted variant for real positions. |
| 6 | CurrentOpeningRate (return) | dbo.dtPrice | NO | - | CODE-BACKED | Live rate for the opposite direction (what it would cost to re-open). Ask for buys, Bid for sells. |
| 7 | PriceRateID (return) | BIGINT | NO | - | CODE-BACKED | CurrencyPrice.PriceRateID for audit trail and rate versioning. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.CurrencyPrice | FROM/WHERE | Reads live bid/ask prices |
| @IsSettled, @InstrumentID | Trade.FnIsRealPosition | CROSS APPLY | Determines real vs CFD classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FnCalculateCurrentPnL | CROSS APPLY | Function call | Provides current closing rate for live PnL |
| Trade.FnCalculatePnLByRates | CROSS APPLY | Function call | Provides fallback closing rate when explicit rate is NULL |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FnGetCurrentClosingRate (function)
  ├── Trade.CurrencyPrice (table)
  └── Trade.FnIsRealPosition (function)
        └── Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | FROM: reads live bid/ask/discounted prices |
| Trade.FnIsRealPosition | Function | CROSS APPLY: determines real vs CFD |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FnCalculateCurrentPnL | Function | CROSS APPLY for live PnL |
| Trade.FnCalculatePnLByRates | Function | CROSS APPLY for rate fallback |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning 3 columns |
| WITH (NOLOCK) | Read hint | CurrencyPrice read with NOLOCK |

---

## 8. Sample Queries

### 8.1 Get current closing rate for a buy CFD position

```sql
SELECT  CurrentClosingRate, CurrentOpeningRate, PriceRateID
FROM    Trade.FnGetCurrentClosingRate(1, 0, 1001, 0);
```

### 8.2 Show closing rates for all open positions of a customer

```sql
SELECT  p.PositionID, p.InstrumentID, p.IsBuy,
        cr.CurrentClosingRate, cr.CurrentOpeningRate
FROM    Trade.PositionTbl p WITH (NOLOCK)
        CROSS APPLY Trade.FnGetCurrentClosingRate(p.IsBuy, p.IsSettled, p.InstrumentID, 0) cr
WHERE   p.CID = 12345678 AND p.StatusID = 1;
```

### 8.3 Compare standard vs discounted rates

```sql
SELECT  'CFD' AS Type, cr_cfd.CurrentClosingRate FROM Trade.FnGetCurrentClosingRate(1, 0, 1001, 0) cr_cfd
UNION ALL
SELECT  'REAL', cr_real.CurrentClosingRate FROM Trade.FnGetCurrentClosingRate(1, 1, 1001, 0) cr_real;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FnGetCurrentClosingRate | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FnGetCurrentClosingRate.sql*
