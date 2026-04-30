# Trade.GetInstrumentMetaDataExtend

> Extended metadata view adding ExchangeID, UnderlyingExchangeID, and PriceSourceID to GetInstrumentMetaData - for consumers needing exchange and price-source identifiers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentMetaDataExtend extends Trade.GetInstrumentMetaData with three additional columns: ExchangeID, UnderlyingExchangeID, and PriceSourceID. It provides the same simplified metadata interface (IsTradable, IsVisible, Industry, ContractHasExpiration, etc.) plus exchange and price-source identifiers needed for fee config, price routing, and multi-exchange instruments.

This view exists for consumers that need exchange context (ExchangeID, UnderlyingExchangeID) or price feed source (PriceSourceID) alongside the base metadata. Trade.UpdateInstrumentsSymbolFullExtend and other extend-aware procedures use it when operating on instruments with exchange/price-source requirements.

Data flows: Read-only. Used by update and configuration procedures that require exchange or price-source awareness.

---

## 2. Business Logic

### 2.1 Additional Columns vs GetInstrumentMetaData

**What**: GetInstrumentMetaDataExtend = GetInstrumentMetaData + ExchangeID, UnderlyingExchangeID, PriceSourceID.

**Columns/Parameters Involved**: `ExchangeID`, `UnderlyingExchangeID`, `PriceSourceID`

**Rules**:
- ExchangeID: FK to Price.Exchange. Primary exchange for this instrument.
- UnderlyingExchangeID: Exchange for underlying when instrument is derivative. NULL for spot.
- PriceSourceID: 0 = eToro internal, 3 = Xignite (stocks/ETF). Validated via Dictionary.PriceSourceName.

---

## 3. Data Overview

| InstrumentID | InstrumentDisplayName | IsTradable | IsVisible | Industry | Symbol | SymbolFull | ExchangeID | UnderlyingExchangeID | PriceSourceID |
|--------------|------------------------|------------|-----------|----------|--------|------------|------------|----------------------|---------------|
| 1 | EUR/USD | 1 | 1 | 0 | EURUSD | EURUSD | NULL | NULL | 0 |
| 2 | GBP/USD | 1 | 1 | 0 | GBPUSD | GBPUSD | NULL | NULL | 0 |
| 1001 | Apple | 1 | 1 | 8 | AAPL | AAPL | 4 | NULL | 3 |
| 1002 | Alphabet | 1 | 1 | 8 | GOOG | GOOG | 4 | NULL | 3 |
| 100000 | Bitcoin | 1 | 1 | 0 | BTC | BTC | 8 | NULL | 0 |

**Selection criteria:** Representative mix: forex (1,2), stocks (1001, 1002 with ExchangeID=4 NASDAQ, PriceSourceID=3 Xignite), crypto (100000 with ExchangeID=8, PriceSourceID=0). Industry and SubCategory omitted for brevity.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | From Trade.InstrumentMetaData. Primary key. |
| 2 | InstrumentDisplayName | varchar(100) | NO | - | CODE-BACKED | From Trade.InstrumentMetaData. Human-readable name. |
| 3 | IsTradable | bit | YES | - | CODE-BACKED | Alias: Tradable. 1 = orders allowed, 0 = trading disabled. |
| 4 | IsVisible | int | YES | (1) | CODE-BACKED | Alias: InstrumentVisible. 1 = shown in UI, 0 = hidden. |
| 5 | Industry | int | NO | - | CODE-BACKED | Computed: ISNULL(StocksIndustryID, 0). Industry ID; 0 for forex/crypto. |
| 6 | ISINCode | varchar(30) | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. International Securities Identification Number. |
| 7 | ISINCountryCode | varchar(15) | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. Country prefix of ISIN. |
| 8 | ContractHasExpiration | bit | NO | (0) | CODE-BACKED | Alias: ContractExpire. 1 = has expiry (futures/options), 0 = no expiry. |
| 9 | Symbol | varchar(100) | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. Short ticker. |
| 10 | SymbolFull | varchar(100) | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. Full/canonical symbol, UNIQUE. |
| 11 | ExchangeID | int | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. FK to Price.Exchange. Primary exchange for instrument. 4=NASDAQ, 8=BATS. |
| 12 | UnderlyingExchangeID | int | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. Exchange for underlying when derivative. NULL for spot. |
| 13 | PriceSourceID | int | NO | (0) | CODE-BACKED | From Trade.InstrumentMetaData. Price feed source. 0 = eToro internal, 3 = Xignite. Dictionary.PriceSourceName. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.InstrumentMetaData | FK/Lookup | Base table. |
| ExchangeID | Price.Exchange | FK | Primary exchange. |
| UnderlyingExchangeID | Price.Exchange | FK | Underlying exchange for derivatives. |
| PriceSourceID | Dictionary.PriceSourceName | Lookup | Price feed source. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsSymbolFullExtend | - | FROM | Symbol full updates with exchange/price awareness. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentMetaDataExtend (view)
└── Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FROM - direct select with aliases + ExchangeID, UnderlyingExchangeID, PriceSourceID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsSymbolFullExtend | Procedure | FROM |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Instruments with Xignite price source

```sql
SELECT InstrumentID, InstrumentDisplayName, SymbolFull, ExchangeID, PriceSourceID
FROM Trade.GetInstrumentMetaDataExtend WITH (NOLOCK)
WHERE PriceSourceID = 3
ORDER BY InstrumentID;
```

### 8.2 Instruments by primary exchange

```sql
SELECT ExchangeID, COUNT(*) AS InstrumentCount
FROM Trade.GetInstrumentMetaDataExtend WITH (NOLOCK)
WHERE ExchangeID IS NOT NULL
GROUP BY ExchangeID
ORDER BY InstrumentCount DESC;
```

### 8.3 Extended metadata for symbol lookup

```sql
SELECT gime.InstrumentID, gime.InstrumentDisplayName, gime.SymbolFull,
       gime.ExchangeID, gime.UnderlyingExchangeID, gime.PriceSourceID
FROM Trade.GetInstrumentMetaDataExtend gime WITH (NOLOCK)
WHERE gime.SymbolFull = 'AAPL';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentMetaDataExtend | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrumentMetaDataExtend.sql*
