# AffiliateAdmin.GetAffiliatePixelByID

> Retrieves a single affiliate tracking pixel's details by its PixelID.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single pixel row (PixelID, AffiliateID, PixelTypeID, Code, IsPost) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.GetAffiliatePixelByID is a detail-retrieval procedure that fetches a single affiliate tracking pixel by its unique identifier. Tracking pixels are HTML/JavaScript snippets embedded in affiliate landing pages or conversion funnels to track user actions such as registrations, deposits, or other conversion events.

This procedure exists because the pixel edit form in the admin portal needs to load the full details of a specific pixel when an admin clicks to view or modify it. The single-row return pattern is optimized for the detail/edit screen workflow.

Data flow: The procedure accepts a single @PixelID parameter and queries dbo.tblaff_AffiliatePixels to return the pixel's ID, owning affiliate, pixel type classification, the actual tracking code snippet, and whether the pixel fires on POST (as opposed to GET/page-load).

---

## 2. Business Logic

No complex business logic detected. This is a simple single-row lookup by primary key. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PixelID | int | NO | - | CODE-BACKED | Unique identifier of the pixel to retrieve from tblaff_AffiliatePixels. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.tblaff_AffiliatePixels | Read | Fetches pixel details (PixelID, AffiliateID, PixelTypeID, Code, IsPost) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.GetAffiliatePixelByID (procedure)
+-- dbo.tblaff_AffiliatePixels (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliatePixels | Table | SELECT for pixel details by PixelID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get pixel by ID
```sql
EXEC AffiliateAdmin.GetAffiliatePixelByID @PixelID = 42;
-- Returns: PixelID, AffiliateID, PixelTypeID, Code, IsPost
```

### 8.2 Manually query pixel with type description
```sql
SELECT p.PixelID, p.AffiliateID, p.PixelTypeID, pt.Description AS PixelType,
       p.Code, p.IsPost
FROM dbo.tblaff_AffiliatePixels p WITH (NOLOCK)
JOIN Dictionary.PixelTypes pt WITH (NOLOCK) ON pt.PixelTypeID = p.PixelTypeID
WHERE p.PixelID = 42;
```

### 8.3 Find all pixels for the same affiliate as a given pixel
```sql
SELECT p2.PixelID, p2.PixelTypeID, p2.Code, p2.IsPost
FROM dbo.tblaff_AffiliatePixels p1 WITH (NOLOCK)
JOIN dbo.tblaff_AffiliatePixels p2 WITH (NOLOCK) ON p2.AffiliateID = p1.AffiliateID
WHERE p1.PixelID = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-4266.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAffiliatePixelByID | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAffiliatePixelByID.sql*
