# fiktivo.etoro_LeadPixel

> Records lead conversion pixel events fired when potential customers register or visit a tracking page, capturing affiliate attribution, customer identity, and browser/cookie state for the registration step of the affiliate funnel.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Table |
| **Key Identifier** | Lead_ID (BIGINT IDENTITY) |
| **Partition** | No |
| **Indexes** | 0 (heap - no clustered index) |

---

## 1. Business Meaning

etoro_LeadPixel records lead tracking pixel events fired when a potential customer interacts with an eToro registration or landing page that contains the affiliate lead tracking pixel. Each row captures a pixel fire event with the customer's identity, affiliate attribution, and browser state. This is part of the early-stage conversion funnel, tracking leads that may later convert to registrations, deposits, and sales.

This table provides pixel-level evidence of lead generation for the affiliate system. The affiliate tracking pixel fires on lead pages and records whether the AffiliateWizard cookie is present, allowing the system to attribute leads to the correct affiliate even if the pixel URL parameters differ from the original click attribution.

Data enters this table when the lead tracking pixel fires. The table contains 256K+ records from the 2007-2009 era. No views or stored procedures in the fiktivo schema reference this table directly, suggesting it serves as raw pixel event storage that is consumed by external reporting or the dbo-schema affiliate commission tables (tblaff_Leads, tblaff_Leads_Commissions).

---

## 2. Business Logic

### 2.1 Lead Cookie Attribution

**What**: The system captures browser cookie state at pixel fire time to reconcile affiliate attribution between the pixel URL and the original click cookie.

**Columns/Parameters Involved**: `Lead_ReadCookie`, `Lead_TestCookie`, `Lead_AffWizCookie`, `AffWizCookieContent`

**Rules**:
- `Lead_ReadCookie` indicates if browser cookies were readable at pixel fire time
- `Lead_TestCookie` contains a test cookie value ('abc77' in sample data) used to verify cookie functionality
- `Lead_AffWizCookie` indicates if the AffiliateWizard tracking cookie was present
- When `Lead_AffWizCookie=true`, `AffWizCookieContent` contains the original click attribution data with AffiliateID, ClickBannerID, SubAffiliateID, and ClickDateTime
- `Downloaded` flag tracks whether the lead also downloaded the software

---

## 3. Data Overview

| Lead_ID | Lead_CID | Lead_AffiliateID | Lead_Browser | Lead_AffWizCookie | Downloaded | Meaning |
|---|---|---|---|---|---|---|
| 257174 | 1056733 | 3 | Opera 9.64 | false | false | Lead pixel fired for customer 1056733 attributed to house affiliate (ID=3). No AffWiz cookie present, customer has not downloaded the software. Cookie test passed ('abc77'). |
| 257172 | 1047867 | 14121 | Firefox 2.0.0.20 | true | true | Lead with AffWiz cookie from affiliate 14121, banner 525, sub-affiliate 'wiki300x250'. Customer also downloaded - a high-quality lead progressing through the funnel. |
| 257176 | 0 | 0 | Mozilla 5.0 | false | false | Pixel fire with no customer identity (CID=0) and no affiliate attribution (AffiliateID=0). QueryString='cid=' suggests the pixel loaded without valid parameters - likely a bot or crawler (IP 66.249.66.x is Google). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Lead_ID | bigint (IDENTITY) | NO | Auto-increment | CODE-BACKED | Unique identifier for each lead pixel event. Auto-generated sequence. |
| 2 | Lead_Date | datetime | NO | GETDATE() | CODE-BACKED | Timestamp when the lead pixel fired. Defaults to current time. Records the precise moment of the lead event. |
| 3 | Lead_CID | bigint | YES | - | CODE-BACKED | Customer ID associated with this lead event. Value of 0 indicates the pixel fired without a valid customer context (bots, crawlers, or missing parameters). |
| 4 | Lead_PID | bigint | YES | - | NAME-INFERRED | Provider ID or Parent ID associated with the lead. All sample data shows 0, suggesting this field was rarely used or deprecated. |
| 5 | Lead_AffiliateID | bigint | YES | - | CODE-BACKED | Affiliate ID attributed with this lead event. Passed via pixel URL parameters. Value of 0 means no affiliate attribution (organic or invalid pixel fire). |
| 6 | Lead_Browser | varchar(200) | YES | - | CODE-BACKED | Browser identification at pixel fire time (e.g., 'Firefox 3.0.11', 'Opera 9.64', 'Mozilla 5.0'). Used for analytics and debugging. |
| 7 | Lead_ReadCookie | bit | YES | - | CODE-BACKED | Whether cookies were readable by the pixel at fire time. true = cookies accessible, false = blocked. Determines reliability of cookie-based attribution. |
| 8 | Lead_TestCookie | varchar(20) | YES | - | CODE-BACKED | Test cookie value used to verify cookie functionality. Sample data shows 'abc77' for browsers with cookies enabled, '0' when disabled. Enables diagnosing cookie-related attribution failures. |
| 9 | Lead_AffWizCookie | bit | YES | - | CODE-BACKED | Whether the AffiliateWizard tracking cookie was present. true = original click attribution data available in AffWizCookieContent, false = rely on pixel URL parameters only. |
| 10 | AffWizCookieContent | varchar(300) | YES | - | CODE-BACKED | Raw AffWiz cookie content containing original click data. Format: 'AffiliateID={id}&ClickBannerID={id}&SubAffiliateID={code}&ClickDateTime={datetime}'. Larger field (300 chars) than FTDPixel (100 chars) to accommodate longer sub-affiliate IDs. |
| 11 | QueryString | varchar(300) | YES | - | CODE-BACKED | Full query string from the lead pixel URL. Contains 'cid={id}&pid={id}' parameters. Primary source for customer identity at lead time. |
| 12 | IP | nchar(16) | YES | - | CODE-BACKED | IP address of the user at lead pixel fire time. Can identify bots (e.g., Google crawlers at 66.249.66.x) and is used for geographic attribution. |
| 13 | Downloaded | bit | YES | - | CODE-BACKED | Whether this lead has also downloaded the software. true = lead has progressed to download stage (higher quality lead), false = registration/visit only. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Lead_AffiliateID | dbo.tblaff_Affiliates | Implicit | References the affiliate credited with this lead |
| Lead_CID | External customer table | Implicit | References the customer who triggered the lead pixel |

### 5.2 Referenced By (other objects point to this)

No objects in the fiktivo schema reference this table.

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

This table has no indexes (heap table). Like etoro_FTDPixel, the lack of indexes suggests it is an append-only pixel event log with infrequent query needs.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Table_1_date | DEFAULT | GETDATE() for Lead_Date - auto-timestamps lead pixel events. Note: constraint name 'Table_1' suggests this table was renamed from a generic placeholder. |

---

## 8. Sample Queries

### 8.1 Recent lead events with valid customer attribution
```sql
SELECT TOP 10 Lead_ID, Lead_Date, Lead_CID, Lead_AffiliateID, Lead_Browser, Downloaded
FROM fiktivo.etoro_LeadPixel WITH (NOLOCK)
WHERE Lead_CID > 0
ORDER BY Lead_Date DESC
```

### 8.2 Leads by affiliate with download conversion rate
```sql
SELECT Lead_AffiliateID,
       COUNT(*) AS TotalLeads,
       SUM(CAST(Downloaded AS INT)) AS WithDownload,
       CAST(SUM(CAST(Downloaded AS INT)) AS FLOAT) / NULLIF(COUNT(*), 0) * 100 AS DownloadPct
FROM fiktivo.etoro_LeadPixel WITH (NOLOCK)
WHERE Lead_AffiliateID > 0
GROUP BY Lead_AffiliateID
ORDER BY COUNT(*) DESC
```

### 8.3 Bot detection - leads with CID=0 grouped by IP
```sql
SELECT TOP 10 IP, COUNT(*) AS FireCount
FROM fiktivo.etoro_LeadPixel WITH (NOLOCK)
WHERE Lead_CID = 0
GROUP BY IP
ORDER BY COUNT(*) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.5/10 (Elements: 9.2/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.etoro_LeadPixel | Type: Table | Source: fiktivo/fiktivo/Tables/fiktivo.etoro_LeadPixel.sql*
