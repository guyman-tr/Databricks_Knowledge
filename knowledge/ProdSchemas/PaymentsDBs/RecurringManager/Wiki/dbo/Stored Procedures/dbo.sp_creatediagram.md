# dbo.sp_creatediagram

> System procedure that creates a new SSMS database diagram by inserting a named binary definition into dbo.sysdiagrams, with duplicate name checking per owner.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Primary output: returns new diagram_id (@@IDENTITY) on success, -1 on invalid args, -2 on duplicate name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_creatediagram handles the "save new diagram" operation in SSMS. When a user creates a new database diagram in the visual designer and saves it for the first time, SSMS calls this procedure to persist the binary layout data with a user-chosen name.

This procedure exists as part of the SSMS diagram infrastructure. Without it, new database diagrams could not be saved. It validates that the diagram name is unique for the owning principal, then inserts the record into dbo.sysdiagrams.

The procedure validates inputs, resolves ownership (defaulting to the caller, with db_owner able to create on behalf of others), checks for duplicate names under the resolved owner, then inserts the diagram record. It returns the new diagram_id (via @@IDENTITY) for SSMS to track the diagram going forward.

---

## 2. Business Logic

### 2.1 Ownership Assignment and Duplicate Prevention

**What**: New diagrams are assigned to the calling user by default, with db_owner able to create diagrams on behalf of other users, and duplicate names prevented per owner.

**Columns/Parameters Involved**: `@diagramname`, `@owner_id`, `@version`, `@definition`

**Rules**:
- If @owner_id is NULL, the diagram is owned by the caller (DATABASE_PRINCIPAL_ID)
- If @owner_id differs from the caller, only db_owner members can proceed (otherwise returns -1)
- Duplicate names per owner are rejected with error 'The name is already used' (returns -2)
- The UK_principal_name constraint on sysdiagrams enforces uniqueness at the database level

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname | sysname | NO | - | CODE-BACKED | Name for the new diagram. Must be unique among diagrams owned by the same principal. If NULL, raises 'E_INVALIDARG' and returns -1. |
| 2 | @owner_id | int | YES | NULL | CODE-BACKED | Database principal ID to own the new diagram. If NULL, defaults to the caller's DATABASE_PRINCIPAL_ID(). Non-db_owner callers cannot create diagrams for other users. |
| 3 | @version | int | NO | - | CODE-BACKED | Diagram format version number. If NULL, raises 'E_INVALIDARG' and returns -1. Stored as the initial version in sysdiagrams. |
| 4 | @definition | varbinary(max) | NO | - | CODE-BACKED | Binary-serialized diagram layout data from the SSMS diagram designer. Contains table positions, relationship lines, zoom level, and display settings. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @diagramname, @owner_id | dbo.sysdiagrams | DML (SELECT, INSERT) | Checks for duplicate name, then inserts the new diagram record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.fn_diagramobjects | - | Reference (object_id) | Checks existence for installation verification (bitmask value 16) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_creatediagram (procedure)
└── dbo.sysdiagrams (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.sysdiagrams | Table | SELECT to check duplicates, INSERT to create new diagram |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.fn_diagramobjects | Function | Checks existence via object_id() |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS 'dbo' | Execution Context | Runs under dbo context for consistent permission behavior |

---

## 8. Sample Queries

### 8.1 List existing diagrams before creating
```sql
EXEC dbo.sp_helpdiagrams
```

### 8.2 Create a new diagram (typically called by SSMS)
```sql
EXEC dbo.sp_creatediagram
    @diagramname = 'RecurringPaymentFlow',
    @owner_id = NULL,
    @version = 1,
    @definition = 0x -- binary data from SSMS
```

### 8.3 Verify the diagram was created
```sql
SELECT diagram_id, name, principal_id, version
FROM dbo.sysdiagrams WITH (NOLOCK)
WHERE name = 'RecurringPaymentFlow'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.3/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_creatediagram | Type: Stored Procedure | Source: RecurringManager/dbo/Stored Procedures/dbo.sp_creatediagram.sql*
