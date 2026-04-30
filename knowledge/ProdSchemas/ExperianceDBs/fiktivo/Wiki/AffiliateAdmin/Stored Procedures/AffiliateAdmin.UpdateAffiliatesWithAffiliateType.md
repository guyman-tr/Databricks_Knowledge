# AffiliateAdmin.UpdateAffiliatesWithAffiliateType

> Batch-updates the affiliate type assignment for multiple affiliates, logging each change with old and new type descriptions from tblaff_AffiliateTypes.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updated AffiliateTypeID on tblaff_Affiliates |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateAffiliatesWithAffiliateType reassigns a batch of affiliates from one affiliate type to another. It accepts the old and new affiliate type IDs along with a list of affiliate IDs, updates each affiliate's AffiliateTypeID in `tblaff_Affiliates`, and creates an audit log entry for each change that includes the old and new type descriptions resolved from `tblaff_AffiliateTypes`.

**WHY:** Affiliate types define the commission structure, banner access, and operational rules for an affiliate. When business needs change -- such as promoting affiliates to a higher-tier commission plan, consolidating affiliate types, or correcting misassignments -- administrators need to reassign multiple affiliates at once. The per-affiliate audit logging ensures complete traceability of type changes, which directly impact commission calculations.

**HOW:** The procedure accepts the @RemovedAffiliateTypeID (the old type being replaced), @AffiliateTypeID (the new type), and @Affiliates (the list of affiliate IDs to update). It resolves the description/name of both old and new types from `tblaff_AffiliateTypes` for audit logging purposes. It then updates `tblaff_Affiliates.AffiliateTypeID` for all affiliates in the input set and creates individual audit log entries recording the user, affiliate ID, and the old-to-new type change with human-readable descriptions.

---

## 2. Business Logic

### 2.1 Batch Type Reassignment
The procedure updates the AffiliateTypeID column on `tblaff_Affiliates` for all affiliate IDs provided in the @Affiliates TVP. This is a straightforward SET operation that changes the type assignment in bulk.

### 2.2 Type Description Resolution
Before performing the update, the procedure resolves the human-readable names/descriptions of both the old (@RemovedAffiliateTypeID) and new (@AffiliateTypeID) affiliate types from `tblaff_AffiliateTypes`. These descriptions are stored in the audit log entries for readability.

### 2.3 Per-Affiliate Audit Logging
Each affiliate type change generates an individual audit log entry. The audit captures:
- The user who performed the change (@UserEmail)
- The affiliate ID being changed
- The old type description and new type description
- The action type (Update)

### 2.4 Old Type Validation
The @RemovedAffiliateTypeID parameter identifies the previous type. While the procedure does not enforce that affiliates currently have this type (the UPDATE is unconditional on the @Affiliates set), it uses this value for audit logging to record what the type was changed FROM.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Email of the admin user performing the type change (for audit logging) |
| 2 | @RemovedAffiliateTypeID | INT | No | - | CODE-BACKED | The affiliate type ID being replaced (old type) |
| 3 | @AffiliateTypeID | INT | No | - | CODE-BACKED | The new affiliate type ID to assign |
| 4 | @Affiliates | dbo.IDTableType READONLY | No | - | CODE-BACKED | Table-valued parameter containing affiliate IDs to reassign |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Affiliates` | Table | UPDATE AffiliateTypeID for specified affiliates |
| `dbo.tblaff_AffiliateTypes` | Table | SELECT type descriptions for audit logging |
| `dbo.AuditLog` | Table | INSERT audit entries for each type change |
| `dbo.IDTableType` | User-Defined Table Type | Input parameter type for affiliate ID list |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Affiliate type management screen | Application | Bulk reassign affiliates between types |
| Affiliate type consolidation | Application | Move affiliates when merging types |

---

## 6. Dependencies

### 6.0 Chain
`UpdateAffiliatesWithAffiliateType` -> `tblaff_AffiliateTypes` (resolve descriptions) -> `tblaff_Affiliates` (UPDATE) -> `AuditLog` (INSERT per affiliate)

### 6.1 Depends On
- `dbo.tblaff_Affiliates` - Target table for affiliate type assignment update
- `dbo.tblaff_AffiliateTypes` - Source for type name/description resolution
- `dbo.AuditLog` - Audit trail storage
- `dbo.IDTableType` - User-defined table type for affiliate ID list input

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
-- 1. Reassign affiliates from type 3 to type 7
DECLARE @AffIDs dbo.IDTableType;
INSERT INTO @AffIDs (ID) VALUES (100), (101), (102);
EXEC AffiliateAdmin.UpdateAffiliatesWithAffiliateType
    @UserEmail = N'admin@company.com',
    @RemovedAffiliateTypeID = 3,
    @AffiliateTypeID = 7,
    @Affiliates = @AffIDs;
```

```sql
-- 2. Move a single affiliate to a new type
DECLARE @AffIDs dbo.IDTableType;
INSERT INTO @AffIDs (ID) VALUES (250);
EXEC AffiliateAdmin.UpdateAffiliatesWithAffiliateType
    @UserEmail = N'manager@company.com',
    @RemovedAffiliateTypeID = 1,
    @AffiliateTypeID = 5,
    @Affiliates = @AffIDs;
```

```sql
-- 3. Verify type changes after update
DECLARE @AffIDs dbo.IDTableType;
INSERT INTO @AffIDs (ID) VALUES (300), (301);
EXEC AffiliateAdmin.UpdateAffiliatesWithAffiliateType
    @UserEmail = N'admin@company.com',
    @RemovedAffiliateTypeID = 2,
    @AffiliateTypeID = 6,
    @Affiliates = @AffIDs;
-- Verify:
SELECT AffiliateID, AffiliateTypeID FROM dbo.tblaff_Affiliates WHERE AffiliateID IN (300, 301);
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4262.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateAffiliatesWithAffiliateType | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateAffiliatesWithAffiliateType.sql*
