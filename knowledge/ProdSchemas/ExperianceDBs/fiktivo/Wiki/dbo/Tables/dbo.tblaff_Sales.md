# dbo.tblaff_Sales

> Tracks sales/trading activity events - records closed trades by affiliate-referred customers for revenue-share commission calculations.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | SalesID (INT IDENTITY, NC PK) |
| **Partition** | No |
| **Indexes** | 8 active (1 NC PK, 1 clustered on ORDER_DATE, 6 NC) |

---

## 1. Business Meaning

This is the second highest-volume event table (2,540,421 records) and the most financially important. Each row represents a completed trade (closed position) by a customer referred through the affiliate program. Sales events are the basis for revenue-share commission models - the most common commission type in the eToro affiliate system.

Unlike CPA (fixed fee per deposit) or registration commissions, sales commissions are calculated as a percentage of the trade's spread revenue or net profit. The GRAND_TOTAL, NetProfit, HedgeCommission, and LotCount columns provide the financial details needed for these calculations.

The table has cascade-delete and update triggers to tblaff_Sales_Commissions. The delete trigger on tblaff_Affiliates also cascade-deletes from Sales_Commissions.

---

## 2. Business Logic

### 2.1 Revenue-Share Commission Calculation

**What**: Sales commissions are calculated from trade financial metrics.

**Columns/Parameters Involved**: `GRAND_TOTAL`, `NetProfit`, `HedgeCommission`, `LotCount`, `USED_BONUS_GRAND_TOTAL`

**Rules**:
- GRAND_TOTAL: The spread revenue from the trade - the primary base for commission calculation
- NetProfit: The net profit/loss from the trade (can be negative when the platform loses money)
- HedgeCommission: The hedging cost component (typically 10% of GRAND_TOTAL based on sample data)
- LotCount: Trade size in lots - larger trades generate more commission
- USED_BONUS_GRAND_TOTAL: Commission attributable to bonus funds usage - may be excluded or reduced in some commission plans

### 2.2 Sales Validation and Attribution

**What**: Each sale event passes through validation before commission calculation.

**Columns/Parameters Involved**: `AffiliateSaleAccepted`, `Valid`, `Reason`

**Rules**:
- AffiliateSaleAccepted=1: The trade is attributed to an affiliate
- Valid=1: The trade passed validation (not wash trade, legitimate activity)
- Both must be TRUE for sales commissions to be calculated

---

## 3. Data Overview

| SalesID | CUSTOMER_ID | ORDER_DATE | GRAND_TOTAL | HedgeCommission | NetProfit | LotCount | Meaning |
|---|---|---|---|---|---|---|---|
| 5631782 | 56D6530A... | 2023-07-19 | 1.12 | 0.112 | -0.0188 | 0.005 | Small trade with $1.12 spread revenue. Hedge commission is 10%. Net profit slightly negative - platform lost money but affiliate still earns on spread |
| 5631781 | 39192898... | 2023-07-19 | 0.46 | 0.046 | -0.0046 | 1.011 | Larger lot count (1.01) but low spread. Demonstrates that lot size and spread are independent |
| 5631780 | C5D50F96... | 2023-07-19 | 0.92 | 0.092 | -0.0092 | 2.023 | Largest trade in sample by lots. Consistent 10% hedge ratio pattern |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SalesID | int | NO | IDENTITY(1,1) | VERIFIED | Primary key. Unique identifier for each sale/trade event. NOT FOR REPLICATION. Referenced by tblaff_Sales_Commissions.SalesID. |
| 2 | CUSTOMER_ID | nvarchar(50) | YES | - | VERIFIED | Customer identifier (GUID format in recent data). |
| 3 | ORDER_DATE | datetime | YES | - | VERIFIED | Timestamp when the trade was closed. Clustered index column. |
| 4 | COUNTRY | nvarchar(50) | YES | - | CODE-BACKED | Legacy country name. Superseded by CountryID. |
| 5 | GRAND_TOTAL | float | YES | 0 | VERIFIED | Spread revenue from the trade. Primary base for revenue-share commission calculation. |
| 6 | HedgeCommission | float | YES | - | VERIFIED | Hedging cost component. Typically ~10% of GRAND_TOTAL. May be deducted from commission base in some models. |
| 7 | AffiliateSaleAccepted | bit | NO | 0 | VERIFIED | Attribution flag. 1=trade attributed to an affiliate, 0=not attributed. |
| 8 | IPAddress | nvarchar(20) | YES | - | CODE-BACKED | Customer's IP at trade time. |
| 9 | Browser | nvarchar(255) | YES | - | CODE-BACKED | Customer's user agent. |
| 10 | Valid | bit | NO | 0 | VERIFIED | Validation flag. 1=valid for commission, 0=rejected. |
| 11 | Reason | nvarchar(50) | YES | - | CODE-BACKED | Rejection reason when Valid=0. |
| 12 | BannerID | int | NO | 0 | VERIFIED | Marketing banner. References dbo.tblaff_Banners [done]. |
| 13 | DaysToConvert | real | NO | 0 | CODE-BACKED | Days between affiliate click and this trade. |
| 14 | Optional1 | nvarchar(25) | YES | - | VERIFIED | Sub-affiliate tracking parameter. |
| 15 | Optional2 | nvarchar(25) | YES | - | CODE-BACKED | Secondary tracking parameter. |
| 16 | Optional3 | bigint | YES | - | VERIFIED | Original CID or extended tracking ID. Has NC index. |
| 17 | DownloadID | bigint | YES | 0 | CODE-BACKED | App download event ID. |
| 18 | ProviderID | bigint | NO | 1 | VERIFIED | Currently attributed affiliate provider. |
| 19 | OriginalProviderID | bigint | NO | 1 | VERIFIED | First affiliate that acquired this customer. |
| 20 | CountryID | bigint | NO | 0 | VERIFIED | Customer's country. References dbo.tblaff_Country [done]. |
| 21 | NetProfit | float | YES | - | VERIFIED | Net profit/loss from the trade. Can be negative. Used in net revenue-share commission models. |
| 22 | LotCount | decimal(16,6) | YES | - | VERIFIED | Trade size in lots. Larger values = larger trades. High precision for fractional lot sizes. |
| 23 | DID | bigint | YES | - | CODE-BACKED | Download tracking ID. |
| 24 | FID | bigint | YES | - | CODE-BACKED | Funnel tracking ID. |
| 25 | RealProviderID | bigint | NO | 1 | VERIFIED | Leaf-level provider after IB hierarchy resolution. |
| 26 | FunnelID | int | YES | - | NAME-INFERRED | Marketing funnel identifier. |
| 27 | LabelID | int | YES | - | NAME-INFERRED | Marketing label/campaign identifier. |
| 28 | PlayerLevelID | int | YES | - | NAME-INFERRED | Customer tier at trade time. |
| 29 | USED_BONUS_GRAND_TOTAL | decimal(18,6) | YES | - | VERIFIED | Spread revenue attributable to bonus funds. May be excluded or reduced in commission calculations for some affiliate types. |
| 30 | ClubID | int | YES | - | NAME-INFERRED | Customer club membership. |

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
| dbo.tblaff_Sales_Commissions | SalesID | Trigger cascade-delete + trigger-enforced FK | Sales commission records |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Sales_Commissions | Table | Cascade-deleted via trigger; trigger-enforced FK on SalesID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_Sales_PK | NC PK | SalesID | - | - | Active (FILLFACTOR=90, PAGE compressed) |
| IX_tblaff_Sales_ORDER_DATE | CLUSTERED | ORDER_DATE | - | - | Active (FILLFACTOR=90, PAGE compressed) |
| Browser | NC | Browser | - | - | Active (FILLFACTOR=90) |
| CUSTOMER_ID | NC | CUSTOMER_ID | - | - | Active (FILLFACTOR=90) |
| IDX_tblaff_Sales_Optional3 | NC | Optional3 | SalesID | - | Active (PAGE compressed) |
| IPAddress | NC | IPAddress | - | - | Active (FILLFACTOR=90) |
| IX_tblaff_Sales_Options | NC | OriginalProviderID | SalesID, Optional3 | - | Active (PAGE compressed) |
| IX_tblaff_Sales_Payments | NC | AffiliateSaleAccepted, Valid | SalesID | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression |
| tblaff_Sales_DTrig | Trigger (DELETE) | Cascade-deletes to tblaff_Sales_Commissions |
| tblaff_Sales_UTrig | Trigger (UPDATE) | Prevents SalesID changes when commissions exist |

---

## 8. Sample Queries

### 8.1 Recent valid sales
```sql
SELECT TOP 10 SalesID, CUSTOMER_ID, ORDER_DATE, GRAND_TOTAL, NetProfit, LotCount
FROM dbo.tblaff_Sales WITH (NOLOCK)
WHERE AffiliateSaleAccepted = 1 AND Valid = 1
ORDER BY ORDER_DATE DESC
```

### 8.2 Sales revenue by provider
```sql
SELECT ProviderID, COUNT(*) AS Trades, SUM(GRAND_TOTAL) AS TotalRevenue, SUM(NetProfit) AS TotalNetProfit
FROM dbo.tblaff_Sales WITH (NOLOCK)
WHERE Valid = 1
GROUP BY ProviderID
ORDER BY TotalRevenue DESC
```

### 8.3 Sales with commissions and affiliate details
```sql
SELECT s.SalesID, s.GRAND_TOTAL, s.NetProfit,
       sc.AffiliateID, sc.Commission, sc.Tier, sc.UsedBonusCommission
FROM dbo.tblaff_Sales s WITH (NOLOCK)
JOIN dbo.tblaff_Sales_Commissions sc WITH (NOLOCK) ON s.SalesID = sc.SalesID
WHERE s.SalesID = 5631780
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 15 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (triggers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Sales | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Sales.sql*
