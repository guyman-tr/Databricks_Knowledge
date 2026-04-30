# AffiliateAdmin.UpdateBannersArchive

> Batch-updates the IsArchived flag on banners, comparing old and new values and logging each change through Dictionary.ChangedSections resolution.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updated IsArchived on tblaff_Banners |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateBannersArchive updates the IsArchived flag for one or more banners based on a table-valued parameter containing (BannerID, IsArchived) pairs. The procedure iterates through each banner, compares the current IsArchived value against the new value, and logs changes to the audit log with the 'Banners' section resolved from `Dictionary.ChangedSections`.

**WHY:** Banner archival is a soft-delete mechanism that removes banners from active display without permanently deleting them. Administrators need to archive outdated banners and occasionally unarchive them for seasonal campaigns or reuse. The per-banner change detection and audit logging ensures that only actual state changes are recorded, preventing audit log noise from no-op updates.

**HOW:** The procedure accepts @BannersPriority of type `dbo.TwoIdsTableType` where ID1 maps to BannerID and ID2 maps to the IsArchived flag (0 or 1). It resolves the 'Banners' SectionID from `Dictionary.ChangedSections`. It then loops through each entry in the TVP, retrieves the current IsArchived value for the banner, compares it to the requested value, and if different, updates the banner and creates an audit log entry recording the change.

---

## 2. Business Logic

### 2.1 Two-ID Table-Valued Parameter
The procedure uses `dbo.TwoIdsTableType` to pass (BannerID, IsArchived) pairs:
- **ID1** = BannerID (the banner to update)
- **ID2** = IsArchived (0 = active, 1 = archived)

### 2.2 Per-Banner Loop
The procedure iterates through each entry in the TVP using a cursor or WHILE loop pattern. For each banner, it:
1. Retrieves the current IsArchived value from `tblaff_Banners`
2. Compares the current value to the requested new value
3. Only performs the UPDATE and audit log INSERT if the values differ

### 2.3 Change Detection
By comparing old vs. new IsArchived values before updating, the procedure avoids unnecessary writes and audit log entries. Only actual state transitions (active-to-archived or archived-to-active) are logged.

### 2.4 Section Resolution
The procedure resolves the 'Banners' section from `Dictionary.ChangedSections` to obtain the SectionID used in audit log entries. See Changed Sections glossary for section ID reference.

### 2.5 Audit Logging
Each actual change generates an audit log entry recording the user (@UserEmail), the banner ID, the old IsArchived value, the new IsArchived value, and the resolved SectionID for Banners.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | NVARCHAR(250) | Yes | NULL | CODE-BACKED | Email of the admin user performing the archive change (for audit logging) |
| 2 | @BannersToArchive | dbo.TwoIdsTableType READONLY | No | - | CODE-BACKED | TVP with ID1=BannerID and ID2=IsArchived (0/1) |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Banners` | Table | UPDATE IsArchived flag per banner |
| `Dictionary.ChangedSections` | Table | Resolve 'Banners' SectionID for audit |
| `dbo.AuditLog` | Table | INSERT audit entries for each actual change |
| `dbo.TwoIdsTableType` | User-Defined Table Type | Input parameter type for (BannerID, IsArchived) pairs |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Banner management screen | Application | Archive/unarchive selected banners |
| Banner list grid | Application | Bulk archive action from UI |

---

## 6. Dependencies

### 6.0 Chain
`UpdateBannersArchive` -> `Dictionary.ChangedSections` (resolve 'Banners') -> LOOP: `tblaff_Banners` (compare + UPDATE) -> `AuditLog` (INSERT if changed)

### 6.1 Depends On
- `dbo.tblaff_Banners` - Target table for IsArchived flag updates
- `Dictionary.ChangedSections` - Section name resolution for audit logging. See Changed Sections glossary.
- `dbo.AuditLog` - Audit trail storage
- `dbo.TwoIdsTableType` - User-defined table type for two-column ID pairs

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
-- 1. Archive specific banners
DECLARE @Banners dbo.TwoIdsTableType;
INSERT INTO @Banners (ID1, ID2) VALUES (100, 1), (101, 1), (102, 1);
EXEC AffiliateAdmin.UpdateBannersArchive
    @UserEmail = N'admin@company.com',
    @BannersToArchive = @Banners;
```

```sql
-- 2. Unarchive a banner (restore to active)
DECLARE @Banners dbo.TwoIdsTableType;
INSERT INTO @Banners (ID1, ID2) VALUES (100, 0);
EXEC AffiliateAdmin.UpdateBannersArchive
    @UserEmail = N'manager@company.com',
    @BannersToArchive = @Banners;
```

```sql
-- 3. Mixed archive/unarchive batch
DECLARE @Banners dbo.TwoIdsTableType;
INSERT INTO @Banners (ID1, ID2) VALUES
    (200, 1),  -- archive banner 200
    (201, 0),  -- unarchive banner 201
    (202, 1);  -- archive banner 202
EXEC AffiliateAdmin.UpdateBannersArchive
    @UserEmail = N'admin@company.com',
    @BannersToArchive = @Banners;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4472.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateBannersArchive | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateBannersArchive.sql*
