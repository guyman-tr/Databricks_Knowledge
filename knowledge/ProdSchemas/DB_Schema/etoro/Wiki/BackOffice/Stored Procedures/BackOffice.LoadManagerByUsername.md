# BackOffice.LoadManagerByUsername

> Returns full manager profile (14 columns) for a given username via case-insensitive login match, joining Manager with GroupsDictionary and ManagerAccessGroupToConnectionStrings.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserName (manager login); returns single manager row or empty |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`LoadManagerByUsername` retrieves a single Back Office manager's full profile by login name. Created by Omar Lomsadze in July 2025, it is a more complete version of the older `LoadManagers` (which returns all managers). This SP is used when a service knows a manager's username and needs their full profile including group affiliation and access type.

The case-insensitive match (`LOWER(BMNG.Login) = LOWER(@UserName)`) ensures that login names like "john.smith" and "John.Smith" are treated as the same manager, which is important for services that receive usernames from different systems with inconsistent casing.

The join to `BackOffice.T_GroupsDictionary` adds the human-readable `GroupDescription` (the manager's group name as shown in the BO UI), and the join to `BackOffice.T_ManagerAccessGroupToConnectionStrings` adds the `ManagerGroupType` (the access tier/type for this manager's group).

A newer addition compared to `LoadManagers` is `CalendlyID` - a scheduling integration identifier linking Back Office managers to their Calendly booking profiles for customer appointment scheduling.

---

## 2. Business Logic

### 2.1 Case-Insensitive Manager Lookup

**What**: Finds a manager by login name with case-insensitive comparison, enriched with group metadata.

**Columns/Parameters Involved**: `@UserName`, `BackOffice.Manager.Login`

**Rules**:
- `WHERE LOWER(BMNG.Login) = LOWER(@UserName)` - case-insensitive login match
- LEFT JOIN `BackOffice.T_GroupsDictionary` on ManagerGroupID -> adds GroupDescription
- LEFT JOIN `BackOffice.T_ManagerAccessGroupToConnectionStrings` on ManagerGroupID -> adds ManagerGroupType
- If no manager matches: empty result set (no row)
- Both JOINs are LEFT: returns manager even if not in T_GroupsDictionary or T_ManagerAccessGroupToConnectionStrings

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName | NVARCHAR(255) | NO | - | CODE-BACKED | Manager login name to look up. Case-insensitive match against BackOffice.Manager.Login (LOWER applied to both). |

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ManagerID | INT | NO | - | CODE-BACKED | Manager's unique numeric ID. |
| 2 | UserGroupID | INT | - | - | CODE-BACKED | The manager's primary user group ID (determines which features and customer segments they can access). |
| 3 | FirstName | NVARCHAR | - | - | CODE-BACKED | Manager's first name. |
| 4 | LastName | NVARCHAR | - | - | CODE-BACKED | Manager's last name. |
| 5 | UserName | NVARCHAR | - | - | CODE-BACKED | Manager's login name (aliased from BMNG.Login). |
| 6 | Email | NVARCHAR | - | - | CODE-BACKED | Manager's email address for notifications. |
| 7 | CalendlyID | NVARCHAR | YES | - | CODE-BACKED | Manager's Calendly scheduling profile ID. Used for customer appointment booking integration. |
| 8 | IsEmailNotified | BIT | - | - | CODE-BACKED | Whether this manager receives email notifications for assigned customers/events. |
| 9 | IsActive | BIT | - | - | CODE-BACKED | Whether the manager account is active. Inactive managers cannot log in. |
| 10 | IsTeamLeader | BIT | - | - | CODE-BACKED | Whether this manager is a team leader (affects permissions and reporting hierarchy). |
| 11 | OverrideReplicaSettings | BIT | - | - | CODE-BACKED | Whether this manager's queries override replica routing settings (used for real-time data access). |
| 12 | IsCustomerManager | BIT | - | - | CODE-BACKED | Whether this manager handles customer management tasks. |
| 13 | ManagerGroupID | INT | YES | - | CODE-BACKED | The manager's access group ID. FK to BackOffice.T_GroupsDictionary and T_ManagerAccessGroupToConnectionStrings. |
| 14 | ManagerGroupName | NVARCHAR | YES | - | CODE-BACKED | Human-readable group name from BackOffice.T_GroupsDictionary.GroupDescription. NULL if ManagerGroupID not in T_GroupsDictionary. |
| 15 | ManagerGroupType | (from T_ManagerAccessGroupToConnectionStrings) | YES | - | CODE-BACKED | Access type classification for the manager's group. Determines which connection strings/databases the group can access. NULL if ManagerGroupID not in T_ManagerAccessGroupToConnectionStrings. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UserName | BackOffice.Manager | Lookup | WHERE LOWER(Login) = LOWER(@UserName) |
| ManagerGroupID | BackOffice.T_GroupsDictionary | Lookup (LEFT JOIN) | Adds GroupDescription as ManagerGroupName |
| ManagerGroupID | BackOffice.T_ManagerAccessGroupToConnectionStrings | Lookup (LEFT JOIN) | Adds ManagerGroupType |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.LoadManagerByUsername (procedure)
├── BackOffice.Manager (table) [SELECT - primary lookup]
├── BackOffice.T_GroupsDictionary (table) [LEFT JOIN on ManagerGroupID]
└── BackOffice.T_ManagerAccessGroupToConnectionStrings (table) [LEFT JOIN on ManagerGroupID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | Primary lookup: LOWER(Login) = LOWER(@UserName) |
| BackOffice.T_GroupsDictionary | Table | LEFT JOIN: adds GroupDescription as ManagerGroupName |
| BackOffice.T_ManagerAccessGroupToConnectionStrings | Table | LEFT JOIN: adds ManagerGroupType |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | Called by BO authentication/profile services when manager username is known |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| LOWER(BMNG.Login) = LOWER(@UserName) | Case-insensitive match | Prevents case-sensitivity issues across different callers |
| LEFT JOIN (both joins) | Design | Returns manager row even if not in group dictionary tables |
| WITH (NOLOCK) on all tables | Query hint | Dirty reads - in-flight manager updates may not be visible |

---

## 8. Sample Queries

### 8.1 Load manager profile by username

```sql
EXEC [BackOffice].[LoadManagerByUsername] @UserName = 'john.smith';
-- Returns manager profile including group name and access type
```

### 8.2 Equivalent direct query

```sql
SELECT
    BMNG.ManagerID, BMNG.UserGroupID,
    BMNG.FirstName, BMNG.LastName,
    BMNG.Login AS UserName, BMNG.Email,
    BMNG.CalendlyID, BMNG.IsEmailNotified,
    BMNG.IsActive, BMNG.IsTeamLeader,
    BMNG.OverrideReplicaSettings, BMNG.IsCustomerManager,
    BMNG.ManagerGroupID,
    BOGD.GroupDescription AS ManagerGroupName,
    ag.ManagerGroupType
FROM BackOffice.Manager BMNG WITH (NOLOCK)
LEFT JOIN BackOffice.T_GroupsDictionary BOGD WITH (NOLOCK)
    ON BMNG.ManagerGroupID = BOGD.ManagerGroupID
LEFT JOIN BackOffice.T_ManagerAccessGroupToConnectionStrings ag WITH (NOLOCK)
    ON BMNG.ManagerGroupID = ag.ManagerGroupID
WHERE LOWER(BMNG.Login) = LOWER('john.smith');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 8.5/10, Logic: 7.5/10, Relationships: 8.0/10, Sources: 5.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.LoadManagerByUsername | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.LoadManagerByUsername.sql*
