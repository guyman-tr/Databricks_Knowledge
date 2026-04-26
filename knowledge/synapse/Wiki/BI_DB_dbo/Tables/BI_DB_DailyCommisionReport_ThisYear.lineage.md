# Column Lineage — BI_DB_dbo.BI_DB_DailyCommisionReport_ThisYear

**Generated**: 2026-04-22 | **Batch**: 22 | **Writer SP**: SP_DailyCommisionReport

## Source Chain

```
eToro production DBs (Trade, BackOffice, etc.)
  → DWH dimensions + revenue TVFs
    → BI_DB_dbo.BI_DB_DailyCommisionReport (parent, Batch 20)
      → WHERE DATEDIFF(YEAR, FullDate, DATEADD(DAY,-1,GETDATE())) = 0
      → GROUP BY (Year × customer dims × InstrumentType)
        → BI_DB_dbo.BI_DB_DailyCommisionReport_ThisYear (this table)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | RealCID | BI_DB_DailyCommisionReport | RealCID | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 2 | Manager | BI_DB_DailyCommisionReport | Manager | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 3 | Region | BI_DB_DailyCommisionReport | Region | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 4 | Year | BI_DB_DailyCommisionReport | FullDate | YEAR(FullDate) | Tier 2 — SP_DailyCommisionReport |
| 5 | UserName | BI_DB_DailyCommisionReport | UserName | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 6 | Commissions | BI_DB_DailyCommisionReport | Commissions | SUM(ISNULL(Commissions,0)) | Tier 2 — SP_DailyCommisionReport |
| 7 | FullCommissions | BI_DB_DailyCommisionReport | FullCommissions | SUM(ISNULL(FullCommissions,0)) | Tier 2 — SP_DailyCommisionReport |
| 8 | CommissionInRisk | — | — | GHOST COLUMN — DDL only, NOT in SP INSERT; always NULL | Tier 4 — Legacy/Ghost |
| 9 | UpdateDate | ETL runtime | — | GETDATE() | Tier 2 — SP_DailyCommisionReport |
| 10 | Regulation | BI_DB_DailyCommisionReport | Regulation | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 11 | Mifid | BI_DB_DailyCommisionReport | Mifid | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 12 | InstrumentType | BI_DB_DailyCommisionReport | InstrumentType | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 13 | IsValidCustomer | BI_DB_DailyCommisionReport | IsValidCustomer | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 14 | IsCreditReportValidCB | BI_DB_DailyCommisionReport | IsCreditReportValidCB | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 15 | IsDLTUser | BI_DB_DailyCommisionReport | IsDLTUser | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 16 | RollOverFee | BI_DB_DailyCommisionReport | RollOverFee | SUM(ISNULL(RollOverFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 17 | TicketFee | BI_DB_DailyCommisionReport | TicketFee | SUM(ISNULL(TicketFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 18 | TicketFeeByPercent | BI_DB_DailyCommisionReport | TicketFeeByPercent | SUM(ISNULL(TicketFeeByPercent,0)) | Tier 2 — SP_DailyCommisionReport |
| 19 | AdminFee | BI_DB_DailyCommisionReport | AdminFee | SUM(ISNULL(AdminFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 20 | SpotAdjustFee | BI_DB_DailyCommisionReport | SpotAdjustFee | SUM(ISNULL(SpotAdjustFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 21 | InvestedAmountOpen | BI_DB_DailyCommisionReport | InvestedAmountOpen | SUM(InvestedAmountOpen) | Tier 2 — SP_DailyCommisionReport |
| 22 | CountUU | BI_DB_DailyCommisionReport | CountUU | SUM(CountUU) | Tier 2 — SP_DailyCommisionReport |
| 23 | IsMarginTrade | BI_DB_DailyCommisionReport | IsMarginTrade | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |

## UC External Lineage

UC Target: `_Not_Migrated` — no Unity Catalog target. No ALTER scripts generated.

## Notes

- CommissionInRisk: Present in DDL (col 8) but NOT in SP INSERT column list (lines 1504–1527). Always NULL. Ghost column consistent with Yesterday, ThisMonth, Last2weeks, LastYear siblings.
- Year derived: `YEAR(FullDate)` integer — single value per run = current calendar year (e.g., 2026).
- Year filter: `DATEDIFF(YEAR, FullDate, DATEADD(DAY,-1,GETDATE())) = 0` — includes all dates from Jan 1 through yesterday of the current calendar year.
- @Dateyear edge case: if `DAY(GETDATE())=1 AND MONTH(GETDATE())=1` (Jan 1), then @Dateyear = first day of prior year. Prevents empty-table state on Jan 1.
- RealCID is `bigint` (DDL line 3) — unlike all other DailyCommisionReport satellites which use `int`. Type mismatch noted.
- No Club column (present in Yesterday, ThisMonth). No Country column (present in Yesterday, ThisMonth). Year-level aggregation coarser than month-level; club/country dimensions dropped.
- No FullDate column (Yesterday-only). No Month column (ThisMonth-only). No weeknum column (MonthlyData-only).
