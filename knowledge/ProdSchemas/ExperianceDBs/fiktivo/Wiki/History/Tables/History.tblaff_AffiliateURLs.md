# History.tblaff_AffiliateURLs

> SQL Server temporal history table storing all historical versions of affiliate website URLs used for traffic validation and tracking.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | AffiliateID + WebSiteURLOrdID (composite - identifies a specific URL slot for an affiliate across versions) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.tblaff_AffiliateURLs is the system-versioned temporal history table for Affiliate.tblaff_AffiliateURLs. It captures every historical version of the website URLs registered by affiliates for tracking and traffic validation purposes. Each affiliate can register multiple URLs, and each row represents one URL at a specific ordinal position for a given affiliate at a point in time.

This table supports compliance and fraud prevention by preserving a complete audit trail of affiliate website changes. When an affiliate updates their registered website URL - for example, switching domains, correcting a typo, or replacing one site with another - the prior URL is preserved here. This history is used to validate that affiliate traffic originates from approved websites and to investigate cases where traffic sources appear inconsistent with the affiliate's declared sites.

Data flows in automatically via SQL Server's temporal mechanism whenever rows in the base table Affiliate.tblaff_AffiliateURLs are updated or deleted. With 613 historical rows, URL changes occur at a moderate pace as affiliates evolve their web properties over time.

---

## 2. Business Logic

### 2.1 Affiliate URL Versioning

**What**: Tracks changes to the website URLs registered by affiliates for traffic validation and tracking.

**Columns/Parameters Involved**: `AffiliateID`, `WebSiteURL`, `WebSiteURLOrdID`, `UpdateDate`, `ValidFrom`, `ValidTo`

**Rules**:
- AffiliateID + WebSiteURLOrdID together identify a specific URL slot for an affiliate
- WebSiteURLOrdID is the ordinal position (1st URL, 2nd URL, etc.) allowing affiliates to register multiple sites
- WebSiteURL stores the full URL (up to 255 characters) of the affiliate's registered website
- UpdateDate records the application-level timestamp of the last update (may differ from ValidFrom which is the system timestamp)
- These URLs are used to validate that affiliate traffic originates from approved websites
- Historical records enable investigation of URL changes during fraud or compliance reviews

---

## 3. Data Overview

The table contains 613 historical rows representing superseded versions of affiliate website URL records. URL changes occur as affiliates rebrand, switch domains, or register additional web properties over the course of their partnership.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | The affiliate who registered this website URL. References dbo.tblaff_Affiliates.AffiliateID. |
| 2 | WebSiteURL | nvarchar(255) | NO | - | CODE-BACKED | The full website URL registered by the affiliate for tracking and validation. |
| 3 | WebSiteURLOrdID | int | NO | - | CODE-BACKED | Ordinal position of the URL in the affiliate's list (1st URL, 2nd URL, etc.). |
| 4 | UpdateDate | datetime | YES | - | CODE-BACKED | Application-level timestamp of the last update to this URL record. NULL if not tracked. |
| 5 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context. |
| 6 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | When this version became active. |
| 7 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | When this version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | Affiliate.tblaff_AffiliateURLs | Temporal History | Stores historical versions of the base table |
| AffiliateID | dbo.tblaff_Affiliates | Implicit FK | The affiliate who registered this website URL |

### 5.2 Referenced By (other objects point to this)

Accessed implicitly via temporal queries on Affiliate.tblaff_AffiliateURLs.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.tblaff_AffiliateURLs (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate.tblaff_AffiliateURLs | Table | SYSTEM_VERSIONING |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_tblaff_AffiliateURLs | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View full URL history for an affiliate
```sql
SELECT AffiliateID, WebSiteURL, WebSiteURLOrdID, UpdateDate, ValidFrom, ValidTo
FROM Affiliate.tblaff_AffiliateURLs FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE AffiliateID = 12345
ORDER BY WebSiteURLOrdID, ValidFrom
```

### 8.2 Check which URLs an affiliate had registered at a specific date
```sql
SELECT AffiliateID, WebSiteURL, WebSiteURLOrdID, UpdateDate
FROM Affiliate.tblaff_AffiliateURLs FOR SYSTEM_TIME AS OF '2025-06-01' WITH (NOLOCK)
WHERE AffiliateID = 12345
ORDER BY WebSiteURLOrdID
```

### 8.3 Find recently changed affiliate URLs
```sql
SELECT AffiliateID, WebSiteURL, WebSiteURLOrdID, UpdateDate, ValidFrom, ValidTo
FROM History.tblaff_AffiliateURLs WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.tblaff_AffiliateURLs | Type: Table | Source: fiktivo/History/Tables/History.tblaff_AffiliateURLs.sql*
