# dbo.sp_upgraddiagrams

> System diagram stored procedure that creates or upgrades the database diagram infrastructure, including the dbo.sysdiagrams table. Used internally by SQL Server Management Studio.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Creates/upgrades diagram infrastructure |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a SQL Server system-installed stored procedure that initializes or upgrades the database diagramming infrastructure in the current database. It ensures the dbo.sysdiagrams table exists with the correct schema and creates supporting objects such as the sysdiagram_properties view. If the legacy dtproperties table (used in older SQL Server versions for diagram storage) is present, it migrates existing diagram data to the new sysdiagrams format.

This procedure has no business logic relationship to WalletDB's crypto wallet operations. It is part of the standard SQL Server diagram infrastructure and is typically called once -- either automatically by SSMS when a user first accesses the database diagrams feature, or manually by a DBA to prepare the diagram subsystem. Unlike the other diagram procedures, sp_upgraddiagrams takes no parameters.

The procedure name uses "upgrad" (not "upgrade") -- this is the standard SQL Server naming and is not a typo.

---

## 2. Business Logic

No business logic -- this is a system utility procedure for SSMS diagram infrastructure setup. The procedure performs the following steps:

1. Checks whether the dbo.sysdiagrams table already exists in the current database.
2. If the table does not exist, creates it with the standard schema: diagram_id (identity, PK), name (sysname), principal_id (int), version (int), definition (varbinary(max)).
3. Creates the UK_principal_name unique constraint on (principal_id, name) if it does not already exist.
4. Checks for the presence of the legacy dbo.dtproperties table used in SQL Server 2000 and earlier for diagram storage.
5. If dtproperties exists, migrates any stored diagram data into the new dbo.sysdiagrams format, mapping the legacy property-bag structure to the new columnar format.
6. Creates or refreshes the sysdiagram_properties compatibility view if needed.
7. Ensures appropriate permissions are granted on the new infrastructure objects.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure takes no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (none) | - | - | - | - | No input or output parameters. The procedure operates on fixed infrastructure objects. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Type | Relationship |
|-------------------|------|-------------|
| dbo.sysdiagrams | Table | Creates if not present; target for migrated data |
| dbo.dtproperties | Table | Reads legacy diagram data if table exists (migration source) |

### 5.2 Referenced By (other objects point to this)

No database objects reference this procedure. Called internally by SQL Server Management Studio during initial diagram setup or upgrade scenarios.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_upgraddiagrams
  --> dbo.sysdiagrams (table, create/write)
  --> dbo.dtproperties (table, read -- legacy migration, if present)
```

### 6.1 Objects This Depends On

| Object | Type | Details |
|--------|------|---------|
| dbo.sysdiagrams | Table | Creates this table if it does not exist; writes migrated data into it |
| dbo.dtproperties | Table | Optional legacy table; reads diagram data for migration if present |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- No EXECUTE AS clause -- runs under the caller's security context with DDL permissions required.
- Idempotent -- safe to run multiple times; checks for existing objects before creating them.
- Handles both fresh installations (no sysdiagrams table) and upgrades (legacy dtproperties migration).
- Creates the UK_principal_name unique constraint to enforce diagram name uniqueness per owner.

---

## 8. Sample Queries

### 8.1 Initialize or upgrade diagram infrastructure
```sql
EXEC dbo.sp_upgraddiagrams
```

### 8.2 Verify infrastructure was created
```sql
-- Run after sp_upgraddiagrams to confirm the table exists
SELECT * FROM sys.tables WHERE name = 'sysdiagrams' AND schema_id = SCHEMA_ID('dbo')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a standard SQL Server system procedure.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 6.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_upgraddiagrams | Type: Stored Procedure | Source: WalletDB/dbo/Stored Procedures/dbo.sp_upgraddiagrams.sql*
