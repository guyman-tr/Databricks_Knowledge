# Billing.GetRanksByCountryAndFundingType

> Returns the ordered list of available currencies (Rank, CurrencyID) for a specific country and payment method combination from the CurrencyPerFundingTypeOverrides table, used by the deposit setup and deposit services to present currency options to the customer.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Rank, CurrencyID from Billing.CurrencyPerFundingTypeOverrides WHERE CountryID=@CountryID AND FundingTypeID=@FundingTypeID ORDER BY Rank |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRanksByCountryAndFundingType` retrieves the currency options and their display order for a specific country and payment method. When a customer initiates a deposit in a country that has currency overrides configured, this procedure returns the list of available currencies ranked by preference order.

The procedure exists to allow the deposit setup service and deposit service to populate currency selection UI for deposit flows. A customer in Germany (CountryID=X) depositing via Credit Card (FundingTypeID=1) might be offered EUR first, then USD - this ordering comes from the Rank column in `Billing.CurrencyPerFundingTypeOverrides`.

Data flows: `DepositSetupUser` and `DepositUser` both call this procedure during deposit initiation. If no rows are returned (no overrides configured for this country/funding type combination), the caller falls back to the default depot-based currency list. The procedure is complementary to `Billing.GetFundingTypesWithOverrides` which handles the full override logic; this procedure provides the raw rank data for the specific combination.

---

## 2. Business Logic

### 2.1 Currency Rank Lookup

**What**: Returns currencies in priority order for a country/funding type combination.

**Columns/Parameters Involved**: `@CountryID`, `@FundingTypeID`, `Rank`, `CurrencyID`

**Rules**:
- `WHERE CountryID = @CountryID AND FundingTypeID = @FundingTypeID` - exact match on both dimensions
- `ORDER BY Rank` - returns currencies in display priority order (Rank=1 is the default/preferred currency)
- Returns only `Rank` and `CurrencyID` - minimal result set, no IsDefault flag
- Returns 0 rows if no override is configured for this country/funding type (caller then uses default depot currencies)

### 2.2 Error Handling Pattern

**What**: The procedure includes a TRY/CATCH block with RAISERROR.

**Rules**:
- `BEGIN TRY ... END TRY BEGIN CATCH ... RAISERROR END CATCH` - structured error handling
- On any error, captures ERROR_MESSAGE, ERROR_SEVERITY, ERROR_STATE and re-raises
- This propagates the original error details to the caller rather than swallowing exceptions
- `SET NOCOUNT ON` - suppresses row count messages (performance best practice)

### 2.3 Relationship to Override Logic

**What**: This procedure is part of the CurrencyPerFundingTypeOverrides system.

**Context** (from `Billing.CurrencyPerFundingTypeOverrides` documentation):
- When ANY override rows exist for (CountryID, FundingTypeID), the default depot currencies are FULLY REPLACED
- `GetRanksByCountryAndFundingType` retrieves just the override rows for the caller to use
- `GetFundingTypesWithOverrides` implements the full EXCEPT + UNION ALL logic that combines defaults with overrides
- Both procedures serve different consumers with different needs

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryID | INT | NO | - | CODE-BACKED | Customer's country. FK to Dictionary.Country. Scopes the currency override lookup to this country. |
| 2 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type. FK to Dictionary.FundingType (1=CreditCard, 2=WireTransfer, 3=PayPal, etc.). Scopes the currency override lookup to this funding type. |

**Return columns:**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 3 | Rank | Billing.CurrencyPerFundingTypeOverrides.Rank | CODE-BACKED | Display priority order for this currency in the deposit UI. Rank=1 is the default/preferred currency shown first. Ascending order (lower rank = higher priority). |
| 4 | CurrencyID | Billing.CurrencyPerFundingTypeOverrides.CurrencyID | CODE-BACKED | The currency available for this country/funding type combination. FK to Dictionary.Currency (1=USD, 2=EUR, etc.). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CountryID | Billing.CurrencyPerFundingTypeOverrides.CountryID | Filter | Scopes lookup to the customer's country |
| @FundingTypeID | Billing.CurrencyPerFundingTypeOverrides.FundingTypeID | Filter | Scopes lookup to the selected payment method |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositSetupUser | GRANT EXECUTE | Permission | Deposit setup service populates currency options for the deposit flow UI |
| DepositUser | GRANT EXECUTE | Permission | Deposit service retrieves currency ranks during deposit processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRanksByCountryAndFundingType (procedure)
└── Billing.CurrencyPerFundingTypeOverrides (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CurrencyPerFundingTypeOverrides | Table | Filtered SELECT by CountryID and FundingTypeID; returns Rank and CurrencyID ordered by Rank |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositSetupUser | DB Security Principal | EXECUTE permission - currency rank lookup for deposit setup flow |
| DepositUser | DB Security Principal | EXECUTE permission - currency rank lookup during deposit processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Source table context**: `Billing.CurrencyPerFundingTypeOverrides` is a system-versioned temporal table (2,527 rows as of documentation date) with History tracked in `History.BillingCurrencyPerFundingTypeOverrides`. The composite PK is (CountryID, FundingTypeID, CurrencyID). This procedure returns a subset of columns (Rank + CurrencyID) rather than `SELECT *`, which is a good pattern for interface stability. **No NOLOCK hint** - unlike many Billing schema procedures, this does not use NOLOCK. Given the temporal table design, this is appropriate as NOLOCK on system-versioned tables can produce inconsistent results.

---

## 8. Sample Queries

### 8.1 Get currency ranks for a country and funding type
```sql
EXEC [Billing].[GetRanksByCountryAndFundingType]
    @CountryID = 1,
    @FundingTypeID = 1
```

### 8.2 Check which country/funding type combinations have overrides
```sql
SELECT CountryID, FundingTypeID, COUNT(*) AS CurrencyCount
FROM Billing.CurrencyPerFundingTypeOverrides
GROUP BY CountryID, FundingTypeID
ORDER BY CountryID, FundingTypeID
```

### 8.3 Get the default currency for a specific country/funding type
```sql
SELECT TOP 1 CurrencyID, Rank
FROM Billing.CurrencyPerFundingTypeOverrides
WHERE CountryID = 1 AND FundingTypeID = 1
ORDER BY Rank
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetRanksByCountryAndFundingType | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRanksByCountryAndFundingType.sql*
