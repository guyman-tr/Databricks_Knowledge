# AffiliateClicks.ClicksImpressionsAggregation

> Primary storage for daily aggregated click and impression counts on affiliate tracking links, partitioned by affiliate ID for efficient querying and used for admin and portal reporting dashboards.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateClicks |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered index on (UpdateDate, PartitionCol100, AffiliateID, CountryID) |
| **Partition** | Yes - PS_Mod100 on PartitionCol100 (AffiliateID % 100) |
| **Indexes** | 2 active (1 clustered + 1 nonclustered), both PAGE compressed |

---

## 1. Business Meaning

AffiliateClicks.ClicksImpressionsAggregation is the central fact table for the affiliate click and impression tracking system. Each row represents one day's aggregated click and impression counts for a specific combination of affiliate, banner, campaign, country, and additional tracking data. The aggregation granularity is 24-hour daily resolution - all events for a given key on a single date are summed into one row.

This table exists to support affiliate performance reporting in the admin and portal dashboards. Without it, the platform would have no record of how many times affiliate tracking links were clicked or viewed, which is critical for affiliate relationship management, commission verification, and marketing ROI analysis.

Data flows in from the aff-clicksimp AKS service (Partners Team) via the UpdateAffiliateClicks stored procedure, which receives batches of aggregated data through a table-valued parameter (AffiliateClicksImpType). The procedure uses a LEFT JOIN anti-pattern to insert only rows that don't already exist (deduplication by full composite key). Old data (older than 6 months) is purged by DeleteClicksImpressionsAggregationByDate.

---

## 2. Business Logic

### 2.1 Composite Deduplication Key

**What**: Rows are deduplicated on a 6-column composite key that uniquely identifies each daily aggregation bucket.

**Columns/Parameters Involved**: `AffiliateID`, `BannerID`, `Campaign`, `UpdateDate`, `CountryID`, `AdditionalData`

**Rules**:
- UpdateAffiliateClicks uses a LEFT JOIN anti-pattern: it joins the incoming TVP to the table on all 6 key columns (plus PartitionCol100 = AffiliateID%100)
- Only rows WHERE the existing table's AffiliateID IS NULL are inserted (no match = new row)
- This means: same affiliate + banner + campaign + date + country + additionalData = duplicate, skipped
- Campaign and AdditionalData use exact binary comparison (Latin1_General_BIN on the TVP side)
- Rows are INSERT-only - once written, they are never updated (per PART-2546: "Modify to load daily without updates")

### 2.2 Partition Strategy

**What**: Table is partitioned by AffiliateID modulo 100 for distributed data access.

**Columns/Parameters Involved**: `PartitionCol100`, `AffiliateID`

**Rules**:
- PartitionCol100 = AffiliateID % 100 (persisted computed column)
- Partition scheme: PS_Mod100 distributes data across 100 partitions
- Both indexes include PartitionCol100 as a key column for partition elimination
- The clustered index leads with UpdateDate for date-range queries (purge and reporting)
- PAGE compression is applied on all partitions to reduce storage

### 2.3 Data Retention (6-Month Purge)

**What**: Data older than 6 months is automatically purged in batches.

**Columns/Parameters Involved**: `UpdateDate`

**Rules**:
- DeleteClicksImpressionsAggregationByDate defaults to purging rows WHERE UpdateDate <= 6 months ago
- Deletion is batched (default 5,000 rows per iteration) to avoid long-running locks
- The clustered index on UpdateDate ASC enables efficient range-based deletion

---

## 3. Data Overview

| AffiliateID | UpdateDate | BannerID | Campaign | CountryID | ClicksCount | ImpressionsCount | Meaning |
|---|---|---|---|---|---|---|---|
| 1 | 2025-12-07 | 625 | test25528case1 | 0 | 2 | 0 | Test affiliate tracking 2 clicks on a QA test campaign; CountryID=0 indicates unknown/test country |
| 1 | 2025-12-07 | 625 | QARD-57125_testcase1 | 0 | 1 | 0 | QA test case (QARD ticket reference) with additional tracking data "ar3r3d3453534ae" |
| 1 | 2025-12-07 | 625 | AFFID_117443_AffwizclickIDxxxx_yy | 0 | 1 | 0 | Campaign string contains encoded affiliate tracking parameters: affiliate wizard click ID format |
| 1 | 2025-11-11 | 625 | xxxx | 0 | 2 | 0 | Earliest record in dataset - test placeholder campaign |
| 1 | 2025-12-07 | 625 | QARD-57125_testcase2 | 0 | 1 | 0 | Second test case from same QA ticket with matching AdditionalData |

*Note: Current data (84 rows, Nov-Dec 2025) appears to be QA/test data - all AffiliateID=1, BannerID=625, CountryID=0.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | VERIFIED | Affiliate identifier. Identifies which affiliate partner's tracking link generated the clicks/impressions. Part of the 6-column deduplication key. Source of the partition column (AffiliateID % 100). Maps to AffiliateAdmin.Affiliates. |
| 2 | PartitionCol100 | (computed) | NO | AffiliateID % 100 | CODE-BACKED | Persisted computed column: AffiliateID modulo 100. Partition column for the PS_Mod100 scheme. Distributes data across 100 partitions for parallel query execution. Included in both indexes for partition elimination. |
| 3 | UpdateDate | date | NO | - | VERIFIED | Date of the aggregation period (24-hour daily resolution per Confluence). All clicks and impressions for the same key combination on this date are summed into one row. Leading column of the clustered index for efficient date-range queries and purge operations. |
| 4 | BannerID | int | NO | - | CODE-BACKED | Marketing banner/creative identifier. Identifies which specific ad creative was clicked or viewed. Part of the 6-column deduplication key. Maps to AffiliateAdmin.Banners. |
| 5 | Campaign | nvarchar(1024) | NO | - | CODE-BACKED | Affiliate marketing campaign tracking tag. Free-text identifier set by the affiliate in their tracking URL. Part of the deduplication key. May contain encoded tracking parameters (e.g., "AFFID_117443_AffwizclickIDxxxx_yy"). |
| 6 | CountryID | int | NO | - | CODE-BACKED | Country identifier of the user who clicked/viewed. 0 = unknown or unresolved country. Used for geographic segmentation of affiliate traffic. Maps to Dictionary.Country. |
| 7 | ClicksCount | int | NO | - | VERIFIED | Total number of clicks on the affiliate tracking link for this aggregation key on this date. A click represents a user actively following the tracking link. Per Confluence: counted by the aff-clicksimp service. |
| 8 | ImpressionsCount | int | NO | - | VERIFIED | Total number of impressions (views) of the affiliate banner/link for this aggregation key on this date. An impression represents the ad being displayed, whether or not the user clicked. Per Confluence: counted by the aff-clicksimp service. |
| 9 | AdditionalData | varchar(512) | NO | '' (empty string) | CODE-BACKED | Additional tracking metadata associated with the click/impression event. Free-text field for extensible tracking parameters. Part of the deduplication key. Added in PART-3693 (Nov 2024). Default is empty string. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | AffiliateAdmin.Affiliates (cross-schema) | Implicit | References the affiliate partner who owns the tracking link |
| BannerID | AffiliateAdmin.Banners (cross-schema) | Implicit | References the marketing creative/banner |
| CountryID | Dictionary.Country (cross-schema) | Implicit | References the country of the user who clicked/viewed |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateClicks.UpdateAffiliateClicks | - | WRITER (INSERT) | Inserts new aggregation rows via LEFT JOIN anti-pattern deduplication |
| AffiliateClicks.DeleteClicksImpressionsAggregationByDate | - | DELETER (DELETE) | Purges rows older than 6 months in batches |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateClicks.UpdateAffiliateClicks | Stored Procedure | WRITER - INSERT with deduplication |
| AffiliateClicks.DeleteClicksImpressionsAggregationByDate | Stored Procedure | DELETER - batched purge by UpdateDate |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_ClicksImpressionsAggregation_UpdateDate | CLUSTERED | UpdateDate ASC, PartitionCol100 ASC, AffiliateID ASC, CountryID ASC | - | - | Active (PAGE compressed) |
| IX_ClicksImpressionsAggregation_AffiliateID | NONCLUSTERED | AffiliateID ASC, CountryID ASC, BannerID ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| AdditionalData_Default | DEFAULT | DEFAULT ('') for AdditionalData - empty string when no additional tracking data is present |
| PartitionCol100 | COMPUTED PERSISTED | AffiliateID % 100 - partition column for PS_Mod100 scheme |

---

## 8. Sample Queries

### 8.1 Daily clicks and impressions for a specific affiliate
```sql
SELECT UpdateDate,
       SUM(ClicksCount) AS TotalClicks,
       SUM(ImpressionsCount) AS TotalImpressions
FROM AffiliateClicks.ClicksImpressionsAggregation WITH (NOLOCK)
WHERE AffiliateID = 12345
GROUP BY UpdateDate
ORDER BY UpdateDate DESC
```

### 8.2 Top affiliates by click volume in last 30 days
```sql
SELECT AffiliateID,
       SUM(ClicksCount) AS TotalClicks,
       SUM(ImpressionsCount) AS TotalImpressions,
       CASE WHEN SUM(ImpressionsCount) > 0
            THEN CAST(SUM(ClicksCount) AS FLOAT) / SUM(ImpressionsCount)
            ELSE 0 END AS CTR
FROM AffiliateClicks.ClicksImpressionsAggregation WITH (NOLOCK)
WHERE UpdateDate >= DATEADD(DAY, -30, CAST(GETUTCDATE() AS DATE))
GROUP BY AffiliateID
ORDER BY TotalClicks DESC
```

### 8.3 Campaign performance breakdown with country
```sql
SELECT Campaign, CountryID, BannerID,
       SUM(ClicksCount) AS Clicks,
       SUM(ImpressionsCount) AS Impressions
FROM AffiliateClicks.ClicksImpressionsAggregation WITH (NOLOCK)
WHERE AffiliateID = 12345
  AND UpdateDate >= '2026-01-01'
GROUP BY Campaign, CountryID, BannerID
ORDER BY Clicks DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Clicks and Impressions](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12188942429) | Confluence | Feature overview: aggregation on 24H daily resolution, columns spec, data feeds admin and portal reports |
| [Clicks and Impressions Deployment](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12188516397) | Confluence | Service: aff-clicksimp (AKS), Team: Partners Team, repo: AffiliateClicks |
| PART-2689 (referenced in SQL comments) | Jira | Original implementation: Affiliate Clicks feature (Feb 2024, Gil Haba) |
| PART-2546 (referenced in SQL comments) | Jira | Modified to load daily without updates (Oct 2024, Gil Haba) |
| PART-3693 (referenced in SQL comments) | Jira | Added AdditionalData column (Nov 2024, Gil Haba) |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.3/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 2 Confluence + 3 Jira (ref) | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateClicks.ClicksImpressionsAggregation | Type: Table | Source: fiktivo/AffiliateClicks/Tables/AffiliateClicks.ClicksImpressionsAggregation.sql*
