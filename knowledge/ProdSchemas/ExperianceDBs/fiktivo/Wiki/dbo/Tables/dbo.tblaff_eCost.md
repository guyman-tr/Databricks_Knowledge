# dbo.tblaff_eCost

> Tracks individual marketing expense (eCost) events attributed to the affiliate program, recording granular expense line items linked to eCostHistory agreements.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | eCostID (INT IDENTITY, NC PK) |
| **Partition** | No |
| **Indexes** | 2 active (1 NC PK, 1 clustered on ORDER_DATE) |

---

## 1. Business Meaning

This table records individual marketing expense (eCost) events - granular line items that roll up to the eCost agreements in dbo.tblaff_eCostHistory. With 1,471,834 records, this is a high-volume table tracking each marketing cost event attributed to the affiliate program.

Each row represents a specific expense instance for a customer interaction. The eCostHistoryID column links each event to its parent agreement in tblaff_eCostHistory. This parent-child relationship allows a single eCost agreement (e.g., "$5,000 for Q1 marketing") to be broken down into individual customer-level expense attributions.

The table follows the standard event table pattern (CUSTOMER_ID, ORDER_DATE, BannerID, CountryID, ProviderID chain) and has cascade-delete and update triggers linking to tblaff_eCost_Commissions. The eCost_Commissions trigger enforces FK integrity against both tblaff_Affiliates and this table.

---

## 2. Business Logic

### 2.1 eCost Event Validation

**What**: Each eCost event passes through validation and attribution.

**Columns/Parameters Involved**: `AffiliateeCostAccepted`, `Valid`, `Reason`

**Rules**:
- AffiliateeCostAccepted=1: The expense event is attributed to an affiliate
- Valid=1: The event passed validation
- Both must be TRUE for eCost commissions to be calculated in tblaff_eCost_Commissions

### 2.2 eCostHistory Linkage

**What**: Each event links to a parent eCost agreement.

**Columns/Parameters Involved**: `eCostHistoryID`

**Rules**:
- eCostHistoryID references tblaff_eCostHistory.eCostHistoryID
- Default 0 indicates no specific agreement linkage (ad-hoc or legacy events)
- When linked, the eCostHistory record provides the currency, total budget, and date range context

---

## 3. Data Overview

N/A - eCost events represent individual marketing expense attributions for affiliate-referred customers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | eCostID | int | NO | IDENTITY(1,1) | VERIFIED | Primary key. Unique identifier for each eCost event. NOT FOR REPLICATION. Referenced by tblaff_eCost_Commissions.eCostID via trigger-enforced FK. |
| 2 | CUSTOMER_ID | nvarchar(50) | YES | - | VERIFIED | Customer identifier from the trading platform. |
| 3 | ORDER_DATE | datetime | YES | - | VERIFIED | Timestamp of the eCost event. Clustered index column. |
| 4 | AffiliateeCostAccepted | bit | NO | 0 | VERIFIED | Attribution flag. 1=accepted for commission, 0=not attributed. |
| 5 | IPAddress | nvarchar(20) | YES | - | CODE-BACKED | Customer's IP address. |
| 6 | Browser | nvarchar(255) | YES | - | CODE-BACKED | Customer's user agent. |
| 7 | Valid | bit | NO | 0 | VERIFIED | Validation flag. 1=valid for commission, 0=rejected. |
| 8 | Reason | nvarchar(50) | YES | - | CODE-BACKED | Rejection reason when Valid=0. |
| 9 | BannerID | int | NO | 0 | VERIFIED | Marketing banner. References dbo.tblaff_Banners [done]. |
| 10 | DaysToConvert | real | NO | 0 | CODE-BACKED | Days between affiliate click and this event. |
| 11 | Optional1 | nvarchar(25) | YES | - | CODE-BACKED | Sub-affiliate tracking parameter. |
| 12 | Optional2 | nvarchar(25) | YES | - | CODE-BACKED | Secondary tracking parameter. |
| 13 | Optional3 | bigint | YES | - | CODE-BACKED | Original CID or extended tracking ID. |
| 14 | Real | bit | YES | - | CODE-BACKED | Whether from a real (funded) or demo account. 1=real, NULL/0=demo. |
| 15 | DownloadID | bigint | YES | 0 | CODE-BACKED | App download event ID. |
| 16 | ProviderID | bigint | NO | 1 | VERIFIED | Currently attributed affiliate provider. |
| 17 | OriginalProviderID | bigint | NO | 1 | VERIFIED | First affiliate that acquired this customer. |
| 18 | CountryID | bigint | YES | 0 | VERIFIED | Customer's country. References dbo.tblaff_Country [done]. Nullable unlike other event tables. |
| 19 | DID | bigint | YES | - | CODE-BACKED | Download tracking ID. |
| 20 | FID | bigint | YES | - | CODE-BACKED | Funnel tracking ID. |
| 21 | RealProviderID | bigint | NO | 1 | VERIFIED | Leaf-level provider after IB hierarchy resolution. |
| 22 | Comment | nvarchar(max) | YES | - | CODE-BACKED | Free-text comment about this specific expense event. Used for line-item annotations. |
| 23 | eCostHistoryID | int | YES | 0 | VERIFIED | Parent eCost agreement. References dbo.tblaff_eCostHistory.eCostHistoryID. 0=no agreement linkage (ad-hoc). |
| 24 | FunnelID | int | YES | - | NAME-INFERRED | Marketing funnel identifier. |
| 25 | LabelID | int | YES | - | NAME-INFERRED | Marketing label/campaign identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| eCostHistoryID | dbo.tblaff_eCostHistory | Implicit FK | Parent eCost agreement defining the budget and terms |
| BannerID | dbo.tblaff_Banners | Implicit | Marketing banner |
| CountryID | dbo.tblaff_Country | Implicit | Customer's country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_eCost_Commissions | eCostID | Trigger cascade-delete + trigger-enforced FK | eCost commission records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.tblaff_eCost (table)
+-- dbo.tblaff_eCostHistory (table) [implicit FK via eCostHistoryID]
      +-- Dictionary.Currency (table) [explicit FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_eCostHistory | Table | Implicit FK on eCostHistoryID (parent agreement) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_eCost_Commissions | Table | Cascade-deleted via trigger; trigger-enforced FK on eCostID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaatblaff_eCost_PK | NC PK | eCostID | - | - | Active (PAGE compressed) |
| CIX_tblaff_eCost_ORDER_DATE | CLUSTERED | ORDER_DATE | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression |
| tblaff_eCost_DTrig | Trigger (DELETE) | Cascade-deletes to tblaff_eCost_Commissions |
| tblaff_eCost_UTrig | Trigger (UPDATE) | Prevents eCostID changes when commissions exist |

---

## 8. Sample Queries

### 8.1 Recent valid eCost events
```sql
SELECT TOP 10 eCostID, CUSTOMER_ID, ORDER_DATE, eCostHistoryID, ProviderID
FROM dbo.tblaff_eCost WITH (NOLOCK)
WHERE AffiliateeCostAccepted = 1 AND Valid = 1
ORDER BY ORDER_DATE DESC
```

### 8.2 eCost events for a specific agreement
```sql
SELECT ec.eCostID, ec.CUSTOMER_ID, ec.ORDER_DATE, ec.CountryID
FROM dbo.tblaff_eCost ec WITH (NOLOCK)
WHERE ec.eCostHistoryID = 15774
ORDER BY ec.ORDER_DATE
```

### 8.3 eCost events with commissions and affiliate details
```sql
SELECT ec.eCostID, ec.CUSTOMER_ID,
       ecc.AffiliateID, ecc.Commission, ecc.Tier, ecc.Paid
FROM dbo.tblaff_eCost ec WITH (NOLOCK)
JOIN dbo.tblaff_eCost_Commissions ecc WITH (NOLOCK) ON ec.eCostID = ecc.eCostID
WHERE ec.eCostHistoryID = 15774
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (triggers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_eCost | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_eCost.sql*
