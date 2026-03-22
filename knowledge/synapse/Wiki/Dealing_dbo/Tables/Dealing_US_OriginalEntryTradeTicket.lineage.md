# Column Lineage: Dealing_dbo.Dealing_US_OriginalEntryTradeTicket

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_US_OriginalEntryTradeTicket` |
| **UC Target** | N/A (US regulatory original-entry trade ticket) |
| **Primary Source** | `CopyFromLake.etoro_DWH_HistoryOrderForOpen` + `CopyFromLake.etoro_DWH_HistoryOrderForClose` |
| **ETL SP** | `Dealing_dbo.SP_USTradeReports` |
| **Secondary Sources** | `Dealing_staging.eToroLogs_Real_Hedge_EMSOrders`, `Dealing_staging.eToroLogs_Real_Hedge_OrderLog`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Position`, `DWH_dbo.Dim_Date` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Open Orders → CopyFromLake.etoro_DWH_HistoryOrderForOpen
Close Orders → CopyFromLake.etoro_DWH_HistoryOrderForClose
  + EMS Orders (for execution/routing details) → Dealing_staging.eToroLogs_Real_Hedge_EMSOrders
  + Order Routing Time → Dealing_staging.eToroLogs_Real_Hedge_OrderLog
  + US Customer Names → DWH_dbo.Dim_Customer (RegulationID=8)
  + Instrument Details → DWH_dbo.Dim_Instrument (InstrumentTypeID IN (5,6))
  + Position Details (for closes) → DWH_dbo.Dim_Position
  + Trade Date → DWH_dbo.Dim_Date
  ↓
ETL: Dealing_dbo.SP_USTradeReports (DELETE+INSERT by DateID, UNION ALL open+close)
  ↓
Target: Dealing_dbo.Dealing_US_OriginalEntryTradeTicket
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **rename** | Same value, different column name. |
| **ETL-computed** | Derived/calculated in ETL SP. |
| **join-enriched** | Joined from secondary source. |
| **constant** | Hardcoded regulatory value. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| `Date` | Dim_Date | `FullDate` | join-enriched | `Dim_Date.FullDate WHERE DateKey=@DateID` | Trade date |
| `DateID` | Dim_Date | `DateKey` | passthrough | `Dim_Date.DateKey` | Integer YYYYMMDD |
| `Side` | HistoryOrderForOpen/Close | `IsBuy` | ETL-computed | `CASE WHEN IsBuy=1 THEN 'B' ELSE 'S' END` (inverted for close: `IsBuy=1→'S'`) | — |
| `Security` | Dim_Instrument | `SymbolFull` | rename | `SymbolFull AS Security` | Ticker as security name |
| `Cusip or ISIN` | Dim_Instrument | `ISINCode` | rename | `ISINCode AS [Cusip or ISIN]` | Regulatory identifier |
| `Order Type` | — | — | constant | `'Market'` | All eToro US orders are market orders |
| `Qty: Shares Requested` | HistoryOrderForOpen | `AmountInUnits` | passthrough | Direct for opens; `CASE WHEN UnitsToDeduct<>0 THEN UnitsToDeduct ELSE ISNULL(RequestedAmountInUnits, AmountInUnitsDecimal) END` for closes | — |
| `Client Name` | Dim_Customer | `FirstName, LastName` | ETL-computed | `CONCAT(FirstName, ' ', LastName)` | **PII** |
| `CID` | HistoryOrderForOpen / HistoryOrderForClose | `CID` | passthrough | Direct | Hash distribution key |
| `Agency/Principal` | — | — | constant | `'Agency'` | eToro acts as agent |
| `Price Executed` | HistoryOrderForOpen / HistoryOrderForClose | `UnitMargin` | passthrough | `UnitMargin AS [Price Executed]` | Different from DailyBlotter ExecutionRate |
| `Executed Quantity` | HistoryOrderForOpen / HistoryOrderForClose | `FilledAmountInUnits` | passthrough | Direct | — |
| `Date Order Received` | HistoryOrderForOpen / HistoryOrderForClose | `RequestOccurred` | ETL-computed | `CAST(RequestOccurred AS DATE)` | UTC date |
| `Time Order Received` | HistoryOrderForOpen / HistoryOrderForClose | `RequestOccurred` | passthrough | Direct (UTC — ⚠️ not EDT) | UTC |
| `Date Order Executed or Cancelled` | HistoryOrderForOpen / HistoryOrderForClose | `StatusUpdateTime / CloseOccurred` | ETL-computed | `CASE WHEN ErrorCode<>0 THEN StatusUpdateTime ELSE CloseOccurred END` | EDT date |
| `Time Order Executed or Cancelled` | HistoryOrderForOpen / HistoryOrderForClose | `StatusUpdateTime / CloseOccurred` | ETL-computed | `DATEADD(HOUR,-4, StatusUpdateTime or CloseOccurred)` | EDT |
| `Solicited / Unsolicited` | — | — | constant | `'Unsolicited'` | Customer-initiated |
| `Order Entered By` | — | — | constant | `'System'` | — |
| `Contra Broker` | — | — | constant | `'Apex'` | eToro's US clearing broker |
| `Long/Short Sell` | — | — | constant | `'Long'` | Long-only positions |
| `Security Location` | — | — | constant | `'Apex'` | Shares held at Apex Clearing |
| `Date/Time routed to APEX` | eToroLogs_Real_Hedge_OrderLog | `SendTime` | passthrough | Direct (UTC — ⚠️ not EDT) | UTC |
| `Discretionary or non` | — | — | constant | `'Non-discretionary'` | — |
| `UpdateDate` | SP runtime | `GETDATE()` | ETL-computed | `GETDATE()` | ETL metadata |
| `OrderID` | HistoryOrderForOpen / HistoryOrderForClose | `OrderID` | passthrough | Direct (bigint) | Different type vs DailyBlotter varchar(25) |
| `IsCopy` | HistoryOrderForOpen / HistoryOrderForClose | `MirrorID` | ETL-computed | `CASE WHEN MirrorID > 0 THEN 'Copy' ELSE 'Manual' END` | — |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 7 |
| **Rename** | 2 |
| **ETL-computed** | 7 |
| **Join-enriched** | 1 |
| **Constant** | 8 |
| **Total** | 25 |
