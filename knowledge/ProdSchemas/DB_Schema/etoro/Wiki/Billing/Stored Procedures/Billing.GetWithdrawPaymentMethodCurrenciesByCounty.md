# Billing.GetWithdrawPaymentMethodCurrenciesByCounty

> Returns the available withdrawal payment method types and their supported currencies for a given country, from the Billing.WithdrawPaymentMethods configuration table; used to populate the withdrawal method options shown to a customer.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CountryID; returns one row per payment method available for withdrawal in that country |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetWithdrawPaymentMethodCurrenciesByCounty (note: "County" is a typo in the original name for "Country") returns the set of payment methods and supported currencies available for withdrawal in a specific country. This is a configuration lookup: the billing service calls this procedure to determine which withdrawal options to display to a customer based on their country.

The result drives the withdrawal method selection UI - for example, a customer in country X might be able to withdraw via credit card in USD/EUR, or via wire transfer in GBP, depending on the `Billing.WithdrawPaymentMethods` configuration.

---

## 2. Business Logic

### 2.1 Country-Based Withdrawal Method Lookup

**What**: Filters Billing.WithdrawPaymentMethods to the specified country and returns payment type + currencies.

**Columns/Parameters Involved**: `@CountryID`, `Billing.WithdrawPaymentMethods.CountryID`, `Billing.WithdrawPaymentMethods.FundingTypeID`, `Billing.WithdrawPaymentMethods.Currencies`

**Rules**:
- `WHERE WPM.CountryID = @CountryID` - single country filter
- Returns one row per payment method configured for that country
- `Currencies` column likely contains a comma-separated or structured list of supported currency codes/IDs
- No default fallback if CountryID not found - returns empty result set

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryID | INT | NO | - | CODE-BACKED | Country identifier. Filters Billing.WithdrawPaymentMethods to configurations for this country. |
| - | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type available for withdrawal in this country. Examples: 1=CreditCard, 2=WireTransfer, 3=PayPal. From Billing.WithdrawPaymentMethods.FundingTypeID. |
| - | Currencies | VARCHAR | YES | - | CODE-BACKED | Supported currency list for this payment method in this country. From Billing.WithdrawPaymentMethods.Currencies. Content format defined by the WithdrawPaymentMethods table schema. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID, FundingTypeID, Currencies | Billing.WithdrawPaymentMethods | SELECT | Country-based withdrawal method and currency configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Withdrawal method selection service | @CountryID | EXEC | Populates available withdrawal method options for a customer's country |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetWithdrawPaymentMethodCurrenciesByCounty (procedure)
+-- Billing.WithdrawPaymentMethods (table) [country -> payment method + currencies config]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawPaymentMethods | Table | SELECT filtered by CountryID; returns FundingTypeID and Currencies |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Withdrawal method selection service | External | Withdrawal options display based on customer country |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Name typo | Naming | "County" instead of "Country" in the SP name - cannot be renamed without changing callers |
| No NOLOCK | Concurrency | No WITH (NOLOCK) hint; reads committed data |
| No fallback | Behavior | Returns empty result if CountryID has no entries in WithdrawPaymentMethods |

---

## 8. Sample Queries

### 8.1 Get withdrawal options for a country

```sql
EXEC [Billing].[GetWithdrawPaymentMethodCurrenciesByCounty] @CountryID = 1
-- Returns: FundingTypeID + Currencies for each available withdrawal method in country 1
```

### 8.2 Equivalent direct query

```sql
SELECT FundingTypeID, Currencies
FROM [Billing].[WithdrawPaymentMethods] WITH (NOLOCK)
WHERE CountryID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 8.5/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetWithdrawPaymentMethodCurrenciesByCounty | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetWithdrawPaymentMethodCurrenciesByCounty.sql*
