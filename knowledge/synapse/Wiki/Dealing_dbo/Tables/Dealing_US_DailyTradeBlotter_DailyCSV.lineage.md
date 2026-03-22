# Column Lineage: Dealing_dbo.Dealing_US_DailyTradeBlotter_DailyCSV

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_US_DailyTradeBlotter_DailyCSV` |
| **UC Target** | N/A (US regulatory trade blotter — daily CSV export) |
| **Primary Source** | `Dealing_staging.eToroLogs_Real_Hedge_EMSOrders` (US EMS order log) |
| **ETL SP** | `Dealing_dbo.SP_USTradeReports` |
| **Secondary Sources** | Same as `Dealing_US_DailyTradeBlotter` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
[Same lineage chain as Dealing_US_DailyTradeBlotter]

US EMS Orders → Dealing_staging.eToroLogs_Real_Hedge_EMSOrders
  + Open/Close Order Details → CopyFromLake.etoro_DWH_HistoryOrderForOpen/Close
  + Execution Rate/Units → CopyFromLake.etoro_Hedge_ExecutionLog
  + Order Routing → Dealing_staging.eToroLogs_Real_Hedge_OrderLog
  + US Customers → DWH_dbo.Dim_Customer (RegulationID=8)
  + Instruments → DWH_dbo.Dim_Instrument (InstrumentTypeID IN (5,6))
  + Trade Date → DWH_dbo.Dim_Date
  ↓
ETL: Dealing_dbo.SP_USTradeReports (TRUNCATE then INSERT — single-day, all statuses)
  ↓
Target: Dealing_dbo.Dealing_US_DailyTradeBlotter_DailyCSV
```

## Column Lineage

> All column mappings are identical to `Dealing_US_DailyTradeBlotter` with three differences:
> 1. No `DateID`, `EntryID`, `OrderID` columns (not in this table)
> 2. No `WHERE OrderStatus = 'Filled'` filter — Partial orders also included
> 3. TRUNCATE replaces DELETE+INSERT by DateID

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| `TradeDate` | Dim_Date | `FullDate` | join-enriched | `Dim_Date.FullDate WHERE DateKey=@DateID` | Always single day |
| `Client Name` | Dim_Customer | `FirstName, LastName` | ETL-computed | `CONCAT(FirstName, ' ', LastName)` | **PII** |
| `CID` | HistoryOrderForOpen / HistoryOrderForClose | `CID` | ETL-computed | `ISNULL(OpenOrder.CID, CloseOrder.CID)` | — |
| `Symbol` | Dim_Instrument | `SymbolFull` | rename | `SymbolFull AS Symbol` | — |
| `Cusip or ISIN` | Dim_Instrument | `ISINCode` | rename | `ISINCode AS [Cusip or ISIN]` | — |
| `Side` | HedgeEMSOrders / HistoryOrderForClose | `IsBuy` | ETL-computed | Inverted for close orders | — |
| `Executed QTY` | etoro_Hedge_ExecutionLog | `Units` | passthrough | `h.Units` | — |
| `Unit Price/share` | etoro_Hedge_ExecutionLog | `ExecutionRate` | passthrough | `h.ExecutionRate` | — |
| `Gross Price (QTY x Share Price)` | etoro_Hedge_ExecutionLog | `Units, ExecutionRate` | ETL-computed | `h.Units * h.ExecutionRate` | — |
| `Executing Broker` | — | — | constant | `'Apex'` | Hardcoded |
| `Order Creation Time` | eToroLogs_Real_Hedge_EMSOrders | `RequestTime` | passthrough | UTC (not EDT) | ⚠️ UTC |
| `Time Order Executed or Cancelled` | eToroLogs_Real_Hedge_EMSOrders | `StatusUpdateTime` | ETL-computed | `DATEADD(HOUR,-4, StatusUpdateTime)` | EDT |
| `Fees` | — | — | constant | `0` | Hardcoded |
| `Net Commission` | — | — | constant | `0` | Hardcoded |
| `Settlement Date` | — | — | constant | `NULL` | Hardcoded |
| `Qty: Shares Requested` | eToroLogs_Real_Hedge_OrderLog | `Units` | passthrough | `ho.Units` | — |
| `Order Routed Time` | eToroLogs_Real_Hedge_OrderLog | `SendTime` | ETL-computed | `DATEADD(HOUR,-4, ho.SendTime)` | EDT |
| `UpdateDate` | SP runtime | `GETDATE()` | ETL-computed | `GETDATE()` | ETL metadata |
| `IsCopy` | HistoryOrderForOpen / HistoryOrderForClose | `MirrorID` | ETL-computed | `CASE WHEN MirrorID > 0 THEN 'Copy' ELSE 'Manual' END` | — |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 4 |
| **Rename** | 2 |
| **ETL-computed** | 8 |
| **Join-enriched** | 1 |
| **Constant** | 4 |
| **Total** | 19 |
