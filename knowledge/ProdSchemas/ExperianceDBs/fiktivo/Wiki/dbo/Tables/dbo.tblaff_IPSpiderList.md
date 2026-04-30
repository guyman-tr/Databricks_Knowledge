# dbo.tblaff_IPSpiderList

> Known bot/spider IP addresses used to filter non-human traffic from affiliate click and impression tracking.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

This table stores IP addresses of known web crawlers, bots, and spiders. Unlike tblaff_IPBlocking (manually curated blocklist), this table specifically targets known spider/crawler IPs. Companion to tblaff_HeaderSpiderList which matches by User-Agent header. Together they provide two layers of bot detection for affiliate traffic quality assurance. Managed by admin users with Preferences_SpiderIPs permission. Currently empty (0 rows).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

Table is currently empty (0 rows).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Auto-incrementing identifier. |
| 2 | IPAddress | nvarchar(85) | NO | - | CODE-BACKED | IP address of a known spider/crawler. Supports IPv4 and IPv6. Checked during affiliate click/impression processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

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
| PK_tblaff_IPSpiderList | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all spider IPs
```sql
SELECT ID, IPAddress FROM dbo.tblaff_IPSpiderList WITH (NOLOCK) ORDER BY IPAddress
```

### 8.2 Check if an IP is a known spider
```sql
SELECT COUNT(*) AS IsSpider FROM dbo.tblaff_IPSpiderList WITH (NOLOCK) WHERE IPAddress = '66.249.66.1'
```

### 8.3 Combined bot check (header + IP)
```sql
SELECT 'IP Match' AS MatchType, IPAddress AS Pattern
FROM dbo.tblaff_IPSpiderList WITH (NOLOCK) WHERE IPAddress = '66.249.66.1'
UNION ALL
SELECT 'Header Match', Header
FROM dbo.tblaff_HeaderSpiderList WITH (NOLOCK) WHERE 'Googlebot/2.1' LIKE '%' + Header + '%'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_IPSpiderList | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_IPSpiderList.sql*
