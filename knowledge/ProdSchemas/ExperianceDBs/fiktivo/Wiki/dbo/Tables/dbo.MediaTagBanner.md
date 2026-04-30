# dbo.MediaTagBanner

> Junction table linking marketing banners to media tags, enabling tag-based banner categorization and filtering with full temporal audit trail.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | BannerID + TagID (composite PK, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK + NC on TagID) |

---

## 1. Business Meaning

This table implements a many-to-many relationship between marketing banners (`dbo.tblaff_Banners`) and media tags (`dbo.MediaTag`). Media tags are labels that categorize banners by theme, campaign, audience segment, or content type, allowing affiliates and administrators to search and filter banners efficiently.

Each row represents one banner-tag assignment. A banner can have multiple tags, and a tag can apply to multiple banners. The temporal versioning (SYSTEM_VERSIONING with History.MediaTagBanner) provides a complete audit trail of when tags were added to or removed from banners.

The Trace computed column captures the database session context (hostname, application, SQL user, SPID) for every insert/update, providing granular audit attribution of who made each tag assignment change.

---

## 2. Business Logic

### 2.1 Temporal Tag Assignment Tracking

**What**: Full history of banner-tag assignments is preserved through SQL Server system-versioned temporal tables.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`, `BannerID`, `TagID`

**Rules**:
- Current assignments have ValidTo = '9999-12-31 23:59:59.999'
- When a tag is removed from a banner, the row is deleted from the current table and moved to History.MediaTagBanner with the actual end timestamp
- The history table enables point-in-time queries to see which tags a banner had on any given date
- This supports compliance requirements for marketing material classification audit trails

---

## 3. Data Overview

| BannerID | TagID | Meaning |
|---|---|---|
| 1 | 5 | Banner #1 tagged with tag #5 - a foundational banner with multiple tag assignments |
| 1 | 7 | Banner #1 also tagged with tag #7 - demonstrates multi-tag pattern |
| 36 | 1 | Banner #36 assigned to tag #1 - recently tagged (Jan 2026) |
| 36 | 2 | Banner #36 also assigned to tag #2 - dual categorization |
| 210 | 3 | Banner #210 tagged with tag #3 - an older assignment from 2022 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BannerID | int | NO | - | VERIFIED | Foreign key to dbo.tblaff_Banners.BannerID. Identifies the marketing banner being tagged. Part of the composite primary key. |
| 2 | TagID | int | NO | - | VERIFIED | Foreign key to dbo.MediaTag.TagID. Identifies the media tag applied to the banner. Part of the composite primary key. |
| 3 | Trace | computed | NO | - | VERIFIED | Computed column (not persisted). Captures database session context as JSON: HostName, AppName, SUserName, SPID, DBName, ObjectName. Provides audit attribution for who created or modified each tag assignment. Formula: `concat(...)` building a JSON string from system functions. |
| 4 | ValidFrom | datetime2(7) | NO | - | VERIFIED | System-versioned temporal column. Timestamp when this tag assignment became effective. Automatically set by SQL Server on INSERT/UPDATE. GENERATED ALWAYS AS ROW START. |
| 5 | ValidTo | datetime2(7) | NO | - | VERIFIED | System-versioned temporal column. Timestamp when this tag assignment was superseded or removed. '9999-12-31' for current assignments. GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BannerID | dbo.tblaff_Banners | Implicit FK | The marketing banner being categorized |
| TagID | dbo.MediaTag | Implicit FK | The media tag applied to the banner |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

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

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MediaTagBanner | CLUSTERED PK | BannerID, TagID | - | - | Active |
| IX_MediaTagBanner_TagID | NC | TagID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SYSTEM_VERSIONING | Temporal | History table: History.MediaTagBanner. Tracks all changes to banner-tag assignments over time. |

---

## 8. Sample Queries

### 8.1 Get all tags for a specific banner
```sql
SELECT mtb.BannerID, mt.TagID, mt.TagName
FROM dbo.MediaTagBanner mtb WITH (NOLOCK)
JOIN dbo.MediaTag mt WITH (NOLOCK) ON mtb.TagID = mt.TagID
WHERE mtb.BannerID = 36
```

### 8.2 Get all banners for a specific tag
```sql
SELECT b.BannerID, b.BannerName, b.BannerURL
FROM dbo.MediaTagBanner mtb WITH (NOLOCK)
JOIN dbo.tblaff_Banners b WITH (NOLOCK) ON mtb.BannerID = b.BannerID
WHERE mtb.TagID = 1
```

### 8.3 View tag assignment history (temporal query)
```sql
SELECT BannerID, TagID, ValidFrom, ValidTo
FROM dbo.MediaTagBanner FOR SYSTEM_TIME ALL
WHERE BannerID = 1
ORDER BY ValidFrom
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.MediaTagBanner | Type: Table | Source: fiktivo/dbo/Tables/dbo.MediaTagBanner.sql*
