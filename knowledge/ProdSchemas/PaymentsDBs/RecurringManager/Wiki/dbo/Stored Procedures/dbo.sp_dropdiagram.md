# dbo.sp_dropdiagram

> System procedure that deletes an SSMS database diagram from dbo.sysdiagrams, with ownership validation to prevent unauthorized deletion.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Primary output: returns 0 on success, -1 on invalid args, -3 on not found or permission denied |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_dropdiagram handles the deletion of saved database diagrams from the SSMS diagram infrastructure. When a user deletes a diagram through the SSMS diagram explorer, this procedure is called to remove the record from dbo.sysdiagrams.

This procedure exists as part of the SSMS diagram lifecycle management. Without it, users could not remove unwanted diagrams. It enforces the same ownership model as the other diagram procedures - only the owner or db_owner can delete a diagram.

The procedure resolves the caller's identity, looks up the diagram by (principal_id, name), validates permissions, then deletes the matching record from dbo.sysdiagrams.

---

## 2. Business Logic

### 2.1 Ownership-Guarded Deletion

**What**: Diagrams can only be deleted by their owner or db_owner members.

**Columns/Parameters Involved**: `@diagramname`, `@owner_id`

**Rules**:
- Diagram is located by (principal_id, name) in dbo.sysdiagrams
- If the diagram does not exist OR the caller is neither the owner nor db_owner, returns -3
- Deletion is a hard DELETE - no soft-delete or recycle bin for diagrams

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname | sysname | NO | - | CODE-BACKED | Name of the diagram to delete. If NULL, raises 'Invalid value' and returns -1. Must match an existing diagram owned by @owner_id. |
| 2 | @owner_id | int | YES | NULL | CODE-BACKED | Database principal ID of the diagram owner. If NULL, defaults to the caller's DATABASE_PRINCIPAL_ID(). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @diagramname, @owner_id | dbo.sysdiagrams | DML (SELECT, DELETE) | Locates diagram by (principal_id, name), then deletes it |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.fn_diagramobjects | - | Reference (object_id) | Checks existence for installation verification (bitmask value 128) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_dropdiagram (procedure)
└── dbo.sysdiagrams (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.sysdiagrams | Table | SELECT to find diagram, DELETE to remove it |

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

### 8.1 List diagrams before deleting
```sql
EXEC dbo.sp_helpdiagrams
```

### 8.2 Delete a diagram (typically called by SSMS)
```sql
EXEC dbo.sp_dropdiagram @diagramname = 'OldDiagram', @owner_id = NULL
```

### 8.3 Verify deletion
```sql
SELECT COUNT(*) AS RemainingDiagrams FROM dbo.sysdiagrams WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_dropdiagram | Type: Stored Procedure | Source: RecurringManager/dbo/Stored Procedures/dbo.sp_dropdiagram.sql*
