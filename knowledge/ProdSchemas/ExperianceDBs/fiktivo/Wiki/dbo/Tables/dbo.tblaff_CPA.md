# dbo.tblaff_CPA

> Tracks Cost Per Acquisition (CPA) deposit events - first qualifying deposits by customers referred through the affiliate program, forming the basis for CPA commission calculations.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | DepositID (INT IDENTITY, NC PK) |
| **Partition** | No |
| **Indexes** | 5 active (1 NC PK, 1 clustered on ORDER_DATE, 3 NC) |

---

## 1. Business Meaning

This is one of the highest-volume tables in the database (1,399,082 records). It records every qualifying deposit event attributed to the affiliate program under the CPA (Cost Per Acquisition) commission model. In CPA, affiliates earn a fixed fee for each customer who makes a qualifying first deposit, regardless of the deposit amount.

Each row represents one CPA-qualifying deposit. The commission is calculated separately in tblaff_CPA_Commissions based on the affiliate's CPA tier rates and the customer's country. The table has cascade-delete and update triggers linking to CPA_Commissions.

The DepositDate column (distinct from ORDER_DATE) suggests that the original deposit may have occurred at a different time than when it was processed/attributed to the affiliate system.

---

## 2. Business Logic

### 2.1 CPA Validation Pipeline

**What**: Each deposit passes through a validation pipeline before CPA commission is calculated.

**Columns/Parameters Involved**: `AffiliateDepositAccepted`, `Valid`, `Reason`

**Rules**:
- AffiliateDepositAccepted=1: The deposit is attributed to an affiliate and accepted for CPA processing
- Valid=1: The deposit passed all validation rules (not fraudulent, meets minimum deposit amount, first qualifying deposit)
- Both must be TRUE for CPA commission to be generated
- Reason stores rejection text when Valid=0

---

## 3. Data Overview

N/A - similar pattern to other event tables. CPA events represent first qualifying deposits from affiliate-referred customers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositID | int | NO | IDENTITY(1,1) | VERIFIED | Primary key. Unique identifier for each CPA deposit event. NOT FOR REPLICATION. Referenced by tblaff_CPA_Commissions.DepositID. |
| 2 | CUSTOMER_ID | nvarchar(50) | YES | - | VERIFIED | Customer identifier from the trading platform. |
| 3 | ORDER_DATE | datetime | YES | - | VERIFIED | Timestamp when the deposit was processed/attributed. Clustered index column. |
| 4 | COUNTRY | nvarchar(50) | YES | - | CODE-BACKED | Legacy country name text. Superseded by CountryID. |
| 5 | GRAND_TOTAL | float | YES | 0 | VERIFIED | Deposit amount. The actual monetary value of the customer's qualifying deposit. |
| 6 | AffiliateDepositAccepted | bit | NO | 0 | VERIFIED | Whether this deposit has been attributed to an affiliate. 1=accepted for CPA commission, 0=not attributed. |
| 7 | IPAddress | nvarchar(20) | YES | - | CODE-BACKED | Customer's IP address at deposit time. Fraud detection. |
| 8 | Browser | nvarchar(255) | YES | - | CODE-BACKED | Customer's user agent string. Fraud detection. |
| 9 | Valid | bit | NO | 0 | VERIFIED | Whether the deposit passed validation. 1=valid for commission, 0=rejected. |
| 10 | Reason | nvarchar(50) | YES | - | CODE-BACKED | Rejection reason when Valid=0. |
| 11 | BannerID | int | NO | 0 | VERIFIED | Marketing banner. References dbo.tblaff_Banners [done]. 0=direct. |
| 12 | DaysToConvert | real | NO | 0 | CODE-BACKED | Days between affiliate click and this deposit. Conversion speed metric. |
| 13 | Optional1 | nvarchar(25) | YES | - | VERIFIED | Sub-affiliate tracking parameter. |
| 14 | Optional2 | nvarchar(25) | YES | - | CODE-BACKED | Secondary tracking parameter. |
| 15 | Optional3 | bigint | YES | 0 | VERIFIED | Original CID or extended tracking ID. Has NC index. |
| 16 | DownloadID | bigint | YES | 0 | CODE-BACKED | App download event ID. Mobile acquisition tracking. |
| 17 | ProviderID | bigint | NO | 1 | VERIFIED | Currently attributed affiliate provider. |
| 18 | OriginalProviderID | bigint | NO | 1 | VERIFIED | First affiliate that acquired this customer. |
| 19 | CountryID | bigint | NO | 0 | VERIFIED | Customer's country. References dbo.tblaff_Country [done]. |
| 20 | DID | bigint | YES | - | CODE-BACKED | Download tracking ID. |
| 21 | FID | bigint | YES | - | CODE-BACKED | Funnel tracking ID. |
| 22 | RealProviderID | bigint | NO | 1 | VERIFIED | Leaf-level provider after IB hierarchy resolution. |
| 23 | FunnelID | int | YES | - | NAME-INFERRED | Marketing funnel identifier. |
| 24 | LabelID | int | YES | - | NAME-INFERRED | Marketing label/campaign identifier. |
| 25 | PlayerLevelID | int | YES | - | NAME-INFERRED | Customer tier/level at event time. |
| 26 | ClubID | int | YES | - | NAME-INFERRED | Customer club/loyalty membership. |
| 27 | DepositDate | datetime | YES | - | CODE-BACKED | Actual date of the deposit (may differ from ORDER_DATE which is the attribution processing date). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BannerID | dbo.tblaff_Banners | Implicit | Marketing banner that drove the customer |
| CountryID | dbo.tblaff_Country | Implicit | Customer's country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_CPA_Commissions | DepositID | Trigger cascade-delete + trigger-enforced FK | CPA commission records for this deposit |
| dbo.tblaff_CPACountriesToAffiliateTypeID | - | Business reference | CPA slab rates per country/affiliate type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CPA_Commissions | Table | Cascade-deleted via trigger; trigger-enforced FK on DepositID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_CPA_PK | NC PK | DepositID | - | - | Active (FILLFACTOR=90, PAGE compressed) |
| IX_tblaff_CPA_ORDER_DATE | CLUSTERED | ORDER_DATE | - | - | Active (FILLFACTOR=90, PAGE compressed) |
| IDX_tblaff_CPA_Optional3 | NC | Optional3 | - | - | Active (PAGE compressed) |
| IX_tblaff_CPA_Incl1 | NC | AffiliateDepositAccepted, Valid | DepositID | - | Active (PAGE compressed) |
| IX_tblaff_CPA_Options | NC | Optional1, Optional3, OriginalProviderID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression |
| tblaff_CPA_DTrig | Trigger (DELETE) | Cascade-deletes to tblaff_CPA_Commissions |
| tblaff_CPA_UTrig | Trigger (UPDATE) | Prevents DepositID changes when commissions exist |

---

## 8. Sample Queries

### 8.1 Get recent valid CPA deposits
```sql
SELECT TOP 10 DepositID, CUSTOMER_ID, ORDER_DATE, GRAND_TOTAL, CountryID
FROM dbo.tblaff_CPA WITH (NOLOCK)
WHERE AffiliateDepositAccepted = 1 AND Valid = 1
ORDER BY ORDER_DATE DESC
```

### 8.2 CPA volume by country
```sql
SELECT c.CountryName, COUNT(*) AS Deposits, SUM(cpa.GRAND_TOTAL) AS TotalValue
FROM dbo.tblaff_CPA cpa WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON cpa.CountryID = c.CountryID
WHERE cpa.Valid = 1
GROUP BY c.CountryName
ORDER BY Deposits DESC
```

### 8.3 Join CPA with commissions
```sql
SELECT cpa.DepositID, cpa.CUSTOMER_ID, cpa.GRAND_TOTAL,
       comm.AffiliateID, comm.Commission, comm.Tier, comm.Paid
FROM dbo.tblaff_CPA cpa WITH (NOLOCK)
JOIN dbo.tblaff_CPA_Commissions comm WITH (NOLOCK) ON cpa.DepositID = comm.DepositID
WHERE cpa.DepositID = 1000
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 8/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 13 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (triggers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_CPA | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_CPA.sql*
