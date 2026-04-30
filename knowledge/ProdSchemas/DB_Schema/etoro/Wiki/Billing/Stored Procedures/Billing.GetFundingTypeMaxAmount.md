# Billing.GetFundingTypeMaxAmount

> Returns all payment methods (funding types) that have a default currency configured, exposing their maximum deposit amount and the abbreviation of their default processing currency.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full configured set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetFundingTypeMaxAmount` is a configuration-read procedure that returns the deposit ceiling and default currency for each payment method on the eToro platform. The data it exposes drives UI and business logic decisions about which payment methods have enforced limits and what currency those limits apply in.

The procedure exists to provide payment-layer consumers with a simple, joined view of two key fields from `Dictionary.FundingType` - the `MaxDepositAmount` cap and the `DefaultCurrency` currency abbreviation - without requiring those consumers to perform the join themselves.

Data flows exclusively outward: the procedure performs no writes, has no input parameters, and returns a read-only snapshot of the current funding type configuration. It is called with EXECUTE permission granted to `ConfigurationServiceUser`, indicating it feeds a configuration or initialization service that caches this data at application start or refresh.

---

## 2. Business Logic

### 2.1 INNER JOIN Exclusion of Unconfigured Funding Types

**What**: The procedure uses an INNER JOIN between `Dictionary.FundingType` and `Dictionary.Currency`, which silently excludes any funding type where `DefaultCurrency` is NULL.

**Columns/Parameters Involved**: `DefaultCurrency` (FK in Dictionary.FundingType), `CurrencyID` (PK in Dictionary.Currency)

**Rules**:
- Only funding types where `DefaultCurrency IS NOT NULL` appear in the result set
- Funding types with `DefaultCurrency = NULL` (meaning "use the user's account currency") are excluded from this procedure's output
- Consumers of this procedure must not assume ALL active funding types are returned - only those with an explicit default currency are present

**Diagram**:
```
Dictionary.FundingType
  DefaultCurrency = NULL   --> EXCLUDED (e.g., CreditCard - uses account currency)
  DefaultCurrency = 1 (USD) --> INCLUDED (e.g., Wire - fixed USD processing)
  DefaultCurrency = 2 (EUR) --> INCLUDED
          |
          INNER JOIN on CurrencyID
          |
Dictionary.Currency
  CurrencyID / Abbreviation
```

### 2.2 MaxDepositAmount as Risk Cap

**What**: The `MaxDepositAmount` column in `Dictionary.FundingType` sets an upper limit on how much can be deposited in a single transaction via that payment method.

**Columns/Parameters Involved**: `MaxDepositAmount`

**Rules**:
- NULL means no single-transaction limit applies for that method
- When a non-NULL value is returned, downstream services use it to block or flag deposits that exceed the cap
- The cap is currency-agnostic in the DB (stored as an integer amount) - meaning the `DefaultCurrencyAbb` returned alongside it contextualizes which currency unit the cap applies in

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has **no input parameters**. The output result set contains the following columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | CODE-BACKED | Primary key of the payment method from Dictionary.FundingType. Identifies the payment method (e.g., 1=CreditCard, 6=Wire, 7=PayPal). See [Funding Type](../../_glossary.md#funding-type). |
| 2 | FundingTypeName | varchar(50) | NO | - | CODE-BACKED | Display name of the payment method (ft.Name aliased). Values: CreditCard, Wire, PayPal, Skrill, Neteller, Rapid Transfer, ApplePay, GooglePay, etc. Used for UI rendering and logging. |
| 3 | MaxDepositAmount | int | YES | - | CODE-BACKED | Maximum allowed single deposit amount for this payment method. NULL=no limit enforced. Non-NULL values are in the denomination of DefaultCurrencyAbb (e.g., 10000 means 10,000 USD if DefaultCurrencyAbb=USD). Source: Dictionary.FundingType.MaxDepositAmount. |
| 4 | DefaultCurrencyAbb | varchar | NO | - | CODE-BACKED | Abbreviation of the default processing currency for this payment method (c.Abbreviation from Dictionary.Currency). Examples: USD, EUR, GBP. Provides the unit context for MaxDepositAmount. Only funding types with a configured DefaultCurrency appear in this result set (INNER JOIN condition). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM clause) | Dictionary.FundingType | Direct Read | Reads payment method configuration including MaxDepositAmount and DefaultCurrency |
| (JOIN clause) | Dictionary.Currency | Direct Read | Resolves DefaultCurrency (int ID) to Abbreviation string for the result set |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConfigurationServiceUser (permissions) | EXECUTE grant | Permission | Grants execution rights - indicates a configuration service role is the primary consumer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingTypeMaxAmount (procedure)
├── Dictionary.FundingType (table)
└── Dictionary.Currency (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FundingType | Table | FROM clause - provides FundingTypeID, Name, MaxDepositAmount, DefaultCurrency |
| Dictionary.Currency | Table | INNER JOIN on CurrencyID = ft.DefaultCurrency - provides Abbreviation for the default currency |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ConfigurationServiceUser | DB Role/User | EXECUTE permission granted - calls this procedure to read funding type limits |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure to see all configured funding types with limits

```sql
EXEC Billing.GetFundingTypeMaxAmount
```

### 8.2 Equivalent ad-hoc query with explicit context

```sql
SELECT
    ft.FundingTypeID,
    ft.Name AS FundingTypeName,
    ft.MaxDepositAmount,
    c.Abbreviation AS DefaultCurrencyAbb
FROM Dictionary.FundingType ft WITH (NOLOCK)
JOIN Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyID = ft.DefaultCurrency
ORDER BY ft.FundingTypeID
```

### 8.3 Find funding types excluded from this procedure (NULL DefaultCurrency)

```sql
SELECT FundingTypeID, Name, MaxDepositAmount
FROM Dictionary.FundingType WITH (NOLOCK)
WHERE DefaultCurrency IS NULL
  AND IsFundingTypeActive = 1
ORDER BY FundingTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.1/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingTypeMaxAmount | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingTypeMaxAmount.sql*
