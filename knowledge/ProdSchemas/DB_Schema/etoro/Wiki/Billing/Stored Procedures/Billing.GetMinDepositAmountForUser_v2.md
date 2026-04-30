# Billing.GetMinDepositAmountForUser_v2

> The preferred replacement for GetMinDepositAmountForUser - same FTD detection and DepositAmount lookup, but CountryID is passed in as a parameter instead of being resolved internally via Customer.Customer.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid + @countryID - returns (MinAmount, Package1Amount, Package2Amount, Package3Amount, IsPackageVisible) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetMinDepositAmountForUser_v2` is the replacement for `GetMinDepositAmountForUser` (created 28/3/2022, PAYIL-3926). The only difference is that `@countryID` is now an explicit input parameter instead of being resolved internally from `Customer.Customer`.

Externalizing the country lookup enables callers to pass a pre-resolved or overridden country (e.g., using the country provided in the payment form rather than the registered country, or using a country that has already been retrieved earlier in the request). This also eliminates the `Customer.Customer` dependency, making the procedure more efficient when the caller already has the country.

The code comment explicitly states: "THIS REPLACES [Billing].[GetMinDepositAmountForUser] - Needs to be deleted" (the v1 is the one to be deleted).

---

## 2. Business Logic

### 2.1 FTD Detection (Same as v1)

**What**: Determines whether the customer is a first-time depositor.

**Columns/Parameters Involved**: `@isFTD`, `Billing.Deposit.PaymentStatusID=2`, `@cid`

**Rules**:
- `@isFTD = 0` if: approved deposit exists (PaymentStatusID=2) for the customer
- `@isFTD = 1` if: no approved deposits exist (first time)
- Identical to v1 logic

### 2.2 DepositAmount Lookup (Same as v1, but no Customer.Customer)

**What**: Fetches deposit configuration for the customer's country and FTD status.

**Columns/Parameters Involved**: `@isFTD`, `@countryID`, `Billing.DepositAmount`

**Rules**:
- Same filter as v1: `WHERE FTD=@isFTD AND (@countryID IS NOT NULL OR mda.CountryID=0) AND (@countryID IS NULL OR mda.CountryID=@countryID)`
- `@countryID=NULL` -> matches CountryID=0 (global fallback)
- `@countryID != NULL` -> matches specific country row

### 2.3 v1 vs v2 Difference

| Aspect | GetMinDepositAmountForUser (v1) | GetMinDepositAmountForUser_v2 |
|--------|--------------------------------|-------------------------------|
| CountryID source | Internal: `SELECT CountryID FROM Customer.Customer WHERE CID=@cid` | External: `@countryID INT` parameter |
| Dependencies | Customer.Customer + Billing.Deposit + Billing.DepositAmount | Billing.Deposit + Billing.DepositAmount |
| Flexibility | Always uses registered country | Caller can override or pre-resolve country |
| Status | Should be replaced | Preferred version |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Used only for FTD detection (Billing.Deposit lookup). Country is no longer resolved from here. |
| 2 | @countryID | INT | NO | - | CODE-BACKED | Customer's country ID passed by the caller. NULL triggers global fallback (CountryID=0 in DepositAmount). Non-NULL triggers country-specific lookup. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | MinAmount | decimal(18,2) | NO | - | CODE-BACKED | Minimum deposit amount in USD for this customer's country and FTD status. Global fallback for FTD=false is $50. |
| 4 | Package1Amount | decimal(18,2) | YES | - | CODE-BACKED | First suggested deposit amount. Typical value: $200. Only shown when IsPackageVisible=1. |
| 5 | Package2Amount | decimal(18,2) | YES | - | CODE-BACKED | Second suggested deposit amount. Typical value: $400. Only shown when IsPackageVisible=1. |
| 6 | Package3Amount | decimal(18,2) | YES | - | CODE-BACKED | Third suggested deposit amount. Typical value: $1,000. Only shown when IsPackageVisible=1. |
| 7 | IsPackageVisible | bit | NO | 0 | CODE-BACKED | Whether to display the Package1/2/3 buttons. 1=show, 0=hide. Only 8 DepositAmount rows have IsPackageVisible=1 (all FTD=true). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXISTS check | Billing.Deposit | Direct Read | FTD status determination (PaymentStatusID=2 check) |
| FROM | Billing.DepositAmount | Direct Read | Min amount and package configuration for (country, FTD) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers. Preferred replacement for v1 - called from application code. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetMinDepositAmountForUser_v2 (procedure)
├── Billing.Deposit (table)
└── Billing.DepositAmount (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | EXISTS check - determines FTD status (PaymentStatusID=2) |
| Billing.DepositAmount | Table | Read - returns MinAmount and package amounts for (CountryID, FTD) |

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

### 8.1 Get minimum deposit for a customer with pre-resolved country

```sql
EXEC Billing.GetMinDepositAmountForUser_v2
    @cid       = 12345678,
    @countryID = 9   -- pass the country from your context
-- Returns: MinAmount, Package1/2/3Amount, IsPackageVisible
```

### 8.2 Use with NULL country (global fallback)

```sql
EXEC Billing.GetMinDepositAmountForUser_v2
    @cid       = 12345678,
    @countryID = NULL
-- Falls back to CountryID=0 global row (MinAmount=$50 for returning depositors)
```

---

## 9. Atlassian Knowledge Sources

PAYIL-3926 (28/3/2022): Added @countryID parameter to externalize the country lookup. This procedure replaces GetMinDepositAmountForUser.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetMinDepositAmountForUser_v2 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetMinDepositAmountForUser_v2.sql*
