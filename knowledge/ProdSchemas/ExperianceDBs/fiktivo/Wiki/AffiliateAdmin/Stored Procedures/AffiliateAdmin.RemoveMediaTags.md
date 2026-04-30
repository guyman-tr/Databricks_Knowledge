# AffiliateAdmin.RemoveMediaTags

> Deletes media tags that have no associated banners, returning both successfully deleted tag IDs and blocked tags with their associated banner IDs.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deleted tag IDs + blocked (TagID, BannerID) pairs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** RemoveMediaTags attempts to delete one or more media tag records from `dbo.MediaTag` based on a list of media tag IDs provided via a table-valued parameter. Tags that have associated banners through the `MediaTagBanner` junction table are protected from deletion and reported back with their blocking banner IDs.

**WHY:** Media tags are used to categorize and organize banners for affiliate marketing campaigns. Removing a tag that still has banner associations would break the categorization system and potentially affect banner delivery logic. This delete-if-empty pattern ensures that tag removal is safe and provides administrators with clear feedback about which tags cannot be removed and the specific banners that prevent deletion.

**HOW:** The procedure joins the requested tag IDs against the `MediaTagBanner` junction table to identify tags with existing banner associations. Tags without any banner links are deleted, and their IDs are returned in the first result set. Tags that have associated banners are returned in a second result set as (TagID, BannerID) pairs. Audit log entries are created with SectionID=10 (MediaTags) for each successful deletion.

---

## 2. Business Logic

### 2.1 Banner Association Check
The procedure checks the `MediaTagBanner` junction table to determine which of the requested media tags have associated banners. This many-to-many relationship means a single tag could be linked to multiple banners, all of which would be returned in the blocked result set.

### 2.2 Delete-If-Empty Pattern
Only media tags with zero banner associations in `MediaTagBanner` are eligible for deletion. This mirrors the pattern used in `RemoveBrands` (which checks `tblaff_Banners` instead). The check and delete are atomic within the procedure execution.

### 2.3 Dual Result Set
The procedure returns two result sets:
- **Result Set 1:** Successfully deleted media tag IDs
- **Result Set 2:** Blocked tags, returning (TagID, BannerID) pairs showing which banners prevent deletion

### 2.4 Audit Logging
Each successful tag deletion generates an audit log entry with SectionID=10 (MediaTags). The audit entry records the performing user's email (@UserEmail) and the tag ID being deleted. See Changed Sections glossary for section ID reference.

### 2.5 Referential Integrity
The procedure enforces logical referential integrity at the application level. Rather than relying on CASCADE DELETE or allowing orphaned junction records, it explicitly prevents deletion of tags that are in use.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Email of the admin user performing the deletion (for audit logging) |
| 2 | @MediaTagIDsToDelete | dbo.IDTableType READONLY | No | - | CODE-BACKED | Table-valued parameter containing media tag IDs to attempt deletion |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.MediaTag` | Table | DELETE tags without banner associations |
| `dbo.MediaTagBanner` | Table | JOIN to check for banner associations |
| `dbo.AuditLog` | Table | INSERT audit entries for each successful deletion |
| `dbo.IDTableType` | User-Defined Table Type | Input parameter type for tag ID list |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Media tag management screen | Application | Delete selected media tags |
| Banner tag administration | Application | Cleanup of unused tags |

---

## 6. Dependencies

### 6.0 Chain
`RemoveMediaTags` -> `MediaTagBanner` (check associations) -> `AuditLog` (INSERT) -> `MediaTag` (DELETE eligible)

### 6.1 Depends On
- `dbo.MediaTag` - Target table for media tag deletion
- `dbo.MediaTagBanner` - Checked for existing banner associations to prevent orphaned records
- `dbo.AuditLog` - Audit trail storage (SectionID=10)
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
-- 1. Attempt to delete specific media tags
DECLARE @TagIDs dbo.IDTableType;
INSERT INTO @TagIDs (ID) VALUES (5), (10), (15);
EXEC AffiliateAdmin.RemoveMediaTags
    @UserEmail = N'admin@company.com',
    @MediaTagIDsToDelete = @TagIDs;
-- Returns: Result set 1 = deleted IDs, Result set 2 = blocked (TagID, BannerID) pairs
```

```sql
-- 2. Delete a single media tag
DECLARE @TagIDs dbo.IDTableType;
INSERT INTO @TagIDs (ID) VALUES (42);
EXEC AffiliateAdmin.RemoveMediaTags
    @UserEmail = N'manager@company.com',
    @MediaTagIDsToDelete = @TagIDs;
```

```sql
-- 3. Pre-check which tags have banner associations
SELECT mt.MediaTagID, mt.Name, COUNT(mtb.BannerID) AS BannerCount
FROM dbo.MediaTag mt
LEFT JOIN dbo.MediaTagBanner mtb ON mtb.MediaTagID = mt.MediaTagID
WHERE mt.MediaTagID IN (5, 10, 15)
GROUP BY mt.MediaTagID, mt.Name;
-- Tags with BannerCount = 0 are safe to delete
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4214.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.RemoveMediaTags | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.RemoveMediaTags.sql*
