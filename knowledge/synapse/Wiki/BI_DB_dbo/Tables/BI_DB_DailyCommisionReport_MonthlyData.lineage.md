# Column Lineage — BI_DB_dbo.BI_DB_DailyCommisionReport_MonthlyData

**Generated**: 2026-04-22 | **Batch**: 22 | **Writer SP**: SP_DailyCommisionReport

## Source Chain

```
eToro production DBs (Trade, BackOffice, etc.)
  → DWH dimensions + revenue TVFs
    → BI_DB_dbo.BI_DB_DailyCommisionReport (parent, Batch 20)
      → GROUP BY (Month × weeknum × customer dims × InstrumentType)
        → BI_DB_dbo.BI_DB_DailyCommisionReport_MonthlyData (this table)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | RealCID | BI_DB_DailyCommisionReport | RealCID | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 2 | Club | BI_DB_DailyCommisionReport | Club | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 3 | Manager | BI_DB_DailyCommisionReport | Manager | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 4 | Country | BI_DB_DailyCommisionReport | Country | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 5 | Region | BI_DB_DailyCommisionReport | Region | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 6 | Month | BI_DB_DailyCommisionReport | FullDate | MONTH(FullDate) + YEAR(FullDate)*100 | Tier 2 — SP_DailyCommisionReport |
| 7 | UserName | BI_DB_DailyCommisionReport | UserName | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 8 | Commissions | BI_DB_DailyCommisionReport | Commissions | SUM(ISNULL(Commissions,0)) | Tier 2 — SP_DailyCommisionReport |
| 9 | FullCommissions | BI_DB_DailyCommisionReport | FullCommissions | SUM(ISNULL(FullCommissions,0)) | Tier 2 — SP_DailyCommisionReport |
| 10 | weeknum | BI_DB_DailyCommisionReport | FullDate | DATEPART(WEEK, FullDate) | Tier 2 — SP_DailyCommisionReport |
| 11 | UpdateDate | ETL runtime | — | GETDATE() | Tier 2 — SP_DailyCommisionReport |
| 12 | Regulation | BI_DB_DailyCommisionReport | Regulation | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 13 | Mifid | BI_DB_DailyCommisionReport | Mifid | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 14 | VolumeOnOpen | BI_DB_DailyCommisionReport | VolumeOnOpen | SUM(ISNULL(VolumeOnOpen,0)) | Tier 2 — SP_DailyCommisionReport |
| 15 | VolumeOnClose | BI_DB_DailyCommisionReport | VolumeOnClose | SUM(ISNULL(VolumeOnClose,0)) | Tier 2 — SP_DailyCommisionReport |
| 16 | RollOverFee | BI_DB_DailyCommisionReport | RollOverFee | SUM(ISNULL(RollOverFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 17 | InstrumentType | BI_DB_DailyCommisionReport | InstrumentType | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 18 | IsValidCustomer | BI_DB_DailyCommisionReport | IsValidCustomer | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 19 | IsCreditReportValidCB | BI_DB_DailyCommisionReport | IsCreditReportValidCB | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 20 | RollOverFee_SDRT | BI_DB_DailyCommisionReport | RollOverFee_SDRT | SUM(ISNULL(RollOverFee_SDRT,0)) | Tier 2 — SP_DailyCommisionReport |
| 21 | TradingFees | BI_DB_DailyCommisionReport | TradingFees | SUM(ISNULL(TradingFees,0)) | Tier 2 — SP_DailyCommisionReport |
| 22 | IsDLTUser | BI_DB_DailyCommisionReport | IsDLTUser | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 23 | TicketFee | BI_DB_DailyCommisionReport | TicketFee | SUM(ISNULL(TicketFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 24 | TicketFeeByPercent | BI_DB_DailyCommisionReport | TicketFeeByPercent | SUM(ISNULL(TicketFeeByPercent,0)) | Tier 2 — SP_DailyCommisionReport |
| 25 | AdminFee | BI_DB_DailyCommisionReport | AdminFee | SUM(ISNULL(AdminFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 26 | SpotAdjustFee | BI_DB_DailyCommisionReport | SpotAdjustFee | SUM(ISNULL(SpotAdjustFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 27 | InvestedAmountOpen | BI_DB_DailyCommisionReport | InvestedAmountOpen | SUM(InvestedAmountOpen) | Tier 2 — SP_DailyCommisionReport |
| 28 | CountUU | BI_DB_DailyCommisionReport | CountUU | SUM(CountUU) | Tier 2 — SP_DailyCommisionReport |
| 29 | IsMarginTrade | BI_DB_DailyCommisionReport | IsMarginTrade | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |

## UC External Lineage

UC Target: `_Not_Migrated` — no Unity Catalog target. No ALTER scripts generated.

## Notes

- All columns Tier 2 — derived from intermediate BI_DB_DailyCommisionReport (itself Tier 2)
- No production DB_Schema upstream wiki applicable (source is BI_DB layer, not production OLTP)
- CommissionInRisk: NOT in this table's DDL or SP INSERT (absent entirely; contrast with ThisMonth/ThisYear/Yesterday where it is a ghost column)
- weeknum unique to MonthlyData among satellites — provides sub-monthly week granularity
- VolumeOnOpen, VolumeOnClose, RollOverFee_SDRT, TradingFees unique to MonthlyData among satellites
