# AffiliateAdmin.SetAffiliateTypeCategory

> Replaces all category assignments for an affiliate type using a DELETE-then-INSERT pattern within a transaction.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Rows affected in tblaff_AffiliateTypeCategories |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** SetAffiliateTypeCategory replaces the complete set of category assignments for a given affiliate type. It deletes all existing category mappings for the specified AffiliateTypeID from `tblaff_AffiliateTypeCategories` and inserts the new set of category IDs provided via a table-valued parameter. The operation runs within a XACT_ABORT transaction.

**WHY:** Affiliate types are associated with one or more banner categories to control which banners are available to affiliates of that type. When an administrator reconfigures the category assignments, the entire mapping must be replaced atomically -- adding some categories and removing others. The DELETE-then-INSERT pattern ensures a clean replacement without complex differential logic, and the XACT_ABORT transaction guarantees all-or-nothing execution.

**HOW:** The procedure begins a transaction with XACT_ABORT ON, ensuring automatic rollback on any error. It first DELETEs all rows from `tblaff_AffiliateTypeCategories` where AffiliateTypeID matches the input parameter. It then INSERTs new rows for each CategoryID in the @Categories table-valued parameter, paired with the @AffiliateTypeID. The transaction commits upon successful completion of both operations.

---

## 2. Business Logic

### 2.1 Full Replacement Pattern
The procedure uses a DELETE-then-INSERT pattern rather than MERGE or differential update. This means the complete set of categories must be provided each time, even if only one category is being added or removed. This simplifies the logic and avoids edge cases in differential synchronization.

### 2.2 Transaction Safety
The procedure uses SET XACT_ABORT ON to ensure that any error during the DELETE or INSERT automatically rolls back the entire transaction. This prevents partial updates where categories might be deleted but not re-inserted.

### 2.3 No Audit Logging
Unlike many other AffiliateAdmin procedures, SetAffiliateTypeCategory does not perform explicit audit logging. Category assignment changes are tracked implicitly through the calling procedure (typically `UpdateInsertAffiliateType` or `UpdateInsertCategory`, which do perform audit logging).

### 2.4 Empty Categories Support
If @Categories is empty (contains no rows), the procedure effectively removes all category assignments for the affiliate type, leaving it with no associated categories.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateTypeID | INT | No | - | CODE-BACKED | The affiliate type whose category assignments are being replaced |
| 2 | @Categories | dbo.IDTableType READONLY | No | - | CODE-BACKED | Table-valued parameter containing the new set of category IDs to assign |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_AffiliateTypeCategories` | Table | DELETE existing + INSERT new category assignments |
| `dbo.IDTableType` | User-Defined Table Type | Input parameter type for category ID list |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| `AffiliateAdmin.UpdateInsertAffiliateType` | Stored Procedure | Called to set categories after upserting affiliate type |
| `AffiliateAdmin.UpdateInsertCategory` | Stored Procedure | May call to update type-category mappings |
| Affiliate type configuration screen | Application | Save category assignments |

---

## 6. Dependencies

### 6.0 Chain
`SetAffiliateTypeCategory` -> BEGIN TRAN -> `tblaff_AffiliateTypeCategories` (DELETE) -> `tblaff_AffiliateTypeCategories` (INSERT from @Categories) -> COMMIT

### 6.1 Depends On
- `dbo.tblaff_AffiliateTypeCategories` - Target junction table for affiliate type to category mappings
- `dbo.IDTableType` - User-defined table type for category ID list input

### 6.2 Depend On This
Called by `AffiliateAdmin.UpdateInsertAffiliateType` and `AffiliateAdmin.UpdateInsertCategory` as part of their composite save operations.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Replace category assignments for affiliate type 5
DECLARE @Cats dbo.IDTableType;
INSERT INTO @Cats (ID) VALUES (1), (3), (7);
EXEC AffiliateAdmin.SetAffiliateTypeCategory
    @AffiliateTypeID = 5,
    @Categories = @Cats;
```

```sql
-- 2. Remove all categories from affiliate type 10
DECLARE @EmptyCats dbo.IDTableType;
EXEC AffiliateAdmin.SetAffiliateTypeCategory
    @AffiliateTypeID = 10,
    @Categories = @EmptyCats;
```

```sql
-- 3. Verify category assignments after update
DECLARE @Cats dbo.IDTableType;
INSERT INTO @Cats (ID) VALUES (2), (4);
EXEC AffiliateAdmin.SetAffiliateTypeCategory
    @AffiliateTypeID = 8,
    @Categories = @Cats;
-- Verify:
SELECT * FROM dbo.tblaff_AffiliateTypeCategories WHERE AffiliateTypeID = 8;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL references: PART-4262, PART-2448.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.SetAffiliateTypeCategory | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.SetAffiliateTypeCategory.sql*
