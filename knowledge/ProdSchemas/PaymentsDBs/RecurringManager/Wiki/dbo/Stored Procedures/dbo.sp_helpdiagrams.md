# dbo.sp_helpdiagrams

> System procedure that lists SSMS database diagrams accessible to the current user, returning diagram metadata (name, ID, owner) for the SSMS diagram explorer.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Primary output: result set with Database, Name, ID, Owner, OwnerID columns |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_helpdiagrams is the "list diagrams" procedure in the SSMS diagram infrastructure. It populates the diagram explorer panel in SSMS, showing all diagrams the current user has access to - their own diagrams plus (for db_owner members) all diagrams in the database.

This procedure exists to provide discovery of saved diagrams. Without it, users would not know which diagrams exist or could not navigate to them in SSMS. It respects the ownership model by filtering results based on the caller's role.

The procedure resolves the caller's identity and db_owner membership, then queries dbo.sysdiagrams with ownership-based filtering. db_owner sees all diagrams; regular users see only their own. Optional parameters allow filtering by specific diagram name or owner.

---

## 2. Business Logic

### 2.1 Role-Based Diagram Visibility

**What**: db_owner members see all diagrams; regular users see only diagrams they own.

**Columns/Parameters Involved**: `@diagramname`, `@owner_id`

**Rules**:
- db_owner (IS_MEMBER('db_owner') = 1) bypasses ownership filtering and sees all diagrams
- Non-db_owner users see only diagrams where USER_NAME(principal_id) matches their username
- Optional @diagramname filter narrows results to a specific diagram
- Optional @owner_id filter narrows results to a specific owner
- Results ordered by Owner, OwnerID, Name

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname | sysname | YES | NULL | CODE-BACKED | Optional filter for a specific diagram name. If NULL, all accessible diagrams are returned. |
| 2 | @owner_id | int | YES | NULL | CODE-BACKED | Optional filter for a specific owner's principal ID. If NULL, diagrams from all accessible owners are returned. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.sysdiagrams | DML (SELECT) | Queries diagram metadata with ownership-based filtering |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.fn_diagramobjects | - | Reference (object_id) | Checks existence for installation verification (bitmask value 4) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_helpdiagrams (procedure)
└── dbo.sysdiagrams (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.sysdiagrams | Table | SELECT to list diagrams with ownership filter |

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
| EXECUTE AS N'dbo' | Execution Context | Runs under dbo context for consistent permission behavior |

---

## 8. Sample Queries

### 8.1 List all diagrams accessible to current user
```sql
EXEC dbo.sp_helpdiagrams
```

### 8.2 Check if a specific diagram exists
```sql
EXEC dbo.sp_helpdiagrams @diagramname = 'RecurringPaymentFlow'
```

### 8.3 Direct query for diagram count
```sql
SELECT COUNT(*) AS DiagramCount FROM dbo.sysdiagrams WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_helpdiagrams | Type: Stored Procedure | Source: RecurringManager/dbo/Stored Procedures/dbo.sp_helpdiagrams.sql*
