# AffiliateAdmin.AffiliatesGroups

> Organizational grouping of affiliates by marketing channel, team assignment, or individual account manager, used for access control, reporting segmentation, and commission management in the affiliate back-office.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Table |
| **Key Identifier** | AffiliatesGroupsID (int IDENTITY, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

AffiliateAdmin.AffiliatesGroups defines the organizational structure for categorizing affiliates into manageable groups. Each group represents either a marketing channel (SEO, SEM, Media, Direct), a business relationship category (eToro Partners, Friend Referral), or an individual account manager's portfolio (Natacha, Yasmin, Jil, Moshe Solomon). Affiliates are assigned to exactly one group via `dbo.tblaff_Affiliates.AffiliatesGroupsID`, enabling role-based access control and reporting segmentation.

This table exists because the affiliate platform manages thousands of affiliates across different business channels, each requiring dedicated account management. Without it, there would be no way to segment affiliates for team-specific payment approvals, restrict back-office user visibility to their assigned portfolios, or aggregate commission reports by organizational unit. It replaced the legacy `dbo.tblaff_AffiliatesGroups` table as part of the PART-5531 migration (February 2026).

Data flows in through `AffiliateAdmin.UpdateInsertAffiliateGroup`, which handles both creation (when @GroupID = 0) and updates (when @GroupID > 0) in a single procedure with full audit logging. Groups can be deleted via `AffiliateAdmin.DeleteAffiliateGroups`, but only if no affiliates are still assigned to the group - deletion cascades to remove the group's viewer assignments in `AffiliateGroups_Viewers`. The table is read extensively by affiliate profile procedures (`dbo.GetAffiliateById`, `dbo.GetAffiliateByAzureObjectId`, `Affiliate.GetAffiliates`) which LEFT JOIN to resolve the group name and account manager for display. `AffiliateAdmin.GetAffiliateGroups` returns all groups except ID=1 for admin UI dropdowns.

---

## 2. Business Logic

### 2.1 Group as Organizational Unit

**What**: Groups categorize affiliates by marketing channel, business relationship, or account manager portfolio for segmented management and reporting.

**Columns/Parameters Involved**: `AffiliatesGroupsID`, `AffiliatesGroupsName`, `ManagerUserID`

**Rules**:
- Each affiliate in `dbo.tblaff_Affiliates` belongs to exactly one group via `AffiliatesGroupsID`
- Group names fall into three patterns: channel-based (SEO, SEM, Media, Direct), relationship-based (eToro Partners, Friend Referral), and manager-named (Natacha, Yasmin, Jil)
- The largest group "Natacha" contains 21,000+ affiliates; "eToro Partners" has 3,700+
- 292 groups exist, showing the granularity of affiliate management

### 2.2 Sentinel Group for Universal Access

**What**: Group ID=1 ("* VIEW ALL GROUPS *") is a special sentinel that grants a user visibility into all affiliate groups when assigned via `AffiliateGroups_Viewers`.

**Columns/Parameters Involved**: `AffiliatesGroupsID`, `AffiliatesGroupsName`

**Rules**:
- ID=1 is excluded from all group listing procedures (`WHERE AffiliatesGroupsID > 1`)
- In the access control logic (commented out but visible in `GetAffiliateGroups`), a user assigned to the sentinel group bypasses per-group filtering
- This is NOT a real affiliate group - no affiliates should be assigned to it
- `dbo.GetPayments` checks if a user is in group ID=1's viewer list to determine if payment filtering should be applied

**Diagram**:
```
AffiliatesGroups
+---+---------------------------+
| 1 | * VIEW ALL GROUPS *       |  <-- Sentinel: grants universal access
+---+---------------------------+
| 2 | Affiliates                |  <-- Channel group (6,138 affiliates)
| 4 | SEM                       |  <-- Channel group
| 5 | SEO                       |  <-- Channel group
|11 | eToro Partners             |  <-- Relationship (3,742 affiliates)
|141| Natacha                    |  <-- Manager portfolio (21,031 affiliates)
+---+---------------------------+
```

### 2.3 Legacy vs New Manager Identity

**What**: The table has both legacy denormalized manager fields (`AccountManagerName`, `AccountManagerEmail`, `AccountManagerImagePath`) and the new normalized `ManagerUserID` FK to `AffiliateAdmin.Users`.

**Columns/Parameters Involved**: `AccountManagerName`, `AccountManagerEmail`, `AccountManagerImagePath`, `ManagerUserID`

**Rules**:
- New groups created via `UpdateInsertAffiliateGroup` only set `AffiliatesGroupsName` and `ManagerUserID` - the legacy fields are not populated
- Old groups retain legacy field values but have NULL `ManagerUserID`
- Procedures that display manager info (GetAffiliateById, GetAffiliateByAzureObjectId) JOIN to `AffiliateAdmin.Users` via `ManagerUserID`, ignoring the legacy denormalized fields
- The legacy fields are kept for backwards compatibility but are effectively deprecated

### 2.4 Audit Trail for Group Changes

**What**: Every group creation, modification, and deletion is recorded in the AuditLog with user identification, old/new values, and reason for change.

**Columns/Parameters Involved**: All columns via `UpdateInsertAffiliateGroup` and `DeleteAffiliateGroups`

**Rules**:
- Create (ActionID=1): Logs "Add new Affiliate group with ID: {ID}"
- Update (ActionID=2): Separately logs changes to `AffiliatesGroupsName` and `ManagerUserID` with old/new values
- Update (ActionID=2): Also logs when the viewer user list changes ("UserObjectID list has changed")
- Delete (ActionID=3): Logs "Delete AffiliateGroupID: {ID}" for each deleted group
- All audit entries use `Dictionary.ChangedSections` where Name='Affiliate Group' to classify the change type
- Delete is blocked if any affiliates are still assigned to the group

---

## 3. Data Overview

| AffiliatesGroupsID | AffiliatesGroupsName | ManagerUserID | Meaning |
|---|---|---|---|
| 1 | * VIEW ALL GROUPS * | NULL | Sentinel group used for access control - assigning a user as viewer of this group grants them visibility into all groups. Excluded from all group listing queries (`WHERE ID > 1`). |
| 11 | eToro Partners | 71466E26-... (Liora Edelstein Hakak) | The primary partner program group with 3,742 affiliates. One of the few groups with an assigned manager via the new ManagerUserID system. |
| 141 | Natacha | NULL | The largest group by affiliate count (21,031). Named after the account manager but uses legacy identity fields, not ManagerUserID. Represents a major affiliate portfolio. |
| 2 | Affiliates | NULL | General-purpose group for unspecified affiliates. Legacy group with no assigned manager. Serves as a catch-all category. |
| 4 | SEM | NULL | Search Engine Marketing channel group. Groups affiliates who drive traffic primarily through paid search advertising. Legacy group without manager assignment. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliatesGroupsID | int IDENTITY(1,1) | NO | IDENTITY | VERIFIED | Auto-incrementing primary key identifying each affiliate group. NOT FOR REPLICATION - identity values are not reseeded during replication. Referenced by `dbo.tblaff_Affiliates.AffiliatesGroupsID` to assign affiliates to groups, by `AffiliateAdmin.AffiliateGroups_Viewers.AffiliatesGroupsID` to control user access, and by `dbo.GetPayments` for payment scoping. ID=1 is a sentinel ("* VIEW ALL GROUPS *") excluded from normal queries. |
| 2 | AffiliatesGroupsName | nvarchar(50) | NO | - | VERIFIED | Display name of the affiliate group. Values fall into three categories: channel names (SEO, SEM, Media, Direct), relationship types (eToro Partners, Friend Referral), or account manager names (Natacha, Yasmin, Jil). Shown in admin UI dropdowns, affiliate profile displays, and reports. Changed via `UpdateInsertAffiliateGroup` with old/new value audit logging. |
| 3 | AccountManagerName | nvarchar(50) MASKED | YES | - | CODE-BACKED | LEGACY - denormalized account manager name. Dynamic data masking applied (`default()` function) for PII protection. Not populated by the current `UpdateInsertAffiliateGroup` procedure - only older groups retain values. Superseded by the JOIN pattern: `AffiliateAdmin.Users.FirstName/LastName` via `ManagerUserID`. Kept for backwards compatibility. |
| 4 | AccountManagerEmail | nvarchar(50) MASKED | YES | - | CODE-BACKED | LEGACY - denormalized account manager email. Dynamic data masking applied (`default()` function) for PII protection. Not populated by current procedures. Superseded by `AffiliateAdmin.Users.Email` via `ManagerUserID` JOIN. Many legacy rows contain empty strings (" ") rather than NULL. |
| 5 | AccountManagerImagePath | nvarchar(200) | YES | - | CODE-BACKED | LEGACY - URL or file path to the account manager's profile image for display in the admin portal. Not populated by current procedures. Many legacy rows contain empty strings (" ") rather than NULL. No masking applied (not PII). |
| 6 | ManagerUserID | uniqueidentifier | YES | - | VERIFIED | Azure AD Object ID of the assigned account manager. Implicit FK to `AffiliateAdmin.Users.UserObjectID`. Set via `UpdateInsertAffiliateGroup` for new and updated groups. Changes are audit-logged with old/new values. NULL for legacy groups and the sentinel group (ID=1). Resolved to manager name/email by LEFT JOINing to `AffiliateAdmin.Users` in procedures like `dbo.GetAffiliateById`, `dbo.GetAffiliateByAzureObjectId`, and `Affiliate.GetAffiliates`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManagerUserID | AffiliateAdmin.Users | Implicit FK | Links the group to its assigned account manager. Resolved via LEFT JOIN for display name/email in affiliate profile procedures. NULL for legacy or unassigned groups. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Affiliates | AffiliatesGroupsID | Implicit FK | Assigns each affiliate to exactly one group. The core organizational relationship. |
| AffiliateAdmin.AffiliateGroups_Viewers | AffiliatesGroupsID | Implicit FK (composite PK) | Controls which back-office users can view data for this group. Cascade-deleted when group is deleted. |
| AffiliateAdmin.UpdateInsertAffiliateGroup | @GroupID / @GroupName / @ManagerUserID | WRITER/MODIFIER | Creates new groups (INSERT) or updates existing groups (UPDATE name and/or ManagerUserID). |
| AffiliateAdmin.DeleteAffiliateGroups | AffiliatesGroupsID | DELETER | Deletes groups that have no affiliated members, with cascade to AffiliateGroups_Viewers. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. It is a leaf table.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.Users | Table | ManagerUserID references UserObjectID (implicit FK for account manager identity) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.AffiliateGroups_Viewers | Table | AffiliatesGroupsID is part of composite PK (access control junction) |
| dbo.tblaff_Affiliates | Table | AffiliatesGroupsID assigns affiliates to groups |
| AffiliateAdmin.UpdateInsertAffiliateGroup | Stored Procedure | WRITER/MODIFIER - creates and updates groups |
| AffiliateAdmin.DeleteAffiliateGroups | Stored Procedure | DELETER - removes groups (with protection) |
| AffiliateAdmin.GetAffiliateGroups | Stored Procedure | READER - lists all groups for admin dropdowns |
| AffiliateAdmin.GetAffiliateGroupByID | Stored Procedure | READER - returns single group + its viewer list |
| AffiliateAdmin.GetAffiliateGroupsList | Stored Procedure | READER - returns groups with filtering |
| AffiliateAdmin.GetAffiliateGroupsWithoutPermissions | Stored Procedure | READER - lists groups without user permission filtering |
| AffiliateAdmin.GetNumberOfAffiliatesInGroups | Stored Procedure | READER - counts affiliates per group |
| dbo.GetAffiliateById | Stored Procedure | READER - LEFT JOINs for group name + manager in affiliate profile |
| dbo.GetAffiliateByAzureObjectId | Stored Procedure | READER - LEFT JOINs for group name + manager in affiliate profile |
| Affiliate.GetAffiliates | Stored Procedure | READER - JOINs for group + manager info in affiliate listing |
| Affiliate.GetAffiliateInfoById | Stored Procedure | READER - JOINs for group info in affiliate detail |
| AffiliateAdmin.GetCountries | Stored Procedure | READER - JOINs for group name in country configuration |
| AffiliateAdmin.MoveAffiliatesToAffiliateGroup | Stored Procedure | MODIFIER - reassigns affiliates between groups |
| AffiliateAdmin.MoveAllAffiliatesToAffiliateGroup | Stored Procedure | MODIFIER - bulk reassigns all affiliates from one group to another |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AffiliateAdmin.AffiliatesGroups | CLUSTERED | AffiliatesGroupsID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AffiliateAdmin.AffiliatesGroups | PRIMARY KEY | Enforces uniqueness on AffiliatesGroupsID |
| IDENTITY(1,1) NOT FOR REPLICATION | IDENTITY | Auto-increment starting at 1, step 1. NOT FOR REPLICATION prevents identity reseeding during database replication - replicated rows keep their source identity values. |

**Dynamic Data Masking**: AccountManagerName and AccountManagerEmail use `MASKED WITH (FUNCTION = 'default()')`. Unprivileged users see masked values; only users with UNMASK permission see actual data.

---

## 8. Sample Queries

### 8.1 List all active groups with affiliate counts
```sql
SELECT ag.AffiliatesGroupsID, ag.AffiliatesGroupsName, COUNT(a.AffiliateID) AS AffiliateCount
FROM AffiliateAdmin.AffiliatesGroups ag WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliatesGroupsID = ag.AffiliatesGroupsID
WHERE ag.AffiliatesGroupsID > 1
GROUP BY ag.AffiliatesGroupsID, ag.AffiliatesGroupsName
ORDER BY AffiliateCount DESC
```

### 8.2 Get group details with resolved account manager name
```sql
SELECT ag.AffiliatesGroupsID, ag.AffiliatesGroupsName,
       u.FirstName + ' ' + u.LastName AS AccountManager, u.Email AS ManagerEmail
FROM AffiliateAdmin.AffiliatesGroups ag WITH (NOLOCK)
LEFT JOIN AffiliateAdmin.Users u WITH (NOLOCK) ON u.UserObjectID = ag.ManagerUserID
WHERE ag.AffiliatesGroupsID > 1
ORDER BY ag.AffiliatesGroupsName
```

### 8.3 Find groups with their viewer users (access control mapping)
```sql
SELECT ag.AffiliatesGroupsName, u.FirstName, u.LastName, u.Email
FROM AffiliateAdmin.AffiliatesGroups ag WITH (NOLOCK)
JOIN AffiliateAdmin.AffiliateGroups_Viewers agv WITH (NOLOCK) ON agv.AffiliatesGroupsID = ag.AffiliatesGroupsID
JOIN AffiliateAdmin.Users u WITH (NOLOCK) ON u.UserObjectID = agv.UserObjectID
ORDER BY ag.AffiliatesGroupsName, u.LastName
```

---

## 9. Atlassian Knowledge Sources

No dedicated Atlassian page found for AffiliateAdmin.AffiliatesGroups. The PART-5531 migration (February 2026) that created this table from legacy `dbo.tblaff_AffiliatesGroups` is referenced in procedure comments. PART-4500 (June-July 2025) created the initial AffiliateAdmin schema structure.

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-5531 (procedure comments) | Jira reference | Migration from legacy dbo.tblaff_AffiliatesGroups to AffiliateAdmin.AffiliatesGroups in February 2026 |
| PART-4500 (procedure comments) | Jira reference | Initial creation of AffiliateAdmin schema procedures (June-July 2025) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.AffiliatesGroups | Type: Table | Source: fiktivo/AffiliateAdmin/Tables/AffiliateAdmin.AffiliatesGroups.sql*
