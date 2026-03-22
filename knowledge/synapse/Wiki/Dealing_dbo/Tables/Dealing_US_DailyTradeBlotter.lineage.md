# Column Lineage: Dealing_dbo.Dealing_US_DailyTradeBlotter

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_US_DailyTradeBlotter` |
| **UC Target** | N/A (US regulatory trade blotter) |
| **Primary Source** | `Dealing_staging.eToroLogs_Real_Hedge_EMSOrders` (US EMS order log) |
| **ETL SP** | `Dealing_dbo.SP_USTradeReports` |
| **Secondary Sources** | `CopyFromLake.etoro_DWH_HistoryOrderForOpen`, `CopyFromLake.etoro_DWH_HistoryOrderForClose`, `CopyFromLake.etoro_Hedge_ExecutionLog`, `Dealing_staging.eToroLogs_Real_Hedge_OrderLog`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Date` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
US EMS Orders → Dealing_staging.eToroLogs_Real_Hedge_EMSOrders
  + Open Order CID/Details → CopyFromLake.etoro_DWH_HistoryOrderForOpen
  + Close Order CID/Details → CopyFromLake.etoro_DWH_HistoryOrderForClose
  + Execution Rate/Units → CopyFromLake.etoro_Hedge_ExecutionLog (matched on EMSOrderID+ExecutionTime)
  + Order Routing → Dealing_staging.eToroLogs_Real_Hedge_OrderLog
  + US Customer Names → DWH_dbo.Dim_Customer (RegulationID=8)
  + Instrument Symbol/ISIN → DWH_dbo.Dim_Instrument (InstrumentTypeID IN (5,6))
  + Trade Date → DWH_dbo.Dim_Date
  ↓
ETL: Dealing_dbo.SP_USTradeReports (DELETE+INSERT by DateID, Filled only)
  ↓
Target: Dealing_dbo.Dealing_US_DailyTradeBlotter
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **join-enriched** | Joined from a secondary source table during ETL. |
| **constant** | Hardcoded value — not derived from any source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| `TradeDate` | Dim_Date | `FullDate` | join-enriched | `Dim_Date.FullDate WHERE DateKey=@DateID` | Trade date |
| `DateID` | Dim_Date | `DateKey` | passthrough | `Dim_Date.DateKey` | Integer YYYYMMDD |
| `Client Name` | Dim_Customer | `FirstName, LastName` | ETL-computed | `CONCAT(FirstName, ' ', LastName)` — RegulationID=8 | **PII** |
| `CID` | HistoryOrderForOpen / HistoryOrderForClose | `CID` | ETL-computed | `ISNULL(OpenOrder.CID, CloseOrder.CID)` | Hash distribution key |
| `Symbol` | Dim_Instrument | `SymbolFull` | rename | `SymbolFull AS Symbol` | Ticker symbol |
| `Cusip or ISIN` | Dim_Instrument | `ISINCode` | rename | `ISINCode AS [Cusip or ISIN]` | Regulatory identifier |
| `Side` | HedgeEMSOrders / HistoryOrderForClose | `IsBuy` | ETL-computed | `CASE WHEN CloseOrder AND IsBuy=1 THEN 'S' ELSE 'B' END` | Inverted for close orders |
| `Executed QTY` | etoro_Hedge_ExecutionLog | `Units` | passthrough | `h.Units` — matched on EMSOrderID+ExecutionTime | — |
| `Unit Price/share` | etoro_Hedge_ExecutionLog | `ExecutionRate` | passthrough | `h.ExecutionRate` | Execution price |
| `Gross Price (QTY x Share Price)` | etoro_Hedge_ExecutionLog | `Units, ExecutionRate` | ETL-computed | `h.Units * h.ExecutionRate` | Computed in ETL |
| `Executing Broker` | — | — | constant | `'Apex'` | Hardcoded — eToro's US broker |
| `Order Creation Time` | eToroLogs_Real_Hedge_EMSOrders | `RequestTime` | passthrough | `a.RequestTime` (UTC — NOT EDT) | ⚠️ UTC, not EDT |
| `Time Order Executed or Cancelled` | eToroLogs_Real_Hedge_EMSOrders | `StatusUpdateTime` | ETL-computed | `DATEADD(HOUR,-4, StatusUpdateTime)` (EDT) | EDT timezone |
| `Fees` | — | — | constant | `0` | Not populated |
| `Net Commission` | — | — | constant | `0` | Not populated |
| `Settlement Date` | — | — | constant | `NULL` | Not populated |
| `Qty: Shares Requested` | eToroLogs_Real_Hedge_OrderLog | `Units` | passthrough | `ho.Units` — matched on OrderID | Requested shares |
| `Order Routed Time` | eToroLogs_Real_Hedge_OrderLog | `SendTime` | ETL-computed | `DATEADD(HOUR,-4, ho.SendTime)` (EDT) | EDT timezone |
| `UpdateDate` | SP runtime | `GETDATE()` | ETL-computed | `GETDATE()` | ETL metadata |
| `EntryID` | eToroLogs_Real_Hedge_EMSOrders | `EntryID` | passthrough | Direct | — |
| `OrderID` | eToroLogs_Real_Hedge_EMSOrders | `OrderID` | passthrough | Direct | — |
| `IsCopy` | HistoryOrderForOpen / HistoryOrderForClose | `MirrorID` | ETL-computed | `CASE WHEN MirrorID > 0 THEN 'Copy' ELSE 'Manual' END` | Mirror/copy trade indicator |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 5 |
| **Rename** | 2 |
| **ETL-computed** | 9 |
| **Join-enriched** | 1 |
| **Constant** | 4 |
| **Total** | 21 |
