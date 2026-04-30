# dbo.MediaTag

> Tracking tag definitions that affiliates attach to their marketing links for campaign attribution and performance measurement.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | TagName (NVARCHAR(500), PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 nonclustered PK on TagName, 1 clustered on TagID) |

---

## 1. Business Meaning

This table defines the media tags that affiliates use to track the performance of individual marketing campaigns or placements. Each tag has a unique name and a translation key for localization. Tags are linked to banners via the tblaff_MediaTagBanner junction table, enabling affiliates to measure which campaigns drive conversions.

The table is system-versioned with temporal history in History.MediaTag, tracking all tag definition changes over time. Tags are created and managed via dbo.CreateMediaTag and dbo.UpdateMediaTag procedures.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A - Tag definitions vary by affiliate campaign.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TagID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing identifier. Clustered index key for physical ordering. |
| 2 | TagName | nvarchar(500) | NO | - | CODE-BACKED | Primary key. Unique tag identifier used in tracking URLs and campaign attribution (e.g., "summer_2024_banner_a"). |
| 3 | TranslationKey | varchar(128) | NO | - | CODE-BACKED | Localization key for displaying the tag name in multiple languages in the affiliate portal UI. |
| 4 | Trace | computed | NO | - | CODE-BACKED | Computed audit column. JSON with session metadata (HostName, AppName, SUserName, SPID). |
| 5 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioning period start. Tracks when this tag definition became active. |
| 6 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioning period end. '9999-12-31' for current rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.MediaTagBanner | TagID | Implicit FK | Junction table linking tags to specific banner assets for campaign tracking. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.MediaTagBanner | Table | Links tags to banners |
| dbo.CreateMediaTag | Stored Procedure | WRITER - creates new tags |
| dbo.UpdateMediaTag | Stored Procedure | MODIFIER - updates tag definitions |
| dbo.RemoveMediaTag | Stored Procedure | DELETER - removes tags |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MediaTag | NC PK | TagName | - | - | Active (PAGE compressed) |
| CDX_MediaTag_TagID | CLUSTERED | TagID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SYSTEM_VERSIONING | Temporal | History table: History.MediaTag |

---

## 8. Sample Queries

### 8.1 List all current tags
```sql
SELECT TagID, TagName, TranslationKey
FROM dbo.MediaTag WITH (NOLOCK)
ORDER BY TagName
```

### 8.2 Find tags with their linked banners
```sql
SELECT mt.TagName, mtb.BannerID
FROM dbo.MediaTag mt WITH (NOLOCK)
JOIN dbo.MediaTagBanner mtb WITH (NOLOCK) ON mt.TagID = mtb.TagID
ORDER BY mt.TagName
```

### 8.3 View tag history (temporal query)
```sql
SELECT TagID, TagName, ValidFrom, ValidTo
FROM dbo.MediaTag
FOR SYSTEM_TIME ALL
WHERE TagName = 'my_campaign_tag'
ORDER BY ValidFrom DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.MediaTag | Type: Table | Source: fiktivo/dbo/Tables/dbo.MediaTag.sql*
