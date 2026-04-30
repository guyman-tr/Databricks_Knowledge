# Trade.GetProviderToInstrumentData

> Returns comprehensive provider-instrument trading parameters (precision, unit, margin, forex currency pair, dollar ratio, conversion instrument) for all instruments, with USD-paired instruments handled separately (no conversion lookup needed).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the full instrument trading configuration used by the trading engine on startup or instrument refresh. It combines physical trading parameters from Trade.ProviderToInstrument (Precision, Unit, LiquidityLotSize, UnitMargin, Benchmark, AllowedRateDiffPercentage) with forex currency data from Trade.GetInstrument (BuyCurrencyID, SellCurrencyID, DollarRatio, InstrumentTypeID) and currency conversion routing from Trade.GetCurrencyConversionsView.

The UNION ALL pattern handles two categories of instruments differently:
- **Non-USD pairs** (both BuyCurrencyID != 1 AND SellCurrencyID != 1): Need a ConversionInstrumentID to translate PnL into USD. Joined to Trade.GetCurrencyConversionsView on SellCurrencyID.
- **USD-paired instruments** (BuyCurrencyID=1 OR SellCurrencyID=1): Already denominated in USD; ConversionInstrumentID=0 and IsReciprocal=0 (no conversion needed).

CurrencyID=1 = USD in the eToro system.

Data flows: Loads all from Trade.ProviderToInstrument + Trade.GetInstrument + Trade.GetCurrencyConversionsView (for non-USD pairs). Called by trading engine processes to load instrument configuration. Added AllowedRateDiffPercentage column in 2015.

---

## 2. Business Logic

### 2.1 Non-USD Pairs: Currency Conversion Lookup

**What**: For instruments where neither currency is USD, a conversion instrument is needed to translate PnL into USD.

**Columns/Parameters Involved**: `BuyCurrencyID`, `SellCurrencyID`, `Trade.GetCurrencyConversionsView`, `ConversionInstrumentID`, `IsReciprocal`

**Rules**:
- Filter: BuyCurrencyID != 1 AND SellCurrencyID != 1.
- JOIN Trade.GetCurrencyConversionsView ON SellCurrencyID = conv.CurrencyID.
- Returns ConversionInstrumentID: the instrument to use for USD conversion.
- Returns IsReciprocal (as ReciprocalForConversion): whether to invert the conversion rate.

### 2.2 USD-Paired Instruments: No Conversion Needed

**What**: Instruments where one leg is USD (CurrencyID=1) do not require a conversion instrument.

**Columns/Parameters Involved**: `BuyCurrencyID`, `SellCurrencyID`

**Rules**:
- Filter: BuyCurrencyID=1 OR SellCurrencyID=1.
- ConversionInstrumentID=0 (hardcoded - no conversion instrument needed).
- ReciprocalForConversion=0 (hardcoded).
- The PnL is already in USD or can be calculated directly from the quote currency.

### 2.3 AllowedRateDiffPercentage

**What**: The maximum allowable percentage difference between the client's viewed rate and the actual execution rate.

**Columns/Parameters Involved**: `AllowedRateDiffPercentage`

**Rules**:
- Added 2015-02-19 by Eran Hershko.
- Used to validate that the rate at which a trade executes is within acceptable bounds of the rate the customer was shown.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters.

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Traded instrument identifier. |
| 2 | Precision | INT | YES | - | CODE-BACKED | Decimal precision for instrument price display (number of decimal places). |
| 3 | Unit | DECIMAL | YES | - | CODE-BACKED | Contract/lot size unit for the instrument. Used to convert between dollar amount and unit count. |
| 4 | LiquidityLotSize | DECIMAL | YES | - | CODE-BACKED | Lot size for liquidity provider orders. Controls aggregation of hedge orders. |
| 5 | Benchmark | DECIMAL | YES | - | CODE-BACKED | Benchmark price rate for the instrument. Used as reference for spread calculation. |
| 6 | UnitMargin | DECIMAL | YES | - | CODE-BACKED | Margin required per unit for leveraged positions. |
| 7 | BuyCurrencyID | INT | NO | - | CODE-BACKED | Base currency of the instrument (numerator). CurrencyID=1 = USD. |
| 8 | SellCurrencyID | INT | NO | - | CODE-BACKED | Quote currency of the instrument (denominator). CurrencyID=1 = USD. |
| 9 | DollarRatio | DECIMAL | YES | - | CODE-BACKED | Fixed USD conversion ratio for instruments with a stable dollar relationship. |
| 10 | ConversionInstrumentID | INT | NO | - | CODE-BACKED | Instrument to use for USD PnL conversion. 0 = no conversion needed (USD-paired instrument). |
| 11 | ReciprocalForConversion | BIT | NO | - | CODE-BACKED | Whether to use 1/rate when applying the conversion instrument. 0 = no conversion (USD-paired). |
| 12 | Enabled | BIT | YES | - | CODE-BACKED | Whether this provider-instrument configuration is active. |
| 13 | AllowedRateDiffPercentage | DECIMAL | YES | - | CODE-BACKED | Maximum allowed rate difference percentage between client view rate and execution rate. Added 2015. |
| 14 | InstrumentTypeID | INT | NO | - | CODE-BACKED | Instrument category (1=CFD Stocks, 2=Currency, 4=Commodities, 5=Indices, 6=ETF, 10=Crypto, etc.). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.ProviderToInstrument | Primary source | Trading parameters (Precision, Unit, Margin, etc.) |
| InstrumentID | Trade.GetInstrument | JOIN | Forex currency IDs, DollarRatio, InstrumentTypeID |
| SellCurrencyID | Trade.GetCurrencyConversionsView | JOIN (non-USD path) | Conversion instrument and reciprocal flag for USD PnL conversion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading engine / server | (no parameters) | Application call | Loads full instrument configuration on startup or refresh |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetProviderToInstrumentData (procedure)
+-- Trade.ProviderToInstrument (table)
+-- Trade.GetInstrument (view)
+-- Trade.GetCurrencyConversionsView (view) [non-USD instruments only]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | Primary source: Precision, Unit, LiquidityLotSize, Benchmark, UnitMargin, Enabled, AllowedRateDiffPercentage |
| Trade.GetInstrument | View | BuyCurrencyID, SellCurrencyID, DollarRatio, InstrumentTypeID |
| Trade.GetCurrencyConversionsView | View | ConversionInstrumentID and IsReciprocal for non-USD currency pairs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading server / engine | External application | Full instrument config load for position pricing, hedging, and PnL calculation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UNION ALL split on CurrencyID=1 | Design | Non-USD pairs get ConversionInstrumentID from view; USD-paired instruments get hardcoded 0 |
| CurrencyID=1 = USD | Domain | Currency identifier 1 represents US Dollar throughout eToro systems |

---

## 8. Sample Queries

### 8.1 Load all instrument provider data

```sql
EXEC Trade.GetProviderToInstrumentData;
```

### 8.2 Check which instruments require USD conversion

```sql
-- After loading: instruments with ConversionInstrumentID > 0 need PnL conversion
-- Non-USD pairs example inline:
SELECT pti.InstrumentID, ins.BuyCurrencyID, ins.SellCurrencyID,
       conv.ConversionInstrumentID, conv.IsReciprocal
FROM Trade.ProviderToInstrument pti WITH (NOLOCK)
INNER JOIN Trade.GetInstrument ins WITH (NOLOCK) ON pti.InstrumentID = ins.InstrumentID
INNER JOIN Trade.GetCurrencyConversionsView conv ON ins.SellCurrencyID = conv.CurrencyID
WHERE ins.BuyCurrencyID <> 1 AND ins.SellCurrencyID <> 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetProviderToInstrumentData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetProviderToInstrumentData.sql*
