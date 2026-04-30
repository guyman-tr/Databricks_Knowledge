# Billing.GetDefaultDepositSettingsByCountryAndFtd

> Returns the minimum deposit amount and per-funding-type default/max amounts for a given country and first-time-deposit flag, used to configure the deposit UI without requiring a customer ID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: (1) MinDepositAmount, (2) (FundingTypeID, CurrencyID, DefaultDepositAmount, MaxDepositAmount) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDefaultDepositSettingsByCountryAndFtd` retrieves deposit UI configuration by country and FTD status instead of by customer ID. This distinguishes it from `Billing.GetDefaultDepositSettingsForUser`, which derives both the country and FTD status from a CID at runtime. This country+FTD variant is used when the customer identity is not yet available (e.g., pre-login deposit page rendering, marketing landing pages, A/B test scenarios).

Without this procedure, the deposit setup for non-authenticated or pre-login flows would require a customer ID lookup. By accepting country and FTD status directly, the caller can drive the deposit page configuration for any hypothetical country/FTD combination.

The procedure is called by the `DepositSetupUser` service account, indicating it is part of the deposit page initialization flow. It contains a hardcoded USA CreditCard override (PAYUA-1702) that sets the `DefaultDepositAmount` to $100 for US customers using credit cards, overriding the standard ~$1,000 default amounts from `Billing.FundingTypeDefaultAmount`.

---

## 2. Business Logic

### 2.1 Two-Result-Set Structure: Min vs. Per-Method Defaults

**What**: The procedure returns two independent result sets addressing different parts of the deposit UI configuration.

**Columns/Parameters Involved**: `@countryID`, `@isFtd`, `Billing.DepositAmount.MinAmount`, `Billing.DepositAmount.MaxAmount`, `Billing.FundingTypeDefaultAmount.DefaultAmount`, `Billing.FundingTypeDefaultAmount.MaxDepositAmount`

**Rules**:
- **Result Set 1**: One row with `MinDepositAmount` - the country- and FTD-specific minimum deposit amount from `Billing.DepositAmount`. Returns no row if the country is not in `Billing.DepositAmount` (no global fallback - compare with commented-out WHERE that did support CountryID=0 fallback).
- **Result Set 2**: One row per funding-type/currency combination from `Billing.FundingTypeDefaultAmount`, with the country-specific MaxAmount overlaid from `Billing.DepositAmount` if present.
- The `MaxDepositAmount` in RS2 uses `ISNULL(da.MaxAmount, MaxDepositAmount)` - the country-specific max overrides the funding-type max if available.

### 2.2 USA CreditCard Override (PAYUA-1702)

**What**: A hardcoded exception sets the default deposit amount to $100 for US customers using CreditCard, overriding the standard default amount from `Billing.FundingTypeDefaultAmount`.

**Columns/Parameters Involved**: `@countryID`, `Dictionary.FundingType.FundingTypeID`, `DefaultAmount`

**Rules**:
- `CASE WHEN @countryID=219 AND ft.FundingTypeID=1 THEN 100 ELSE DefaultAmount END`
- CountryID 219 = USA; FundingTypeID 1 = CreditCard
- Standard DefaultAmount from `Billing.FundingTypeDefaultAmount` for USD CreditCard is ~$1,000
- USA regulatory/risk requirements called for a lower default ($100) per PAYUA-1702
- Comment notes this is a "temporary quick and dirty solution" - a proper country dimension in `Billing.FundingTypeDefaultAmount` was proposed but not implemented

**Diagram**:
```
@countryID + @isFtd
  |
  +---> RS1: Billing.DepositAmount WHERE FTD=@isFtd AND CountryID=@countryID
  |           -> MinDepositAmount
  |
  +---> RS2: Billing.FundingTypeDefaultAmount
              JOIN Dictionary.FundingType ON FundingTypeID
              LEFT JOIN Billing.DepositAmount ON CountryID=@countryID
              |
              +-- DefaultDepositAmount:
              |     IF countryID=219 AND FundingTypeID=1 -> 100 (USA CreditCard hardcode)
              |     ELSE -> DefaultAmount from FundingTypeDefaultAmount
              |
              +-- MaxDepositAmount:
                    ISNULL(DepositAmount.MaxAmount, FundingTypeDefaultAmount.MaxDepositAmount)
                    -> country-specific max overrides funding-type max when available
```

### 2.3 FTD vs. Returning Depositor Minimum

**What**: The `@isFtd` flag selects different minimum amount rows from `Billing.DepositAmount`, reflecting different risk thresholds for first-time vs. returning depositors.

**Columns/Parameters Involved**: `@isFtd`, `Billing.DepositAmount.FTD`, `Billing.DepositAmount.MinAmount`

**Rules**:
- `@isFtd = 1`: Rows where `Billing.DepositAmount.FTD = 1` - first-time deposit minimums (often lower, to reduce FTD friction)
- `@isFtd = 0`: Rows where `Billing.DepositAmount.FTD = 0` - returning depositor minimums
- Both first and second result sets respect the same `@countryID` filter; only RS1 uses `@isFtd`

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @countryID | INT | NO | - | CODE-BACKED | Country ID to look up deposit configuration. Maps to `Dictionary.Country.CountryID`. Used to filter both result sets. If no matching row in `Billing.DepositAmount`, RS1 returns empty. CountryID=219 triggers USA CreditCard $100 override (PAYUA-1702). |
| 2 | @isFtd | BIT | NO | - | CODE-BACKED | First-time deposit flag: 1 = customer is making their first deposit (FTD), 0 = returning depositor. Filters RS1 (Billing.DepositAmount.FTD). RS2 is not filtered by this parameter. |
| 3 | MinDepositAmount (RS1) | MONEY | YES | - | CODE-BACKED | The minimum allowed deposit amount for the country and FTD combination. Sourced from `Billing.DepositAmount.MinAmount`. Returns no row if no matching (CountryID, FTD) configuration exists. |
| 4 | FundingTypeID (RS2) | INT | NO | - | CODE-BACKED | Payment method type ID from `Dictionary.FundingType`. Identifies the funding type for which DefaultDepositAmount and MaxDepositAmount apply (e.g., 1=CreditCard, 2=WireTransfer). |
| 5 | CurrencyID (RS2) | INT | YES | - | CODE-BACKED | Currency for this funding-type default amount. From `Billing.FundingTypeDefaultAmount.CurrencyID`. References `Dictionary.Currency`. |
| 6 | DefaultDepositAmount (RS2) | INT/MONEY | YES | - | CODE-BACKED | The pre-filled default deposit amount shown to users in the deposit UI for this funding type. For USA+CreditCard (countryID=219, FundingTypeID=1): hardcoded 100. For all others: `Billing.FundingTypeDefaultAmount.DefaultAmount` (~$1,000 USD equivalent per currency). |
| 7 | MaxDepositAmount (RS2) | INT | YES | - | CODE-BACKED | Maximum deposit amount for this funding type. `ISNULL(Billing.DepositAmount.MaxAmount, Billing.FundingTypeDefaultAmount.MaxDepositAmount)` - country-specific max overrides funding-type max when a matching `Billing.DepositAmount` row is found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @countryID | Billing.DepositAmount.CountryID | Lookup | Filters deposit amount limits by country |
| @isFtd | Billing.DepositAmount.FTD | Lookup | Filters by first-time vs. returning depositor |
| FundingTypeID | Billing.FundingTypeDefaultAmount.FundingTypeID | JOIN | Source of default and max deposit amounts |
| FundingTypeID | Dictionary.FundingType.FundingTypeID | JOIN | Validates funding type exists and retrieves FundingTypeID |
| @countryID | Billing.DepositAmount.MaxAmount | Lookup | Country-specific max override for RS2 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositSetupUser | GRANT EXECUTE | Permission | Called by the deposit setup service during deposit page initialization for non-authenticated flows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDefaultDepositSettingsByCountryAndFtd (procedure)
├── Billing.DepositAmount (table)
├── Billing.FundingTypeDefaultAmount (table)
└── Dictionary.FundingType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositAmount | Table | RS1: provides MinAmount for country+FTD. RS2: LEFT JOIN to provide country-specific MaxAmount override. |
| Billing.FundingTypeDefaultAmount | Table | RS2: primary source for FundingTypeID, CurrencyID, DefaultAmount, MaxDepositAmount |
| Dictionary.FundingType | Table | RS2: JOIN to retrieve FundingTypeID for the result set (ensures valid funding type context) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositSetupUser (application service) | DB User | Calls this SP to configure deposit page for pre-login or non-CID contexts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Setting | Applied after RS1; RS1 SELECT (before SET NOCOUNT ON) will emit row-count messages to the caller. This is a minor code issue - SET NOCOUNT ON should be placed before the first SELECT. |
| PAYUA-1702 hardcode | Business rule | USA (CountryID=219) CreditCard (FundingTypeID=1) DefaultDepositAmount = 100; a temporary override pending proper country dimension in FundingTypeDefaultAmount |
| No CountryID=0 fallback | Design | RS1 WHERE clause filters `CountryID = @countryID` directly (no OR CountryID=0 fallback). A commented-out version existed with the fallback. The current form returns no row for unrecognized countries. |

---

## 8. Sample Queries

### 8.1 Get deposit settings for a UK FTD customer

```sql
EXEC Billing.GetDefaultDepositSettingsByCountryAndFtd @countryID = 81, @isFtd = 1;
-- Returns: RS1 = UK FTD minimum deposit; RS2 = default/max amounts per funding type
```

### 8.2 Get deposit settings for a US returning depositor (see hardcoded CreditCard override)

```sql
EXEC Billing.GetDefaultDepositSettingsByCountryAndFtd @countryID = 219, @isFtd = 0;
-- RS2 will show DefaultDepositAmount = 100 for FundingTypeID=1 (CreditCard), PAYUA-1702 override
```

### 8.3 Inline check of what the procedure will return for a given country

```sql
-- RS1: Min deposit amounts by country and FTD status
SELECT CountryID, FTD, MinAmount, MaxAmount
FROM Billing.DepositAmount WITH (NOLOCK)
WHERE CountryID = 81  -- UK
ORDER BY FTD;

-- RS2: Per-funding-type defaults
SELECT ftda.FundingTypeID, ftda.CurrencyID, ftda.DefaultAmount, ftda.MaxDepositAmount
FROM Billing.FundingTypeDefaultAmount ftda WITH (NOLOCK)
INNER JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ftda.FundingTypeID = ft.FundingTypeID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Deposit setup Min amount](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/12049285166) | Confluence | Documents country-specific minimum deposit configuration - confirms DepositAmount table drives country/FTD minimums |
| [Deposit Info Current Structure and Data](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11701716456) | Confluence | Describes deposit info structure; context for this SP's role in deposit page configuration |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.1/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 SQL callers (DepositSetupUser service) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDefaultDepositSettingsByCountryAndFtd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDefaultDepositSettingsByCountryAndFtd.sql*
