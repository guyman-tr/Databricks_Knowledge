# Column Lineage: BI_DB_dbo.BI_DB_RollOverFee_ByInstrument

**Generated**: 2026-04-22
**Writer SP**: `BI_DB_dbo.SP_DailyCommisionReport`
**ETL Pattern**: DELETE WHERE DateID=@DateID + INSERT (daily incremental GROUP BY aggregation)
**Immediate Source**: `BI_DB_dbo.BI_DB_DailyCommisionReport`
**Root Sources**: `DWH_dbo.Fact_CustomerAction`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Position`, `DWH_dbo.Fact_SnapshotCustomer` (via BI_DB_DailyCommisionReport → revenue TVFs)

## ETL Pipeline

```
DWH_dbo.Fact_CustomerAction + Dim_Instrument + Dim_Position
  |-- Revenue TVFs (Function_Revenue_*) --|
  v
BI_DB_dbo.BI_DB_DailyCommisionReport
  (~179K rows/date — position-grain revenue)
  |-- SP_DailyCommisionReport GROUP BY Instrument×Regulation×ValidCustomer --|
  v
BI_DB_dbo.BI_DB_RollOverFee_ByInstrument
  (~7K rows/date — by-instrument aggregate fee summary)
  |-- (UC: Not Migrated) --|
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | FullDate | BI_DB_DailyCommisionReport | FullDate | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 2 | DateID | BI_DB_DailyCommisionReport | DateID | GROUP BY passthrough | Tier 2 — SP_DailyCommisionReport |
| 3 | InstrumentType | BI_DB_DailyCommisionReport | InstrumentType | GROUP BY passthrough (from Dim_Instrument) | Tier 2 — SP_DailyCommisionReport |
| 4 | Instrument | BI_DB_DailyCommisionReport | Instrument | GROUP BY passthrough (from Dim_Instrument.Name) | Tier 2 — SP_DailyCommisionReport |
| 5 | RollOverFee | BI_DB_DailyCommisionReport | RollOverFee | SUM(RollOverFee) — overnight/Islamic fee aggregate | Tier 2 — SP_DailyCommisionReport |
| 6 | UpdateDate | ETL runtime | GETDATE() | ETL execution timestamp | Tier 2 — SP_DailyCommisionReport |
| 7 | FullCommissions | BI_DB_DailyCommisionReport | FullCommissions | SUM(ISNULL(FullCommissions,0)) — gross commission aggregate | Tier 2 — SP_DailyCommisionReport |
| 8 | Commissions | BI_DB_DailyCommisionReport | Commissions | SUM(ISNULL(Commissions,0)) — net commission aggregate | Tier 2 — SP_DailyCommisionReport |
| 9 | IsValidCustomer | BI_DB_DailyCommisionReport | IsValidCustomer | GROUP BY passthrough (from Fact_SnapshotCustomer) | Tier 2 — SP_DailyCommisionReport |
| 10 | IsCreditReportValidCB | BI_DB_DailyCommisionReport | IsCreditReportValidCB | GROUP BY passthrough (from Fact_SnapshotCustomer) | Tier 2 — SP_DailyCommisionReport |
| 11 | Regulation | BI_DB_DailyCommisionReport | Regulation | GROUP BY passthrough (ToRegulation) | Tier 2 — SP_DailyCommisionReport |
| 12 | RollOverFee_SDRT | BI_DB_DailyCommisionReport | RollOverFee_SDRT | SUM(RollOverFee_SDRT) — UK SDRT component of rollover; added 2023-10-31 | Tier 2 — SP_DailyCommisionReport |
| 13 | TradingFees | BI_DB_DailyCommisionReport | TradingFees | SUM(TradingFees) — combined TicketFee+AdminFee; added 2024-02-25 | Tier 2 — SP_DailyCommisionReport |
| 14 | IsDLTUser | BI_DB_DailyCommisionReport | IsDLTUser | GROUP BY passthrough (DLT user flag); added 2024-07-30 | Tier 2 — SP_DailyCommisionReport |
| 15 | TicketFee | BI_DB_DailyCommisionReport | TicketFee | SUM(ISNULL(TicketFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 16 | TicketFeeByPercent | BI_DB_DailyCommisionReport | TicketFeeByPercent | SUM(ISNULL(TicketFeeByPercent,0)) — crypto ticket fee (percentage-based) | Tier 2 — SP_DailyCommisionReport |
| 17 | AdminFee | BI_DB_DailyCommisionReport | AdminFee | SUM(ISNULL(AdminFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 18 | SpotAdjustFee | BI_DB_DailyCommisionReport | SpotAdjustFee | SUM(ISNULL(SpotAdjustFee,0)) | Tier 2 — SP_DailyCommisionReport |
| 19 | IsMarginTrade | BI_DB_DailyCommisionReport | IsMarginTrade | GROUP BY passthrough (SettlementTypeID=5); added 2025-10-23 | Tier 2 — SP_DailyCommisionReport |
