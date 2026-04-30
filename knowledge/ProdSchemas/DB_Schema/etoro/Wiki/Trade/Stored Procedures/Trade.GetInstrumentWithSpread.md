# Trade.GetInstrumentWithSpread

> Returns instrument metadata enriched with spread calculations (bid/ask in both pips and rate units) by joining Trade.GetInstrument, Trade.InstrumentSpread, and Trade.ProviderToInstrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns instrument data with spread from three joined sources |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentWithSpread returns a comprehensive instrument dataset that combines core instrument metadata with spread pricing data. It calculates spreads in two units:
- **Pips**: Raw bid/ask from InstrumentSpread, plus total spread (ABS(Ask) + ABS(Bid))
- **Rate units**: Bid/Ask divided by 10^Precision, converting pip-denominated spreads to actual price movements

This enables services to display both the raw pip spread and the economically meaningful rate spread. Only spreads from FeedID = 1 (the primary/default feed) are included. The procedure also returns risk parameters (MaxStopLossPercentage, MaxTakeProfitPercentage) and the spread type classification.

---

## 2. Business Logic

### 2.1 Spread Pip-to-Rate Conversion

**What**: Converts pip-based spreads to rate-based spreads using the instrument's precision.

**Columns/Parameters Involved**: `TIS.Bid`, `TIS.Ask`, `TPI.Precision`

**Rules**:
- `SpreadBid = TIS.Bid / POWER(10, TPI.Precision)` - bid spread in rate units
- `SpreadAsk = TIS.Ask / POWER(10, TPI.Precision)` - ask spread in rate units
- `SpreadPips = ABS(TIS.Ask) + ABS(TIS.Bid)` - total spread width in pips (absolute values ensure positive regardless of sign convention)
- Uses INNER JOINs: instruments without spread data or provider configuration are excluded

### 2.2 Feed Filter

**What**: Only the primary feed's spread is returned.

**Rules**:
- Hardcoded `WHERE TIS.FeedID = 1` - only the primary/default price feed
- Secondary/backup feeds are excluded from this result set

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.GetInstrument.InstrumentID | CODE-BACKED | Instrument identifier. |
| R2 | BuyCurrencyID | int | Trade.GetInstrument.BuyCurrencyID | CODE-BACKED | Base currency of the instrument pair. |
| R3 | SellCurrencyID | int | Trade.GetInstrument.SellCurrencyID | CODE-BACKED | Quote currency of the instrument pair. |
| R4 | InstrumentTypeID | int | Trade.GetInstrument.InstrumentTypeID | CODE-BACKED | Asset class (FK to Dictionary.InstrumentType). |
| R5 | Name | nvarchar | Trade.GetInstrument.Name | CODE-BACKED | Instrument display name (e.g., "EURUSD", "AAPL"). |
| R6 | TradeRange | decimal | Trade.GetInstrument.TradeRange | CODE-BACKED | Maximum allowable price deviation from market for order validation. |
| R7 | DollarRatio | decimal | Trade.GetInstrument.DollarRatio | CODE-BACKED | Conversion factor to USD equivalent. |
| R8 | Passport | bit | Trade.GetInstrument.Passport | CODE-BACKED | Whether instrument participates in CopyTrader/Smart Portfolios. |
| R9 | PipDifferenceThreshold | decimal | Trade.GetInstrument.PipDifferenceThreshold | CODE-BACKED | Alert threshold for abnormal price feed deviation (in pips). |
| R10 | IsMajor | bit | Trade.GetInstrument.IsMajor | CODE-BACKED | Whether instrument is classified as a major/popular instrument. |
| R11 | SpreadBidPips | decimal | Trade.InstrumentSpread.Bid | CODE-BACKED | Bid-side spread component in pips. |
| R12 | SpreadAskPips | decimal | Trade.InstrumentSpread.Ask | CODE-BACKED | Ask-side spread component in pips. |
| R13 | SpreadPips | decimal | Computed: ABS(Ask) + ABS(Bid) | CODE-BACKED | Total spread width in pips (always positive). |
| R14 | SpreadBid | decimal | Computed: Bid / POWER(10, Precision) | CODE-BACKED | Bid-side spread in rate units (actual price movement). |
| R15 | SpreadAsk | decimal | Computed: Ask / POWER(10, Precision) | CODE-BACKED | Ask-side spread in rate units (actual price movement). |
| R16 | MaxStopLossPercentage | decimal | Trade.ProviderToInstrument.MaxStopLossPercentage | CODE-BACKED | Maximum allowed stop-loss as percentage of position value. |
| R17 | MaxTakeProfitPercentage | decimal | Trade.ProviderToInstrument.MaxTakeProfitPercentage | CODE-BACKED | Maximum allowed take-profit as percentage of position value. |
| R18 | SpreadTypeID | int | Trade.InstrumentSpread.SpreadTypeID | CODE-BACKED | Spread classification (e.g., fixed vs. variable). |
| R19 | ExchangeID | int | Trade.GetInstrument.ExchangeID | CODE-BACKED | Exchange where instrument is listed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.GetInstrument | Read (SELECT JOIN) | Core instrument metadata |
| JOIN | Trade.InstrumentSpread | Read (SELECT JOIN) | Spread bid/ask data filtered to FeedID = 1 |
| JOIN | Trade.ProviderToInstrument | Read (SELECT JOIN) | Precision for rate conversion, risk percentages |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentWithSpread (procedure)
+-- Trade.GetInstrument (view)
+-- Trade.InstrumentSpread (table)
+-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View | JOIN - instrument metadata (name, type, currencies, exchange) |
| Trade.InstrumentSpread | Table | JOIN ON InstrumentID - bid/ask spread data, filtered WHERE FeedID = 1 |
| Trade.ProviderToInstrument | Table | JOIN ON InstrumentID - Precision for pip-to-rate conversion, risk percentages |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dealing/pricing services | Application | Spread display and rate calculations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all instruments with spread

```sql
EXEC Trade.GetInstrumentWithSpread;
```

### 8.2 Find instruments with widest spreads

```sql
SELECT  TOP 20 TGI.InstrumentID, TGI.Name,
        ABS(TIS.Ask) + ABS(TIS.Bid) AS SpreadPips
FROM    Trade.GetInstrument TGI WITH (NOLOCK)
        JOIN Trade.InstrumentSpread TIS ON TGI.InstrumentID = TIS.InstrumentID
WHERE   TIS.FeedID = 1
ORDER BY SpreadPips DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentWithSpread | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentWithSpread.sql*
