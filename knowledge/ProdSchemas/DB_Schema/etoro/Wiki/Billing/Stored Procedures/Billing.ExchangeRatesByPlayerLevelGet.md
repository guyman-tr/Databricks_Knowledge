# Billing.ExchangeRatesByPlayerLevelGet

> Returns effective conversion fees (flat + percentage) with current live market prices (Bid/Ask) for each currency/funding-type/instrument combination, applying a 5-level override priority chain keyed to the customer's player level and country.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlayerLevelID + @CountryID - pure SELECT with live price join |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ExchangeRatesByPlayerLevelGet` (PAYIL-4807, 08/08/2022, Elrom B.) is the conversion fee and exchange rate query used by payment services to determine what fees apply when a customer deposits or withdraws in a non-USD currency. The result set contains one row per (FundingType, Currency, Instrument) combination with the effective DepositFee, CashoutFee, DepositFeePercentage, and CashoutFeePercentage resolved through a multi-tier override chain.

The override system allows eToro to configure fees at multiple granularities: global defaults, global funding-type overrides, player-level overrides, and country-specific player-level overrides. The COALESCE chain ensures the most specific override wins. The SP also joins to the Trade schema to retrieve live market bid/ask prices and exchange fee multipliers for the underlying currency instruments (always using ProviderID=1 for the primary liquidity provider).

Version history: initial version Aug 2022, performance revision Sep 2022 (Shay Oren), FeePercentage columns added PAYIL-8694 (Aug 2024).

---

## 2. Business Logic

### 2.1 Base Data Collection (RelevantData CTE)

**What**: Unions base ConversionFee records with applicable ConversionFeeOverride records.

**Rules**:
- Row set 1: All `Billing.ConversionFee` rows as base fees with FundingTypeID=0 (flag meaning "no specific FundingType override"), CountryID=NULL, override flags=0.
- Row set 2: `Billing.ConversionFeeOverride` WHERE `PlayerLevelID = @PlayerLevelID OR PlayerLevelID = 0` CROSS JOIN `Billing.ConversionFee` - produces all override rows that could apply to this player level (or the global level=0 overrides), paired with base fee data.

### 2.2 Override Priority Resolution (Fees CTE)

**What**: Applies a 5-level COALESCE chain to select the highest-priority applicable fee override.

**Priority levels (highest to lowest)**:
| Priority | Name | Conditions |
|----------|------|-----------|
| 1 (O5) | Player+funding, no country, @CountryID=NULL | PlayerLevel=@PlayerLevelID, CurrencyID=0 or specific, FundingType-specific, CountryID IS NULL override, called without country |
| 2 (O45) | Player+funding+specific country | PlayerLevel=@PlayerLevelID, CurrencyID=0 or specific, FundingType-specific, CountryID=@CountryID, @CountryID IS NOT NULL |
| 3 (O4) | Player+funding, null-country override, @CountryID given | PlayerLevel=@PlayerLevelID, CurrencyID=0 or specific, FundingType-specific, CountryID IS NULL (=all countries), @CountryID IS NOT NULL |
| 4 (O3) | Player+funding, ISNULL(country,-1)=@CountryID | PlayerLevel=@PlayerLevelID, CurrencyID=0 or specific, FundingType-specific, ISNULL(CountryID,-1)=@CountryID |
| 5 (O2) | Global (level=0), specific currency | PlayerLevel=0, CurrencyID=specific, FundingType-specific |
| 6 (O1) | Global (level=0), all currencies | PlayerLevel=0, CurrencyID=0 (all), FundingType-specific |
| 7 (r) | Base ConversionFee | No override applies |

All four fee columns (DepositFee, CashoutFee, DepositFeePercentage, CashoutFeePercentage) are resolved independently through the same COALESCE chain.

### 2.3 Live Price Join

**What**: Adds current market bid/ask prices and exchange precision for the currency instruments.

**Rules**:
- INNER JOIN `Trade.Instrument TI` ON InstrumentID - confirms instrument exists.
- INNER JOIN `Trade.ProviderToInstrument TPTI` WHERE ProviderID=1 - uses primary liquidity provider; `ExchangeFeeMultiplier` aliased as `[Precision]`.
- INNER JOIN `Trade.CurrencyPrice CP` WHERE ProviderID=1 - live Bid/Ask prices.
- `Reciprocal = IIF(TI.BuyCurrencyID=1, 1, 0)` - flag indicating whether to use the reciprocal rate for this currency pair. BuyCurrencyID=1 means USD is the base currency.

```
@PlayerLevelID, @CountryID
  -> RelevantData CTE: ConversionFee UNION (ConversionFeeOverride + ConversionFee)
  -> Fees CTE: 6 OUTER APPLYs resolve override priority
  -> Final SELECT: join Trade.Instrument + ProviderToInstrument + CurrencyPrice (ProviderID=1)
  -> Return: FundingTypeID, CurrencyID, InstrumentID, DepositFee, CashoutFee, DepositFeePercentage,
             CashoutFeePercentage, Reciprocal, Bid, Ask, [Precision]
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlayerLevelID | INT | NO | - | CODE-BACKED | Customer's player level. Used to select ConversionFeeOverride rows where PlayerLevelID=@PlayerLevelID OR PlayerLevelID=0. Determines which override tier applies. FK to Dictionary.PlayerLevel (inferred). |
| 2 | @CountryID | INT | YES | NULL | CODE-BACKED | Customer's country. When provided, enables country-specific override lookups (O3, O4, O45). When NULL, only player-level and global overrides apply (O5). |

**Output columns:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 3 | FundingTypeID | INT | NO | CODE-BACKED | Payment method category. From Billing.ConversionFeeOverride or ConversionFee. |
| 4 | CurrencyID | INT | NO | CODE-BACKED | Currency being converted. FK to Dictionary.Currency. |
| 5 | InstrumentID | INT | NO | CODE-BACKED | Trade instrument for this currency pair (e.g., USD/EUR). FK to Trade.Instrument. Used to get live prices. |
| 6 | DepositFee | (decimal) | YES | CODE-BACKED | Flat deposit fee after override resolution. May be NULL if only percentage fee applies. |
| 7 | CashoutFee | (decimal) | YES | CODE-BACKED | Flat cashout/withdrawal fee after override resolution. |
| 8 | DepositFeePercentage | (decimal) | YES | CODE-BACKED | Percentage-based deposit fee (e.g., 0.5 = 0.5%). Added PAYIL-8694. |
| 9 | CashoutFeePercentage | (decimal) | YES | CODE-BACKED | Percentage-based cashout fee. Added PAYIL-8694. |
| 10 | Reciprocal | BIT | NO | CODE-BACKED | 1 if Trade.Instrument.BuyCurrencyID=1 (USD is base, use reciprocal rate), 0 otherwise. Used by payment service to apply correct rate direction. |
| 11 | Bid | (price) | NO | CODE-BACKED | Current bid price from Trade.CurrencyPrice for ProviderID=1. Used to compute sell-side exchange rate. |
| 12 | Ask | (price) | NO | CODE-BACKED | Current ask price from Trade.CurrencyPrice for ProviderID=1. Used to compute buy-side exchange rate. |
| 13 | Precision | (decimal) | YES | CODE-BACKED | ExchangeFeeMultiplier from Trade.ProviderToInstrument (ProviderID=1). Applied to the exchange fee calculation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID + InstrumentID | Billing.ConversionFee | READ | Base fee records for all currencies. |
| @PlayerLevelID + FundingTypeID | Billing.ConversionFeeOverride | READ | Override records for player levels, countries, funding types. |
| InstrumentID | Trade.Instrument | INNER JOIN (cross-schema) | Confirms instrument; provides Reciprocal flag (BuyCurrencyID). |
| InstrumentID | Trade.ProviderToInstrument | INNER JOIN (cross-schema) | ExchangeFeeMultiplier ([Precision]) for ProviderID=1. |
| InstrumentID | Trade.CurrencyPrice | INNER JOIN (cross-schema) | Live Bid/Ask prices for ProviderID=1. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment services / frontend APIs | @PlayerLevelID, @CountryID | EXEC | Called to determine applicable fees and live rates when displaying deposit/withdrawal currency options. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ExchangeRatesByPlayerLevelGet (procedure)
+-- Billing.ConversionFee (table)
+-- Billing.ConversionFeeOverride (table)
+-- Trade.Instrument (table) [cross-schema]
+-- Trade.ProviderToInstrument (table) [cross-schema]
+-- Trade.CurrencyPrice (table) [cross-schema]
```

---

## 7. Technical Details

**OUTER APPLY pattern**: The 5 OUTER APPLYs in the Fees CTE each attempt to find a matching override at a specific priority level. If no match is found, the OUTER APPLY returns NULL, and the COALESCE falls through to the next level.

**CurrencyID=0 convention**: In ConversionFeeOverride, CurrencyID=0 means "applies to all currencies" - the `cfo.CurrencyID IN (0, r.CurrencyID)` filter catches both explicit and wildcard matches.

**PlayerLevelID=0 convention**: Level=0 means global/default - applies to all player levels.

**Performance note**: Revised for performance in Sep 2022 (Shay Oren) - the original PAYIL-4807 version had performance issues with the complex CROSS JOIN and OUTER APPLY structure.

---

## 8. Sample Queries

### 8.1 Get fees for a standard retail customer with country

```sql
EXEC [Billing].[ExchangeRatesByPlayerLevelGet]
    @PlayerLevelID = 3,   -- e.g., Standard
    @CountryID = 82;      -- United Kingdom
```

### 8.2 Get global base fees (no country)

```sql
EXEC [Billing].[ExchangeRatesByPlayerLevelGet]
    @PlayerLevelID = 0,
    @CountryID = NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ExchangeRatesByPlayerLevelGet | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ExchangeRatesByPlayerLevelGet.sql*
