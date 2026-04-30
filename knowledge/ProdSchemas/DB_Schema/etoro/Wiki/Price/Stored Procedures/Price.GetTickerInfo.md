# Price.GetTickerInfo

> Returns all instrument ticker, exchange, and currency info for a given liquidity provider - resolves provider-specific exchange display names and normalizes GBX (UK pence) to GBP in the currency output.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LiquidityProviderID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetTickerInfo retrieves the complete ticker and exchange reference data for all instruments that a given liquidity provider covers. It is used by the pricing infrastructure to build or validate the feed symbol mapping: for each instrument a provider feeds, this procedure returns the exchange ticker symbol, the exchange identity (name, MIC, RIC), and the instrument's currency.

The five-table join resolves:
1. **Ticker** (`lpc.Ticker`): The liquidity provider's own symbol for this instrument (e.g., "AAPL", "EUR/USD")
2. **Exchange** (`Price.Exchange`): The exchange on which this instrument is listed (with MIC and RIC codes)
3. **Provider-specific exchange name** (`Price.ExchangeNameToProvider`): Some providers use different display names for the same exchange. `ISNULL(petp.Name, pe.Name)` returns the provider's preferred name if mapped, or the generic exchange name as fallback.
4. **Currency** (`Dictionary.Currency` via `Trade.Instrument.SellCurrencyID`): The instrument's denomination currency, with GBX normalized to GBP (see Section 2.2)

This procedure is typically called by pricing feed configuration tools when setting up or reviewing a liquidity provider's instrument coverage.

---

## 2. Business Logic

### 2.1 Provider-Specific Exchange Name Resolution

**What**: The exchange name returned is the provider's preferred name for that exchange, falling back to the standard name.

**Columns/Parameters Involved**: `petp.Name`, `pe.Name`, `PrimaryExch`

**Rules**:
- `Price.ExchangeNameToProvider` maps an (ExchangeID, ProviderID) pair to a provider-specific name
- LEFT JOIN with condition `petp.ExchangeID = pe.ExchangeID AND petp.ProviderID = lpc.LiquidityProviderID`
- `ISNULL(petp.Name, pe.Name) AS PrimaryExch`: if the provider has a custom name for this exchange, use it; otherwise use the exchange's standard name
- This handles cases where the same exchange (e.g., NYSE) has different display names across different data providers
- pe.Mic (Market Identifier Code) and pe.Ric are always from Price.Exchange - not provider-specific

### 2.2 GBX to GBP Currency Normalization

**What**: UK stocks priced in pence (GBX) are reported as GBP in the currency output.

**Columns/Parameters Involved**: `Currency`, `c.Abbreviation`

**Rules**:
- `CASE WHEN c.Abbreviation = 'GBX' THEN 'GBP' ELSE c.Abbreviation END AS Currency`
- GBX is "pence sterling" (1/100th of GBP) - eToro internally represents some UK stocks' sell currency as GBX
- This is normalized to GBP in the output because: (a) clients expect GBP as the denomination, and (b) the pricing feed typically provides prices in GBP regardless of the GBX internal representation
- All other currency abbreviations pass through unchanged

### 2.3 Provider Scoping

**What**: All results are scoped to a single liquidity provider.

**Columns/Parameters Involved**: `@LiquidityProviderID`, `lpc.LiquidityProviderID`

**Rules**:
- `WHERE lpc.LiquidityProviderID = @LiquidityProviderID`: filters Trade.LiquidityProviderContracts to one provider
- `lpc.LiquidityProviderID` is also returned in the result set (redundant with the filter, useful for batch processing)
- One row per instrument the provider covers (one row per LiquidityProviderContracts entry for this provider)
- An instrument can appear multiple times if the provider has multiple contract entries for it

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityProviderID | INT | NOT NULL | - | CODE-BACKED | The liquidity provider to retrieve ticker info for. FK to Trade.LiquidityProviders.LiquidityProviderID. Returns all instruments this provider covers with ticker and exchange details. Non-existent ID returns empty result. |

**Result set columns** (7 columns):

| # | Column | Description |
|---|--------|-------------|
| 1 | LiquidityProviderID | The liquidity provider identifier (echoes @LiquidityProviderID). FK to Trade.LiquidityProviders. |
| 2 | InstrumentID | eToro instrument identifier. FK to Trade.Instrument. |
| 3 | Ticker | The liquidity provider's own ticker symbol for this instrument (e.g., "AAPL", "EUR/USD", "BTC"). This is the feed symbol used to subscribe to this instrument from this provider. |
| 4 | PrimaryExch | Exchange display name. Provider-specific name if configured in ExchangeNameToProvider, else the standard exchange name from Price.Exchange. |
| 5 | Mic | Market Identifier Code - ISO 10383 standard exchange identifier (e.g., "XNAS" for NASDAQ, "XLON" for London Stock Exchange). From Price.Exchange. |
| 6 | Ric | Reuters Instrument Code for the exchange (e.g., ".O" for NYSE). From Price.Exchange. Used in Refinitiv/Reuters feed integration. |
| 7 | Currency | The instrument's denomination currency abbreviation. GBX is normalized to GBP (UK pence treated as pounds for display). From Dictionary.Currency via Trade.Instrument.SellCurrencyID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderID | Trade.LiquidityProviderContracts | READER (filter) | Primary source - all instrument/ticker mappings for the provider |
| ExchangeID | Price.Exchange | READER (JOIN) | Exchange name, MIC, and RIC codes |
| ExchangeID + ProviderID | Price.ExchangeNameToProvider | READER (LEFT JOIN) | Provider-specific exchange name override |
| InstrumentID | Trade.Instrument | READER (JOIN) | Instrument data - specifically SellCurrencyID for currency lookup |
| SellCurrencyID | Dictionary.Currency | READER (JOIN) | Currency abbreviation for GBX->GBP normalization |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (pricing feed configuration tool) | @LiquidityProviderID | CALLER | Called to review/validate a provider's ticker and exchange coverage |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetTickerInfo (procedure)
+-- Trade.LiquidityProviderContracts (table) - primary: provider ticker mappings
+-- Price.Exchange (table) - exchange MIC, RIC, name
+-- Price.ExchangeNameToProvider (table) - provider-specific exchange names (LEFT JOIN)
+-- Trade.Instrument (table) - SellCurrencyID
+-- Dictionary.Currency (table) - currency abbreviation with GBX->GBP normalization
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderContracts | Table | FROM source - ticker and InstrumentID per provider |
| Price.Exchange | Table | JOIN on ExchangeID - exchange name, MIC, RIC |
| Price.ExchangeNameToProvider | Table | LEFT JOIN - provider-specific exchange display name |
| Trade.Instrument | Table | JOIN on InstrumentID - SellCurrencyID for currency lookup |
| Dictionary.Currency | Table | JOIN on SellCurrencyID - currency abbreviation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (pricing feed configuration tool) | External | Calls to enumerate a provider's ticker/exchange/currency coverage |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No SET NOCOUNT ON. No NOLOCK hints. No error handling. No transaction. The GBX -> GBP normalization in the CASE expression is a hardcoded business rule: GBX is the only currency requiring normalization (UK stocks priced in pence). The LEFT JOIN to ExchangeNameToProvider uses a compound condition (ExchangeID AND ProviderID) - if either mapping is absent, the standard exchange name is used. All three non-LEFT JOINs are INNER - instruments or exchanges not in the joined tables are excluded silently.

---

## 8. Sample Queries

### 8.1 Get ticker info for a specific provider

```sql
EXEC Price.GetTickerInfo @LiquidityProviderID = 1;
```

### 8.2 Equivalent manual query

```sql
SELECT
    lpc.LiquidityProviderID,
    lpc.InstrumentID,
    lpc.Ticker,
    ISNULL(petp.Name, pe.Name) AS PrimaryExch,
    pe.Mic,
    pe.Ric,
    CASE WHEN c.Abbreviation = 'GBX' THEN 'GBP' ELSE c.Abbreviation END AS Currency
FROM Trade.LiquidityProviderContracts lpc WITH (NOLOCK)
JOIN Price.Exchange pe WITH (NOLOCK)
    ON lpc.ExchangeID = pe.ExchangeID
LEFT JOIN Price.ExchangeNameToProvider petp WITH (NOLOCK)
    ON petp.ExchangeID = pe.ExchangeID
    AND petp.ProviderID = lpc.LiquidityProviderID
JOIN Trade.Instrument ti WITH (NOLOCK)
    ON ti.InstrumentID = lpc.InstrumentID
JOIN Dictionary.Currency c WITH (NOLOCK)
    ON ti.SellCurrencyID = c.CurrencyID
WHERE lpc.LiquidityProviderID = 1
ORDER BY lpc.InstrumentID;
```

### 8.3 Count instruments per provider (diagnostic)

```sql
SELECT lpc.LiquidityProviderID, COUNT(*) AS InstrumentCount
FROM Trade.LiquidityProviderContracts lpc WITH (NOLOCK)
GROUP BY lpc.LiquidityProviderID
ORDER BY InstrumentCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetTickerInfo | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetTickerInfo.sql*
