# dbo.tblaff_Chargebacks

> Records customer chargeback events attributed to the affiliate program, tracking disputed transactions that reduce affiliate commission earnings.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ChargebackID (INT IDENTITY, NC PK) |
| **Partition** | No |
| **Indexes** | 3 active (1 NC PK, 1 clustered on ORDER_DATE, 1 NC) |

---

## 1. Business Meaning

This table records chargeback events - disputed customer transactions where a payment is reversed. In the affiliate model, chargebacks are negative events that reduce affiliate earnings. When a customer referred by an affiliate initiates a chargeback (e.g., disputes a credit card deposit), the affiliate may lose or have deducted the commission previously earned on that customer's activity.

With 7,047 records, this is a relatively low-volume table compared to other event types, reflecting that chargebacks are infrequent but financially significant. Each row links to tblaff_Chargebacks_Commissions for the corresponding negative commission adjustments.

No cascade triggers exist on this table (unlike other event tables), suggesting chargebacks are handled through a different cleanup process.

---

## 2. Business Logic

### 2.1 Chargeback Validation

**What**: Each chargeback event is validated before commission clawback.

**Columns/Parameters Involved**: `AffiliateChargebackAccepted`, `Valid`, `Reason`

**Rules**:
- AffiliateChargebackAccepted=1: The chargeback is attributed to an affiliate's referred customer
- Valid=1: The chargeback is confirmed and valid for commission clawback
- Both must be TRUE for negative commission adjustments to be applied
- GRAND_TOTAL typically represents the chargeback amount (positive value representing money returned to customer)

---

## 3. Data Overview

N/A - chargeback events represent disputed transactions from affiliate-referred customers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChargebackID | int | NO | IDENTITY(1,1) | VERIFIED | Primary key. Unique identifier for each chargeback event. NOT FOR REPLICATION. |
| 2 | CUSTOMER_ID | nvarchar(50) | YES | - | VERIFIED | Customer identifier from the trading platform. |
| 3 | ORDER_DATE | datetime | YES | - | VERIFIED | Timestamp when the chargeback was processed. Clustered index column. |
| 4 | COUNTRY | nvarchar(50) | YES | - | CODE-BACKED | Legacy country name text. Superseded by CountryID. |
| 5 | GRAND_TOTAL | float | YES | 0 | VERIFIED | Chargeback amount. The monetary value of the disputed transaction being reversed. |
| 6 | AffiliateChargebackAccepted | bit | NO | 0 | VERIFIED | Whether this chargeback is attributed to an affiliate. 1=accepted for commission clawback, 0=not attributed. |
| 7 | IPAddress | nvarchar(20) | YES | - | CODE-BACKED | Customer's IP address. Fraud detection. |
| 8 | Browser | nvarchar(255) | YES | - | CODE-BACKED | Customer's user agent. Fraud detection. |
| 9 | Valid | bit | NO | 0 | VERIFIED | Whether the chargeback passed validation. 1=confirmed for clawback, 0=rejected. |
| 10 | Reason | nvarchar(50) | YES | - | CODE-BACKED | Rejection reason when Valid=0. |
| 11 | BannerID | int | NO | 0 | VERIFIED | Marketing banner. References dbo.tblaff_Banners [done]. |
| 12 | DaysToConvert | real | NO | 0 | CODE-BACKED | Days between affiliate click and this chargeback. |
| 13 | Optional1 | nvarchar(25) | YES | - | CODE-BACKED | Sub-affiliate tracking parameter. |
| 14 | Optional2 | nvarchar(25) | YES | - | CODE-BACKED | Secondary tracking parameter. |
| 15 | Optional3 | bigint | YES | - | VERIFIED | Original CID or extended tracking ID. Has NC index. |
| 16 | DownloadID | bigint | YES | 0 | CODE-BACKED | App download event ID. |
| 17 | ProviderID | bigint | NO | 1 | VERIFIED | Currently attributed affiliate provider. |
| 18 | OriginalProviderID | bigint | NO | 1 | VERIFIED | First affiliate that acquired this customer. |
| 19 | CountryID | bigint | NO | 0 | VERIFIED | Customer's country. References dbo.tblaff_Country [done]. |
| 20 | DID | bigint | YES | - | CODE-BACKED | Download tracking ID. |
| 21 | FID | bigint | YES | - | CODE-BACKED | Funnel tracking ID. |
| 22 | RealProviderID | bigint | NO | 1 | VERIFIED | Leaf-level provider after IB hierarchy resolution. |
| 23 | FunnelID | int | YES | - | NAME-INFERRED | Marketing funnel identifier. |
| 24 | LabelID | int | YES | - | NAME-INFERRED | Marketing label/campaign identifier. |
| 25 | PlayerLevelID | int | YES | - | NAME-INFERRED | Customer tier at event time. |
| 26 | ClubID | int | YES | - | NAME-INFERRED | Customer club membership. |

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
| dbo.tblaff_Chargebacks_Commissions | ChargebackID | Implicit FK | Negative commission records for this chargeback |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Chargebacks_Commissions | Table | Implicit FK on ChargebackID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_Chargebacks_PK | NC PK | ChargebackID | - | - | Active |
| IX_tblaff_Chargebacks_ORDER_DATE | CLUSTERED | ORDER_DATE | - | - | Active (FILLFACTOR=90) |
| IDX_tblaff_Chargebacks_Optional3 | NC | Optional3 | ChargebackID | - | Active (PAGE compressed) |

### 7.2 Constraints

None (no cascade triggers unlike other event tables).

---

## 8. Sample Queries

### 8.1 Get valid chargebacks
```sql
SELECT TOP 10 ChargebackID, CUSTOMER_ID, ORDER_DATE, GRAND_TOTAL
FROM dbo.tblaff_Chargebacks WITH (NOLOCK)
WHERE AffiliateChargebackAccepted = 1 AND Valid = 1
ORDER BY ORDER_DATE DESC
```

### 8.2 Chargeback summary by provider
```sql
SELECT ProviderID, COUNT(*) AS ChargebackCount, SUM(GRAND_TOTAL) AS TotalAmount
FROM dbo.tblaff_Chargebacks WITH (NOLOCK)
WHERE Valid = 1
GROUP BY ProviderID
ORDER BY TotalAmount DESC
```

### 8.3 Join chargebacks with commissions
```sql
SELECT cb.ChargebackID, cb.CUSTOMER_ID, cb.GRAND_TOTAL,
       cc.AffiliateID, cc.Commission, cc.Tier
FROM dbo.tblaff_Chargebacks cb WITH (NOLOCK)
JOIN dbo.tblaff_Chargebacks_Commissions cc WITH (NOLOCK) ON cb.ChargebackID = cc.ChargebackID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 8/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 11 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Chargebacks | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Chargebacks.sql*
