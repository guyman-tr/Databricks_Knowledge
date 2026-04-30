# dbo.ReportSummaryPerAffiliate

## 1. Overview

Returns individual commission event rows (not aggregated) for a single affiliate and, optionally, for up to four levels of sub-affiliates beneath it. Each row represents one commission record from registrations, CPA/FTDs, bonuses, sales, or chargebacks. The result set is used by the reporting layer to display per-transaction detail and support downstream grouping and totalling. This is the row-level companion to `ReportSummaryByAffiliate`.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_Registrations, dbo.tblaff_CPA, dbo.tblaff_Bonuses, dbo.tblaff_Sales, dbo.tblaff_Chargebacks |
| Secondary Tables | Commission junction tables, dbo.tblaff_Tier2Members, #childAffiliates (temp) |
| Operation | SELECT |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

Returns one row per commission event within the date range for the specified affiliate (own tier rows) UNION ALL with tier-1 rows from each child affiliate up to four levels deep. Columns include:

| Column | Description |
|---|---|
| AffiliateCommission | Always 0 (placeholder for caller-side calculation) |
| AffiliateID | Affiliate that generated the event |
| CommissionID | Primary key of the source commission record |
| AType | Event type: 0=Registration, 1=CPA, 2=Bonus, 3=Sale, 4=Chargeback |
| Date | Calendar date of the event |
| BannerID | Banner that generated the event |
| SerialID | Sub-affiliate serial ID |
| CustomerID | Customer associated with the event |
| CountryID | Country of the event |
| Tier | Commission tier |
| Registrations | 1 if AType=0 and @AggregateRegistrations=1, else NULL |
| FTDs | 1 if AType=1 and first-time deposit, else 0/NULL |
| FTDEs | 1 if AType=1 and valid first-time deposit, else 0/NULL |
| RegistrationCommission | Commission amount if AType=0, else NULL |
| FTDCommission | Commission on valid FTDs, else NULL |
| FTDAmount | Deposit amount for FTDs |
| DepositAmount | Total deposit amount for AType=1 |
| FTDEAmount | Deposit amount for valid FTDs |
| SaleCommission | Commission if AType=3 |
| GrossRevenue | Total sale amount if AType=3 |
| SaleRevenue | Same as GrossRevenue |
| ChargebackRevenue | Total amount if AType=4 |
| ChargebackCommission | Commission if AType=4 |
| Bonuses | Bonus amount if AType=2 |

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @AffiliateId | IN | INT | required | The primary affiliate to report on. |
| @FromDate | IN | DateTime | required | Start of the date range (inclusive; truncated to date). |
| @ToDate | IN | DateTime | required | End of the date range (inclusive; date + 1 day appended for range math). |
| @AggregateRegistrations | IN | BIT | required | 1 = include registration events. |
| @AggregateFTDs | IN | BIT | required | 1 = include CPA/FTD events. |
| @AggregateSales | IN | BIT | required | 1 = include sales/chargeback events. |
| @tiers | IN | dbo.IDTableType READONLY | required | Table listing the tier IDs to include for the primary affiliate. Child affiliates are always tier 1. |

## 5. Business Logic

1. Adjusts `@ToDate` to `DateAdd(Day, 1, @ToDate)` for exclusive upper-bound range filtering.
2. **Child affiliates CTE (`cte_affiliations`):** Recursively walks `tblaff_Tier2Members` from `@AffiliateId` up to 4 levels (tier 2 through 5 inclusive); inserts matching `NewMemberID` values into `#childAffiliates` temp table filtered by the requested `@tiers`.
3. **First UNION member:** Queries all five event types for `AffiliateID = @AffiliateId` within the date window and the caller-specified tiers. Mirrors the same AType coding as `ReportSummaryByAffiliate` but returns unaggregated rows (one row per commission record).
4. **Second UNION member:** Queries the same five event types for affiliates in `#childAffiliates`, but only at tier 1. Bonus arm is commented out for child affiliates.
5. Column values for inactive aggregate categories are returned as NULL (not 0) to allow the caller to distinguish "not requested" from "zero value".

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_Registrations + _Commissions | Tables | dbo | Registration events and their commission rows |
| dbo.tblaff_CPA + _Commissions | Tables | dbo | CPA/FTD events and commissions |
| dbo.tblaff_Bonuses + _Commissions | Tables | dbo | Bonus events and commissions |
| dbo.tblaff_Sales + _Commissions | Tables | dbo | Sales events and commissions (with HedgeCommission deduction) |
| dbo.tblaff_Chargebacks + _Commissions | Tables | dbo | Chargeback events and commissions |
| dbo.tblaff_Tier2Members | Table | dbo | Defines sub-affiliate relationships for the recursive CTE |
| dbo.IDTableType | User-Defined Table Type | dbo | Table type for @tiers parameter |
| #childAffiliates | Temp Table | tempdb | Holds child affiliate IDs for the sub-affiliate union arm |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- The recursive CTE is limited to depth 4 (tiers 2-5) and uses the default `MAXRECURSION` limit; for affiliates with deep sub-affiliate trees this may need `OPTION (MAXRECURSION 0)`.
- All base table reads use `NOLOCK`.
- Returns unaggregated rows; the result set may be large for affiliates with many events over a wide date range.
- `HedgeCommission` is deducted from `GRAND_TOTAL` in the Sales arm to compute net revenue.

## 8. Usage Examples

```sql
DECLARE @tiers dbo.IDTableType;
INSERT INTO @tiers VALUES (1), (2);

EXEC dbo.ReportSummaryPerAffiliate
    @AffiliateId            = 1001,
    @FromDate               = '2024-06-01',
    @ToDate                 = '2024-06-30',
    @AggregateRegistrations = 1,
    @AggregateFTDs          = 1,
    @AggregateSales         = 1,
    @tiers                  = @tiers;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2020-08-17 | Ran Ovadia | N/A | Created: new report replacing [AffWizReports].[ReportSummaryByAffiliate] |

---
*Object: dbo.ReportSummaryPerAffiliate | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.ReportSummaryPerAffiliate.sql*
