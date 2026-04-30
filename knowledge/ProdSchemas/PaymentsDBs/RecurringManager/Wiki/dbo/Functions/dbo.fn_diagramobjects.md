# dbo.fn_diagramobjects

> System scalar function that returns a bitmask indicating which SSMS database diagram infrastructure objects (table + procedures) are installed in the current database.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns: int (bitmask 0-255) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

fn_diagramobjects is the installation status checker for the SSMS database diagram infrastructure. It returns a bitmask integer where each bit represents the presence of one of the eight diagram-related objects. SSMS calls this function to determine whether the diagram feature is fully installed before attempting to use it.

This function exists because the diagram infrastructure consists of 8 interdependent objects (1 table + 7 procedures) that must all be present for SSMS diagrams to work correctly. If any are missing, SSMS prompts the user to install them. fn_diagramobjects provides the diagnostic check that drives this prompt.

The function uses OBJECT_ID() to check for the existence of each of the 8 diagram objects by their fully qualified name, then adds each object's bit value to a running total. A return value of 255 (all 8 bits set) indicates a complete installation.

---

## 2. Business Logic

### 2.1 Bitmask Installation Verification

**What**: Each diagram infrastructure object is assigned a unique power-of-2 value, and their combined presence is reported as a single bitmask integer.

**Columns/Parameters Involved**: N/A (no parameters)

**Rules**:
- Each object is checked via `OBJECT_ID(N'dbo.{objectname}')` - if non-NULL, the object exists
- Bitmask values: 1=sp_upgraddiagrams, 2=sysdiagrams (table), 4=sp_helpdiagrams, 8=sp_helpdiagramdefinition, 16=sp_creatediagram, 32=sp_renamediagram, 64=sp_alterdiagram, 128=sp_dropdiagram
- Return value of 255 means all 8 objects are installed (complete infrastructure)
- Return value of 0 means none are installed
- Any value between indicates partial installation

**Diagram**:
```
Bit  Value  Object
---  -----  ------
 0     1    sp_upgraddiagrams
 1     2    sysdiagrams (table)
 2     4    sp_helpdiagrams
 3     8    sp_helpdiagramdefinition
 4    16    sp_creatediagram
 5    32    sp_renamediagram
 6    64    sp_alterdiagram
 7   128    sp_dropdiagram
         -----
Full:  255  All installed
```

---

## 3. Data Overview

N/A for Function.

---

## 4. Elements

This function has no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | RETURN | int | NO | - | CODE-BACKED | Bitmask integer (0-255) indicating which diagram infrastructure objects exist. Each bit represents one object: 1=sp_upgraddiagrams, 2=sysdiagrams, 4=sp_helpdiagrams, 8=sp_helpdiagramdefinition, 16=sp_creatediagram, 32=sp_renamediagram, 64=sp_alterdiagram, 128=sp_dropdiagram. 255 = fully installed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (bit 0) | dbo.sp_upgraddiagrams | Reference (object_id) | Checks existence - value 1 in bitmask |
| (bit 1) | dbo.sysdiagrams | Reference (object_id) | Checks existence - value 2 in bitmask |
| (bit 2) | dbo.sp_helpdiagrams | Reference (object_id) | Checks existence - value 4 in bitmask |
| (bit 3) | dbo.sp_helpdiagramdefinition | Reference (object_id) | Checks existence - value 8 in bitmask |
| (bit 4) | dbo.sp_creatediagram | Reference (object_id) | Checks existence - value 16 in bitmask |
| (bit 5) | dbo.sp_renamediagram | Reference (object_id) | Checks existence - value 32 in bitmask |
| (bit 6) | dbo.sp_alterdiagram | Reference (object_id) | Checks existence - value 64 in bitmask |
| (bit 7) | dbo.sp_dropdiagram | Reference (object_id) | Checks existence - value 128 in bitmask |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by SSMS internally to check diagram infrastructure status.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.fn_diagramobjects (function)
├── dbo.sysdiagrams (table) - checks existence via object_id
├── dbo.sp_upgraddiagrams (procedure) - checks existence via object_id
├── dbo.sp_helpdiagrams (procedure) - checks existence via object_id
├── dbo.sp_helpdiagramdefinition (procedure) - checks existence via object_id
├── dbo.sp_creatediagram (procedure) - checks existence via object_id
├── dbo.sp_renamediagram (procedure) - checks existence via object_id
├── dbo.sp_alterdiagram (procedure) - checks existence via object_id
└── dbo.sp_dropdiagram (procedure) - checks existence via object_id
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.sysdiagrams | Table | Existence check via OBJECT_ID() |
| dbo.sp_upgraddiagrams | Stored Procedure | Existence check via OBJECT_ID() |
| dbo.sp_helpdiagrams | Stored Procedure | Existence check via OBJECT_ID() |
| dbo.sp_helpdiagramdefinition | Stored Procedure | Existence check via OBJECT_ID() |
| dbo.sp_creatediagram | Stored Procedure | Existence check via OBJECT_ID() |
| dbo.sp_renamediagram | Stored Procedure | Existence check via OBJECT_ID() |
| dbo.sp_alterdiagram | Stored Procedure | Existence check via OBJECT_ID() |
| dbo.sp_dropdiagram | Stored Procedure | Existence check via OBJECT_ID() |

### 6.2 Objects That Depend On This

No dependents found in the SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS N'dbo' | Execution Context | Runs under dbo context to ensure OBJECT_ID() can see all objects regardless of caller permissions |
| Deterministic | No | References system catalog via OBJECT_ID() which can change between calls |
| SCHEMABINDING | No | Not schema-bound |

---

## 8. Sample Queries

### 8.1 Check full installation status
```sql
SELECT dbo.fn_diagramobjects() AS InstalledBitmask
-- 255 = all 8 objects installed, 0 = none
```

### 8.2 Check individual objects using bitwise AND
```sql
SELECT
    CASE WHEN dbo.fn_diagramobjects() & 1 > 0 THEN 'YES' ELSE 'NO' END AS sp_upgraddiagrams,
    CASE WHEN dbo.fn_diagramobjects() & 2 > 0 THEN 'YES' ELSE 'NO' END AS sysdiagrams,
    CASE WHEN dbo.fn_diagramobjects() & 4 > 0 THEN 'YES' ELSE 'NO' END AS sp_helpdiagrams,
    CASE WHEN dbo.fn_diagramobjects() & 128 > 0 THEN 'YES' ELSE 'NO' END AS sp_dropdiagram
```

### 8.3 Quick yes/no check for full installation
```sql
SELECT CASE WHEN dbo.fn_diagramobjects() = 255 THEN 'Fully installed' ELSE 'Partially installed' END AS DiagramStatus
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.fn_diagramobjects | Type: Scalar Function | Source: RecurringManager/dbo/Functions/dbo.fn_diagramobjects.sql*
