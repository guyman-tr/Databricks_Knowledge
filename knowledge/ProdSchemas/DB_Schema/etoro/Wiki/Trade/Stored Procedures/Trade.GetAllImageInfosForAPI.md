# Trade.GetAllImageInfosForAPI

> Retrieves all instrument image metadata (dimensions and URIs) for the trading platform API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID, Width, Height, Uri for all instrument images |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the complete set of instrument images used by the trading platform UI. Each instrument (stock, ETF, crypto, commodity) has associated image assets (logos, icons) with specific dimensions and CDN URIs. The API layer caches this data to render instrument logos across the platform.

The procedure exists to serve the instrument image catalog to the API layer in a single bulk read. This avoids per-instrument image lookups and enables the client to cache the full image set on startup.

Data flows from `Trade.InstrumentImages` with no filtering - all images for all instruments are returned. The API layer maps these to the instrument display components.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple bulk read of the image catalog. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. Output columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | FK to Trade.Instrument. Identifies which trading instrument this image belongs to. |
| 2 | Width | INT | YES | - | CODE-BACKED | Image width in pixels. Used by the UI to render the correct image size without layout shift. |
| 3 | Height | INT | YES | - | CODE-BACKED | Image height in pixels. Used alongside Width for proper image rendering. |
| 4 | Uri | NVARCHAR | YES | - | CODE-BACKED | CDN URI for the image asset. The API returns this directly to clients for image loading. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.InstrumentImages | SELECT FROM | Source table for all instrument image data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllImageInfosForAPI (procedure)
+-- Trade.InstrumentImages (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentImages | Table | SELECT FROM - reads all instrument image records |

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

### 8.1 Execute the procedure
```sql
EXEC Trade.GetAllImageInfosForAPI;
```

### 8.2 Find instruments with images of a specific size
```sql
SELECT  InstrumentID, Width, Height, Uri
FROM    Trade.InstrumentImages WITH (NOLOCK)
WHERE   Width = 150 AND Height = 150;
```

### 8.3 Find instruments missing images
```sql
SELECT  i.InstrumentID, imd.InstrumentDisplayName
FROM    Trade.Instrument i WITH (NOLOCK)
        INNER JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON i.InstrumentID = imd.InstrumentID
        LEFT JOIN Trade.InstrumentImages img WITH (NOLOCK) ON i.InstrumentID = img.InstrumentID
WHERE   img.InstrumentID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllImageInfosForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllImageInfosForAPI.sql*
