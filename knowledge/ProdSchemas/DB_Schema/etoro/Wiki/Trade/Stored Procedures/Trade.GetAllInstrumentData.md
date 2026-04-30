# Trade.GetAllInstrumentData

> Retrieves comprehensive instrument data including metadata, provider configuration, futures details, and price source for a specific instrument type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns enriched instrument data filtered by instrument type name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a comprehensive instrument data view filtered by instrument type (e.g., "Stocks", "Crypto", "Commodities"). It combines instrument metadata, provider visibility configuration, futures contract details (when applicable), price source names, and currency pair information into a single result set. This serves internal operations tools that need a complete picture of all instruments in a specific asset class.

The procedure exists because instrument management requires cross-referencing multiple tables - metadata, provider configuration, futures specifics, and currency pairs. This procedure pre-joins them and applies the visibility/enabled filter to return only instruments that are either enabled by a provider or visible to end users.

Data flows from `Trade.InstrumentMetaData` as the core, enriched via JOINs to `Trade.ProviderToInstrument` (provider config), `Trade.FuturesMetaData` (futures details, LEFT JOIN), `Dictionary.PriceSourceName` (price source label, LEFT JOIN), `Trade.Instrument` (currency pairs, LEFT JOIN), and `Dictionary.CurrencyType` (type name filter, INNER JOIN).

---

## 2. Business Logic

### 2.1 Visibility Filter

**What**: Only returns instruments that are either enabled by a provider or visible to end users.

**Columns/Parameters Involved**: `pti.Enabled`, `imd.InstrumentVisible`

**Rules**:
- `WHERE (pti.Enabled = 1 OR imd.InstrumentVisible = 1)` - instrument must be provider-enabled OR user-visible
- Also requires `imd.InstrumentTypeID IS NOT NULL` - instruments must have a type classification

### 2.2 Type-Based Filtering

**What**: Filters by the CurrencyType name string to return only instruments of a specific asset class.

**Columns/Parameters Involved**: `@InstrumentType`, `ct.Name`

**Rules**:
- `ct.Name = @InstrumentType` matches against Dictionary.CurrencyType.Name
- Common values: "Stocks", "Commodities", "Currencies", "Indices", "Crypto", "ETF"

### 2.3 Column Aliasing for API Compatibility

**What**: Several columns are aliased for backward API compatibility.

**Columns/Parameters Involved**: `InstrumentTypeID`, `ContractExpire`

**Rules**:
- `InstrumentTypeID AS CurrencyTypeID` - legacy alias from when types were called "CurrencyType"
- `ContractExpire AS HasExpirationDate` - semantic alias clarifying the boolean meaning

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentType | VARCHAR(50) | NO | - | CODE-BACKED | Name of the instrument type to filter by. Matched against Dictionary.CurrencyType.Name. Examples: "Stocks", "Commodities", "Crypto", "Currencies", "Indices", "ETF". |
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Unique instrument identifier from Trade.InstrumentMetaData. |
| 3 | InstrumentDisplayName | NVARCHAR | YES | - | CODE-BACKED | Human-readable display name shown in the trading platform. |
| 4 | CurrencyTypeID | INT | YES | - | CODE-BACKED | Aliased from InstrumentTypeID. FK to Dictionary.CurrencyType. Legacy name from when asset types were called "currency types". |
| 5 | ExchangeID | INT | YES | - | CODE-BACKED | FK to exchange lookup. Identifies the exchange for this instrument. |
| 6 | SymbolFull | NVARCHAR | YES | - | CODE-BACKED | Full ticker symbol including contract/pair details. |
| 7 | StocksIndustryID | INT | YES | - | CODE-BACKED | FK to Dictionary.StocksIndustry. Industry sector for stocks. |
| 8 | InstrumentTypeSubCategoryID | INT | YES | - | CODE-BACKED | FK to Dictionary.InstrumentTypeSubCategory. Sub-classification within the asset type. |
| 9 | PriceSourceName | VARCHAR | NO | '' | CODE-BACKED | Resolved name of the price feed source from Dictionary.PriceSourceName. Empty string if no price source configured. |
| 10 | HasExpirationDate | BIT | YES | - | CODE-BACKED | Aliased from ContractExpire. Whether this instrument has a contract expiration (futures). 1 = has expiration. |
| 11 | Tradable | BIT | YES | - | CODE-BACKED | Whether the instrument is currently tradable on the platform. |
| 12 | InstrumentVisible | BIT | YES | - | CODE-BACKED | Whether the instrument is visible to end users in the UI. |
| 13 | VisibleInternallyOnly | BIT | YES | - | CODE-BACKED | From ProviderToInstrument. Whether this instrument is visible only to internal users (not public). |
| 14 | BuyCurrencyID | INT | YES | - | CODE-BACKED | FK to Dictionary.Currency. The buy-side currency of the instrument pair. |
| 15 | SellCurrencyID | INT | YES | - | CODE-BACKED | FK to Dictionary.Currency. The sell-side currency of the instrument pair. |
| 16 | SettlementTime | DATETIME | YES | - | CODE-BACKED | From FuturesMetaData. Daily settlement time for futures contracts. NULL for non-futures. |
| 17 | Multiplier | DECIMAL | YES | - | CODE-BACKED | From FuturesMetaData. Contract multiplier for PnL calculation. NULL for non-futures. |
| 18 | LastTradingDateTime | DATETIME | YES | - | CODE-BACKED | From FuturesMetaData. Last trading date before contract expiration. NULL for non-futures. |
| 19 | ExpirationDateTime | DATETIME | YES | - | CODE-BACKED | From FuturesMetaData. Contract expiration date/time. NULL for non-futures. |
| 20 | IndexPointValue | DECIMAL | YES | - | CODE-BACKED | From FuturesMetaData. Dollar value per index point for index futures. NULL for non-index futures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.InstrumentMetaData | INNER JOIN | Core instrument properties |
| (body) | Trade.ProviderToInstrument | INNER JOIN | Provider-instrument mapping and visibility |
| (body) | Trade.FuturesMetaData | LEFT JOIN | Futures-specific metadata (optional) |
| (body) | Dictionary.PriceSourceName | LEFT JOIN | Price source label resolution |
| (body) | Trade.Instrument | LEFT JOIN | Currency pair (buy/sell currency) |
| (body) | Dictionary.CurrencyType | INNER JOIN | Instrument type classification for filtering |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllInstrumentData (procedure)
+-- Trade.InstrumentMetaData (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.FuturesMetaData (table)
+-- Dictionary.PriceSourceName (table)
+-- Trade.Instrument (table)
+-- Dictionary.CurrencyType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | INNER JOIN - core instrument data |
| Trade.ProviderToInstrument | Table | INNER JOIN - provider visibility config |
| Trade.FuturesMetaData | Table | LEFT JOIN - futures contract details |
| Dictionary.PriceSourceName | Table | LEFT JOIN - price source name resolution |
| Trade.Instrument | Table | LEFT JOIN - currency pair information |
| Dictionary.CurrencyType | Table | INNER JOIN - type name filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all stock instruments
```sql
EXEC Trade.GetAllInstrumentData @InstrumentType = 'Stocks';
```

### 8.2 Get all crypto instruments
```sql
EXEC Trade.GetAllInstrumentData @InstrumentType = 'Crypto';
```

### 8.3 Find instrument types available in the system
```sql
SELECT  ct.CurrencyTypeID, ct.Name, COUNT(imd.InstrumentID) AS InstrumentCount
FROM    Dictionary.CurrencyType ct WITH (NOLOCK)
        LEFT JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON ct.CurrencyTypeID = imd.InstrumentTypeID
GROUP BY ct.CurrencyTypeID, ct.Name
ORDER BY InstrumentCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllInstrumentData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllInstrumentData.sql*
