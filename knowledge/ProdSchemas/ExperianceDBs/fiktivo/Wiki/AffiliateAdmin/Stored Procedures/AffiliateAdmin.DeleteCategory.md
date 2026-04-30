# AffiliateAdmin.DeleteCategory

> Hard-deletes one or more banner categories that have no assigned banners, returning both deleted and skipped categories with reasons.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns deleted category IDs + skipped categories with blocking banners |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.DeleteCategory removes banner categories from the system. Categories organize marketing banners into groups (e.g., "Crypto Campaigns", "Seasonal Offers") that affiliates browse when selecting creative assets. Categories that still have banners assigned cannot be deleted - the procedure returns them in a second result set with the blocking banner IDs.

This procedure exists because category deletion must be safe: removing a category that has banners would break the banner-to-category relationship. The delete-if-empty pattern prevents orphaned banners while allowing cleanup of unused categories.

Data flow: Admin sends CategoryIDs via `dbo.IDTableType`. The procedure identifies categories with assigned banners via JOIN to dbo.tblaff_Banners, deletes only empty categories from dbo.tblaff_Categories using OUTPUT, creates audit entries (SectionID=5, ActionID=3), and returns two result sets.

---

## 2. Business Logic

### 2.1 Delete-If-Empty Pattern

**What**: Only categories with no assigned banners can be deleted.

**Columns/Parameters Involved**: `@CategoryIDsToDelete`, tblaff_Categories.CategoryID, tblaff_Banners.CategoryID

**Rules**:
- Categories with banners are captured in @NotDeletedCategories (CategoryID, BannerID)
- DELETE uses OUTPUT clause to capture deleted CategoryIDs
- Blocked categories returned with their blocking BannerIDs for UI display

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | nvarchar(250) | NO | - | CODE-BACKED | Email of the admin user. Written to AuditLog.UserEmail. |
| 2 | @CategoryIDsToDelete | dbo.IDTableType | READONLY | - | CODE-BACKED | Table-valued parameter containing CategoryIDs to delete from dbo.tblaff_Categories. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE | dbo.tblaff_Categories | Write | Deletes categories without banners |
| SELECT | dbo.tblaff_Banners | Read | Checks for assigned banners (deletion guard) |
| INSERT INTO | dbo.AuditLog | Write | Logs deletion with SectionID=5, ActionID=3 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.DeleteCategory (procedure)
+-- dbo.tblaff_Categories (table)
+-- dbo.tblaff_Banners (table)
+-- dbo.AuditLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Categories | Table | DELETE target |
| dbo.tblaff_Banners | Table | JOIN to check for assigned banners |
| dbo.AuditLog | Table | INSERT for audit trail |

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

### 8.1 Delete categories
```sql
DECLARE @Cats dbo.IDTableType;
INSERT INTO @Cats (ID) VALUES (5), (6);
EXEC AffiliateAdmin.DeleteCategory @UserEmail = 'admin@company.com', @CategoryIDsToDelete = @Cats;
```

### 8.2 Find empty categories safe to delete
```sql
SELECT c.CategoryID, c.CategoryName
FROM dbo.tblaff_Categories c WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Banners b WITH (NOLOCK) ON b.CategoryID = c.CategoryID
WHERE b.BannerID IS NULL;
```

### 8.3 View category deletion audit
```sql
SELECT ChangedOnDate, UserEmail, ReasonOfChange, ReferencedChangedID
FROM dbo.AuditLog WITH (NOLOCK)
WHERE ChangedSectionID = 5 AND ActionID = 3
ORDER BY ChangedOnDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-4222 (Gil, 23/4/25).

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.DeleteCategory | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.DeleteCategory.sql*
