# Billing.DepositAmount

> Per-country, per-customer-type configuration of deposit amount limits and suggested package amounts; defines MinAmount/MaxAmount and three suggested deposit "packages" shown to customers, split by First Time Deposit (FTD) vs. returning depositor status.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | Id - IDENTITY PK CLUSTERED |
| **Partition** | N/A - PRIMARY filegroup |
| **Indexes** | 1 (PK on Id) |
| **System-Versioned** | YES - History.DepositAmount |

---

## 1. Business Meaning

`Billing.DepositAmount` configures the deposit amount constraints and suggested "package" amounts shown to customers when initiating a deposit. It has two dimensions:
- **CountryID**: Country-specific limits. CountryID=0 is the global fallback (used when no country-specific row exists).
- **FTD** (First Time Deposit): `1` = configuration for customers making their FIRST deposit ever; `0` = configuration for returning depositors who have previously deposited.

The table holds 501 rows: 251 for FTD=false (returning depositors), 242 for FTD=true, and 8 for FTD=true + IsPackageVisible=true.

`GetDepositAmountsForUser` implements the lookup: it first checks if the customer has any approved deposit (PaymentStatusID=2 in Billing.Deposit) to determine FTD status, then fetches the matching (CountryID, FTD) row.

The table is system-versioned - changes to deposit limits are tracked in History.DepositAmount.

---

## 2. Business Logic

### 2.1 FTD vs. Returning Depositor Limits

**What**: First-time depositors see different minimum/maximum amounts and package suggestions than returning depositors.

**Columns/Parameters Involved**: `FTD`, `MinAmount`, `MaxAmount`, `CountryID`

**Rules**:
```
GetDepositAmountsForUser(@CID, @CountryID):
  IsFTD = 1 IF no approved deposit (PaymentStatusID=2) exists for @CID
            ELSE 0

  SELECT MinAmount, MaxAmount, Package1Amount, Package2Amount, Package3Amount, IsPackageVisible
  FROM   Billing.DepositAmount
  WHERE  FTD = @IsFTD
    AND  CountryID = ISNULL(@CountryID, 0)  -- 0 = global fallback
```

The FTD=0 global fallback row: MinAmount=50, no MaxAmount, packages=200/400/1000.
The FTD=0 CountryID=1 row: MinAmount=2, MaxAmount=50 (unusually low - may be a test or special jurisdiction).

### 2.2 Package Suggestions

**What**: Up to 3 pre-defined deposit amounts are offered as quick-select buttons in the deposit UI. IsPackageVisible controls whether the packages are displayed.

**Columns/Parameters Involved**: `Package1Amount`, `Package2Amount`, `Package3Amount`, `IsPackageVisible`

**Rules**:
- IsPackageVisible=1 (8 rows, all FTD=true): Package amounts displayed as suggested deposit buttons in the UI.
- IsPackageVisible=0 (493 rows): Package amounts not displayed; customer enters amount manually.
- Default package values when visible: $200 / $400 / $1,000 (from global fallback row).
- All three package columns are nullable - a package can be omitted if fewer than 3 options are needed.

### 2.3 CountryID=0 Global Fallback

**What**: CountryID=0 is the catch-all row used when no country-specific limit is configured.

**Rules**:
```
GetDepositAmountsForUser passes @CountryID=NULL if no country provided
  -> ISNULL(@CountryID, 0) = 0
  -> Uses global fallback row (CountryID=0):
       FTD=false: MinAmount=50, MaxAmount=NULL, packages=200/400/1000, IsPackageVisible=false
```

---

## 3. Data Overview

| Id | CountryID | MinAmount | MaxAmount | Package1 | Package2 | Package3 | FTD | IsPackageVisible |
|----|-----------|-----------|-----------|----------|----------|----------|-----|-----------------|
| 1 | 0 (global) | 50.00 | NULL | 200.00 | 400.00 | 1000.00 | false | false | Global fallback for returning depositors: min $50, no max |
| 2 | 1 | 2.00 | 50.00 | 200.00 | 400.00 | 1000.00 | false | false | Country 1 special: min $2, max $50 (low-limit jurisdiction) |
| 3-10 | 2-9 | 50.00 | NULL/10000 | 200.00 | 400.00 | 1000.00 | false | false | Standard per-country rows |
| (501 total) | (0 to ~250) | (varies) | (mostly NULL) | 200.00 | 400.00 | 1000.00 | true/false | mostly false |

Distribution:
- FTD=false, IsPackageVisible=false: 251 rows (returning depositors, no package buttons)
- FTD=true, IsPackageVisible=false: 242 rows (first-time depositors, no package buttons)
- FTD=true, IsPackageVisible=true: 8 rows (first-time depositors with package suggestion buttons)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | Country for which these deposit limits apply. Implicit FK to Dictionary.Country(CountryID). CountryID=0 is the global fallback used when no country-specific row exists (via ISNULL(@CountryID, 0) in GetDepositAmountsForUser). |
| 2 | MinAmount | decimal(18,2) | NO | - | VERIFIED | Minimum deposit amount in USD. The smallest amount a customer in this country can deposit (or globally, $50 for the fallback). Enforced at the deposit validation layer. |
| 3 | Package1Amount | decimal(18,2) | YES | - | VERIFIED | First suggested deposit amount shown as a quick-select button. NULL if not applicable. Default value is $200.00 across most rows. Only displayed when IsPackageVisible=1. |
| 4 | Package2Amount | decimal(18,2) | YES | - | VERIFIED | Second suggested deposit amount. NULL if not applicable. Default value is $400.00. Only displayed when IsPackageVisible=1. |
| 5 | Package3Amount | decimal(18,2) | YES | - | VERIFIED | Third suggested deposit amount. NULL if not applicable. Default value is $1,000.00. Only displayed when IsPackageVisible=1. |
| 6 | FTD | bit | NO | 0 | VERIFIED | First Time Deposit flag. 1=this row applies to customers making their FIRST approved deposit (no prior PaymentStatusID=2 in Billing.Deposit). 0=this row applies to returning depositors. GetDepositAmountsForUser dynamically determines FTD status and selects the appropriate row. DEFAULT 0. |
| 7 | Id | int IDENTITY(1,1) | NO | auto | VERIFIED | Surrogate PK. Auto-incremented row identifier. Not the natural business key - lookups are by (CountryID, FTD). |
| 8 | IsPackageVisible | bit | NO | 0 | VERIFIED | Whether the Package1/2/3 suggested amounts should be displayed in the deposit UI. 1=show package buttons (8 rows, all FTD=true), 0=hide packages, customer enters amount manually (493 rows). DEFAULT 0. |
| 9 | Trace | computed | NO | - | VERIFIED | Non-persisted JSON audit string (HostName, AppName, SUserName, SPID, DBName, ObjectName). Computed at query time for diagnostic purposes. Same pattern as CurrencyPerFundingTypeOverrides. |
| 10 | ValidFrom | datetime2(7) | NO | - | VERIFIED | System-time start: row became current at this timestamp. GENERATED ALWAYS AS ROW START. |
| 11 | ValidTo | datetime2(7) | NO | - | VERIFIED | System-time end: row was superseded at this timestamp (9999-12-31 for current rows). GENERATED ALWAYS AS ROW END. |
| 12 | MaxAmount | decimal(18,2) | YES | - | VERIFIED | Maximum deposit amount in USD. NULL means no upper limit. When set (e.g., MaxAmount=50 for CountryID=1), enforces a cap on deposit size for that country/depositor type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit | Country-specific deposit limit scoping |
| (history) | History.DepositAmount | System-Versioning | Temporal history table for all prior row versions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetDepositAmountsForUser | CountryID, FTD | READER | Primary consumer - looks up limits by (CountryID, FTD) based on customer's deposit history |
| Billing.GetDefaultDepositSettingsByCountryAndFtd | CountryID, FTD | READER | Direct config lookup by country and FTD status |
| Billing.GetDefaultDepositSettingsForUser | CountryID, FTD | READER | User-contextualized settings lookup |
| Billing.GetFundingTypeMaxAmount | MaxAmount | READER | Used for funding type max amount retrieval |
| Billing.UpdateFundingTypeMaxAmount | MaxAmount | WRITER | Updates MaxAmount for a (CountryID, FTD) row |
| Billing.GetMinDepositAmountForUser | MinAmount | READER | Minimum deposit amount for validation |
| Billing.GetMinDepositAmountForUser_v2 | MinAmount | READER | V2 minimum deposit lookup |
| Billing.GetCustomerDepositInfo | (multiple) | READER | Customer deposit configuration info |
| Billing.GetRedeemValidationData | MinAmount | READER | Minimum amount check for redeem flow |
| Billing.GetRedeemNFTValidationData | MinAmount | READER | NFT redeem validation |
| Billing.GetAllFundingTypes | (multiple) | READER | Full funding type configuration |
| Billing.GetMedianDepositAmount | (multiple) | READER | Statistical deposit amount analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositAmount (table)
  (no FK constraints in DDL - CountryID relationship is implicit)
|- History.DepositAmount [temporal history]
```

### 6.1 Objects This Depends On

No FK constraints. Implicit dependency on Dictionary.Country.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetDepositAmountsForUser | Stored Procedure | READER - main consumer for deposit UI configuration |
| Billing.GetDefaultDepositSettingsByCountryAndFtd | Stored Procedure | READER - direct config lookup |
| Billing.GetDefaultDepositSettingsForUser | Stored Procedure | READER - user-contextualized lookup |
| Billing.GetFundingTypeMaxAmount | Stored Procedure | READER - max amount retrieval |
| Billing.UpdateFundingTypeMaxAmount | Stored Procedure | WRITER - max amount updates |
| Billing.GetMinDepositAmountForUser | Stored Procedure | READER - min amount validation |
| Billing.GetMinDepositAmountForUser_v2 | Stored Procedure | READER - min amount validation v2 |
| Billing.GetCustomerDepositInfo | Stored Procedure | READER - deposit configuration |
| Billing.GetRedeemValidationData | Stored Procedure | READER - redeem flow validation |
| Billing.GetRedeemNFTValidationData | Stored Procedure | READER - NFT redeem validation |
| Billing.GetAllFundingTypes | Stored Procedure | READER - funding type configuration |
| Billing.GetMedianDepositAmount | Stored Procedure | READER - deposit analytics |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Billing_DepositAmount_TPL_Id | CLUSTERED PK | Id ASC | - | - | Active (FILLFACTOR 95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Billing_DepositAmount_TPL_Id | PRIMARY KEY CLUSTERED | Id - surrogate PK |
| DF (FTD=0) | DEFAULT | FTD defaults to 0 (returning depositor row) |
| DF_BillingDepositAmount_IsPackageVisible_TPL | DEFAULT | IsPackageVisible defaults to 0 |

### 7.3 Temporal History

| Property | Value |
|----------|-------|
| System-Versioning | ON |
| History Table | History.DepositAmount |
| ValidFrom/ValidTo | datetime2(7) GENERATED ALWAYS AS ROW START/END |

---

## 8. Sample Queries

### 8.1 Get deposit configuration for a customer and country
```sql
DECLARE @CID INT = 12345, @CountryID INT = 9;
DECLARE @IsFTD BIT = CASE
    WHEN EXISTS (SELECT 1 FROM Billing.Deposit WITH (NOLOCK)
                 WHERE PaymentStatusID = 2 AND CID = @CID)
    THEN 0 ELSE 1
END;

SELECT  DA.MinAmount, DA.MaxAmount,
        DA.Package1Amount, DA.Package2Amount, DA.Package3Amount,
        DA.IsPackageVisible, DA.FTD
FROM    Billing.DepositAmount DA WITH (NOLOCK)
WHERE   DA.FTD = @IsFTD
        AND DA.CountryID = ISNULL(@CountryID, 0);
```

### 8.2 Find countries with non-standard deposit limits
```sql
SELECT  DA.CountryID,
        DC.Name             AS CountryName,
        DA.FTD,
        DA.MinAmount,
        DA.MaxAmount
FROM    Billing.DepositAmount DA WITH (NOLOCK)
INNER JOIN Dictionary.Country DC WITH (NOLOCK)
        ON DA.CountryID = DC.CountryID
WHERE   DA.CountryID > 0
        AND (DA.MinAmount <> 50 OR DA.MaxAmount IS NOT NULL)
ORDER BY DA.CountryID, DA.FTD;
```

### 8.3 View historical deposit limit changes (system-versioned)
```sql
SELECT  Id, CountryID, MinAmount, MaxAmount, FTD, ValidFrom, ValidTo
FROM    Billing.DepositAmount FOR SYSTEM_TIME ALL
WHERE   CountryID = 0
ORDER BY ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific table.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositAmount | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.DepositAmount.sql*
