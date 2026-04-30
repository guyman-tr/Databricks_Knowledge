# BackOffice.AffiliateToUserGroup

> Junction table that assigns affiliate accounts to BackOffice sales user groups, controlling which sales team is responsible for managing each affiliate.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (AffiliateID, UserGroupID) - composite CLUSTERED PK |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 2 active (1 clustered composite PK + 1 NC on UserGroupID) |

---

## 1. Business Meaning

BackOffice.AffiliateToUserGroup is a many-to-many bridge table that assigns affiliate partners to BackOffice user groups (sales teams). Each row means "this affiliate is managed by this sales team." The table enables the BackOffice CRM interface to filter affiliate lists by team, directing the right sales team to the right affiliates.

The table exists separately from BackOffice.Affiliate because a single affiliate can, in principle, be assigned to multiple user groups simultaneously. In practice, all 574 rows map affiliates to exactly one of two groups: Sales 1 (UserGroupID=9, 487 affiliates) or Sales 2 (UserGroupID=10, 87 affiliates). Both are sub-groups of UserGroupID=7 (Sales/Support) under Operations.

Data flows into this table when affiliates are on-boarded or reassigned across sales teams. No stored procedure in the SSDT repo writes to this table - assignment is likely managed via direct inserts from an external affiliate management tool or a process not captured in this schema.

---

## 2. Business Logic

### 2.1 Sales Team Assignment

**What**: Each affiliate is assigned to a specific sales sub-team within the Sales/Support department.

**Columns Involved**: `AffiliateID`, `UserGroupID`

**Rules**:
- Both active groups are children of UserGroupID=7 (Sales/Support), itself under Operations.
- Sales 1 (UserGroupID=9): 487 affiliates - the primary sales team.
- Sales 2 (UserGroupID=10): 87 affiliates - the secondary/overflow sales team.
- All other UserGroupIDs in Dictionary.UserGroup are unused in this table.
- An affiliate can theoretically hold multiple rows (no UNIQUE constraint on AffiliateID alone), but in practice each affiliate appears at most once.

**Diagram**:
```
Dictionary.UserGroup hierarchy for active groups:
Operations (2)
  └── Sales/Support (7)
        ├── Sales 1 (9) <- 487 affiliates
        └── Sales 2 (10) <- 87 affiliates
```

---

## 3. Data Overview

| AffiliateID | UserGroupID | UserGroupName | Meaning |
|-------------|-------------|---------------|---------|
| 2 | 10 | Sales 2 | Affiliate 2 is assigned to the Sales 2 team for CRM management |
| 3 | 10 | Sales 2 | Affiliate 3 is assigned to the Sales 2 team |
| 7 | 9 | Sales 1 | Affiliate 7 is assigned to the larger Sales 1 team |
| 8 | 10 | Sales 2 | Affiliate 8 is assigned to Sales 2 |
| 15 | 9 | Sales 1 | Affiliate 15 is managed by the Sales 1 team, which handles the majority (84.8%) of affiliate assignments |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | VERIFIED | The affiliate's unique identifier. Part of the composite PK. FK (WITH CHECK) to BackOffice.Affiliate(AffiliateID). Maps to the affiliate's customer account ID (SerialID in Customer.Customer). Only affiliates already registered in BackOffice.Affiliate can appear here. |
| 2 | UserGroupID | int | NO | - | VERIFIED | The BackOffice user group (sales team) assigned to manage this affiliate. Part of the composite PK. FK (WITH CHECK) to Dictionary.UserGroup(UserGroupID). In practice only two values are used: 9=Sales 1 (487 affiliates, 84.8%), 10=Sales 2 (87 affiliates, 15.2%). Both are sub-groups of UserGroupID=7 (Sales/Support). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | BackOffice.Affiliate | FK (WITH CHECK) | Must reference an existing affiliate profile; constraint name FK_BAFF_BAUG |
| UserGroupID | Dictionary.UserGroup | FK (WITH CHECK) | Must reference an existing BackOffice user group; constraint name FK_DUGR_BAUG |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No stored procedures or views in the SSDT repo directly reference this table; assignment is managed externally or via direct DML.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AffiliateToUserGroup (table)
- FK targets (leaf nodes):
  ├── BackOffice.Affiliate (table)
  └── Dictionary.UserGroup (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Affiliate | Table | FK on AffiliateID - affiliate must exist before assignment |
| Dictionary.UserGroup | Table | FK on UserGroupID - user group must exist before assignment |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo. Table may be queried directly by BackOffice application layer.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BAUG | CLUSTERED PK | AffiliateID ASC, UserGroupID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |
| BAUG_USERGROUP | NC | UserGroupID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BAUG | PK | Uniqueness of (AffiliateID, UserGroupID) pairs |
| FK_BAFF_BAUG | FK (WITH CHECK) | AffiliateID -> BackOffice.Affiliate(AffiliateID) |
| FK_DUGR_BAUG | FK (WITH CHECK) | UserGroupID -> Dictionary.UserGroup(UserGroupID) |

---

## 8. Sample Queries

### 8.1 List all affiliates with their assigned sales team
```sql
SELECT
    aug.AffiliateID,
    ug.Name AS UserGroupName,
    ug.ParentID
FROM BackOffice.AffiliateToUserGroup aug WITH (NOLOCK)
JOIN Dictionary.UserGroup ug WITH (NOLOCK) ON ug.UserGroupID = aug.UserGroupID
ORDER BY ug.UserGroupID, aug.AffiliateID
```

### 8.2 Count affiliates per sales team
```sql
SELECT
    ug.UserGroupID,
    ug.Name AS UserGroupName,
    COUNT(aug.AffiliateID) AS AffiliateCount
FROM BackOffice.AffiliateToUserGroup aug WITH (NOLOCK)
JOIN Dictionary.UserGroup ug WITH (NOLOCK) ON ug.UserGroupID = aug.UserGroupID
GROUP BY ug.UserGroupID, ug.Name
ORDER BY AffiliateCount DESC
```

### 8.3 Find affiliates not yet assigned to any sales team
```sql
SELECT a.AffiliateID, a.AffiliateStatusID, a.SpreadGroupID
FROM BackOffice.Affiliate a WITH (NOLOCK)
LEFT JOIN BackOffice.AffiliateToUserGroup aug WITH (NOLOCK) ON aug.AffiliateID = a.AffiliateID
WHERE aug.AffiliateID IS NULL
ORDER BY a.AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AffiliateToUserGroup | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.AffiliateToUserGroup.sql*
