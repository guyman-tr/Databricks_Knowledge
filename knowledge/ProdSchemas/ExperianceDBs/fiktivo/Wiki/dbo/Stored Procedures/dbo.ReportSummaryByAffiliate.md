# dbo.ReportSummaryByAffiliate

## 1. Overview

Generates a flexible summary report for a single affiliate over a specified date range, combining data from registrations, CPA (first-time deposits), bonuses, sales, and chargebacks. Grouping dimensions (date, month, banner, serial/sub-affiliate, customer, country, tier) and the metric categories to include (registrations, FTDs, sales/revenue) are all runtime-controlled via bit flags. Used to power the affiliate performance summary view in the reporting console.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_Registrations, dbo.tblaff_CPA, dbo.tblaff_Bonuses, dbo.tblaff_Sales, dbo.tblaff_Chargebacks |
| Secondary Tables | dbo.tblaff_Registrations_Commissions, dbo.tblaff_CPA_Commissions, dbo.tblaff_Bonuses_Commissions, dbo.tblaff_Sales_Commissions, dbo.tblaff_Chargebacks_Commissions |
| Operation | SELECT |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

Returns one row per unique combination of the enabled grouping dimensions within the requested date range for the specified affiliate. Columns are conditionally populated based on the aggregate flags:

| Column | Condition | Description |
|---|---|---|
| Date | @GroupByDate = 1 | Calendar date of the events |
| Month | @GroupByMonth = 1 | Month number |
| BannerID | @GroupByBannerId = 1 | Banner that generated the event |
| SerialID | @GroupBySerialId = 1 | Sub-affiliate serial ID |
| CustomerID | @GroupByCustomerId = 1 | Customer associated with the event |
| CountryID | @GroupByCountryId = 1 | Country of the event |
| Tier | @GroupByTier = 1 | Commission tier |
| Registrations | @AggregateRegistrations = 1 | Count of registration events |
| FTDs | @AggregateFTDs = 1 | Count of first-time deposits |
| FTDEs | @AggregateFTDs = 1 | Count of FTD-eligible events |
| RegistrationCommission | @AggregateRegistrations = 1 | Commission earned on registrations |
| FTDCommission | @AggregateFTDs = 1 | Commission earned on valid FTDs |
| FTDAmount | @AggregateFTDs = 1 | Total deposit amount for Optional FTDs |
| DepositAmount | @AggregateFTDs = 1 | Total gross deposit amount |
| FTDEAmount | @AggregateFTDs = 1 | Total deposit amount for valid FTDs |
| RevenueCommission | @AggregateSales = 1 | Commission on sales and chargebacks |
| GrossRevenue | @AggregateSales = 1 | Gross sales total |
| NetRevenue | @AggregateSales = 1 | Net revenue (sales + chargebacks) |
| RefundsAndChargebacks | @AggregateSales = 1 | Chargeback total |
| Bonuses | @AggregateSales = 1 | Bonus total |

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @AffiliateId | IN | INT | required | Affiliate to report on. |
| @FromDate | IN | DateTime | required | Start of the date range (inclusive; truncated to date). |
| @ToDate | IN | DateTime | required | End of the date range (inclusive; truncated to date). |
| @GroupByDate | IN | BIT | required | 1 = group by calendar date. |
| @GroupByMonth | IN | BIT | required | 1 = group by month. |
| @GroupByBannerId | IN | BIT | required | 1 = group by BannerID. |
| @GroupBySerialId | IN | BIT | required | 1 = group by SerialID (sub-affiliate). |
| @GroupByCustomerId | IN | BIT | required | 1 = group by CustomerID. |
| @GroupByCountryId | IN | BIT | required | 1 = group by CountryID. |
| @GroupByTier | IN | BIT | required | 1 = group by commission tier. |
| @AggregateRegistrations | IN | BIT | required | 1 = include registration metrics. |
| @AggregateFTDs | IN | BIT | required | 1 = include FTD/CPA metrics. |
| @AggregateSales | IN | BIT | required | 1 = include sales/revenue/bonus/chargeback metrics. |
| @Tiers | IN | dbo.IDTableType READONLY | required | Table-valued parameter listing the tier IDs to include. |

## 5. Business Logic

1. Truncates `@FromDate` and `@ToDate` to date precision.
2. Builds a unified derived table (`u`) via UNION ALL across five event types:
   - AType 0: Registrations (from `tblaff_Registrations_Commissions` JOIN `tblaff_Registrations`)
   - AType 1: CPA / FTD (from `tblaff_CPA_Commissions` JOIN `tblaff_CPA`)
   - AType 2: Bonuses (from `tblaff_Bonuses_Commissions` JOIN `tblaff_Bonuses`)
   - AType 3: Sales (from `tblaff_Sales_Commissions` JOIN `tblaff_Sales`, with HedgeCommission deducted)
   - AType 4: Chargebacks (from `tblaff_Chargebacks_Commissions` JOIN `tblaff_Chargebacks`)
3. Each union arm is conditionally included via `WHERE 1 = @Aggregate*` so unused arms produce no rows.
4. Filters the union result by `AffiliateID`, date range, and `@Tiers`.
5. Groups and aggregates using CASE expressions; inactive grouping dimensions produce NULL (rather than a constant) so the caller can distinguish "not grouped" from a meaningful value.
6. Uses `OPTION (RECOMPILE)` to ensure an optimal plan for the specific combination of active grouping flags.
7. All tables queried with `NOLOCK`.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_Registrations | Table | dbo | Registration events |
| dbo.tblaff_Registrations_Commissions | Table | dbo | Commission details for registrations |
| dbo.tblaff_CPA | Table | dbo | First-time deposit events |
| dbo.tblaff_CPA_Commissions | Table | dbo | Commission details for CPA/FTD events |
| dbo.tblaff_Bonuses | Table | dbo | Bonus events |
| dbo.tblaff_Bonuses_Commissions | Table | dbo | Commission details for bonuses |
| dbo.tblaff_Sales | Table | dbo | Sales (net revenue) events |
| dbo.tblaff_Sales_Commissions | Table | dbo | Commission details for sales |
| dbo.tblaff_Chargebacks | Table | dbo | Chargeback events |
| dbo.tblaff_Chargebacks_Commissions | Table | dbo | Commission details for chargebacks |
| dbo.IDTableType | User-Defined Table Type | dbo | Table type for @Tiers parameter |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- `OPTION (RECOMPILE)` forces a fresh plan on each call; this is appropriate given that the active grouping columns and aggregate flags vary per call, but adds compilation overhead on high-frequency calls.
- UNION ALL across five large tables without date-range pushdown in the outer WHERE is mitigated by the `WHERE 1 = @Aggregate*` filter in each arm, which eliminates unused arms entirely.

## 8. Usage Examples

```sql
-- Summary by date and banner for affiliate 1001, June 2024, all tiers, registrations and FTDs only
DECLARE @tiers dbo.IDTableType;
INSERT INTO @tiers VALUES (1), (2), (3);

EXEC dbo.ReportSummaryByAffiliate
    @AffiliateId            = 1001,
    @FromDate               = '2024-06-01',
    @ToDate                 = '2024-06-30',
    @GroupByDate            = 1,
    @GroupByMonth           = 0,
    @GroupByBannerId        = 1,
    @GroupBySerialId        = 0,
    @GroupByCustomerId      = 0,
    @GroupByCountryId       = 0,
    @GroupByTier            = 0,
    @AggregateRegistrations = 1,
    @AggregateFTDs          = 1,
    @AggregateSales         = 0,
    @Tiers                  = @tiers;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2020-08-17 | Ran Ovadia | N/A | Created: new report replacing [AffWizReports].[ReportSummaryByAffiliate] |

---
*Object: dbo.ReportSummaryByAffiliate | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.ReportSummaryByAffiliate.sql*
