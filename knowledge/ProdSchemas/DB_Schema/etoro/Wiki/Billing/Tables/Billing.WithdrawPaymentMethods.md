# Billing.WithdrawPaymentMethods

> Country-to-payment-method eligibility matrix that defines which withdrawal payment methods are available in each country and the accepted currencies for each combination.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (CountryID, FundingTypeID) - composite natural key (no explicit PK constraint) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on CountryID) |

---

## 1. Business Meaning

Billing.WithdrawPaymentMethods is a routing eligibility table that controls which e-wallet withdrawal methods a customer can use based on their country of registration. Each row represents one allowed combination of country + payment method, along with the comma-separated list of currency IDs the customer may use for that withdrawal channel.

This table exists to enforce regulatory and commercial restrictions on withdrawal payment methods by geography. Not all payment providers (PayPal, Skrill/MoneyBookers) operate in every country, and the currency options differ by country (e.g., Czech customers can withdraw in CZK while Swiss customers use CHF). Without this table, withdrawal routing could offer methods unavailable in a customer's jurisdiction.

Application services call `Billing.GetWithdrawPaymentMethodCurrenciesByCounty` (note: procedure name has a typo - "County") to retrieve the available withdrawal methods and their eligible currencies for a given customer's CountryID. This is used when building the withdrawal options presented to the customer.

---

## 2. Business Logic

### 2.1 Country-Specific Payment Method Availability

**What**: Controls which e-wallet payment processors are available for withdrawals by country.

**Columns/Parameters Involved**: `CountryID`, `FundingTypeID`

**Rules**:
- Only PayPal (FundingTypeID=3) and MoneyBookers/Skrill (FundingTypeID=8) appear in this table - other payment methods are routed differently.
- A country may support both methods (Czech Republic, Denmark, Hungary, Norway, Poland, Sweden, Switzerland) or only one (Romania: MoneyBookers only).
- Countries not present in this table have no e-wallet withdrawal options via these two methods.

**Diagram**:
```
Czech Republic (55)  -> PayPal (3): CZK, USD, EUR, GBP, AUD
                     -> MoneyBookers (8): CZK, USD, EUR, GBP, AUD

Denmark (57)         -> PayPal (3): DKK, USD, EUR, GBP, AUD
                     -> MoneyBookers (8): DKK, USD, EUR, GBP, AUD

Romania (168)        -> MoneyBookers (8) ONLY: RON, USD, EUR, GBP, AUD
                        (PayPal not available in Romania)
```

### 2.2 Currency List Structure

**What**: The Currencies column encodes a comma-separated list of CurrencyIDs, with the local currency always listed first.

**Columns/Parameters Involved**: `CountryID`, `Currencies`

**Rules**:
- The pattern is always: `{local_currency_id},{1},{2},{3},{5}` - local currency + USD + EUR + GBP + AUD.
- The local (native) currency ID appears first, making it the default/preferred selection.
- The trailing four currencies (1=USD, 2=EUR, 3=GBP, 5=AUD) are standard across all countries.
- Country-to-local-currency mapping: CZ->82(CZK), DK->46(DKK), HU->45(HUF), NO->39(NOK), PL->44(PLN), RO->83(RON), SE->40(SEK), CH->6(CHF).

---

## 3. Data Overview

| CountryID | FundingTypeID | Currencies | Meaning |
|-----------|--------------|------------|---------|
| 55 (Czech Republic) | 3 (PayPal) | 82,1,2,3,5 | Czech customers can withdraw via PayPal in CZK (local), USD, EUR, GBP, or AUD. CZK is offered first as the preferred option. |
| 57 (Denmark) | 8 (MoneyBookers) | 46,1,2,3,5 | Danish customers can use Skrill/MoneyBookers for withdrawal, with DKK as the primary currency alongside major forex options. |
| 168 (Romania) | 8 (MoneyBookers) | 83,1,2,3,5 | Romania supports only MoneyBookers withdrawals (PayPal is not available). Currencies include RON (83) as local plus USD, EUR, GBP, AUD. |
| 197 (Switzerland) | 3 (PayPal) | 6,1,2,3,5 | Swiss customers can withdraw via PayPal with CHF as the local currency option in addition to USD, EUR, GBP, AUD. |
| 197 (Switzerland) | 8 (MoneyBookers) | 6,1,2,3,5 | Switzerland supports both withdrawal methods - same currency set for MoneyBookers, CHF listed first. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Country of the customer's registration. Implicit FK to Dictionary.Country (CountryID). The clustered index on this column enables fast lookups by country when the application checks withdrawal eligibility for a specific customer. Known values: 55=Czech Republic, 57=Denmark, 94=Hungary, 154=Norway, 164=Poland, 168=Romania, 196=Sweden, 197=Switzerland. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method identifier for the withdrawal channel. Implicit FK to Dictionary.FundingType (FundingTypeID). Only two values present: 3=PayPal, 8=MoneyBookers (Skrill). Not all countries have both methods - Romania has MoneyBookers only. |
| 3 | Currencies | varchar(100) | NO | - | CODE-BACKED | Comma-separated list of CurrencyIDs representing the currencies accepted for this country/payment-method combination. Pattern: local currency first, then USD(1), EUR(2), GBP(3), AUD(5). Parsed by application code to build the currency selection list during withdrawal. Example: "82,1,2,3,5" = CZK, USD, EUR, GBP, AUD for Czech Republic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit | Identifies the country for which the payment method restriction applies. |
| FundingTypeID | Dictionary.FundingType | Implicit | Identifies the withdrawal payment method (PayPal or MoneyBookers/Skrill). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetWithdrawPaymentMethodCurrenciesByCounty | @CountryID | JOIN | Reads this table to return available withdrawal methods and their currencies for a given country. Called during customer withdrawal flow. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (table with no computed columns or FK constraints).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetWithdrawPaymentMethodCurrenciesByCounty | Stored Procedure | Reader - SELECTs FundingTypeID and Currencies filtered by CountryID to return available withdrawal options. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_WithdrawPaymentMethods_Clustered | CLUSTERED | CountryID ASC | - | - | Active |

Note: No PRIMARY KEY constraint is defined. The logical composite key is (CountryID, FundingTypeID) but is not enforced by a constraint.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | No CHECK, DEFAULT, or UNIQUE constraints. No PK defined. Row uniqueness is maintained by application logic only. |

---

## 8. Sample Queries

### 8.1 Get all withdrawal options for a specific country

```sql
SELECT
    wpm.CountryID,
    wpm.FundingTypeID,
    ft.Name AS PaymentMethod,
    wpm.Currencies
FROM Billing.WithdrawPaymentMethods wpm WITH (NOLOCK)
JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = wpm.FundingTypeID
WHERE wpm.CountryID = 55; -- Czech Republic
```

### 8.2 Find countries supporting a specific payment method

```sql
SELECT
    wpm.CountryID,
    c.Name AS CountryName,
    wpm.Currencies
FROM Billing.WithdrawPaymentMethods wpm WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON c.CountryID = wpm.CountryID
WHERE wpm.FundingTypeID = 8 -- MoneyBookers/Skrill
ORDER BY c.Name;
```

### 8.3 Full matrix with resolved country and payment method names

```sql
SELECT
    c.Name AS Country,
    ft.Name AS PaymentMethod,
    wpm.Currencies
FROM Billing.WithdrawPaymentMethods wpm WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON c.CountryID = wpm.CountryID
JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = wpm.FundingTypeID
ORDER BY c.Name, ft.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawPaymentMethods | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.WithdrawPaymentMethods.sql*
