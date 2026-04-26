# Column Lineage — BI_DB_dbo.BI_DB_DailyCommisionReport_Yesterday

**Generated**: 2026-04-22 | **Batch**: 22 | **Writer SP**: SP_DailyCommisionReport

## Source Chain

```
eToro production DBs (Trade, BackOffice, etc.)
  → DWH dimensions + revenue TVFs
    → BI_DB_dbo.BI_DB_DailyCommisionReport (parent, Batch 20)
      → WHERE DateID = @DateID (single-day filter)
      → GROUP BY (FullDate × customer dims × InstrumentType)
        → BI_DB_dbo.BI_DB_DailyCommisionReport_Yesterday (this table)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | RealCID | BI_DB_DailyCommisionReport | RealCID | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 2 | Club | BI_DB_DailyCommisionReport | Club | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 3 | Manager | BI_DB_DailyCommisionReport | Manager | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 4 | Country | BI_DB_DailyCommisionReport | Country | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 5 | Region | BI_DB_DailyCommisionReport | Region | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 6 | FullDate | BI_DB_DailyCommisionReport | FullDate | GROUP BY passthrough (single day = @Date) | Tier 2 — SP_DailyCommisionReport |
| 7 | UserName | BI_DB_DailyCommisionReport | UserName | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 8 | Commissions | BI_DB_DailyCommisionReport | Commissions | SUM(ISNULL(Commissions,0)) | Tier 2 — SP_DailyCommisionReport |
| 9 | FullCommissions | BI_DB_DailyCommisionReport | FullCommissions | SUM(ISNULL(FullCommissions,0)) | Tier 2 — SP_DailyCommisionReport |
| 10 | CommissionInRisk | — | — | GHOST COLUMN — in DDL but NOT in SP INSERT list; always NULL | Tier 4 — Legacy/Ghost |
| 11 | UpdateDate | ETL runtime | — | GETDATE() | Tier 2 — SP_DailyCommisionReport |
| 12 | Regulation | BI_DB_DailyCommisionReport | Regulation | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 13 | Mifid | BI_DB_DailyCommisionReport | Mifid | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 14 | InstrumentType | BI_DB_DailyCommisionReport | InstrumentType | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 15 | IsValidCustomer | BI_DB_DailyCommisionReport | IsValidCustomer | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 16 | IsCreditReportValidCB | BI_DB_DailyCommisionReport | IsCreditReportValidCB | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 17 | IsDLTUser | BI_DB_DailyCommisionReport | IsDLTUser | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 18 | RollOverFee | BI_DB_DailyCommisionReport | RollOverFee | SUM(ISNULL(RollOverFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 19 | TicketFee | BI_DB_DailyCommisionReport | TicketFee | SUM(ISNULL(TicketFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 20 | TicketFeeByPercent | BI_DB_DailyCommisionReport | TicketFeeByPercent | SUM(ISNULL(TicketFeeByPercent,0)) | Tier 2 — SP_DailyCommisionReport |
| 21 | AdminFee | BI_DB_DailyCommisionReport | AdminFee | SUM(ISNULL(AdminFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 22 | SpotAdjustFee | BI_DB_DailyCommisionReport | SpotAdjustFee | SUM(ISNULL(SpotAdjustFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 23 | InvestedAmountOpen | BI_DB_DailyCommisionReport | InvestedAmountOpen | SUM(InvestedAmountOpen) | Tier 2 — SP_DailyCommisionReport |
| 24 | CountUU | BI_DB_DailyCommisionReport | CountUU | SUM(CountUU) | Tier 2 — SP_DailyCommisionReport |
| 25 | IsMarginTrade | BI_DB_DailyCommisionReport | IsMarginTrade | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 26 | (CommissionInRisk) | — | — | See row 10 — always NULL | Tier 4 — Legacy/Ghost |

## UC External Lineage

UC Target: `_Not_Migrated` — no Unity Catalog target. No ALTER scripts generated.

## Notes

- CommissionInRisk: Present in DDL but NOT in the SP INSERT column list (lines 1265–1289). Always NULL. Ghost column pattern consistent with DailyCommisionReport_Last2weeks and DailyCommisionReport_LastYear.
- FullDate is a date column (not DateID integer) — exactly one value per run = @DatePrev (yesterday's date)
- VolumeOnOpen, VolumeOnClose, RollOverFee_SDRT, TradingFees absent from this satellite (present only in MonthlyData)
