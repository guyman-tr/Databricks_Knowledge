# Dealing_dbo.Dealing_US_OriginalEntryTradeTicket

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_US_OriginalEntryTradeTicket |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_USTradeReports` |
| **Refresh** | ⚠️ NOT IN OPSDB — scheduling unclear (**STALE since 2025-01-13**) |
| **Distribution** | HASH(`[CID]`) |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~587.6M |
| **Date Range** | 2023-01-02 → 2025-01-13 (**STALE ~14 months**) |
| **PII** | `[Client Name]` — contains customer full name (FirstName + LastName) |

---

## 1. Business Meaning

The original-entry trade ticket for US broker-dealer regulatory compliance. Contains every US stock/ETF trade (both opens and closes) for US-regulated customers (RegulationID=8) in a format matching FINRA original-entry trade ticket requirements. While `Dealing_US_DailyTradeBlotter` shows the order execution from the EMS/broker perspective, this table captures the **order as entered by the customer** — including order receipt time, regulatory required fields like Agency/Principal, Solicited/Unsolicited, Long/Short, and routing to Apex.

Several fields are hardcoded to regulatory standard values:
- `[Order Type]` = 'Market' (all eToro US orders are market orders)
- `[Agency/ Principal]` = 'Agency' (eToro acts as agent)
- `[Solicited/ Unsolicited]` = 'Unsolicited'
- `[Order Entered By]` = 'System'
- `[Contra Broker]` = 'Apex'
- `[Long/Short Sell]` = 'Long'
- `[Security Location]` = 'Apex'
- `[Discretionary or non]` = 'Non-discretionary'

Sources both open orders (`HistoryOrderForOpen`) and close orders (`HistoryOrderForClose`) — unlike `Dealing_US_DailyTradeBlotter` which uses EMS orders as the primary source.

**This table is stale since 2025-01-13** and **not in OpsDB**. At 587.6M rows it is the largest table in the Dealing schema.

---

## 2. Business Logic

- **Order sources**: Two-part UNION ALL — `#HistoryOrderForOpen` for opening orders and `#HistoryOrderForClose` for closing orders. Both filtered to `InstrumentTypeID IN (5,6)` and US customers.
- **Side**: 'B' or 'S' from `IsBuy`. For close orders: inverted (`IsBuy=1 → 'S'`).
- **Execution price**: `UnitMargin` from the order record (vs `ExecutionRate` from HedgeExecutionLog in the blotter).
- **Executed QTY**: `FilledAmountInUnits` from the order record.
- **QTY Requested**: `AmountInUnits` for opens; for closes: `CASE WHEN UnitsToDeduct<>0 THEN UnitsToDeduct ELSE ISNULL(RequestedAmountInUnits, AmountInUnitsDecimal) END`.
- **Routing time**: `ho.SendTime` from `eToroLogs_Real_Hedge_OrderLog` (matched on OrderID via EMS order).
- **Times in EDT**: `DATEADD(HOUR, -4, UTC_time)`.
- **Execution date logic**: `CASE WHEN ErrorCode<>0 THEN StatusUpdateTime ELSE CloseOccurred END` — uses StatusUpdateTime if there was an error, otherwise the actual close time.
- **IsCopy**: 'Copy' when `MirrorID > 0`.
- **DELETE+INSERT by DateID**: Accumulating table (587.6M rows).

---

## 3. Relationships

| Direction | Table | Join Key | Notes |
|-----------|-------|----------|-------|
| Source | `CopyFromLake.etoro_DWH_HistoryOrderForOpen` | `CID` | Opening order records |
| Source | `CopyFromLake.etoro_DWH_HistoryOrderForClose` | `CID, PositionID` | Closing order records |
| Source | `Dealing_staging.eToroLogs_Real_Hedge_EMSOrders` | `ExecutionID` | EMS order for execution rate and routing |
| Source | `Dealing_staging.eToroLogs_Real_Hedge_OrderLog` | `OrderID` | Order routing time to Apex |
| Source | `DWH_dbo.Dim_Customer` | `RealCID` | US customer filter (RegulationID=8) |
| Source | `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument filter (InstrumentTypeID IN (5,6)) |
| Source | `DWH_dbo.Dim_Position` | `PositionID` | For close orders: position details (InstrumentID, AmountInUnitsDecimal) |
| Source | `DWH_dbo.Dim_Date` | `DateKey` | Date resolution |
| Related | `Dealing_dbo.Dealing_US_DailyTradeBlotter` | `Date` | EMS-perspective companion |

---

## 4. Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | YES | Trade date. From `Dim_Date.FullDate`. Clustered index. (Tier 2 — SP_USTradeReports) |
| `DateID` | int | YES | Integer date key. From `Dim_Date.DateKey`. (Tier 2 — SP_USTradeReports) |
| `Side` | varchar(2) | YES | 'B' (Buy) or 'S' (Sell). Inverted for close orders. (Tier 2 — SP_USTradeReports) |
| `Security` | varchar(max) | YES | Instrument ticker (`SymbolFull` from Dim_Instrument). Regulatory name for the instrument. (Tier 2 — SP_USTradeReports) |
| `Cusip or ISIN` | varchar(max) | YES | ISIN code from Dim_Instrument. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Order Type` | varchar(max) | YES | Hardcoded 'Market'. All eToro US orders are market orders. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Qty: Shares Requested` | decimal(38,8) | YES | Shares originally requested. `AmountInUnits` for opens; derived for closes. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Client Name` | varchar(max) | YES | Customer full name. `CONCAT(FirstName, ' ', LastName)`. **PII.** Special-character column. (Tier 2 — SP_USTradeReports) |
| `CID` | int | YES | Customer ID. Hash distribution key. (Tier 2 — SP_USTradeReports) |
| `Agency/Principal` | varchar(max) | YES | Hardcoded 'Agency'. eToro acts as agent for US trades. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Price Executed` | decimal(38,8) | YES | Execution price per share. `UnitMargin` from order record. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Executed Quantity` | decimal(38,8) | YES | Filled units. `FilledAmountInUnits` from order record. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Date Order Received` | date | YES | Date the order was received. `CAST(RequestOccurred AS DATE)`. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Time Order Received` | datetime | YES | UTC time order was received (`RequestOccurred`). ⚠️ UTC not EDT. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Date Order Executed or Cancelled` | date | YES | Execution/cancellation date in EDT. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Time Order Executed or Cancelled` | datetime | YES | Execution time in EDT: `DATEADD(HOUR,-4, StatusUpdateTime or CloseOccurred)`. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Solicited / Unsolicited` | varchar(max) | YES | Hardcoded 'Unsolicited'. All eToro US trades are customer-initiated. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Order Entered By` | varchar(max) | YES | Hardcoded 'System'. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Contra Broker` | varchar(max) | YES | Hardcoded 'Apex'. eToro's US clearing broker. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Long/Short Sell` | varchar(max) | YES | Hardcoded 'Long'. All US stock positions are long-only. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Security Location` | varchar(max) | YES | Hardcoded 'Apex'. Shares held at Apex Clearing. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Date/Time routed to APEX` | datetime | YES | UTC time order was routed to Apex (`ho.SendTime`). ⚠️ UTC. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Discretionary or non` | varchar(max) | YES | Hardcoded 'Non-discretionary'. Special-character column. (Tier 2 — SP_USTradeReports) |
| `UpdateDate` | datetime | YES | ETL metadata: `GETDATE()`. |
| `OrderID` | bigint | YES | Order ID from HistoryOrderForOpen/Close. (Tier 2 — SP_USTradeReports) |
| `IsCopy` | varchar(10) | YES | 'Copy' (MirrorID > 0) or 'Manual'. (Tier 2 — SP_USTradeReports) |

---

## 5. Data Quality Notes

- ⚠️ **STALE**: Data stopped 2025-01-13 (~14 months at time of documentation). SP not in OpsDB.
- **PII**: `[Client Name]` contains full customer name.
- **587.6M rows**: Largest table in the Dealing schema. Always filter on `[Date]` (clustered index) or `[CID]` (hash distribution key).
- **Multiple hardcoded constants**: `[Order Type]`, `[Agency/Principal]`, `[Solicited / Unsolicited]`, `[Order Entered By]`, `[Contra Broker]`, `[Long/Short Sell]`, `[Security Location]`, `[Discretionary or non]` are all hardcoded.
- **Mixed UTC/EDT**: `[Time Order Received]` and `[Date/Time routed to APEX]` are UTC. `[Time Order Executed or Cancelled]` is EDT. Flag for report consumers.
- **Special-character columns**: Most columns have spaces or special characters requiring bracket quoting.
- **`Price Executed` uses `UnitMargin`**: Different price source than `Dealing_US_DailyTradeBlotter` (which uses `ExecutionRate` from HedgeExecutionLog).

---

## 6. Usage Notes

```sql
-- Latest date available
SELECT MAX([Date]) FROM Dealing_dbo.Dealing_US_OriginalEntryTradeTicket;

-- Trades for a specific customer on a date
SELECT [Date], CID, [Client Name], Security, Side,
       [Executed Quantity], [Price Executed], IsCopy
FROM Dealing_dbo.Dealing_US_OriginalEntryTradeTicket
WHERE [Date] = '2025-01-13'
  AND CID = 12345;
```

**Performance**: HASH(CID) + CLUSTERED on [Date]. At 587.6M rows, always filter on both `[Date]` and `[CID]`.

---

## 7. Known Issues

- Stale since 2025-01-13 — not in OpsDB.
- Mixed timezone: some columns UTC, some EDT.
- Most fields are hardcoded regulatory constants.
- Multiple special-character column names require bracket quoting.

---

## 8. Sources & Confidence

| Source | Phase | Confidence |
|--------|-------|------------|
| SSDT DDL (`Dealing_dbo.Dealing_US_OriginalEntryTradeTicket.sql`) | P1 | High |
| SP Logic (`Dealing_dbo.SP_USTradeReports.sql`) | P9 | High |
| Live data sample (Synapse MCP) | P2 | High |
| OpsDB orchestration | P9B | Not in OpsDB |
| Atlassian knowledge scan | P10 | Not available |

**Quality Score: 6.5/10** — Clear ETL logic but stale. Deducted: stale (−1), not in OpsDB (−0.5), no Atlassian (−1), many hardcoded fields reduce analytical value (−0.5), PII (−0.5).
