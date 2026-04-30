# Billing.GetMinDepositAmountForUser

> Returns the minimum deposit amount and suggested package amounts for a customer by detecting their FTD (First Time Depositor) status and looking up the per-country configuration in Billing.DepositAmount.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid - returns (MinAmount, Package1Amount, Package2Amount, Package3Amount, IsPackageVisible) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetMinDepositAmountForUser` determines the minimum deposit threshold and suggested deposit "packages" that should be presented to a specific customer. The minimum amount differs based on two factors: the customer's country and whether they are making their first-ever deposit (FTD=First Time Deposit).

The procedure internally detects FTD status by checking if the customer has any approved deposit (`PaymentStatusID=2`) in `Billing.Deposit`. This auto-detection means the caller does not need to know the customer's deposit history - just the customer ID. The country is resolved from `Customer.Customer.CountryID`.

**Superseded by v2**: The code comment in `GetMinDepositAmountForUser_v2` states it should replace this procedure (v2 externalizes the `@countryID` parameter, added 28/3/2022 PAYIL-3926, to avoid the internal Customer.Customer lookup). Both procedures exist in the codebase, though v2 is preferred for new integrations.

---

## 2. Business Logic

### 2.1 FTD Detection

**What**: Determines whether the customer is a first-time depositor by checking for any approved deposit.

**Columns/Parameters Involved**: `@isFTD`, `Billing.Deposit.PaymentStatusID`, `Billing.Deposit.CID`

**Rules**:
- `@isFTD = 0` (returning depositor) if: `EXISTS (SELECT 42 FROM Billing.Deposit WHERE PaymentStatusID=2 AND CID=@cid)`
- `@isFTD = 1` (first-time depositor) if: no approved deposit exists
- `PaymentStatusID=2` = approved/successful deposit (same threshold used throughout Billing procedures)

### 2.2 Country Lookup

**What**: Retrieves the customer's country from their Customer record.

**Columns/Parameters Involved**: `@countryID`, `Customer.Customer.CountryID`

**Rules**:
- `SELECT @countryID = CountryID FROM Customer.Customer WHERE CID = @cid`
- `@countryID` can be NULL if the customer has no registered country (new/incomplete registration)
- NULL country is handled in the DepositAmount lookup via the filter logic

### 2.3 DepositAmount Lookup

**What**: Fetches the deposit configuration row matching the customer's FTD status and country.

**Columns/Parameters Involved**: `@isFTD`, `@countryID`, `Billing.DepositAmount.CountryID`, `Billing.DepositAmount.FTD`

**Rules**:
- `WHERE FTD = @isFTD AND (@countryID IS NOT NULL OR mda.CountryID = 0) AND (@countryID IS NULL OR mda.CountryID = @countryID)`
- If `@countryID IS NULL`: only matches `CountryID=0` (global fallback)
- If `@countryID IS NOT NULL`: only matches `CountryID = @countryID` (country-specific row)
- No fallback to CountryID=0 when a specific country is provided - the calling layer handles the fallback

**Diagram**:
```
@cid -> Customer.Customer -> @countryID
@cid -> Billing.Deposit (PaymentStatusID=2) -> @isFTD

Billing.DepositAmount WHERE FTD=@isFTD AND CountryID=@countryID
Returns: MinAmount, Package1Amount, Package2Amount, Package3Amount, IsPackageVisible
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Used to look up country (Customer.Customer) and FTD status (Billing.Deposit). |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | MinAmount | decimal(18,2) | NO | - | CODE-BACKED | Minimum deposit amount in USD for this customer's country and FTD status. Global fallback for FTD=false is $50. First-time depositors may have different thresholds. |
| 3 | Package1Amount | decimal(18,2) | YES | - | CODE-BACKED | First suggested deposit amount (quick-select button). NULL if not applicable. Typical value: $200. Only shown when IsPackageVisible=1. |
| 4 | Package2Amount | decimal(18,2) | YES | - | CODE-BACKED | Second suggested deposit amount. NULL if not applicable. Typical value: $400. Only shown when IsPackageVisible=1. |
| 5 | Package3Amount | decimal(18,2) | YES | - | CODE-BACKED | Third suggested deposit amount. NULL if not applicable. Typical value: $1,000. Only shown when IsPackageVisible=1. |
| 6 | IsPackageVisible | bit | NO | 0 | CODE-BACKED | Whether to display the Package1/2/3 buttons in the deposit UI. 1=show, 0=hide (customer enters amount manually). Only 8 rows in DepositAmount have IsPackageVisible=1, all for FTD=true. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (countryID) | Customer.Customer | Direct Read | Reads customer's registered country for deposit amount lookup |
| EXISTS check | Billing.Deposit | Direct Read | Checks if customer has any approved deposits (PaymentStatusID=2) to determine FTD status |
| FROM | Billing.DepositAmount | Direct Read | Retrieves min amount and package amounts for (country, FTD) combination |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers. Superseded by GetMinDepositAmountForUser_v2 (PAYIL-3926, 28/3/2022). Called from application code. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetMinDepositAmountForUser (procedure)
├── Customer.Customer (table)
├── Billing.Deposit (table)
└── Billing.DepositAmount (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Read - retrieves CountryID for the customer |
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

### 8.1 Get minimum deposit for a customer

```sql
EXEC Billing.GetMinDepositAmountForUser @cid = 12345678
-- Returns: MinAmount, Package1/2/3Amount, IsPackageVisible
-- Internally detects FTD status and resolves country
```

### 8.2 Equivalent ad-hoc query

```sql
DECLARE @countryID INT, @isFTD BIT
SELECT @countryID = CountryID FROM Customer.Customer WITH (NOLOCK) WHERE CID = 12345678
SELECT @isFTD = CASE WHEN EXISTS (
    SELECT 1 FROM Billing.Deposit WITH (NOLOCK)
    WHERE PaymentStatusID = 2 AND CID = 12345678)
THEN 0 ELSE 1 END

SELECT MinAmount, Package1Amount, Package2Amount, Package3Amount, IsPackageVisible
FROM Billing.DepositAmount WITH (NOLOCK)
WHERE FTD = @isFTD
  AND ((@countryID IS NOT NULL AND CountryID = @countryID)
       OR (@countryID IS NULL AND CountryID = 0))
```

### 8.3 Use v2 instead (preferred)

```sql
-- v2 avoids the internal Customer.Customer lookup:
DECLARE @countryID INT
SELECT @countryID = CountryID FROM Customer.Customer WITH (NOLOCK) WHERE CID = 12345678

EXEC Billing.GetMinDepositAmountForUser_v2 @cid = 12345678, @countryID = @countryID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetMinDepositAmountForUser | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetMinDepositAmountForUser.sql*
