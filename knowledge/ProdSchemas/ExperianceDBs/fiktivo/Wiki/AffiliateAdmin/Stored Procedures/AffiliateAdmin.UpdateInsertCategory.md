# AffiliateAdmin.UpdateInsertCategory

> Upserts a banner category with affiliate type associations using MERGE, with audit logging for both name changes and type association changes.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OutputCategoryID (inserted or updated CategoryID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateInsertCategory upserts a banner category record in `tblaff_Categories` and manages its affiliate type associations through `tblaff_AffiliateTypeCategories` using a MERGE pattern. The procedure handles the category name, the set of affiliate types that can access banners in this category, and creates audit log entries for both name changes and type association changes.

**WHY:** Banner categories organize the creative asset library into logical groups (e.g., "Display Ads", "Email Templates", "Landing Pages"). Each category is associated with specific affiliate types, controlling which affiliates can see and use banners in that category. This access control mechanism ensures that affiliates only see creative assets appropriate for their commission plan and partnership tier. The combined category + type association upsert ensures atomic configuration changes.

**HOW:** The procedure checks @CategoryID to determine INSERT (=0) or UPDATE (>0) mode. For the category record, it performs the appropriate INSERT or UPDATE on `tblaff_Categories`. It then uses a MERGE statement on `tblaff_AffiliateTypeCategories` to synchronize the affiliate type associations: new types are added, removed types are deleted. Audit entries are created for the category name change and for type association changes (capturing old vs. new type lists).

---

## 2. Business Logic

### 2.1 Insert vs. Update Detection
- **@CategoryID = 0:** INSERT a new category record
- **@CategoryID > 0:** UPDATE the existing category record

### 2.2 Category Name Management
The category record primarily contains the CategoryName. On UPDATE, the procedure compares the current name to the new value and logs the change if different.

### 2.3 Affiliate Type Association via MERGE
The @AffiliateTypeIDs TVP contains the set of affiliate types that should have access to this category. The MERGE on `tblaff_AffiliateTypeCategories`:
- **WHEN NOT MATCHED BY TARGET:** INSERT new type-category associations
- **WHEN NOT MATCHED BY SOURCE:** DELETE removed associations
- **WHEN MATCHED:** No action needed

### 2.4 Dual Audit Logging
Two types of changes are independently audit-logged:
1. **Name changes:** When CategoryName is modified
2. **Type association changes:** When the set of associated affiliate types changes

### 2.5 Output Parameter
@OutputCategoryID returns the CategoryID to the caller, either newly generated (INSERT) or confirmed (UPDATE).

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Admin user performing the change (for audit) |
| 2 | @ReasonOfChange | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | Reason for the change (audit context) |
| 3 | @CategoryID | INT | No | 0 | CODE-BACKED | 0 for INSERT, >0 for UPDATE |
| 4 | @CategoryName | NVARCHAR(500) | No | - | CODE-BACKED | Display name for the category |
| 5 | @AffiliateTypeIDs | dbo.IDTableType READONLY | No | - | CODE-BACKED | TVP containing affiliate type IDs to associate with this category |
| 6 | @OutputCategoryID | INT | No | OUTPUT | CODE-BACKED | Returns the CategoryID (new or existing) |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Categories` | Table | INSERT or UPDATE category record |
| `dbo.tblaff_AffiliateTypeCategories` | Table | MERGE type associations |
| `dbo.AuditLog` | Table | INSERT audit entries for name and type changes |
| `dbo.IDTableType` | User-Defined Table Type | Input type for affiliate type ID list |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Category management screen | Application | Create or edit banner categories |
| Banner configuration | Application | Category setup during banner organization |

---

## 6. Dependencies

### 6.0 Chain
`UpdateInsertCategory` -> check @CategoryID -> INSERT or UPDATE `tblaff_Categories` -> MERGE `tblaff_AffiliateTypeCategories` -> `AuditLog` (INSERT for name + type changes)

### 6.1 Depends On
- `dbo.tblaff_Categories` - Category record storage
- `dbo.tblaff_AffiliateTypeCategories` - Category-to-type junction table
- `dbo.AuditLog` - Audit trail storage
- `dbo.IDTableType` - User-defined table type for ID list input

### 6.2 Depend On This
No known database dependencies. Called from application layer.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Create a new category associated with specific affiliate types
DECLARE @Types dbo.IDTableType;
INSERT INTO @Types (ID) VALUES (1), (3), (5);
DECLARE @NewCatID INT;
EXEC AffiliateAdmin.UpdateInsertCategory
    @UserEmail = N'admin@company.com',
    @ReasonOfChange = N'New category for email templates',
    @CategoryID = 0,
    @CategoryName = N'Email Templates',
    @AffiliateTypeIDs = @Types,
    @OutputCategoryID = @NewCatID OUTPUT;
SELECT @NewCatID AS CreatedCategoryID;
```

```sql
-- 2. Update category name and expand type access
DECLARE @Types dbo.IDTableType;
INSERT INTO @Types (ID) VALUES (1), (2), (3), (4), (5);
DECLARE @CatID INT = 10;
EXEC AffiliateAdmin.UpdateInsertCategory
    @UserEmail = N'admin@company.com',
    @ReasonOfChange = N'Renamed and opened to all types',
    @CategoryID = @CatID,
    @CategoryName = N'Email & Newsletter Templates',
    @AffiliateTypeIDs = @Types,
    @OutputCategoryID = @CatID OUTPUT;
```

```sql
-- 3. Create a category with no type associations (admin-only)
DECLARE @EmptyTypes dbo.IDTableType;
DECLARE @NewID INT;
EXEC AffiliateAdmin.UpdateInsertCategory
    @UserEmail = N'admin@company.com',
    @ReasonOfChange = N'Draft category for upcoming campaign',
    @CategoryID = 0,
    @CategoryName = N'Q4 Campaign (Draft)',
    @AffiliateTypeIDs = @EmptyTypes,
    @OutputCategoryID = @NewID OUTPUT;
SELECT @NewID AS CategoryID;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4222.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateInsertCategory | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertCategory.sql*
