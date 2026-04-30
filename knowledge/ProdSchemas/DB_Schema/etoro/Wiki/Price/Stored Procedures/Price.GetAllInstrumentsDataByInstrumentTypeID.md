# Price.GetAllInstrumentsDataByInstrumentTypeID

> Returns comprehensive instrument metadata for all instruments of a given type (or a single instrument within that type), joining instrument display data, provider settings, and futures-specific fields into a unified result set for the pricing configuration API.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentTypeID (required filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetAllInstrumentsDataByInstrumentTypeID is a data-access procedure that returns a combined instrument information payload to the pricing configuration API. It aggregates data from four tables - InstrumentMetaData, ProviderToInstrument, Instrument, and FuturesMetaData - into a single result set covering all the metadata a pricing system needs to configure, display, or route prices for instruments of a given type.

This procedure exists because the pricing engine and its configuration UI need a single endpoint for instrument lookup by type. Without it, callers would need to join four tables themselves - and the `@InstrumentID` optional parameter enables the same procedure to power both list-all and get-one queries for a given type.

Data flows into this procedure from three instrument master tables: `Trade.InstrumentMetaData` (the primary source for display and classification data), `Trade.Instrument` (currency pair mapping), and `Trade.ProviderToInstrument` (provider visibility settings). The optional `Trade.FuturesMetaData` join enriches futures instruments with their contract-specific fields (SettlementTime, Multiplier, MinimalTick, expiry dates). For non-futures instruments, futures columns return NULL.

---

## 2. Business Logic

### 2.1 Visibility Filter: Enabled OR Visible

**What**: The WHERE clause uses OR logic: returns instruments where either the provider has enabled them OR they are marked as visible to instruments list.

**Columns/Parameters Involved**: `pti.Enabled`, `imd.InstrumentVisible`

**Rules**:
- `(pti.Enabled = 1 OR imd.InstrumentVisible = 1)` - an instrument qualifies if EITHER condition is true
- This means: a disabled-by-provider instrument that is still InstrumentVisible=1 will still be returned
- And: a not-InstrumentVisible instrument that a provider has explicitly Enabled=1 will also be returned
- Instruments where both Enabled=0 AND InstrumentVisible=0 are excluded
- The INNER JOIN on ProviderToInstrument means instruments with no provider assignment are excluded entirely

### 2.2 Optional Single-Instrument Filter

**What**: @InstrumentID defaults to NULL meaning "all instruments of this type". When provided, limits to one specific instrument.

**Columns/Parameters Involved**: `@InstrumentID`, `@InstrumentTypeID`

**Rules**:
- `@InstrumentTypeID` is always required (INT, no default)
- `@InstrumentID = NULL` -> returns all instruments of the given type matching the visibility filter
- `@InstrumentID IS NOT NULL` -> adds `AND imd.InstrumentID = @InstrumentID` - functions as a single-instrument lookup, but the type filter still applies (caller must pass correct type)

### 2.3 Legacy Column Alias: InstrumentTypeID -> CurrencyTypeID

**What**: The output column `CurrencyTypeID` is actually `imd.InstrumentTypeID`.

**Rules**:
- `imd.InstrumentTypeID AS CurrencyTypeID` - the alias CurrencyTypeID is misleading; this is the instrument classification type, not a currency type
- This alias likely predates the InstrumentTypeID naming convention; callers must use `CurrencyTypeID` as the column name in the result set
- Similarly, `imd.ContractExpire AS HasExpirationDate` renames the boolean flag - 1 = instrument has an expiration date (futures), 0 = perpetual

### 2.4 Futures Fields via LEFT JOIN

**What**: FuturesMetaData columns are returned for all instruments; they are NULL for non-futures instruments.

**Columns/Parameters Involved**: `SettlementTime`, `Multiplier`, `MinimalTick`, `LastTradingDateTime`, `ExpirationDateTime`, `IndexPointValue`

**Rules**:
- LEFT JOIN on FuturesMetaData - non-futures instruments get NULL for all six futures columns
- For futures instruments: `ExpirationDateTime` gives the contract expiry, `LastTradingDateTime` the last trading day, `Multiplier` the contract multiplier, `MinimalTick` the minimum price movement, `SettlementTime` the daily settlement time, `IndexPointValue` the cash value per index point

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentTypeID | INT | NOT NULL | - | CODE-BACKED | Required. Filters instruments by classification type. Maps to Trade.InstrumentMetaData.InstrumentTypeID. Common types: 1=Currency pairs (forex), 2=Commodities, 5=Stocks, 6=ETFs, 10=Crypto. Determines which instruments appear in the result set. |
| 2 | @InstrumentID | INT | YES | NULL | CODE-BACKED | Optional single-instrument filter. When NULL (default), returns all qualifying instruments of the given type. When provided, returns only that specific instrument (if it matches the type and visibility filter). Enables the same procedure for both list and single-record access. |

**Result set columns** (22 columns):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | InstrumentID | imd.InstrumentID | eToro instrument identifier |
| 2 | InstrumentDisplayName | imd.InstrumentDisplayName | Human-readable name shown in the UI |
| 3 | CurrencyTypeID | imd.InstrumentTypeID | **Legacy alias for InstrumentTypeID** - the instrument classification type (1=FX, 2=Commodity, 5=Stock, etc.). The name "CurrencyTypeID" is a legacy misnomer. |
| 4 | ExchangeID | imd.ExchangeID | Exchange where the instrument is traded. FK to Price.Exchange. |
| 5 | SymbolFull | imd.SymbolFull | Full symbol string (e.g., "EURUSD", "AAPL") |
| 6 | Symbol | imd.Symbol | Abbreviated symbol used in some systems |
| 7 | StocksIndustryID | imd.StocksIndustryID | Industry classification for stock instruments; NULL for non-stocks |
| 8 | InstrumentTypeSubCategoryID | imd.InstrumentTypeSubCategoryID | Sub-category within the instrument type for finer classification |
| 9 | HasExpirationDate | imd.ContractExpire | **Renamed ContractExpire**: 1 = instrument has an expiration date (futures/options), 0 = perpetual instrument |
| 10 | Tradable | imd.Tradable | Whether the instrument is currently tradable: 1=Yes, 0=No (suspended/restricted) |
| 11 | InstrumentVisible | imd.InstrumentVisible | Whether the instrument is visible in the instrument list to clients |
| 12 | Cusip | imd.Cusip | CUSIP identifier for US securities; NULL for non-securities |
| 13 | ISINCode | imd.ISINCode | International Securities Identification Number; NULL for non-securities |
| 14 | VisibleInternallyOnly | pti.VisibleInternallyOnly | From Trade.ProviderToInstrument. If 1, the instrument is visible to internal users only, not client-facing |
| 15 | BuyCurrencyID | inst.BuyCurrencyID | From Trade.Instrument. The base/buy currency of the instrument. FK to Dictionary.Currency. |
| 16 | SellCurrencyID | inst.SellCurrencyID | From Trade.Instrument. The quote/sell currency of the instrument. FK to Dictionary.Currency. |
| 17 | SettlementTime | tfm.SettlementTime | From Trade.FuturesMetaData (LEFT JOIN). Daily settlement time for futures. NULL for non-futures. |
| 18 | Multiplier | tfm.Multiplier | From Trade.FuturesMetaData (LEFT JOIN). Contract multiplier (e.g., 1000 for mini contracts). NULL for non-futures. |
| 19 | MinimalTick | tfm.MinimalTick | From Trade.FuturesMetaData (LEFT JOIN). Minimum price increment for the futures contract. NULL for non-futures. |
| 20 | LastTradingDateTime | tfm.LastTradingDateTime | From Trade.FuturesMetaData (LEFT JOIN). Last date/time trading is permitted before expiry. NULL for non-futures. |
| 21 | ExpirationDateTime | tfm.ExpirationDateTime | From Trade.FuturesMetaData (LEFT JOIN). Contract expiration timestamp. NULL for non-futures (perpetual instruments). |
| 22 | IndexPointValue | tfm.IndexPointValue | From Trade.FuturesMetaData (LEFT JOIN). Cash value per index point for index futures (e.g., $50 per S&P 500 point). NULL for non-futures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentTypeID | Trade.InstrumentMetaData | JOIN filter | Filters by InstrumentTypeID - primary data source |
| InstrumentID | Trade.ProviderToInstrument | INNER JOIN | Filters to instruments with provider assignments; supplies VisibleInternallyOnly |
| InstrumentID | Trade.Instrument | INNER JOIN | Supplies BuyCurrencyID and SellCurrencyID |
| InstrumentID | Trade.FuturesMetaData | LEFT JOIN | Supplies futures contract details for futures instruments |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (pricing configuration API) | @InstrumentTypeID | CALLER | Called by the pricing configuration service to retrieve instrument data by type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetAllInstrumentsDataByInstrumentTypeID (procedure)
+-- Trade.InstrumentMetaData (table) - primary source, type filter
+-- Trade.ProviderToInstrument (table) - provider visibility data
+-- Trade.Instrument (table) - currency pair (BuyCurrencyID, SellCurrencyID)
+-- Trade.FuturesMetaData (table) - futures contract details (LEFT JOIN)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | Primary FROM source; InstrumentTypeID filter; most output columns |
| Trade.ProviderToInstrument | Table | INNER JOIN on InstrumentID; provides VisibleInternallyOnly and Enabled filter |
| Trade.Instrument | Table | INNER JOIN on InstrumentID; provides BuyCurrencyID and SellCurrencyID |
| Trade.FuturesMetaData | Table | LEFT JOIN on InstrumentID; provides 6 futures-specific columns (NULL for non-futures) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (pricing configuration API) | External | Calls this procedure to retrieve instrument metadata by type |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No error handling. No transaction. All JOINed tables use WITH (NOLOCK) - READ UNCOMMITTED for performance. INNER JOINs on ProviderToInstrument and Instrument mean instruments must exist in both tables to be returned. The @InstrumentTypeID parameter has no default - callers must always provide it. No validation is performed on the InstrumentTypeID value (invalid type returns empty result set silently).

---

## 8. Sample Queries

### 8.1 Get all enabled/visible stocks (InstrumentTypeID=5)

```sql
EXEC Price.GetAllInstrumentsDataByInstrumentTypeID @InstrumentTypeID = 5;
```

### 8.2 Get data for a specific futures instrument

```sql
EXEC Price.GetAllInstrumentsDataByInstrumentTypeID
    @InstrumentTypeID = 4,   -- futures type
    @InstrumentID = 1234;
```

### 8.3 Equivalent manual query

```sql
SELECT imd.InstrumentID,
       imd.InstrumentDisplayName,
       imd.InstrumentTypeID AS CurrencyTypeID,
       imd.ExchangeID,
       imd.SymbolFull,
       imd.Symbol,
       imd.StocksIndustryID,
       imd.InstrumentTypeSubCategoryID,
       imd.ContractExpire AS HasExpirationDate,
       imd.Tradable,
       imd.InstrumentVisible,
       imd.Cusip,
       imd.ISINCode,
       pti.VisibleInternallyOnly,
       inst.BuyCurrencyID,
       inst.SellCurrencyID,
       tfm.SettlementTime,
       tfm.Multiplier,
       tfm.MinimalTick,
       tfm.LastTradingDateTime,
       tfm.ExpirationDateTime,
       tfm.IndexPointValue
FROM   Trade.InstrumentMetaData imd WITH (NOLOCK)
       INNER JOIN Trade.ProviderToInstrument pti WITH (NOLOCK) ON pti.InstrumentID = imd.InstrumentID
       INNER JOIN Trade.Instrument inst WITH (NOLOCK) ON imd.InstrumentID = inst.InstrumentID
       LEFT  JOIN Trade.FuturesMetaData tfm WITH (NOLOCK) ON tfm.InstrumentID = imd.InstrumentID
WHERE  (pti.Enabled = 1 OR imd.InstrumentVisible = 1)
  AND  imd.InstrumentTypeID = 5;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetAllInstrumentsDataByInstrumentTypeID | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetAllInstrumentsDataByInstrumentTypeID.sql*
