# Billing.GetExchangeRatesByInstruments

> Returns exchange rate data (payment and market bid/ask prices, fee multiplier) for a caller-specified set of instrument IDs - a bulk instrument price lookup for the deposit service using comma-separated input.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns price rows for InstrumentIDs in @Instruments (comma-separated list), ProviderID=1 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetExchangeRatesByInstruments` is a targeted exchange rate lookup for specific instruments. Rather than returning the full exchange rate table (like `GetExchangeRatesBaseTable`), it accepts a comma-separated list of InstrumentIDs and returns live pricing data for only those instruments.

Created by Shay Oren, September 2020 (PAYIL-1270), as part of the payment service exchange rate infrastructure. ProviderID=1 is hardcoded - prices are sourced from provider 1 (the primary/default market data provider).

---

## 2. Business Logic

### 2.1 Instrument-Filtered Price Lookup

**What**: Returns payment bid/ask and market bid/ask prices for specified instruments from ProviderID=1.

**Rules**:
- `WHERE TPVI.ProviderID = 1` - hardcoded to primary provider
- `AND TPVI.InstrumentID IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@Instruments, ','))` - parses comma-separated InstrumentID list
- INNER JOIN between Trade.ProviderToInstrument and Trade.CurrencyPrice on both ProviderID and InstrumentID - ensures price exists for each instrument
- Returns PaymentBid/PaymentAsk (payment-specific prices from ProviderToInstrument) alongside standard market Bid/Ask (from CurrencyPrice)

**Diagram**:
```
@Instruments = '100,101,102'
  |
  STRING_SPLIT -> InstrumentIDs [100, 101, 102]
  |
  -> Trade.ProviderToInstrument WHERE ProviderID=1 AND InstrumentID IN (...)
     INNER JOIN Trade.CurrencyPrice ON ProviderID=1 AND InstrumentID
  |
  v
  Price rows per instrument: ProviderID, InstrumentID, Precision, PresentationCode, PaymentBid, PaymentAsk, Bid, Ask
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Instruments | VARCHAR(200) | NO | - | CODE-BACKED | Comma-separated list of InstrumentIDs to look up (e.g., '100,101,102'). Parsed via STRING_SPLIT. Max 200 chars limits the number of instruments per call. |
| 2 | ProviderID (output) | INT | NO | - | CODE-BACKED | Always 1 (primary market data provider). Hardcoded in WHERE clause. |
| 3 | InstrumentID (output) | INT | NO | - | CODE-BACKED | Trade instrument identifier. One row per instrument from @Instruments that has a matching price. |
| 4 | Precision (output) | DECIMAL | YES | - | CODE-BACKED | ExchangeFeeMultiplier from Trade.ProviderToInstrument. Fee precision/multiplier for this instrument. |
| 5 | PresentationCode (output) | VARCHAR | YES | - | CODE-BACKED | Display code for the instrument from Trade.ProviderToInstrument (e.g., 'EURUSD'). Used by payment UI. |
| 6 | PaymentBid (output) | dbo.dtPrice | YES | - | CODE-BACKED | Payment-specific bid price from Trade.ProviderToInstrument. May differ from market Bid due to payment spread. |
| 7 | PaymentAsk (output) | dbo.dtPrice | YES | - | CODE-BACKED | Payment-specific ask price from Trade.ProviderToInstrument. May differ from market Ask due to payment spread. |
| 8 | Bid (output) | dbo.dtPrice | YES | - | CODE-BACKED | Market bid price from Trade.CurrencyPrice (live feed). |
| 9 | Ask (output) | dbo.dtPrice | YES | - | CODE-BACKED | Market ask price from Trade.CurrencyPrice (live feed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID (from @Instruments) | Trade.ProviderToInstrument | Lookup + JOIN | Gets payment prices and fee multiplier for ProviderID=1 |
| TPVI.InstrumentID | Trade.CurrencyPrice | INNER JOIN | Gets live market bid/ask for ProviderID=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit/exchange rate service | Direct execution | Operational | No GRANT EXECUTE found in SSDT |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetExchangeRatesByInstruments (procedure)
├── Trade.ProviderToInstrument (table) [cross-schema]
└── Trade.CurrencyPrice (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | READ NOLOCK - filtered by ProviderID=1 + InstrumentID list |
| Trade.CurrencyPrice | Table | READ NOLOCK - INNER JOIN for live bid/ask |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ProviderID = 1 hardcoded | Design | All prices from provider 1 (primary market data provider); no multi-provider support |
| VARCHAR(200) limit | Design | Comma-separated instrument list limited to 200 chars; approximately 10-20 instruments maximum before truncation risk |
| STRING_SPLIT | Compatibility | Requires SQL Server 2016+ (compatibility level 130+); no fallback for older versions |
| INNER JOIN excludes missing prices | Design | Instruments with no price in Trade.CurrencyPrice are silently excluded from results |

---

## 8. Sample Queries

### 8.1 Get exchange rates for specific instruments

```sql
EXEC Billing.GetExchangeRatesByInstruments @Instruments = '100,101,102,110';
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Exchange rate migration - Deposit Service (Confluence) | Confluence | Context for the deposit service exchange rate architecture this SP is part of |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 9/10, Logic: 7/10, Relationships: 4/10, Sources: 3/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence (search result) + 0 Jira | Procedures: 0 SQL callers | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetExchangeRatesByInstruments | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetExchangeRatesByInstruments.sql*
