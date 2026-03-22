# Dealing_dbo.Dealing_US_DailyTradeBlotter

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_US_DailyTradeBlotter |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_USTradeReports` |
| **Refresh** | ⚠️ NOT IN OPSDB — scheduling unclear (**STALE since 2025-01-13**) |
| **Distribution** | HASH(`[CID]`) |
| **Index** | CLUSTERED on `[TradeDate]` |
| **Rows** | ~408.7M |
| **Date Range** | 2022-01-02 → 2025-01-13 (**STALE ~14 months**) |
| **PII** | `[Client Name]` — contains customer full name (FirstName + LastName) |

---

## 1. Business Meaning

The daily trade blotter for US broker-dealer regulatory compliance. Contains every **Filled** trade executed for US-regulated customers (Dim_Customer.RegulationID=8) in US Stocks and ETFs (InstrumentTypeID IN (5,6)) for a given date. This is a FINRA/SEC-facing report format — each row represents one executed order with broker, price, quantity, and timing data in Eastern Daylight Time (EDT).

All times stored in EDT (UTC-4). The Executing Broker and Contra Broker are hardcoded as 'Apex' — eToro's US clearing broker. Fees and Net Commission are hardcoded to 0. Settlement Date is always NULL. `IsCopy` indicates whether the trade originated from a mirror/copy trade portfolio ('Copy') or was manually placed ('Manual').

**This table is stale since 2025-01-13** and is **not in OpsDB** — the SP scheduling is unclear. The table has ~408.7M rows — one of the largest in the Dealing schema. The companion `Dealing_US_DailyTradeBlotter_DailyCSV` holds only the latest day (TRUNCATE pattern) and includes Partial orders.

---

## 2. Business Logic

- **Order filter**: Only `OrderStatus = 'Filled'` orders are included. Partial fills and other statuses are excluded (use DailyCSV for Partial fills).
- **Trade matching**: `#HedgeEMSOrders` (from `eToroLogs_Real_Hedge_EMSOrders`) is the primary source. Joined to `HistoryOrderForOpen` and `HistoryOrderForClose` via ExecutionID to resolve CID.
- **Execution details**: `Units` and `ExecutionRate` from `CopyFromLake.etoro_Hedge_ExecutionLog` (matched on EMSOrderID+ExecutionTime).
- **Order routing**: `SendTime` and `Units` from `Dealing_staging.eToroLogs_Real_Hedge_OrderLog`.
- **US customers**: `Dim_Customer` filtered to `RegulationID = 8`.
- **Instruments**: `Dim_Instrument` filtered to `InstrumentTypeID IN (5, 6)` (Stocks=5, ETFs=6).
- **Side logic**: For open orders: 'B'/'S' from `IsBuy`. For close orders: inverted (`CASE WHEN c.ExecutionID IS NOT NULL AND IsBuy=1 THEN 'S' ELSE 'B' END`).
- **Times**: All timestamps in EDT via `DATEADD(HOUR, -4, UTC_time)`.
- **Hardcoded constants**: Executing Broker='Apex', Fees=0, Net Commission=0, Settlement Date=NULL.
- **IsCopy**: `CASE WHEN MirrorID > 0 THEN 'Copy' ELSE 'Manual' END` — distinguishes mirror/copy trade portfolios.
- **Refresh pattern**: DELETE by DateID then INSERT (accumulating, not TRUNCATE — this is why it has 408.7M rows).

---

## 3. Relationships

| Direction | Table | Join Key | Notes |
|-----------|-------|----------|-------|
| Source | `Dealing_staging.eToroLogs_Real_Hedge_EMSOrders` | `ExecutionID, OrderID` | Primary EMS order source |
| Source | `CopyFromLake.etoro_DWH_HistoryOrderForOpen` | `ExecutionID` | Open order CID and details |
| Source | `CopyFromLake.etoro_DWH_HistoryOrderForClose` | `ExecutionID` | Close order CID and details |
| Source | `CopyFromLake.etoro_Hedge_ExecutionLog` | `EMSOrderID, ExecutionTime` | Actual execution rate and units |
| Source | `Dealing_staging.eToroLogs_Real_Hedge_OrderLog` | `OrderID` | Order routing time and requested units |
| Source | `DWH_dbo.Dim_Customer` | `RealCID` | US customer filter (RegulationID=8) |
| Source | `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument filter (InstrumentTypeID IN (5,6)) |
| Source | `DWH_dbo.Dim_Date` | `DateKey` | Date resolution for TradeDate/DateID |
| Related | `Dealing_dbo.Dealing_US_DailyTradeBlotter_DailyCSV` | `TradeDate, CID` | Daily snapshot variant (TRUNCATE, includes Partial) |
| Related | `Dealing_dbo.Dealing_US_OriginalEntryTradeTicket` | `Date` | Regulatory original-entry companion |

---

## 4. Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `TradeDate` | date | YES | Date of trade execution. From `Dim_Date.FullDate` via @DateID. Clustered index. (Tier 2 — SP_USTradeReports) |
| `DateID` | int | YES | Integer date key (YYYYMMDD). From `Dim_Date.DateKey`. (Tier 2 — SP_USTradeReports) |
| `Client Name` | varchar(max) | YES | Customer full name: `CONCAT(FirstName, ' ', LastName)` from Dim_Customer. **PII — contains customer name.** Special-character column. (Tier 2 — SP_USTradeReports) |
| `CID` | int | YES | Customer ID. `ISNULL(OpenOrder.CID, CloseOrder.CID)`. Hash distribution key. (Tier 2 — SP_USTradeReports) |
| `Symbol` | varchar(max) | YES | Instrument ticker symbol (`SymbolFull` from Dim_Instrument). (Tier 2 — SP_USTradeReports) |
| `Cusip or ISIN` | varchar(max) | YES | ISIN code from Dim_Instrument. Used as CUSIP/ISIN identifier in regulatory reports. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Side` | varchar(2) | YES | Trade direction: 'B' (Buy) or 'S' (Sell). For close orders: direction is inverted (closing a Buy = 'S'). (Tier 2 — SP_USTradeReports) |
| `Executed QTY` | decimal(38,8) | YES | Number of shares executed. From `etoro_Hedge_ExecutionLog.Units`. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Unit Price/share` | decimal(38,8) | YES | Execution price per share. From `etoro_Hedge_ExecutionLog.ExecutionRate`. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Gross Price (QTY x Share Price)` | decimal(38,8) | YES | `Units × ExecutionRate`. Computed in ETL. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Executing Broker` | varchar(50) | YES | Hardcoded as 'Apex'. eToro's US clearing broker. (Tier 2 — SP_USTradeReports) |
| `Order Creation Time` | datetime | YES | Order request time in UTC (`RequestTime` from HedgeEMSOrders). Note: stored in UTC, not EDT. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Time Order Executed or Cancelled` | datetime | YES | Order execution time in EDT: `DATEADD(HOUR,-4, StatusUpdateTime)`. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Fees` | money | YES | Hardcoded to 0. No fee data captured. (Tier 2 — SP_USTradeReports) |
| `Net Commission` | money | YES | Hardcoded to 0. No commission data captured. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Settlement Date` | date | YES | Always NULL — settlement date not populated. (Tier 2 — SP_USTradeReports) |
| `Qty: Shares Requested` | decimal(38,8) | YES | Number of shares originally requested. From `eToroLogs_Real_Hedge_OrderLog.Units`. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Order Routed Time` | datetime | YES | Time order was routed to Apex in EDT: `DATEADD(HOUR,-4, ho.SendTime)`. Special-character column. (Tier 2 — SP_USTradeReports) |
| `UpdateDate` | datetime | YES | ETL metadata: `GETDATE()` at SP execution time. |
| `EntryID` | bigint | YES | Entry ID from `eToroLogs_Real_Hedge_EMSOrders`. (Tier 2 — SP_USTradeReports) |
| `OrderID` | varchar(25) | YES | Order ID from `eToroLogs_Real_Hedge_EMSOrders`. (Tier 2 — SP_USTradeReports) |
| `IsCopy` | varchar(10) | YES | 'Copy' if order originated from a mirror/copy trade portfolio (MirrorID > 0); 'Manual' otherwise. (Tier 2 — SP_USTradeReports) |

---

## 5. Data Quality Notes

- ⚠️ **STALE**: Data stopped 2025-01-13 (~14 months at time of documentation). SP not in OpsDB — run frequency unclear.
- **PII**: `[Client Name]` contains customer full name (`CONCAT(FirstName, ' ', LastName)`). Treat as PII.
- **`Order Creation Time` is UTC, not EDT**: This column uses `a.RequestTime` directly (UTC), while other time columns use `DATEADD(HOUR,-4,...)` for EDT. Flag for report consumers.
- **Settlement Date always NULL**: Not populated in the ETL. Do not use for settlement analysis.
- **Fees and Net Commission always 0**: No fee/commission data is captured.
- **408.7M rows**: Largest table in Dealing schema. Always filter on `[TradeDate]` (clustered index) or `[CID]` (hash distribution key).
- **Special-character columns**: Multiple columns with spaces and special characters (`[Client Name]`, `[Cusip or ISIN]`, `[Executed QTY]`, `[Unit Price/share]`, `[Gross Price (QTY x Share Price)]`, `[Order Creation Time]`, `[Time Order Executed or Cancelled]`, `[Net Commission]`, `[Qty: Shares Requested]`, `[Order Routed Time]`) require bracket quoting.
- **Filled only**: Only 'Filled' orders. For Partial fills, use `Dealing_US_DailyTradeBlotter_DailyCSV`.

---

## 6. Usage Notes

```sql
-- Latest date available
SELECT MAX([TradeDate]) FROM Dealing_dbo.Dealing_US_DailyTradeBlotter;

-- Trades for a specific date + customer
SELECT [TradeDate], [Client Name], CID, Symbol, Side,
       [Executed QTY], [Unit Price/share], [Gross Price (QTY x Share Price)], IsCopy
FROM Dealing_dbo.Dealing_US_DailyTradeBlotter
WHERE [TradeDate] = '2025-01-13'
  AND CID = 12345;
```

**Performance**: HASH(CID) distribution + CLUSTERED on [TradeDate]. Best queries filter on both `[TradeDate]` AND `[CID]`. Avoid full scans on this 408.7M row table.

---

## 7. Known Issues

- Table is stale since 2025-01-13 — not in OpsDB, SP scheduling unclear.
- `[Order Creation Time]` is in UTC while all other time columns are in EDT.
- Settlement Date always NULL.
- Fees and Net Commission always 0.
- Multiple special-character column names require bracket quoting.

---

## 8. Sources & Confidence

| Source | Phase | Confidence |
|--------|-------|------------|
| SSDT DDL (`Dealing_dbo.Dealing_US_DailyTradeBlotter.sql`) | P1 | High |
| SP Logic (`Dealing_dbo.SP_USTradeReports.sql`) | P9 | High |
| Live data sample (Synapse MCP) | P2 | High |
| OpsDB orchestration | P9B | Not in OpsDB |
| Atlassian knowledge scan | P10 | Not available |

**Quality Score: 6.5/10** — Active SP with clear logic, but table is stale. Deducted: stale data (−1), not in OpsDB (−0.5), no Atlassian (−1), many special-character columns/complexity (−0.5), PII present (−0.5).
