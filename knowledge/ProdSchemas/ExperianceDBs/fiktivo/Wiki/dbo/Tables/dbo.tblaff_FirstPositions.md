# dbo.tblaff_FirstPositions

> Tracks first trading position events - when affiliate-referred customers open their very first trade, a key conversion milestone for affiliate attribution.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | FirstPositionID (INT IDENTITY, NC PK) |
| **Partition** | No |
| **Indexes** | 3 active (1 NC PK, 1 clustered on OriginalCID, 1 NC) |

---

## 1. Business Meaning

This table records first trading position events - the moment an affiliate-referred customer opens their very first trade on the platform. This is a critical conversion milestone: it demonstrates that the customer has progressed from registration through deposit to actual trading activity.

With only 5 records, this appears to be a recently introduced or rarely used event type in this environment. The FirstPositions_Commissions table has an explicit FK to this table, making it the only event table with a formal foreign key to its commission counterpart.

The table uses OriginalCID as the clustered index (not ORDER_DATE like other event tables), indicating that lookups by customer ID are the primary access pattern - likely used to check "has this customer already had a first position recorded?"

---

## 2. Business Logic

### 2.1 First Position Attribution

**What**: Only the very first trade by a customer counts as a "first position" event.

**Columns/Parameters Involved**: `AffiliateFirstPositionAccepted`, `Valid`, `GRAND_TOTAL`, `OriginalCID`

**Rules**:
- Each OriginalCID should appear at most once (clustered index enables efficient duplicate checking)
- AffiliateFirstPositionAccepted=1: Event attributed to an affiliate
- Valid=1: Event confirmed as genuine first position (not a duplicate, meets trade size requirements)
- GRAND_TOTAL: The monetary value/size of the first trade

---

## 3. Data Overview

N/A - only 5 records in this environment.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FirstPositionID | int | NO | IDENTITY(1,1) | VERIFIED | Primary key. Unique identifier for each first position event. NOT FOR REPLICATION. Referenced by tblaff_FirstPositions_Commissions via explicit FK. |
| 2 | ORDER_DATE | datetime | YES | - | VERIFIED | Timestamp when the first position was opened. |
| 3 | GRAND_TOTAL | float | YES | 0 | VERIFIED | Monetary value/size of the first trade. |
| 4 | AffiliateFirstPositionAccepted | bit | NO | 0 | VERIFIED | Attribution flag. 1=accepted for commission, 0=not attributed. |
| 5 | Valid | bit | NO | 0 | VERIFIED | Validation flag. 1=valid, 0=rejected. |
| 6 | BannerID | int | NO | 0 | VERIFIED | Marketing banner. References dbo.tblaff_Banners [done]. |
| 7 | DaysToConvert | real | NO | 0 | CODE-BACKED | Days between affiliate click and first position. |
| 8 | Optional1 | nvarchar(25) | YES | - | CODE-BACKED | Sub-affiliate tracking parameter. |
| 9 | Optional2 | nvarchar(25) | YES | - | CODE-BACKED | Secondary tracking parameter. |
| 10 | OriginalCID | bigint | YES | - | VERIFIED | Original customer ID. Clustered index column - primary lookup pattern for deduplication. |
| 11 | DownloadID | bigint | YES | 0 | CODE-BACKED | App download event ID. |
| 12 | ProviderID | bigint | NO | 1 | VERIFIED | Currently attributed affiliate provider. |
| 13 | OriginalProviderID | bigint | NO | 1 | VERIFIED | First affiliate that acquired this customer. |
| 14 | CountryID | bigint | NO | 0 | VERIFIED | Customer's country. References dbo.tblaff_Country [done]. |
| 15 | RealProviderID | bigint | NO | 1 | VERIFIED | Leaf-level provider after IB hierarchy resolution. |
| 16 | FunnelID | int | YES | - | NAME-INFERRED | Marketing funnel identifier. |
| 17 | LabelID | int | YES | - | NAME-INFERRED | Marketing label/campaign identifier. |
| 18 | PlayerLevelID | int | YES | - | NAME-INFERRED | Customer tier at event time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BannerID | dbo.tblaff_Banners | Implicit | Marketing banner |
| CountryID | dbo.tblaff_Country | Implicit | Customer's country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_FirstPositions_Commissions | FirstPositionID | Explicit FK | Commission records for this first position event |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_FirstPositions_Commissions | Table | Explicit FK on FirstPositionID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_FirstPositions_PK | NC PK | FirstPositionID | - | - | Active (FILLFACTOR=90, PAGE compressed) |
| CLU_IDX_tblaff_FirstPositions_OrigincalCID | CLUSTERED | OriginalCID | - | - | Active (FILLFACTOR=70, PAGE compressed) |
| IDX_tblaff_FirstPositions_Optional3 | NC | OriginalCID | FirstPositionID | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression |

---

## 8. Sample Queries

### 8.1 Check if customer has a first position
```sql
SELECT FirstPositionID, ORDER_DATE, GRAND_TOTAL
FROM dbo.tblaff_FirstPositions WITH (NOLOCK)
WHERE OriginalCID = 12345
```

### 8.2 First positions with commissions
```sql
SELECT fp.FirstPositionID, fp.OriginalCID, fp.GRAND_TOTAL,
       fpc.AffiliateID, fpc.Commission
FROM dbo.tblaff_FirstPositions fp WITH (NOLOCK)
JOIN dbo.tblaff_FirstPositions_Commissions fpc WITH (NOLOCK) ON fp.FirstPositionID = fpc.FirstPositionID
```

### 8.3 Valid first positions by provider
```sql
SELECT ProviderID, COUNT(*) AS Cnt
FROM dbo.tblaff_FirstPositions WITH (NOLOCK)
WHERE AffiliateFirstPositionAccepted = 1 AND Valid = 1
GROUP BY ProviderID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 8/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_FirstPositions | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_FirstPositions.sql*
