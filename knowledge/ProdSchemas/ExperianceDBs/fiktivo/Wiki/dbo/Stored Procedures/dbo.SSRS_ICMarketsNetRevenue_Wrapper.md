# dbo.SSRS_ICMarketsNetRevenue_Wrapper

## 1. Overview

A thin wrapper around `dbo.SSRS_ICMarketsNetRevenue` that provides default date range logic when no dates are supplied. Defaults `@EndDate` to the first day of the current month and `@StartDate` to the first day of the previous month, enabling the SSRS report to run without manually specifying the period each time.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | (delegates to SSRS_ICMarketsNetRevenue) |
| Secondary Tables | (delegates to SSRS_ICMarketsNetRevenue) |
| Operation | EXEC (wrapper) |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

Returns the same result set as `dbo.SSRS_ICMarketsNetRevenue`: one row per calendar day with `NetRev` and `Date` columns.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @StartDate | IN | date | NULL | Start of the reporting period. Defaults to the first day of the previous month if NULL. |
| @EndDate | IN | date | NULL | End of the reporting period (exclusive). Defaults to the first day of the current month if NULL. |

## 5. Business Logic

1. If `@EndDate` is NULL, computes the first day of the current month using `DATEADD(mm, DATEDIFF(mm, '20000101', GETDATE()), '20000101')`.
2. If `@StartDate` is NULL, computes one month before `@EndDate` using `DATEADD(mm, -1, @EndDate)`.
3. Delegates execution to `EXEC SSRS_ICMarketsNetRevenue @StartDate, @EndDate` with the resolved values.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.SSRS_ICMarketsNetRevenue | Stored Procedure | dbo | Core reporting procedure being wrapped |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- No additional overhead beyond two date calculations and a single EXEC call.
- The SSRS report can call this wrapper without parameters to always report on the previous calendar month.

## 8. Usage Examples

```sql
-- Run for previous month (default)
EXEC dbo.SSRS_ICMarketsNetRevenue_Wrapper;

-- Run for a specific period
EXEC dbo.SSRS_ICMarketsNetRevenue_Wrapper
    @StartDate = '2024-04-01',
    @EndDate   = '2024-05-01';
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Unknown | Unknown | N/A | Initial creation |

---
*Object: dbo.SSRS_ICMarketsNetRevenue_Wrapper | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.SSRS_ICMarketsNetRevenue_Wrapper.sql*
