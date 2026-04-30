# Billing.GetExchangeRatesForCustomerFunding_v2

> Returns currency exchange rates and conversion fees for a given funding method and player level, filtering results by FundingTypeID after calling the core rate-calculation procedure ExchangeRatesByPlayerLevelGet.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingTypeID + @PlayerLevelID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the player-level-aware version of the exchange rate lookup chain. Rather than accepting a customer CID, it accepts a PlayerLevelID directly - allowing calling code that already knows the tier to skip the CID resolution step. This makes it both more direct and more reusable (e.g., for back-office operations or bulk rate lookups).

The procedure exists at the v2 level because it introduced a clean delegation to ExchangeRatesByPlayerLevelGet (PAYIL-5889), replacing the earlier inline fee-calculation SQL. It also introduced the @CountryID parameter and the DepositFeePercentage/CashoutFeePercentage columns (PAYIL-8808) for percentage-based fee support.

Callers include GetExchangeRatesForCustomerFunding (the CID-based wrapper) and any direct integration that uses PlayerLevelID. The result is filtered to return only the row(s) matching @FundingTypeID, giving callers only the rates relevant to their chosen payment method.

---

## 2. Business Logic

### 2.1 Fee Tier Delegation and FundingType Filtering

**What**: Delegates to ExchangeRatesByPlayerLevelGet for all fee/rate computation, then filters to the requested FundingTypeID.

**Columns/Parameters Involved**: `@FundingTypeID`, `@PlayerLevelID`, `@CountryID`

**Rules**:
- ExchangeRatesByPlayerLevelGet returns rates for ALL FundingTypeIDs applicable to the player level
- This procedure filters to return only the rows matching @FundingTypeID
- If no match for @FundingTypeID, the result set will be empty (callers should handle this)
- The @Result table variable captures the full multi-row output from ExchangeRatesByPlayerLevelGet before filtering

**Diagram**:
```
EXEC ExchangeRatesByPlayerLevelGet(@PlayerLevelID, @CountryID)
  -> @Result TABLE (all rates for player level)
  -> SELECT WHERE FundingTypeID = @FundingTypeID
  -> Returns filtered exchange rates + fees
```

### 2.2 Percentage Fee Support

**What**: Extended fee model supporting percentage-based fees alongside flat fees.

**Columns/Parameters Involved**: `DepositFeePercentage`, `CashoutFeePercentage`

**Rules**:
- Added per PAYIL-8808 (August 2024, Itay H)
- Both flat (DepositFee/CashoutFee as INT) and percentage-based (DECIMAL 18,2) fees are returned
- Application layer decides which fee model to apply
- NULL values in percentage columns mean percentage fees do not apply for this combination

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method identifier. Used to filter the result set from ExchangeRatesByPlayerLevelGet. Only rates applicable to this funding type are returned. Lookup: Dictionary.FundingType. |
| 2 | @PlayerLevelID | INT | NO | - | CODE-BACKED | Customer VIP/tier level. Determines which fee overrides apply. Passed to ExchangeRatesByPlayerLevelGet which resolves the applicable ConversionFee/ConversionFeeOverride rows. PlayerLevelID=0 is the default/no-VIP tier. |
| 3 | @CountryID | INT | YES | NULL | CODE-BACKED | Optional country for country-specific fee overrides. Passed to ExchangeRatesByPlayerLevelGet. When NULL, country-specific overrides are not applied. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method identifier matching @FundingTypeID filter. |
| R2 | CurrencyID | INT | NO | - | CODE-BACKED | Currency for which fees/rates are returned. Lookup: Dictionary.Currency. |
| R3 | DepositFee | INT | NO | - | CODE-BACKED | Flat deposit conversion fee for this currency/funding type. Unit depends on instrument (basis points or percentage points). |
| R4 | CashoutFee | INT | NO | - | CODE-BACKED | Flat withdrawal/cashout conversion fee. Same unit as DepositFee. |
| R5 | DepositFeePercentage | DECIMAL(18,2) | YES | NULL | CODE-BACKED | Percentage-based deposit fee. NULL if not applicable. Added PAYIL-8808. |
| R6 | CashoutFeePercentage | DECIMAL(18,2) | YES | NULL | CODE-BACKED | Percentage-based cashout fee. NULL if not applicable. Added PAYIL-8808. |
| R7 | Reciprocal | INT | NO | - | CODE-BACKED | Rate direction flag: 1 = direct rate (USD is base, BuyCurrencyID=1); 0 = reciprocal rate. Determines how the application applies Bid/Ask to convert amounts. |
| R8 | Bid | dtPrice | NO | - | CODE-BACKED | Current bid price for the currency instrument from Trade.CurrencyPrice (ProviderID=1). |
| R9 | Ask | dtPrice | NO | - | CODE-BACKED | Current ask price for the currency instrument. |
| R10 | Precision | INT | NO | - | CODE-BACKED | ExchangeFeeMultiplier from Trade.ProviderToInstrument aliased as Precision. Multiplier applied to fee calculations for this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (delegation) | Billing.ExchangeRatesByPlayerLevelGet | EXEC | Core rate/fee calculation delegated to this procedure |
| @FundingTypeID | Dictionary.FundingType | Lookup | FundingTypeID is validated/resolved in ExchangeRatesByPlayerLevelGet |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetExchangeRatesForCustomerFunding | (delegation) | EXEC | CID-based wrapper calls this after resolving PlayerLevelID |
| Application payment services | @PlayerLevelID | EXEC | Direct callers that already have the player level |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetExchangeRatesForCustomerFunding_v2 (procedure)
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
| Billing.ExchangeRatesByPlayerLevelGet | Stored Procedure | INSERT INTO @Result EXEC - retrieves all applicable rates then filtered |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetExchangeRatesForCustomerFunding | Stored Procedure | EXEC - CID wrapper delegates here after resolving PlayerLevelID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get exchange rates for a VIP customer depositing via credit card

```sql
EXEC Billing.GetExchangeRatesForCustomerFunding_v2
    @FundingTypeID = 1,       -- Credit card
    @PlayerLevelID = 3,       -- VIP tier 3
    @CountryID = NULL;
```

### 8.2 Get rates with country-specific override

```sql
EXEC Billing.GetExchangeRatesForCustomerFunding_v2
    @FundingTypeID = 35,      -- Trustly
    @PlayerLevelID = 0,       -- Standard tier
    @CountryID = 74;          -- Country-specific override
```

### 8.3 Check what ExchangeRatesByPlayerLevelGet returns for a player level

```sql
-- Inspect underlying rate data before v2 filters by FundingTypeID
EXEC Billing.ExchangeRatesByPlayerLevelGet
    @PlayerLevelID = 0,
    @CountryID = NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetExchangeRatesForCustomerFunding_v2 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetExchangeRatesForCustomerFunding_v2.sql*
