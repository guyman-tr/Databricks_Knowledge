# dbo.tblaff_GroupBanners

> Junction table linking banner groups to individual banners with weighting, enabling weighted rotation of marketing creatives within affiliate banner groups.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NC) |
| **Partition** | No |
| **Indexes** | 4 active |

---

## 1. Business Meaning

dbo.tblaff_GroupBanners is a many-to-many junction table that assigns individual banners (tblaff_Banners) to banner groups (tblaff_Groups) with a weighting factor. This enables affiliates to embed a single group code on their site, and the system rotates between assigned banners based on their weighting values.

Without this table, affiliates could only display single banners. The group mechanism allows campaign managers to bundle multiple creatives into a rotation set, control display frequency via weighting, and swap creatives without requiring affiliates to update their embed codes.

Trigger-based referential integrity ensures both BannerID and GroupID reference valid records. The table contains 460 assignments. The `CreateBanner` and `UpdateBanner` procedures manage banner lifecycle, while the admin interface manages group assignments.

---

## 2. Business Logic

### 2.1 Weighted Banner Rotation

**What**: Banners within a group are served based on their relative weighting.

**Columns/Parameters Involved**: `GroupID`, `BannerID`, `Weighting`

**Rules**:
- All sample data shows Weighting=1 (equal rotation) - but the system supports differential weighting
- Higher weighting = more frequent display relative to other banners in the same group
- A group can contain multiple banners (e.g., GroupID=13 has at least 2 banners)
- Triggers enforce that BannerID exists in tblaff_Banners and GroupID exists in tblaff_Groups

---

## 3. Data Overview

| ID | GroupID | BannerID | Weighting | Meaning |
|---|---|---|---|---|
| 1349 | 13 | 3338 | 1 | Banner 3338 assigned to group 13 with standard weight. Equal rotation with other group members. |
| 1348 | 13 | 2019 | 1 | Banner 2019 also in group 13. Both banners rotate equally (same weight). |
| 1345 | 145 | 520 | 1 | Banner 520 assigned to group 145. May be the only banner in this group (single-banner rotation). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing primary key. NOT FOR REPLICATION. |
| 2 | GroupID | int | YES | 0 | VERIFIED | Banner group ID. References tblaff_Groups.GroupID. Trigger enforces RI on INSERT/UPDATE. Default 0 = unassigned. |
| 3 | BannerID | int | YES | 0 | VERIFIED | Banner ID. References tblaff_Banners.BannerID. Trigger enforces RI on INSERT/UPDATE. Default 0 = unassigned. |
| 4 | Weighting | int | YES | 0 | CODE-BACKED | Relative display weight within the group. Higher values = more frequent display. All current data uses Weighting=1 (equal rotation). Default 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GroupID | dbo.tblaff_Groups | Implicit (trigger) | The banner group this assignment belongs to |
| BannerID | dbo.tblaff_Banners | Implicit (trigger) | The specific banner creative assigned to the group |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_GroupBanners_PK | NC PK | ID ASC | - | - | Active (fill 90%) |
| Group_Clustered | CLUSTERED | GroupID, BannerID, Weighting | - | - | Active (fill 90%) |
| BannersGroupBanners | NC | BannerID ASC | - | - | Active (fill 90%) |
| GroupsGroupBanners | NC | GroupID ASC | - | - | Active (fill 90%) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_GroupBanners_GroupID | DEFAULT | 0 |
| DF_tblaff_GroupBanners_BannerID | DEFAULT | 0 |
| DF_tblaff_GroupBanners_Weighting | DEFAULT | 0 |

---

## 8. Sample Queries

### 8.1 List banners in a group with weights
```sql
SELECT gb.BannerID, b.BannerName, gb.Weighting
FROM dbo.tblaff_GroupBanners gb WITH (NOLOCK)
JOIN dbo.tblaff_Banners b WITH (NOLOCK) ON gb.BannerID = b.BannerID
WHERE gb.GroupID = @GroupID
ORDER BY gb.Weighting DESC
```

### 8.2 Groups with multiple banners
```sql
SELECT GroupID, COUNT(*) AS BannerCount, SUM(Weighting) AS TotalWeight
FROM dbo.tblaff_GroupBanners WITH (NOLOCK)
GROUP BY GroupID
HAVING COUNT(*) > 1
ORDER BY BannerCount DESC
```

### 8.3 Find which groups a banner belongs to
```sql
SELECT gb.GroupID, g.GroupName, gb.Weighting
FROM dbo.tblaff_GroupBanners gb WITH (NOLOCK)
JOIN dbo.tblaff_Groups g WITH (NOLOCK) ON gb.GroupID = g.GroupID
WHERE gb.BannerID = @BannerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_GroupBanners | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_GroupBanners.sql*
