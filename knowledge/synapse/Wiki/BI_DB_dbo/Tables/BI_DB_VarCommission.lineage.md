# Column Lineage -- BI_DB_dbo.BI_DB_VarCommission

**Writer SP**: `BI_DB_dbo.SP_VarCommission` (Priority 99 -- FinanceReportSPS)
**Author**: Jenia Simonovitch (2020-10-18)
**ETL Pattern**: DELETE-INSERT by DateID
**Architecture**: #Month (calendar) CROSS JOIN + #Commissions (aggregated) -> INSERT

---

## Source Tables

| Source | Alias | Role |
|--------|-------|------|
| DWH_dbo.Dim_Position | dp | Primary -- commissions, forex rates, open/close dates |
| DWH_dbo.Dim_Instrument | di | Instrument metadata (type, name, SellCurrencyID) |
| DWH_dbo.Dim_Customer | dc | Customer validity (IsValidCustomer=1) |
| DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot | dphscl | Hedge server assignment (LEFT JOIN) |
| DWH_dbo.Dim_Date | dd | Calendar fields (via #Month) |

---

## Column-Level Lineage

**Alias-level source attribution applied** -- #Commissions temp table -> INSERT.

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| Date | computed | @Date | Direct |
| DateID | computed | @Date | BI_DB_dbo.DateToDateID(@Date) |
| InstrumentType | Dim_Instrument (di) | InstrumentType | Direct |
| CalendarYearMonth | Dim_Date (dd via #Month) | CalendarYearMonth | CROSS JOIN from #Month |
| MonthName | Dim_Date (dd via #Month) | MonthName | CROSS JOIN from #Month |
| IsSettled | Dim_Position (dp) | IsSettled | Direct. GROUP BY dimension |
| FullCommission | Dim_Position (dp) | FullCommissionByUnits, FullCommissionOnClose | SUM(CASE: same-day=OnClose, carry-over=OnClose-ByUnits, new=ByUnits) |
| VarCommission | Dim_Position (dp) | AmountInUnitsDecimal, Ask, Bid, USDConversionRate | SUM(Units * Spread * USDRate). CASE for open/close/same-day |
| VarCommission_Openings | Dim_Position (dp) | InitForex_Ask, InitForex_Bid | SUM for positions where OpenDateID = @DateID only |
| FullCommission_Openings | Dim_Position (dp) | FullCommissionByUnits | SUM for positions where OpenDateID = @DateID only |
| UpdateDate | computed | GETDATE() | SP execution timestamp |
| InstrumentID | Dim_Position (dp) / Dim_Instrument (di) | InstrumentID | Direct |
| InstrumentName | Dim_Instrument (di) | Name | Direct |
| VarCommission_Closings | Dim_Position (dp) | EndForex_Ask, EndForex_Bid | SUM for positions where CloseDateID = @DateID only |
| FullCommission_Closings | Dim_Position (dp) | FullCommissionOnClose | SUM for positions where CloseDateID = @DateID only |
| HedgeServerID | Snapshot (dphscl) / Dim_Position (dp) | HedgeServerID | ISNULL(dphscl.HedgeServerID, dp.HedgeServerID). Snapshot takes priority |
