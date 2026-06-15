# BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear — Column Lineage

**Generated**: 2026-04-22 | **Writer SP**: SP_DailyCommisionReport | **Batch**: 21

## Summary

Annual customer-level aggregation of BI_DB_DailyCommisionReport for the prior complete calendar year. TRUNCATE+INSERT daily: the entire table is replaced with rows from the parent where `DATEDIFF(YEAR, FullDate, DATEADD(DAY, -1, GETDATE())) = 1` (i.e., FullDate falls in last year). Grain: RealCID × Year × Region × Manager × UserName × InstrumentType × Regulation × Mifid × customer flags (IsValidCustomer, IsCreditReportValidCB, IsDLTUser, IsMarginTrade). No Club, Country, Label, or week dimensions — narrower than Last2weeks. Metric columns are SUM() aggregations. 22 of 23 columns are populated; CommissionInRisk is a ghost column (DDL only, never inserted). UC Target: Not Migrated to Unity Catalog.

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | RealCID | BI_DB_dbo.BI_DB_DailyCommisionReport | RealCID | GROUP BY pass-through — customer integer ID. Primary clustering key. | Tier 2 — SP_DailyCommisionReport |
| 2 | Manager | BI_DB_dbo.BI_DB_DailyCommisionReport | Manager | GROUP BY pass-through — account manager name. | Tier 2 — SP_DailyCommisionReport |
| 3 | Region | BI_DB_dbo.BI_DB_DailyCommisionReport | Region | GROUP BY pass-through — marketing region label. | Tier 2 — SP_DailyCommisionReport |
| 4 | Year | BI_DB_dbo.BI_DB_DailyCommisionReport | FullDate | YEAR(FullDate) — calendar year of the trading date. GROUP BY key. As of 2026-04-22 this always equals 2025 (last year). | Tier 2 — SP_DailyCommisionReport |
| 5 | UserName | BI_DB_dbo.BI_DB_DailyCommisionReport | UserName | GROUP BY pass-through — customer username string. | Tier 2 — SP_DailyCommisionReport |
| 6 | Commissions | BI_DB_dbo.BI_DB_DailyCommisionReport | Commissions | SUM(Commissions) — net eToro commission for the year within this customer×segment combination. | Tier 2 — SP_DailyCommisionReport |
| 7 | FullCommissions | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions | SUM(FullCommissions) — gross full commission for MIFID reporting for the year. | Tier 2 — SP_DailyCommisionReport |
| 8 | CommissionInRisk | — | — | **Always NULL — ghost column.** Present in DDL but absent from the SP INSERT column list. SP does not write to this column. | Tier 4 — Legacy/Deprecated |
| 9 | UpdateDate | — | — | GETDATE() at ETL execution time. | Tier 2 — SP_DailyCommisionReport |
| 10 | Regulation | BI_DB_dbo.BI_DB_DailyCommisionReport | Regulation | GROUP BY pass-through — regulatory jurisdiction label. | Tier 2 — SP_DailyCommisionReport |
| 11 | Mifid | BI_DB_dbo.BI_DB_DailyCommisionReport | Mifid | GROUP BY pass-through — MiFID classification label. | Tier 2 — SP_DailyCommisionReport |
| 12 | InstrumentType | BI_DB_dbo.BI_DB_DailyCommisionReport | InstrumentType | GROUP BY pass-through — instrument type label (Currencies, Stocks, Crypto Currencies, etc.). | Tier 2 — SP_DailyCommisionReport |
| 13 | IsValidCustomer | BI_DB_dbo.BI_DB_DailyCommisionReport | IsValidCustomer | GROUP BY pass-through — valid customer quality flag. | Tier 2 — SP_DailyCommisionReport |
| 14 | IsCreditReportValidCB | BI_DB_dbo.BI_DB_DailyCommisionReport | IsCreditReportValidCB | GROUP BY pass-through — Client_Balance validity flag. | Tier 2 — SP_DailyCommisionReport |
| 15 | IsDLTUser | BI_DB_dbo.BI_DB_DailyCommisionReport | IsDLTUser | GROUP BY pass-through — DLT user flag. | Tier 2 — SP_DailyCommisionReport |
| 16 | RollOverFee | BI_DB_dbo.BI_DB_DailyCommisionReport | RollOverFee | SUM(RollOverFee) — aggregated overnight rollover/carry fee for the year. | Tier 2 — SP_DailyCommisionReport |
| 17 | TicketFee | BI_DB_dbo.BI_DB_DailyCommisionReport | TicketFee | SUM(TicketFee) — aggregated per-ticket transaction fee for the year. | Tier 2 — SP_DailyCommisionReport |
| 18 | TicketFeeByPercent | BI_DB_dbo.BI_DB_DailyCommisionReport | TicketFeeByPercent | SUM(TicketFeeByPercent) — aggregated percentage-based ticket fee for the year. | Tier 2 — SP_DailyCommisionReport |
| 19 | AdminFee | BI_DB_dbo.BI_DB_DailyCommisionReport | AdminFee | SUM(AdminFee) — aggregated Islamic finance/administration fee for the year. | Tier 2 — SP_DailyCommisionReport |
| 20 | SpotAdjustFee | BI_DB_dbo.BI_DB_DailyCommisionReport | SpotAdjustFee | SUM(SpotAdjustFee) — aggregated spot price adjustment fee for the year. | Tier 2 — SP_DailyCommisionReport |
| 21 | InvestedAmountOpen | BI_DB_dbo.BI_DB_DailyCommisionReport | InvestedAmountOpen | SUM(InvestedAmountOpen) — aggregated USD invested amount for positions opened within last year. | Tier 2 — SP_DailyCommisionReport |
| 22 | CountUU | BI_DB_dbo.BI_DB_DailyCommisionReport | CountUU | SUM(CountUU) — sum of unique-user count values from parent rows for the year. | Tier 2 — SP_DailyCommisionReport |
| 23 | IsMarginTrade | BI_DB_dbo.BI_DB_DailyCommisionReport | IsMarginTrade | GROUP BY pass-through — 1=margin-funded position (SettlementTypeID=5). Added 2025-10-23. | Tier 2 — SP_DailyCommisionReport |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_DailyCommisionReport (last calendar year)
  — customer×instrument×position grain — dates where YEAR(FullDate) = YEAR(yesterday)-0 = last year
  |
  | SP_DailyCommisionReport @Date (same execution, runs after Last2weeks insert)
  |   TRUNCATE TABLE BI_DB_DailyCommisionReport_LastYear
  |   INSERT INTO BI_DB_DailyCommisionReport_LastYear (22 columns — CommissionInRisk excluded)
  |     SELECT ... SUM(Commissions/FullCommissions/fees)
  |     FROM BI_DB_dbo.BI_DB_DailyCommisionReport WITH (NOLOCK)
  |     WHERE DATEDIFF(YEAR, FullDate, DATEADD(DAY, -1, GETDATE())) = 1
  |     GROUP BY RealCID, YEAR(FullDate), UserName, Region, Manager,
  |              Regulation, Mifid, InstrumentType,
  |              IsValidCustomer, IsCreditReportValidCB, IsDLTUser, IsMarginTrade
  v
BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear
  (~6.48M rows | Year=2025 | ~2.19M CIDs | CLUSTERED INDEX RealCID | ROUND_ROBIN)
  |
  |-- NOT migrated to Unity Catalog ---|
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — |
| Tier 2 | 22 | RealCID, Manager, Region, Year, UserName, Commissions, FullCommissions, UpdateDate, Regulation, Mifid, InstrumentType, IsValidCustomer, IsCreditReportValidCB, IsDLTUser, RollOverFee, TicketFee, TicketFeeByPercent, AdminFee, SpotAdjustFee, InvestedAmountOpen, CountUU, IsMarginTrade |
| Tier 3 | 0 | — |
| Tier 4 | 1 | CommissionInRisk |
