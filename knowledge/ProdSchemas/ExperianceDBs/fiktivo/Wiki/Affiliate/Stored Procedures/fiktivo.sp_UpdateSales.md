# fiktivo.sp_UpdateSales

> Inserts a new sales event or updates an existing one in dbo.tblaff_Sales using an upsert pattern, returning the sale ID and whether a new record was created.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SalesID OUTPUT, @DidCreateNew OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_UpdateSales is the primary writer procedure for sales event records in the affiliate commission system. It records trading activity (sales) that qualify for affiliate commission calculation. Unlike most "Update" procedures in the affiliate schema which are INSERT-only, sp_UpdateSales implements a true upsert pattern: if a matching sale already exists for the same affiliate, date, tracking tokens, and provider, the existing record's monetary amounts are accumulated rather than creating a duplicate row.

This upsert behavior is critical for trading platforms where a single customer may generate multiple trades throughout a trading day. Rather than creating a separate sales record per trade, the procedure aggregates the day's activity into a single record per affiliate-customer-provider-date combination. This aggregation simplifies downstream commission calculations and payment reporting while preserving the granularity needed for commission tier evaluation.

The procedure also performs unit conversion on two monetary inputs: @NetProfit and @USED_BONUS_GRAND_TOTAL are both divided by 100 before storage, converting from cents (or basis points) to the standard currency unit used throughout the commission system. This normalization ensures consistency with other commission tables where amounts are stored in whole currency units.

---

## 2. Business Logic

### 2.1 Input Normalization

**What**: Converts cent-denominated monetary values to standard currency units before any database operations.

**Columns/Parameters Involved**: @NetProfit, @USED_BONUS_GRAND_TOTAL

**Rules**:
- @NetProfit is divided by 100 (cents-to-currency conversion) before use in INSERT or UPDATE
- @USED_BONUS_GRAND_TOTAL is divided by 100 (cents-to-currency conversion) before use in INSERT or UPDATE
- All other monetary parameters (@GRAND_TOTAL, @HedgeCommission) are used as-is without conversion

### 2.2 Duplicate Detection (Match Lookup)

**What**: Searches for an existing unpaid sale record that matches the current event's key dimensions.

**Columns/Parameters Involved**: AffiliateID, Optional1, Optional3, OriginalProviderID, ORDER_DATE, Paid

**Rules**:
- A matching record must satisfy ALL of these conditions:
  - Same @AffiliateID
  - Same @Optional1 (tracking token / sub-ID)
  - Same @Optional3 (secondary tracking identifier)
  - Same @OriginalProviderID
  - Same date (ORDER_DATE compared at date-level granularity, same day)
  - Paid = 0 (only unpaid records can be aggregated into)
- If multiple matches exist, the first one found is used (non-deterministic; relies on underlying table order)

### 2.3 UPDATE Path (Match Found)

**What**: When a matching unpaid sale is found, accumulates the new amounts into the existing record.

**Columns/Parameters Involved**: GRAND_TOTAL, HedgeCommission, NetProfit, LotCount, USED_BONUS_GRAND_TOTAL, SalesID, DidCreateNew

**Rules**:
- UPDATE dbo.tblaff_Sales SET:
  - GRAND_TOTAL = GRAND_TOTAL + @GRAND_TOTAL (accumulates trading volume)
  - HedgeCommission = HedgeCommission + @HedgeCommission (accumulates hedge commission)
  - NetProfit = NetProfit + (@NetProfit / 100) (accumulates converted net profit)
  - LotCount = LotCount + @LotCount (accumulates lot volume)
  - USED_BONUS_GRAND_TOTAL = USED_BONUS_GRAND_TOTAL + (@USED_BONUS_GRAND_TOTAL / 100) (accumulates converted bonus total)
- @SalesID OUTPUT is set to the existing record's SalesID
- @DidCreateNew OUTPUT is set to 0 (indicates update, not insert)

### 2.4 INSERT Path (No Match Found)

**What**: When no matching record is found, creates a new sale record with all provided values.

**Columns/Parameters Involved**: All input parameters

**Rules**:
- INSERT INTO dbo.tblaff_Sales with all parameter values mapped directly to columns
- @NetProfit / 100 and @USED_BONUS_GRAND_TOTAL / 100 are stored (converted values)
- SELECT @SalesID = SCOPE_IDENTITY() to capture the auto-generated identity value
- @DidCreateNew OUTPUT is set to 1 (indicates new insert)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INT (IN) | NO | - | CODE-BACKED | The affiliate earning commission on this sale. Used as part of the upsert match key. |
| 2 | @CUSTOMER_ID | NVARCHAR(50) (IN) | NO | - | CODE-BACKED | The customer identifier associated with this trading activity. |
| 3 | @ORDER_DATE | DATETIME (IN) | NO | - | CODE-BACKED | The date and time of the trading activity. The date portion is used for upsert matching. |
| 4 | @GRAND_TOTAL | FLOAT (IN) | NO | - | CODE-BACKED | The trading volume amount in standard currency units. Accumulated on UPDATE path. |
| 5 | @HedgeCommission | FLOAT (IN) | NO | - | CODE-BACKED | The hedge commission amount. Accumulated on UPDATE path. |
| 6 | @AffiliateSaleAccepted | BIT (IN) | NO | 1 | CODE-BACKED | Whether the sale event passed initial validation. 1 = accepted, 0 = rejected. |
| 7 | @Valid | BIT (IN) | NO | 1 | CODE-BACKED | Whether the record is active for commission processing. 1 = valid, 0 = invalidated. |
| 8 | @BannerID | INT (IN) | NO | 0 | CODE-BACKED | The marketing banner or creative that the customer clicked through. 0 = no banner tracked. |
| 9 | @DaysToConvert | REAL (IN) | NO | 0 | CODE-BACKED | Number of days between customer registration and this sale event. |
| 10 | @Optional1 | NVARCHAR(25) (IN) | YES | - | CODE-BACKED | Custom tracking field 1 (sub-ID / campaign token). Part of the upsert match key. |
| 11 | @Optional2 | NVARCHAR(25) (IN) | YES | - | CODE-BACKED | Custom tracking field 2, typically used for additional segmentation. |
| 12 | @Optional3 | BIGINT (IN) | YES | - | CODE-BACKED | Custom tracking field 3 (secondary identifier). Part of the upsert match key. |
| 13 | @DownloadID | BIGINT (IN) | NO | 0 | CODE-BACKED | Reference to the download/registration event. 0 = not tracked. |
| 14 | @ProviderID | BIGINT (IN) | NO | 0 | CODE-BACKED | The provider (broker/platform) ID assigned at the time of the event. |
| 15 | @OriginalProviderID | BIGINT (IN) | NO | 0 | CODE-BACKED | The original provider ID at customer registration time. Part of the upsert match key. |
| 16 | @CountryID | BIGINT (IN) | NO | 0 | CODE-BACKED | The country code of the customer. 0 = unknown. |
| 17 | @NetProfit | FLOAT (IN) | NO | 0 | CODE-BACKED | Net profit in cents. Divided by 100 before storage. Accumulated on UPDATE path. |
| 18 | @LotCount | DECIMAL(16,6) (IN) | NO | 0 | CODE-BACKED | Number of lots traded. Accumulated on UPDATE path. |
| 19 | @RealProviderID | BIGINT (IN) | NO | 1 | CODE-BACKED | The actual provider ID used for commission calculations. |
| 20 | @FunnelID | INT (IN) | NO | 0 | CODE-BACKED | Marketing funnel identifier. 0 = default/unclassified. |
| 21 | @LabelID | INT (IN) | NO | 1 | CODE-BACKED | White-label identifier. 1 = default label. |
| 22 | @PlayerLevelID | INT (IN) | NO | 1 | CODE-BACKED | Player tier/level classification. 1 = default level. |
| 23 | @USED_BONUS_GRAND_TOTAL | DECIMAL(18,6) (IN) | NO | 0 | CODE-BACKED | Bonus portion of the trade volume in cents. Divided by 100 before storage. Accumulated on UPDATE path. |
| 24 | @SalesID | INT (OUTPUT) | NO | - | CODE-BACKED | Returns the SalesID of the affected record, whether newly inserted or updated. |
| 25 | @DidCreateNew | BIT (OUTPUT) | NO | - | CODE-BACKED | Indicates the operation performed. 1 = new record inserted, 0 = existing record updated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_Sales | INSERT / UPDATE | Inserts new sales record or updates existing matching record (upsert) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_UpdateSales (procedure)
└── dbo.tblaff_Sales (table, cross-schema)
```

### 6.1 Objects This Depends On

1 cross-schema dbo table (tblaff_Sales).

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Insert a new sale for an affiliate (first trade of the day)
```sql
DECLARE @SalesID INT, @DidCreateNew BIT
EXEC fiktivo.sp_UpdateSales
    @AffiliateID = 100,
    @CUSTOMER_ID = N'CUST-98765',
    @ORDER_DATE = '2026-04-12 10:15:00',
    @GRAND_TOTAL = 1500.00,
    @HedgeCommission = 12.50,
    @AffiliateSaleAccepted = 1,
    @Valid = 1,
    @BannerID = 42,
    @DaysToConvert = 7.0,
    @Optional1 = N'spring_promo',
    @Optional2 = N'landing_v3',
    @Optional3 = 555,
    @DownloadID = 112233,
    @ProviderID = 5,
    @OriginalProviderID = 5,
    @CountryID = 276,
    @NetProfit = 32500,          -- 325.00 in cents
    @LotCount = 2.500000,
    @RealProviderID = 1,
    @FunnelID = 10,
    @LabelID = 1,
    @PlayerLevelID = 1,
    @USED_BONUS_GRAND_TOTAL = 5000,  -- 50.00 in cents
    @SalesID = @SalesID OUTPUT,
    @DidCreateNew = @DidCreateNew OUTPUT
SELECT @SalesID AS SalesID, @DidCreateNew AS DidCreateNew
```

### 8.2 Verify upsert behavior by checking accumulated values
```sql
SELECT
    SalesID,
    AffiliateID,
    CUSTOMER_ID,
    ORDER_DATE,
    GRAND_TOTAL,
    HedgeCommission,
    NetProfit,
    LotCount,
    USED_BONUS_GRAND_TOTAL,
    Paid
FROM dbo.tblaff_Sales WITH (NOLOCK)
WHERE AffiliateID = 100
    AND Optional1 = N'spring_promo'
    AND CAST(ORDER_DATE AS DATE) = '2026-04-12'
    AND Paid = 0
ORDER BY SalesID DESC
```

### 8.3 Review recent sales activity with insert vs update breakdown
```sql
SELECT
    CAST(ORDER_DATE AS DATE) AS SaleDate,
    AffiliateID,
    COUNT(*) AS RecordCount,
    SUM(GRAND_TOTAL) AS TotalVolume,
    SUM(NetProfit) AS TotalNetProfit,
    SUM(LotCount) AS TotalLots
FROM dbo.tblaff_Sales WITH (NOLOCK)
WHERE ORDER_DATE >= DATEADD(DAY, -7, GETDATE())
    AND Valid = 1
    AND AffiliateSaleAccepted = 1
GROUP BY CAST(ORDER_DATE AS DATE), AffiliateID
ORDER BY SaleDate DESC, TotalVolume DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 8.5/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_UpdateSales | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_UpdateSales.sql*
