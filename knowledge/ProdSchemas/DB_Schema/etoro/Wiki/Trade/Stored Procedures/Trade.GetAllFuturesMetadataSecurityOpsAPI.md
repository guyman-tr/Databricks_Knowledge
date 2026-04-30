# Trade.GetAllFuturesMetadataSecurityOpsAPI

> Retrieves all futures instrument metadata with associated display information for the Security Operations API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns combined futures metadata and instrument display data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure serves the Security Operations API by providing a complete view of all futures instruments with their contract metadata. Futures are derivative financial instruments with expiration dates, multipliers, and settlement methods - this procedure combines the structural instrument data (display name, symbol, exchange) with futures-specific metadata (expiration, settlement, multiplier).

The procedure exists because futures instruments require additional metadata beyond what standard instruments have. Security Operations teams need this combined view to manage futures contract lifecycle - monitoring expiring contracts, validating settlement methods, and overseeing instrument configuration.

Data is read from `Trade.FuturesMetaData` (the driving table) LEFT JOINed to `Trade.InstrumentMetaData` for display information. The LEFT JOIN ensures that futures records without matching instrument metadata are still returned, which could indicate orphaned or newly-created futures entries.

---

## 2. Business Logic

### 2.1 Futures-to-Instrument Enrichment

**What**: Combines futures contract data with instrument display data via InstrumentID.

**Columns/Parameters Involved**: `FuturesMetaData.InstrumentID`, `InstrumentMetaData.InstrumentID`

**Rules**:
- LEFT JOIN from FuturesMetaData to InstrumentMetaData ensures all futures records are returned even without instrument metadata
- No filtering - returns ALL futures instruments (no WHERE clause)
- Uses NOLOCK on both tables for non-blocking reads

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. Output columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument identifier from InstrumentMetaData. Links to Trade.Instrument. May be NULL for orphaned futures entries (due to LEFT JOIN). |
| 2 | InstrumentDisplayName | NVARCHAR | YES | - | CODE-BACKED | Human-readable display name of the futures instrument shown in the trading platform UI. |
| 3 | Exchange | NVARCHAR | YES | - | CODE-BACKED | Name of the exchange where the futures contract trades (e.g., CME, NYMEX). |
| 4 | Industry | NVARCHAR | YES | - | CODE-BACKED | Industry classification of the underlying asset. |
| 5 | CompanyInfo | NVARCHAR | YES | - | CODE-BACKED | Extended company/asset information for the underlying instrument. |
| 6 | InstrumentVisible | BIT | YES | - | CODE-BACKED | Whether the instrument is visible to end users on the trading platform. 1 = visible, 0 = hidden/internal only. |
| 7 | Symbol | NVARCHAR | YES | - | CODE-BACKED | Short ticker symbol for the instrument (e.g., CL, ES, NQ). |
| 8 | CandleTimeframeGroup | INT | YES | - | CODE-BACKED | Grouping identifier for candle chart timeframe configuration. |
| 9 | SymbolFull | NVARCHAR | YES | - | CODE-BACKED | Full symbol identifier including contract details (e.g., CLF25 for crude oil January 2025). |
| 10 | Tradable | BIT | YES | - | CODE-BACKED | Whether the instrument is currently available for trading. 1 = tradable, 0 = suspended/not tradable. |
| 11 | ExchangeID | INT | YES | - | CODE-BACKED | FK to the exchange lookup table. Identifies which exchange this instrument belongs to. |
| 12 | StocksIndustryID | INT | YES | - | CODE-BACKED | FK to Dictionary.StocksIndustry. Classifies the instrument by industry sector. |
| 13 | ISINCode | NVARCHAR | YES | - | CODE-BACKED | International Securities Identification Number for the underlying instrument. |
| 14 | ISINCountryCode | NVARCHAR | YES | - | CODE-BACKED | Two-letter country code portion of the ISIN. |
| 15 | ContractExpire | BIT | YES | - | CODE-BACKED | Whether this futures instrument has an expiration date. 1 = expires, 0 = perpetual/rolling. |
| 16 | InstrumentTypeSubCategoryID | INT | YES | - | CODE-BACKED | FK to Dictionary.InstrumentTypeSubCategory. Sub-classification within the instrument type. |
| 17 | InstrumentTypeID | INT | YES | - | CODE-BACKED | FK to Dictionary.CurrencyType. The broad instrument type category (e.g., Commodities, Indices). |
| 18 | PriceSourceID | INT | YES | - | CODE-BACKED | FK to Dictionary.PriceSourceName. Identifies the price feed source for this instrument. |
| 19 | Cusip | NVARCHAR | YES | - | CODE-BACKED | CUSIP identifier for US/Canadian securities underlying the futures contract. |
| 20 | UnderlyingExchangeID | INT | YES | - | CODE-BACKED | Exchange ID for the underlying asset (may differ from the futures exchange). |
| 21 | SubCategory | NVARCHAR | YES | - | CODE-BACKED | Display name of the instrument sub-category. |
| 22 | Multiplier | DECIMAL | YES | - | CODE-BACKED | Contract multiplier - the dollar value per point of futures price movement. Critical for PnL calculation. |
| 23 | MinimalTick | DECIMAL | YES | - | CODE-BACKED | Minimum price movement (tick size) for the futures contract. |
| 24 | LastTradingDateTime | DATETIME | YES | - | CODE-BACKED | Last date/time the contract can be traded before expiration. After this, the contract settles. |
| 25 | ExpirationDateTime | DATETIME | YES | - | CODE-BACKED | Contract expiration date/time. Positions must be closed or rolled before this date. |
| 26 | SettlementTime | DATETIME | YES | - | CODE-BACKED | Time of day when daily settlement occurs for margin calculations. |
| 27 | IndexPointValue | DECIMAL | YES | - | CODE-BACKED | Dollar value per index point for index futures contracts. |
| 28 | SettlementMethod | INT | YES | - | CODE-BACKED | Method of contract settlement at expiration: physical delivery vs cash settlement. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.FuturesMetaData | SELECT FROM | Driving table - all futures contract metadata |
| (body) | Trade.InstrumentMetaData | LEFT JOIN | Enrichment - instrument display information |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllFuturesMetadataSecurityOpsAPI (procedure)
+-- Trade.FuturesMetaData (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FuturesMetaData | Table | SELECT FROM - driving table for futures data |
| Trade.InstrumentMetaData | Table | LEFT JOIN - instrument display enrichment |

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
EXEC Trade.GetAllFuturesMetadataSecurityOpsAPI;
```

### 8.2 Check futures expiring in the next 30 days
```sql
SELECT  InstrumentID, InstrumentDisplayName, Symbol, ExpirationDateTime, LastTradingDateTime, SettlementMethod
FROM    (EXEC Trade.GetAllFuturesMetadataSecurityOpsAPI) -- Use via application or wrap in temp table
-- Alternative direct query:
SELECT  fm.InstrumentID, im.InstrumentDisplayName, im.Symbol, fm.ExpirationDateTime, fm.LastTradingDateTime, fm.SettlementMethod
FROM    Trade.FuturesMetaData fm WITH (NOLOCK)
        LEFT JOIN Trade.InstrumentMetaData im WITH (NOLOCK) ON im.InstrumentID = fm.InstrumentID
WHERE   fm.ExpirationDateTime BETWEEN GETUTCDATE() AND DATEADD(DAY, 30, GETUTCDATE());
```

### 8.3 Find futures without matching instrument metadata (orphaned entries)
```sql
SELECT  fm.InstrumentID, fm.Multiplier, fm.ExpirationDateTime
FROM    Trade.FuturesMetaData fm WITH (NOLOCK)
        LEFT JOIN Trade.InstrumentMetaData im WITH (NOLOCK) ON im.InstrumentID = fm.InstrumentID
WHERE   im.InstrumentID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.6/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllFuturesMetadataSecurityOpsAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllFuturesMetadataSecurityOpsAPI.sql*
