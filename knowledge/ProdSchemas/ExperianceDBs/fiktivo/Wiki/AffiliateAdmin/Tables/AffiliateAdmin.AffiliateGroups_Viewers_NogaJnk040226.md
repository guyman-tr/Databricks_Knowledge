# AffiliateAdmin.AffiliateGroups_Viewers_NogaJnk040226

> SSDT-only backup copy of AffiliateAdmin.AffiliateGroups_Viewers, created by developer Noga on 2026-02-04 as part of a schema migration. Does not exist in the live database.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Table |
| **Key Identifier** | Composite: AffiliatesGroupsID + UserObjectID |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

This table is a backup snapshot of AffiliateAdmin.AffiliateGroups_Viewers created during a development maintenance operation. The naming convention `_NogaJnk040226` indicates: developer "Noga", "Jnk" (junk/backup), created on 2026-02-04.

The main AffiliateGroups_Viewers table is a many-to-many junction between affiliate groups and users who have permission to view those groups in the admin portal. This backup preserves the junction table structure before a migration was applied.

This table exists only in the SSDT project files - it is not deployed to the live database (querying it returns "Invalid object name"). It serves as a historical record of the permission assignments before migration.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple 2-column junction table backup. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A - table does not exist in the live database. SSDT-only artifact.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliatesGroupsID | int | NO | - | CODE-BACKED | FK to AffiliateAdmin.AffiliatesGroups. Identifies which affiliate group this viewer permission applies to. In the main table, this forms half of the composite key. |
| 2 | UserObjectID | uniqueidentifier | NO | - | CODE-BACKED | Azure AD Object ID of the user who has viewing permission for this group. References AffiliateAdmin.Users.UserObjectID in the main table. Forms the other half of the composite key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. No foreign keys defined (backup copy lacks constraints).

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

None.

### 7.2 Constraints

None. No PK, FK, CHECK, or DEFAULT constraints defined.

---

## 8. Sample Queries

### 8.1 Check if backup exists in SSDT vs live
```sql
SELECT OBJECT_ID('AffiliateAdmin.AffiliateGroups_Viewers_NogaJnk040226') AS ObjectExists;
-- Returns NULL in production
```

### 8.2 Compare with current viewers table
```sql
SELECT c.name, t.name AS data_type, c.max_length, c.is_nullable
FROM sys.columns c WITH (NOLOCK)
JOIN sys.types t WITH (NOLOCK) ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('AffiliateAdmin.AffiliateGroups_Viewers')
ORDER BY c.column_id;
```

### 8.3 List all viewers backup tables
```sql
SELECT name
FROM sys.tables WITH (NOLOCK)
WHERE schema_id = SCHEMA_ID('AffiliateAdmin')
  AND name LIKE 'AffiliateGroups_Viewers_Noga%'
ORDER BY name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 2.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.AffiliateGroups_Viewers_NogaJnk040226 | Type: Table | Source: fiktivo/AffiliateAdmin/Tables/AffiliateAdmin.AffiliateGroups_Viewers_NogaJnk040226.sql*
