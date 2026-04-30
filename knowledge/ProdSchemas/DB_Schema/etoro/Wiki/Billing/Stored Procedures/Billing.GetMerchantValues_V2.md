# Billing.GetMerchantValues_V2

> Enhanced version of GetMerchantValues that adds CurrencyID as a second prioritization dimension - country-specific AND currency-specific routing rules win over generic wildcards.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepotID + @DepotModeID + @RegulationID + optional dimensions - returns (MerchantAccountID, ParameterID, Value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetMerchantValues_V2` is an enhanced version of `GetMerchantValues` with one key difference: the final credential selection uses both `MAX(CountryID)` and `MAX(CurrencyID)` to prefer currency-specific rules in addition to country-specific rules.

This allows routing different merchant accounts for the same depot/mode/regulation/country combination based on the payment currency - for example, routing EUR payments through one Checkout.com merchant account and USD payments through another, within the same regulatory entity.

The core logic (routing dimension matching, BIN code resolution, OUTER APPLY to Dictionary.CountryBin) is identical to `GetMerchantValues`. Added by Dor Izmaylov 07/09/2023 (PAYIL-7194 "Allow GetMerchantValues by CurrencyID").

---

## 2. Business Logic

### 2.1 Identical Routing to GetMerchantValues

**What**: All routing dimension matching and BIN code country resolution is identical to `GetMerchantValues`. See that procedure's documentation for the full routing algorithm.

**Differences from GetMerchantValues**:
- The `@ParamList` temp table includes a `CurrencyID INT` column (in addition to CountryID)
- `BMAR.CurrencyID` is stored in `@ParamList` (not just used for filtering)
- Final SELECT adds: `AND CurrencyID = (SELECT MAX(CurrencyID) FROM @ParamList)`

### 2.2 Dual Prioritization: Country AND Currency

**What**: When multiple routing rules match, the rule that is both most country-specific AND most currency-specific wins.

**Columns/Parameters Involved**: `CountryID`, `CurrencyID` in `@ParamList`, `MAX(CountryID)`, `MAX(CurrencyID)`

**Rules**:
- `WHERE CountryID = (SELECT MAX(CountryID) FROM @ParamList)` - same as V1: prefer specific country over wildcard (0)
- `AND CurrencyID = (SELECT MAX(CurrencyID) FROM @ParamList)` - NEW: prefer specific currency over wildcard (0)
- Both conditions must be satisfied: the winning rule must be BOTH most-country AND most-currency specific

**Prioritization matrix**:
```
Row | CountryID | CurrencyID | Wins?
----|-----------|------------|------
 A  |     0     |     0      | Only if no other rows
 B  |     5     |     0      | Wins if no C or D
 C  |     0     |     2      | Wins if no D
 D  |     5     |     2      | Always wins (most specific)

MAX(CountryID) = 5 -> filter to rows B and D
MAX(CurrencyID) among B,D: B=0, D=2 -> MAX=2 -> filter to D only
Result: row D (CountryID=5, CurrencyID=2) wins
```

**Limitation**: The dual MAX filtering is applied independently, not jointly. If there's no single rule that matches both `MAX(CountryID)` and `MAX(CurrencyID)`, the result may be empty or unexpected. This assumes routing data is consistent (a country-specific rule exists for each currency where currency-specific routing is needed).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepotID | INT | NO | - | CODE-BACKED | Payment depot (gateway). FK to Billing.Depot.DepotID. Required. |
| 2 | @DepotModeID | INT | NO | - | CODE-BACKED | Mode: 1=Live, 2=Demo. Required. |
| 3 | @RegulationID | INT | NO | - | CODE-BACKED | Regulatory entity (CySEC=1, FCA=2, ASIC=4, etc.). Required. |
| 4 | @CurrencyID | INT | YES | 0 | CODE-BACKED | Payment currency. 0=any. Used for both routing filter AND currency-specificity selection in V2. |
| 5 | @PaymentTypeID | INT | YES | 0 | CODE-BACKED | Payment type. 0=any. Exact match. |
| 6 | @BinCode | INT | YES | NULL | CODE-BACKED | Credit card BIN code. If provided, resolved via Dictionary.CountryBin for country-specific routing. |
| 7 | @SubTypeID | INT | YES | 0 | CODE-BACKED | Sub-routing variant. 0=default. |
| 8 | @CountryID | INT | YES | 0 | CODE-BACKED | Customer country. 0=any. Used only when @BinCode IS NULL. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 9 | MerchantAccountID | int | NO | - | CODE-BACKED | The resolved merchant account ID - selected by both country and currency specificity. |
| 10 | ParameterID | int | YES | - | CODE-BACKED | Credential parameter type identifier. Same values as GetMerchantValues (9=entity name, 156=API key, etc.). |
| 11 | Value | varchar(4000) | NO | - | CODE-BACKED | The credential value as a string. Always VARCHAR regardless of actual type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Billing.MerchantAccountRouting | Direct Read | Routing lookup - same as GetMerchantValues |
| JOIN (via BMVAV) | Billing.MerchantAccountValues | Direct Read | Credential retrieval - same as GetMerchantValues |
| OUTER APPLY | Dictionary.CountryBin | Direct Read | BIN code to country resolution - same as GetMerchantValues |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers found. Called from application code for currency-aware merchant routing. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetMerchantValues_V2 (procedure)
├── Billing.MerchantAccountRouting (table)
├── Billing.MerchantAccountValues (table)
└── Dictionary.CountryBin (table) - only when @BinCode IS NOT NULL
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.MerchantAccountValues | Table | JOIN - retrieves credential parameter values for the matched merchant account |
| Billing.MerchantAccountRouting | Table | JOIN - matches payment context dimensions to MerchantAccountID (WITH NOLOCK, unlike V1) |
| Dictionary.CountryBin | Table | OUTER APPLY - resolves @BinCode to CountryID |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note**: V2 adds `WITH(NOLOCK)` hints on `Billing.MerchantAccountValues` and `Billing.MerchantAccountRouting` that are absent in V1.

---

## 8. Sample Queries

### 8.1 Get currency-aware merchant credentials

```sql
EXEC Billing.GetMerchantValues_V2
    @DepotID       = 92,
    @DepotModeID   = 1,    -- Live
    @RegulationID  = 1,    -- CySEC
    @CurrencyID    = 2,    -- EUR-specific routing
    @CountryID     = 5     -- Germany-specific routing
-- Returns rules matching BOTH CountryID=5 AND CurrencyID=2 (or best available)
```

### 8.2 V1 vs V2 comparison

```sql
-- V1: only country-specific priority
EXEC Billing.GetMerchantValues    @DepotID=92, @DepotModeID=1, @RegulationID=1, @CurrencyID=2, @CountryID=5
-- V2: country AND currency-specific priority
EXEC Billing.GetMerchantValues_V2 @DepotID=92, @DepotModeID=1, @RegulationID=1, @CurrencyID=2, @CountryID=5
-- Results differ when routing rules exist that are both country=5 AND currency=2 specific
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetMerchantValues_V2 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetMerchantValues_V2.sql*
