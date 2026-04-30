# Dictionary.PixelTypes

> Lookup table defining the types of conversion tracking pixels fired to affiliate tracking systems, each corresponding to a specific customer lifecycle event.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PixelTypeID (int IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.PixelTypes defines the conversion tracking events that the affiliate platform fires to external tracking systems. When a referred customer completes a key lifecycle event (registration, first deposit), the system fires a tracking pixel to notify the affiliate's tracking platform. This enables affiliates to measure their campaign effectiveness and optimize their marketing spend.

Without this table, the system would not know which tracking pixels to fire for which events. Affiliate pixel management depends on classifying each pixel by the event it tracks - registration pixels fire on signups, FTD pixels fire on first deposits.

This is static reference data with IDENTITY-generated IDs. The non-sequential IDs (1, 6, 8) suggest historical pixel types were deprecated. The dbo.tblaff_AffiliatePixels table stores pixel configurations keyed by PixelTypeID.

---

## 2. Business Logic

### 2.1 Conversion Funnel Tracking

**What**: Three conversion events tracked across the customer acquisition funnel.

**Columns/Parameters Involved**: `PixelTypeID`, `PixelTypeName`

**Rules**:
- ID=1 (Registration Pixel): Fires when a customer completes registration - tracks top-of-funnel signups
- ID=6 (Approved FTD Pixel): Fires when a customer's first deposit is approved - tracks bottom-of-funnel qualified conversions
- ID=8 (Eligible FTD Pixel): Fires when a customer's first deposit meets eligibility criteria - tracks potential conversions before final approval
- FTD = First Time Deposit, the key conversion metric in affiliate marketing for financial services
- Non-sequential IDs (gap between 1 and 6) indicate deprecated pixel types were removed

**Diagram**:
```
Customer Funnel:
  [Registration (1)] --> [Eligible FTD (8)] --> [Approved FTD (6)]
       ^                       ^                       ^
  Registration Pixel    Eligible Pixel         Approved Pixel
  fires here            fires here             fires here
```

---

## 3. Data Overview

| PixelTypeID | PixelTypeName | Meaning |
|---|---|---|
| 1 | Registration Pixel | Fired when a referred customer completes account registration. Tracks signup conversions - the broadest funnel metric. Every successful registration triggers this pixel for the associated affiliate |
| 6 | Approved FTD Pixel | Fired when a customer's first deposit is approved and cleared. This is the gold-standard conversion event - "First Time Deposit" is the primary metric affiliates optimize for. Only fires once per customer |
| 8 | Eligible FTD Pixel | Fired when a customer's first deposit meets initial eligibility criteria but has not yet been fully approved. Allows affiliates to track near-conversions for optimization before final approval confirms |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PixelTypeID | int | NO | - | VERIFIED | Primary key (IDENTITY) identifying the pixel type. Values: 1=Registration Pixel, 6=Approved FTD Pixel, 8=Eligible FTD Pixel. See [Pixel Types](../../_glossary.md#pixel-types) for full definitions. Non-sequential IDs indicate deprecated types were removed. IDENTITY column - NOT FOR REPLICATION. |
| 2 | PixelTypeName | nvarchar(25) | YES | - | VERIFIED | Human-readable label for the pixel type. Nullable (unusual for a lookup table - all current rows have values). Used in pixel management admin screens and tracking configuration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_AffiliatePixels | PixelTypeID | Implicit FK | Stores pixel configurations per affiliate per type |
| Tracking.GetAffiliatesPixels | JOIN | Lookup | Returns pixel configs for the tracking service |
| Tracking.GetApprovedFTDPixels | WHERE | Filter | Retrieves approved FTD pixels specifically |
| Tracking.GetClientRegistrationPixels | WHERE | Filter | Retrieves registration pixels specifically |
| AffiliateAdmin.GetAffiliatePixels | JOIN | Lookup | Admin view of affiliate pixel configurations |
| AffiliateAdmin.UpdateInsertAffiliatePixel | Parameter | Lookup | Creates/updates pixel configurations |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliatePixels | Table | Stores pixel configs by type |
| Tracking.GetAffiliatesPixels | Stored Procedure | READER - returns pixel configs |
| Tracking.GetApprovedFTDPixels | Stored Procedure | READER - FTD pixel lookup |
| Tracking.GetClientRegistrationPixels | Stored Procedure | READER - registration pixel lookup |
| AffiliateAdmin.GetAffiliatePixels | Stored Procedure | READER - admin pixel view |
| AffiliateAdmin.UpdateInsertAffiliatePixel | Stored Procedure | WRITER - manages pixel configs |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.PixelTypes | CLUSTERED PK | PixelTypeID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all pixel types
```sql
SELECT PixelTypeID, PixelTypeName
FROM Dictionary.PixelTypes WITH (NOLOCK)
ORDER BY PixelTypeID
```

### 8.2 Show affiliate pixel configurations with type names
```sql
SELECT ap.AffiliateID, pt.PixelTypeName, ap.PixelURL
FROM dbo.tblaff_AffiliatePixels ap WITH (NOLOCK)
JOIN Dictionary.PixelTypes pt WITH (NOLOCK) ON ap.PixelTypeID = pt.PixelTypeID
ORDER BY ap.AffiliateID, pt.PixelTypeID
```

### 8.3 Find affiliates with FTD pixel configured
```sql
SELECT DISTINCT ap.AffiliateID
FROM dbo.tblaff_AffiliatePixels ap WITH (NOLOCK)
WHERE ap.PixelTypeID IN (6, 8)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PixelTypes | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.PixelTypes.sql*
