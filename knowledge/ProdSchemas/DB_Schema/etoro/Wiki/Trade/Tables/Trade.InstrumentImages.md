# Trade.InstrumentImages

> Stores logo and avatar image URLs per instrument at multiple resolutions - drives UI display in the trading app, API responses, and Facebook product feeds.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ImageID (INT, PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK, IX_InstrumentID) |

---

## 1. Business Meaning

Trade.InstrumentImages stores the visual assets (logos, avatars) for each tradeable instrument at multiple pixel dimensions. When a user browses markets, opens a position, or searches for an instrument, the platform displays an image - typically at 35x35 (list thumbnails), 50x50 (medium cards), or 150x150 (large detail views). This table maps each instrument to CDN or S3 URLs for those resolutions, enabling responsive UI and consistent branding across web and mobile.

This table exists because different parts of the eToro UI require different image sizes - discovery lists use small thumbnails, instrument detail pages use large images, and Facebook product feeds require 150x150. Without InstrumentImages, the platform could not reliably serve the correct image for each context. Multiple rows per instrument (one per size) allow efficient lookups without resizing at request time.

Data flows: Rows are created by `Stocks.AddNewStock` (when adding new stocks - inserts 35, 50, 80, 90, 150 sizes from S3 pattern), `Trade.InsertInstrumentMetadataSecurityOpsAPI` (Security Ops API instrument ingestion), `Internal.Newcurrency` / `Internal.Newcurrency_3163` (legacy instrument setup from XML), and `Trade.InsertInstrumentRealTable` (bulk loads). `Trade.GetAllImageInfosForAPI` and `Trade.GetAllImageInfosForAPIExtended` expose the data for APIs. `dbo.V_DataForFB` and `dbo.FaceBook2FTP` join for Facebook product feeds (Width=150). `Trade.GetInstrumentsData` joins for ImageUrl (150x150). Deletion cascades from `dbo.Delete_Instrument` and `Stocks.AddNewStock` (replace-all pattern: delete existing, insert new).

---

## 2. Business Logic

### 2.1 Multi-Resolution Image Mapping

**What**: Each instrument can have multiple image rows - one per (Width, Height) pair - allowing the same logo to be served at different resolutions for different UI contexts.

**Columns/Parameters Involved**: `InstrumentID`, `Width`, `Height`, `Uri`

**Rules**:
- Common sizes from code: 35, 50, 80, 90, 150 (Stocks.AddNewStock), plus 70 (observed in live data). Sizes are typically square (Width = Height).
- Uri points to CDN (e.g., etoro-cdn.etorostatic.com/market-avatars/{symbol}/35x35.png) or S3 (s3.etoro.com/images/markets/avatars/{symbol}/150x150.png). Legacy paths like /medium/EUR_USD.png also exist.
- API consumers filter by size: Trade.GetInstrumentsData uses `Width = 150 AND Height = 150`. Facebook feeds use `Width = 150`.
- No unique constraint on (InstrumentID, Width, Height) - multiple rows per size may exist (legacy data).

**Diagram**:
```
InstrumentID=1 (EUR/USD)
  -> 35x35:  .../eur-usd/35x35.png  (list thumbnails)
  -> 50x50:  .../eur-usd/50x50.png  (medium cards)
  -> 70x70:  .../eur-usd/70x70.png
  -> 80x80:  /medium/EUR_USD.png
  -> 150x150: .../eur-usd/150x150.png  (detail, Facebook feed)
```

### 2.2 URI Pattern by Source

**What**: Uri format depends on how the instrument was added - new instruments use CDN/S3, legacy use relative paths.

**Columns/Parameters Involved**: `Uri`

**Rules**:
- Stocks.AddNewStock builds: `https://s3.etoro.com/images/markets/avatars/{SymbolFull}/{Dim}x{Dim}.png`
- Trade.InsertInstrumentMetadataSecurityOpsAPI receives full URLs from caller.
- Internal.Newcurrency parses from XML `NewInstrumentSchema/Trade.InstrumentImages/Row`.
- Legacy rows may have /medium/{SYMBOL}.png style paths.

---

## 3. Data Overview

| ImageID | InstrumentID | Width | Height | Uri | Meaning |
|---|---|---|---|---|---|
| 1 | 1 | 35 | 35 | https://etoro-cdn.etorostatic.com/market-avatars/eur-usd/35x35.png | EUR/USD 35x35 thumbnail - used in instrument lists and compact views. CDN-hosted. |
| 46 | 1 | 80 | 80 | /medium/EUR_USD.png | EUR/USD 80x80 - legacy path. Older ingestion used relative paths. |
| 91 | 1 | 50 | 50 | https://etoro-cdn.etorostatic.com/market-avatars/eur-usd/50x50.png | EUR/USD 50x50 medium size - card views. |
| 176 | 1 | 150 | 150 | https://etoro-cdn.etorostatic.com/market-avatars/eur-usd/150x150.png | EUR/USD 150x150 - detail page and Facebook product feed. Most API consumers use this size. |
| 1296 | 1 | 70 | 70 | https://etoro-cdn.etorostatic.com/market-avatars/eur-usd/70x70.png | EUR/USD 70x70 - intermediate size, possibly for specific UI contexts. |

**Selection criteria for the 5 rows:**
- All for InstrumentID=1 (EUR/USD) to show multiple resolutions per instrument.
- Mix of CDN and legacy Uri patterns.
- Common sizes: 35, 50, 70, 80, 150.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ImageID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key. IDENTITY, NOT FOR REPLICATION. Allocated on INSERT. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument.InstrumentID. The instrument this image row belongs to. |
| 3 | Width | numeric(8,2) | YES | - | CODE-BACKED | Image width in pixels. Common values: 35, 50, 70, 80, 90, 150. Used with Height to identify resolution. NULL allowed (e.g., SVG rows from Trade.InsertInstrumentMetadataSecurityOpsAPI). |
| 4 | Height | numeric(8,2) | YES | - | CODE-BACKED | Image height in pixels. Typically equals Width for square avatars. NULL for non-raster (SVG). |
| 5 | Uri | varchar(250) | YES | - | CODE-BACKED | Full URL or path to the image. CDN: etoro-cdn.etorostatic.com/market-avatars/{symbol}/{W}x{H}.png. S3: s3.etoro.com/images/markets/avatars/{symbol}/{W}x{H}.png. Legacy: /medium/{SYMBOL}.png. |
| 6 | BackgroundColor | varchar(250) | YES | - | NAME-INFERRED | Optional background color for image display (e.g., hex or CSS color). NULL in sampled data - may be unused or for future theming. |
| 7 | TextColor | varchar(250) | YES | - | NAME-INFERRED | Optional text/overlay color. NULL in sampled data - may be unused or for future theming. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | Each image row belongs to one instrument. FK_InstrumentImages_Instrument. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetAllImageInfosForAPI | - | Reader | Selects InstrumentID, Width, Height, Uri for API consumers. |
| Trade.GetAllImageInfosForAPIExtended | - | Reader | Same as above, extended API. |
| Trade.GetInstrumentsData | - | JOIN | LEFT JOIN for ImageUrl (Width=150, Height=150). |
| dbo.V_DataForFB | - | JOIN | Joins for image_link (Width=150) in Facebook product feed. |
| dbo.FaceBook2FTP | - | JOIN | Joins for image_link (Width=150) in Facebook FTP feed. |
| Stocks.AddNewStock | - | Writer/Deleter | Deletes existing, inserts new at 35, 50, 80, 90, 150. |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | - | Writer | Inserts rows from Security Ops API. |
| Internal.Newcurrency / Internal.Newcurrency_3163 | - | Writer | Inserts from XML during legacy instrument setup. |
| dbo.Delete_Instrument | - | Deleter | Deletes by InstrumentID when instrument is removed. |
| Trade.CheckValidInstruments | InstrumentID | Validator | Checks InstrumentImages exists for instrument validation. |
| Monitor.CheckInsertInstrumentNewProcess | - | Reader | Counts distinct InstrumentID for monitoring. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentImages (table)
  (no code-level dependencies - tables are leaf nodes)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target for InstrumentID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetAllImageInfosForAPI | Procedure | Reads InstrumentID, Width, Height, Uri. |
| Trade.GetAllImageInfosForAPIExtended | Procedure | Reads InstrumentID, Width, Height, Uri. |
| Trade.GetInstrumentsData | Procedure | LEFT JOIN for ImageUrl. |
| dbo.V_DataForFB | View | JOIN for image_link. |
| dbo.FaceBook2FTP | View | JOIN for image_link. |
| Stocks.AddNewStock | Procedure | DELETE, INSERT. |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | Procedure | INSERT. |
| Internal.Newcurrency | Procedure | INSERT. |
| Internal.Newcurrency_3163 | Procedure | INSERT. |
| dbo.Delete_Instrument | Procedure | DELETE. |
| Trade.CheckValidInstruments | Procedure | SELECT EXISTS. |
| Monitor.CheckInsertInstrumentNewProcess | Procedure | COUNT. |
| Trade.CheckInstrumentIdExistsSecurityOpsAPI | Procedure | SELECT EXISTS. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InstrumentImages | CLUSTERED | ImageID | - | - | Active |
| IX_InstrumentID | NC | InstrumentID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_InstrumentImages | PRIMARY KEY | ImageID - unique identifier. |
| FK_InstrumentImages_Instrument | FOREIGN KEY | InstrumentID references Trade.Instrument(InstrumentID). |

---

## 8. Sample Queries

### 8.1 Get all image sizes for an instrument
```sql
SELECT ImageID, InstrumentID, Width, Height, Uri
FROM Trade.InstrumentImages WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY Width, Height;
```

### 8.2 Get 150x150 image URLs for API (primary display size)
```sql
SELECT imd.InstrumentID, imd.SymbolFull, ii.Uri AS ImageUrl
FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
INNER JOIN Trade.Instrument i WITH (NOLOCK) ON i.InstrumentID = imd.InstrumentID
LEFT JOIN Trade.InstrumentImages ii WITH (NOLOCK)
  ON ii.InstrumentID = imd.InstrumentID AND ii.Width = 150 AND ii.Height = 150
WHERE imd.InstrumentVisible = 1;
```

### 8.3 Instruments with missing 150x150 image
```sql
SELECT imd.InstrumentID, imd.SymbolFull, imd.InstrumentDisplayName
FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
LEFT JOIN Trade.InstrumentImages ii WITH (NOLOCK)
  ON ii.InstrumentID = imd.InstrumentID AND ii.Width = 150 AND ii.Height = 150
WHERE imd.InstrumentVisible = 1
  AND ii.ImageID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2025-03-14 | Enriched: 2025-03-14 | Quality: 8.2/10 (Elements: 8.6/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentImages | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InstrumentImages.sql*
