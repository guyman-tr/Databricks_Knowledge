# BackOffice.P_GetManagerGroups

> Returns all manager access group definitions (ID + description) from the groups dictionary, used to populate group selection dropdowns in the BackOffice UI.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT ManagerGroupID, GroupDescription FROM BackOffice.T_GroupsDictionary |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.P_GetManagerGroups` returns the complete list of manager access groups with their human-readable names. It is used to populate group selection controls in the BackOffice administration UI - for example, when assigning a manager to a group, or when configuring access group connection strings. The table has 9 rows (groups 1-6 and 9 in production).

Part of the back-office segregation framework (ticket 36240, May 2016) that introduced group-based DB connection routing. These thin wrapper procedures provide a controlled interface to the underlying tables without requiring application code to access tables directly.

---

## 2. Business Logic

### 2.1 Static Dictionary Read

**What**: Returns all rows from T_GroupsDictionary with no filtering. Static configuration data that rarely changes.

**Rules**:
- No parameters. Returns all rows.
- Result: ManagerGroupID (int) + GroupDescription (varchar). See BackOffice.T_GroupsDictionary for full value mapping.
- Groups: 1=Staging Real, 2=Staging Real Remote, 3=Integration Real Remote, 4=Staging Real Russia Limited, 5=Automation Real, 6=Automation Real Remote, 9=Ukraine-ReadWrite.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no input parameters. Returns all rows from BackOffice.T_GroupsDictionary:

| # | Output Column | Type | Confidence | Description |
|---|--------------|------|------------|-------------|
| 1 | ManagerGroupID | int | CODE-BACKED | Group identifier. PK of T_GroupsDictionary. Used as FK in BackOffice.Manager.ManagerGroupID and T_ManagerAccessGroupToConnectionStrings. |
| 2 | GroupDescription | varchar | CODE-BACKED | Human-readable group name: "Staging Real", "Staging Real Remote", "Automation Real", etc. Displayed in BackOffice admin UI for group assignment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | BackOffice.T_GroupsDictionary | Reader | Returns all group definitions |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice admin UI for group selection population.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.P_GetManagerGroups (procedure)
+-- BackOffice.T_GroupsDictionary (table) [SELECT source]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.T_GroupsDictionary | Table | SELECT all rows (ManagerGroupID, GroupDescription) |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get all manager groups

```sql
EXEC BackOffice.P_GetManagerGroups;
-- Returns: ManagerGroupID, GroupDescription for all 9 groups
```

### 8.2 Direct equivalent query

```sql
SELECT ManagerGroupID, GroupDescription
FROM BackOffice.T_GroupsDictionary WITH (NOLOCK)
ORDER BY ManagerGroupID;
```

### 8.3 Count managers per group

```sql
SELECT g.ManagerGroupID, g.GroupDescription, COUNT(m.ManagerID) AS ManagerCount
FROM BackOffice.T_GroupsDictionary g WITH (NOLOCK)
LEFT JOIN BackOffice.Manager m WITH (NOLOCK) ON m.ManagerGroupID = g.ManagerGroupID AND m.IsActive = 1
GROUP BY g.ManagerGroupID, g.GroupDescription
ORDER BY g.ManagerGroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.P_GetManagerGroups | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.P_GetManagerGroups.sql*
