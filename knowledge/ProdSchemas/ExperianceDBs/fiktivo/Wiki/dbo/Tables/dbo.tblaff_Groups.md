# dbo.tblaff_Groups

> Banner/media groups that organize marketing creative assets by dimensions, refresh rate, category, language, and brand for affiliate selection.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | GroupID (INT IDENTITY, PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 nonclustered PK, 1 covering GroupID+GroupName+Width+Height) |

---

## 1. Business Meaning

This table defines banner groups - organizational containers for marketing banners. Each group specifies dimensions (Width x Height), a refresh period, and is linked to a category, language, and brand. Affiliates browse groups to find banner sets that fit their website layouts and target audience.

Without this table, individual banners could not be organized into logical sets. Currently 138 groups. Groups cascade-delete their tblaff_GroupBanners entries via trigger. Managed by admin users with Banners_* permissions.

---

## 2. Business Logic

### 2.1 Banner Group Organization

**What**: Groups define a display context (size + language + brand + category) and collect banners that fit that context.

**Columns/Parameters Involved**: `Width`, `Height`, `CategoryID`, `LanguageID`, `BrandID`, `RefreshPeriod`, `IsArchived`

**Rules**:
- Width/Height define the banner slot dimensions (e.g., 728x90 leaderboard, 300x250 medium rectangle)
- CategoryID links to [tblaff_Categories](dbo.tblaff_Categories.md) for content classification
- LanguageID links to [tblaff_Languages](dbo.tblaff_Languages.md) for locale targeting
- BrandID links to [tblaff_Brands](dbo.tblaff_Brands.md) for entity/jurisdiction separation
- RefreshPeriod controls how often rotating banners cycle (in seconds, 0 = no rotation)
- IsArchived=1 hides the group from active selection

---

## 3. Data Overview

N/A - Group configurations are operational data. See element descriptions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GroupID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Referenced by tblaff_GroupBanners.GroupID for banner-to-group mapping. |
| 2 | GroupName | nvarchar(50) | YES | - | CODE-BACKED | Display name of the banner group. Shown in affiliate portal banner selection. |
| 3 | Width | int | YES | 0 | CODE-BACKED | Banner slot width in pixels (e.g., 728, 300, 160). 0 = any/variable width. |
| 4 | Height | int | YES | 0 | CODE-BACKED | Banner slot height in pixels (e.g., 90, 250, 600). 0 = any/variable height. |
| 5 | RefreshPeriod | int | NO | 0 | CODE-BACKED | Auto-rotation period in seconds for rotating banner groups. 0 = static (no rotation). |
| 6 | GroupDescription | nvarchar(1000) | YES | - | NAME-INFERRED | Descriptive text about the banner group, displayed in the affiliate portal. |
| 7 | CategoryID | int | NO | 0 | CODE-BACKED | References [dbo.tblaff_Categories](dbo.tblaff_Categories.md).CategoryID. Content category for the group. Default 0. |
| 8 | LanguageID | int | YES | 1 | CODE-BACKED | References [dbo.tblaff_Languages](dbo.tblaff_Languages.md).LanguageID. Target language for the group. Default 1 (English). |
| 9 | BrandID | int | YES | 1 | CODE-BACKED | References [dbo.tblaff_Brands](dbo.tblaff_Brands.md).BrandID. Brand/entity for regulatory separation. Default 1 (eToro). |
| 10 | IsArchived | bit | NO | 0 | CODE-BACKED | Archive flag. 1 = group is hidden from active banner selection. 0 = active and available to affiliates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CategoryID | [dbo.tblaff_Categories](dbo.tblaff_Categories.md) | Implicit FK | Content category of the group. |
| LanguageID | [dbo.tblaff_Languages](dbo.tblaff_Languages.md) | Implicit FK | Target language. |
| BrandID | [dbo.tblaff_Brands](dbo.tblaff_Brands.md) | Implicit FK | Brand/entity. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_GroupBanners | GroupID | Implicit FK | Links banners to this group. Cascade-deleted via trigger. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no hard dependencies (all FKs are implicit).

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_GroupBanners | Table | GroupID referenced; cascade-deleted |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_Groups_PK | NC PK | GroupID | - | - | Active |
| Group_Covered | NC | GroupID, GroupName, Width, Height | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_Groups_Width/Height | DEFAULT | 0 (variable size) |
| DF_tblaff_Groups_RefreshPeriod | DEFAULT | 0 (static) |
| DF_tblaff_Groups_CategoryID | DEFAULT | 0 |
| DF_tblaff_Groups_LanguageID_1 | DEFAULT | 1 (English) |
| DF_tblaff_Groups_BrandID | DEFAULT | 1 (eToro) |
| DF_tblaff_Groups_IsArchived | DEFAULT | 0 (active) |
| tblaff_Groups_DTrig | TRIGGER (DELETE) | Cascade-deletes tblaff_GroupBanners rows |
| tblaff_Groups_UTrig | TRIGGER (UPDATE) | Prevents GroupID update if dependent GroupBanners exist |

---

## 8. Sample Queries

### 8.1 List active banner groups with dimensions
```sql
SELECT GroupID, GroupName, Width, Height, RefreshPeriod
FROM dbo.tblaff_Groups WITH (NOLOCK)
WHERE IsArchived = 0
ORDER BY GroupName
```

### 8.2 Find groups by language and brand
```sql
SELECT g.GroupID, g.GroupName, l.LanguageName, br.BrandName
FROM dbo.tblaff_Groups g WITH (NOLOCK)
JOIN dbo.tblaff_Languages l WITH (NOLOCK) ON g.LanguageID = l.LanguageID
JOIN dbo.tblaff_Brands br WITH (NOLOCK) ON g.BrandID = br.BrandID
WHERE g.IsArchived = 0
ORDER BY br.BrandName, l.LanguageName
```

### 8.3 Find groups with specific banner dimensions
```sql
SELECT GroupID, GroupName, CategoryID
FROM dbo.tblaff_Groups WITH (NOLOCK)
WHERE Width = 728 AND Height = 90 AND IsArchived = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 9.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Groups | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Groups.sql*
