# AffiliateAdmin.GetIdentificationType

> Returns all identification types from the Dictionary.IdentificationType reference table for document verification workflows.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | IdentificationTypeID, IdentificationTypeName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetIdentificationType retrieves the complete list of identification document types from `Dictionary.IdentificationType`, returning each type's identifier and display name. These types represent the kinds of identity documents that can be associated with affiliates (e.g., passport, national ID, driver's license).

**WHY:** Affiliate onboarding and compliance processes require identity verification. When administrators manage affiliate identification documents, they need a standardized list of document types to classify uploaded documents. This procedure provides that reference data for dropdown menus in the affiliate identity management interface. See Identification Type glossary for the full list of identification types.

**HOW:** The procedure executes a simple SELECT of IdentificationTypeID and IdentificationTypeName from `Dictionary.IdentificationType`. No filtering, ordering clause, or parameterization is explicitly documented, though the natural order follows IdentificationTypeID.

---

## 2. Business Logic

No complex business logic. This is a direct lookup against the Dictionary.IdentificationType reference table providing standardized identification document type options for the affiliate management interface.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure accepts no parameters |

**Result Set:** IdentificationTypeID (INT), IdentificationTypeName (NVARCHAR) from `Dictionary.IdentificationType` (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `Dictionary.IdentificationType` | Table | SELECT IdentificationTypeID, IdentificationTypeName |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Affiliate identity management | Application | Populates identification type dropdowns |
| Document upload forms | Application | Classifies uploaded identity documents |

---

## 6. Dependencies

### 6.0 Chain
`GetIdentificationType` -> `Dictionary.IdentificationType`

### 6.1 Depends On
- `Dictionary.IdentificationType` - Reference table for identification document types. See Identification Type glossary.

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
-- 1. Get all identification types
EXEC AffiliateAdmin.GetIdentificationType;
```

```sql
-- 2. Load identification types for document upload form
EXEC AffiliateAdmin.GetIdentificationType;
-- Use IdentificationTypeID when saving a new identification document record
```

```sql
-- 3. Verify identification type list
EXEC AffiliateAdmin.GetIdentificationType;
-- Compare with: SELECT COUNT(*) FROM Dictionary.IdentificationType;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-3147.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetIdentificationType | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetIdentificationType.sql*
