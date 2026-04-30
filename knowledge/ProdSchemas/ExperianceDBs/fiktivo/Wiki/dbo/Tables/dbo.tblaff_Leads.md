# dbo.tblaff_Leads

> Tracks lead generation events - when potential customers referred by affiliates show initial interest (e.g., form submissions, demo account creation) before converting to a registered user.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | LeadID (INT IDENTITY, NC PK) |
| **Partition** | No |
| **Indexes** | 6 active (1 NC PK, 1 clustered on ORDER_DATE, 4 NC) |

---

## 1. Business Meaning

This table records lead generation events - the earliest stage of the affiliate conversion funnel. A lead represents initial customer interest (demo account creation, form submission, inquiry) before full registration and deposit. With 371,553 records, this is a high-volume event table representing the top of the acquisition funnel.

Lead events form the basis for lead-based commission models where affiliates earn per qualified lead. The table uses cascade-delete and update triggers linking to tblaff_Leads_Commissions. The `Real` column distinguishes genuine leads from demo/test leads.

The delete trigger on tblaff_Affiliates also cascade-deletes from tblaff_Leads_Commissions, ensuring data consistency when an affiliate is removed.

---

## 2. Business Logic

### 2.1 Lead Qualification

**What**: Each lead event passes through validation and attribution.

**Columns/Parameters Involved**: `AffiliateSaleAccepted`, `Valid`, `Reason`, `Real`

**Rules**:
- AffiliateSaleAccepted=1: The lead is attributed to an affiliate (note: column named "SaleAccepted" but used for lead attribution - legacy naming)
- Valid=1: The lead passed validation (not duplicate, genuine interest signal)
- Real=1: The lead came from a real account (not demo/test). NULL or 0 means demo or unknown
- Both AffiliateSaleAccepted and Valid must be TRUE for lead commissions

---

## 3. Data Overview

N/A - lead events represent early-funnel customer acquisition signals attributed to affiliates.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LeadID | int | NO | IDENTITY(1,1) | VERIFIED | Primary key. Unique identifier for each lead event. NOT FOR REPLICATION. Referenced by tblaff_Leads_Commissions.LeadID via trigger-enforced FK. |
| 2 | CUSTOMER_ID | nvarchar(50) | YES | - | VERIFIED | Customer identifier from the trading platform. |
| 3 | ORDER_DATE | datetime | YES | - | VERIFIED | Timestamp when the lead was generated. Clustered index column. |
| 4 | AffiliateSaleAccepted | bit | NO | 0 | VERIFIED | Attribution flag (legacy name from shared codebase). 1=lead attributed to an affiliate, 0=not attributed. |
| 5 | IPAddress | nvarchar(20) | YES | - | CODE-BACKED | Customer's IP address. Fraud detection and geo-verification. |
| 6 | Browser | nvarchar(255) | YES | - | CODE-BACKED | Customer's user agent string. |
| 7 | Valid | bit | NO | 0 | VERIFIED | Validation flag. 1=qualified lead, 0=rejected. |
| 8 | Reason | nvarchar(50) | YES | - | CODE-BACKED | Rejection reason when Valid=0. |
| 9 | BannerID | int | NO | 0 | VERIFIED | Marketing banner. References dbo.tblaff_Banners [done]. |
| 10 | DaysToConvert | real | NO | 0 | CODE-BACKED | Days between affiliate click and lead generation. |
| 11 | Optional1 | nvarchar(25) | YES | - | CODE-BACKED | Sub-affiliate tracking parameter. |
| 12 | Optional2 | nvarchar(25) | YES | - | CODE-BACKED | Secondary tracking parameter. |
| 13 | Optional3 | bigint | YES | - | VERIFIED | Original CID or extended tracking ID. Has NC index. |
| 14 | Real | bit | YES | - | CODE-BACKED | Whether the lead is from a real (funded) or demo account. 1=real, NULL/0=demo or unknown. |
| 15 | DownloadID | bigint | YES | 0 | CODE-BACKED | App download event ID. |
| 16 | ProviderID | bigint | NO | 1 | VERIFIED | Currently attributed affiliate provider. |
| 17 | OriginalProviderID | bigint | NO | 1 | VERIFIED | First affiliate that acquired this customer. |
| 18 | CountryID | bigint | NO | 0 | VERIFIED | Customer's country. References dbo.tblaff_Country [done]. |
| 19 | DID | bigint | YES | - | CODE-BACKED | Download tracking ID. |
| 20 | FID | bigint | YES | - | CODE-BACKED | Funnel tracking ID. |
| 21 | RealProviderID | bigint | NO | 1 | VERIFIED | Leaf-level provider after IB hierarchy resolution. |
| 22 | FunnelID | int | YES | - | NAME-INFERRED | Marketing funnel identifier. |
| 23 | LabelID | int | YES | - | NAME-INFERRED | Marketing label/campaign identifier. |
| 24 | PlayerLevelID | int | YES | - | NAME-INFERRED | Customer tier at event time. |
| 25 | ClubID | int | YES | - | NAME-INFERRED | Customer club membership. |

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
| dbo.tblaff_Leads_Commissions | LeadID | Trigger-enforced FK | Lead commission records |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Leads_Commissions | Table | Cascade-deleted via trigger; trigger-enforced FK on LeadID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_Leads_PK | NC PK | LeadID | - | - | Active (FILLFACTOR=90, PAGE compressed) |
| IX_tblaff_Leads_ORDER_DATE | CLUSTERED | ORDER_DATE | - | - | Active (FILLFACTOR=90, PAGE compressed) |
| Browser | NC | Browser | - | - | Active (FILLFACTOR=90) |
| CUSTOMER_ID | NC | CUSTOMER_ID | - | - | Active (FILLFACTOR=90) |
| IDX_tblaff_Leads_Optional3 | NC | Optional3 | - | - | Active |
| IPAddress | NC | IPAddress | - | - | Active (FILLFACTOR=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression |
| tblaff_Leads_DTrig | Trigger (DELETE) | Cascade-deletes to tblaff_Leads_Commissions |
| tblaff_Leads_UTrig | Trigger (UPDATE) | Prevents LeadID changes when commissions exist |

---

## 8. Sample Queries

### 8.1 Get recent valid leads
```sql
SELECT TOP 10 LeadID, CUSTOMER_ID, ORDER_DATE, Real
FROM dbo.tblaff_Leads WITH (NOLOCK)
WHERE AffiliateSaleAccepted = 1 AND Valid = 1
ORDER BY ORDER_DATE DESC
```

### 8.2 Lead volume by provider
```sql
SELECT ProviderID, COUNT(*) AS LeadCount
FROM dbo.tblaff_Leads WITH (NOLOCK)
WHERE Valid = 1
GROUP BY ProviderID
ORDER BY LeadCount DESC
```

### 8.3 Leads with commissions
```sql
SELECT l.LeadID, l.CUSTOMER_ID, lc.AffiliateID, lc.Commission, lc.Tier, lc.Paid
FROM dbo.tblaff_Leads l WITH (NOLOCK)
JOIN dbo.tblaff_Leads_Commissions lc WITH (NOLOCK) ON l.LeadID = lc.LeadID
WHERE l.LeadID = 1000
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 8/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 11 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (triggers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Leads | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Leads.sql*
