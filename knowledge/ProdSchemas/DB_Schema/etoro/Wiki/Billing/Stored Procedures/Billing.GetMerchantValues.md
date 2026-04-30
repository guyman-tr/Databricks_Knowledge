# Billing.GetMerchantValues

> Resolves the merchant account for a payment context (depot, mode, regulation, currency, type, BIN, country) and returns its API credential parameters - country-specific routing rules win over generic wildcard rules.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepotID + @DepotModeID + @RegulationID + optional dimensions - returns (MerchantAccountID, ParameterID, Value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetMerchantValues` is the primary merchant account credential resolver. When processing a payment, the system needs to know which payment processor API credentials to use - this depends on the depot (gateway), mode (live/demo), regulation (CySEC/FCA/ASIC), and optionally currency, payment type, country, and sub-type.

The procedure implements a two-stage lookup:
1. **Route**: Query `Billing.MerchantAccountRouting` to find all matching routing rules for the given context dimensions
2. **Prioritize**: Among matching rules, prefer country-specific rules over generic wildcards (`MAX(CountryID)` selection)
3. **Retrieve**: Join to `Billing.MerchantAccountValues` to return the API credentials (ParameterID/Value pairs) for the selected MerchantAccountID

The `@BinCode` parameter adds an additional resolution path: when provided, the BIN code is looked up in `Dictionary.CountryBin` to resolve the card's issuing country, enabling country-specific routing for credit card payments without knowing the customer's registered country.

Created by Shay Oren 27/12/2020 (PAYUS-20163), with subsequent enhancements: KateM 19/01/2022 (PAYSOLB-475), Dor Izmaylov 09/05/2023 (PAYIL-6492, CountryID parameter), Dor Izmaylov (PAYUSOLA-6872, Value precision to 500... actually changed to VARCHAR(4000)).

---

## 2. Business Logic

### 2.1 Routing Dimension Matching

**What**: Finds all routing records matching the payment context, with wildcard support for optional dimensions.

**Columns/Parameters Involved**: `@DepotID`, `@DepotModeID`, `@RegulationID`, `@CurrencyID`, `@PaymentTypeID`, `@SubTypeID`

**Rules**:
- `BMAR.DepotID = @DepotID` - exact match (no wildcard)
- `BMAR.DepotModeID = @DepotModeID` - exact match
- `BMAR.RegulationID = @RegulationID` - exact match
- `BMAR.CurrencyID IN (@CurrencyID, 0)` - matches exact currency OR wildcard (0=any)
- `BMAR.PaymentTypeID = @PaymentTypeID` - exact match (0=any when caller passes 0)
- `BMAR.SubTypeID = @SubTypeID` - exact match (0=default)

### 2.2 Country Resolution with BIN Code

**What**: Resolves the customer's issuing country from a credit card BIN code, then uses that for country-specific routing.

**Columns/Parameters Involved**: `@BinCode`, `@CountryID`, `Dictionary.CountryBin`, `BMAR.CountryID`

**Rules**:
- If `@BinCode IS NOT NULL`: look up `CountryID` from `Dictionary.CountryBin WHERE BinCode = @BinCode` (OUTER APPLY, returns NULL if not found -> ISNULL -> 0)
- If `@BinCode IS NULL`: use `@CountryID` directly (defaults to 0 = any country)
- Routing match: `BMAR.CountryID = <resolved_country> OR BMAR.CountryID = 0` (both specific and wildcard can match)

**Diagram**:
```
@BinCode IS NOT NULL:
  resolved_country = Dictionary.CountryBin.CountryID WHERE BinCode = @BinCode
                     (or 0 if not found)

@BinCode IS NULL:
  resolved_country = @CountryID (default 0)

Routing match:
  BMAR.CountryID = resolved_country   <- country-specific rule
  OR BMAR.CountryID = 0               <- wildcard rule
```

### 2.3 Country Specificity Priority (MAX(CountryID))

**What**: When both country-specific and wildcard rules match, prefer the country-specific rule.

**Columns/Parameters Involved**: `CountryID` in `@ParamList`, `MAX(CountryID)`

**Rules**:
- All matching routing rows (with their credential values) are inserted into `@ParamList` temp table
- Final SELECT: `WHERE CountryID = (SELECT MAX(CountryID) FROM @ParamList)`
- Since `CountryID=0` (wildcard) < any real `CountryID` (positive integer), `MAX` always returns the most specific country
- If only wildcard rules matched: `MAX = 0`, returns those
- If country-specific rules matched: `MAX = <country_id>`, only those are returned (wildcards suppressed)

**Diagram**:
```
@ParamList might contain:
  { MerchantAccountID=1, ParameterID=9, Value="EU LTD", CountryID=0  }  <- wildcard
  { MerchantAccountID=2, ParameterID=9, Value="DE Entity", CountryID=5 } <- Germany-specific

MAX(CountryID) = 5
-> Returns only CountryID=5 rows (Germany-specific merchant account)
-> CountryID=0 rows are suppressed
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepotID | INT | NO | - | CODE-BACKED | Payment depot (gateway) to route through. FK to Billing.Depot.DepotID. Required - no wildcard. |
| 2 | @DepotModeID | INT | NO | - | CODE-BACKED | Depot operating mode. 1=Live, 2=Demo. Required - no wildcard. |
| 3 | @RegulationID | INT | NO | - | CODE-BACKED | Regulatory entity under which the payment is processed (CySEC=1, FCA=2, ASIC=4, etc.). Required - no wildcard. |
| 4 | @CurrencyID | INT | YES | 0 | CODE-BACKED | Payment currency. 0=any (wildcard). Matches routing rules for this currency OR wildcard rules. |
| 5 | @PaymentTypeID | INT | YES | 0 | CODE-BACKED | Payment type (deposit/withdrawal/etc). 0=any. Exact match against routing rule PaymentTypeID. |
| 6 | @BinCode | INT | YES | NULL | CODE-BACKED | Credit card BIN code (first 6 digits). If provided, resolved to a CountryID via Dictionary.CountryBin for country-specific routing. Takes precedence over @CountryID. |
| 7 | @SubTypeID | INT | YES | 0 | CODE-BACKED | Sub-routing variant. 0=default. Allows multiple routing variants for the same depot+mode+regulation combination. |
| 8 | @CountryID | INT | YES | 0 | CODE-BACKED | Customer country for routing. 0=any. Used only when @BinCode IS NULL. Country-specific rules (non-zero) take precedence over wildcards (0) via MAX(CountryID) selection. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 9 | MerchantAccountID | int | NO | - | CODE-BACKED | The resolved merchant account ID. All returned rows share the same MerchantAccountID (the most country-specific one matched). |
| 10 | ParameterID | int | YES | - | CODE-BACKED | Credential parameter type identifier (from Billing.Parameter). Examples: 9=entity name, 156=API key name, 167=boolean flag. |
| 11 | Value | varchar(4000) | NO | - | CODE-BACKED | The credential value for this parameter. Examples: "EU LTD" (entity name), "ApiKeyCheckoutEU" (API key identifier), "false" (boolean flag). Always VARCHAR regardless of actual data type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Billing.MerchantAccountRouting | Direct Read | Routing lookup - finds matching merchant account rules for the payment context dimensions |
| JOIN (via BMVAV) | Billing.MerchantAccountValues | Direct Read | Credential retrieval - gets parameter values for the resolved MerchantAccountID |
| OUTER APPLY | Dictionary.CountryBin | Direct Read | BIN code to country resolution - maps credit card BIN to issuing CountryID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers found. Called from payment processing application code. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetMerchantValues (procedure)
├── Billing.MerchantAccountRouting (table)
├── Billing.MerchantAccountValues (table)
└── Dictionary.CountryBin (table) - only when @BinCode IS NOT NULL
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.MerchantAccountValues | Table | JOIN - retrieves credential parameter values for the matched merchant account |
| Billing.MerchantAccountRouting | Table | JOIN - matches payment context dimensions to MerchantAccountID |
| Dictionary.CountryBin | Table | OUTER APPLY - resolves @BinCode to CountryID for country-specific routing |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get merchant credentials for a live Checkout.com payment (EU/CySEC)

```sql
EXEC Billing.GetMerchantValues
    @DepotID       = 92,   -- Checkout.com
    @DepotModeID   = 1,    -- Live
    @RegulationID  = 1,    -- CySEC
    @CurrencyID    = 0,    -- any currency
    @PaymentTypeID = 0,    -- any payment type
    @BinCode       = NULL,
    @SubTypeID     = 0,
    @CountryID     = 0
-- Returns: MerchantAccountID, ParameterID, Value rows for the matched merchant account
```

### 8.2 Get merchant credentials with BIN-based country routing

```sql
EXEC Billing.GetMerchantValues
    @DepotID       = 92,
    @DepotModeID   = 1,
    @RegulationID  = 1,
    @BinCode       = 421456  -- card's first 6 digits -> resolves to CountryID
-- If a country-specific rule exists for that BIN's country, it wins over wildcard
```

### 8.3 Check what routing rules exist for a depot

```sql
SELECT BMAR.*, BMVAV.ParameterID, BMVAV.Value
FROM Billing.MerchantAccountRouting BMAR WITH (NOLOCK)
JOIN Billing.MerchantAccountValues BMVAV WITH (NOLOCK)
    ON BMAR.MerchantAccountID = BMVAV.MerchantAccountID
WHERE BMAR.DepotID = 92
  AND BMAR.DepotModeID = 1
ORDER BY BMAR.CountryID DESC, BMAR.MerchantAccountID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetMerchantValues | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetMerchantValues.sql*
