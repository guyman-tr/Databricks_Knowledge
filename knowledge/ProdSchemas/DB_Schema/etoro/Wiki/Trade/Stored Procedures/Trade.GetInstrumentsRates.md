# Trade.GetInstrumentsRates

> Returns current price rates (bid, ask, skew, unit margin, USD conversion) for a set of instruments or all visible/tradable instruments, powering real-time pricing in trading services.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 16 price-related columns from Trade.CurrencyPrice + Trade.ProviderToInstrument |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentsRates is a price data procedure that returns comprehensive current rate information for instruments. It reads from Trade.CurrencyPrice (real-time bid/ask/skew data) joined with Trade.ProviderToInstrument (precision), providing everything needed to calculate execution prices, P&L, and margin requirements.

This procedure exists because trading services need a single call to get complete pricing data including raw rates, spread-adjusted rates, USD conversion rates, unit margin values, and skew adjustments. The data powers execution engines, equity calculations, and real-time P&L.

When the TVP is empty (no instrument IDs provided), the procedure auto-populates with all visible+tradable instruments from ProviderToInstrument (ProviderID=1) PLUS currency conversion instruments from Trade.GetCurrencyConversionsView. This fallback ensures price services always have rates for all active instruments and conversion pairs.

---

## 2. Business Logic

### 2.1 Instrument Set Auto-Population

**What**: When no specific instruments are requested, automatically includes all visible/tradable instruments plus currency conversion instruments.

**Columns/Parameters Involved**: `@InstrumentIDs`, `Trade.InstrumentMetaData.InstrumentVisible`, `Trade.InstrumentMetaData.Tradable`, `Trade.ProviderToInstrument.Enabled`, `Trade.GetCurrencyConversionsView.ConversionInstrumentID`

**Rules**:
- If @InstrumentIDs TVP is empty (@@ROWCOUNT = 0 after insert to #instrumentID):
  - Include instruments where ProviderID=1 AND (InstrumentVisible=1 OR Enabled=1) AND Tradable=1
  - ALSO include conversion instruments from GetCurrencyConversionsView that are not already in the set
- If @InstrumentIDs TVP has rows, use exactly those instrument IDs
- Conversion instruments are critical because P&L calculations need USD conversion rates for non-USD denominated instruments

### 2.2 Price Data Assembly

**What**: Combines current market rates with instrument precision for a complete pricing snapshot.

**Columns/Parameters Involved**: `Bid`, `Ask`, `BidDiscounted`, `AskDiscounted`, `SkewValueBid`, `SkewValueAsk`, `UnitMargin*`, `USDConversionRate*`, `Precision`

**Rules**:
- Bid/Ask are raw market rates; BidDiscounted/AskDiscounted are spread-adjusted
- SkewValueBid/SkewValueAsk are risk-management adjustments applied to rates
- USDConversionRateAskSpreaded/BidSpreaded convert instrument-currency P&L to USD
- UnitMargin variants (base, Bid/Ask discounted, Bid/Ask) support different margin calculations
- Precision from ProviderToInstrument defines decimal accuracy for rate display

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentIDs | dbo.InstrumentIDs (READONLY) | NO | - | CODE-BACKED | TVP of instrument IDs to retrieve rates for. If empty, auto-populates with all visible/tradable instruments plus currency conversion instruments. Uses dbo.InstrumentIDs type (not Trade.InstrumentIDsTbl). |

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.CurrencyPrice.InstrumentID | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. |
| R2 | Bid | money | Trade.CurrencyPrice.Bid | CODE-BACKED | Current best bid (sell) price from the primary price feed. |
| R3 | Ask | money | Trade.CurrencyPrice.Ask | CODE-BACKED | Current best ask (buy) price from the primary price feed. |
| R4 | USDConversionRateAskSpreaded | money | Trade.CurrencyPrice | CODE-BACKED | Ask-side USD conversion rate with spread applied. Used for converting non-USD P&L to USD. |
| R5 | USDConversionRateBidSpreaded | money | Trade.CurrencyPrice | CODE-BACKED | Bid-side USD conversion rate with spread applied. |
| R6 | Occurred | datetime | Trade.CurrencyPrice.Occurred | CODE-BACKED | Timestamp of when this price tick was received. |
| R7 | UnitMargin | money | Trade.CurrencyPrice.UnitMargin | CODE-BACKED | Base unit margin amount for margin calculations. |
| R8 | UnitMarginBidDiscounted | money | Trade.CurrencyPrice | CODE-BACKED | Bid-discounted unit margin for short position margin calculations. |
| R9 | UnitMarginAskDiscounted | money | Trade.CurrencyPrice | CODE-BACKED | Ask-discounted unit margin for long position margin calculations. |
| R10 | UnitMarginBid | money | Trade.CurrencyPrice | CODE-BACKED | Bid-side unit margin. |
| R11 | UnitMarginAsk | money | Trade.CurrencyPrice | CODE-BACKED | Ask-side unit margin. |
| R12 | PriceRateID | bigint | Trade.CurrencyPrice.PriceRateID | CODE-BACKED | Unique identifier for this specific price tick. Used for audit trail and rate locking. |
| R13 | BidDiscounted | money | Trade.CurrencyPrice.BidDiscounted | CODE-BACKED | Bid price with discount/spread adjustment applied. |
| R14 | AskDiscounted | money | Trade.CurrencyPrice.AskDiscounted | CODE-BACKED | Ask price with discount/spread adjustment applied. |
| R15 | SkewValueBid | money | Trade.CurrencyPrice.SkewValueBid | CODE-BACKED | Risk management skew adjustment on bid side. |
| R16 | SkewValueAsk | money | Trade.CurrencyPrice.SkewValueAsk | CODE-BACKED | Risk management skew adjustment on ask side. |
| R17 | Precision | int | Trade.ProviderToInstrument.Precision | CODE-BACKED | Number of decimal places for this instrument's rate. From ProviderToInstrument via InstrumentID JOIN. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.CurrencyPrice | Read (SELECT) | Source of real-time bid/ask/skew/unit margin data |
| JOIN | Trade.ProviderToInstrument | Read (SELECT) | Source of Precision; joined on InstrumentID |
| Fallback | Trade.InstrumentMetaData | Read (SELECT) | Used in auto-population path to check InstrumentVisible and Tradable |
| Fallback | Trade.GetCurrencyConversionsView | Read (SELECT) | Used in auto-population path to include conversion instruments |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price/Execution services | (application) | Consumer | Real-time pricing for trade execution and P&L calculations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentsRates (procedure)
+-- Trade.CurrencyPrice (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.InstrumentMetaData (table)
+-- Trade.GetCurrencyConversionsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | INNER JOIN - primary source of all price rate data |
| Trade.ProviderToInstrument | Table | INNER JOIN - source of Precision; also used in auto-population filter |
| Trade.InstrumentMetaData | Table | INNER JOIN in auto-population - InstrumentVisible and Tradable filters |
| Trade.GetCurrencyConversionsView | View | SELECT in auto-population - adds conversion instruments |
| dbo.InstrumentIDs | User Defined Type | TVP type for @InstrumentIDs parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading services | Application | Real-time pricing data for execution and P&L |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No validation on input IDs; missing instruments simply return no rows.

---

## 8. Sample Queries

### 8.1 Get rates for all visible instruments (empty TVP)

```sql
DECLARE @IDs dbo.InstrumentIDs;
EXEC Trade.GetInstrumentsRates @InstrumentIDs = @IDs;
```

### 8.2 Get rates for specific instruments

```sql
DECLARE @IDs dbo.InstrumentIDs;
INSERT INTO @IDs (InstrumentID) VALUES (1), (5), (10);
EXEC Trade.GetInstrumentsRates @InstrumentIDs = @IDs;
```

### 8.3 Check current spread for an instrument

```sql
SELECT  InstrumentID,
        Ask - Bid AS RawSpread,
        AskDiscounted - BidDiscounted AS DiscountedSpread,
        Occurred
FROM    Trade.CurrencyPrice WITH (NOLOCK)
WHERE   InstrumentID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentsRates | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentsRates.sql*
