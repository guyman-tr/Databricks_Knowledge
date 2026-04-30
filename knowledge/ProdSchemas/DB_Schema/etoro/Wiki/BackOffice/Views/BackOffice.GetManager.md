# BackOffice.GetManager

> Returns all currently active BackOffice staff members with their department name resolved, serving as the standard lookup for active managers used by documents and TnC procedures.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | ManagerID - from BackOffice.Manager |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.GetManager` is the operational lookup view for all currently active eToro back-office staff. It wraps `BackOffice.Manager` (filtered to `IsActive=1`) and joins to `Dictionary.UserGroup` to resolve the department name, providing a clean, ready-to-use result set without needing callers to perform the UserGroupID-to-name resolution themselves.

This view exists to decouple consumers from the underlying Manager table structure. Stored procedures that need to locate a manager by login or reference the group name use this view instead of querying BackOffice.Manager directly. It also enforces the implicit rule that only active managers should be surfaced - inactive/offboarded staff are automatically excluded.

Data flows from `BackOffice.Manager` (maintained by HR onboarding/offboarding processes) and `Dictionary.UserGroup` (a static configuration table). The view is used by `BackOffice.InsertDocument` and `BackOffice.InsertTncDocument` as a source to validate or resolve manager records when attaching documents to TnC flows.

---

## 2. Business Logic

### 2.1 Active Manager Filter

**What**: Only active back-office staff are returned. Deactivated managers (offboarded employees) are silently excluded.

**Columns/Parameters Involved**: `IsActive` (from BackOffice.Manager, not in output), `ManagerID`

**Rules**:
- `WHERE BMNG.IsActive = 1` - only managers with active status are included
- Managers set to IsActive=0 upon offboarding are completely invisible to consumers of this view
- The Password column is included in the output; consumers should restrict access to this view appropriately

**Diagram**:
```
BackOffice.Manager (all staff, including historical)
         |
    WHERE IsActive = 1
         |
         v
BackOffice.GetManager (active staff only)
         + UserGroupName resolved from Dictionary.UserGroup
```

### 2.2 Department Name Resolution

**What**: Translates the numeric UserGroupID into a human-readable department name via a direct join to `Dictionary.UserGroup`.

**Columns/Parameters Involved**: `UserGroupID`, `UserGroupName`

**Rules**:
- JOIN is implicit (old-style comma syntax): `WHERE BMNG.UserGroupID = DGRP.UserGroupID` - effectively an INNER JOIN
- Any Manager with a UserGroupID not present in Dictionary.UserGroup would be silently excluded (INNER JOIN behavior)
- The UserGroup hierarchy (ParentID) is not surfaced in this view - only the direct group name

---

## 3. Data Overview

| ManagerID | UserGroupID | UserGroupName | ManagerName | Login |
|-----------|-------------|---------------|-------------|-------|
| 14 | 1 | Administrators | Avi Sela | avi |
| 16 | 1 | Administrators | Yonatan Dayan | yonash |
| 18 | 8 | Account Management | Tom Rozenvasser | tomr |
| 22 | 1 | Administrators | David Virster | david |
| 27 | 1 | Administrators | Valeria Lerner | Valeria |

*Row meanings*: Each row represents one active eToro back-office employee. UserGroupName reveals their department - Administrators have full platform access while Account Management handles customer relationship workflows. Login is the short username used to authenticate into the BackOffice web application.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ManagerID | INT | NO | - | CODE-BACKED | Unique identifier for the back-office staff member. Primary key from BackOffice.Manager. Referenced by audit trail columns in BackOffice.Customer, BackOffice.Task, BackOffice.WithdrawApproval, and other tables that track which manager performed an action. |
| 2 | UserGroupID | INT | NO | - | CODE-BACKED | Department/role group identifier. FK to Dictionary.UserGroup. Values: 1=Administrators, 2=Operations, 3=Risk, 4=Marketing, 5=Accounting, 6=Trading, 7=Sales/Support, 8=Account Management, 20=Support, 31=BackOffice, 36=AML, plus regional IB offices (16-33). Used to scope permissions and filter managers by team. |
| 3 | UserGroupName | NVARCHAR (from Dictionary.UserGroup.Name) | NO | - | VERIFIED | Human-readable department name for this manager's UserGroup. Resolved by joining Dictionary.UserGroup on UserGroupID. Examples: "Administrators", "Account Management", "Risk", "AML". Eliminates the need for callers to join Dictionary.UserGroup separately. |
| 4 | ManagerName | NVARCHAR (computed) | - | - | CODE-BACKED | Full display name of the manager, computed as `BMNG.FirstName + ' ' + BMNG.LastName`. Used for display in BackOffice UI lists, document attribution, and reports. Example: "Avi Sela". |
| 5 | Login | NVARCHAR (from BackOffice.Manager.Login) | NO | - | CODE-BACKED | Short username used by the manager to authenticate into the BackOffice system. Example: "avi", "tomr". Used by BackOffice.LogIn procedure to identify the manager during authentication. |
| 6 | Password | NVARCHAR (from BackOffice.Manager.Password) | YES | - | CODE-BACKED | Hashed/stored password credential for BackOffice authentication. Included in this view's output; access should be restricted to authorized consumers only. From BackOffice.Manager.Password. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManagerID, Login, Password | BackOffice.Manager | Source (Filter: IsActive=1) | Base table for all manager identity and credential data. Only active rows are included. |
| UserGroupID | Dictionary.UserGroup | Lookup (INNER JOIN) | Resolves department code to human-readable group name. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.InsertDocument | BackOffice.GetManager | READER | Looks up manager data when inserting a document record. |
| BackOffice.InsertTncDocument | BackOffice.GetManager | READER | Looks up manager data when inserting a TnC document. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetManager (view)
├── BackOffice.Manager (table)
└── Dictionary.UserGroup (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | FROM clause (alias BMNG) - primary data source, filtered to IsActive=1 |
| Dictionary.UserGroup | Table | FROM clause (alias DGRP) - joined on UserGroupID to resolve department name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.InsertDocument | Stored Procedure | READER - queries view to resolve/validate manager records for document insertion |
| BackOffice.InsertTncDocument | Stored Procedure | READER - queries view to resolve/validate manager records for TnC document insertion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Note: WHERE clause enforces `IsActive=1` filter and `UserGroupID` match (implicit INNER JOIN).

---

## 8. Sample Queries

### 8.1 Find all managers in a specific department

```sql
SELECT ManagerID, ManagerName, Login
FROM BackOffice.GetManager WITH (NOLOCK)
WHERE UserGroupName = 'Account Management'
ORDER BY ManagerName
```

### 8.2 Look up a manager by login name

```sql
SELECT ManagerID, ManagerName, UserGroupName
FROM BackOffice.GetManager WITH (NOLOCK)
WHERE Login = 'tomr'
```

### 8.3 Count active managers per department

```sql
SELECT UserGroupName, UserGroupID, COUNT(*) AS ActiveManagers
FROM BackOffice.GetManager WITH (NOLOCK)
GROUP BY UserGroupName, UserGroupID
ORDER BY ActiveManagers DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetManager | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetManager.sql*
