# BackOffice.P_GetManagerGroup

> Returns the ManagerGroupID for a specified manager, enabling the application to determine which database environment group the manager belongs to.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT ManagerGroupID FROM BackOffice.Manager WHERE ManagerID = @ManagerID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.P_GetManagerGroup` is a lookup procedure that resolves a manager's group assignment from the BackOffice.Manager table. After authenticating a manager, the application needs to know which access group they belong to in order to route their database queries to the correct connection string (via `BackOffice.T_ManagerAccessGroupToConnectionStrings`). This procedure provides that single value.

The `P_` prefix is part of the back-office segregation naming convention introduced in ticket 36240 (May 2016) when the group-based connection routing was implemented. These procedures are thin wrappers exposing specific columns to application code without requiring direct table access.

---

## 2. Business Logic

### 2.1 Manager-to-Group Resolution

**What**: Single-column lookup - maps ManagerID to ManagerGroupID for connection routing.

**Columns/Parameters Involved**: `@ManagerID`, `BackOffice.Manager.ManagerGroupID`

**Rules**:
- Returns 0 or 1 rows (ManagerID is PK in BackOffice.Manager, so at most 1 row).
- If ManagerID does not exist: returns empty result set (0 rows) - no error raised.
- ManagerGroupID values: 1=Staging Real, 2=Staging Real Remote, 3=Integration Real Remote, 4=Staging Real Russia Limited, 5=Automation Real, 6=Automation Real Remote, 9=Ukraine-ReadWrite (from T_GroupsDictionary).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ManagerID | int | NO | - | CODE-BACKED | ID of the manager to look up. FK to BackOffice.Manager.ManagerID. The ManagerID is typically obtained from the session after authentication. |

Output: single column `ManagerGroupID` (int) - the group this manager belongs to. See BackOffice.T_GroupsDictionary for group descriptions and BackOffice.T_ManagerAccessGroupToConnectionStrings for associated connection strings.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ManagerID | BackOffice.Manager | Reader | Reads ManagerGroupID for the specified manager |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice application during session initialization to determine connection routing.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.P_GetManagerGroup (procedure)
+-- BackOffice.Manager (table) [SELECT target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | SELECT ManagerGroupID WHERE ManagerID = @ManagerID |

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

### 8.1 Get the group for a specific manager

```sql
EXEC BackOffice.P_GetManagerGroup @ManagerID = 701;
-- Returns: ManagerGroupID (e.g., 1 = Staging Real)
```

### 8.2 Resolve group name after getting the group ID

```sql
DECLARE @GroupID INT;
SELECT @GroupID = ManagerGroupID FROM BackOffice.Manager WITH (NOLOCK) WHERE ManagerID = 701;
SELECT GroupDescription FROM BackOffice.T_GroupsDictionary WITH (NOLOCK) WHERE ManagerGroupID = @GroupID;
```

### 8.3 Get all managers with their group descriptions

```sql
SELECT m.ManagerID, m.Login, g.GroupDescription
FROM BackOffice.Manager m WITH (NOLOCK)
JOIN BackOffice.T_GroupsDictionary g WITH (NOLOCK) ON g.ManagerGroupID = m.ManagerGroupID
WHERE m.IsActive = 1
ORDER BY g.GroupDescription, m.Login;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.P_GetManagerGroup | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.P_GetManagerGroup.sql*
