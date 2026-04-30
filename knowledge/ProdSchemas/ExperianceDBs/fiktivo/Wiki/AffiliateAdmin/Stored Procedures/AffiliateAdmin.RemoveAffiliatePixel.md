# AffiliateAdmin.RemoveAffiliatePixel

> Deletes tracking pixels by their IDs with audit logging for each deletion, resolving the section from Dictionary.ChangedSections.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deleted pixel IDs from tblaff_AffiliatePixels |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** RemoveAffiliatePixel deletes one or more tracking pixel records from `tblaff_AffiliatePixels` based on a list of pixel IDs provided via a table-valued parameter. Before deletion, it resolves the 'AffiliatePixel' section identifier from `Dictionary.ChangedSections` and creates an audit log entry for each deleted pixel.

**WHY:** Tracking pixels are used to monitor affiliate-driven conversions and user behavior. Over time, pixels may become outdated, invalid, or need to be removed for compliance reasons. This procedure provides a safe, audited deletion mechanism that ensures every pixel removal is tracked in the audit log. The per-pixel audit trail supports compliance requirements and enables investigation of pixel configuration changes.

**HOW:** The procedure first resolves the SectionID for 'AffiliatePixel' from `Dictionary.ChangedSections` to use in audit log entries. It then iterates through the pixel IDs in the @PixelIDsToDelete table-valued parameter, creating an audit log entry for each one (recording the deletion action, the performing user @UserEmail, and the pixel details). Finally, it deletes the matching records from `tblaff_AffiliatePixels`. See Changed Sections glossary for section ID reference.

---

## 2. Business Logic

### 2.1 Section Resolution
The procedure looks up the SectionID for 'AffiliatePixel' from `Dictionary.ChangedSections`. This SectionID is used in the audit log entries to categorize the deletion under the correct system section. See Changed Sections glossary.

### 2.2 Per-Pixel Audit Logging
Each pixel deletion is individually audit-logged. The audit entry captures:
- The user who performed the deletion (@UserEmail)
- The pixel ID being deleted
- The section identifier (AffiliatePixel)
- The action type (Delete). See Action glossary: 3=Delete.

### 2.3 Bulk Deletion
The procedure uses the @PixelIDsToDelete table-valued parameter (dbo.IDTableType) to accept multiple pixel IDs for deletion in a single call. The actual DELETE is performed against `tblaff_AffiliatePixels` for all IDs in the input set.

### 2.4 Audit-Then-Delete Sequence
Audit logging occurs before the actual deletion to ensure the audit trail is created even if the deletion encounters an issue. This guarantees a record of the deletion attempt.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Email of the admin user performing the deletion (for audit logging) |
| 2 | @PixelIDsToDelete | dbo.IDTableType READONLY | No | - | CODE-BACKED | Table-valued parameter containing pixel IDs to delete |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_AffiliatePixels` | Table | DELETE pixels by ID |
| `Dictionary.ChangedSections` | Table | Resolve 'AffiliatePixel' SectionID |
| `dbo.AuditLog` | Table | INSERT audit entries for each deletion |
| `dbo.IDTableType` | User-Defined Table Type | Input parameter type for pixel ID list |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Pixel management screen | Application | Delete selected tracking pixels |
| Affiliate pixel configuration | Application | Remove outdated or invalid pixels |

---

## 6. Dependencies

### 6.0 Chain
`RemoveAffiliatePixel` -> `Dictionary.ChangedSections` (lookup) -> `AuditLog` (INSERT) -> `tblaff_AffiliatePixels` (DELETE)

### 6.1 Depends On
- `dbo.tblaff_AffiliatePixels` - Target table for pixel deletion
- `Dictionary.ChangedSections` - Section name resolution for audit logging. See Changed Sections glossary.
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
-- 1. Delete specific tracking pixels
DECLARE @PixelIDs dbo.IDTableType;
INSERT INTO @PixelIDs (ID) VALUES (101), (102), (103);
EXEC AffiliateAdmin.RemoveAffiliatePixel
    @UserEmail = N'admin@company.com',
    @PixelIDsToDelete = @PixelIDs;
```

```sql
-- 2. Delete a single tracking pixel
DECLARE @PixelIDs dbo.IDTableType;
INSERT INTO @PixelIDs (ID) VALUES (250);
EXEC AffiliateAdmin.RemoveAffiliatePixel
    @UserEmail = N'manager@company.com',
    @PixelIDsToDelete = @PixelIDs;
```

```sql
-- 3. Delete pixels and verify removal
DECLARE @PixelIDs dbo.IDTableType;
INSERT INTO @PixelIDs (ID) VALUES (300), (301);
EXEC AffiliateAdmin.RemoveAffiliatePixel
    @UserEmail = N'admin@company.com',
    @PixelIDsToDelete = @PixelIDs;
-- Verify: SELECT * FROM dbo.tblaff_AffiliatePixels WHERE AffiliatePixelID IN (300, 301);
-- Should return no rows
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4266.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.RemoveAffiliatePixel | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.RemoveAffiliatePixel.sql*
