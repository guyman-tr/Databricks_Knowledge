# AffiliateAdmin.AffiliateGroups_Viewers

> Junction table implementing role-based access control by linking back-office users to the affiliate groups whose data they are permitted to view in the admin portal.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Table |
| **Key Identifier** | (AffiliatesGroupsID, UserObjectID) composite PK, CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK only, FILLFACTOR=90) |

---

## 1. Business Meaning

AffiliateAdmin.AffiliateGroups_Viewers is the access control junction table that determines which back-office employees can view data for which affiliate groups. Each row represents a single permission grant: "user X can see group Y." This many-to-many mapping enables fine-grained visibility control over the affiliate management portal - an account manager sees only their assigned groups, while administrators can see all groups.

This table exists because the affiliate platform manages 292 groups containing tens of thousands of affiliates, and different team members need visibility into different subsets. Without it, either all users would see all data (a compliance and operational risk) or the system would need hardcoded access rules. The access control model supports both per-group assignment and a universal access sentinel (Group ID=1, "* VIEW ALL GROUPS *").

Data flows in exclusively through `AffiliateAdmin.UpdateInsertAffiliateGroup`, which uses a DELETE-then-INSERT pattern: when a group's viewer list is updated, all existing viewer rows for that group are deleted and the new list is inserted. This means the table is always in a consistent state - partial updates cannot occur. Rows are also cascade-deleted when a group is deleted via `AffiliateAdmin.DeleteAffiliateGroups`. The table is read by `AffiliateAdmin.GetAffiliateGroupByID` (returns viewer list for a group) and by `dbo.GetPayments` (checks if the requesting user has access to a specific group's payment data).

---

## 2. Business Logic

### 2.1 Many-to-Many Access Control

**What**: Each user can be assigned to view multiple groups, and each group can have multiple viewers, creating a flexible access control matrix.

**Columns/Parameters Involved**: `AffiliatesGroupsID`, `UserObjectID`

**Rules**:
- The composite PK ensures a user can only be assigned to a group once (no duplicate grants)
- Most groups have 1-2 viewers; "test11" is the only group with 3 viewers
- Chana Naftali and Liora Edelstein Hakak appear as viewers for the majority of groups, suggesting they have broad administrative responsibilities
- 379 total rows for 292 groups and 18 users shows that viewer coverage is sparse - most users see a limited set of groups

### 2.2 Universal Access via Sentinel Group

**What**: Users assigned as viewers of Group ID=1 ("* VIEW ALL GROUPS *") effectively have visibility into all groups without needing individual per-group assignments.

**Columns/Parameters Involved**: `AffiliatesGroupsID` (value = 1)

**Rules**:
- `dbo.GetPayments` checks if a user's UserObjectID appears in AffiliateGroups_Viewers with AffiliatesGroupsID=1 to determine if they bypass group-level filtering
- The sentinel logic is also visible (commented out) in `AffiliateAdmin.GetAffiliateGroups` where it would grant `@Admin_ShowAll = 1`
- Currently 2 users (Liora Edelstein Hakak and Chana Naftali) have this universal access

**Diagram**:
```
User: Liora
  |
  +-- Group 1: * VIEW ALL GROUPS * --> sees ALL groups
  +-- Group 11: eToro Partners      --> (redundant but explicitly assigned)
  +-- Group 165: Adextent retargeting
  +-- ... (many more individual groups)

User: Adi Rosha
  |
  +-- Group 24: Adi                 --> sees only "Adi" group
```

### 2.3 Delete-and-Replace Update Pattern

**What**: Viewer assignments are managed atomically - the entire viewer list for a group is replaced in a single transaction, not edited incrementally.

**Columns/Parameters Involved**: Both columns

**Rules**:
- `UpdateInsertAffiliateGroup` first DELETEs all rows for the target group, then INSERTs the new viewer list from a TVP
- The old and new viewer lists are compared (via STRING_AGG) to detect changes, and differences are audit-logged
- The FILLFACTOR=90 on the clustered index accommodates this bulk delete/insert pattern by leaving page headroom
- This pattern ensures no orphaned viewers and prevents race conditions from incremental edits

---

## 3. Data Overview

| AffiliatesGroupsID | AffiliatesGroupsName | ViewerName | Meaning |
|---|---|---|---|
| 1 | * VIEW ALL GROUPS * | Liora Edelstein Hakak | Universal access grant - this user can view data for every affiliate group in the system. Only 2 users have this level of access. |
| 1 | * VIEW ALL GROUPS * | Chana Naftali | Second universal access holder. Together with Liora, these users represent the top-level administrators of the affiliate platform. |
| 11 | eToro Partners | Liora Edelstein Hakak | Explicit group-level access to the eToro Partners group (3,742 affiliates). Redundant for Liora since she has universal access, but maintained for completeness. |
| 334 | 56662 | Chana Naftali | Access to a numerically-named group - likely a legacy or system-generated group identifier. Shows that viewer assignments cover even unusual group names. |
| 24 | Adi | Chana Naftali | Single-viewer group - only Chana can see this account manager's affiliate portfolio. Demonstrates the per-group isolation model. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliatesGroupsID | int | NO | - | VERIFIED | The affiliate group being granted access to. Part of composite PK. Implicit FK to `AffiliateAdmin.AffiliatesGroups.AffiliatesGroupsID`. Value of 1 grants universal access via the "* VIEW ALL GROUPS *" sentinel group. Cascade-deleted when the group itself is deleted by `AffiliateAdmin.DeleteAffiliateGroups`. Bulk-replaced (DELETE + INSERT) when the group's viewer list is updated by `AffiliateAdmin.UpdateInsertAffiliateGroup`. |
| 2 | UserObjectID | uniqueidentifier | NO | - | VERIFIED | The back-office user being granted view access. Part of composite PK. Implicit FK to `AffiliateAdmin.Users.UserObjectID`. Represents an Azure AD Object ID of an eToro employee. Used by `dbo.GetPayments` to check if the requesting user (resolved from legacy UserID via email matching) has access to group-scoped payment data. Populated from a TVP (`Affiliate.NvarcharList255`) during the group update process. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliatesGroupsID | AffiliateAdmin.AffiliatesGroups | Implicit FK | Links the viewer permission to a specific affiliate group. The group provides the organizational context for the access grant. |
| UserObjectID | AffiliateAdmin.Users | Implicit FK | Links the viewer permission to a specific back-office user. The user provides the identity context for the access grant. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateAdmin.UpdateInsertAffiliateGroup | AffiliatesGroupsID | WRITER/DELETER | Manages the viewer list for each group via DELETE-then-INSERT pattern within a transaction |
| AffiliateAdmin.DeleteAffiliateGroups | AffiliatesGroupsID | DELETER | Cascade-deletes all viewer assignments when a group is removed |
| AffiliateAdmin.GetAffiliateGroupByID | AffiliatesGroupsID | READER | Returns the UserObjectID list for a group's viewers |
| dbo.GetPayments | UserObjectID, AffiliatesGroupsID | READER | Checks if the requesting user has access to group-scoped payment data, including the sentinel group (ID=1) check |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. It is a leaf table.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.AffiliatesGroups | Table | AffiliatesGroupsID references AffiliatesGroupsID (implicit FK) |
| AffiliateAdmin.Users | Table | UserObjectID references UserObjectID (implicit FK) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.UpdateInsertAffiliateGroup | Stored Procedure | WRITER/DELETER - manages viewer list via bulk replace |
| AffiliateAdmin.DeleteAffiliateGroups | Stored Procedure | DELETER - cascade deletes viewers when group is removed |
| AffiliateAdmin.GetAffiliateGroupByID | Stored Procedure | READER - retrieves viewer list for a group |
| dbo.GetPayments | Stored Procedure | READER - access control check for payment data visibility |
| AffiliateAdmin.GetAffiliateGroups | Stored Procedure | READER - viewer-based group filtering (currently commented out in code) |
| AffiliateAdmin.GetAffiliateGroupsList | Stored Procedure | READER - viewer-filtered group listing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AffiliateAdmin.tblaff_AffiliateGroups_Viewers | CLUSTERED | AffiliatesGroupsID ASC, UserObjectID ASC | - | - | Active |

**Note**: The PK constraint name retains the legacy prefix `tblaff_` from the original `dbo.tblaff_AffiliateGroups_Viewers` table, even though the table was migrated to the AffiliateAdmin schema. FILLFACTOR=90 leaves 10% page headroom to accommodate the bulk DELETE + INSERT update pattern used by `UpdateInsertAffiliateGroup`.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AffiliateAdmin.tblaff_AffiliateGroups_Viewers | PRIMARY KEY (composite) | Enforces uniqueness on (AffiliatesGroupsID, UserObjectID) - a user can be assigned to a group at most once |

---

## 8. Sample Queries

### 8.1 List all users with universal access (sentinel group viewers)
```sql
SELECT u.FirstName, u.LastName, u.Email
FROM AffiliateAdmin.AffiliateGroups_Viewers agv WITH (NOLOCK)
JOIN AffiliateAdmin.Users u WITH (NOLOCK) ON u.UserObjectID = agv.UserObjectID
WHERE agv.AffiliatesGroupsID = 1
```

### 8.2 Find all groups a specific user can view
```sql
SELECT ag.AffiliatesGroupsID, ag.AffiliatesGroupsName
FROM AffiliateAdmin.AffiliateGroups_Viewers agv WITH (NOLOCK)
JOIN AffiliateAdmin.AffiliatesGroups ag WITH (NOLOCK) ON ag.AffiliatesGroupsID = agv.AffiliatesGroupsID
WHERE agv.UserObjectID = '71466E26-C43B-4A72-B39C-0216B34B0E0E'
ORDER BY ag.AffiliatesGroupsName
```

### 8.3 Access control check - does a user have access to a group (including sentinel)
```sql
SELECT CASE
    WHEN EXISTS (
        SELECT 1 FROM AffiliateAdmin.AffiliateGroups_Viewers WITH (NOLOCK)
        WHERE UserObjectID = @UserObjectID AND AffiliatesGroupsID = @GroupID
    ) OR EXISTS (
        SELECT 1 FROM AffiliateAdmin.AffiliateGroups_Viewers WITH (NOLOCK)
        WHERE UserObjectID = @UserObjectID AND AffiliatesGroupsID = 1
    )
    THEN 'ACCESS GRANTED'
    ELSE 'ACCESS DENIED'
END AS AccessResult
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. The table was migrated from `dbo.tblaff_AffiliateGroups_Viewers` as part of PART-5531 (February 2026).

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.AffiliateGroups_Viewers | Type: Table | Source: fiktivo/AffiliateAdmin/Tables/AffiliateAdmin.AffiliateGroups_Viewers.sql*
