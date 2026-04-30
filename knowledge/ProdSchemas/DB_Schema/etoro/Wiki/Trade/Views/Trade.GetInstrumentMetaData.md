# Trade.GetInstrumentMetaData

> Simplified metadata view with friendly column aliases (IsTradable, IsVisible, Industry, ContractHasExpiration) for API and procedure consumers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentMetaData is a direct projection of Trade.InstrumentMetaData with renamed and computed columns tuned for consumers who expect friendlier names: Tradable -> IsTradable, InstrumentVisible -> IsVisible, ISNULL(StocksIndustryID,0) -> Industry, ContractExpire -> ContractHasExpiration. It exposes the subset of metadata fields most commonly used by procedures and APIs: identifiers, symbols, regulatory codes, and visibility/tradability flags.

This view exists to provide a stable, consumer-friendly interface without exposing internal column names. Trade.ClosePositionsByInstrumentID uses it to validate ContractHasExpiration: instruments must have ContractHasExpiration=1 to allow bulk close-by-instrument (e.g., oil, copper, natgas, China50).

Data flows: Read-only. Consumers include ClosePositionsByInstrumentID (checks ContractHasExpiration), APIs, and reporting.

---

## 2. Business Logic

### 2.1 ContractHasExpiration Gates Bulk Close

**What**: ClosePositionsByInstrumentID only allows closing all positions for instruments where ContractHasExpiration = 1.

**Columns/Parameters Involved**: `ContractHasExpiration`, `ContractExpire`

**Rules**:
- ContractHasExpiration = 1 (from ContractExpire): instrument has expiry (futures, options) - bulk close allowed
- ContractHasExpiration = 0: no expiry (stocks, forex, crypto) - bulk close blocked
- OIL(20), Copper(21), NATGAS(22), China50(26) are the intended targets per procedure comments

---

## 3. Data Overview

| InstrumentID | InstrumentDisplayName | IsTradable | IsVisible | Industry | ISINCode | ContractHasExpiration | Symbol | SymbolFull | SubCategory |
|--------------|------------------------|------------|-----------|----------|----------|----------------------|--------|------------|-------------|
| 1 | EUR/USD | 1 | 1 | 1 | ccc345 | 0 | EURUSD | EURUSD | NULL |
| 2 | GBP/USD | 1 | 1 | 0 | NULL | 0 | GBPUSD | GBPUSD | Qwerty_xxxx |
| 3 | NZD/USD | 1 | 1 | 0 | NULL | 0 | NZDUSD | NZDUSD12 | NULL |
| 4 | USD/CAD | 1 | 1 | 0 | NULL | 0 | USDCAD1 | USDCAD | STABLE SUBCATEGORY #2 |
| 5 | USD/JPY | 1 | 1 | 0 | NULL | 0 | USDJPY | USDJPY | Test SubCategory 1 |

**Selection criteria:** First 5 instruments. Forex pairs, IsTradable=1, IsVisible=1. Industry 0 or 1; ContractHasExpiration=0 (no expiry). SubCategory shows variety (NULL, labels).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | From Trade.InstrumentMetaData. Primary key. |
| 2 | InstrumentDisplayName | varchar(100) | NO | - | CODE-BACKED | From Trade.InstrumentMetaData. Human-readable name (e.g., "EUR/USD", "Apple"). |
| 3 | IsTradable | bit | YES | - | CODE-BACKED | Alias: Tradable. 1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument. |
| 4 | IsVisible | int | YES | (1) | CODE-BACKED | Alias: InstrumentVisible. 1 = shown in UI, 0 = hidden. Default 1. |
| 5 | Industry | int | NO | - | CODE-BACKED | Computed: ISNULL(StocksIndustryID, 0). Industry ID for stocks; 0 for forex/crypto. Dictionary.StocksIndustry. |
| 6 | ISINCode | varchar(30) | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. International Securities Identification Number. Required for stocks; NULL for forex/crypto. |
| 7 | ISINCountryCode | varchar(15) | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. Country prefix of ISIN (e.g., "US"). |
| 8 | ContractHasExpiration | bit | NO | (0) | CODE-BACKED | Alias: ContractExpire. 1 = instrument has expiry (futures, options), 0 = no expiry. ClosePositionsByInstrumentID requires 1 for bulk close. |
| 9 | Symbol | varchar(100) | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. Short ticker (e.g., "EURUSD", "AAPL"). |
| 10 | SymbolFull | varchar(100) | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. Full/canonical symbol, UNIQUE. Primary identifier in Security Ops API. |
| 11 | SubCategory | varchar(255) | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. Human-readable subcategory label. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.InstrumentMetaData | FK/Lookup | Base table. |
| Industry (StocksIndustryID) | Dictionary.StocksIndustry | Lookup | Industry classification. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ClosePositionsByInstrumentID | FROM | SELECT | Validates ContractHasExpiration=1 before allowing bulk close by instrument. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentMetaData (view)
└── Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FROM - direct select with column aliases and ISNULL |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ClosePositionsByInstrumentID | Procedure | SELECT - ContractHasExpiration check |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List tradable visible instruments

```sql
SELECT InstrumentID, InstrumentDisplayName, Symbol, SymbolFull, IsTradable, IsVisible, ContractHasExpiration
FROM Trade.GetInstrumentMetaData WITH (NOLOCK)
WHERE IsTradable = 1 AND IsVisible = 1
ORDER BY InstrumentID;
```

### 8.2 Instruments with contract expiration (bulk-close eligible)

```sql
SELECT InstrumentID, InstrumentDisplayName, SymbolFull, ContractHasExpiration
FROM Trade.GetInstrumentMetaData WITH (NOLOCK)
WHERE ContractHasExpiration = 1;
```

### 8.3 Lookup by SymbolFull

```sql
SELECT gim.InstrumentID, gim.InstrumentDisplayName, gim.Symbol, gim.Industry, gim.ISINCode
FROM Trade.GetInstrumentMetaData gim WITH (NOLOCK)
WHERE gim.SymbolFull = 'AAPL';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentMetaData | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrumentMetaData.sql*
