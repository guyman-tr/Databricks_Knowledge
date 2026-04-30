# AffiliateAdmin.AffiliatesGroups_NogaJunk080226

> DEPRECATED / DEVELOPER BACKUP. A point-in-time snapshot of AffiliateAdmin.AffiliatesGroups taken on 2026-02-08 by developer "Noga" during or before the PART-5531 migration. Not used by any active procedures.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Table |
| **Key Identifier** | AffiliatesGroupsID (int IDENTITY, no PK constraint) |
| **Partition** | No |
| **Indexes** | 0 (no indexes or constraints) |

---

## 1. Business Meaning

This table is a developer backup copy of `AffiliateAdmin.AffiliatesGroups`, created on February 8, 2026 as a safety net during the PART-5531 migration that restructured affiliate group management. The naming convention `_NogaJunk080226` follows the team's pattern: `{DeveloperName}Junk{DDMMYY}` - indicating developer "Noga" created it on 08/02/26.

The backup exists to allow rollback if the PART-5531 migration encountered issues. It preserves the state of the AffiliatesGroups table at the time of the migration. It contains 291 rows (one fewer than the current 292 in the main table, confirming it was taken before the latest group was added).

No active procedures reference this table. It is safe to drop once the PART-5531 migration is confirmed stable. The team's convention is to eventually clean up these backup tables, but they are typically retained for several months as a safety net.

---

## 2. Business Logic

No complex multi-column business logic patterns. This is a static backup with no active business processes. See `AffiliateAdmin.AffiliatesGroups` for the active table's business logic.

---

## 3. Data Overview

This is a snapshot of `AffiliateAdmin.AffiliatesGroups` from 2026-02-08 with 291 rows. The structure and data are identical to the source table at that point in time. See [AffiliateAdmin.AffiliatesGroups](AffiliateAdmin.AffiliatesGroups.md) Section 3 for representative data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliatesGroupsID | int IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Backup copy of the group identifier. IDENTITY but no PK constraint (unlike the source table). Same values as `AffiliateAdmin.AffiliatesGroups.AffiliatesGroupsID` at the time of backup. No dynamic data masking applied. |
| 2 | AffiliatesGroupsName | nvarchar(50) | NO | - | CODE-BACKED | Backup copy of the group display name. Same as source table's `AffiliatesGroupsName`. |
| 3 | AccountManagerName | nvarchar(50) | YES | - | CODE-BACKED | Backup copy of the legacy denormalized account manager name. No dynamic data masking (unlike the source table which has MASKED). |
| 4 | AccountManagerEmail | nvarchar(50) | YES | - | CODE-BACKED | Backup copy of the legacy denormalized account manager email. No dynamic data masking (unlike the source table which has MASKED). |
| 5 | AccountManagerImagePath | nvarchar(200) | YES | - | CODE-BACKED | Backup copy of the account manager profile image path. |
| 6 | ManagerUserID | uniqueidentifier | YES | - | CODE-BACKED | Backup copy of the manager's Azure AD Object ID. Same implicit relationship to `AffiliateAdmin.Users.UserObjectID` as the source table, but no enforcement since no FK exists. |

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

No indexes. Unlike the source table (`AffiliateAdmin.AffiliatesGroups`), this backup was created without a PK or any indexes - confirming it is a simple `SELECT INTO` or `INSERT INTO` backup copy.

### 7.2 Constraints

None. The backup has no PK, no FK, no CHECK, no DEFAULT constraints. The IDENTITY property is retained from the source table but serves no functional purpose.

---

## 8. Sample Queries

### 8.1 Compare backup to current table (detect drift since migration)
```sql
SELECT 'In backup only' AS Status, b.AffiliatesGroupsID, b.AffiliatesGroupsName
FROM AffiliateAdmin.AffiliatesGroups_NogaJunk080226 b WITH (NOLOCK)
LEFT JOIN AffiliateAdmin.AffiliatesGroups c WITH (NOLOCK) ON c.AffiliatesGroupsID = b.AffiliatesGroupsID
WHERE c.AffiliatesGroupsID IS NULL
UNION ALL
SELECT 'In current only', c.AffiliatesGroupsID, c.AffiliatesGroupsName
FROM AffiliateAdmin.AffiliatesGroups c WITH (NOLOCK)
LEFT JOIN AffiliateAdmin.AffiliatesGroups_NogaJunk080226 b WITH (NOLOCK) ON b.AffiliatesGroupsID = c.AffiliatesGroupsID
WHERE b.AffiliatesGroupsID IS NULL
```

### 8.2 Count rows in backup vs current
```sql
SELECT 'Backup (080226)' AS Source, COUNT(*) AS Rows FROM AffiliateAdmin.AffiliatesGroups_NogaJunk080226 WITH (NOLOCK)
UNION ALL
SELECT 'Current', COUNT(*) FROM AffiliateAdmin.AffiliatesGroups WITH (NOLOCK)
```

### 8.3 Check for data masking differences (backup has no masking)
```sql
SELECT TOP 5 AffiliatesGroupsID, AffiliatesGroupsName, AccountManagerName, AccountManagerEmail
FROM AffiliateAdmin.AffiliatesGroups_NogaJunk080226 WITH (NOLOCK)
WHERE AccountManagerName IS NOT NULL
ORDER BY AffiliatesGroupsID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Related migration ticket: PART-5531 (February 2026).

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.AffiliatesGroups_NogaJunk080226 | Type: Table | Source: fiktivo/AffiliateAdmin/Tables/AffiliateAdmin.AffiliatesGroups_NogaJnk080226.sql*
