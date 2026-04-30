# Tracking.GetAffiliatesPixels

> Bulk retrieval procedure that returns all affiliate conversion tracking pixel configurations from the pixel registry, used by tracking services to cache the complete pixel mapping for real-time pixel firing decisions.

| Property | Value |
|----------|-------|
| **Schema** | Tracking |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from dbo.tblaff_AffiliatePixels |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Tracking.GetAffiliatesPixels is a bulk data retrieval procedure that returns the complete set of affiliate conversion tracking pixel configurations. Each row defines a pixel (tracking code snippet) assigned to a specific affiliate and pixel type combination - controlling which tracking code fires when a conversion event occurs (registration, FTD, etc.).

This procedure exists to enable tracking services to build an in-memory cache of all pixel configurations. Rather than querying per-event, the service loads the entire pixel registry upfront and matches incoming conversion events against the cached rules. This supports the real-time pixel firing pipeline where milliseconds matter.

The procedure performs a simple SELECT * (5 columns) from dbo.tblaff_AffiliatePixels with NOLOCK. No filtering - returns all active pixel configurations for all affiliates.

---

## 2. Business Logic

### 2.1 Full Registry Load

**What**: Returns the complete pixel configuration table for cache initialization.

**Columns/Parameters Involved**: No parameters

**Rules**:
- Returns ALL rows from dbo.tblaff_AffiliatePixels (no filtering)
- Output columns: AffiliateID, SubAffiliateID, PixelTypeID, IsPost, Code
- PixelTypeID values: 1=Registration Pixel, 6=Approved FTD Pixel, 8=Eligible FTD Pixel. See [Pixel Types](../../_glossary.md#pixel-types)
- IsPost: 0=Client-side pixel (JavaScript/HTML embedded in page), 1=Server-side postback (HTTP call from server)
- AffiliateID=NULL entries are global pixels that fire for ALL affiliates
- NOLOCK hint for non-blocking read (configuration data, eventual consistency acceptable)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure takes no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | No input parameters. Returns all rows from dbo.tblaff_AffiliatePixels: AffiliateID (int), SubAffiliateID (int), PixelTypeID (int), IsPost (bit), Code (nvarchar). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_AffiliatePixels | READ (SELECT) | Full table scan returning all pixel configurations |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tracking Service (external) | - | Caller | Loads full pixel registry for in-memory caching |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tracking.GetAffiliatesPixels (procedure)
+-- dbo.tblaff_AffiliatePixels (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliatePixels | Table | Full table SELECT for pixel configuration data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tracking Service (external) | Application | Cache initialization for real-time pixel firing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all pixel configurations
```sql
EXEC Tracking.GetAffiliatesPixels
```

### 8.2 Equivalent direct query with filtering by type
```sql
SELECT AffiliateID, SubAffiliateID, PixelTypeID, IsPost, Code
FROM dbo.tblaff_AffiliatePixels WITH (NOLOCK)
WHERE PixelTypeID = 1 -- Registration pixels only
```

### 8.3 Count pixels by type and delivery method
```sql
SELECT PixelTypeID,
       CASE IsPost WHEN 0 THEN 'Client-Side' WHEN 1 THEN 'Server-Side' END AS DeliveryMethod,
       COUNT(*) AS PixelCount
FROM dbo.tblaff_AffiliatePixels WITH (NOLOCK)
GROUP BY PixelTypeID, IsPost
ORDER BY PixelTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tracking.GetAffiliatesPixels | Type: Stored Procedure | Source: fiktivo/Tracking/Stored Procedures/Tracking.GetAffiliatesPixels.sql*
