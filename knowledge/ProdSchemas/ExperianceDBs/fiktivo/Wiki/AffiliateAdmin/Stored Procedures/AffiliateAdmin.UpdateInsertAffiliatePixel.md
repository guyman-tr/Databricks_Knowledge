# AffiliateAdmin.UpdateInsertAffiliatePixel

> Upserts a tracking pixel record for an affiliate with field-level audit logging, resolving the section from Dictionary.ChangedSections.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OutputPixelID (inserted or updated PixelID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateInsertAffiliatePixel upserts a tracking pixel record in `tblaff_AffiliatePixels`. When @PixelID=0, a new pixel is created; otherwise the existing pixel is updated. The procedure resolves the 'AffiliatePixel' section from `Dictionary.ChangedSections` and creates field-level audit log entries for all changes.

**WHY:** Tracking pixels are essential for conversion attribution in affiliate marketing. Each pixel represents a code snippet placed on a conversion page that fires when a referred user completes a target action. Administrators need to create, modify, and configure pixels per affiliate, with complete audit trails of all changes for compliance and troubleshooting purposes. The upsert pattern reduces code duplication between create and edit operations.

**HOW:** The procedure checks @PixelID to determine INSERT (=0) or UPDATE (>0) mode. For inserts, it creates a new row in `tblaff_AffiliatePixels` with the provided AffiliateID, PixelTypeID, IsPost flag, and Code. For updates, it retrieves the current values, compares each field, updates the record, and creates individual audit entries for each changed field. The @OutputPixelID OUTPUT parameter returns the pixel ID.

---

## 2. Business Logic

### 2.1 Insert vs. Update Detection
- **@PixelID = 0:** INSERT a new tracking pixel record
- **@PixelID > 0:** UPDATE the existing pixel record

### 2.2 Pixel Configuration Fields
Each pixel record contains:
- **AffiliateID:** The affiliate who owns this pixel
- **PixelTypeID:** The type of tracking pixel (e.g., image, iframe, postback)
- **IsPost:** Whether the pixel fires via HTTP POST (bit flag)
- **Code:** The actual pixel code/URL (nvarchar(max))

### 2.3 Section Resolution
The procedure resolves the 'AffiliatePixel' section from `Dictionary.ChangedSections` for use in audit log entries. See Changed Sections glossary for section ID reference.

### 2.4 Field-Level Audit Logging
On UPDATE, the procedure compares each field's current value to the incoming value. Individual audit entries are created for:
- PixelTypeID changes
- IsPost flag changes
- Code content changes
- AffiliateID changes (if reassignment is supported)

### 2.5 Output Parameter
The @OutputPixelID OUTPUT parameter returns the PixelID to the caller -- either the newly generated identity value (INSERT) or the same input value (UPDATE).

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PixelID | INT | No | 0 | CODE-BACKED | 0 for INSERT, >0 for UPDATE of existing pixel |
| 2 | @AffiliateID | INT | No | - | CODE-BACKED | The affiliate who owns this tracking pixel |
| 3 | @PixelTypeID | INT | No | - | CODE-BACKED | Type of tracking pixel (image, iframe, postback, etc.) |
| 4 | @IsPost | BIT | No | - | CODE-BACKED | Whether the pixel fires via HTTP POST |
| 5 | @Code | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | The pixel code/URL content |
| 6 | @ReasonOfChange | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | Reason for the change (audit context) |
| 7 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Admin user performing the change (for audit) |
| 8 | @OutputPixelID | INT | No | OUTPUT | CODE-BACKED | Returns the PixelID (new or existing) |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_AffiliatePixels` | Table | INSERT or UPDATE pixel record |
| `Dictionary.ChangedSections` | Table | Resolve 'AffiliatePixel' SectionID |
| `dbo.AuditLog` | Table | INSERT field-level audit entries |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Pixel management screen | Application | Create or edit tracking pixels |
| Affiliate configuration | Application | Pixel setup during affiliate onboarding |

---

## 6. Dependencies

### 6.0 Chain
`UpdateInsertAffiliatePixel` -> `Dictionary.ChangedSections` (resolve 'AffiliatePixel') -> check @PixelID -> INSERT or UPDATE `tblaff_AffiliatePixels` -> `AuditLog` (INSERT per changed field)

### 6.1 Depends On
- `dbo.tblaff_AffiliatePixels` - Pixel record storage
- `Dictionary.ChangedSections` - Section name resolution for audit logging. See Changed Sections glossary.
- `dbo.AuditLog` - Audit trail storage

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
-- 1. Create a new tracking pixel for an affiliate
DECLARE @NewPixelID INT;
EXEC AffiliateAdmin.UpdateInsertAffiliatePixel
    @PixelID = 0,
    @AffiliateID = 100,
    @PixelTypeID = 1,
    @IsPost = 0,
    @Code = N'<img src="https://tracking.example.com/pixel?aid=100" />',
    @ReasonOfChange = N'New conversion tracking pixel',
    @UserEmail = N'admin@company.com',
    @OutputPixelID = @NewPixelID OUTPUT;
SELECT @NewPixelID AS CreatedPixelID;
```

```sql
-- 2. Update pixel code content
DECLARE @PID INT = 50;
EXEC AffiliateAdmin.UpdateInsertAffiliatePixel
    @PixelID = @PID,
    @AffiliateID = 100,
    @PixelTypeID = 1,
    @IsPost = 0,
    @Code = N'<img src="https://tracking.example.com/v2/pixel?aid=100" />',
    @ReasonOfChange = N'Updated to v2 tracking endpoint',
    @UserEmail = N'admin@company.com',
    @OutputPixelID = @PID OUTPUT;
```

```sql
-- 3. Change pixel type to postback
DECLARE @PID INT = 50;
EXEC AffiliateAdmin.UpdateInsertAffiliatePixel
    @PixelID = @PID,
    @AffiliateID = 100,
    @PixelTypeID = 3,
    @IsPost = 1,
    @Code = N'https://tracking.example.com/postback?aid=100&event={event}',
    @ReasonOfChange = N'Switched from image pixel to server-side postback',
    @UserEmail = N'manager@company.com',
    @OutputPixelID = @PID OUTPUT;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4266.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateInsertAffiliatePixel | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertAffiliatePixel.sql*
