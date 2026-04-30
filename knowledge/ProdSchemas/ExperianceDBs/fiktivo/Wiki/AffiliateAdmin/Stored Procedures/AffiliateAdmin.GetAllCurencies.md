# AffiliateAdmin.GetAllCurencies

> Returns all available currencies ordered by their identifier from the Dictionary.Currency reference table.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | CurrencyID, CurrencyName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetAllCurencies (note: the misspelling of "Currencies" is intentional and preserved in the procedure name) retrieves the complete list of currencies from the Dictionary.Currency reference table, returning each currency's identifier and display name ordered by CurrencyID.

**WHY:** Currency selection is required across multiple affiliate administration workflows, including commission configuration, payment setup, and financial reporting. This procedure provides a standardized lookup for populating currency dropdown menus throughout the admin interface, ensuring consistent currency options across the platform.

**HOW:** The procedure executes a simple SELECT of CurrencyID and CurrencyName from `Dictionary.Currency`, ordered by CurrencyID in ascending order. No filtering or parameterization is applied. See Currency glossary for standard currency reference values.

---

## 2. Business Logic

No complex business logic. This is a direct lookup against the Dictionary.Currency reference table. The ordering by CurrencyID ensures a stable, predictable sort order rather than alphabetical, which is typical for dictionary/reference tables where the ID order is meaningful.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure accepts no parameters |

**Result Set:** CurrencyID (INT), CurrencyName (NVARCHAR) from `Dictionary.Currency` (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `Dictionary.Currency` | Table | SELECT CurrencyID, CurrencyName |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Currency dropdown components | Application | Populates currency selection lists |
| Commission configuration screens | Application | Currency selection for payment settings |

---

## 6. Dependencies

### 6.0 Chain
`GetAllCurencies` -> `Dictionary.Currency`

### 6.1 Depends On
- `Dictionary.Currency` - Reference table for currency definitions. See Currency glossary.

### 6.2 Depend On This
No known database dependencies. Called from application layer for UI population.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Get all currencies for dropdown population
EXEC AffiliateAdmin.GetAllCurencies;
```

```sql
-- 2. Verify currency list completeness
EXEC AffiliateAdmin.GetAllCurencies;
-- Compare with: SELECT COUNT(*) FROM Dictionary.Currency;
```

```sql
-- 3. Use in context of affiliate payment configuration
-- Load available currencies first
EXEC AffiliateAdmin.GetAllCurencies;
-- Then use the CurrencyID in subsequent affiliate payment setup
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-3147.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAllCurencies | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAllCurencies.sql*
