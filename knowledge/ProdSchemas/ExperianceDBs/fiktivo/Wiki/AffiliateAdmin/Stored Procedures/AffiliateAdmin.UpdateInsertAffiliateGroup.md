# AffiliateAdmin.UpdateInsertAffiliateGroup

> Upserts an affiliate group with viewer permissions, managing both the group record and the associated viewer user list with full field-level audit logging.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OutputGroupID (inserted or updated GroupID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateInsertAffiliateGroup upserts an affiliate group record in `AffiliateAdmin.AffiliatesGroups` and manages the associated viewer permissions in `AffiliateAdmin.AffiliateGroups_Viewers`. When @GroupID=0, a new group is created; otherwise the existing group is updated. The procedure also replaces the viewer user list using a DELETE-then-INSERT pattern and performs full field-level audit logging for all changes.

**WHY:** Affiliate groups organize affiliates into logical collections for management, reporting, and access control purposes. Each group has a name, an optional manager, and a set of viewer users who can see the group's affiliates and their data. The combined group + viewers upsert ensures that group configuration changes are atomic and fully audited, supporting the access control model of the affiliate administration system.

**HOW:** The procedure first checks @GroupID to determine INSERT or UPDATE mode. For inserts, it creates a new row in `AffiliateAdmin.AffiliatesGroups` with the group name and manager. For updates, it compares each field and logs changes. In both cases, it then replaces the viewer list by deleting all existing viewers from `AffiliateAdmin.AffiliateGroups_Viewers` for the group and inserting the new viewer set from @Users. The @OutputGroupID OUTPUT parameter returns the group ID.

---

## 2. Business Logic

### 2.1 Insert vs. Update Detection
- **@GroupID = 0:** INSERT a new group into `AffiliateAdmin.AffiliatesGroups`
- **@GroupID > 0:** UPDATE the existing group record

### 2.2 Group Record Management
The group record includes:
- **GroupName:** Display name for the group
- **ManagerUserID:** Optional uniqueidentifier pointing to the managing user

### 2.3 Viewer Permissions Replacement
After upserting the group record, the procedure replaces viewer permissions using DELETE-then-INSERT on `AffiliateAdmin.AffiliateGroups_Viewers`. The @Users parameter (of type `Affiliate.NvarcharList255`) contains the list of viewer user identifiers.

### 2.4 Field-Level Audit Logging
On UPDATE, the procedure compares old and new values for each field (GroupName, ManagerUserID, viewer list). Individual audit log entries are created for each field that changed, recording the old value, new value, user email, and reason of change.

### 2.5 Output Parameter
The @OutputGroupID OUTPUT parameter returns the GroupID to the caller. For inserts, this is the newly generated identity value. For updates, this is the same as the input @GroupID.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GroupID | INT | No | 0 | CODE-BACKED | 0 for INSERT, >0 for UPDATE of existing group |
| 2 | @GroupName | NVARCHAR(50) | No | - | CODE-BACKED | Display name for the affiliate group |
| 3 | @ManagerUserID | UNIQUEIDENTIFIER | Yes | NULL | CODE-BACKED | Optional Azure AD user ID of the group manager |
| 4 | @Users | Affiliate.NvarcharList255 READONLY | No | - | CODE-BACKED | TVP containing viewer user identifiers for group access |
| 5 | @ReasonOfChange | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | Reason for the change (audit context) |
| 6 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Admin user performing the change (for audit) |
| 7 | @OutputGroupID | INT | No | OUTPUT | CODE-BACKED | Returns the GroupID (new or existing) |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `AffiliateAdmin.AffiliatesGroups` | Table | INSERT or UPDATE group record |
| `AffiliateAdmin.AffiliateGroups_Viewers` | Table | DELETE + INSERT viewer permissions |
| `dbo.AuditLog` | Table | INSERT field-level audit entries |
| `Affiliate.NvarcharList255` | User-Defined Table Type | Input type for viewer user list |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Affiliate group management screen | Application | Create or edit group with viewer assignments |
| Group configuration API | Application | REST endpoint for group CRUD |

---

## 6. Dependencies

### 6.0 Chain
`UpdateInsertAffiliateGroup` -> check @GroupID -> INSERT or UPDATE `AffiliatesGroups` -> DELETE + INSERT `AffiliateGroups_Viewers` -> `AuditLog` (INSERT per changed field)

### 6.1 Depends On
- `AffiliateAdmin.AffiliatesGroups` - Group record storage
- `AffiliateAdmin.AffiliateGroups_Viewers` - Viewer permission junction table
- `dbo.AuditLog` - Audit trail storage
- `Affiliate.NvarcharList255` - User-defined table type for nvarchar list input

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
-- 1. Create a new affiliate group with viewers
DECLARE @Viewers Affiliate.NvarcharList255;
INSERT INTO @Viewers (Value) VALUES (N'user1@company.com'), (N'user2@company.com');
DECLARE @NewGroupID INT;
EXEC AffiliateAdmin.UpdateInsertAffiliateGroup
    @GroupID = 0,
    @GroupName = N'Premium Partners',
    @ManagerUserID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
    @Users = @Viewers,
    @ReasonOfChange = N'New group for premium tier affiliates',
    @UserEmail = N'admin@company.com',
    @OutputGroupID = @NewGroupID OUTPUT;
SELECT @NewGroupID AS CreatedGroupID;
```

```sql
-- 2. Update group name and reassign viewers
DECLARE @Viewers Affiliate.NvarcharList255;
INSERT INTO @Viewers (Value) VALUES (N'viewer1@company.com'), (N'viewer3@company.com');
DECLARE @GID INT = 5;
EXEC AffiliateAdmin.UpdateInsertAffiliateGroup
    @GroupID = @GID,
    @GroupName = N'Gold Partners',
    @Users = @Viewers,
    @ReasonOfChange = N'Renamed group and updated viewer access',
    @UserEmail = N'manager@company.com',
    @OutputGroupID = @GID OUTPUT;
```

```sql
-- 3. Create a group with no viewers and no manager
DECLARE @EmptyViewers Affiliate.NvarcharList255;
DECLARE @NewID INT;
EXEC AffiliateAdmin.UpdateInsertAffiliateGroup
    @GroupID = 0,
    @GroupName = N'Unassigned',
    @ManagerUserID = NULL,
    @Users = @EmptyViewers,
    @ReasonOfChange = N'Default group for unassigned affiliates',
    @UserEmail = N'admin@company.com',
    @OutputGroupID = @NewID OUTPUT;
SELECT @NewID AS GroupID;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4500.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateInsertAffiliateGroup | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertAffiliateGroup.sql*
