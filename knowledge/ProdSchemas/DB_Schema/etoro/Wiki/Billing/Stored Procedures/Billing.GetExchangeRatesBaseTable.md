# Billing.GetExchangeRatesBaseTable

> Returns the base (non-customer-specific, FundingTypeID=0) exchange rate table with deposit/cashout fees and live bid/ask prices for all configured currency instruments - the foundation layer of the exchange rate system used by the deposit service.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from ConversionFee joined to live Trade prices (no parameters, no filters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetExchangeRatesBaseTable` returns the global base exchange rate configuration - the default fee and price table that applies to all customers before any player-level or funding-type-specific overrides. It joins `Billing.ConversionFee` (fee configuration per currency/instrument) with live market prices from `Trade.CurrencyPrice` via `Trade.ProviderToInstrument`.

The hardcoded `FundingTypeID = 0` in the output marks these as "base/generic" rates - not tied to a specific payment method. Customer-specific or funding-type-specific overrides are layered on top of these base rates by other SPs (like `Billing.ExchangeRatesByPlayerLevelGet`).

**Change history**:
- 03/09/2020 Shay Oren: Added ExchangeFeeMultiplier (Precision) to dataset
- 05/09/2022 Shay Oren: Added NOLOCK to prevent deadlocks - DBAD-20
- 11/08/2024 Itay H: Added DepositFeePercentage and CashoutFeePercentage - PAYIL-8754

---

## 2. Business Logic

### 2.1 Base Exchange Rate Assembly

**What**: Joins the currency fee table with the live instrument price feed to produce a complete exchange rate record per currency.

**Rules**:
- `FROM Billing.ConversionFee` - base fee configuration per CurrencyID/InstrumentID
- `INNER JOIN Trade.Instrument ON InstrumentID` - gets BuyCurrencyID for reciprocal calculation
- `INNER JOIN Trade.ProviderToInstrument ON InstrumentID` - gets ExchangeFeeMultiplier
- `INNER JOIN Trade.CurrencyPrice ON InstrumentID` - live bid/ask prices
- `Reciprocal = IIF(TI.BuyCurrencyID = 1, 1, 0)` - flag indicating if this rate is expressed as reciprocal (USD as buy currency = 1, meaning the instrument price gives USD per 1 foreign unit)
- `FundingTypeID = 0` hardcoded - identifies all returned rows as base/generic rates (no funding-type specificity)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID (output) | INT | NO | 0 | CODE-BACKED | Always 0. Marks these as base/generic exchange rates not tied to a specific payment method type. |
| 2 | CurrencyID (output) | INT | NO | - | CODE-BACKED | FK to Dictionary.Currency. The non-USD currency being priced. |
| 3 | DepositFee (output) | DECIMAL | YES | - | CODE-BACKED | Fixed deposit fee for this currency from Billing.ConversionFee. |
| 4 | CashoutFee (output) | DECIMAL | YES | - | CODE-BACKED | Fixed cashout/withdrawal fee for this currency from Billing.ConversionFee. |
| 5 | DepositFeePercentage (output) | DECIMAL | YES | - | CODE-BACKED | Deposit fee as percentage. Added PAYIL-8754 (Aug 2024). |
| 6 | CashoutFeePercentage (output) | DECIMAL | YES | - | CODE-BACKED | Cashout fee as percentage. Added PAYIL-8754 (Aug 2024). |
| 7 | Reciprocal (output) | BIT | NO | - | CODE-BACKED | 1 if BuyCurrencyID=1 (USD), meaning price = foreign/USD. 0 = price = USD/foreign. Used by callers to correctly interpret Bid/Ask direction. |
| 8 | Bid (output) | dbo.dtPrice | YES | - | CODE-BACKED | Live bid price from Trade.CurrencyPrice. |
| 9 | Ask (output) | dbo.dtPrice | YES | - | CODE-BACKED | Live ask price from Trade.CurrencyPrice. |
| 10 | Precision (output) | DECIMAL | YES | - | CODE-BACKED | ExchangeFeeMultiplier from Trade.ProviderToInstrument. Represents the precision/multiplier applied to exchange fees for this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Billing.ConversionFee | Source | Base fee configuration |
| CF.InstrumentID | Trade.Instrument | INNER JOIN | Gets BuyCurrencyID for reciprocal logic |
| TI.InstrumentID | Trade.ProviderToInstrument | INNER JOIN | Gets ExchangeFeeMultiplier |
| TPTI.InstrumentID | Trade.CurrencyPrice | INNER JOIN | Gets live Bid/Ask prices |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit service / exchange rate services | Direct execution | Operational | No GRANT EXECUTE found in SSDT |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetExchangeRatesBaseTable (procedure)
├── Billing.ConversionFee (table)
├── Trade.Instrument (table) [cross-schema]
├── Trade.ProviderToInstrument (table) [cross-schema]
└── Trade.CurrencyPrice (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ConversionFee | Table | READ NOLOCK - fee rates per currency/instrument |
| Trade.Instrument | Table | INNER JOIN (no NOLOCK in original - DBAD-20 fix added NOLOCK to prevent deadlocks) - gets BuyCurrencyID |
| Trade.ProviderToInstrument | Table | READ NOLOCK - gets ExchangeFeeMultiplier |
| Trade.CurrencyPrice | Table | READ NOLOCK - live bid/ask prices |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FundingTypeID = 0 hardcoded | Design | Output is always labeled as base/generic rates; callers overlay funding-type-specific rates |
| NOLOCK added DBAD-20 | History | NOLOCK added Sep 2022 to prevent deadlocks between Billing and Trade schemas during price updates |
| No parameters | Design | Returns the full base rate table every call; no filtering; caller processes in memory |
| INNER JOINs | Design | Currency/instrument must exist in all three Trade tables; currencies without a matched instrument are excluded |

---

## 8. Sample Queries

```sql
EXEC Billing.GetExchangeRatesBaseTable;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Exchange rate migration - Deposit Service (Confluence) | Confluence | Context for how exchange rates were migrated to the deposit service - likely describes this SP's role in the rate system |
| Billing Service Database Readonly Separation (Confluence) | Confluence | Context for the read-separated architecture that this SP is part of |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.2/10 (Elements: 9/10, Logic: 7/10, Relationships: 4/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 2 Confluence (search results) + 0 Jira | Procedures: 0 SQL callers | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetExchangeRatesBaseTable | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetExchangeRatesBaseTable.sql*
