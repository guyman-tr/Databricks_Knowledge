# dbo.tblaff_HeaderSpiderList

> Known bot/spider HTTP User-Agent header patterns used to filter non-human traffic from affiliate click and impression tracking.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

This table contains User-Agent header strings that identify known web crawlers, bots, and spiders. When affiliate tracking URLs are clicked, the system checks the request's User-Agent against this list. Matches are filtered out to prevent bot traffic from inflating affiliate click/impression counts and triggering fraudulent commissions.

Managed by admin users with Preferences_SpiderHeaders permission in tblaff_User. Currently 73 entries including patterns like "bandit", "Crawler", "Borz", "cherry", "collect".

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| ID | Header | Meaning |
|----|--------|---------|
| 2 | bandit | Identifies the "Bandit" web scraper - traffic from this bot is excluded from affiliate click counts |
| 6 | Crawler | Generic crawler User-Agent pattern - matches any bot identifying as a crawler |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Auto-incrementing identifier. |
| 2 | Header | nvarchar(255) | NO | - | CODE-BACKED | User-Agent header pattern to match against incoming requests. Partial match strings (e.g., "Crawler" matches "Googlebot/2.1 Crawler"). Used for bot traffic filtering in click/impression tracking. |

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

No dependents found in SSDT stored procedures.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_HeaderSpiderList | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all spider header patterns
```sql
SELECT ID, Header FROM dbo.tblaff_HeaderSpiderList WITH (NOLOCK) ORDER BY Header
```

### 8.2 Check if a User-Agent matches a known spider
```sql
SELECT Header FROM dbo.tblaff_HeaderSpiderList WITH (NOLOCK)
WHERE 'Mozilla/5.0 (compatible; Googlebot/2.1)' LIKE '%' + Header + '%'
```

### 8.3 Count spider patterns
```sql
SELECT COUNT(*) AS PatternCount FROM dbo.tblaff_HeaderSpiderList WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_HeaderSpiderList | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_HeaderSpiderList.sql*
