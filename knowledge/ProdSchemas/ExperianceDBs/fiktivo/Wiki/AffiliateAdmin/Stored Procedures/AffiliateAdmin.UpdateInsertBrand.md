# AffiliateAdmin.UpdateInsertBrand

> Upserts a brand record in tblaff_Brands with audit logging using SectionID=7, returning the brand ID via output parameter.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OutputBrandID (inserted or updated BrandID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateInsertBrand upserts a brand record in `tblaff_Brands`. When @BrandID=0, a new brand is created; otherwise the existing brand is updated. The procedure performs audit logging with SectionID=7 (Brands) and returns the brand ID through the @OutputBrandID OUTPUT parameter.

**WHY:** Brands organize banners and marketing materials into logical product/brand groups within the affiliate system. Each banner is associated with a brand, enabling affiliates to find and use creative assets for specific product lines. The upsert pattern provides a single entry point for brand creation and modification, with audit logging ensuring all brand changes are tracked for administrative review.

**HOW:** The procedure checks @BrandID to determine the operation mode. For inserts (@BrandID=0), it creates a new row in `tblaff_Brands` with the provided @BrandName and logs the creation. For updates, it compares the current BrandName to the new value, updates the record if changed, and creates an audit log entry with the old and new values. SectionID=7 is used directly (not resolved from Dictionary.ChangedSections) for the audit entries.

---

## 2. Business Logic

### 2.1 Insert vs. Update Detection
- **@BrandID = 0:** INSERT a new brand record
- **@BrandID > 0:** UPDATE the existing brand record

### 2.2 Brand Name Management
The brand record contains a single data field: BrandName (varchar(150)). This is the primary attribute managed by this procedure.

### 2.3 Audit Logging
Both INSERT and UPDATE operations generate audit log entries:
- **INSERT:** Logs the creation of a new brand with SectionID=7
- **UPDATE:** Logs the name change (old value -> new value) with SectionID=7

### 2.4 Output Parameter
@OutputBrandID returns the BrandID to the caller. For inserts, this is the newly generated identity value; for updates, it confirms the updated brand's ID.

### 2.5 Section ID
SectionID=7 corresponds to Brands in the audit log section classification. This is used directly rather than being resolved from `Dictionary.ChangedSections`.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Admin user performing the change (for audit) |
| 2 | @ReasonOfChange | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | Reason for the change (audit context) |
| 3 | @BrandID | INT | No | 0 | CODE-BACKED | 0 for INSERT, >0 for UPDATE |
| 4 | @BrandName | VARCHAR(150) | No | - | CODE-BACKED | Brand display name |
| 5 | @OutputBrandID | INT | No | OUTPUT | CODE-BACKED | Returns the BrandID (new or existing) |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Brands` | Table | INSERT or UPDATE brand record |
| `dbo.AuditLog` | Table | INSERT audit entries (SectionID=7) |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Brand management screen | Application | Create or edit brands |
| Banner configuration | Application | Create brands for new product lines |

---

## 6. Dependencies

### 6.0 Chain
`UpdateInsertBrand` -> check @BrandID -> INSERT or UPDATE `tblaff_Brands` -> `AuditLog` (INSERT with SectionID=7)

### 6.1 Depends On
- `dbo.tblaff_Brands` - Brand record storage
- `dbo.AuditLog` - Audit trail storage (SectionID=7)

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
-- 1. Create a new brand
DECLARE @NewBrandID INT;
EXEC AffiliateAdmin.UpdateInsertBrand
    @UserEmail = N'admin@company.com',
    @ReasonOfChange = N'New product line launch',
    @BrandID = 0,
    @BrandName = 'Premium Trading',
    @OutputBrandID = @NewBrandID OUTPUT;
SELECT @NewBrandID AS CreatedBrandID;
```

```sql
-- 2. Update an existing brand name
DECLARE @BID INT = 5;
EXEC AffiliateAdmin.UpdateInsertBrand
    @UserEmail = N'marketing@company.com',
    @ReasonOfChange = N'Brand rename per marketing directive',
    @BrandID = @BID,
    @BrandName = 'Premium Trading Plus',
    @OutputBrandID = @BID OUTPUT;
```

```sql
-- 3. Create brand and assign to a new banner
DECLARE @NewBrandID INT;
EXEC AffiliateAdmin.UpdateInsertBrand
    @UserEmail = N'admin@company.com',
    @ReasonOfChange = N'New brand for Q3 campaign',
    @BrandID = 0,
    @BrandName = 'Summer Invest',
    @OutputBrandID = @NewBrandID OUTPUT;
-- Now use @NewBrandID when creating banners via UpdateInsertBanners
SELECT @NewBrandID AS BrandID;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4218.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateInsertBrand | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertBrand.sql*
