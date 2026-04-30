# Dictionary.UserGroup

> Hierarchical organizational tree of BackOffice user groups (departments, teams, regional offices) used to assign permissions, route withdrawal approvals, manage affiliate relationships, and segment internal staff across the platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | UserGroupID (INT, manually assigned) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 3 (1 clustered PK + 1 unique NC on Name + 1 NC on ParentID) |

---

## 1. Business Meaning

Dictionary.UserGroup defines the organizational hierarchy for BackOffice internal users (managers, support agents, compliance staff, traders). Each group represents a department, team, or regional office, and groups can be nested via the ParentID self-reference to form a tree structure. This hierarchy drives permission inheritance, withdrawal approval routing, and affiliate-to-team assignment.

Without this table, the platform could not organize its BackOffice users into logical groups for permission management, approval workflows, or customer assignment. Withdrawal requests require multi-level approval routed through user groups. Managers belong to groups that determine their permission set and customer visibility.

The table is consumed by 30+ procedures across BackOffice, Billing, and Maintenance schemas. Key consumers include: BackOffice.WithdrawApprovalAdd/Get/Upsert (withdrawal approval routing), BackOffice.LoadManagers/LoadManagerByUsername (manager-to-group resolution), Maintenance.ManagerAdd/ManagerEdit (group assignment during manager provisioning), BackOffice.RedeemApprovalAdd (CopyTrading redeem approval), and BackOffice.CustomerSetAffiliateManager (affiliate assignment). The child table Dictionary.UserGroupToPermission maps group-level permissions.

---

## 2. Business Logic

### 2.1 Organizational Hierarchy (Self-Referencing Tree)

**What**: User groups form a parent-child tree representing the company's internal organizational structure.

**Columns/Parameters Involved**: `UserGroupID`, `Name`, `ParentID`

**Rules**:
- Root groups (ParentID = NULL) represent top-level departments: Administrators, Operations, Marketing, Trading, AML
- Child groups (ParentID → another UserGroupID) are sub-teams: Risk, Accounting, Sales/Support are children of Operations
- Third-level groups exist: Sales 1 and Sales 2 are children of Sales/Support, which is a child of Operations
- Regional offices (Local Offices/IBs) form a geographic sub-tree under Marketing with branches for Singapore, Brazil, Australia, India, etc.
- The self-referencing FK (FK_DUSG_DUSG) ensures referential integrity: every ParentID must point to an existing UserGroupID

**Diagram**:
```
UserGroup Hierarchy:
  Administrators (1)
  ├── AmitTest (14)
  └── AmitTest2 (15)
  Operations (2)
  ├── Risk (3)
  ├── Accounting (5)
  ├── Sales/Support (7)
  │   ├── Sales 1 (9)
  │   └── Sales 2 (10)
  ├── Account Management (8)
  │   ├── Account Management 1 (11)
  │   ├── Account Management 2 (12)
  │   └── Account Management 3 (13)
  ├── Support (20)
  ├── BackOffice (31)
  │   └── MimoOps (34)
  │       ├── MimoApps (35)
  │       └── Should delete (53)
  └── Training (32)
  Marketing (4)
  └── Local Offices/IBs (16)
      ├── Singapore (17)
      ├── Brazil (18)
      ├── Australia (19)
      ├── Premiere (21)
      ├── India/Dubai/German/Canada/China/USA/Uruguay/Turkey...
  Trading (6)
  AML (36)
```

### 2.2 Withdrawal Approval Routing

**What**: User groups control which teams must approve withdrawal requests before they are processed.

**Columns/Parameters Involved**: `UserGroupID` (linked to BackOffice.WithdrawApproval)

**Rules**:
- Each withdrawal may require approval from one or more user groups
- BackOffice.IsApprovedByAllUserGroups checks if all required groups have approved a withdrawal
- The hierarchical structure allows approval delegation — if Risk (3) approves, it covers the Operations (2) parent level
- BackOffice.GetUnapprovedWithdrawRequests filters by the current user's group to show only relevant pending requests

---

## 3. Data Overview

| UserGroupID | Name | ParentID | Meaning |
|---|---|---|---|
| 1 | Administrators | NULL | Top-level admin group with full platform access. Root of the admin organizational branch. |
| 2 | Operations | NULL | Umbrella department for all operational teams — Risk, Accounting, Sales/Support, BackOffice. Parent of most day-to-day operational groups. |
| 3 | Risk | 2 | Risk management team under Operations — handles fraud detection, AML alerts, and customer risk classification. Critical for withdrawal approval workflows. |
| 16 | Local Offices (IBs) | 4 | Regional introducing broker offices under Marketing — manages affiliate partnerships in specific geographies (Singapore, Brazil, Australia, etc.). |
| 36 | AML | NULL | Anti-Money Laundering team — independent top-level group for regulatory compliance and screening operations. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserGroupID | int | NO | - | CODE-BACKED | Unique identifier for the user group. Manually assigned, not auto-incrementing. Referenced by 30+ procedures for permission checks, approval routing, and manager assignment. Values range from 1-53 with gaps. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Display name of the group (e.g., "Administrators", "Risk", "Sales/Support"). Unique constraint (DGRP_NAME index) prevents duplicate group names. Used in BackOffice UI for group selection dropdowns and approval displays. |
| 3 | ParentID | int | YES | - | CODE-BACKED | Self-referencing FK to UserGroupID — points to this group's parent in the organizational hierarchy. NULL for root-level departments (Administrators, Operations, Marketing, Trading, AML). FK_DUSG_DUSG enforces referential integrity. Indexed (DGRP_PARENT) for efficient hierarchy traversal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParentID | Dictionary.UserGroup | Self-Reference/FK | Points to the parent group in the organizational hierarchy. FK_DUSG_DUSG enforces that every parent must be an existing group. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.UserGroupToPermission | UserGroupID | FK | Maps permissions to groups — each group gets a set of allowed operations |
| BackOffice.Manager | UserGroupID | Implicit | Each BackOffice manager belongs to a user group |
| BackOffice.Customer | UserGroupID | Implicit | Customers may be assigned to a group for sales/support routing |
| BackOffice.WithdrawApproval | UserGroupID | Implicit | Tracks which groups have approved/rejected withdrawal requests |
| BackOffice.RedeemApproval | UserGroupID | Implicit | Tracks group approvals for CopyTrading redeem operations |
| BackOffice.AffiliateToUserGroup | UserGroupID | FK | Maps affiliate partnerships to their managing user group |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.UserGroup (table)
└── Dictionary.UserGroup (self-reference via ParentID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.UserGroup | Table | Self-reference — ParentID FK points to own UserGroupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.UserGroupToPermission | Table | FK — group-to-permission mapping |
| BackOffice.WithdrawApprovalAdd | Stored Procedure | Routes approval to specific groups |
| BackOffice.WithdrawApprovalGet | Stored Procedure | Retrieves approval status by group |
| BackOffice.WithdrawApprovalUpsert | Stored Procedure | Updates approval records per group |
| BackOffice.IsApprovedByAllUserGroups | Stored Procedure | Checks multi-group approval completion |
| BackOffice.LoadManagers | Stored Procedure | Loads managers with group membership |
| Maintenance.ManagerAdd | Stored Procedure | Assigns new managers to groups |
| Maintenance.ManagerEdit | Stored Procedure | Changes manager group assignment |
| BackOffice.UserGroupAdd | Stored Procedure | Creates new user groups |
| BackOffice.GetRedeemDisplayData | Stored Procedure | Shows group context in redeem UI |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DGRP | CLUSTERED | UserGroupID ASC | - | - | Active |
| DGRP_NAME | NC UNIQUE | Name ASC | - | - | Active |
| DGRP_PARENT | NC | ParentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_DUSG_DUSG | FK | ParentID → Dictionary.UserGroup(UserGroupID) — self-referencing FK ensures hierarchy integrity |

---

## 8. Sample Queries

### 8.1 Show the full group hierarchy with parent names
```sql
SELECT  g.UserGroupID,
        g.Name AS GroupName,
        p.Name AS ParentGroupName,
        g.ParentID
FROM    [Dictionary].[UserGroup] g WITH (NOLOCK)
LEFT JOIN [Dictionary].[UserGroup] p WITH (NOLOCK)
        ON p.UserGroupID = g.ParentID
ORDER BY ISNULL(g.ParentID, 0), g.UserGroupID;
```

### 8.2 List root-level departments
```sql
SELECT  UserGroupID,
        Name
FROM    [Dictionary].[UserGroup] WITH (NOLOCK)
WHERE   ParentID IS NULL
ORDER BY UserGroupID;
```

### 8.3 Find all groups in a subtree (e.g., all under Operations)
```sql
;WITH GroupTree AS (
    SELECT UserGroupID, Name, ParentID, 0 AS Level
    FROM   [Dictionary].[UserGroup] WITH (NOLOCK)
    WHERE  UserGroupID = 2 -- Operations
    UNION ALL
    SELECT g.UserGroupID, g.Name, g.ParentID, t.Level + 1
    FROM   [Dictionary].[UserGroup] g WITH (NOLOCK)
    JOIN   GroupTree t ON t.UserGroupID = g.ParentID
)
SELECT  REPLICATE('  ', Level) + Name AS GroupHierarchy,
        UserGroupID,
        ParentID
FROM    GroupTree
ORDER BY Level, UserGroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.UserGroup | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.UserGroup.sql*
