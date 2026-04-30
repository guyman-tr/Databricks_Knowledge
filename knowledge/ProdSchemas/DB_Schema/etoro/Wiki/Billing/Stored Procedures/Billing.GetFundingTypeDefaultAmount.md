# Billing.GetFundingTypeDefaultAmount

> Returns the full list of default deposit/withdraw amounts per funding type and currency, joining funding type names and currency abbreviations for display purposes.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters - returns all rows) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Different payment methods have different default transaction amounts - a credit card deposit might default to $200 while a wire transfer defaults to $500. These defaults pre-populate the amount field in the deposit/withdrawal UI, improving UX by suggesting a reasonable starting value for the customer.

This procedure returns the complete configuration table of default amounts, enriched with the human-readable names of the funding type (e.g., "Credit Card") and the currency abbreviation (e.g., "USD"). It is typically called by UI or configuration services that need to render these defaults without requiring additional lookup calls.

---

## 2. Business Logic

### 2.1 Full Table Lookup with Display Enrichment

**What**: Returns all rows from FundingTypeDefaultAmount with joined display names for funding type and currency.

**Rules**:
- No filters - returns ALL configured default amounts
- `JOIN Dictionary.FundingType ft ON fd.FundingTypeID = ft.FundingTypeID` - enriches with funding type name
- `JOIN Dictionary.Currency c ON c.CurrencyID = fd.CurrencyID` - enriches with currency abbreviation
- Returns the composite key (FundingTypeID + CurrencyID) along with names for display

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters.

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type. PK of Billing.FundingTypeDefaultAmount. Lookup: Dictionary.FundingType. |
| R2 | FundingTypeName | NVARCHAR | NO | - | CODE-BACKED | Human-readable name of the funding type from Dictionary.FundingType.Name. E.g., 'Credit Card', 'Wire Transfer'. |
| R3 | CurrencyID | INT | NO | - | CODE-BACKED | Currency of the default amount. Part of composite key. Lookup: Dictionary.Currency. |
| R4 | CurrencyAbbreviation | VARCHAR | NO | - | CODE-BACKED | Short currency code from Dictionary.Currency.Abbreviation. E.g., 'USD', 'EUR', 'GBP'. |
| R5 | DefaultAmount | DECIMAL/NUMERIC | NO | - | CODE-BACKED | The default pre-populated amount for this funding type + currency combination. Displayed in the deposit/withdrawal UI amount field. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Billing.FundingTypeDefaultAmount | FROM | Source of default amount configurations |
| FundingTypeID | Dictionary.FundingType | JOIN | Resolves FundingTypeID to display name |
| CurrencyID | Dictionary.Currency | JOIN | Resolves CurrencyID to abbreviation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application deposit/withdrawal UI | (all rows) | EXEC | Loads default amount configuration for all payment types |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingTypeDefaultAmount (procedure)
├── Billing.FundingTypeDefaultAmount (table)
├── Dictionary.FundingType (table)
└── Dictionary.Currency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeDefaultAmount | Table | FROM - primary data source (FundingTypeID, CurrencyID, DefaultAmount) |
| Dictionary.FundingType | Table | JOIN on FundingTypeID - display name |
| Dictionary.Currency | Table | JOIN on CurrencyID - abbreviation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from application configuration/UI services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all default amounts

```sql
EXEC Billing.GetFundingTypeDefaultAmount;
```

### 8.2 Direct equivalent query

```sql
SELECT fd.FundingTypeID,
       ft.Name AS FundingTypeName,
       fd.CurrencyID,
       c.Abbreviation AS CurrencyAbbreviation,
       fd.DefaultAmount
FROM Billing.FundingTypeDefaultAmount fd
JOIN Dictionary.FundingType ft ON fd.FundingTypeID = ft.FundingTypeID
JOIN Dictionary.Currency c ON c.CurrencyID = fd.CurrencyID;
```

### 8.3 Check default amount for a specific funding type and currency

```sql
SELECT fd.DefaultAmount
FROM Billing.FundingTypeDefaultAmount fd WITH (NOLOCK)
WHERE fd.FundingTypeID = 1   -- Credit card
  AND fd.CurrencyID = 1;     -- USD
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingTypeDefaultAmount | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingTypeDefaultAmount.sql*
