# BackOffice.P_SetManagerGroup

> Assigns a manager to a specific access group by updating ManagerGroupID in BackOffice.Manager for the given ManagerID.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE BackOffice.Manager SET ManagerGroupID = @ManagerGroupID WHERE ManagerID = @ManagerID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.P_SetManagerGroup` assigns or reassigns a manager to a database access group. In the BackOffice segregation framework, each manager's session is routed to a specific SQL Server environment (staging real, staging remote, live, etc.) based on their ManagerGroupID. This procedure is the write endpoint for that assignment.

Use cases:
- Onboarding a new manager: assign them to the correct environment group after creation.
- Changing a manager's environment: move them from staging to live, or between staging tiers.
- Clearing a group assignment: set ManagerGroupID to NULL to remove routing (manager will have no environment until reassigned).

The complementary read procedures are `P_GetManagerGroup` (by ManagerID) and `P_GetManagersAndGroups` (all managers). The complementary procedure `P_SetManagerGroup` is the sole SQL-layer writer for the ManagerGroupID column in BackOffice.Manager.

Part of the back-office segregation framework (ticket 36240, May 2016).

---

## 2. Business Logic

### 2.1 Single-Column Group Assignment

**What**: Single UPDATE on BackOffice.Manager targeting the ManagerGroupID column for one manager.

**Rules**:
- `WHERE ManagerID = @ManagerID`: targets a single manager row. If ManagerID does not exist, 0 rows affected (no error raised).
- `SET ManagerGroupID = @ManagerGroupID`: direct assignment. Accepts NULL to clear the group assignment.
- No IsActive check: group can be assigned to inactive managers.
- No validation that @ManagerGroupID exists in T_GroupsDictionary: if an invalid GroupID is passed, the UPDATE succeeds and creates an orphan reference (no FK enforced in the procedure).
- No transaction wrapper: single-statement update is atomic by default.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ManagerID | int | NO | - | CODE-BACKED | ID of the manager to update. FK to BackOffice.Manager.ManagerID (PK). If no manager with this ID exists, 0 rows are affected (silent no-op). |
| 2 | @ManagerGroupID | int | YES | - | CODE-BACKED | The access group to assign this manager to. FK to BackOffice.T_GroupsDictionary.ManagerGroupID (not enforced in procedure). Known values: 1=Staging Real, 2=Staging Real Remote, 3=Staging Demo, 4=Live Real, 5=Live Demo. NULL clears the assignment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ManagerID | BackOffice.Manager | Writer | Updates ManagerGroupID for the specified manager |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice administration tools when configuring manager environment routing.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.P_SetManagerGroup (procedure)
+-- BackOffice.Manager (table) [UPDATE ManagerGroupID WHERE ManagerID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | UPDATE ManagerGroupID = @ManagerGroupID WHERE ManagerID = @ManagerID |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No FK validation performed within the procedure - callers must ensure @ManagerGroupID is a valid T_GroupsDictionary value.

---

## 8. Sample Queries

### 8.1 Assign a manager to the Live Real group

```sql
EXEC BackOffice.P_SetManagerGroup
    @ManagerID = 42,
    @ManagerGroupID = 4;  -- 4 = Live Real
```

### 8.2 Clear a manager's group assignment

```sql
EXEC BackOffice.P_SetManagerGroup
    @ManagerID = 42,
    @ManagerGroupID = NULL;
```

### 8.3 Verify the assignment (read back via getter)

```sql
EXEC BackOffice.P_GetManagerGroup @ManagerID = 42;
-- Returns ManagerGroupID for manager 42
```

### 8.4 Direct equivalent query

```sql
UPDATE BackOffice.Manager WITH (ROWLOCK)
SET ManagerGroupID = 4
WHERE ManagerID = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.P_SetManagerGroup | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.P_SetManagerGroup.sql*
