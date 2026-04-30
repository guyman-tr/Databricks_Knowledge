# AffiliateAdmin.MoveAffiliatesToAffiliateGroup

> Moves a specified set of affiliates to a target affiliate group with validation and audit logging for each moved affiliate.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN value: count of moved affiliates |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** MoveAffiliatesToAffiliateGroup reassigns a specified set of affiliates from their current groups to a target affiliate group. It accepts a table-valued parameter with the list of affiliate IDs to move, validates that the target group exists, performs the group reassignment, and creates an audit log entry for each individual move.

**WHY:** Affiliate group management is a core administrative function. As business relationships evolve, affiliates may need to be reorganized between groups for reasons such as performance tiers, regional restructuring, or partner program changes. This procedure provides a safe, audited mechanism for bulk affiliate reassignment, ensuring that every move is tracked for compliance and operational transparency.

**HOW:** The procedure first validates that the target @AffiliateGroupID exists in the affiliate groups table. If validation passes, it updates `tblaff_Affiliates.AffiliatesGroupsID` for all affiliates whose IDs are in the @Affiliates table-valued parameter. For each affected affiliate, an audit log entry is created recording the move action, the performing user (@UserEmail), and the change details. The procedure returns the count of moved affiliates via RETURN.

---

## 2. Business Logic

### 2.1 Target Group Validation
Before performing any updates, the procedure validates that the target @AffiliateGroupID exists in the affiliate groups table. If the target group does not exist, the procedure exits without making changes, preventing affiliates from being assigned to a non-existent group.

### 2.2 Bulk Affiliate Update
The procedure uses the @Affiliates table-valued parameter (dbo.IDTableType) to accept multiple affiliate IDs in a single call. All specified affiliates have their AffiliatesGroupsID updated to the target group value. This bulk approach is more efficient than individual updates.

### 2.3 Audit Logging
Each individual affiliate move is recorded in the audit log. The audit entry captures:
- The user who performed the action (@UserEmail)
- The affected affiliate ID
- The group change details (from/to)
- The timestamp of the change

This per-affiliate audit trail ensures granular tracking of group reassignment operations.

### 2.4 Return Value
The procedure returns the count of successfully moved affiliates via the RETURN statement, allowing the calling application to confirm the operation's scope.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Affiliates | dbo.IDTableType READONLY | No | - | CODE-BACKED | Table-valued parameter containing affiliate IDs to move |
| 2 | @AffiliateGroupID | INT | No | - | CODE-BACKED | Target affiliate group ID to move affiliates into |
| 3 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Email of the admin user performing the move (for audit logging) |

**Return Value:** Count of moved affiliates (INT) (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Affiliates` | Table | UPDATE AffiliatesGroupsID for specified affiliates |
| `AffiliateAdmin.AffiliatesGroups` | Table | Validate target group exists |
| `dbo.AuditLog` | Table | INSERT audit entries for each move |
| `dbo.IDTableType` | User-Defined Table Type | Input parameter type for affiliate ID list |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Affiliate group management | Application | Bulk affiliate reassignment operations |
| Group merge workflows | Application | Moving selected affiliates between groups |

---

## 6. Dependencies

### 6.0 Chain
`MoveAffiliatesToAffiliateGroup` -> `tblaff_Affiliates` (UPDATE) + `AuditLog` (INSERT)

### 6.1 Depends On
- `dbo.tblaff_Affiliates` - Target table for group reassignment
- `AffiliateAdmin.AffiliatesGroups` - Validation of target group existence
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
-- 1. Move specific affiliates to group 5
DECLARE @AffIDs dbo.IDTableType;
INSERT INTO @AffIDs (ID) VALUES (1001), (1002), (1003);
DECLARE @Result INT;
EXEC @Result = AffiliateAdmin.MoveAffiliatesToAffiliateGroup
    @Affiliates = @AffIDs,
    @AffiliateGroupID = 5,
    @UserEmail = N'admin@company.com';
SELECT @Result AS AffiliatesMoved;
```

```sql
-- 2. Move a single affiliate to a new group
DECLARE @AffIDs dbo.IDTableType;
INSERT INTO @AffIDs (ID) VALUES (2050);
EXEC AffiliateAdmin.MoveAffiliatesToAffiliateGroup
    @Affiliates = @AffIDs,
    @AffiliateGroupID = 12,
    @UserEmail = N'manager@company.com';
```

```sql
-- 3. Verify the move by checking affiliate group assignment
DECLARE @AffIDs dbo.IDTableType;
INSERT INTO @AffIDs (ID) VALUES (1001), (1002);
EXEC AffiliateAdmin.MoveAffiliatesToAffiliateGroup
    @Affiliates = @AffIDs,
    @AffiliateGroupID = 8,
    @UserEmail = N'admin@company.com';
-- Verify: SELECT AffiliateID, AffiliatesGroupsID FROM dbo.tblaff_Affiliates WHERE AffiliateID IN (1001, 1002);
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL references: PART-5531, PART-4262, PART-3147.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.MoveAffiliatesToAffiliateGroup | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.MoveAffiliatesToAffiliateGroup.sql*
