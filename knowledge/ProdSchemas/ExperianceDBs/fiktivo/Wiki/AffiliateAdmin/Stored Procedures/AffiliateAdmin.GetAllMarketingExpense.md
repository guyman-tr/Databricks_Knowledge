# AffiliateAdmin.GetAllMarketingExpense

> Returns all marketing expense types ordered alphabetically by name for classification and reporting purposes.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | MarketingExpenseID, MarketingExpenseName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetAllMarketingExpense retrieves the full list of marketing expense categories from the `tblaff_MarketingExpense` table, returning each expense type's identifier and display name sorted alphabetically by name.

**WHY:** Marketing expenses are tracked and categorized within the affiliate program to support cost analysis and ROI reporting. Administrative interfaces need access to the complete list of expense types for dropdown menus when recording or classifying marketing costs associated with affiliate campaigns and partnerships.

**HOW:** The procedure executes a simple SELECT of MarketingExpenseID and MarketingExpenseName from `tblaff_MarketingExpense`, ordered by MarketingExpenseName in ascending alphabetical order. No filtering or parameterization is applied.

---

## 2. Business Logic

No complex business logic. This is a straightforward lookup that returns all marketing expense types in alphabetical order. The alphabetical ordering provides a user-friendly presentation for dropdown selection interfaces.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure accepts no parameters |

**Result Set:** MarketingExpenseID (INT), MarketingExpenseName (NVARCHAR) from `tblaff_MarketingExpense` (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_MarketingExpense` | Table | SELECT MarketingExpenseID, MarketingExpenseName |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Marketing expense dropdowns | Application | Populates expense type selection lists |
| Expense reporting screens | Application | Provides classification options for marketing costs |

---

## 6. Dependencies

### 6.0 Chain
`GetAllMarketingExpense` -> `tblaff_MarketingExpense`

### 6.1 Depends On
- `dbo.tblaff_MarketingExpense` - Source table for marketing expense type definitions

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
-- 1. Get all marketing expense types for dropdown
EXEC AffiliateAdmin.GetAllMarketingExpense;
```

```sql
-- 2. Verify marketing expense type count
EXEC AffiliateAdmin.GetAllMarketingExpense;
-- Compare with: SELECT COUNT(*) FROM dbo.tblaff_MarketingExpense;
```

```sql
-- 3. Use in context of recording a new marketing expense
-- Step 1: Load expense types
EXEC AffiliateAdmin.GetAllMarketingExpense;
-- Step 2: Use selected MarketingExpenseID for expense record creation
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-3147.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAllMarketingExpense | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAllMarketingExpense.sql*
