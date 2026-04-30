# AffiliateAdmin.MoveAllAffiliatesToAffiliateGroup

> Moves all affiliates from one affiliate group to another with validation of both groups and audit logging of the operation.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN value: count of moved affiliates (-1 if none found) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** MoveAllAffiliatesToAffiliateGroup performs a bulk transfer of all affiliates from a source group to a target group. It validates that both the source and target groups exist, audit logs the operation, updates all affiliates in the source group to the target group, and returns the count of affected affiliates.

**WHY:** When restructuring affiliate groups, administrators sometimes need to merge one group entirely into another or dissolve a group by moving all its members. This is a common operation during organizational restructuring, group consolidation, or when retiring a group. The procedure ensures a safe, validated, and fully audited group-level migration that moves all members at once rather than requiring individual selection.

**HOW:** The procedure first validates that both @AffiliateGroupIDFrom (source) and @AffiliateGroupIDTo (target) exist in the affiliate groups table. It then checks whether any affiliates belong to the source group. If no affiliates are found, it returns -1. Otherwise, it creates audit log entries for the move, updates all affiliates' AffiliatesGroupsID from the source to the target group, and returns the count of moved affiliates via RETURN.

---

## 2. Business Logic

### 2.1 Dual Group Validation
The procedure validates the existence of both the source and target affiliate groups before proceeding. This prevents invalid operations such as moving from a non-existent group or moving to a deleted group.

### 2.2 Empty Source Group Handling
If the source group has no affiliates assigned, the procedure returns -1 via RETURN without performing any updates or audit logging. The calling application should handle this return value to display an appropriate message (e.g., "No affiliates found in source group").

### 2.3 Audit Logging Before Update
The procedure creates audit log entries recording the bulk move operation before performing the actual update. This ensures the audit trail captures the user (@UserEmail) and the nature of the operation (source group, target group).

### 2.4 Bulk Update
All affiliates with AffiliatesGroupsID matching @AffiliateGroupIDFrom are updated to @AffiliateGroupIDTo in a single UPDATE statement. This atomic operation ensures all members are moved together.

### 2.5 Return Value
The procedure returns the count of successfully moved affiliates via RETURN. A return value of -1 indicates no affiliates were found in the source group.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateGroupIDFrom | INT | No | - | CODE-BACKED | Source affiliate group ID to move all members from |
| 2 | @AffiliateGroupIDTo | INT | No | - | CODE-BACKED | Target affiliate group ID to move all members into |
| 3 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Email of the admin user performing the move (for audit logging) |

**Return Value:** Count of moved affiliates (INT), or -1 if no affiliates found in source group (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Affiliates` | Table | UPDATE AffiliatesGroupsID for all affiliates in source group |
| `AffiliateAdmin.AffiliatesGroups` | Table | Validate both source and target groups exist |
| `dbo.AuditLog` | Table | INSERT audit entries for the bulk move operation |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Group merge workflow | Application | Consolidates one group into another |
| Group dissolution | Application | Empties a group before deletion |

---

## 6. Dependencies

### 6.0 Chain
`MoveAllAffiliatesToAffiliateGroup` -> `AffiliatesGroups` (validate) -> `tblaff_Affiliates` (UPDATE) + `AuditLog` (INSERT)

### 6.1 Depends On
- `dbo.tblaff_Affiliates` - Target table for bulk group reassignment
- `AffiliateAdmin.AffiliatesGroups` - Validation of both source and target group existence
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
-- 1. Move all affiliates from group 3 to group 7
DECLARE @Result INT;
EXEC @Result = AffiliateAdmin.MoveAllAffiliatesToAffiliateGroup
    @AffiliateGroupIDFrom = 3,
    @AffiliateGroupIDTo = 7,
    @UserEmail = N'admin@company.com';
SELECT @Result AS AffiliatesMoved;
-- Returns count of moved affiliates, or -1 if source group was empty
```

```sql
-- 2. Consolidate group 10 into group 1 as part of group merge
DECLARE @Result INT;
EXEC @Result = AffiliateAdmin.MoveAllAffiliatesToAffiliateGroup
    @AffiliateGroupIDFrom = 10,
    @AffiliateGroupIDTo = 1,
    @UserEmail = N'manager@company.com';
IF @Result = -1
    PRINT 'No affiliates found in source group';
ELSE
    PRINT CAST(@Result AS VARCHAR) + ' affiliates moved successfully';
```

```sql
-- 3. Empty a group before deletion
DECLARE @Result INT;
EXEC @Result = AffiliateAdmin.MoveAllAffiliatesToAffiliateGroup
    @AffiliateGroupIDFrom = 15,
    @AffiliateGroupIDTo = 1,
    @UserEmail = N'admin@company.com';
-- After move, verify source group is empty:
-- SELECT COUNT(*) FROM dbo.tblaff_Affiliates WHERE AffiliatesGroupsID = 15;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4500.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.MoveAllAffiliatesToAffiliateGroup | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.MoveAllAffiliatesToAffiliateGroup.sql*
