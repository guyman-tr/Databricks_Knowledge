# Trade.GetAllInstrumentDisplayDatasForAPI

> Retrieves all active instrument display data including metadata, ticker, provider visibility, and futures details for the API layer.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns enriched instrument display data for all visible/enabled instruments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure serves the API's instrument discovery endpoint by returning display-ready data for all active instruments across all asset types. It is similar to `Trade.GetAllInstrumentData` but without the type filter and with a slightly different column set (includes Ticker, MinimalTick). This bulk read is called on API startup or cache refresh to populate the instrument catalog.

The procedure exists as the primary instrument catalog feed for the public-facing API. All instruments that are either provider-enabled or user-visible are returned with their display properties, price source, and futures metadata.

Data flows from `Trade.InstrumentMetaData` (core), enriched via `Trade.ProviderToInstrument` (visibility), `Trade.FuturesMetaData` (futures details, LEFT), and `Dictionary.PriceSourceName` (price source, LEFT). Only instruments with a valid InstrumentTypeID are included.

---

## 2. Business Logic

### 2.1 Active Instrument Filter

**What**: Only returns instruments that are either enabled by a provider or visible to end users.

**Columns/Parameters Involved**: `pti.Enabled`, `imd.InstrumentVisible`, `imd.InstrumentTypeID`

**Rules**:
- `WHERE (pti.Enabled = 1 OR imd.InstrumentVisible = 1) AND imd.InstrumentTypeID IS NOT NULL`
- Same visibility logic as GetAllInstrumentData but without the type name filter

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. Output columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Unique instrument identifier. FK to Trade.Instrument. |
| 2 | InstrumentDisplayName | NVARCHAR | YES | - | CODE-BACKED | Human-readable instrument name shown in the platform UI. |
| 3 | Ticker | NVARCHAR | YES | - | CODE-BACKED | Short trading ticker symbol (e.g., AAPL, BTC, EURUSD). |
| 4 | CurrencyTypeID | INT | YES | - | CODE-BACKED | Aliased from InstrumentTypeID. FK to Dictionary.CurrencyType for asset type classification. |
| 5 | ExchangeID | INT | YES | - | CODE-BACKED | FK to exchange lookup. Identifies which exchange this instrument trades on. |
| 6 | SymbolFull | NVARCHAR | YES | - | CODE-BACKED | Full symbol identifier including contract/pair details. |
| 7 | StocksIndustryID | INT | YES | - | CODE-BACKED | FK to Dictionary.StocksIndustry. Industry classification for stocks. |
| 8 | InstrumentTypeSubCategoryID | INT | YES | - | CODE-BACKED | FK to Dictionary.InstrumentTypeSubCategory. Sub-classification within asset type. |
| 9 | PriceSourceName | VARCHAR | NO | '' | CODE-BACKED | Resolved price source name from Dictionary.PriceSourceName. Empty string if not configured. |
| 10 | HasExpirationDate | BIT | YES | - | CODE-BACKED | Aliased from ContractExpire. Whether this is an expiring futures instrument. |
| 11 | VisibleInternallyOnly | BIT | YES | - | CODE-BACKED | Whether this instrument is restricted to internal users only (not visible to public). |
| 12 | Multiplier | DECIMAL | YES | - | CODE-BACKED | Futures contract multiplier. NULL for non-futures instruments. |
| 13 | MinimalTick | DECIMAL | YES | - | CODE-BACKED | Minimum price movement (tick size) for futures. NULL for non-futures. |
| 14 | LastTradingDateTime | DATETIME | YES | - | CODE-BACKED | Last date/time for trading before futures expiration. NULL for non-futures. |
| 15 | ExpirationDateTime | DATETIME | YES | - | CODE-BACKED | Futures contract expiration date/time. NULL for non-futures. |
| 16 | SettlementTime | DATETIME | YES | - | CODE-BACKED | Daily settlement time for futures margin calculations. NULL for non-futures. |
| 17 | IndexPointValue | DECIMAL | YES | - | CODE-BACKED | Dollar value per index point for index futures. NULL for non-index futures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.InstrumentMetaData | INNER JOIN | Core instrument display properties |
| (body) | Trade.ProviderToInstrument | INNER JOIN | Provider visibility configuration |
| (body) | Trade.FuturesMetaData | LEFT JOIN | Futures-specific contract metadata |
| (body) | Dictionary.PriceSourceName | LEFT JOIN | Price source name resolution |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllInstrumentDisplayDatasForAPI (procedure)
+-- Trade.InstrumentMetaData (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.FuturesMetaData (table)
+-- Dictionary.PriceSourceName (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | INNER JOIN - core instrument data |
| Trade.ProviderToInstrument | Table | INNER JOIN - provider visibility |
| Trade.FuturesMetaData | Table | LEFT JOIN - futures details |
| Dictionary.PriceSourceName | Table | LEFT JOIN - price source labels |

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

### 8.1 Execute the procedure
```sql
EXEC Trade.GetAllInstrumentDisplayDatasForAPI;
```

### 8.2 Compare to GetAllInstrumentData for a specific type
```sql
EXEC Trade.GetAllInstrumentData @InstrumentType = 'Stocks';
-- vs
SELECT * FROM (EXEC Trade.GetAllInstrumentDisplayDatasForAPI) WHERE CurrencyTypeID = 5; -- Use via app code
```

### 8.3 Find internal-only instruments
```sql
SELECT  imd.InstrumentID, imd.InstrumentDisplayName, imd.Ticker
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
        INNER JOIN Trade.ProviderToInstrument pti WITH (NOLOCK) ON pti.InstrumentID = imd.InstrumentID
WHERE   pti.VisibleInternallyOnly = 1
        AND (pti.Enabled = 1 OR imd.InstrumentVisible = 1);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.6/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllInstrumentDisplayDatasForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllInstrumentDisplayDatasForAPI.sql*
