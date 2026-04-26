# Column Lineage: BI_DB_dbo.BI_DB_Subsidieries_Realized_Commissions_Adjustments

**Generated**: 2026-04-22
**Writer SP**: `BI_DB_dbo.SP_M_Subsidieries_Realized_Commissions_Adjustments`
**ETL Pattern**: DELETE WHERE EOMonth=@Date + INSERT (monthly idempotent re-run)
**Immediate Source**: `DWH_dbo.Dim_Position` (commissions), `DWH_dbo.Fact_SnapshotCustomer` (credit/regulation), `DWH_dbo.Dim_Regulation` (regulation names), `DWH_dbo.Dim_Instrument` (instrument type)
**Root Sources**: `etoro_Trade_OpenPositionEndOfDay` (via Dim_Position), `etoro_History_BackOfficeCustomer` (via Fact_SnapshotCustomer), `Dictionary.Regulation` (via Dim_Regulation)

## ETL Pipeline

```
DWH_dbo.Dim_Position (dp)
  + DWH_dbo.Fact_SnapshotCustomer (fsc — close date snapshot)
  + DWH_dbo.Fact_SnapshotCustomer (fsc1 — open date snapshot)
  + DWH_dbo.Dim_Range (dr, dr1 — SCD2 range resolution)
  + DWH_dbo.Dim_Instrument (di — InstrumentType)
  |-- #relPos2: filter CloseDateID IN @sdate..@edateID + IsCreditReportValidCB = 1 (either snapshot) --|
  v
  #relPos2 (position-grain: per PositionID)
  + DWH_dbo.Dim_Regulation (dr — resolve RegulationIDOnOpen to Name)
  + DWH_dbo.Dim_Regulation (dr1 — resolve Fact_SnapshotCustomer.RegulationID to Name)
  |-- #summary: GROUP BY Regulation × Credit × Period × InstrumentType × IsSettled --|
  v
  #summary (aggregate-grain)
  |-- SP: DELETE WHERE EOMonth=@Date + INSERT --|
  v
BI_DB_dbo.BI_DB_Subsidieries_Realized_Commissions_Adjustments
  (~424 rows/month — monthly commission aggregate by subsidiary regulation)
  |-- (UC: Not Migrated) --|
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Year | ETL runtime | @sdate | YEAR(DATEADD(month, DATEDIFF(month,0,@Date), 0)) — first day of month year | Tier 2 — SP_M_Subsidieries_Realized_Commissions_Adjustments |
| 2 | YearMonth | ETL runtime | @sdate | CONVERT(VARCHAR(6), @sdate, 112) — YYYYMM format | Tier 2 — SP_M_Subsidieries_Realized_Commissions_Adjustments |
| 3 | EOMonth | ETL runtime | @Date | EOMONTH(@Date) — last day of month; used as partition/delete key | Tier 2 — SP_M_Subsidieries_Realized_Commissions_Adjustments |
| 4 | CreditValidClose | Fact_SnapshotCustomer | IsCreditReportValidCB | CASE: 1→'CreditValidClose', 0→'CreditInvalidClose'; customer credit status at close-date snapshot | Tier 2 — SP_M_Subsidieries_Realized_Commissions_Adjustments |
| 5 | CreditValidOpen | Fact_SnapshotCustomer | IsCreditReportValidCB | CASE: 1→'CreditValidOpen', 0→'CreditInvalidOpen'; customer credit status at open-date snapshot | Tier 2 — SP_M_Subsidieries_Realized_Commissions_Adjustments |
| 6 | RegulationOnClose | Dim_Regulation | Name | LEFT JOIN on Fact_SnapshotCustomer.RegulationID = Dim_Regulation.DWHRegulationID; regulation name at close date | Tier 1 — Dim_Regulation.md |
| 7 | RegulationOnOpen | Dim_Regulation | Name | LEFT JOIN on Dim_Position.RegulationIDOnOpen = Dim_Regulation.DWHRegulationID; regulation name at open date | Tier 1 — Dim_Regulation.md |
| 8 | PeriodOpen | Dim_Position | OpenOccurred | CASE WHEN YEAR(OpenOccurred)=YEAR(@Date) THEN 'Current_Period_Open' ELSE 'Previos_Period_Open' [sic] | Tier 2 — SP_M_Subsidieries_Realized_Commissions_Adjustments |
| 9 | PeriodClose | Dim_Position | CloseOccurred | CASE WHEN YEAR(CloseOccurred)=YEAR(@Date) THEN 'Current_Period_Close' ELSE 'Previous_Period_Close' | Tier 2 — SP_M_Subsidieries_Realized_Commissions_Adjustments |
| 10 | FullCommissionByUnits | Dim_Position | FullCommissionByUnits | SUM(FullCommissionByUnits) — prorated full commission for partial-close positions | Tier 1 — Dim_Position.md |
| 11 | FullCommissionOnClose | Dim_Position | FullCommissionOnClose | SUM(FullCommissionOnClose) — full commission on close | Tier 1 — Dim_Position.md |
| 12 | CommissionByUnits | Dim_Position | CommissionByUnits | SUM(CommissionByUnits) — prorated net commission for partial-close positions | Tier 1 — Dim_Position.md |
| 13 | CommissionOnClose | Dim_Position | CommissionOnClose | SUM(CommissionOnClose) — net commission on close | Tier 1 — Dim_Position.md |
| 14 | InstrumentType | Dim_Instrument | InstrumentType | Direct passthrough via dp.InstrumentID JOIN; 6 values: Currencies, Commodities, Indices, Stocks, ETF, Crypto Currencies | Tier 1 — Dim_Instrument.md |
| 15 | UpdateDate | ETL runtime | GETDATE() | ETL execution date (DATE type, not DATETIME) | Tier 2 — SP_M_Subsidieries_Realized_Commissions_Adjustments |
| 16 | IsSettled | Dim_Position | IsSettled | Direct passthrough; GROUP BY dimension | Tier 1 — Dim_Position.md |
