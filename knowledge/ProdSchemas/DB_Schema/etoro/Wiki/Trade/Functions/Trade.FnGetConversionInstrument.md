# Trade.FnGetConversionInstrument

> Resolves the currency conversion instrument needed to convert a traded instrument's price into the customer's account currency, handling both direct and cross-currency pairs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with `ConversionInstrumentID` (INT) and `IsReciprocal` (INT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FnGetConversionInstrument determines which forex instrument to use for converting a position's value from its native trading currency into the customer's account denomination currency. Since eToro supports multiple account currencies (USD, EUR, GBP, AUD, etc.) and instruments trade in various currency pairs, this function resolves the correct conversion path - either directly through the instrument itself, or via a cross-currency intermediate instrument.

This function is essential because PnL, equity, margin, and fee calculations all require values in the customer's account currency. A customer trading EUR/JPY with a USD account needs a EUR/USD or USD/JPY instrument to convert the PnL. Without this resolution, multi-currency PnL calculations would fail for non-USD-denominated accounts and for instruments not directly paired with the account currency.

The function is consumed primarily by Trade.FnGetCurrentConversionRate (which uses the resolved instrument to fetch the actual conversion rate) and by the OpenPositionEndOfDay views for end-of-day PnL snapshots. It reads from Trade.Instrument to examine buy/sell currency pairs and find matching conversion paths.

---

## 2. Business Logic

### 2.1 Three-Tier Conversion Resolution

**What**: The function resolves the conversion instrument using a priority-based search across three tiers: direct sell-side match, direct buy-side match, and cross-currency lookup.

**Columns/Parameters Involved**: `@InstrumentID`, `@AccountCurrencyID`, `Trade.Instrument.SellCurrencyID`, `Trade.Instrument.BuyCurrencyID`

**Rules**:
- **Tier 1 - Sell currency match**: If the traded instrument's SellCurrencyID equals the account currency, use the traded instrument itself as the conversion instrument. IsReciprocal=0 (direct rate). Example: Trading EUR/USD with a USD account - USD is the sell currency, so use EUR/USD directly.
- **Tier 2 - Buy currency match**: If the traded instrument's BuyCurrencyID equals the account currency, use the traded instrument itself. IsReciprocal=1 (reciprocal rate needed). Example: Trading USD/JPY with a USD account - USD is the buy currency, use 1/rate.
- **Tier 3 - Cross-currency**: If neither currency matches, find a bridge instrument where SellCurrencyID of the traded instrument's sell side matches an instrument that has BuyCurrencyID = account currency. Also tries the reverse path (sell side of bridge = account currency).
- The function uses UNION ALL of two CTEs covering both bridge directions, then picks the first non-NULL result.

**Diagram**:
```
Input: @InstrumentID (e.g., EUR/JPY), @AccountCurrencyID (e.g., USD)
  |
  v
Tier 1: SellCurrencyID = @AccountCurrencyID?  (JPY = USD? No)
  |
  v
Tier 2: BuyCurrencyID = @AccountCurrencyID?  (EUR = USD? No)
  |
  v
Tier 3: Find bridge instrument
  CTE1: ti.SellCurrencyID = cti.SellCurrencyID AND cti.BuyCurrencyID = @AccountCurrencyID
        -> JPY/USD exists? Use its InstrumentID, IsReciprocal=0
  CTE2: ti.SellCurrencyID = cti.BuyCurrencyID AND cti.SellCurrencyID = @AccountCurrencyID
        -> USD/JPY exists? Use its InstrumentID, IsReciprocal=1
  |
  v
Return first non-NULL ConversionInstrumentID
```

### 2.2 Reciprocal Flag

**What**: Indicates whether the conversion rate should be used directly or inverted (1/rate).

**Columns/Parameters Involved**: `IsReciprocal`

**Rules**:
- IsReciprocal = 0: Use the conversion instrument's rate directly (sell-side match or bridge sell-side)
- IsReciprocal = 1: Use 1/rate (buy-side match or bridge buy-side)
- The consumer (FnGetCurrentConversionRate) reads this flag to determine whether to use BuyPrice or SellPrice and whether to invert

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The traded instrument whose PnL needs currency conversion. Looked up in Trade.Instrument to determine SellCurrencyID and BuyCurrencyID (the currency pair). |
| 2 | @AccountCurrencyID | INT | NO | - | CODE-BACKED | The customer's account denomination currency ID. The function finds an instrument that bridges from the traded instrument's currency to this account currency. Common values: 1=USD, 2=EUR, 4=GBP, 6=AUD. |
| 3 | ConversionInstrumentID (return) | INT | YES | - | CODE-BACKED | The InstrumentID to use for currency conversion. May be the traded instrument itself (if one side is the account currency) or a bridge instrument (cross-currency). NULL if no conversion path exists. |
| 4 | IsReciprocal (return) | INT | YES | - | CODE-BACKED | 0 = use the conversion instrument's rate directly (sell-side match), 1 = use the reciprocal (1/rate, buy-side match). Determines whether consumer reads BuyPrice or SellPrice from CurrencyPrice. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.Instrument | FROM/WHERE | Primary lookup: reads SellCurrencyID, BuyCurrencyID for the traded instrument |
| Cross-currency | Trade.Instrument | OUTER APPLY | Secondary lookup: searches for bridge instruments matching currency pairs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FnGetCurrentConversionRate | OUTER APPLY | Function call | Primary consumer: uses resolved ConversionInstrumentID + IsReciprocal to fetch the actual conversion rate |
| Trade.OpenPositionEndOfDay | OUTER APPLY | View reference | End-of-day snapshot PnL conversion |
| Trade.OpenPositionEndOfDayWith2Pnl | OUTER APPLY | View reference | Dual-PnL end-of-day snapshot |
| History.ClosePositionEndOfDay | OUTER APPLY | View reference | Historical close PnL conversion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FnGetConversionInstrument (function)
  └── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FROM + OUTER APPLY: lookups on InstrumentID, SellCurrencyID, BuyCurrencyID for conversion path resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FnGetCurrentConversionRate | Function | OUTER APPLY for conversion instrument resolution |
| Trade.OpenPositionEndOfDay | View | OUTER APPLY for EOD PnL conversion |
| Trade.OpenPositionEndOfDayWith2Pnl | View | OUTER APPLY for dual-PnL snapshot |
| History.ClosePositionEndOfDay | View | OUTER APPLY for historical PnL conversion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning ConversionInstrumentID and IsReciprocal |
| WITH (NOLOCK) | Read hint | All Trade.Instrument reads use NOLOCK |
| UNION ALL + TOP 1 WHERE NOT NULL | Logic | Two CTEs cover both bridge directions; first non-NULL result wins |

---

## 8. Sample Queries

### 8.1 Find the conversion instrument for a specific trade

```sql
SELECT  ci.ConversionInstrumentID,
        ci.IsReciprocal,
        conv.SymbolFull AS ConversionPair
FROM    Trade.FnGetConversionInstrument(1001, 1) ci
        LEFT JOIN Trade.Instrument conv WITH (NOLOCK) ON ci.ConversionInstrumentID = conv.InstrumentID;
```

### 8.2 Show conversion paths for all open positions of a customer

```sql
SELECT  p.PositionID,
        p.InstrumentID,
        i.SymbolFull AS TradedPair,
        ci.ConversionInstrumentID,
        ci.IsReciprocal,
        conv.SymbolFull AS ConversionPair
FROM    Trade.PositionTbl p WITH (NOLOCK)
        JOIN Trade.Instrument i WITH (NOLOCK) ON p.InstrumentID = i.InstrumentID
        OUTER APPLY Trade.FnGetConversionInstrument(p.InstrumentID, 1) ci
        LEFT JOIN Trade.Instrument conv WITH (NOLOCK) ON ci.ConversionInstrumentID = conv.InstrumentID
WHERE   p.CID = 12345678
        AND p.StatusID = 1;
```

### 8.3 Find positions with no conversion path (potential issues)

```sql
SELECT  p.PositionID,
        p.InstrumentID,
        i.SymbolFull
FROM    Trade.PositionTbl p WITH (NOLOCK)
        JOIN Trade.Instrument i WITH (NOLOCK) ON p.InstrumentID = i.InstrumentID
        OUTER APPLY Trade.FnGetConversionInstrument(p.InstrumentID, 1) ci
WHERE   p.StatusID = 1
        AND ci.ConversionInstrumentID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object directly. Multi-currency conversion context available in Confluence pages "Supporting Services - Multi-Currency Changes" and "Equity Calculator Multi-Currency Support" (general architecture, not function-specific).

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FnGetConversionInstrument | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FnGetConversionInstrument.sql*
