# dbo.tblaff_AffiliatesGroups_NogaJnk080226

> Developer backup/snapshot of tblaff_AffiliatesGroups, created on 2026-02-08 by Noga. No indexes, no FKs, no triggers - exists purely as a point-in-time data safety copy.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table (backup/junk) |
| **Key Identifier** | None (heap) |
| **Partition** | No |
| **Indexes** | 0 (heap) |

---

## 1. Business Meaning

dbo.tblaff_AffiliatesGroups_NogaJnk080226 is a developer backup copy of dbo.tblaff_AffiliatesGroups, created on 2026-02-08 as a data safety snapshot. The "NogaJnk" suffix indicates this was created by developer Noga as a temporary working copy during a development or migration task. These tables should be reviewed for potential cleanup.

See [dbo.tblaff_AffiliatesGroups](dbo.tblaff_AffiliatesGroups.md) for full documentation of the source table's structure, business meaning, and element descriptions. This backup has an identical column structure but no indexes, constraints, triggers, or foreign keys.

---

## 2. Business Logic

No business logic. This is a static backup copy.

---

## 3. Data Overview

Developer backup - data represents a point-in-time snapshot from 2026-02-08.

---

## 4. Elements

See [dbo.tblaff_AffiliatesGroups](dbo.tblaff_AffiliatesGroups.md) for complete element descriptions. This table has identical columns: AffiliatesGroupsID (int IDENTITY), AffiliatesGroupsName (nvarchar(50)), AccountManagerName (nvarchar(50)), AccountManagerEmail (nvarchar(50)), AccountManagerImagePath (nvarchar(200)), ManagerUserID (int).

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (backup copy - no FKs).

### 5.2 Referenced By (other objects point to this)

No dependents found. This is an orphaned backup table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

No indexes (heap table).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if backup has data
```sql
SELECT COUNT(*) AS RowCount FROM dbo.tblaff_AffiliatesGroups_NogaJnk080226 WITH (NOLOCK)
```

### 8.2 Compare with current source table
```sql
SELECT 'Current' AS Source, COUNT(*) AS Rows FROM dbo.tblaff_AffiliatesGroups WITH (NOLOCK)
UNION ALL
SELECT 'Backup', COUNT(*) FROM dbo.tblaff_AffiliatesGroups_NogaJnk080226 WITH (NOLOCK)
```

### 8.3 Sample backup data
```sql
SELECT TOP 5 * FROM dbo.tblaff_AffiliatesGroups_NogaJnk080226 WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_AffiliatesGroups_NogaJnk080226 | Type: Table (backup) | Source: fiktivo/dbo/Tables/dbo.tblaff_AffiliatesGroups_NogaJnk080226.sql*
