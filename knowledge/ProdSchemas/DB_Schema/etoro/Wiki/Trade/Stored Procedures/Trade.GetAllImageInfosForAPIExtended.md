# Trade.GetAllImageInfosForAPIExtended

> Extended version of the image API that includes background/text colors and supports optional single-instrument filtering.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns instrument image data with color information, optionally filtered by InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the extended variant of `Trade.GetAllImageInfosForAPI`. It returns the same image metadata (dimensions, URI) plus additional color properties (BackgroundColor, TextColor) used by the UI for branded instrument cards. It also supports optional filtering by a single InstrumentID, allowing the API to refresh one instrument's images without reloading the entire catalog.

The procedure exists because newer UI designs require color-coordinated instrument display cards. The background and text colors ensure proper contrast and brand consistency when rendering instrument logos.

Data flows from `Trade.InstrumentImages`. When @InstrumentID is NULL, all images are returned (bulk mode). When provided, only images for that instrument are returned (single-instrument mode).

---

## 2. Business Logic

### 2.1 Optional Instrument Filter

**What**: Supports both bulk and single-instrument retrieval using the same procedure.

**Columns/Parameters Involved**: `@InstrumentID`, `InstrumentID`

**Rules**:
- `WHERE @InstrumentID IS NULL OR InstrumentID = @InstrumentID`
- When @InstrumentID is NULL, returns ALL images (same as GetAllImageInfosForAPI but with extra columns)
- When @InstrumentID is provided, returns only that instrument's images

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | YES | NULL | CODE-BACKED | Optional filter. When provided, returns images only for this instrument. When NULL, returns all instrument images. |
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | FK to Trade.Instrument. Identifies which trading instrument this image belongs to. |
| 3 | Width | INT | YES | - | CODE-BACKED | Image width in pixels for UI rendering. |
| 4 | Height | INT | YES | - | CODE-BACKED | Image height in pixels for UI rendering. |
| 5 | Uri | NVARCHAR | YES | - | CODE-BACKED | CDN URI for the image asset. |
| 6 | BackgroundColor | NVARCHAR | YES | - | CODE-BACKED | Hex color code for the instrument card background in the UI. Ensures brand-consistent display. |
| 7 | TextColor | NVARCHAR | YES | - | CODE-BACKED | Hex color code for text overlaid on the instrument card. Ensures readable contrast against BackgroundColor. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.InstrumentImages | SELECT FROM | Source table for image data including colors |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllImageInfosForAPIExtended (procedure)
+-- Trade.InstrumentImages (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentImages | Table | SELECT FROM - reads image records with optional filter |

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

### 8.1 Get all images with colors
```sql
EXEC Trade.GetAllImageInfosForAPIExtended;
```

### 8.2 Get images for a specific instrument
```sql
EXEC Trade.GetAllImageInfosForAPIExtended @InstrumentID = 1001;
```

### 8.3 Find instruments with dark backgrounds
```sql
SELECT  InstrumentID, Width, Height, Uri, BackgroundColor, TextColor
FROM    Trade.InstrumentImages WITH (NOLOCK)
WHERE   BackgroundColor IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllImageInfosForAPIExtended | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllImageInfosForAPIExtended.sql*
