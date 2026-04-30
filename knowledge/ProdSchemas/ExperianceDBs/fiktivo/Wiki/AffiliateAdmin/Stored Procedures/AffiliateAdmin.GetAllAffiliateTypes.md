# AffiliateAdmin.GetAllAffiliateTypes

> Returns a simple list of all active, top-level affiliate types ordered by description for use in dropdown selectors.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns AffiliateTypeID + Description for all active top-level types |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.GetAllAffiliateTypes is a lightweight lookup procedure that returns all active, top-level affiliate types for populating dropdown selectors and filter lists throughout the affiliate admin portal. It provides the simplest possible type listing with no filtering parameters, search capabilities, or affiliate count aggregation.

This procedure exists as the standard dropdown data source for affiliate type selectors. Unlike GetAffiliateTypes (which includes affiliate counts and optional text search), this procedure is optimized for minimal overhead in UI dropdown scenarios where only the type ID and description are needed.

Data flow: The procedure takes no parameters and performs a simple SELECT of AffiliateTypeID and Description from dbo.tblaff_AffiliateTypes, filtered to IsActive = 1 and FatherAffiliateTypeID IS NULL (top-level types only), ordered alphabetically by Description for user-friendly display.

---

## 2. Business Logic

No complex business logic detected. This is a simple filtered SELECT with static WHERE conditions. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | This procedure accepts no input parameters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.tblaff_AffiliateTypes | Read | Reads active top-level type IDs and descriptions |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.GetAllAffiliateTypes (procedure)
+-- dbo.tblaff_AffiliateTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateTypes | Table | SELECT for AffiliateTypeID and Description WHERE IsActive = 1 AND FatherAffiliateTypeID IS NULL |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all active affiliate types for dropdown
```sql
EXEC AffiliateAdmin.GetAllAffiliateTypes;
-- Returns: AffiliateTypeID, Description ordered alphabetically
```

### 8.2 Compare with count-enriched version
```sql
-- Simple dropdown list (this procedure)
EXEC AffiliateAdmin.GetAllAffiliateTypes;

-- Management grid with counts (heavier query)
EXEC AffiliateAdmin.GetAffiliateTypes @TxtSearchWord = NULL;
```

### 8.3 Manually verify active top-level types
```sql
SELECT AffiliateTypeID, Description
FROM dbo.tblaff_AffiliateTypes WITH (NOLOCK)
WHERE IsActive = 1 AND FatherAffiliateTypeID IS NULL
ORDER BY Description;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-4262, PART-3147.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAllAffiliateTypes | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAllAffiliateTypes.sql*
