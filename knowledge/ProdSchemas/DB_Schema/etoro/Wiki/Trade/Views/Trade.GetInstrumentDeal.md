# Trade.GetInstrumentDeal

> Instrument deal view with CurrencyType-derived InstrumentTypeID (from buy currency), pair name, trade params, and industry - used when instrument type must come from Dictionary.Currency, not InstrumentMetaData.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentDeal exposes instrument data for deal/trading contexts where the asset type (InstrumentTypeID) must be derived from the buy-side currency's CurrencyTypeID in Dictionary.Currency, rather than from InstrumentMetaData.InstrumentTypeID. This differs from Trade.GetInstrument, which uses IMD.InstrumentTypeID and filters WHERE InstrumentTypeID IS NOT NULL. GetInstrumentDeal has no such filter and includes all instruments with InstrumentID != 0.

This view exists to support flows that rely on currency-based asset classification (e.g., forex pairs always get type from the base currency) rather than the metadata layer. The Name column is built as BuyAbbreviation/SellAbbreviation (e.g., "EUR/USD", "JPY/USD"). Industry comes from InstrumentMetaData (varchar label or ISNULL(StocksIndustryID,0) depending on schema).

Data flows: Read-only view. Consumers include procedures and APIs that need deal instrument data without the InstrumentTypeID IS NOT NULL restriction of GetInstrument.

---

## 2. Business Logic

### 2.1 InstrumentTypeID from Currency, Not Metadata

**What**: InstrumentTypeID is TDCUR_BUY.CurrencyTypeID, not InstrumentMetaData.InstrumentTypeID.

**Columns/Parameters Involved**: `InstrumentTypeID`, `TDCUR_BUY.CurrencyTypeID`, `BuyCurrencyID`

**Rules**:
- GetInstrument uses IMD.InstrumentTypeID and filters InstrumentTypeID IS NOT NULL
- GetInstrumentDeal uses Dictionary.Currency.CurrencyTypeID (buy side) - no InstrumentMetaData type filter
- Ensures instruments are included even when InstrumentMetaData.InstrumentTypeID is NULL

### 2.2 Pair Name Construction

**What**: Name = BuyAbbreviation + '/' + SellAbbreviation from Dictionary.Currency.

**Columns/Parameters Involved**: `Name`, `TDCUR_BUY.Abbreviation`, `TDCUR_SEL.Abbreviation`

**Rules**:
- Forex: "EUR/USD", "GBP/USD", "USD/JPY"
- Stocks: Buy currency is the asset, Sell is denomination (e.g., "Bayer/EUR")

---

## 3. Data Overview

| InstrumentID | BuyCurrencyID | SellCurrencyID | InstrumentTypeID | Name | TradeRange | DollarRatio | IsMajor | Industry | OperationMode |
|--------------|---------------|----------------|------------------|------|------------|-------------|---------|----------|---------------|
| 1 | 2 | 1 | 1 | EUR/USD | 5 | 1 | 1 | Basic Materials | 0 |
| 2 | 3 | 1 | 1 | GBP/USD | 5 | 1 | 1 | NULL | 0 |
| 3 | 8 | 1 | 1 | NZD/USD | 5 | 1 | 1 | NULL | 0 |
| 4 | 1 | 7 | 1 | USD/CAD | 5 | 1 | 1 | NULL | 0 |
| 5 | 4 | 1 | 1 | JPY/USD | 5 | 100 | 0 | NULL | 0 |

**Selection criteria:** First 5 instruments. Forex majors show DollarRatio=1; JPY/USD shows DollarRatio=100. Industry from InstrumentMetaData (varchar label or 0). OperationMode=0 (standard).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | From Trade.Instrument. Primary key. Filtered WHERE != 0. |
| 2 | BuyCurrencyID | int | NO | 0 | CODE-BACKED | From Trade.Instrument. FK to Dictionary.Currency. Buy-side asset. For forex: base currency. For stocks: asset's CurrencyID. |
| 3 | SellCurrencyID | int | NO | 0 | CODE-BACKED | From Trade.Instrument. FK to Dictionary.Currency. Quote/denomination currency. |
| 4 | InstrumentTypeID | int | NO | - | CODE-BACKED | Computed in view: TDCUR_BUY.CurrencyTypeID. Asset class from buy currency (Dictionary.Currency.CurrencyTypeID), NOT from InstrumentMetaData.InstrumentTypeID. 1=Forex, 2=Commodity, 5=Stocks, 10=Crypto. |
| 5 | Name | varchar | NO | - | CODE-BACKED | Computed in view: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Pair display name (e.g., "EUR/USD", "JPY/USD"). |
| 6 | TradeRange | smallint | NO | - | CODE-BACKED | From Trade.Instrument. Allowed pip distance for pending orders. |
| 7 | DollarRatio | decimal(8,2) | NO | - | CODE-BACKED | From Trade.Instrument. Price scaling for USD. 1 for most; 100 for JPY pairs. |
| 8 | Passport | timestamp | NO | - | CODE-BACKED | From Trade.Instrument. Row version/concurrency token. |
| 9 | PipDifferenceThreshold | bigint | YES | - | CODE-BACKED | From Trade.Instrument. Max pip difference for price validation. |
| 10 | IsMajor | bit | NO | 0 | CODE-BACKED | From Trade.Instrument. 1 = major instrument, 0 = minor. Affects spread and leverage caps. |
| 11 | Industry | varchar/int | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. Industry sector label (varchar) or ISNULL(StocksIndustryID,0). NULL for forex; value for stocks. |
| 12 | OperationMode | tinyint | YES | 0 | CODE-BACKED | From Trade.Instrument. 0 = standard, 1 = alternate (e.g., European stock CFDs in non-USD). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | Base instrument. |
| BuyCurrencyID | Dictionary.Currency | FK | Buy-side asset; used for InstrumentTypeID via CurrencyTypeID. |
| SellCurrencyID | Dictionary.Currency | FK | Quote currency. |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Industry (StocksIndustryID or label). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentDeal (view)
├── Trade.Instrument (table)
├── Dictionary.Currency (table) [BuyCurrencyID]
├── Dictionary.Currency (table) [SellCurrencyID]
└── Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FROM - core instrument, BuyCurrencyID, SellCurrencyID |
| Dictionary.Currency | Table | INNER JOIN x2 - buy and sell currency abbreviations, buy-side CurrencyTypeID |
| Trade.InstrumentMetaData | Table | INNER JOIN - Industry |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get deal data for forex majors

```sql
SELECT InstrumentID, Name, InstrumentTypeID, DollarRatio, IsMajor, Industry
FROM Trade.GetInstrumentDeal WITH (NOLOCK)
WHERE InstrumentTypeID = 1
  AND IsMajor = 1
ORDER BY InstrumentID;
```

### 8.2 Find instruments by industry

```sql
SELECT gid.InstrumentID, gid.Name, gid.InstrumentTypeID, gid.Industry, gid.OperationMode
FROM Trade.GetInstrumentDeal gid WITH (NOLOCK)
WHERE gid.Industry IS NOT NULL
ORDER BY gid.Industry, gid.InstrumentID;
```

### 8.3 JPY pairs with DollarRatio

```sql
SELECT InstrumentID, Name, BuyCurrencyID, SellCurrencyID, DollarRatio, TradeRange
FROM Trade.GetInstrumentDeal WITH (NOLOCK)
WHERE DollarRatio = 100;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.1/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentDeal | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrumentDeal.sql*
