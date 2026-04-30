# dbo.SSRS_ICMarketsNetRevenue

## 1. Overview

Calculates daily net revenue attributed to IC Markets-eligible customers for a given date range. Filters sales to specific country IDs (country 12, and country 146 for registrations before 7 November 2016), excludes customers classified as PlayerLevel 4 (VIP/excluded segment), and sums net revenue (gross revenue plus used bonus grand total, minus hedge commission) for tier-1 commission rows. Designed for the IC Markets SSRS financial report.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_Sales |
| Secondary Tables | dbo.tblaff_Sales_Commissions, dbo.tblaff_Registrations, Customer.Customer |
| Operation | SELECT |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

Returns one row per calendar day in the requested period that has qualifying sales.

| Column | Type | Description |
|---|---|---|
| NetRev | float | Sum of net revenue for tier-1 sales: GRAND_TOTAL - HedgeCommission + USED_BONUS_GRAND_TOTAL |
| Date | datetime | Truncated to the start of the calendar day |

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @StartDate | IN | date | required | Inclusive start date for the sales window. |
| @EndDate | IN | date | required | Exclusive end date (ORDER_DATE < @EndDate). |

## 5. Business Logic

1. Builds a temp table `#PlayerLevel` containing the distinct `OriginalCID` values for all customers with `PlayerLevelID = 4` from `Customer.Customer`.
2. Queries `tblaff_Sales` joined to `tblaff_Sales_Commissions` (on `SalesID`) and LEFT JOINs `tblaff_Registrations` (matching on `Optional3` customer field) to access the registration date for country 146 customers.
3. **Filters applied:**
   - `tblaff_Sales_Commissions.Tier >= 1` (only commission rows).
   - `tblaff_Sales.Optional3 - 17 NOT IN (SELECT OriginalCID FROM #PlayerLevel)` — excludes PlayerLevel 4 customers using an offset of 17 applied to the Optional3 field to align to OriginalCID.
   - Country filter: `CountryID = 12` (Australia) OR (`CountryID = 146` AND registration date <= `2016-11-06`).
   - Date range: `ORDER_DATE >= @StartDate AND ORDER_DATE < @EndDate`.
4. **Aggregation:** `SUM(GRAND_TOTAL - ISNULL(HedgeCommission, 0) + USED_BONUS_GRAND_TOTAL)` grouped by calendar day using `DATEDIFF`/`DATEADD` truncation. Only tier-1 rows are summed (CASE WHEN Tier=1).

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_Sales | Table | dbo | Source of sales events and revenue figures |
| dbo.tblaff_Sales_Commissions | Table | dbo | Links sales to commission tiers |
| dbo.tblaff_Registrations | Table | dbo | Provides registration date for country 146 cutoff logic |
| Customer.Customer | Table | Customer | Source of PlayerLevelID for exclusion list |
| #PlayerLevel | Temp Table | tempdb | Holds OriginalCIDs to exclude |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- The `Optional3 - 17` expression used to align CIDs for the PlayerLevel exclusion check is a domain-specific mapping; verify this offset remains valid if the customer numbering scheme changes.
- The LEFT JOIN to `tblaff_Registrations` on `Optional3` may produce multiple registration rows per sale if a customer has multiple registrations; the country 146 date filter logic may be affected by which registration row is matched.
- `NOLOCK` hints on all base tables reduce locking but allow dirty reads.

## 8. Usage Examples

```sql
-- Net revenue for IC Markets customers in May 2024
EXEC dbo.SSRS_ICMarketsNetRevenue
    @StartDate = '2024-05-01',
    @EndDate   = '2024-06-01';
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Unknown | Unknown | N/A | Initial creation |

---
*Object: dbo.SSRS_ICMarketsNetRevenue | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.SSRS_ICMarketsNetRevenue.sql*
