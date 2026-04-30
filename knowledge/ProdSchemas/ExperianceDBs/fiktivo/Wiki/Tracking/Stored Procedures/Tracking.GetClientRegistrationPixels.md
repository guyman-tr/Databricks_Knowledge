# Tracking.GetClientRegistrationPixels

> Retrieves client-side registration pixel codes and the affiliate's marketing channel name for a given affiliate, enabling the tracking service to fire registration conversion pixels when a new customer signs up.

| Property | Value |
|----------|-------|
| **Schema** | Tracking |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: registration pixel codes + marketing channel name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Tracking.GetClientRegistrationPixels is called when a new customer registers through an affiliate tracking link. The tracking service needs to fire registration conversion pixels to notify the affiliate's external tracking platform that a registration occurred. This procedure returns the applicable Registration pixel codes (PixelTypeID=1) and the affiliate's marketing expense channel name.

This procedure exists because registration is the first measurable conversion event in the affiliate funnel. When a referred customer creates an account, the registration pixel fires to the affiliate's tracking system, confirming the lead was captured. This is the earliest signal that an affiliate's marketing effort produced a result, even before any deposit or trading occurs.

The procedure returns two result sets: (1) client-side Registration pixel codes - both affiliate-specific AND global (AffiliateID IS NULL), and (2) the affiliate's MarketingExpenseName (marketing channel), which may be used for pixel URL parameterization or routing logic.

---

## 2. Business Logic

### 2.1 Registration Pixel Code Retrieval

**What**: Returns registration pixel codes for the specified affiliate plus global pixels.

**Columns/Parameters Involved**: `@AffiliateID`, PixelTypeID=1, IsPost=0

**Rules**:
- WHERE IsPost=0 (client-side only) AND PixelTypeID=1 (Registration Pixel)
- Combines affiliate-specific (AffiliateID=@AffiliateID) and global (AffiliateID IS NULL) pixels in one WHERE clause using OR
- PixelTypeID=1 = Registration Pixel. See [Pixel Types](../../_glossary.md#pixel-types)
- Returns only the Code column (pixel markup/URL)

### 2.2 Marketing Channel Resolution

**What**: Returns the affiliate's marketing expense channel name.

**Columns/Parameters Involved**: `@AffiliateID`, `MarketingExpenseName`

**Rules**:
- Joins dbo.tblaff_Affiliates to dbo.tblaff_MarketingExpense on MarketingExpenseID
- WHERE AffiliateID=@AffiliateID
- Returns MarketingExpenseName (e.g., "Direct", "Media Buy", "SEO", etc.)
- Used by the tracking service for pixel routing or URL parameter substitution

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int | NO | - | CODE-BACKED | The affiliate whose registration pixel codes should be returned. Also used to look up the affiliate's marketing channel. Passed by the tracking service after the registration event identifies the referring affiliate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AffiliateID | dbo.tblaff_AffiliatePixels | READ | Retrieves Registration pixel codes (PixelTypeID=1, IsPost=0) |
| @AffiliateID | dbo.tblaff_Affiliates | READ | Looks up affiliate's MarketingExpenseID |
| - | dbo.tblaff_MarketingExpense | READ (JOIN) | Resolves MarketingExpenseID to MarketingExpenseName |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tracking Service (external) | - | Caller | Called on customer registration to fire conversion pixels |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tracking.GetClientRegistrationPixels (procedure)
+-- dbo.tblaff_AffiliatePixels (table, cross-schema)
+-- dbo.tblaff_Affiliates (table, cross-schema)
+-- dbo.tblaff_MarketingExpense (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliatePixels | Table | SELECT pixel Code WHERE PixelTypeID=1, IsPost=0 |
| dbo.tblaff_Affiliates | Table | JOIN to resolve affiliate's MarketingExpenseID |
| dbo.tblaff_MarketingExpense | Table | JOIN to resolve MarketingExpenseName |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tracking Service (external) | Application | Fires registration conversion pixels |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get registration pixels for an affiliate
```sql
EXEC Tracking.GetClientRegistrationPixels @AffiliateID = 12345
```

### 8.2 Check which affiliates have registration pixels
```sql
SELECT DISTINCT AffiliateID
FROM dbo.tblaff_AffiliatePixels WITH (NOLOCK)
WHERE PixelTypeID = 1 AND IsPost = 0
ORDER BY AffiliateID
```

### 8.3 List all marketing channels with their affiliate count
```sql
SELECT me.MarketingExpenseName, COUNT(DISTINCT aff.AffiliateID) AS AffiliateCount
FROM dbo.tblaff_Affiliates aff WITH (NOLOCK)
JOIN dbo.tblaff_MarketingExpense me WITH (NOLOCK) ON aff.MarketingExpenseID = me.MarketingExpenseID
GROUP BY me.MarketingExpenseName
ORDER BY AffiliateCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-867 (referenced in SQL comments) | Jira | Original SP creation (Dec 2022, Moshe Ozar, approved by Noga) |

No Confluence pages found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tracking.GetClientRegistrationPixels | Type: Stored Procedure | Source: fiktivo/Tracking/Stored Procedures/Tracking.GetClientRegistrationPixels.sql*
