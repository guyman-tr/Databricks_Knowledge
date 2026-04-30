# dbo.qry_afw_Tier2MemberList1

> Base view for tier 2 member listing, joining tier 2 member relationships with affiliate profile details and type descriptions. Used as a building block for qry_afw_Tier2MemberList.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base tables: tblaff_Tier2Members + tblaff_Affiliates + tblaff_AffiliateTypes |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_afw_Tier2MemberList1 enriches the raw tier 2 member relationships (tblaff_Tier2Members) with the recruited affiliate's full profile data (name, email, website, company, country) and their affiliate type description. This view shows the CHILD affiliate's details for each tier 2 relationship.

This is the inner building block of a two-layer view pattern: qry_afw_Tier2MemberList1 provides child affiliate details, and qry_afw_Tier2MemberList wraps it to also include the PARENT affiliate's details (for side-by-side comparison).

Updated 2023-09-11 (PART-2028) to use AffiliateURLs from the dedicated Affiliate.tblaff_AffiliateURLs table instead of the legacy WebSiteURL column.

---

## 2. Business Logic

### 2.1 Tier 2 Child Affiliate Profile

**What**: Each row shows a recruited affiliate's profile in the context of their tier 2 relationship.

**Columns/Parameters Involved**: `AffiliateID` (parent), `NewMemberID` (child), affiliate profile columns

**Rules**:
- JOIN: tblaff_Affiliates ON AffiliateID = NewMemberID (shows the CHILD affiliate's profile)
- JOIN: tblaff_AffiliateTypes for type description
- WebSiteURL: STRING_AGG from Affiliate.tblaff_AffiliateURLs (pipe-delimited, ordered by WebSiteURLOrdID)
- NOLOCK hints on all tables

---

## 3. Data Overview

View displays tier 2 member details. See dbo.tblaff_Tier2Members for relationship data (23K records).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DateCreated | datetime | YES | - | VERIFIED | Child affiliate's registration date. From tblaff_Affiliates. |
| 2 | AffiliateID | int | YES | - | VERIFIED | Parent/referring affiliate ID. From tblaff_Tier2Members. |
| 3 | NewMemberID | int | YES | - | VERIFIED | Child/recruited affiliate ID. From tblaff_Tier2Members. |
| 4 | LoginName | nvarchar(50) | YES | - | VERIFIED | Child affiliate's login username. From tblaff_Affiliates. |
| 5 | Contact | nvarchar(255) | YES | - | VERIFIED | Child affiliate's contact name. |
| 6 | Email | nvarchar(255) | YES | - | VERIFIED | Child affiliate's email address. |
| 7 | WebSiteTitle | nvarchar(255) | YES | - | VERIFIED | Child affiliate's website title. |
| 8 | WebSiteURL | nvarchar(max) | YES | - | VERIFIED | Child affiliate's website URLs. Computed via STRING_AGG from Affiliate.tblaff_AffiliateURLs, pipe-delimited. Empty strings are excluded. |
| 9 | CompanyName | nvarchar(255) | YES | - | VERIFIED | Child affiliate's company name. |
| 10 | CompanyAddress | nvarchar(255) | YES | - | VERIFIED | Child affiliate's company address. |
| 11 | CountryID | int | NO | - | VERIFIED | Child affiliate's country. |
| 12 | City | nvarchar(100) | YES | - | VERIFIED | Child affiliate's city. |
| 13 | Telephone | nvarchar(50) | YES | - | VERIFIED | Child affiliate's phone number. |
| 14 | SubAffiliateID | nvarchar(1024) | YES | - | VERIFIED | Sub-affiliate tracking tag from the tier 2 relationship. From tblaff_Tier2Members. |
| 15 | Description | nvarchar | YES | - | VERIFIED | Child affiliate's affiliate type description. From tblaff_AffiliateTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| NewMemberID | dbo.tblaff_Affiliates | INNER JOIN | Child affiliate profile data |
| AffiliateID | dbo.tblaff_Tier2Members | Base table | Tier 2 relationship |
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | INNER JOIN | Type description |
| WebSiteURL | Affiliate.tblaff_AffiliateURLs | Correlated subquery | Website URLs (cross-schema) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.qry_afw_Tier2MemberList | INNER JOIN | View | Wraps this view to add parent affiliate details |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_afw_Tier2MemberList1 (view)
  +-- dbo.tblaff_Affiliates (table)
  +-- dbo.tblaff_Tier2Members (table)
  +-- dbo.tblaff_AffiliateTypes (table)
  +-- Affiliate.tblaff_AffiliateURLs (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | INNER JOIN for child profile |
| dbo.tblaff_Tier2Members | Table | Base tier 2 relationships |
| dbo.tblaff_AffiliateTypes | Table | INNER JOIN for type description |
| Affiliate.tblaff_AffiliateURLs | Table | Correlated subquery for website URLs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.qry_afw_Tier2MemberList | View | Wraps this view |

---

## 7. Technical Details

N/A for view.

---

## 8. Sample Queries

### 8.1 Tier 2 members for a parent affiliate
```sql
SELECT NewMemberID, LoginName, Contact, Email, Description
FROM dbo.qry_afw_Tier2MemberList1 WITH (NOLOCK)
WHERE AffiliateID = @ParentAffiliateID
```

### 8.2 Recruited affiliates by type
```sql
SELECT Description, COUNT(*) AS MemberCount
FROM dbo.qry_afw_Tier2MemberList1 WITH (NOLOCK)
GROUP BY Description ORDER BY MemberCount DESC
```

### 8.3 Recent tier 2 recruits
```sql
SELECT TOP 10 AffiliateID AS Parent, NewMemberID AS Child, LoginName, DateCreated
FROM dbo.qry_afw_Tier2MemberList1 WITH (NOLOCK)
ORDER BY DateCreated DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-2028](https://etoro-jira.atlassian.net/browse/PART-2028) | Jira | Use AffiliateURLs from dedicated Affiliate.tblaff_AffiliateURLs table (referenced in code comment, 2023-09-11) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 15 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_afw_Tier2MemberList1 | Type: View | Source: fiktivo/dbo/Views/dbo.qry_afw_Tier2MemberList1.sql*
