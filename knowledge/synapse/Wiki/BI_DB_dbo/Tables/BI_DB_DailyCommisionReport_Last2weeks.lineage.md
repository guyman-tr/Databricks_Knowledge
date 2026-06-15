# BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks — Column Lineage

**Generated**: 2026-04-22 | **Writer SP**: SP_DailyCommisionReport | **Batch**: 21

## Summary

Rolling two-week customer×week-level aggregation of BI_DB_DailyCommisionReport. TRUNCATE+INSERT daily: the entire table is replaced with rows from the parent where DateID >= the Sunday two weeks before the run date. Grain: RealCID × Week (DATEPART(WEEK,FullDate)+YEAR(FullDate)*100) × InstrumentType × Regulation × Mifid × Club × Manager × Country × Region × UserName × customer flags. Metric columns are SUM() aggregations from the parent. 26 of 27 columns are populated; CommissionInRisk is a ghost column present in the DDL but absent from the SP INSERT list (always NULL). UC Target: Not Migrated to Unity Catalog.

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | RealCID | BI_DB_dbo.BI_DB_DailyCommisionReport | RealCID | GROUP BY pass-through — customer integer ID. Primary clustering key. | Tier 2 — SP_DailyCommisionReport |
| 2 | Club | BI_DB_dbo.BI_DB_DailyCommisionReport | Club | GROUP BY pass-through — customer club tier (Diamond, Platinum Plus, Platinum, Gold, Silver, Bronze, etc.). | Tier 2 — SP_DailyCommisionReport |
| 3 | Manager | BI_DB_dbo.BI_DB_DailyCommisionReport | Manager | GROUP BY pass-through — account manager name. | Tier 2 — SP_DailyCommisionReport |
| 4 | Country | BI_DB_dbo.BI_DB_DailyCommisionReport | Country | GROUP BY pass-through — customer country name. | Tier 2 — SP_DailyCommisionReport |
| 5 | Region | BI_DB_dbo.BI_DB_DailyCommisionReport | Region | GROUP BY pass-through — marketing region label. | Tier 2 — SP_DailyCommisionReport |
| 6 | Week | BI_DB_dbo.BI_DB_DailyCommisionReport | FullDate | DATEPART(WEEK, FullDate) + YEAR(FullDate) * 100 — composite week code (e.g., 202615 = week 15 of 2026). GROUP BY key. | Tier 2 — SP_DailyCommisionReport |
| 7 | UserName | BI_DB_dbo.BI_DB_DailyCommisionReport | UserName | GROUP BY pass-through — customer username string. | Tier 2 — SP_DailyCommisionReport |
| 8 | Commissions | BI_DB_dbo.BI_DB_DailyCommisionReport | Commissions | SUM(Commissions) — net eToro commission for the week within this customer×segment combination. | Tier 2 — SP_DailyCommisionReport |
| 9 | FullCommissions | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions | SUM(FullCommissions) — gross full commission for MIFID reporting. | Tier 2 — SP_DailyCommisionReport |
| 10 | CommissionInRisk | — | — | **Always NULL — ghost column.** Present in DDL but absent from the SP INSERT column list. SP does not write to this column. | Tier 4 — Legacy/Deprecated |
| 11 | weeknum | BI_DB_dbo.BI_DB_DailyCommisionReport | FullDate | DATEPART(WEEK, FullDate) — ISO week number within year (1-53). Redundant with Week but separated for convenience. | Tier 2 — SP_DailyCommisionReport |
| 12 | UpdateDate | — | — | GETDATE() at ETL execution time. | Tier 2 — SP_DailyCommisionReport |
| 13 | Regulation | BI_DB_dbo.BI_DB_DailyCommisionReport | Regulation | GROUP BY pass-through — regulatory jurisdiction label. | Tier 2 — SP_DailyCommisionReport |
| 14 | Mifid | BI_DB_dbo.BI_DB_DailyCommisionReport | Mifid | GROUP BY pass-through — MiFID classification label (e.g., 'MIFID', 'Non-MIFID'). | Tier 2 — SP_DailyCommisionReport |
| 15 | InstrumentType | BI_DB_dbo.BI_DB_DailyCommisionReport | InstrumentType | GROUP BY pass-through — instrument type name (Currencies, Stocks, Crypto Currencies, etc.). | Tier 2 — SP_DailyCommisionReport |
| 16 | IsValidCustomer | BI_DB_dbo.BI_DB_DailyCommisionReport | IsValidCustomer | GROUP BY pass-through — valid customer quality flag. | Tier 2 — SP_DailyCommisionReport |
| 17 | IsCreditReportValidCB | BI_DB_dbo.BI_DB_DailyCommisionReport | IsCreditReportValidCB | GROUP BY pass-through — Client_Balance validity flag. | Tier 2 — SP_DailyCommisionReport |
| 18 | IsDLTUser | BI_DB_dbo.BI_DB_DailyCommisionReport | IsDLTUser | GROUP BY pass-through — DLT user flag. | Tier 2 — SP_DailyCommisionReport |
| 19 | RollOverFee | BI_DB_dbo.BI_DB_DailyCommisionReport | RollOverFee | SUM(RollOverFee) — aggregated overnight rollover/carry fee for the week. | Tier 2 — SP_DailyCommisionReport |
| 20 | TicketFee | BI_DB_dbo.BI_DB_DailyCommisionReport | TicketFee | SUM(TicketFee) — aggregated per-ticket transaction fee for the week. | Tier 2 — SP_DailyCommisionReport |
| 21 | TicketFeeByPercent | BI_DB_dbo.BI_DB_DailyCommisionReport | TicketFeeByPercent | SUM(TicketFeeByPercent) — aggregated percentage-based ticket fee for the week. | Tier 2 — SP_DailyCommisionReport |
| 22 | AdminFee | BI_DB_dbo.BI_DB_DailyCommisionReport | AdminFee | SUM(AdminFee) — aggregated Islamic finance administration fee for the week. | Tier 2 — SP_DailyCommisionReport |
| 23 | SpotAdjustFee | BI_DB_dbo.BI_DB_DailyCommisionReport | SpotAdjustFee | SUM(SpotAdjustFee) — aggregated spot price adjustment fee for the week. | Tier 2 — SP_DailyCommisionReport |
| 24 | IsThisWeek | BI_DB_dbo.BI_DB_DailyCommisionReport | FullDate | CASE WHEN DATEPART(WEEK,FullDate)+YEAR(FullDate)*100 = DATEPART(WEEK,@Date)+YEAR(@Date)*100 THEN 1 ELSE 0 END — 1 if this is the current (in-progress) week, 0 if the prior complete week. **Stored as [money] type despite being a 0/1 flag.** | Tier 2 — SP_DailyCommisionReport |
| 25 | InvestedAmountOpen | BI_DB_dbo.BI_DB_DailyCommisionReport | InvestedAmountOpen | SUM(InvestedAmountOpen) — aggregated USD invested amount on positions opened within the 2-week window. | Tier 2 — SP_DailyCommisionReport |
| 26 | CountUU | BI_DB_dbo.BI_DB_DailyCommisionReport | CountUU | SUM(CountUU) — sum of unique-user count values from parent rows for the week. | Tier 2 — SP_DailyCommisionReport |
| 27 | IsMarginTrade | BI_DB_dbo.BI_DB_DailyCommisionReport | IsMarginTrade | GROUP BY pass-through — 1=margin-funded position (SettlementTypeID=5). Added 2025-10-23. | Tier 2 — SP_DailyCommisionReport |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_DailyCommisionReport (rolling 2-week window)
  — customer×instrument×position grain — source for last ~14 days of dates
  |
  | SP_DailyCommisionReport @Date (same execution, runs after Instrument_Agg)
  |   TRUNCATE TABLE BI_DB_DailyCommisionReport_Last2weeks
  |   INSERT INTO BI_DB_DailyCommisionReport_Last2weeks (26 columns — CommissionInRisk excluded)
  |     SELECT ... SUM(commissions/fees) GROUP BY RealCID × Week × InstrumentType × ...
  |     FROM BI_DB_dbo.BI_DB_DailyCommisionReport WITH (NOLOCK)
  |     WHERE DateID >= [Sunday 2 weeks before @Date]
  v
BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks
  (~861K rows | 2 weeks: 202615-202616 | ~521K CIDs | CLUSTERED INDEX RealCID | ROUND_ROBIN)
  |
  |-- NOT migrated to Unity Catalog ---|
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — |
| Tier 2 | 26 | RealCID, Club, Manager, Country, Region, Week, UserName, Commissions, FullCommissions, weeknum, UpdateDate, Regulation, Mifid, InstrumentType, IsValidCustomer, IsCreditReportValidCB, IsDLTUser, RollOverFee, TicketFee, TicketFeeByPercent, AdminFee, SpotAdjustFee, IsThisWeek, InvestedAmountOpen, CountUU, IsMarginTrade |
| Tier 3 | 0 | — |
| Tier 4 | 1 | CommissionInRisk |
