# dbo.tblaff_CopyTraders

> Tracks CopyTrader activation events - when affiliate-referred customers start copying another trader, generating copy trading commissions.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | CopyTraderID (INT IDENTITY, NC PK) |
| **Partition** | No |
| **Indexes** | 2 active (1 NC PK, 1 NC on Optional3) |

---

## 1. Business Meaning

This table records CopyTrader activation events - a unique conversion type specific to eToro's social trading platform. When a customer referred by an affiliate starts copying another trader (using the CopyTrader feature), this constitutes a measurable engagement event that can trigger affiliate commissions.

With 67,855 records, this represents a significant but specialized event type. CopyTrader is a flagship eToro feature, so tracking these activations helps measure the quality of affiliate-referred traffic in terms of platform engagement depth.

Unlike most other event tables, this one has no clustered index on ORDER_DATE - it lacks an ORDER_DATE-based clustered index entirely, which may affect time-range query performance.

---

## 2. Business Logic

### 2.1 CopyTrader Attribution

**What**: Each copy trading activation is validated and attributed for commission.

**Columns/Parameters Involved**: `AffiliateCopyTraderAccepted`, `Valid`, `Reason`

**Rules**:
- AffiliateCopyTraderAccepted=1: The event is attributed to an affiliate
- Valid=1: The event passed validation (not a duplicate, meets minimum copy amount, etc.)
- Both TRUE required for commission calculation in tblaff_CopyTraders_Commissions

---

## 3. Data Overview

N/A - CopyTrader events represent affiliate-referred customers initiating copy trading relationships.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CopyTraderID | int | NO | IDENTITY(1,1) | VERIFIED | Primary key. Unique identifier for each CopyTrader activation event. NOT FOR REPLICATION. |
| 2 | CUSTOMER_ID | nvarchar(50) | YES | - | VERIFIED | Customer who initiated the copy trading. |
| 3 | ORDER_DATE | datetime | YES | - | VERIFIED | Timestamp of the CopyTrader activation. |
| 4 | AffiliateCopyTraderAccepted | bit | NO | 0 | VERIFIED | Attribution flag. 1=accepted for commission, 0=not attributed. |
| 5 | Valid | bit | NO | 0 | VERIFIED | Validation flag. 1=valid for commission, 0=rejected. |
| 6 | BannerID | int | NO | 0 | VERIFIED | Marketing banner. References dbo.tblaff_Banners [done]. |
| 7 | DaysToConvert | real | NO | 0 | CODE-BACKED | Days between affiliate click and CopyTrader activation. |
| 8 | Optional1 | nvarchar(25) | YES | - | CODE-BACKED | Sub-affiliate tracking parameter. |
| 9 | Optional2 | nvarchar(25) | YES | - | CODE-BACKED | Secondary tracking parameter. |
| 10 | Optional3 | bigint | YES | - | VERIFIED | Original CID or extended tracking ID. Has NC index. |
| 11 | Real | bit | YES | - | CODE-BACKED | Whether the customer is a real (funded) account or demo. 1=real money, NULL/0=demo or unknown. |
| 12 | DownloadID | bigint | YES | 0 | CODE-BACKED | App download event ID. |
| 13 | ProviderID | bigint | NO | 1 | VERIFIED | Currently attributed affiliate provider. |
| 14 | OriginalProviderID | bigint | NO | 1 | VERIFIED | First affiliate that acquired this customer. |
| 15 | CountryID | bigint | NO | 0 | VERIFIED | Customer's country. References dbo.tblaff_Country [done]. |
| 16 | RealProviderID | bigint | NO | 1 | VERIFIED | Leaf-level provider after IB hierarchy resolution. |
| 17 | FunnelID | int | YES | - | NAME-INFERRED | Marketing funnel identifier. |
| 18 | LabelID | int | YES | - | NAME-INFERRED | Marketing label/campaign identifier. |
| 19 | PlayerLevelID | int | YES | - | NAME-INFERRED | Customer tier at event time. |
| 20 | Reason | nvarchar(50) | YES | - | CODE-BACKED | Rejection reason when Valid=0. |

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
| dbo.tblaff_CopyTraders_Commissions | CopyTraderID | Implicit FK | Commission records for this CopyTrader event |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CopyTraders_Commissions | Table | Implicit FK on CopyTraderID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaatblaff_Copytraders_PK | NC PK | CopyTraderID | - | - | Active (PAGE compressed) |
| IDX_tblaff_CopyTraders_Optional3 | NC | Optional3 | CopyTraderID | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression |

---

## 8. Sample Queries

### 8.1 Get recent valid CopyTrader events
```sql
SELECT TOP 10 CopyTraderID, CUSTOMER_ID, ORDER_DATE, AffiliateCopyTraderAccepted, Valid
FROM dbo.tblaff_CopyTraders WITH (NOLOCK)
WHERE Valid = 1
ORDER BY ORDER_DATE DESC
```

### 8.2 CopyTrader events by provider
```sql
SELECT ProviderID, COUNT(*) AS CopyCount
FROM dbo.tblaff_CopyTraders WITH (NOLOCK)
WHERE AffiliateCopyTraderAccepted = 1 AND Valid = 1
GROUP BY ProviderID
ORDER BY CopyCount DESC
```

### 8.3 Real vs demo CopyTrader activations
```sql
SELECT CASE WHEN Real = 1 THEN 'Real' ELSE 'Demo/Unknown' END AS AccountType, COUNT(*) AS Cnt
FROM dbo.tblaff_CopyTraders WITH (NOLOCK)
GROUP BY CASE WHEN Real = 1 THEN 'Real' ELSE 'Demo/Unknown' END
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 8/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_CopyTraders | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_CopyTraders.sql*
