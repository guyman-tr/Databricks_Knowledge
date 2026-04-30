# Billing.GetDefaultDepositSettingsForUser

> Returns deposit UI configuration (min/max amounts and per-funding-type defaults) for an authenticated customer, auto-detecting their country and first-time-deposit status from the customer record and deposit history.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: (1) MinDepositAmount, (2) (FundingTypeID, CurrencyID, DefaultDepositAmount, MaxDepositAmount) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDefaultDepositSettingsForUser` is the customer-identity-driven variant of `Billing.GetDefaultDepositSettingsByCountryAndFtd`. Given only a CID, it auto-resolves both the country and FTD status, then returns identical deposit UI configuration data: the minimum deposit amount and the per-funding-type default/max amounts to display on the deposit screen.

This is the primary procedure for authenticated deposit page loads where the customer ID is known. `GetDefaultDepositSettingsByCountryAndFtd` is its counterpart for pre-login or non-CID contexts.

FTD detection logic: if ANY approved deposit (PaymentStatusID=2) exists for the CID, the customer is a returning depositor (`@isFTD=0`). If no approved deposit exists, this is the customer's first deposit (`@isFTD=1`). This is the authoritative runtime FTD check used to select the correct minimum deposit configuration.

---

## 2. Business Logic

### 2.1 Auto-Detected Country and FTD Status

**What**: The procedure derives both key lookup dimensions (country and FTD status) from the customer record and deposit history instead of requiring them as input.

**Columns/Parameters Involved**: `@cid`, `Customer.Customer.CountryID`, `Billing.Deposit.PaymentStatusID`, `@countryID`, `@isFTD`

**Rules**:
- `@countryID`: resolved from `Customer.Customer.CountryID WHERE CID=@cid`. Note: uses `Customer.Customer`, not `Customer.CustomerStatic` (see `GetDefaultCurrencyByFundingTypeAndCID` which uses CustomerStatic).
- `@isFTD`: `0` if `EXISTS (SELECT 42 FROM Billing.Deposit WHERE PaymentStatusID=2 AND CID=@cid)`, else `1`. The `SELECT 42` is a performant existence check.
- Once resolved, the deposit amount lookup is identical to `GetDefaultDepositSettingsByCountryAndFtd`.

**Diagram**:
```
@cid
  |
  +---> Customer.Customer: @countryID = CountryID WHERE CID=@cid
  |
  +---> Billing.Deposit: EXISTS(PaymentStatusID=2 AND CID=@cid)?
  |       YES -> @isFTD = 0 (returning depositor)
  |       NO  -> @isFTD = 1 (first-time depositor)
  |
  v
(Same logic as GetDefaultDepositSettingsByCountryAndFtd with @countryID, @isFTD)
  |
  +---> RS1: Billing.DepositAmount WHERE FTD=@isFTD AND CountryID=@countryID
  |           -> MinDepositAmount
  |
  +---> RS2: FundingTypeDefaultAmount JOIN FundingType LEFT JOIN DepositAmount
              -> FundingTypeID, CurrencyID, DefaultDepositAmount, MaxDepositAmount
              (USA CreditCard override: countryID=219 + FundingTypeID=1 -> DefaultDepositAmount=100)
```

### 2.2 USA CreditCard Default Amount Override (PAYUA-1702)

**What**: Hardcoded override sets DefaultDepositAmount=100 for US CreditCard, same as sibling procedure.

**Columns/Parameters Involved**: `@countryID`, `FundingTypeID`, `DefaultDepositAmount`

**Rules**:
- `CASE WHEN @countryID=219 AND ft.FundingTypeID=1 THEN 100 ELSE DefaultAmount END`
- CountryID=219 (USA), FundingTypeID=1 (CreditCard) -> $100 override
- All other country/funding-type combinations use `Billing.FundingTypeDefaultAmount.DefaultAmount`
- Comment marks this as a "temporary quick and dirty solution" per PAYUA-1702

### 2.3 Country-Specific MaxDepositAmount Override

**What**: The maximum deposit amount can be overridden at country level from `Billing.DepositAmount`.

**Columns/Parameters Involved**: `Billing.DepositAmount.MaxAmount`, `Billing.FundingTypeDefaultAmount.MaxDepositAmount`

**Rules**:
- `CAST(ISNULL(da.MaxAmount, MaxDepositAmount) AS INT)`
- If `Billing.DepositAmount` has a row for `@countryID`, its `MaxAmount` overrides the funding-type-level max
- If no country-specific row exists, the funding-type default max applies
- The result is cast to INT regardless of source type

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Used to look up CountryID from Customer.Customer and to check deposit history in Billing.Deposit for FTD determination. |
| 2 | MinDepositAmount (RS1) | MONEY | YES | - | CODE-BACKED | The minimum allowed deposit amount for the customer's country and FTD status. From Billing.DepositAmount.MinAmount. Returns no row if no matching (CountryID, FTD) configuration exists for the customer's country. |
| 3 | FundingTypeID (RS2) | INT | NO | - | CODE-BACKED | Payment method type ID. One row per entry in Billing.FundingTypeDefaultAmount joined to Dictionary.FundingType. |
| 4 | CurrencyID (RS2) | INT | YES | - | CODE-BACKED | Currency for the default amount. From Billing.FundingTypeDefaultAmount.CurrencyID. References Dictionary.Currency. |
| 5 | DefaultDepositAmount (RS2) | INT/MONEY | YES | - | CODE-BACKED | Pre-filled deposit amount shown in the UI. For USA (CountryID=219) CreditCard (FundingTypeID=1): hardcoded 100 (PAYUA-1702). For all others: Billing.FundingTypeDefaultAmount.DefaultAmount. |
| 6 | MaxDepositAmount (RS2) | INT | YES | - | CODE-BACKED | Maximum deposit amount for this funding type and currency. ISNULL(Billing.DepositAmount.MaxAmount, FundingTypeDefaultAmount.MaxDepositAmount) - country max overrides funding-type max when available. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid | Customer.Customer.CID | Lookup | Resolves customer's CountryID |
| @cid | Billing.Deposit.CID | Lookup | Checks for approved deposits to determine FTD status |
| @countryID (derived) | Billing.DepositAmount.CountryID | Lookup | Filters deposit amount limits by country |
| @isFTD (derived) | Billing.DepositAmount.FTD | Lookup | Filters by FTD vs. returning depositor |
| FundingTypeID | Billing.FundingTypeDefaultAmount.FundingTypeID | JOIN | Source of default and max deposit amounts |
| FundingTypeID | Dictionary.FundingType.FundingTypeID | JOIN | Validates funding type |
| @countryID (derived) | Billing.DepositAmount.MaxAmount | Lookup | Country-specific max override |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositSetupUser | GRANT EXECUTE | Permission | Called during authenticated deposit page initialization |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDefaultDepositSettingsForUser (procedure)
├── Customer.Customer (table)
├── Billing.Deposit (table)
├── Billing.DepositAmount (table)
├── Billing.FundingTypeDefaultAmount (table)
└── Dictionary.FundingType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | READ - derives @countryID from CID |
| Billing.Deposit | Table | READ - EXISTS check for PaymentStatusID=2 to determine @isFTD |
| Billing.DepositAmount | Table | READ - RS1 source for MinAmount; RS2 LEFT JOIN for MaxAmount override |
| Billing.FundingTypeDefaultAmount | Table | READ - RS2 source for FundingTypeID, CurrencyID, DefaultAmount, MaxDepositAmount |
| Dictionary.FundingType | Table | READ - RS2 JOIN to retrieve FundingTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositSetupUser (application service) | DB User | Called for authenticated deposit page configuration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Setting | Placed at top - suppresses all row-count messages (unlike sibling SP which places it after RS1) |
| TRY/CATCH with THROW | Error handling | Runtime errors re-thrown to caller |
| PAYUA-1702 hardcode | Business rule | USA (CountryID=219) + CreditCard (FundingTypeID=1) -> DefaultDepositAmount=100 |
| SELECT 42 pattern | Implementation | `EXISTS (SELECT 42 ...)` is a performant way to check for row existence without returning data |

---

## 8. Sample Queries

### 8.1 Get deposit UI settings for an authenticated customer

```sql
EXEC Billing.GetDefaultDepositSettingsForUser @cid = 12345;
```

### 8.2 Check what FTD status will be detected for a customer

```sql
SELECT
    CID,
    CASE WHEN EXISTS (
        SELECT 1 FROM Billing.Deposit WITH (NOLOCK)
        WHERE PaymentStatusID = 2 AND CID = 12345
    ) THEN 0 ELSE 1 END AS isFTD,
    (SELECT CountryID FROM Customer.Customer WITH (NOLOCK) WHERE CID = 12345) AS CountryID;
```

### 8.3 Compare CID-based vs. country-based deposit settings

```sql
-- CID-based (authenticated)
EXEC Billing.GetDefaultDepositSettingsForUser @cid = 12345;

-- Country-based equivalent (pre-login, same result if country/FTD match)
EXEC Billing.GetDefaultDepositSettingsByCountryAndFtd @countryID = 81, @isFtd = 0;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Deposit setup Min amount](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/12049285166) | Confluence | Country-specific minimum deposit configuration - confirms DepositAmount table drives country/FTD minimums |
| [Deposit Info Current Structure and Data](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11701716456) | Confluence | Deposit info structure context; this SP is the primary deposit settings call for authenticated users |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 SQL callers (DepositSetupUser service) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDefaultDepositSettingsForUser | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDefaultDepositSettingsForUser.sql*
