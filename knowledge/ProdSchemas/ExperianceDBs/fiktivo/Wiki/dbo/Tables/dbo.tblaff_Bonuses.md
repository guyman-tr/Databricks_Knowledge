# dbo.tblaff_Bonuses

> Tracks bonus redemption events by customers referred through the affiliate program, recording each bonus usage for affiliate commission attribution.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | BonusID (INT IDENTITY, NC PK) |
| **Partition** | No |
| **Indexes** | 4 active (1 NC PK, 1 clustered on ORDER_DATE, 2 NC) |

---

## 1. Business Meaning

This table records every bonus event attributed to the affiliate program. When a customer referred by an affiliate uses a platform bonus (deposit bonus, trading credit, etc.), a row is created here. These events serve as the basis for bonus-type commission calculations - affiliates earn commissions when their referred customers use bonuses.

With 409,269 records, this is a significant volume event table. Each row links a customer action (bonus usage) to the affiliate tracking chain via Optional1 (sub-affiliate ID), Optional3 (original CID/tracking), BannerID, and ProviderID. The GRAND_TOTAL field often shows negative values (e.g., -20), indicating bonus costs charged back against revenue.

The table has cascade-delete triggers to tblaff_Bonuses_Commissions (removing all commission records when a bonus event is deleted) and update triggers preventing BonusID changes when commissions exist. No explicit FK to tblaff_Affiliates - the commission table provides the affiliate linkage.

---

## 2. Business Logic

### 2.1 Bonus Validation and Attribution

**What**: Each bonus event passes through a validation and attribution pipeline before commissions are calculated.

**Columns/Parameters Involved**: `AffiliateBonusAccepted`, `Valid`, `Reason`

**Rules**:
- AffiliateBonusAccepted=1: The event has been attributed to an affiliate (accepted into the commission pipeline)
- Valid=1: The event passed validation rules (not fraudulent, not duplicated, meets minimum requirements)
- Both must be TRUE (1) for commissions to be calculated
- Reason stores the rejection reason text when Valid=0 (e.g., "duplicate", "fraud", "below minimum")
- Events can be accepted but invalid, or valid but not accepted - these represent different pipeline stages

### 2.2 Multi-Provider Attribution Chain

**What**: Each event tracks the full attribution chain from original provider through current and real providers.

**Columns/Parameters Involved**: `ProviderID`, `OriginalProviderID`, `RealProviderID`

**Rules**:
- OriginalProviderID: The first affiliate that acquired this customer
- ProviderID: The currently attributed affiliate (may differ from original after reassignment)
- RealProviderID: The leaf-level provider after IB hierarchy resolution
- When all three match (default=1), the customer was directly acquired with no IB involvement

---

## 3. Data Overview

| BonusID | CUSTOMER_ID | ORDER_DATE | GRAND_TOTAL | Valid | BannerID | CountryID | Meaning |
|---|---|---|---|---|---|---|---|
| 413341 | 5546073... | 2013-01-19 | -20.00 | 1 | 2284 | 73 | Customer used a $20 bonus - negative value represents cost to the platform. Attributed via banner 2284 from country 73 |
| 413340 | 5489791... | 2013-01-19 | -20.00 | 1 | 1009 | 216 | Another $20 bonus usage. Attributed via banner 1009 from country 216 |
| 413339 | 5379317... | 2013-01-19 | -20.00 | 1 | 0 | 138 | $20 bonus with no banner (BannerID=0, direct/organic attribution) from country 138 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BonusID | int | NO | IDENTITY(1,1) | VERIFIED | Primary key. Unique identifier for each bonus event. NOT FOR REPLICATION identity. Referenced by tblaff_Bonuses_Commissions.BonusID. |
| 2 | CUSTOMER_ID | nvarchar(50) | YES | - | VERIFIED | Customer identifier from the trading platform. Can be numeric or GUID format depending on the era. Links to external customer system. |
| 3 | ORDER_DATE | datetime | YES | - | VERIFIED | Timestamp when the bonus event occurred. Clustered index column - data is physically ordered by date. |
| 4 | COUNTRY | nvarchar(50) | YES | - | CODE-BACKED | Legacy country name text. Often NULL in recent data. Superseded by CountryID for normalized lookups. |
| 5 | GRAND_TOTAL | float | YES | 0 | VERIFIED | Monetary value of the bonus. Typically negative (e.g., -20) representing the cost of the bonus to the platform. Used as the base for commission calculations. |
| 6 | AffiliateBonusAccepted | bit | NO | 0 | VERIFIED | Whether this bonus event has been attributed to an affiliate and accepted into the commission pipeline. 1=accepted for commission, 0=not attributed. |
| 7 | IPAddress | nvarchar(20) | YES | - | CODE-BACKED | IP address of the customer at the time of the bonus event. Used for fraud detection and geographic verification. |
| 8 | Browser | nvarchar(255) | YES | - | CODE-BACKED | User agent/browser string of the customer. Used for fraud detection and traffic quality analysis. |
| 9 | Valid | bit | NO | 0 | VERIFIED | Whether the event passed validation rules. 1=valid for commission, 0=rejected. Must be 1 along with AffiliateBonusAccepted for commissions. |
| 10 | Reason | nvarchar(50) | YES | - | CODE-BACKED | Rejection reason when Valid=0. Examples: "duplicate", "fraud", "below minimum". NULL when valid. |
| 11 | BannerID | int | NO | 0 | VERIFIED | Marketing banner that drove the customer. References dbo.tblaff_Banners [done]. 0=no banner (direct/organic). |
| 12 | DaysToConvert | real | NO | 0 | CODE-BACKED | Days between the affiliate click/impression and this bonus event. Measures conversion speed. |
| 13 | Optional1 | nvarchar(25) | YES | - | VERIFIED | Sub-affiliate tracking parameter. Used by affiliates to segment their traffic sources. |
| 14 | Optional2 | nvarchar(25) | YES | - | CODE-BACKED | Secondary tracking parameter for additional campaign segmentation. |
| 15 | Optional3 | bigint | YES | - | VERIFIED | Original CID or extended tracking ID. Has NC index. Links to CID-based tracking. |
| 16 | DownloadID | bigint | YES | 0 | CODE-BACKED | App download event that led to registration. Tracks mobile acquisition funnel. |
| 17 | ProviderID | bigint | NO | 1 | VERIFIED | Currently attributed affiliate provider. Default 1. May differ from OriginalProviderID after reassignment. |
| 18 | OriginalProviderID | bigint | NO | 1 | VERIFIED | First affiliate that acquired this customer. Preserved for attribution audit. |
| 19 | CountryID | bigint | NO | 0 | VERIFIED | Customer's country. References dbo.tblaff_Country [done] (implicit, bigint vs int type mismatch). 0=unknown. |
| 20 | DID | bigint | YES | - | CODE-BACKED | Download tracking ID. Part of the mobile attribution chain. |
| 21 | FID | bigint | YES | - | CODE-BACKED | Funnel tracking ID. Part of the conversion funnel attribution. |
| 22 | RealProviderID | bigint | NO | 1 | VERIFIED | Leaf-level provider after IB hierarchy resolution. For direct affiliates equals ProviderID. |
| 23 | FunnelID | int | YES | - | NAME-INFERRED | Marketing funnel identifier for acquisition path tracking. |
| 24 | LabelID | int | YES | - | NAME-INFERRED | Marketing label/campaign identifier for channel segmentation. |
| 25 | PlayerLevelID | int | YES | - | NAME-INFERRED | Customer tier/level classification at event time. May affect commission rates. |
| 26 | ClubID | int | YES | - | NAME-INFERRED | Customer club/loyalty program membership at event time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BannerID | dbo.tblaff_Banners | Implicit | Marketing banner that drove the customer acquisition |
| CountryID | dbo.tblaff_Country | Implicit | Customer's country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Bonuses_Commissions | BonusID | Trigger cascade-delete | Commission records for this bonus event |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Bonuses_Commissions | Table | Cascade-deleted via tblaff_Bonuses_DTrig when bonus is deleted |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_Bonuses_PK | NC PK | BonusID | - | - | Active (FILLFACTOR=90, PAGE compressed) |
| IX_tblaff_Bonuses_ORDER_DATE | CLUSTERED | ORDER_DATE | - | - | Active (FILLFACTOR=90, PAGE compressed) |
| IDX_tblaff_Bonuses_Optional3 | NC | Optional3 | BonusID | - | Active (PAGE compressed) |
| IX_tblaff_Bonuses_Options | NC | Optional1, Optional3, OriginalProviderID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression on main table |

---

## 8. Sample Queries

### 8.1 Get recent bonus events
```sql
SELECT TOP 10 BonusID, CUSTOMER_ID, ORDER_DATE, GRAND_TOTAL, AffiliateBonusAccepted, Valid
FROM dbo.tblaff_Bonuses WITH (NOLOCK)
ORDER BY ORDER_DATE DESC
```

### 8.2 Find valid accepted bonuses for a provider
```sql
SELECT BonusID, CUSTOMER_ID, GRAND_TOTAL, ORDER_DATE
FROM dbo.tblaff_Bonuses WITH (NOLOCK)
WHERE ProviderID = 100
  AND AffiliateBonusAccepted = 1 AND Valid = 1
ORDER BY ORDER_DATE DESC
```

### 8.3 Bonus summary by country
```sql
SELECT b.CountryID, c.CountryName, COUNT(*) AS BonusCount, SUM(b.GRAND_TOTAL) AS TotalValue
FROM dbo.tblaff_Bonuses b WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON b.CountryID = c.CountryID
WHERE b.Valid = 1
GROUP BY b.CountryID, c.CountryName
ORDER BY BonusCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 12 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (trigger) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Bonuses | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Bonuses.sql*
