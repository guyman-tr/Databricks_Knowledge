# BackOffice.UserGroupAdd

> Inserts a new user group into Dictionary.UserGroup using manual MAX+1 ID assignment; no IDENTITY column on the target table.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Name - the group name to add |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UserGroupAdd` is an administrative SP for creating new entries in the `Dictionary.UserGroup` lookup table. User groups are used to categorize back-office staff and managers into organizational units for access control, assignment, and reporting. Groups can be hierarchical (via ParentID), allowing tree-structured organization of management teams.

The SP implements a manual MAX+1 ID assignment: it reads `MAX(UserGroupID)+1` from the table and uses that as the new ID. This means the dictionary table does not use an IDENTITY column for this key. The pattern is safe only for low-frequency admin operations (race conditions are theoretically possible but acceptable given the rarity of concurrent group additions).

---

## 2. Business Logic

### 2.1 Manual ID Assignment and Insert

**What**: Assigns the next available UserGroupID (MAX+1) and inserts the new group record.

**Columns/Parameters Involved**: `@Name`, `@ParentID`, `Dictionary.UserGroup.UserGroupID`

**Rules**:
- `@UserGroupID = MAX(UserGroupID) + 1` from Dictionary.UserGroup - no concurrency control.
- Inserts (UserGroupID, Name, ParentID) directly.
- No validation of @ParentID existence (no FK check within the SP; the table may enforce it via FK constraint).
- RETURN 0 on success.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Name | varchar(50) | NO | - | CODE-BACKED | The name of the new user group (maps to Dictionary.UserGroup.Name). Max 50 characters. |
| 2 | @ParentID | int | NO | - | CODE-BACKED | Parent group ID for hierarchical grouping (maps to Dictionary.UserGroup.ParentID). Pass NULL or a root GroupID for top-level groups; pass an existing GroupID for child groups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Name, @ParentID | Dictionary.UserGroup | INSERT target + SELECT MAX | Creates new group record; reads MAX(ID) for manual key |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No direct callers found in BackOffice SPs. | - | - | Called from back-office administration tools for user group management. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UserGroupAdd (procedure)
+-- Dictionary.UserGroup (table) [SELECT MAX + INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.UserGroup | Table | SELECT MAX(UserGroupID) for manual ID; INSERT new group record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from admin/configuration tooling. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Manual MAX+1 ID assignment has a theoretical race condition for concurrent calls. Safe for low-frequency admin use only.
- SET NOCOUNT ON.
- RETURN 0 on success (no error return codes).

---

## 8. Sample Queries

### 8.1 Add a new user group

```sql
EXEC BackOffice.UserGroupAdd
    @Name     = 'EU Compliance Team',
    @ParentID = 5;   -- parent group ID
SELECT MAX(UserGroupID) AS NewGroupID FROM Dictionary.UserGroup WITH (NOLOCK);
```

### 8.2 View existing user groups

```sql
SELECT UserGroupID, Name, ParentID
FROM Dictionary.UserGroup WITH (NOLOCK)
ORDER BY ParentID, Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UserGroupAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UserGroupAdd.sql*
