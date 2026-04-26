# Lineage: BI_DB_dbo.BI_CLData_AllTimeData_Optimove

**Generated**: 2026-04-23
**Schema**: BI_DB_dbo
**Object**: BI_CLData_AllTimeData_Optimove
**Object Type**: Table — Optimove marketing feed (Credit Line all-time data)
**Writer SP**: None identified (no writer SP in SSDT BI_DB_dbo; not registered in OpsDB)
**Production Source**: Unknown — no Generic Pipeline mapping, no External Table, no SSDT SP
**Related Table**: BI_DB_dbo.BI_DB_CreditLineData_Optimove (similar schema, also empty)

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | RealCID | Unknown (likely etoro production — Customer.RealCID) | RealCID | Passthrough | Tier 3 |
| 2 | DateReceive | Unknown | DateReceive | Passthrough | Tier 3 |
| 3 | EndOfMonthOFDateReceive | Unknown | Computed | EOMONTH(DateReceive) or equivalent | Tier 3 |
| 4 | Rounds | Unknown | Unknown | Unknown — date type for Rounds is atypical | Tier 4 |
| 5 | MonthYear | Unknown | Computed | Formatted month-year string from DateReceive | Tier 3 |
| 6 | MONTH | Unknown | Computed | MONTH(DateReceive) or equivalent | Tier 3 |
| 7 | Year | Unknown | Computed | YEAR(DateReceive) or equivalent | Tier 3 |
| 8 | PostiveTotalCLAmount | Unknown | PostiveTotalCLAmount | Running positive CL total (typo: "Positve") | Tier 3 |
| 9 | DailySum | Unknown | Computed | Daily credit line amount for this date | Tier 3 |
| 10 | TotalCLEver | Unknown | TotalCLEver | Cumulative all-time credit line received | Tier 3 |
| 11 | UpdateDate | Unknown | Unknown | ETL metadata timestamp | Tier 5 |

## ETL Pipeline

```
Unknown source (Credit Line data from etoro production — ActionTypeID=9, BonusTypeID=71)
  |-- Unknown feed mechanism (no Generic Pipeline, no External Table, no SSDT SP) --|
  v
BI_DB_dbo.BI_CLData_AllTimeData_Optimove (0 rows — empty as of 2026-04-23)
  |-- Was presumably exported to Optimove API for campaign segmentation --|
  v
Optimove Marketing Platform (external CRM/marketing tool)

Companion table (same domain, also empty):
  BI_DB_dbo.BI_DB_CreditLineData_Optimove (per-period CL data, no MonthYear/MONTH/Year/DailySum)

Domain context: Credit Line (CL) = eToro bonus credit lines
  Tracked via: SP_Daily_CreditLine → BI_DB_dbo.BI_DB_Daily_CreditLine
  Source actions: DWH_dbo.Fact_CustomerAction WHERE ActionTypeID=9 AND BonusTypeID=71
```

## Notes

- Table is currently empty (0 rows as of 2026-04-23)
- No writer SP in SSDT BI_DB_dbo; not registered in OpsDB
- Related table `BI_DB_CreditLineData_Optimove` also empty — pattern suggests Optimove CL feed discontinued
- `Rounds` column typed as `date` — unusual for a campaign round concept; purpose unclear
- Column name typo: `PostiveTotalCLAmount` (missing 'i' in "Positive") — inherited from upstream source
- `AllTimeData` suffix distinguishes from per-period `BI_DB_CreditLineData_Optimove`
