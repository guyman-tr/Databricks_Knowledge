# AffiliateAdmin.GetGeneralAffiliateTypeResource

> Returns ISA product types joined with account type names for affiliate type configuration screens.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SubAccountTypeID, SubAccountTypeName, ProductID, ProductName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetGeneralAffiliateTypeResource retrieves the list of ISA (Investment Sub-Account) product types along with their associated account type names. The result combines data from `Dictionary.ISAProduct` and `Dictionary.AccountType` to provide a comprehensive product-to-account-type mapping.

**WHY:** Affiliate types in the platform are configured with specific product and account type associations. When administrators create or edit affiliate types, they need to see the available product options and their corresponding account types. This procedure provides the reference data for those configuration screens, ensuring consistent product-type options across the admin interface.

**HOW:** The procedure performs a JOIN between `Dictionary.ISAProduct` and `Dictionary.AccountType` to return SubAccountTypeID, SubAccountTypeName, ProductID, and ProductName. No filtering or parameterization is applied; all product-type combinations are returned.

---

## 2. Business Logic

### 2.1 Product-Account Type Relationship
The JOIN between `Dictionary.ISAProduct` and `Dictionary.AccountType` resolves the relationship between ISA products and their parent account types. Each ISA product has a SubAccountTypeID that links to a specific account type, and the procedure returns both the product details and the account type name for display purposes.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure accepts no parameters |

**Result Set:** SubAccountTypeID (INT), SubAccountTypeName (NVARCHAR), ProductID (INT), ProductName (NVARCHAR) from Dictionary.ISAProduct + Dictionary.AccountType (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `Dictionary.ISAProduct` | Table | SELECT product details (ProductID, ProductName) |
| `Dictionary.AccountType` | Table | JOIN for account type name resolution (SubAccountTypeID, SubAccountTypeName) |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Affiliate type configuration | Application | Provides product-type options for affiliate type setup |
| Affiliate type edit screen | Application | Populates product assignment controls |

---

## 6. Dependencies

### 6.0 Chain
`GetGeneralAffiliateTypeResource` -> `Dictionary.ISAProduct` + `Dictionary.AccountType`

### 6.1 Depends On
- `Dictionary.ISAProduct` - ISA product definitions
- `Dictionary.AccountType` - Account type definitions

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
-- 1. Get all ISA product types with account type names
EXEC AffiliateAdmin.GetGeneralAffiliateTypeResource;
```

```sql
-- 2. Load product types before configuring an affiliate type
EXEC AffiliateAdmin.GetGeneralAffiliateTypeResource;
-- Use returned ProductID and SubAccountTypeID for type configuration
```

```sql
-- 3. Verify product-type mapping completeness
EXEC AffiliateAdmin.GetGeneralAffiliateTypeResource;
-- Compare with: SELECT COUNT(*) FROM Dictionary.ISAProduct;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-5461.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetGeneralAffiliateTypeResource | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetGeneralAffiliateTypeResource.sql*
