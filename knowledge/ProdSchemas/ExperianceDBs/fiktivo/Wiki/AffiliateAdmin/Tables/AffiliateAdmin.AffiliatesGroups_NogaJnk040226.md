# AffiliateAdmin.AffiliatesGroups_NogaJnk040226

> SSDT-only backup copy of AffiliateAdmin.AffiliatesGroups, created by developer Noga on 2026-02-04 as part of a schema migration. Does not exist in the live database.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Table |
| **Key Identifier** | AffiliatesGroupsID (int, IDENTITY) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

This table is a backup snapshot of AffiliateAdmin.AffiliatesGroups created during a development maintenance operation. The naming convention `_NogaJnk040226` indicates: developer "Noga", "Jnk" (junk/backup), created on 2026-02-04.

This backup was likely created as a safety net before a structural change to the main AffiliatesGroups table. It preserves the table structure as it existed at that point in time, with 6 columns including group identity, name, and manager assignment.

This table exists only in the SSDT project files - it is not deployed to the live database (querying it returns "Invalid object name"). It serves as a historical record of the schema state before migration, stored in source control.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a backup table with no constraints, indexes, or foreign keys. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A - table does not exist in the live database. SSDT-only artifact.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliatesGroupsID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key identifying each affiliate group. Matches the PK structure of the main AffiliatesGroups table. |
| 2 | AffiliatesGroupsName | nvarchar(50) | NO | - | CODE-BACKED | Display name for the affiliate group (e.g., "Premium Partners", "LATAM Affiliates"). Required field. |
| 3 | AccountManagerName | nvarchar(50) | YES | - | CODE-BACKED | Name of the account manager responsible for this group. Nullable - not all groups have an assigned manager. |
| 4 | AccountManagerEmail | nvarchar(50) | YES | - | CODE-BACKED | Email address of the account manager. Nullable. |
| 5 | AccountManagerImagePath | nvarchar(200) | YES | - | CODE-BACKED | File path or URL to the account manager's profile image. Nullable. |
| 6 | ManagerUserID | uniqueidentifier | YES | - | CODE-BACKED | Azure AD Object ID of the assigned manager user. References AffiliateAdmin.Users.UserObjectID in the main table. Nullable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. No foreign keys defined.

### 5.2 Referenced By (other objects point to this)

No objects reference this backup table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found. This is an orphaned backup table.

---

## 7. Technical Details

### 7.1 Indexes

None. The backup was created without indexes (unlike the main AffiliatesGroups table which has a clustered PK).

### 7.2 Constraints

None. No PK, FK, CHECK, or DEFAULT constraints defined.

---

## 8. Sample Queries

### 8.1 Check if backup exists in SSDT vs live
```sql
-- This table exists only in SSDT, not in the live database
SELECT OBJECT_ID('AffiliateAdmin.AffiliatesGroups_NogaJnk040226') AS ObjectExists;
-- Returns NULL in production
```

### 8.2 Compare backup structure with current main table
```sql
SELECT c.name, t.name AS data_type, c.max_length, c.is_nullable
FROM sys.columns c WITH (NOLOCK)
JOIN sys.types t WITH (NOLOCK) ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('AffiliateAdmin.AffiliatesGroups')
ORDER BY c.column_id;
```

### 8.3 Identify all Noga backup tables in schema
```sql
SELECT name
FROM sys.tables WITH (NOLOCK)
WHERE schema_id = SCHEMA_ID('AffiliateAdmin')
  AND name LIKE '%Noga%'
ORDER BY name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 2.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.AffiliatesGroups_NogaJnk040226 | Type: Table | Source: fiktivo/AffiliateAdmin/Tables/AffiliateAdmin.AffiliatesGroups_NogaJnk040226.sql*
