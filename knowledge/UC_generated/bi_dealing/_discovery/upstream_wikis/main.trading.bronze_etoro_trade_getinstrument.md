# Trade.GetInstrument

> Instrument deal view that joins Instrument with currency abbreviations and metadata to produce display-ready instrument rows with Name as "BUY/SELL", filtering out InstrumentID=0 and NULL InstrumentTypeID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID (from base table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrument is the primary instrument view used across the trading platform to expose instrument definitions with human-readable display data. It answers: "What instruments are tradeable, and how do I show them in the UI?" The view joins Trade.Instrument with Dictionary.Currency (for buy and sell abbreviations), Trade.InstrumentMetaData (for InstrumentTypeID, Industry, ExchangeID), and computes a display Name as "BUY/SELL" (e.g., EUR/USD, GBP/USD).

The view exists so procedures and APIs can get a single row per instrument with all the attributes needed for display, filtering, and validation. Without it, every caller would need to replicate the JOIN and WHERE logic. Trade.InsertDividend, Trade.GetInstrumentInterestRates, Trade.GetPositionsForFeeBulkGeneral, Trade.CalcOverNightFeeRates, Trade.GetInstrumentWithSpread, and dozens of other procedures use this view to resolve InstrumentTypeID, Name, and trading parameters.

Data flows: The view reads from Trade.Instrument, Dictionary.Currency (twice for buy/sell), and Trade.InstrumentMetaData with NOLOCK. It filters out InstrumentID=0 (system placeholder) and instruments with NULL InstrumentTypeID (incomplete metadata). Rows appear when Instrument and InstrumentMetaData exist and InstrumentMetaData has a valid InstrumentTypeID.

---

## 2. Business Logic

### 2.1 Display Name as BUY/SELL Abbreviation

**What**: The Name column concatenates buy and sell currency abbreviations for display (e.g., EUR/USD).

**Columns/Parameters Involved**: `Name`, `TDCUR_BUY.Abbreviation`, `TDCUR_SEL.Abbreviation`

**Rules**:
- Name = TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation
- For forex: literal pair (EUR/USD, GBP/USD, NZD/USD)
- For stocks: BuyCurrencyID = InstrumentID (asset), SellCurrencyID = denomination (EUR, USD, GBX), so Name shows as "ASSET/CURRENCY"

**Diagram**:
```
Forex:   Buy=EUR, Sell=USD -> Name = "EUR/USD"
Stock:   Buy=1203(Bayer), Sell=EUR -> Name = "Bayer/EUR" (abbreviation from Dictionary.Currency)
```

### 2.2 InstrumentTypeID from Metadata

**What**: InstrumentTypeID comes from InstrumentMetaData, not Instrument. Only instruments with non-NULL InstrumentTypeID appear.

**Columns/Parameters Involved**: `IMD.InstrumentTypeID`, `TSISR.InstrumentID`

**Rules**:
- WHERE IMD.InstrumentTypeID IS NOT NULL - excludes instruments without asset-class metadata
- InstrumentTypeID: 1=Forex, 5=Stocks, 10=Crypto, etc. (Dictionary.CurrencyType)
- Trade.InsertDividend and Trade.UpdateDividend use InstrumentTypeID IN (4,5,6) to restrict dividend-eligible instruments

### 2.3 Exclusion of System Placeholder

**What**: InstrumentID=0 is excluded from the view.

**Columns/Parameters Involved**: `TSISR.InstrumentID`

**Rules**:
- WHERE TSISR.InstrumentID != 0
- InstrumentID=0 is the system placeholder in Trade.Instrument and Dictionary.Currency; never used for real trading

---

## 3. Data Overview

| InstrumentID | Name | BuyCurrencyID | SellCurrencyID | InstrumentTypeID | DollarRatio | IsMajor | Industry | ExchangeID | Meaning |
|---|---|---|---|---|---|---|---|---|---|
| 1 | EUR/USD | 2 | 1 | 1 | 1 | true | Basic Materials | 1 | Major forex pair. InstrumentTypeID=1 (Forex). Standard DollarRatio for spot. |
| 2 | GBP/USD | 3 | 1 | 1 | 1 | true | NULL | 1 | GBP/USD forex. Industry NULL for forex (industry applies to stocks). |
| 3 | NZD/USD | 8 | 1 | 1 | 1 | true | NULL | 17 | NZD/USD with different ExchangeID for price routing. |
| 4 | USD/CAD | 1 | 7 | 1 | 1 | true | NULL | 1 | USD/CAD - inverted pair notation. |
| 5 | JPY/USD | 4 | 1 | 1 | 100 | false | NULL | 1 | USD/JPY. DollarRatio=100 because JPY quoted in hundredths. IsMajor=false in sample. |

**Selection criteria**: Picked from live MCP sample. Major forex pairs showing Name format, DollarRatio (1 vs 100 for JPY), and Industry NULL for forex.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Primary key from Trade.Instrument. Identifies the tradeable instrument pair. |
| 2 | BuyCurrencyID | int | NO | - | CODE-BACKED | FK to Dictionary.Currency. Buy-side asset. For forex: base currency; for stocks: asset itself (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument. |
| 3 | SellCurrencyID | int | NO | - | CODE-BACKED | FK to Dictionary.Currency. Sell-side (denomination) currency. For forex: quote currency; for stocks: trading currency. Inherited from Trade.Instrument. |
| 4 | InstrumentTypeID | int | YES | - | CODE-BACKED | From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. |
| 5 | Name | varchar | NO | - | CODE-BACKED | Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). |
| 6 | TradeRange | smallint | NO | - | CODE-BACKED | Allowed trade range (pip distance) for pending orders. From Trade.Instrument. |
| 7 | DollarRatio | decimal(8,2) | NO | - | CODE-BACKED | Price scaling factor. Most=1; JPY pairs=100. From Trade.Instrument. |
| 8 | Passport | timestamp | NO | - | CODE-BACKED | Row version/concurrency token. From Trade.Instrument. |
| 9 | PipDifferenceThreshold | bigint | YES | - | CODE-BACKED | Max pip difference for price validation. From Trade.Instrument. |
| 10 | IsMajor | bit | NO | - | CODE-BACKED | 1=major instrument (spread/margin treatment); 0=minor. From Trade.Instrument. |
| 11 | Industry | varchar(max) | YES | - | CODE-BACKED | Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData. |
| 12 | ExchangeID | int | YES | - | CODE-BACKED | FK to Price.Exchange. Primary exchange for price feed routing. From Trade.InstrumentMetaData. |
| 13 | OperationMode | tinyint | YES | - | CODE-BACKED | Trading operation mode: 0=Standard, 1=Alternate (e.g., European stocks in non-USD). From Trade.Instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID, BuyCurrencyID, SellCurrencyID | Trade.Instrument | Base/Lookup | Core instrument definition |
| BuyCurrencyID | Dictionary.Currency | Lookup | Buy-side abbreviation |
| SellCurrencyID | Dictionary.Currency | Lookup | Sell-side abbreviation |
| InstrumentTypeID | Dictionary.CurrencyType | Lookup | Asset class |
| ExchangeID | Price.Exchange | Lookup | Primary exchange |
| Industry | Trade.InstrumentMetaData (StocksIndustryID) | Lookup | Industry sector for stocks |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertDividend | WHERE | Reader | Validates InstrumentTypeID IN (4,5,6) |
| Trade.UpdateDividend | WHERE | Reader | Same validation |
| Trade.GetInstrumentInterestRates | FROM | Reader | Instrument data for interest rates |
| Trade.GetInstrumentInterestRates_TRDOPS | FROM | Reader | Same |
| Trade.GetPositionsForFeeBulkGeneral | INNER JOIN | Reader | Fee calculation by instrument |
| Trade.GetPositionsForFeeProcess | INNER JOIN | Reader | Same |
| Trade.CalcOverNightFeeRates | FROM | Reader | Overnight fee rates |
| Trade.GetInstrumentWithSpread | FROM | Reader | Instrument with spread data |
| Trade.CM_GetLeveragesRestrictionsWhiteList | INNER JOIN | Reader | Leverage restrictions |
| Trade.CM_InsertLeveragesRestrictionsWhiteList | WHERE | Reader | Instrument filter |
| Trade.FundMgrSync | INNER JOIN | Reader | Fund manager sync |
| Trade.GetProviderToInstrumentData | INNER JOIN | Reader | Provider-instrument data |
| Trade.GetInstrumentType | FROM | Reader | Instrument type lookup |
| Trade.GetInstrumentDataForAPI | INNER JOIN | Reader | API instrument data |
| Trade.GetForexRates | INNER JOIN | Reader | Forex rate display |
| Trade.MatchInstrumentIDToTickerName | LEFT JOIN | Reader | Ticker matching |
| Trade.InsertNewTradingResourceDefault | JOIN | Reader | Trading resource defaults |
| Trade.ChangeIsSettledForASYCUsers | JOIN | Reader | ASYC user positions |
| Trade.NewCheckBSL, Trade.CheckBSL | JOIN | Reader | BSL validation |
| Trade.GetLeveragesRestrictionsWhiteList | INNER JOIN | Reader | Leverage whitelist |
| Trade.GetInterestRateOverrides | LEFT JOIN | Reader | Interest rate overrides |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrument (view)
├── Trade.Instrument (table)
├── Dictionary.Currency (table) [buy]
├── Dictionary.Currency (table) [sell]
└── Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FROM - base instrument definition |
| Dictionary.Currency | Table | INNER JOIN (twice) - buy and sell abbreviations |
| Trade.InstrumentMetaData | Table | INNER JOIN - InstrumentTypeID, Industry, ExchangeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertDividend | Procedure | WHERE InstrumentTypeID validation |
| Trade.UpdateDividend | Procedure | Same |
| Trade.GetInstrumentInterestRates | Procedure | FROM |
| Trade.GetPositionsForFeeBulkGeneral | Procedure | INNER JOIN |
| Trade.CalcOverNightFeeRates | Procedure | FROM |
| Trade.GetInstrumentWithSpread | Procedure | FROM |
| Trade.GetInstrumentDataForAPI | Procedure | INNER JOIN |
| Trade.GetForexRates | Procedure | INNER JOIN |
| (20+ other procedures) | Procedure | Various reads |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get instrument by ID with display name
```sql
SELECT InstrumentID, Name, BuyCurrencyID, SellCurrencyID, InstrumentTypeID,
       DollarRatio, IsMajor, Industry, ExchangeID
  FROM Trade.GetInstrument WITH (NOLOCK)
 WHERE InstrumentID = 1
```

### 8.2 Forex instruments only
```sql
SELECT InstrumentID, Name, TradeRange, PipDifferenceThreshold
  FROM Trade.GetInstrument WITH (NOLOCK)
 WHERE InstrumentTypeID = 1
 ORDER BY Name
```

### 8.3 Resolve instruments to asset class names
```sql
SELECT GI.InstrumentID, GI.Name, GI.InstrumentTypeID, CT.Name AS AssetClassName
  FROM Trade.GetInstrument GI WITH (NOLOCK)
  LEFT JOIN Dictionary.CurrencyType CT WITH (NOLOCK)
    ON GI.InstrumentTypeID = CT.CurrencyTypeID
 WHERE GI.InstrumentID IN (1, 1001, 100000)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Trade (schema) | Confluence | Schema context for Trade views |
| Trade.GetInstrument | Confluence | View referenced in documentation |

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 20+ analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetInstrument | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrument.sql*
