# Dictionary.ExcludedFundingTypesByCountryAndRegulation

## 1. Business Meaning

### What It Is
A configuration table that defines which payment methods (funding types) are blocked for specific country and regulatory entity combinations.

### Why It Exists
Not all payment methods are available everywhere. Regulatory requirements, payment provider limitations, and risk controls mean that certain funding types must be excluded for customers in specific countries under specific regulations. For example, PayPal may be unavailable under certain regulators, or Giropay (a German-only payment method) may be excluded for non-German countries.

### How It's Used
Queried by the billing/payment system to filter out unavailable funding types when presenting payment options to a customer. The table is read with country and regulation context to determine which funding types to hide from the customer's deposit/withdrawal UI.

---

## 2. Business Logic

### Exclusion Logic
A row in this table means: **"FundingTypeID X is NOT available for customers in CountryID Y under RegulationID Z."**

The absence of a row means the funding type IS available for that country/regulation combination.

### Key Patterns
- **CountryID = 0** entries act as global exclusions for a regulation (applies to ALL countries under that regulator)
- Specific country entries override/supplement global rules
- The `FundingTypeID` maps to `Dictionary.FundingType` (e.g., PayPal, Giropay, Wire Transfer)
- The `RegulationID` maps to `Dictionary.Regulation` (e.g., CySEC, FCA, ASIC)

### Example
- FundingTypeID 11 (Giropay) excluded for CountryID 0, RegulationID 2 → Giropay disabled globally under this regulation
- FundingTypeID 3 (PayPal) excluded for CountryID 0, RegulationID 2 → PayPal disabled globally under this regulation
- FundingTypeID 3 (PayPal) excluded for CountryID 0, RegulationID 9 → PayPal also disabled under a different regulation

---

## 3. Data Overview

915 exclusion rules. Representative sample:

| FundingTypeID | CountryID | RegulationID | Funding Type |
|--------------|----------|-------------|-------------|
| 11 | 0 | 2 | Giropay |
| 3 | 0 | 2 | PayPal |
| 3 | 0 | 9 | PayPal |
| 11 | 1 | 2 | Giropay |
| 3 | 1 | 2 | PayPal |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **FundingTypeID** | `int` | NO | FK to Dictionary.FundingType. The payment method being excluded. | `MCP` |
| **CountryID** | `int` | NO | FK to Dictionary.Country. The country where the exclusion applies. 0 = global (all countries under the regulation). | `MCP` |
| **RegulationID** | `int` | NO | FK to Dictionary.Regulation. The regulatory entity under which the exclusion applies. | `MCP` |

---

## 5. Relationships

### References To (Implicit)
| Table | Column | Relationship |
|-------|--------|-------------|
| Dictionary.FundingType | FundingTypeID | Which payment method is excluded |
| Dictionary.Country | CountryID | Which country (0 = all countries) |
| Dictionary.Regulation | RegulationID | Which regulatory entity |

### Referenced By
None directly — queried by billing services at runtime.

---

## 6. Dependencies

### Depends On
- `Dictionary.FundingType` — payment method definitions
- `Dictionary.Country` — country definitions
- `Dictionary.Regulation` — regulatory entity definitions

### Depended On By
- Billing/payment services (application layer) — filters available payment methods per customer

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | None defined |
| **Indexes** | `CIX_ExcludedFundingTypesByCountryAndRegulation` — clustered on (CountryID, RegulationID) for efficient lookup by country + regulation |
| **Filegroup** | DICTIONARY |
| **Row Count** | 915 |
| **Identity** | No |
| **Temporal** | No |

> **Note**: No primary key — the clustered index on (CountryID, RegulationID) serves as the primary access pattern. Duplicate exclusion entries are theoretically possible but unlikely in practice.

---

## 8. Sample Queries

```sql
-- Get all exclusions for a specific country and regulation
SELECT  e.FundingTypeID,
        f.Name              AS FundingTypeName
FROM    Dictionary.ExcludedFundingTypesByCountryAndRegulation e WITH (NOLOCK)
JOIN    Dictionary.FundingType f WITH (NOLOCK)
        ON e.FundingTypeID = f.FundingTypeID
WHERE   e.CountryID = 105       -- specific country
AND     e.RegulationID = 2;     -- specific regulation

-- Count exclusions per regulation
SELECT  r.Name              AS Regulation,
        COUNT(*)            AS ExclusionCount
FROM    Dictionary.ExcludedFundingTypesByCountryAndRegulation e WITH (NOLOCK)
JOIN    Dictionary.Regulation r WITH (NOLOCK)
        ON e.RegulationID = r.RegulationID
GROUP BY r.Name
ORDER BY ExclusionCount DESC;

-- Find globally excluded funding types (CountryID = 0)
SELECT  DISTINCT f.Name     AS FundingTypeName,
        r.Name              AS Regulation
FROM    Dictionary.ExcludedFundingTypesByCountryAndRegulation e WITH (NOLOCK)
JOIN    Dictionary.FundingType f WITH (NOLOCK)
        ON e.FundingTypeID = f.FundingTypeID
JOIN    Dictionary.Regulation r WITH (NOLOCK)
        ON e.RegulationID = r.RegulationID
WHERE   e.CountryID = 0
ORDER BY f.Name, r.Name;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
