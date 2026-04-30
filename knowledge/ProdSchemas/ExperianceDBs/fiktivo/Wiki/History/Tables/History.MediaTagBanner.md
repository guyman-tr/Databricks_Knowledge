# History.MediaTagBanner

> SQL Server temporal history table storing all historical versions of the media-tag-to-banner association, tracking which marketing tags have been applied to which banners over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | BannerID + TagID (composite) - identifies the tag-banner association across versions |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.MediaTagBanner is the system-versioned temporal history table for dbo.MediaTagBanner. It captures every historical version of the many-to-many relationship between media tags and banners. When a tag is applied to or removed from a banner, the previous association version is preserved here.

This table supports auditing of how marketing creatives were organized and categorized at any point in time. Tags enable affiliates to filter banners by theme, campaign, or category, so changes to tag assignments directly affect which banners affiliates can discover and use.

Data flows in automatically via SQL Server's temporal mechanism when dbo.MediaTagBanner is modified. The Trace column shows the CreateMediaTagBanner procedure is the primary operation that triggers history entries.

---

## 2. Business Logic

### 2.1 Tag-Banner Association Tracking

**What**: Tracks the temporal lifecycle of tag-to-banner associations, enabling point-in-time queries of banner categorization.

**Columns/Parameters Involved**: `BannerID`, `TagID`, `ValidFrom`, `ValidTo`

**Rules**:
- Each row represents a historical association between one banner and one tag
- When a tag is removed from a banner, the row moves from dbo.MediaTagBanner to this history table
- When a tag assignment is modified (e.g., replaced), the old version appears here
- BannerID references dbo.tblaff_Banners; TagID references dbo.MediaTag

---

## 3. Data Overview

| BannerID | TagID | Trace (ObjectName) | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|
| 4860 | 1 | CreateMediaTagBanner | 2026-02-18 07:38:19 | 2026-02-18 07:38:25 | Tag 1 was applied to banner 4860 then removed 6 seconds later (test scenario) |
| 4818 | 1 | CreateMediaTagBanner | 2026-02-17 20:45:02 | 2026-02-17 20:45:04 | Tag 1 applied to banner 4818 - another short-lived test association |
| 4773 | 1 | CreateMediaTagBanner | 2026-01-07 11:21:23 | 2026-01-07 11:21:25 | Tag 1 applied to banner 4773 - pattern shows automated test creating and removing tag associations |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BannerID | int | NO | - | CODE-BACKED | Identifier of the banner in this association. References dbo.tblaff_Banners.BannerID. |
| 2 | TagID | int | NO | - | CODE-BACKED | Identifier of the media tag in this association. References dbo.MediaTag.TagID. |
| 3 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context. Contains HostName, AppName, SUserName, SPID, DBName, ObjectName (typically "CreateMediaTagBanner"). |
| 4 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this association became active. Set by SQL Server temporal mechanism. |
| 5 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this association was superseded or removed. Set by SQL Server temporal mechanism. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | dbo.MediaTagBanner | Temporal History | Stores historical versions of the base table |
| BannerID | dbo.tblaff_Banners | Implicit FK | The banner in this tag-banner association |
| TagID | dbo.MediaTag | Implicit FK | The media tag in this tag-banner association |

### 5.2 Referenced By (other objects point to this)

This table is accessed implicitly via temporal queries (FOR SYSTEM_TIME) on dbo.MediaTagBanner.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MediaTagBanner (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.MediaTagBanner | Table | SYSTEM_VERSIONING - superseded versions stored here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_MediaTagBanner | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View tag assignment history for a banner
```sql
SELECT BannerID, TagID, ValidFrom, ValidTo
FROM dbo.MediaTagBanner FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE BannerID = 4860
ORDER BY ValidFrom
```

### 8.2 Find which banners had a specific tag at a point in time
```sql
SELECT mtb.BannerID, b.BannerName, mt.TagName
FROM dbo.MediaTagBanner FOR SYSTEM_TIME AS OF '2025-06-01' mtb WITH (NOLOCK)
JOIN dbo.tblaff_Banners b WITH (NOLOCK) ON mtb.BannerID = b.BannerID
JOIN dbo.MediaTag mt WITH (NOLOCK) ON mtb.TagID = mt.TagID
ORDER BY mtb.BannerID
```

### 8.3 Audit recent tag assignment changes
```sql
SELECT BannerID, TagID,
       JSON_VALUE(Trace, '$.ObjectName') AS ChangedBy,
       ValidFrom, ValidTo
FROM History.MediaTagBanner WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.MediaTagBanner | Type: Table | Source: fiktivo/History/Tables/History.MediaTagBanner.sql*
