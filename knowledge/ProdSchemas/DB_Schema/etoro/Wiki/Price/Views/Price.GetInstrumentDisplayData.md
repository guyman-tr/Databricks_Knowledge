# Price.GetInstrumentDisplayData

> View that combines instrument internal name, market-facing display name, asset type, exchange, and industry classification into a single display-ready row per instrument - used by the pricing layer to resolve human-readable instrument metadata.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetInstrumentDisplayData answers: "What is the display label, asset type, exchange, and industry for this instrument?" It aggregates the four pieces of human-readable metadata a pricing consumer needs to label or categorize an instrument: the internal pair name (from Trade.GetInstrument), the market-facing display name (from Trade.InstrumentMetaData), the asset type string (from Dictionary.CurrencyType), the exchange identifier (from Trade.InstrumentMetaData), and the industry classification (from Trade.GetInstrument).

The view exists because the pricing configuration layer needs instrument labels for dashboards, configuration UIs, and feed management tools - but these attributes come from three different tables. Without this view, each consumer would join GetInstrument, Dictionary.CurrencyType, and InstrumentMetaData separately.

Key data characteristic: `Name` and `InstrumentDisplayName` may differ for instruments where internal pair notation does not match market convention. For example, instrument 5 has Name="JPY/USD" (internal: Buy=JPY, Sell=USD) but InstrumentDisplayName="USD/JPY" (market convention: USD is base). The LEFT JOIN to InstrumentMetaData means instruments without a metadata row still appear (InstrumentDisplayName and Exchange will be NULL for those).

---

## 2. Business Logic

### 2.1 Internal Name vs Display Name Divergence

**What**: The Name column uses the internal BuyCurrency/SellCurrency notation while InstrumentDisplayName uses market convention, which can differ for pairs where USD is the base (not the quote).

**Columns/Parameters Involved**: `Name`, `InstrumentDisplayName`

**Rules**:
- Name = TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation (computed in Trade.GetInstrument)
- InstrumentDisplayName = Trade.InstrumentMetaData.InstrumentDisplayName (manually configured market label)
- For pairs where USD is quote (EUR/USD, GBP/USD): Name = InstrumentDisplayName (e.g., "EUR/USD" = "EUR/USD")
- For pairs where USD is base (USD/JPY): internal Name = "JPY/USD" (JPY=BuyCurrency, USD=SellCurrency) but InstrumentDisplayName = "USD/JPY" (market convention)
- Pricing tools should use InstrumentDisplayName for user-facing labels and Name for internal routing/lookup

**Diagram**:
```
EUR/USD: BuyCurrency=EUR, SellCurrency=USD
  Name = "EUR/USD"           <- internal (matches market)
  InstrumentDisplayName = "EUR/USD"

USD/JPY: BuyCurrency=JPY, SellCurrency=USD (internal storage inverted)
  Name = "JPY/USD"           <- internal pair order
  InstrumentDisplayName = "USD/JPY"  <- market convention label
```

### 2.2 LEFT JOIN to InstrumentMetaData

**What**: InstrumentMetaData is LEFT JOINed, so instruments without a metadata row still appear with NULL InstrumentDisplayName and Exchange.

**Columns/Parameters Involved**: `InstrumentDisplayName`, `Exchange`

**Rules**:
- Instruments without a Trade.InstrumentMetaData row: InstrumentDisplayName=NULL, Exchange=NULL
- All instruments in Trade.GetInstrument are returned (WHERE TGI.InstrumentTypeID IS NOT NULL is redundant with GetInstrument's own filter)
- INNER JOIN to Dictionary.CurrencyType means instruments with no matching CurrencyTypeID would be excluded, but GetInstrument already filters InstrumentTypeID IS NOT NULL so this is a safe join

---

## 3. Data Overview

| InstrumentID | Name | InstrumentDisplayName | Type | Exchange | Industry | Meaning |
|---|---|---|---|---|---|---|
| 1 | EUR/USD | EUR/USD | Forex | FX | Basic Materials | EUR/USD forex pair. Name and DisplayName match. Exchange="FX" for all standard FX. Industry classification present (unusual for forex). |
| 2 | GBP/USD | GBP/USD | Forex | FX | NULL | GBP/USD. Industry NULL typical for forex instruments. |
| 3 | NZD/USD | NZD/USD | Forex | Helsinki Stock Exchange | NULL | NZD/USD with unexpected Exchange value - likely InstrumentMetaData data quality issue. |
| 4 | USD/CAD | USD/CAD | Forex | FX | NULL | Standard FX pair, matching names. |
| 5 | JPY/USD | USD/JPY | Forex | FX | NULL | Name diverges from DisplayName: internal stores as JPY/USD (Buy=JPY, Sell=USD), market shows as USD/JPY. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. From Trade.GetInstrument. All valid, non-placeholder instruments with a non-NULL InstrumentTypeID. |
| 2 | Name | varchar | NO | - | CODE-BACKED | Internal instrument pair name in Buy/Sell currency abbreviation format (e.g., "EUR/USD", "JPY/USD"). Computed in Trade.GetInstrument as BuyCurrencyAbbrev + '/' + SellCurrencyAbbrev. Use for internal routing and instrument identification. |
| 3 | InstrumentDisplayName | varchar | YES | - | CODE-BACKED | Market-facing display label from Trade.InstrumentMetaData. Uses market convention (e.g., "USD/JPY" where Name may show "JPY/USD"). NULL if no InstrumentMetaData row exists. Use for UI display and feed labels. |
| 4 | Type | varchar | NO | - | CODE-BACKED | Asset type name from Dictionary.CurrencyType (via InstrumentTypeID). Values: "Forex", "Commodity", "CFD", "Indices", "Stocks", "ETF", "Crypto". Used for categorizing instruments in pricing tools and dashboards. |
| 5 | Exchange | varchar | YES | - | CODE-BACKED | Exchange identifier string from Trade.InstrumentMetaData. Examples: "FX" (forex), "NASDAQ", "NYSE", exchange names for stocks. NULL if no InstrumentMetaData row or exchange not configured. |
| 6 | Industry | varchar | YES | - | CODE-BACKED | Industry classification from Trade.GetInstrument. Typically NULL for forex and crypto; populated for stocks (e.g., "Technology", "Healthcare", "Basic Materials"). From Trade.InstrumentMetaData via GetInstrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.GetInstrument | JOIN source | Provides Name, InstrumentTypeID, Industry |
| Type | Dictionary.CurrencyType | INNER JOIN (via InstrumentTypeID) | Resolves type name from InstrumentTypeID |
| InstrumentDisplayName, Exchange | Trade.InstrumentMetaData | LEFT JOIN (via InstrumentID) | Provides display name and exchange; NULL when absent |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetInstrumentDisplayData (view)
├── Trade.GetInstrument (view)
│     ├── Trade.Instrument (table)
│     ├── Dictionary.Currency (table)
│     └── Trade.InstrumentMetaData (table)
├── Dictionary.CurrencyType (table)
└── Trade.InstrumentMetaData (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View | FROM - provides InstrumentID, Name, InstrumentTypeID, Industry |
| Dictionary.CurrencyType | Table | INNER JOIN on InstrumentTypeID - resolves Type name |
| Trade.InstrumentMetaData | Table | LEFT JOIN on InstrumentID - provides InstrumentDisplayName and Exchange |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. LEFT JOIN to InstrumentMetaData means display columns can be NULL.

---

## 8. Sample Queries

### 8.1 Get display data for a specific instrument

```sql
SELECT InstrumentID, Name, InstrumentDisplayName, Type, Exchange, Industry
FROM Price.GetInstrumentDisplayData WITH (NOLOCK)
WHERE InstrumentID = 5;  -- Shows Name vs DisplayName divergence for USD/JPY
```

### 8.2 Find all instruments where internal name differs from display name

```sql
SELECT InstrumentID, Name, InstrumentDisplayName, Type
FROM Price.GetInstrumentDisplayData WITH (NOLOCK)
WHERE Name <> InstrumentDisplayName
  AND InstrumentDisplayName IS NOT NULL
ORDER BY Type, InstrumentID;
```

### 8.3 Count instruments by asset type

```sql
SELECT Type, COUNT(*) AS InstrumentCount
FROM Price.GetInstrumentDisplayData WITH (NOLOCK)
GROUP BY Type
ORDER BY InstrumentCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetInstrumentDisplayData | Type: View | Source: etoro/etoro/Price/Views/Price.GetInstrumentDisplayData.sql*
