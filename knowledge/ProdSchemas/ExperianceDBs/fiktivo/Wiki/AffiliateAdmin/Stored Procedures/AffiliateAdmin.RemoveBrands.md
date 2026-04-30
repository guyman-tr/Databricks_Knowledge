# AffiliateAdmin.RemoveBrands

> Deletes brands that have no associated banners, returning both successfully deleted brand IDs and blocked brands with their associated banner IDs.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deleted brand IDs + blocked (BrandID, BannerID) pairs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** RemoveBrands attempts to delete one or more brand records from `tblaff_Brands` based on a list of brand IDs provided via a table-valued parameter. Brands that have associated banners in `tblaff_Banners` are protected from deletion and reported back to the caller along with the banner IDs that block them.

**WHY:** Brands serve as organizational groupings for banners in the affiliate marketing system. Deleting a brand that still has active banners would create orphaned banner records and break banner display logic. This delete-if-empty pattern ensures referential integrity at the application level while providing clear feedback about which brands cannot be removed and why. The dual result set design allows the UI to display actionable information to the administrator.

**HOW:** The procedure first identifies which of the requested brands have associated banners by joining `tblaff_Brands` with `tblaff_Banners`. Brands without banners are deleted and their IDs returned in the first result set. Brands that have banners are returned in a second result set as blocked entries, each paired with the BannerID that prevents deletion. Audit log entries (SectionID=7) are created for each successful deletion, recording the user who performed the action.

---

## 2. Business Logic

### 2.1 Banner Association Check
Before attempting any deletion, the procedure joins the requested brand IDs against `tblaff_Banners` to determine which brands have existing banner associations. This is the core guard that prevents orphaned banners.

### 2.2 Delete-If-Empty Pattern
Only brands with zero associated banners are eligible for deletion. This pattern is consistent with other remove procedures in the AffiliateAdmin schema (e.g., RemoveMediaTags). The check and delete operate within the same execution context to prevent race conditions.

### 2.3 Dual Result Set
The procedure returns two result sets:
- **Result Set 1:** Successfully deleted brand IDs
- **Result Set 2:** Blocked brands, returning (BrandID, BannerID) pairs showing which banners prevent deletion

### 2.4 Audit Logging
Each successful brand deletion generates an audit log entry with SectionID=7 (Brands). The audit entry records the performing user's email (@UserEmail) and the brand ID. Audit logging occurs as part of the deletion flow to ensure traceability.

### 2.5 Section ID Reference
SectionID=7 corresponds to the Brands section in `Dictionary.ChangedSections`. See Changed Sections glossary for full section ID reference.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Email of the admin user performing the deletion (for audit logging) |
| 2 | @BrandIDsToDelete | dbo.IDTableType READONLY | No | - | CODE-BACKED | Table-valued parameter containing brand IDs to attempt deletion |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Brands` | Table | DELETE brands without banners |
| `dbo.tblaff_Banners` | Table | JOIN to check for banner associations |
| `dbo.AuditLog` | Table | INSERT audit entries for each successful deletion |
| `dbo.IDTableType` | User-Defined Table Type | Input parameter type for brand ID list |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Brand management screen | Application | Delete selected brands |
| Banner administration | Application | Cleanup of unused brands |

---

## 6. Dependencies

### 6.0 Chain
`RemoveBrands` -> `tblaff_Banners` (check associations) -> `AuditLog` (INSERT) -> `tblaff_Brands` (DELETE eligible)

### 6.1 Depends On
- `dbo.tblaff_Brands` - Target table for brand deletion
- `dbo.tblaff_Banners` - Checked for existing banner associations to prevent orphaned records
- `dbo.AuditLog` - Audit trail storage (SectionID=7)
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
-- 1. Attempt to delete specific brands
DECLARE @BrandIDs dbo.IDTableType;
INSERT INTO @BrandIDs (ID) VALUES (10), (20), (30);
EXEC AffiliateAdmin.RemoveBrands
    @UserEmail = N'admin@company.com',
    @BrandIDsToDelete = @BrandIDs;
-- Returns: Result set 1 = deleted IDs, Result set 2 = blocked (BrandID, BannerID) pairs
```

```sql
-- 2. Delete a single brand
DECLARE @BrandIDs dbo.IDTableType;
INSERT INTO @BrandIDs (ID) VALUES (15);
EXEC AffiliateAdmin.RemoveBrands
    @UserEmail = N'manager@company.com',
    @BrandIDsToDelete = @BrandIDs;
```

```sql
-- 3. Pre-check which brands have banners before attempting deletion
SELECT b.BrandID, COUNT(ban.BannerID) AS BannerCount
FROM dbo.tblaff_Brands b
LEFT JOIN dbo.tblaff_Banners ban ON ban.BrandID = b.BrandID
WHERE b.BrandID IN (10, 20, 30)
GROUP BY b.BrandID;
-- Then call RemoveBrands for brands with BannerCount = 0
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4218.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.RemoveBrands | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.RemoveBrands.sql*
