# Trade.GetInstrumentDataDealing

> Dealing-desk view of instruments with display names, asset type, exchange, tradability, and provider visibility - used for Sevision and operations tooling.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID (one row per instrument per provider) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentDataDealing exposes instrument data needed by the dealing desk and operations teams: display names, ticker symbols, asset type (from Dictionary.CurrencyType via the buy currency), exchange name, tradability flag, and whether the instrument is visible only internally. It joins InstrumentMetaData, Instrument (for buy currency), Dictionary.Currency, Dictionary.CurrencyType, and ProviderToInstrument to produce a single row per instrument-provider combination that includes the human-readable instrument type name.

This view exists because dealing operations need a flattened view of instruments with type labels (e.g., "Stocks", "Forex") instead of IDs, plus visibility and tradability for filtering. Without it, ops tooling would need multiple JOINs and lookups. Trade.GetInstrumentsForSevision reads it to list instruments for Sevision (InstrumentID < 1000000, VisibleInternallyOnly = 0).

Data flows: The view is read-only. Trade.GetInstrumentsForSevision is the primary consumer, returning InstrumentID, InstrumentDisplayName, Symbol, InstrumentType, Exchange, Tradable for external/customer-facing instruments.

---

## 2. Business Logic

### 2.1 Instrument Type from Buy Currency

**What**: InstrumentType is derived from the buy-side currency's CurrencyTypeID, not from InstrumentMetaData.InstrumentTypeID.

**Columns/Parameters Involved**: `InstrumentType`, `inst.BuyCurrencyID`, `dc.CurrencyTypeID`, `ct.Name`

**Rules**:
- JOIN path: Instrument -> Currency (buy) -> CurrencyType
- ct.Name becomes the InstrumentType label (e.g., "Stocks", "Forex")
- Ensures consistency: instrument type comes from the underlying asset classification in Dictionary

### 2.2 Provider Visibility Filter

**What**: VisibleInternallyOnly from ProviderToInstrument controls whether the instrument appears in external tools.

**Columns/Parameters Involved**: `VisibleInternallyOnly`, `PTI.VisibleInternallyOnly`

**Rules**:
- 1 = internal/ops only; 0 = visible to clients
- Trade.GetInstrumentsForSevision filters WHERE VisibleInternallyOnly = 0 to exclude internal instruments

---

## 3. Data Overview

| InstrumentID | InstrumentDisplayName | Symbol | InstrumentType | Exchange | Tradable | VisibleInternallyOnly | Meaning |
|--------------|------------------------|--------|----------------|----------|----------|----------------------|---------|
| 10029 | Paramount Global | PARAA | Stocks | Nasdaq | 0 | 0 | US equity. Tradable=0 (trading disabled). Visible to clients. |
| 10030 | iQIYI Inc | IQ.US | Stocks | Nasdaq | 0 | 0 | US equity. Different symbol pattern (IQ.US). |
| 10031 | TFS Financial Corporation | TFSL | Stocks | Nasdaq | 0 | 0 | US financial stock. |
| 10032 | Olink Holding AB publ | OLK | Stocks | Nasdaq | 0 | 0 | Swedish company on Nasdaq. |
| 10033 | HUTCHMED China Limited | HCM | Stocks | Nasdaq | 0 | 0 | China-based stock on Nasdaq. |

**Selection criteria:** First 5 rows by InstrumentID from live query. All Stocks, Nasdaq, Tradable=0, VisibleInternallyOnly=0. Representative of dealing-desk instrument list for Sevision.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | From Trade.InstrumentMetaData. Primary key of the instrument. Same as Trade.Instrument.InstrumentID. |
| 2 | InstrumentDisplayName | varchar(100) | NO | - | CODE-BACKED | From Trade.InstrumentMetaData. Human-readable name (e.g., "Paramount Global", "EUR/USD"). Used in UI and dealing desk. |
| 3 | Symbol | varchar(100) | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. Short ticker (e.g., "PARAA", "EURUSD"). Used for display and lookup. |
| 4 | InstrumentType | varchar | - | - | CODE-BACKED | From Dictionary.CurrencyType.Name via inst.BuyCurrencyID -> dc.CurrencyTypeID -> ct.CurrencyTypeID. Asset class label: "Stocks", "Forex", "Commodity", "Crypto", etc. Derived from buy currency, not InstrumentMetaData.InstrumentTypeID. |
| 5 | Exchange | varchar(max) | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. Exchange name string (e.g., "Nasdaq"). Populated from Price.Exchange via ExchangeID. |
| 6 | Tradable | bit | YES | - | CODE-BACKED | From Trade.InstrumentMetaData. 1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument. |
| 7 | VisibleInternallyOnly | bit | NO | 0 | CODE-BACKED | From Trade.ProviderToInstrument. 1 = hidden from external clients (internal/ops only), 0 = visible to all. GetInstrumentsForSevision filters WHERE VisibleInternallyOnly = 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.InstrumentMetaData | FK/Lookup | Base instrument metadata. |
| InstrumentID | Trade.Instrument | Implicit | Buy/Sell currency pairing. |
| BuyCurrencyID (via Instrument) | Dictionary.Currency | Lookup | Resolves to CurrencyType for InstrumentType label. |
| InstrumentID | Trade.ProviderToInstrument | JOIN | Provider visibility and config. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrumentsForSevision | FROM | JOIN | Primary consumer. Returns instruments for Sevision (VisibleInternallyOnly=0, InstrumentID<1000000). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentDataDealing (view)
├── Trade.InstrumentMetaData (table)
├── Trade.Instrument (table)
│     ├── Dictionary.Currency (table)
│     └── Dictionary.Currency (table)
├── Dictionary.Currency (table)
├── Dictionary.CurrencyType (table)
└── Trade.ProviderToInstrument (table)
      ├── Trade.Provider (table)
      └── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FROM - display name, symbol, exchange, tradable |
| Trade.Instrument | Table | INNER JOIN - buy currency for type resolution |
| Dictionary.Currency | Table | INNER JOIN - BuyCurrencyID -> CurrencyTypeID |
| Dictionary.CurrencyType | Table | INNER JOIN - CurrencyTypeID -> Name (InstrumentType) |
| Trade.ProviderToInstrument | Table | INNER JOIN - VisibleInternallyOnly |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentsForSevision | Procedure | FROM - instrument list for Sevision |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List tradable instruments for dealing desk

```sql
SELECT InstrumentID, InstrumentDisplayName, Symbol, InstrumentType, Exchange, Tradable
FROM Trade.GetInstrumentDataDealing WITH (NOLOCK)
WHERE Tradable = 1
  AND VisibleInternallyOnly = 0
ORDER BY InstrumentType, Symbol;
```

### 8.2 Instruments by asset type

```sql
SELECT InstrumentType, COUNT(*) AS InstrumentCount
FROM Trade.GetInstrumentDataDealing WITH (NOLOCK)
WHERE VisibleInternallyOnly = 0
GROUP BY InstrumentType
ORDER BY InstrumentCount DESC;
```

### 8.3 Find instruments by display name pattern

```sql
SELECT gid.InstrumentID, gid.InstrumentDisplayName, gid.Symbol, gid.InstrumentType, gid.Exchange
FROM Trade.GetInstrumentDataDealing gid WITH (NOLOCK)
WHERE gid.InstrumentDisplayName LIKE '%Global%'
  AND gid.VisibleInternallyOnly = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentDataDealing | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrumentDataDealing.sql*
