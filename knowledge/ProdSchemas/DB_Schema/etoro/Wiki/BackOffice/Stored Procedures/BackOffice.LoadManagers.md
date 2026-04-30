# BackOffice.LoadManagers

> Returns all active Back Office managers (ManagerID > 0) with 14 profile columns including Calendly ID and access group type.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; returns all managers WHERE ManagerID > 0 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`LoadManagers` returns the full list of Back Office managers used to populate manager assignment dropdowns, team member lists, and authentication lookups throughout the BO system. It is the "get all managers" counterpart to `LoadManagerByUsername` (single manager lookup).

The WHERE clause `ManagerID > 0` excludes system/anonymous accounts that may use ID = 0 as a sentinel value.

The LEFT JOIN to `BackOffice.T_ManagerAccessGroupToConnectionStrings` adds `ManagerGroupType` - the access tier for each manager's group. Note that unlike `LoadManagerByUsername`, `LoadManagers` does NOT join `BackOffice.T_GroupsDictionary`, so the `GroupDescription` is not included.

The `CalendlyID` column (added later) links managers to their Calendly scheduling profiles for customer appointment booking integrations.

---

## 2. Business Logic

### 2.1 All Managers Lookup

**What**: Returns all manager records with ManagerID > 0, enriched with access group type.

**Rules**:
- `WHERE ManagerID > 0` - excludes system/sentinel accounts with ID 0 or negative
- LEFT JOIN `BackOffice.T_ManagerAccessGroupToConnectionStrings` on ManagerGroupID -> adds ManagerGroupType
- Returns 14 columns (same set as LoadManagerByUsername except no GroupDescription column)
- WITH (NOLOCK) on Manager; NOT NOLOCK on T_ManagerAccessGroupToConnectionStrings

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ManagerID | INT | NO | - | CODE-BACKED | Manager's unique numeric ID. ManagerID > 0 (system accounts excluded). |
| 2 | UserGroupID | INT | - | - | CODE-BACKED | Primary user group ID controlling feature access and customer segment visibility. |
| 3 | FirstName | NVARCHAR | - | - | CODE-BACKED | Manager first name. |
| 4 | LastName | NVARCHAR | - | - | CODE-BACKED | Manager last name. |
| 5 | UserName | NVARCHAR | - | - | CODE-BACKED | Manager login name (aliased from BMNG.Login). |
| 6 | Email | NVARCHAR | - | - | CODE-BACKED | Manager email for notifications. |
| 7 | IsEmailNotified | BIT | - | - | CODE-BACKED | Whether manager receives email notifications. |
| 8 | IsActive | BIT | - | - | CODE-BACKED | Whether manager account is active. Note: unlike LoadManagerByUsername, LoadManagers returns all managers regardless of IsActive status. |
| 9 | IsTeamLeader | BIT | - | - | CODE-BACKED | Whether manager is a team leader. |
| 10 | OverrideReplicaSettings | BIT | - | - | CODE-BACKED | Whether manager bypasses replica routing for real-time data. |
| 11 | IsCustomerManager | BIT | - | - | CODE-BACKED | Whether manager handles customer management tasks. |
| 12 | ManagerGroupID | INT | YES | - | CODE-BACKED | Access group ID. FK to T_GroupsDictionary and T_ManagerAccessGroupToConnectionStrings. |
| 13 | CalendlyID | NVARCHAR | YES | - | CODE-BACKED | Calendly scheduling profile ID for appointment booking. |
| 14 | ManagerGroupType | (from T_ManagerAccessGroupToConnectionStrings) | YES | - | CODE-BACKED | Access type/tier for the manager's group. NULL if ManagerGroupID not in the access group table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManagerID | BackOffice.Manager | Lookup | SELECT all managers WHERE ManagerID > 0 |
| ManagerGroupID | BackOffice.T_ManagerAccessGroupToConnectionStrings | Lookup (LEFT JOIN) | Adds ManagerGroupType |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.LoadManagers (procedure)
├── BackOffice.Manager (table) [SELECT all WHERE ManagerID > 0]
└── BackOffice.T_ManagerAccessGroupToConnectionStrings (table) [LEFT JOIN on ManagerGroupID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | SELECT all active managers (ManagerID > 0) |
| BackOffice.T_ManagerAccessGroupToConnectionStrings | Table | LEFT JOIN: adds ManagerGroupType |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | Called by BO UI/services to populate manager lists |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| WHERE ManagerID > 0 | Filter | Excludes system/sentinel accounts with ID = 0 |
| WITH (NOLOCK) on Manager only | Design | T_ManagerAccessGroupToConnectionStrings uses default lock; Manager uses NOLOCK |
| No IsActive filter | Design | Returns all managers including inactive ones (callers filter if needed) |

---

## 8. Sample Queries

### 8.1 Load all managers

```sql
EXEC [BackOffice].[LoadManagers];
-- Returns all managers with ManagerID > 0
```

### 8.2 Filter active managers with group name

```sql
SELECT
    BMNG.ManagerID,
    BMNG.FirstName + ' ' + BMNG.LastName AS FullName,
    BMNG.Login AS UserName,
    BMNG.UserGroupID,
    BMNG.IsActive,
    ag.ManagerGroupType
FROM BackOffice.Manager BMNG WITH (NOLOCK)
LEFT JOIN BackOffice.T_ManagerAccessGroupToConnectionStrings ag
    ON BMNG.ManagerGroupID = ag.ManagerGroupID
WHERE BMNG.ManagerID > 0 AND BMNG.IsActive = 1
ORDER BY BMNG.LastName, BMNG.FirstName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 8.5/10, Logic: 7.5/10, Relationships: 7.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.LoadManagers | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.LoadManagers.sql*
