# AffiliateAdmin.AffiliateGroups_Viewers_NogaJunk080226

> DEPRECATED / DEVELOPER BACKUP. A point-in-time snapshot of AffiliateAdmin.AffiliateGroups_Viewers taken on 2026-02-08 by developer "Noga" during or before the PART-5531 migration. Not used by any active procedures.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Table |
| **Key Identifier** | (AffiliatesGroupsID, UserObjectID) - no PK constraint |
| **Partition** | No |
| **Indexes** | 0 (no indexes or constraints) |

---

## 1. Business Meaning

This table is a developer backup copy of `AffiliateAdmin.AffiliateGroups_Viewers`, created on February 8, 2026 as a safety net during the PART-5531 migration. The naming convention `_NogaJunk080226` follows the team's pattern: `{DeveloperName}Junk{DDMMYY}`.

The backup contains only 2 rows compared to the current 379 rows in the main table, suggesting it was either taken at a very early stage of the migration (before viewer assignments were fully populated) or represents a minimal test copy rather than a complete backup.

No active procedures reference this table. It is safe to drop once the PART-5531 migration is confirmed stable.

---

## 2. Business Logic

No complex multi-column business logic patterns. This is a static backup with no active business processes. See `AffiliateAdmin.AffiliateGroups_Viewers` for the active table's business logic.

---

## 3. Data Overview

This is a snapshot containing 2 rows of viewer assignments from 2026-02-08. The active table now has 379 rows. See [AffiliateAdmin.AffiliateGroups_Viewers](AffiliateAdmin.AffiliateGroups_Viewers.md) Section 3 for representative data from the active table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliatesGroupsID | int | NO | - | CODE-BACKED | Backup copy of the affiliate group identifier. Same values as `AffiliateAdmin.AffiliateGroups_Viewers.AffiliatesGroupsID` at the time of backup. No PK constraint (unlike the source table which has a composite PK). |
| 2 | UserObjectID | uniqueidentifier | NO | - | CODE-BACKED | Backup copy of the viewer user's Azure AD Object ID. Same values as `AffiliateAdmin.AffiliateGroups_Viewers.UserObjectID` at the time of backup. No PK constraint. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is an isolated backup with no constraints or active relationships.

### 5.2 Referenced By (other objects point to this)

This object is not referenced by any active procedures, views, or other tables.

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

No indexes. Unlike the source table (`AffiliateAdmin.AffiliateGroups_Viewers`), this backup was created without a PK or any indexes - confirming it is a simple backup copy.

### 7.2 Constraints

None. The backup has no PK, no FK, no CHECK constraints. Duplicate rows are theoretically possible (unlike the source table which enforces uniqueness via composite PK).

---

## 8. Sample Queries

### 8.1 View all rows in the backup
```sql
SELECT agv.AffiliatesGroupsID, ag.AffiliatesGroupsName, u.FirstName, u.LastName
FROM AffiliateAdmin.AffiliateGroups_Viewers_NogaJunk080226 agv WITH (NOLOCK)
LEFT JOIN AffiliateAdmin.AffiliatesGroups ag WITH (NOLOCK) ON ag.AffiliatesGroupsID = agv.AffiliatesGroupsID
LEFT JOIN AffiliateAdmin.Users u WITH (NOLOCK) ON u.UserObjectID = agv.UserObjectID
```

### 8.2 Compare backup to current table
```sql
SELECT 'Backup' AS Source, COUNT(*) AS Rows FROM AffiliateAdmin.AffiliateGroups_Viewers_NogaJunk080226 WITH (NOLOCK)
UNION ALL
SELECT 'Current', COUNT(*) FROM AffiliateAdmin.AffiliateGroups_Viewers WITH (NOLOCK)
```

### 8.3 Find rows in backup not in current (lost assignments)
```sql
SELECT b.AffiliatesGroupsID, b.UserObjectID
FROM AffiliateAdmin.AffiliateGroups_Viewers_NogaJunk080226 b WITH (NOLOCK)
LEFT JOIN AffiliateAdmin.AffiliateGroups_Viewers c WITH (NOLOCK)
    ON c.AffiliatesGroupsID = b.AffiliatesGroupsID AND c.UserObjectID = b.UserObjectID
WHERE c.AffiliatesGroupsID IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Related migration ticket: PART-5531 (February 2026).

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.AffiliateGroups_Viewers_NogaJunk080226 | Type: Table | Source: fiktivo/AffiliateAdmin/Tables/AffiliateAdmin.AffiliateGroups_Viewers_NogaJnk080226.sql*
