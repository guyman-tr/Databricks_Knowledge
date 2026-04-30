# dbo.sp_upgraddiagrams

> System procedure that creates the dbo.sysdiagrams table if it does not exist and migrates any legacy diagrams from the deprecated dbo.dtproperties format to the modern sysdiagrams format.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Primary output: returns 0 (table exists), 1 (table created, no legacy data), or 2 (table created with migrated data) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_upgraddiagrams is the initialization and migration procedure for the SSMS diagram infrastructure. It ensures the dbo.sysdiagrams table exists and migrates any diagrams stored in the deprecated dbo.dtproperties format (from older SQL Server/SSMS versions) to the modern sysdiagrams schema.

This procedure exists to handle the upgrade path from legacy diagram storage. Older versions of SQL Server stored SSMS diagrams in a table called dtproperties. When upgrading to a newer version or when first enabling diagram support, this procedure creates the sysdiagrams table and migrates any legacy data. It is idempotent - if sysdiagrams already exists, it returns immediately.

The procedure is called by SSMS when it first attempts to use database diagrams and finds no sysdiagrams table. It creates the table with the standard schema (name, principal_id, diagram_id, version, definition) and the UK_principal_name unique constraint, then migrates legacy dtproperties data if present.

---

## 2. Business Logic

### 2.1 Idempotent Infrastructure Setup with Legacy Migration

**What**: Creates the diagram infrastructure table if missing and migrates data from the deprecated storage format.

**Columns/Parameters Involved**: N/A (no parameters)

**Rules**:
- If sysdiagrams already exists, returns 0 immediately (no-op)
- Creates sysdiagrams with: name (sysname), principal_id (int), diagram_id (identity PK), version (int), definition (varbinary(max)), UK_principal_name unique constraint
- If dbo.dtproperties exists (legacy format), migrates diagrams by matching DtgSchemaGUID pattern and extracting name + definition blobs
- Migrated diagrams are assigned to the dbo principal with version=0 (indicating old format)
- Returns 1 if table was created with no legacy data, 2 if legacy data was migrated

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | Procedure takes no input. Returns 0 (already exists), 1 (created empty), or 2 (created with migrated legacy data). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.sysdiagrams | DDL + DML | Checks for existence, creates if missing, inserts migrated legacy data |
| - | dbo.dtproperties | DML (SELECT) | Reads legacy diagram data for migration (if table exists) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.fn_diagramobjects | - | Reference (object_id) | Checks existence for installation verification (bitmask value 1) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_upgraddiagrams (procedure)
├── dbo.sysdiagrams (table) - creates if missing
└── dbo.dtproperties (table) - reads for legacy migration (if exists)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.sysdiagrams | Table | Checks existence via OBJECT_ID, creates if missing, inserts migrated data |
| dbo.dtproperties | Table | Reads legacy diagram data for migration (optional - only if table exists) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.fn_diagramobjects | Function | Checks existence via object_id() |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None (no EXECUTE AS clause - runs under caller's context).

---

## 8. Sample Queries

### 8.1 Check if diagram infrastructure needs setup
```sql
SELECT OBJECT_ID(N'dbo.sysdiagrams') AS SysdiagramsObjectId
-- NULL = needs setup, non-NULL = already exists
```

### 8.2 Run the upgrade (idempotent)
```sql
EXEC dbo.sp_upgraddiagrams
-- Returns: 0 = already exists, 1 = created empty, 2 = created with migrated data
```

### 8.3 Check installation status after upgrade
```sql
SELECT dbo.fn_diagramobjects() AS InstalledBitmask
-- 255 = all diagram objects installed
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_upgraddiagrams | Type: Stored Procedure | Source: RecurringManager/dbo/Stored Procedures/dbo.sp_upgraddiagrams.sql*
