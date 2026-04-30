# AffiliateClicks.AffiliateClicksImpType

> Table-valued parameter type used to pass batches of aggregated affiliate click and impression counts from the aff-clicksimp AKS service to the database for upsert processing.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateClicks |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | Composite: AffiliateID + BannerID + Campaign + UpdateDate + CountryID + AdditionalData |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateClicks.AffiliateClicksImpType is a table-valued parameter (TVP) type that defines the data contract between the aff-clicksimp application service and the AffiliateClicks.UpdateAffiliateClicks stored procedure. Each row in this type represents one day's aggregated click and impression counts for a specific combination of affiliate, banner, campaign, country, and additional tracking data.

This type exists to enable efficient bulk insertion of click/impression aggregates. Instead of calling the procedure once per record, the application service batches all aggregated rows into a single TVP and sends them in one database call. The column structure mirrors AffiliateClicks.ClicksImpressionsAggregation (minus the computed PartitionCol100 column).

The aff-clicksimp AKS service (owned by the Partners Team) receives click and impression notifications from affiliate tracking links, aggregates them on a 24-hour daily resolution, and passes the aggregated data through this type to the database for storage and reporting in admin and portal dashboards.

---

## 2. Business Logic

### 2.1 Binary Collation for Exact Matching

**What**: Campaign and AdditionalData use Latin1_General_BIN collation for case-sensitive, binary comparison.

**Columns/Parameters Involved**: `Campaign`, `AdditionalData`

**Rules**:
- Latin1_General_BIN ensures exact byte-level comparison when the TVP is joined to the target table in UpdateAffiliateClicks
- This prevents false deduplication: "CampaignA" and "campaigna" are treated as different campaigns
- Matches must be byte-exact for the LEFT JOIN anti-pattern in UpdateAffiliateClicks to work correctly

---

## 3. Data Overview

N/A for User Defined Type. This is a type definition, not a persisted table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | Affiliate identifier. Identifies which affiliate partner's tracking link generated the clicks/impressions. Maps to AffiliateAdmin.Affiliates. |
| 2 | BannerID | int | NO | - | CODE-BACKED | Marketing banner/creative identifier. Identifies which specific ad creative was clicked or viewed. Maps to AffiliateAdmin.Banners. |
| 3 | Campaign | nvarchar(1024) | NO | - | CODE-BACKED | Affiliate marketing campaign tracking tag. Free-text identifier set by the affiliate in their tracking URL. Latin1_General_BIN collation for case-sensitive matching during deduplication. |
| 4 | UpdateDate | date | NO | - | VERIFIED | Date of the aggregation period (24-hour daily resolution per Confluence). All clicks and impressions for this affiliate/banner/campaign/country combination on this date are summed into one row. |
| 5 | CountryID | int | NO | - | CODE-BACKED | Country identifier of the user who clicked/viewed. Used for geographic segmentation of affiliate traffic. Maps to Dictionary.Country. |
| 6 | ClicksCount | int | NO | - | VERIFIED | Total number of clicks on the affiliate tracking link for this aggregation key on this date. A click represents a user actively following the tracking link. Per Confluence: counted by the aff-clicksimp service. |
| 7 | ImpressionsCount | int | NO | - | VERIFIED | Total number of impressions (views) of the affiliate banner/link for this aggregation key on this date. An impression represents the ad being displayed, whether or not the user clicked. Per Confluence: counted by the aff-clicksimp service. |
| 8 | AdditionalData | varchar(512) | NO | - | CODE-BACKED | Additional tracking metadata associated with the click/impression event. Free-text field for extensible tracking parameters. Latin1_General_BIN collation for case-sensitive matching. Added in PART-3693 (Nov 2024). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (it is a type definition).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateClicks.UpdateAffiliateClicks | @AffiliateClicksImp | Parameter Type | Used as READONLY table-valued parameter for batch insert |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateClicks.UpdateAffiliateClicks | Stored Procedure | Parameter type for @AffiliateClicksImp (READONLY TVP) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None. Table types cannot have named constraints. All columns are NOT NULL, enforcing that the application must provide complete data for every row.

---

## 8. Sample Queries

### 8.1 Declare and populate the type for testing
```sql
DECLARE @TestData AffiliateClicks.AffiliateClicksImpType
INSERT INTO @TestData (AffiliateID, BannerID, Campaign, UpdateDate, CountryID, ClicksCount, ImpressionsCount, AdditionalData)
VALUES (12345, 100, 'summer_2026', '2026-04-13', 1, 50, 1200, '')
SELECT * FROM @TestData
```

### 8.2 Call UpdateAffiliateClicks with test data
```sql
DECLARE @Clicks AffiliateClicks.AffiliateClicksImpType
INSERT INTO @Clicks (AffiliateID, BannerID, Campaign, UpdateDate, CountryID, ClicksCount, ImpressionsCount, AdditionalData)
VALUES (12345, 100, 'spring_promo', '2026-04-13', 1, 25, 800, ''),
       (12345, 101, 'spring_promo', '2026-04-13', 2, 10, 300, '')
EXEC AffiliateClicks.UpdateAffiliateClicks @AffiliateClicksImp = @Clicks
```

### 8.3 Compare type structure to target table
```sql
SELECT c.name, c.system_type_name, c.is_nullable
FROM sys.dm_exec_describe_first_result_set(
    N'DECLARE @t AffiliateClicks.AffiliateClicksImpType; SELECT * FROM @t', NULL, 0) c
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Clicks and Impressions](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12188942429) | Confluence | Feature overview: service aggregates click and impression notifications on affiliate tracking links on 24H daily resolution for admin/portal reports |
| [Clicks and Impressions Deployment](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12188516397) | Confluence | Service name: aff-clicksimp, Platform: AKS, Team: Partners Team, Code repo: AffiliateClicks |
| PART-3693 (referenced in SQL comments) | Jira | Added AdditionalData column to ClicksImpressionsAggregation (Nov 2024, Gil Haba) |
| PART-2689 (referenced in SQL comments) | Jira | Original implementation: Affiliate Clicks - Count clicks and impressions (Feb 2024, Gil Haba) |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 2 Confluence + 2 Jira (ref) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateClicks.AffiliateClicksImpType | Type: User Defined Type | Source: fiktivo/AffiliateClicks/User Defined Types/AffiliateClicks.AffiliateClicksImpType.sql*
