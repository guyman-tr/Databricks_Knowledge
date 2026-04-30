# BackOffice.P_GetManagersAndGroups

> Returns the ManagerID and ManagerGroupID for every manager in the system, providing the full manager-to-group mapping table for connection routing configuration.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT ManagerID, ManagerGroupID FROM BackOffice.Manager |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.P_GetManagersAndGroups` returns the complete mapping of every manager to their assigned access group. Unlike `P_GetManagerGroup` (which looks up one manager's group by ManagerID) or `P_GetManagerId` (which resolves a login name to ID), this procedure dumps the entire manager-to-group table in one call. It is used when the application needs to load all group assignments at once - for example, when building a routing table at startup or when displaying all managers with their environment assignments in an admin interface.

Part of the back-office segregation framework (ticket 36240, May 2016). Returns ALL managers including inactive ones (no IsActive filter).

---

## 2. Business Logic

### 2.1 Bulk Group Assignment Dump

**What**: Returns full ManagerID -> ManagerGroupID mapping for all managers, including inactive.

**Rules**:
- No parameters. No filtering.
- Includes all managers regardless of IsActive status.
- ManagerGroupID may be NULL for managers not assigned to a group.
- Callers use this to build in-memory routing maps rather than making per-manager lookups at runtime.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no input parameters. Returns two columns from BackOffice.Manager:

| # | Output Column | Type | Confidence | Description |
|---|--------------|------|------------|-------------|
| 1 | ManagerID | int | CODE-BACKED | Unique manager identifier. PK of BackOffice.Manager. |
| 2 | ManagerGroupID | int | CODE-BACKED | The access group this manager belongs to. FK to BackOffice.T_GroupsDictionary. May be NULL for unassigned managers. Determines which DB connection strings are used for this manager's session. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | BackOffice.Manager | Reader | Returns ManagerID and ManagerGroupID for all managers |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice application for bulk group assignment loading.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.P_GetManagersAndGroups (procedure)
+-- BackOffice.Manager (table) [SELECT source]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | SELECT ManagerID, ManagerGroupID (all rows, no filter) |

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

### 8.1 Get all manager-to-group assignments

```sql
EXEC BackOffice.P_GetManagersAndGroups;
```

### 8.2 Get assignments with group names (direct query equivalent)

```sql
SELECT m.ManagerID, m.Login, m.ManagerGroupID, g.GroupDescription
FROM BackOffice.Manager m WITH (NOLOCK)
LEFT JOIN BackOffice.T_GroupsDictionary g WITH (NOLOCK) ON g.ManagerGroupID = m.ManagerGroupID
WHERE m.IsActive = 1
ORDER BY g.GroupDescription, m.Login;
```

### 8.3 Find managers with no group assignment

```sql
SELECT ManagerID, Login, FirstName + ' ' + LastName AS FullName
FROM BackOffice.Manager WITH (NOLOCK)
WHERE ManagerGroupID IS NULL AND IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.P_GetManagersAndGroups | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.P_GetManagersAndGroups.sql*
