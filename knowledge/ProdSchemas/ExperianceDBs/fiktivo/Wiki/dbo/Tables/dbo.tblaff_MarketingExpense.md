# dbo.tblaff_MarketingExpense

> Marketing channel/expense category lookup defining how customer acquisition costs are classified (Affiliate, SEO, SEM, Direct, PR, TV, etc.).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | MarketingExpenseID (BIGINT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

This table defines the marketing channels through which customer acquisition occurs. Each entry represents a distinct acquisition cost category used for budgeting, reporting, and affiliate attribution. Affiliates are assigned to a marketing expense channel via tblaff_Affiliates.MarketingExpenseID, which determines how their costs are reported in financial/marketing analytics.

Without this table, the platform could not categorize customer acquisition costs by channel. Finance and marketing teams use this classification to analyze ROI per channel (e.g., Affiliate vs SEM vs Direct). The table also feeds into the Channels denormalized view.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| MarketingExpenseID | MarketingExpenseName | Meaning |
|-------------------|---------------------|---------|
| 1 | Affiliate | Standard affiliate partner channel - commissions paid to third-party promoters |
| 2 | Media Performance | Paid media campaigns optimized for performance metrics (CPA, CPI) |
| 4 | SEO | Organic search traffic - no direct acquisition cost per customer |
| 5 | SEM | Paid search advertising (Google Ads, Bing) - cost per click/acquisition |
| 24 | TV | Television advertising campaigns - high-reach brand awareness channel |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MarketingExpenseID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Referenced by tblaff_Affiliates.MarketingExpenseID and dbo.Channels.MarketingExpenseID. Non-sequential IDs (gap at 10021-10022) suggest later additions. |
| 2 | MarketingExpenseName | nvarchar(50) | NO | - | CODE-BACKED | Display name of the marketing channel. Values include: Affiliate, Media Performance, Direct, SEO, SEM, SMM, Offline Partners, Local Offices, RAF, Local Partners, Introducing Agents, Networks, Mobile media, PR, Sponsorships, Events, Productions, OOH, Club, systems, Content Partnerships, Media Programmatic, TV, Social Organic, Media CPA, Affiliate Branding. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Affiliates | MarketingExpenseID | Implicit FK | Assigns the affiliate to a marketing cost channel for financial reporting. |
| dbo.Channels | MarketingExpenseID | Implicit FK | Denormalized reference in the channel lookup table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | MarketingExpenseID implicit FK |
| dbo.Channels | Table | MarketingExpenseID implicit FK |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_MarketingExpense | CLUSTERED PK | MarketingExpenseID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all marketing channels
```sql
SELECT MarketingExpenseID, MarketingExpenseName
FROM dbo.tblaff_MarketingExpense WITH (NOLOCK)
ORDER BY MarketingExpenseName
```

### 8.2 Count affiliates per marketing channel
```sql
SELECT me.MarketingExpenseName, COUNT(a.AffiliateID) AS AffiliateCount
FROM dbo.tblaff_MarketingExpense me WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON me.MarketingExpenseID = a.MarketingExpenseID
GROUP BY me.MarketingExpenseName
ORDER BY AffiliateCount DESC
```

### 8.3 Find a specific channel by name
```sql
SELECT MarketingExpenseID, MarketingExpenseName
FROM dbo.tblaff_MarketingExpense WITH (NOLOCK)
WHERE MarketingExpenseName LIKE '%Affiliate%'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_MarketingExpense | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_MarketingExpense.sql*
