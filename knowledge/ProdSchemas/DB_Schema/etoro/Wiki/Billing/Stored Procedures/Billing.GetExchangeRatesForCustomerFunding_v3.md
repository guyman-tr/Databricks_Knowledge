# Billing.GetExchangeRatesForCustomerFunding_v3

> Returns the exchange rate and conversion fees for a specific currency + funding type + player level combination, with direct SQL implementation (no delegation) and additional CurrencyID filtering not present in v1/v2.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingTypeID + @PlayerLevelID + @CurrencyID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This v3 procedure is a currency-specific variant of the exchange rate lookup. Unlike v2 (which returns all currencies for the given FundingType and filters by FundingTypeID), v3 accepts an explicit @CurrencyID and returns only the rate for that specific currency. This is useful when the calling service already knows which currency the customer will be transacting in and wants a single-row result.

The procedure directly implements the override resolution logic by joining ConversionFeeOverride with ConversionFee, then joining Trade.Instrument and Trade.CurrencyPrice for live rates. If no player-level or country-specific override exists, it falls back to ConversionFee defaults. The inline SQL mirrors the logic that ExchangeRatesByPlayerLevelGet does more comprehensively in its COALESCE chain.

Note: The CountryID filter is commented out in the WHERE clause (as of the current version), indicating country-specific resolution is intentionally not applied in v3 - it was planned but deactivated.

---

## 2. Business Logic

### 2.1 Override Resolution with Currency Filter

**What**: Applies the two-tier override system (player-level override -> base fee) filtered to one specific currency.

**Columns/Parameters Involved**: `@CurrencyID`, `@PlayerLevelID`, `@FundingTypeID`

**Rules**:
- Step 1: Try to find a ConversionFeeOverride row for (FundingTypeID, CurrencyID, PlayerLevelID)
- Step 2: If @@rowcount = 0 (no override found), fall back to ConversionFee base rates for that CurrencyID
- The #Conversion temp table holds the resolved fee row(s) for further JOIN to Trade data
- `IIF(TI.BuyCurrencyID = 1, 1, 0)` - Reciprocal flag: 1 when USD is the base currency of the instrument

**Diagram**:
```
ConversionFeeOverride (for FundingTypeID + CurrencyID + PlayerLevelID)
  -> Found: use override fees
  -> Not found (@@rowcount = 0): fall back to ConversionFee (for CurrencyID)
  -> JOIN Trade.Instrument (InstrumentID from ConversionFee)
  -> JOIN Trade.ProviderToInstrument (ProviderID=1)
  -> JOIN Trade.CurrencyPrice (ProviderID=1)
  -> Return: fees + Bid/Ask/Precision for the specific currency
```

### 2.2 Country Filter - Commented Out

**What**: Country-specific override was planned but deactivated.

**Columns/Parameters Involved**: `@CountryID`

**Rules**:
- `--AND cfo.CountryID = @CountryID` is commented out in both the WHERE clause
- The parameter is accepted but has no effect on the ConversionFeeOverride join filter
- Country filtering is present in v4 and ExchangeRatesByPlayerLevelGet but not active in v3
- @CountryID = NULL is the default; even non-null values are ignored in the current implementation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlayerLevelID | INT | NO | - | CODE-BACKED | Customer VIP/tier level. Matched against ConversionFeeOverride.PlayerLevelID. Determines which fee override row to use for this player tier. |
| 2 | @CountryID | INT | YES | NULL | CODE-BACKED | Intended for country-specific fee overrides. Currently NOT applied in the WHERE clause (commented out). Parameter is accepted for API compatibility but has no effect in v3. |
| 3 | @CurrencyID | INT | NO | - | CODE-BACKED | Currency identifier. Filters both ConversionFeeOverride and ConversionFee to return rates for this specific currency only. Lookup: Dictionary.Currency. |
| 4 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method identifier. Filters ConversionFeeOverride to the applicable funding type. Lookup: Dictionary.FundingType. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingTypeID | INT | NO | - | CODE-BACKED | Returns @FundingTypeID (the input value). Always matches the requested funding type. |
| R2 | CurrencyID | INT | NO | - | CODE-BACKED | Currency for the returned rate. Matches @CurrencyID. Lookup: Dictionary.Currency. |
| R3 | DepositFee | INT | NO | - | CODE-BACKED | Flat deposit conversion fee from the resolved override or base rate. |
| R4 | CashoutFee | INT | NO | - | CODE-BACKED | Flat cashout/withdrawal conversion fee. |
| R5 | DepositFeePercentage | DECIMAL(18,2) | YES | NULL | CODE-BACKED | Percentage-based deposit fee. NULL if not defined for this combination. |
| R6 | CashoutFeePercentage | DECIMAL(18,2) | YES | NULL | CODE-BACKED | Percentage-based cashout fee. NULL if not defined. |
| R7 | Reciprocal | INT | NO | - | CODE-BACKED | Rate direction: 1 = USD is base (direct quote), 0 = indirect/reciprocal. IIF(TI.BuyCurrencyID = 1, 1, 0). Application uses this to determine how to convert amounts using Bid/Ask. |
| R8 | Bid | dtPrice | NO | - | CODE-BACKED | Current bid price for the currency instrument (Trade.CurrencyPrice, ProviderID=1). |
| R9 | Ask | dtPrice | NO | - | CODE-BACKED | Current ask price (Trade.CurrencyPrice, ProviderID=1). |
| R10 | Precision | INT | NO | - | CODE-BACKED | ExchangeFeeMultiplier (aliased as Precision) from Trade.ProviderToInstrument. Precision/multiplier for fee calculations on this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeID + @CurrencyID + @PlayerLevelID | Billing.ConversionFeeOverride | JOIN | Tries player-level override first |
| @CurrencyID | Billing.ConversionFee | JOIN (fallback) | Default base rates when no override exists |
| InstrumentID | Trade.Instrument | JOIN | Links currency to its trading instrument for Bid/Ask |
| InstrumentID | Trade.ProviderToInstrument | JOIN | Provider=1 pricing configuration + ExchangeFeeMultiplier |
| InstrumentID | Trade.CurrencyPrice | JOIN | Live Bid/Ask prices from provider 1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application payment services | @CurrencyID | EXEC | Direct callers needing single-currency rate with player level |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetExchangeRatesForCustomerFunding_v3 (procedure)
├── Billing.ConversionFeeOverride (table)
├── Billing.ConversionFee (table)
├── Trade.Instrument (table)
├── Trade.ProviderToInstrument (table)
└── Trade.CurrencyPrice (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ConversionFeeOverride | Table | Primary fee override lookup for player level + currency + funding type |
| Billing.ConversionFee | Table | Fallback base fee rates when no override exists |
| Trade.Instrument | Table | JOIN on InstrumentID to get BuyCurrencyID for Reciprocal flag |
| Trade.ProviderToInstrument | Table | JOIN on ProviderID=1 + InstrumentID to get ExchangeFeeMultiplier (Precision) |
| Trade.CurrencyPrice | Table | JOIN on ProviderID=1 + InstrumentID for live Bid/Ask rates |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from application layer only. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get exchange rate for EUR credit card deposit for a standard player

```sql
EXEC Billing.GetExchangeRatesForCustomerFunding_v3
    @PlayerLevelID = 0,
    @CountryID = NULL,
    @CurrencyID = 2,      -- EUR (Dictionary.Currency)
    @FundingTypeID = 1;   -- Credit card
```

### 8.2 Get rate for a VIP player doing GBP wire transfer

```sql
EXEC Billing.GetExchangeRatesForCustomerFunding_v3
    @PlayerLevelID = 5,
    @CountryID = NULL,
    @CurrencyID = 3,      -- GBP
    @FundingTypeID = 2;   -- Wire transfer
```

### 8.3 Check ConversionFeeOverride entries for a player level + currency

```sql
SELECT *
FROM Billing.ConversionFeeOverride WITH (NOLOCK)
WHERE PlayerLevelID = 0
  AND CurrencyID = 2
  AND FundingTypeID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.4/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetExchangeRatesForCustomerFunding_v3 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetExchangeRatesForCustomerFunding_v3.sql*
