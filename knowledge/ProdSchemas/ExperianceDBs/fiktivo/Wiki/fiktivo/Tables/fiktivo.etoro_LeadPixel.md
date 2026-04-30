# fiktivo.etoro_LeadPixel

> Legacy log of lead (registration) conversion pixel firings, recording when the platform notified affiliate tracking systems that a referred visitor registered as a lead.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Table |
| **Key Identifier** | Lead_ID (BIGINT IDENTITY, no declared PK) |
| **Partition** | No |
| **Indexes** | 0 (heap - no clustered index) |

---

## 1. Business Meaning

This table logs every lead registration pixel event fired by the affiliate platform. When a visitor referred by an affiliate registers (becomes a "lead"), the platform fires a tracking pixel to confirm the conversion to the affiliate's system. Each row captures the customer and affiliate identifiers, browser/cookie state, and the raw query string parameters at the time of pixel firing.

Lead registration is an early conversion milestone in the affiliate funnel - it occurs after a visitor clicks an affiliate link but before they make a deposit (FTD). This table serves as the audit trail for lead pixel delivery. See [Pixel Types](../../_glossary.md#pixel-types): ID 1 = Registration Pixel.

The table contains 256,016 rows from up to mid-2009 - historical data from the early affiliate platform. No views or stored procedures currently reference this table, indicating the lead pixel mechanism has been modernized into the event-driven commission pipeline (see [Event State](../../_glossary.md#event-state) and [Service Type](../../_glossary.md#service-type) ID 2 = Registration).

---

## 2. Business Logic

### 2.1 Lead Pixel Attribution and Cookie Validation

**What**: Records the moment a lead registration pixel fires and validates the affiliate tracking chain.

**Columns/Parameters Involved**: `Lead_CID`, `Lead_PID`, `Lead_AffiliateID`, `Lead_AffWizCookie`, `AffWizCookieContent`, `Downloaded`

**Rules**:
- Lead_CID is the customer ID of the registering user. Value 0 indicates the CID could not be resolved (bot/crawler or error).
- Lead_PID appears to be a parent/partner ID. Value 0 in all sample data suggests it was rarely populated.
- Lead_AffiliateID may differ from the AffiliateID in AffWizCookieContent - final attribution vs original click attribution.
- Downloaded=1 means the lead also downloaded the application; Downloaded=0 means registration-only without download.
- Lead_TestCookie contains a test string (e.g., 'abc77') used to verify cookie functionality; '0' when cookies were not readable.

**Diagram**:
```
Visitor clicks affiliate banner (cookie set)
       |
       v
Visitor registers on the platform
       |
       v
[etoro_LeadPixel row created]
  Lead_CID = customer ID
  Lead_AffiliateID = attributed affiliate
  QueryString = "cid={cid}&pid={pid}"
       |
       v
Lead pixel fires to affiliate tracking system
```

---

## 3. Data Overview

| Lead_ID | Lead_CID | Lead_AffiliateID | Lead_Browser | Downloaded | Meaning |
|---------|----------|-----------------|--------------|------------|---------|
| 257172 | 1047867 | 14121 | Firefox 2.0.0.20 | true | Full conversion: lead registered AND downloaded the app. AffWiz cookie present with banner 525 and sub-affiliate 'wiki300x250'. |
| 257174 | 1056733 | 3 | Opera 9.64 | false | Registration-only lead (no download). Cookies readable (Lead_TestCookie='abc77') but no AffWiz cookie - direct attribution to affiliate 3. |
| 257176 | 0 | 0 | Mozilla 5.0 | false | Unresolved pixel firing: CID=0 and AffiliateID=0 with cookies unreadable. IP 66.249.66.x is a known Google crawler range - likely a bot hit. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Lead_ID | BIGINT IDENTITY | NO | auto-increment | CODE-BACKED | Unique identifier for each lead pixel firing event. |
| 2 | Lead_Date | DATETIME | NO | getdate() | CODE-BACKED | Timestamp when the lead pixel was fired. Data ranges up to mid-2009. |
| 3 | Lead_CID | BIGINT | YES | - | CODE-BACKED | Customer ID of the registering lead. Confirmed by QueryString: `cid=1056733`. Value 0 means customer could not be resolved (bot or error). |
| 4 | Lead_PID | BIGINT | YES | - | CODE-BACKED | Parent/partner ID. Confirmed by QueryString: `pid=0`. Value 0 in all sample data - rarely populated. |
| 5 | Lead_AffiliateID | BIGINT | YES | - | CODE-BACKED | Affiliate credited for this lead conversion. Value 0 when no affiliate could be attributed. |
| 6 | Lead_Browser | VARCHAR(200) | YES | - | CODE-BACKED | Browser identification at time of pixel firing (e.g., 'Firefox 3.0.11', 'Opera 9.64', 'Mozilla 5.0'). |
| 7 | Lead_ReadCookie | BIT | YES | - | CODE-BACKED | Whether the browser's cookies were readable. 1=readable (tracking functional), 0=blocked (potential bot or privacy settings). |
| 8 | Lead_TestCookie | VARCHAR(20) | YES | - | CODE-BACKED | Test cookie verification string. Value 'abc77' indicates cookies are working. Value '0' indicates cookie test failed. Used to validate browser cookie support. |
| 9 | Lead_AffWizCookie | BIT | YES | - | CODE-BACKED | Whether the AffWiz tracking cookie was found. 1=present (visitor came through affiliate click), 0=not found (direct/organic registration). |
| 10 | AffWizCookieContent | VARCHAR(300) | YES | - | CODE-BACKED | Full AffWiz cookie content. Format: `AffiliateID={id}&ClickBannerID={id}&SubAffiliateID={subId}&ClickDateTime={datetime}`. Empty when Lead_AffWizCookie=0. |
| 11 | QueryString | VARCHAR(300) | YES | - | CODE-BACKED | URL query string from pixel firing. Format: `cid={cid}&pid={pid}`. Primary audit trail for pixel parameters. |
| 12 | IP | NCHAR(16) | YES | - | CODE-BACKED | Visitor's IP address at time of registration/pixel firing. Useful for bot detection (e.g., Google crawler IPs). |
| 13 | Downloaded | BIT | YES | - | CODE-BACKED | Whether the lead also downloaded the application. 1=downloaded (full funnel progression), 0=registration only (no download). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Lead_CID | (external) Customer system | Implicit | Customer who registered as a lead. |
| Lead_AffiliateID | dbo.tblaff_Affiliates | Implicit | Affiliate credited with the lead conversion. |

### 5.2 Referenced By (other objects point to this)

No objects currently reference this table. Lead tracking has been modernized into the event-driven commission pipeline.

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

This table is a **heap** (no clustered index). No nonclustered indexes defined.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Table_1_date | DEFAULT | getdate() for [Lead_Date] - auto-timestamps pixel firing events |

---

## 8. Sample Queries

### 8.1 Lead pixels by affiliate with download rate
```sql
SELECT Lead_AffiliateID,
       COUNT(*) AS TotalLeads,
       SUM(CAST(Downloaded AS INT)) AS WithDownload,
       CAST(SUM(CAST(Downloaded AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,1)) AS DownloadPct
FROM fiktivo.etoro_LeadPixel WITH (NOLOCK)
WHERE Lead_AffiliateID > 0
GROUP BY Lead_AffiliateID
ORDER BY TotalLeads DESC
```

### 8.2 Bot detection - unresolved leads with unreadable cookies
```sql
SELECT Lead_ID, Lead_Date, IP, Lead_Browser
FROM fiktivo.etoro_LeadPixel WITH (NOLOCK)
WHERE Lead_CID = 0 AND Lead_ReadCookie = 0
ORDER BY Lead_Date DESC
```

### 8.3 Leads with AffWiz cookie showing full attribution chain
```sql
SELECT Lead_ID, Lead_CID, Lead_AffiliateID, AffWizCookieContent, QueryString
FROM fiktivo.etoro_LeadPixel WITH (NOLOCK)
WHERE Lead_AffWizCookie = 1
ORDER BY Lead_Date DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.etoro_LeadPixel | Type: Table | Source: fiktivo/fiktivo/Tables/fiktivo.etoro_LeadPixel.sql*
