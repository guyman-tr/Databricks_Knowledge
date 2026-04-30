# Billing.GetExchangeRatesForCustomerFunding

> Legacy wrapper that resolves a customer CID to a player level and delegates to GetExchangeRatesForCustomerFunding_v2 to return currency exchange rates and conversion fees for a given funding method.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer), @FundingTypeID (payment method) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the original public entry point for retrieving exchange rate and conversion fee data needed when a customer wants to deposit or withdraw using a specific payment method. Given a customer ID (CID), a funding type, and optionally a country, it returns the bid/ask prices, deposit/cashout fees, and reciprocal flag for the applicable currency instrument.

The procedure exists to provide a CID-based interface to the exchange rate system. Internally, eToro's fee engine works with PlayerLevelID (a VIP/tier segment), not directly with CIDs. This wrapper bridges the gap by looking up the customer's PlayerLevelID from Customer.CustomerStatic, then delegating the actual rate calculation to GetExchangeRatesForCustomerFunding_v2.

As of PAYSOLB-1018 (July 2022), the legacy inline logic was commented out and replaced with a delegation to v2. The procedure is kept for backward compatibility with callers that pass CID rather than PlayerLevelID. New integrations should prefer v2 or later versions directly.

---

## 2. Business Logic

### 2.1 CID-to-PlayerLevel Resolution

**What**: Translates a customer identifier into a player level tier before rate lookup.

**Columns/Parameters Involved**: `@CID`, `@PlayerLevelID` (internal variable)

**Rules**:
- CustomerStatic is queried for the CID to obtain PlayerLevelID
- PlayerLevelID controls fee tier - VIP customers may have lower deposit/cashout fees
- If no matching CID exists, @PlayerLevelID will be NULL (which v2 handles gracefully)
- Once resolved, all rate logic is delegated entirely to GetExchangeRatesForCustomerFunding_v2

**Diagram**:
```
Caller (passes @CID) -> GetExchangeRatesForCustomerFunding
  -> SELECT PlayerLevelID FROM Customer.CustomerStatic WHERE CID = @CID
  -> EXEC GetExchangeRatesForCustomerFunding_v2 (@FundingTypeID, @PlayerLevelID, @CountryID)
  -> Returns: FundingTypeID, CurrencyID, DepositFee, CashoutFee, Bid, Ask, Reciprocal, Precision
```

### 2.2 Version Delegation Pattern

**What**: This is a delegation-only wrapper introduced when the core logic was moved to v2.

**Columns/Parameters Involved**: `@FundingTypeID`, `@CountryID`

**Rules**:
- The original inline logic (querying ConversionFee, ConversionFeeOverride, Trade.Instrument, etc.) is fully commented out in the current code
- Only the delegation call remains active
- All fee override logic (player level, country, currency specificity) runs inside v2/ExchangeRatesByPlayerLevelGet

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Used to look up the customer's PlayerLevelID from Customer.CustomerStatic. Determines which fee tier applies for the deposit/cashout fee calculation. |
| 2 | @FundingTypeID | INT | NO | - | CODE-BACKED | Identifies the payment method (credit card, wire, Trustly, etc.). Passed directly to v2. Filters the rate results to return only rates relevant to the chosen payment method. |
| 3 | @CountryID | INT | YES | NULL | CODE-BACKED | Optional country identifier. Passed to v2 for country-specific fee overrides. When NULL, only non-country-specific overrides apply. |

**Return columns** (proxied from GetExchangeRatesForCustomerFunding_v2):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingTypeID | INT | NO | - | CODE-BACKED | The funding type the rates apply to. Matches @FundingTypeID or 0 (default) if no specific override exists. |
| R2 | CurrencyID | INT | NO | - | CODE-BACKED | Currency for which rates and fees are returned. Lookup: Dictionary.Currency. |
| R3 | DepositFee | INT | NO | - | CODE-BACKED | Flat deposit fee in basis points or percentage units for the currency/funding type combination. From Billing.ConversionFee or overrides. |
| R4 | CashoutFee | INT | NO | - | CODE-BACKED | Flat withdrawal/cashout fee in basis points or percentage units. From Billing.ConversionFee or overrides. |
| R5 | DepositFeePercentage | DECIMAL(18,2) | YES | NULL | CODE-BACKED | Percentage-based deposit fee. Used alongside or instead of flat DepositFee. Added per PAYUA-1956. |
| R6 | CashoutFeePercentage | DECIMAL(18,2) | YES | NULL | CODE-BACKED | Percentage-based cashout fee. Added per PAYUA-1956. |
| R7 | Reciprocal | INT | NO | - | CODE-BACKED | 1 if the instrument's BuyCurrencyID = 1 (USD is the base currency, rate is direct); 0 if rate is reciprocal. Used by the application to determine quote direction. IIF(TI.BuyCurrencyID = 1, 1, 0). |
| R8 | Bid | dtPrice | NO | - | CODE-BACKED | Current bid price for the currency instrument (from Trade.CurrencyPrice, ProviderID=1). Used to convert deposit/cashout amounts. |
| R9 | Ask | dtPrice | NO | - | CODE-BACKED | Current ask price for the currency instrument (from Trade.CurrencyPrice, ProviderID=1). |
| R10 | Precision | INT | NO | - | CODE-BACKED | ExchangeFeeMultiplier from Trade.ProviderToInstrument. Aliased as Precision - controls precision/multiplier for fee calculations on this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Lookup | Resolves CID to PlayerLevelID for fee tier determination |
| (delegation) | Billing.GetExchangeRatesForCustomerFunding_v2 | EXEC | All rate logic delegated to v2 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer (payment services) | @CID | EXEC | Called by payment services that have a CID but not a PlayerLevelID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetExchangeRatesForCustomerFunding (procedure)
├── Customer.CustomerStatic (table)
└── Billing.GetExchangeRatesForCustomerFunding_v2 (procedure)
      └── Billing.ExchangeRatesByPlayerLevelGet (procedure)
            ├── Billing.ConversionFee (table)
            ├── Billing.ConversionFeeOverride (table)
            ├── Trade.Instrument (table)
            ├── Trade.ProviderToInstrument (table)
            └── Trade.CurrencyPrice (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | SELECT PlayerLevelID WHERE CID = @CID |
| Billing.GetExchangeRatesForCustomerFunding_v2 | Stored Procedure | EXEC - delegates all rate/fee logic |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application payment services | External | EXEC - called with CID to retrieve exchange rates before deposit/withdrawal |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get exchange rates for a credit card deposit

```sql
EXEC Billing.GetExchangeRatesForCustomerFunding
    @CID = 1234567,
    @FundingTypeID = 1,   -- Credit card
    @CountryID = NULL;
```

### 8.2 Get exchange rates with country-specific overrides

```sql
EXEC Billing.GetExchangeRatesForCustomerFunding
    @CID = 9876543,
    @FundingTypeID = 2,   -- Wire transfer
    @CountryID = 103;     -- Specific country for override resolution
```

### 8.3 Inspect the player level for a customer before calling this procedure

```sql
SELECT CID, PlayerLevelID
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE CID = 1234567;
-- Use this to understand which fee tier will apply
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetExchangeRatesForCustomerFunding | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetExchangeRatesForCustomerFunding.sql*
