# dbo.tblaff_AffiliatePixels

> Configuration table for affiliate tracking pixels, defining the callback URLs and integration settings that fire when customers complete tracked events (registrations, deposits, etc.).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | PixelID (int IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK + AffiliateID) |

---

## 1. Business Meaning

dbo.tblaff_AffiliatePixels stores the tracking pixel configurations for affiliates. Each pixel defines a callback URL or code snippet that the system fires when a customer event occurs (e.g., registration, first deposit, approved deposit). This enables affiliates to track conversions in their own analytics systems and is the core mechanism for third-party attribution verification.

Without this table, affiliates would have no way to verify conversions in their own systems. Pixel firing is the industry-standard mechanism for real-time conversion notification in affiliate marketing. The table supports both GET (image pixel) and POST (server-to-server postback) callback methods.

Pixels are created and managed via the affiliate admin interface. When a tracked event occurs, the system looks up active pixels for the relevant affiliate and fires them via the durable message queue (tblaff_DurableMessages). The pixel URLs support template variables (##AffiliateID##, ##CustomerID##, ##SerialID##, ##AdditionalData##) that are replaced with actual values at fire time. Contains 440 active pixel configurations.

---

## 2. Business Logic

### 2.1 Pixel Type Classification

**What**: Seven types of pixels for different conversion events.

**Columns/Parameters Involved**: `PixelTypeID`

**Rules**:
- Type 1: 232 pixels (53%) - most common, likely registration or general conversion pixels
- Type 2: 46 pixels (10%) - secondary event type
- Type 3: 105 pixels (24%) - third event type (significant volume)
- Type 5: 6 pixels - rare event type
- Type 6: 30 pixels (7%) - deposit or FTD pixels
- Type 7: 2 pixels - very rare
- Type 8: 19 pixels - another event type
- No PixelTypeID=4 exists (gap in sequence)
- No explicit lookup table found in SSDT for PixelTypeID values

### 2.2 GET vs POST Callback Methods

**What**: Pixels support two delivery mechanisms.

**Columns/Parameters Involved**: `IsPost`, `Code`

**Rules**:
- `IsPost = 0` (GET method): Code contains a pixel ID, short code, or tracking identifier. The system fires an HTTP GET to a constructed URL.
- `IsPost = 1` (POST method): Code contains the full callback URL with template variables (##AffiliateID##, ##CustomerID##, ##SerialID##, ##AdditionalData##). The system fires an HTTP POST to this URL with event data.
- Template variables in POST URLs are replaced at fire time with actual values from the triggering event.
- Example POST URL: `https://stg-tracking-affiliate-mock-pixel-func.azurewebsites.net/api/PixelMock/{guid}?AffiliateID=##AffiliateID##...`

### 2.3 AppsFlyer Integration

**What**: Optional mobile attribution integration via AppsFlyer.

**Columns/Parameters Involved**: `IsAppsFlyerIntegrated`

**Rules**:
- `IsAppsFlyerIntegrated = 1`: This pixel triggers AppsFlyer mobile attribution callbacks in addition to the standard pixel fire
- `IsAppsFlyerIntegrated = 0`: Standard pixel only (all sample data)
- Links to tblaff_DurableMessages.AppsFlyerID for mobile attribution tracking

---

## 3. Data Overview

| PixelID | AffiliateID | PixelTypeID | IsPost | Code | IsAppsFlyerIntegrated | Meaning |
|---|---|---|---|---|---|---|
| 2876 | 8 | 1 | false | 8 | false | Simple GET pixel for affiliate #8. Code "8" is a short identifier used to construct the GET callback URL. Type 1 (standard conversion). |
| 2875 | 4 | 6 | false | 4 | false | GET pixel for affiliate #4, type 6 (likely deposit event). Simple numeric code. |
| 2873 | NULL | 1 | false | Automation - CodePixel... | false | System/test pixel with no specific affiliate. Code contains descriptive test text. |
| 2871 | 61725 | 1 | true | https://stg-tracking-affiliate-mock... | false | Server-to-server POST pixel pointing to Azure staging mock endpoint. URL contains template variables for runtime substitution. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PixelID | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing primary key. NOT FOR REPLICATION. Referenced by tblaff_DurableMessages.PixelIDs (as JSON array). |
| 2 | AffiliateID | int | YES | - | VERIFIED | The affiliate who owns this pixel configuration. Maps to tblaff_Affiliates.AffiliateID. NULL = system/global pixel not tied to a specific affiliate. Indexed for lookup. |
| 3 | SubAffiliateID | nvarchar(1024) | YES | - | CODE-BACKED | Optional sub-affiliate filter. When set, this pixel only fires for events matching this specific sub-affiliate tracking tag. NULL = fires for all sub-affiliates. |
| 4 | PixelTypeID | int | YES | - | CODE-BACKED | Event type that triggers this pixel: 1 (53%, standard), 2 (10%), 3 (24%), 5 (1%), 6 (7%), 7 (<1%), 8 (4%). No explicit lookup table - likely maps to conversion event types (registration, deposit, FTD, etc.). |
| 5 | IsPost | bit | YES | - | VERIFIED | Callback method: 0 = HTTP GET (image pixel), 1 = HTTP POST (server-to-server postback). POST pixels contain full URLs with template variables in the Code column. |
| 6 | Code | nvarchar(max) | YES | - | VERIFIED | Pixel callback definition. For GET pixels: a short identifier or code. For POST pixels: the full callback URL with template variables (##AffiliateID##, ##CustomerID##, ##SerialID##, ##AdditionalData##) replaced at fire time. |
| 7 | Tag | nvarchar(250) | YES | - | NAME-INFERRED | Optional tag/label for organizing pixels. NULL in all sample data. May be used for categorization in the admin interface. |
| 8 | IsAppsFlyerIntegrated | bit | YES | 0 | VERIFIED | AppsFlyer mobile attribution integration flag: 1 = also trigger AppsFlyer callback, 0 = standard pixel only. Connects to the mobile attribution ecosystem for app install tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | dbo.tblaff_Affiliates | Implicit | The affiliate who owns this pixel configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_DurableMessages | PixelIDs (JSON) | Logical | Durable messages reference pixel IDs to fire |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_DurableMessages | Table | References PixelIDs in JSON array for event-driven pixel firing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | PixelID ASC | - | - | Active |
| IX_tblaff_AffiliatePixels_AffiliateID | NC | AffiliateID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_tblaff_AffiliatePixels_IsAppsFlyerIntegrated | DEFAULT | 0 - Standard pixel, no AppsFlyer |

---

## 8. Sample Queries

### 8.1 Get all active pixels for an affiliate
```sql
SELECT PixelID, PixelTypeID, IsPost, Code, IsAppsFlyerIntegrated
FROM dbo.tblaff_AffiliatePixels WITH (NOLOCK)
WHERE AffiliateID = @AffiliateID
ORDER BY PixelTypeID, PixelID
```

### 8.2 Count pixels by type and method
```sql
SELECT PixelTypeID,
       SUM(CASE WHEN IsPost = 1 THEN 1 ELSE 0 END) AS PostPixels,
       SUM(CASE WHEN IsPost = 0 THEN 1 ELSE 0 END) AS GetPixels,
       COUNT(*) AS Total
FROM dbo.tblaff_AffiliatePixels WITH (NOLOCK)
GROUP BY PixelTypeID
ORDER BY PixelTypeID
```

### 8.3 Find affiliates with AppsFlyer integration
```sql
SELECT ap.AffiliateID, a.Contact, a.Email, COUNT(*) AS AppsFlyerPixels
FROM dbo.tblaff_AffiliatePixels ap WITH (NOLOCK)
JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON ap.AffiliateID = a.AffiliateID
WHERE ap.IsAppsFlyerIntegrated = 1
GROUP BY ap.AffiliateID, a.Contact, a.Email
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 8.8/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_AffiliatePixels | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_AffiliatePixels.sql*
