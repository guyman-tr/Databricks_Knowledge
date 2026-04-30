# AffiliateAdmin.UpdateBannersPriority

> Batch-updates the Priority value on banners, comparing old and new values and logging each change through Dictionary.ChangedSections resolution.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updated Priority on tblaff_Banners |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateBannersPriority updates the Priority value for one or more banners based on a table-valued parameter containing (BannerID, Priority) pairs. The procedure iterates through each banner, compares the current Priority value against the new value, and logs changes to the audit log with the 'Banners' section resolved from `Dictionary.ChangedSections`.

**WHY:** Banner priority determines the display order and prominence of affiliate marketing banners. Higher-priority banners appear first or more frequently. Administrators regularly adjust priorities to promote seasonal campaigns, new creative assets, or high-performing banners. The per-banner change detection ensures the audit trail only captures actual priority changes.

**HOW:** The procedure accepts @BannersPriority of type `dbo.TwoIdsTableType` where ID1 maps to BannerID and ID2 maps to the new Priority value. It resolves the 'Banners' SectionID from `Dictionary.ChangedSections`. It then loops through each entry, retrieves the current Priority for the banner, compares it to the requested value, and if different, updates the banner and creates an audit log entry.

---

## 2. Business Logic

### 2.1 Two-ID Table-Valued Parameter
The procedure uses `dbo.TwoIdsTableType` to pass (BannerID, Priority) pairs:
- **ID1** = BannerID (the banner to update)
- **ID2** = Priority (the new priority value, typically an integer)

### 2.2 Per-Banner Loop
The procedure iterates through each entry in the TVP using the same loop pattern as `UpdateBannersArchive`. For each banner, it:
1. Retrieves the current Priority value from `tblaff_Banners`
2. Compares the current value to the requested new value
3. Only performs the UPDATE and audit log INSERT if the values differ

### 2.3 Change Detection
By comparing old vs. new Priority values before updating, the procedure avoids unnecessary writes and audit log entries. Only actual priority changes are logged, keeping the audit trail clean.

### 2.4 Section Resolution
The procedure resolves the 'Banners' section from `Dictionary.ChangedSections` to obtain the SectionID used in audit log entries. This is the same section used by `UpdateBannersArchive`. See Changed Sections glossary.

### 2.5 Audit Logging
Each actual priority change generates an audit log entry recording the user (@UserEmail), the banner ID, the old Priority value, the new Priority value, and the resolved SectionID for Banners.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | NVARCHAR(250) | Yes | NULL | CODE-BACKED | Email of the admin user performing the priority change (for audit logging) |
| 2 | @BannersPriority | dbo.TwoIdsTableType READONLY | No | - | CODE-BACKED | TVP with ID1=BannerID and ID2=Priority |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Banners` | Table | UPDATE Priority per banner |
| `Dictionary.ChangedSections` | Table | Resolve 'Banners' SectionID for audit |
| `dbo.AuditLog` | Table | INSERT audit entries for each actual change |
| `dbo.TwoIdsTableType` | User-Defined Table Type | Input parameter type for (BannerID, Priority) pairs |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Banner management screen | Application | Reorder banner priorities |
| Banner list grid | Application | Drag-and-drop priority reordering |

---

## 6. Dependencies

### 6.0 Chain
`UpdateBannersPriority` -> `Dictionary.ChangedSections` (resolve 'Banners') -> LOOP: `tblaff_Banners` (compare + UPDATE) -> `AuditLog` (INSERT if changed)

### 6.1 Depends On
- `dbo.tblaff_Banners` - Target table for Priority updates
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
-- 1. Set priorities for specific banners
DECLARE @Priorities dbo.TwoIdsTableType;
INSERT INTO @Priorities (ID1, ID2) VALUES (100, 1), (101, 2), (102, 3);
EXEC AffiliateAdmin.UpdateBannersPriority
    @UserEmail = N'admin@company.com',
    @BannersPriority = @Priorities;
```

```sql
-- 2. Promote a single banner to highest priority
DECLARE @Priorities dbo.TwoIdsTableType;
INSERT INTO @Priorities (ID1, ID2) VALUES (250, 1);
EXEC AffiliateAdmin.UpdateBannersPriority
    @UserEmail = N'manager@company.com',
    @BannersPriority = @Priorities;
```

```sql
-- 3. Bulk reorder banners and verify
DECLARE @Priorities dbo.TwoIdsTableType;
INSERT INTO @Priorities (ID1, ID2) VALUES
    (300, 5), (301, 3), (302, 1), (303, 2), (304, 4);
EXEC AffiliateAdmin.UpdateBannersPriority
    @UserEmail = N'admin@company.com',
    @BannersPriority = @Priorities;
-- Verify:
SELECT BannerID, Priority FROM dbo.tblaff_Banners
WHERE BannerID IN (300, 301, 302, 303, 304)
ORDER BY Priority;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4472.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateBannersPriority | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateBannersPriority.sql*
