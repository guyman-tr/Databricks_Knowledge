# Tracking.GetApprovedFTDPixels

> Retrieves the affiliate context and client-side FTD (First-Time Deposit) pixel codes for a customer, enabling the tracking service to fire approved-deposit conversion pixels to the affiliate's tracking system.

| Property | Value |
|----------|-------|
| **Schema** | Tracking |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: affiliate context + FTD pixel codes for a CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Tracking.GetApprovedFTDPixels is called when a customer's first-time deposit (FTD) is approved. The tracking service needs to know which affiliate referred this customer and which pixel codes to fire to notify the affiliate's tracking system of the conversion. This procedure resolves the customer's affiliate attribution via their registration record and returns the applicable Approved FTD pixel codes (PixelTypeID=6).

This procedure exists because FTD conversion is a critical affiliate metric - it represents the moment a referred customer makes their first deposit, which typically triggers the highest-value commission event (CPA). The pixel notifies the affiliate's external tracking platform (e.g., HasOffers, CAKE, Impact) that the conversion occurred, enabling the affiliate to reconcile their own records with eToro's commission payments.

The procedure returns two result sets: (1) the affiliate context (AffiliateID, AffiliateCampaign, OriginalCID, AdditionalData) resolved from the registration record, and (2) the client-side Approved FTD pixel codes - both affiliate-specific AND global (AffiliateID IS NULL) pixels.

---

## 2. Business Logic

### 2.1 Affiliate Resolution via Registration

**What**: Looks up the customer's referring affiliate from their registration record.

**Columns/Parameters Involved**: `@CID`, `@AffiliateID`, `@AffiliateCampaign`, `@OriginalCID`, `@AdditionalData`

**Rules**:
- SELECT from AffiliateCommission.RegistrationVW WHERE CID=@CID
- Extracts: AffiliateID, AffiliateCampaign, OriginalCID, AdditionalData into local variables
- If no registration exists, @AffiliateID stays at 0 (default) - Result Set 1 returns 0 for AffiliateID
- Result Set 1 returns these 4 values for the calling service to use in pixel URL parameter substitution

### 2.2 Pixel Code Retrieval (Affiliate-Specific + Global)

**What**: Returns FTD pixel codes from both affiliate-specific and global configurations.

**Columns/Parameters Involved**: `@AffiliateID`, PixelTypeID=6, IsPost=0

**Rules**:
- UNION ALL of two queries:
  - Affiliate-specific: WHERE IsPost=0 AND PixelTypeID=6 AND AffiliateID=@AffiliateID
  - Global: WHERE IsPost=0 AND PixelTypeID=6 AND AffiliateID IS NULL
- PixelTypeID=6 = Approved FTD Pixel. See [Pixel Types](../../_glossary.md#pixel-types)
- IsPost=0 = client-side pixels only (JavaScript/HTML snippets rendered in the customer's browser)
- Global pixels fire for ALL affiliates regardless of which one referred the customer
- Returns only the Code column (the actual pixel markup/URL)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | bigint | NO | - | CODE-BACKED | Customer ID whose FTD was just approved. Used to resolve the customer's affiliate attribution via AffiliateCommission.RegistrationVW. The registration record links the CID to the affiliate who referred them. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | AffiliateCommission.RegistrationVW | READ | Resolves customer's affiliate attribution from registration record |
| - | dbo.tblaff_AffiliatePixels | READ | Retrieves Approved FTD pixel codes (PixelTypeID=6, IsPost=0) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tracking Service / AKS (external) | - | Caller | Called on FTD approval to fire conversion pixels |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tracking.GetApprovedFTDPixels (procedure)
+-- AffiliateCommission.RegistrationVW (view, cross-schema)
+-- dbo.tblaff_AffiliatePixels (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationVW | View | SELECT to resolve CID -> AffiliateID attribution |
| dbo.tblaff_AffiliatePixels | Table | SELECT pixel Code WHERE PixelTypeID=6, IsPost=0 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tracking Service (external) | Application | Fires FTD conversion pixels to affiliate tracking systems |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get FTD pixel data for a customer
```sql
EXEC Tracking.GetApprovedFTDPixels @CID = 12345
```

### 8.2 Check which affiliates have FTD pixels configured
```sql
SELECT DISTINCT AffiliateID
FROM dbo.tblaff_AffiliatePixels WITH (NOLOCK)
WHERE PixelTypeID = 6 AND IsPost = 0
ORDER BY AffiliateID
```

### 8.3 Find global FTD pixels (fire for all affiliates)
```sql
SELECT Code
FROM dbo.tblaff_AffiliatePixels WITH (NOLOCK)
WHERE PixelTypeID = 6 AND IsPost = 0 AND AffiliateID IS NULL
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-576 (referenced in SQL comments) | Jira | Refactor deposit pixel to AKS |
| PART-2448 (referenced in SQL comments) | Jira | CPA New Compensation Design (Dec 2023, Gil & Noga) |
| PART-3638 (referenced in SQL comments) | Jira | Added AdditionalData from Registration view (Oct 2024, Gil) |

No Confluence pages found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.1/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 3 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tracking.GetApprovedFTDPixels | Type: Stored Procedure | Source: fiktivo/Tracking/Stored Procedures/Tracking.GetApprovedFTDPixels.sql*
