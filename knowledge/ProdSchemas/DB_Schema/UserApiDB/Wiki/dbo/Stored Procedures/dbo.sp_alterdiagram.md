# dbo.sp_alterdiagram

> Standard SQL Server procedure for modifying an existing database diagram in dbo.sysdiagrams.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @diagramname + @version + @definition (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Standard SQL Server diagram infrastructure procedure. Updates an existing diagram's version and binary definition in dbo.sysdiagrams. Validates ownership (owner or db_owner). EXECUTE AS 'dbo'.

---

## 2. Business Logic

Ownership check + UPDATE on sysdiagrams.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname | sysname (IN) | NO | - | CODE-BACKED | Diagram to modify. |
| 2 | @owner_id | int (IN) | YES | NULL | CODE-BACKED | Owner principal. NULL = current user. |
| 3 | @version | int (IN) | NO | - | CODE-BACKED | New diagram version. |
| 4 | @definition | varbinary(max) (IN) | NO | - | CODE-BACKED | New diagram binary data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.sysdiagrams | UPDATE | Modifies diagram |

### 5.2 Referenced By (other objects point to this)

SSMS diagram designer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_alterdiagram (procedure)
  +-- dbo.sysdiagrams (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.sysdiagrams | Table | UPDATE |

### 6.2 Objects That Depend On This

SSMS.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

EXECUTE AS 'dbo'.

---

## 8. Sample Queries

### 8.1 Alter diagram (SSMS internal)
```sql
-- Called internally by SSMS diagram designer
EXEC dbo.sp_alterdiagram @diagramname = 'MyDiagram', @version = 2, @definition = 0x0102
```

### 8.2 List existing diagrams
```sql
EXEC dbo.sp_helpdiagrams
```

### 8.3 Check if diagrams exist
```sql
SELECT dbo.fn_diagramobjects()
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: dbo.sp_alterdiagram | Type: Stored Procedure | Source: UserApiDB/UserApiDB/dbo/Stored Procedures/dbo.sp_alterdiagram.sql*
