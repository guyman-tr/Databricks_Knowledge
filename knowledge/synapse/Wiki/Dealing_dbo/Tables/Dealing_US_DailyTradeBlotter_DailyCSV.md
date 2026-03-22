# Dealing_dbo.Dealing_US_DailyTradeBlotter_DailyCSV

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_US_DailyTradeBlotter_DailyCSV |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_USTradeReports` |
| **Refresh** | ⚠️ NOT IN OPSDB — scheduling unclear (**STALE since 2025-01-13**) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[TradeDate]` |
| **Rows** | ~1.16M |
| **Date Range** | 2025-01-13 only (TRUNCATE pattern — holds one day at a time) |
| **PII** | `[Client Name]` — contains customer full name (FirstName + LastName) |

---

## 1. Business Meaning

A single-day snapshot variant of the US daily trade blotter, designed to be exported as a CSV file for daily regulatory reporting. Unlike `Dealing_US_DailyTradeBlotter` (which accumulates all dates), this table is **truncated on every SP execution** and contains only the most recently processed trading day.

Key differences from `Dealing_US_DailyTradeBlotter`:
- **TRUNCATE pattern**: Table is truncated before each insert — always contains exactly one day.
- **Includes Partial fills**: No `WHERE OrderStatus = 'Filled'` filter — both 'Filled' and 'Partial' orders are included.
- **Fewer columns**: No `DateID`, `EntryID`, `OrderID` (not needed for the CSV export format).
- **ROUND_ROBIN distribution**: No hash distribution key (smaller table, scan-only access).

The same `#TradeBlotter` temp table feeds both this table and `Dealing_US_DailyTradeBlotter`.

---

## 2. Business Logic

- Identical data preparation to `Dealing_US_DailyTradeBlotter` (see that table for full business logic).
- **TRUNCATE** before INSERT: `TRUNCATE TABLE Dealing_dbo.Dealing_US_DailyTradeBlotter_DailyCSV`.
- **All statuses**: No `WHERE OrderStatus` filter — includes both 'Filled' and 'Partial' orders.
- Same column computations: times in EDT, Client Name = CONCAT, Fees=0, Net Commission=0, Settlement Date=NULL, Executing Broker='Apex', IsCopy from MirrorID.

---

## 3. Relationships

| Direction | Table | Join Key | Notes |
|-----------|-------|----------|-------|
| Source | Same as `Dealing_US_DailyTradeBlotter` | — | All same source tables |
| Related | `Dealing_dbo.Dealing_US_DailyTradeBlotter` | `TradeDate, CID` | Accumulating counterpart (Filled only) |

---

## 4. Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `TradeDate` | date | YES | Trade date. From `Dim_Date.FullDate`. Clustered index. Always contains a single day (TRUNCATE pattern). (Tier 2 — SP_USTradeReports) |
| `Client Name` | varchar(max) | YES | Customer full name. `CONCAT(FirstName, ' ', LastName)`. **PII.** Special-character column. (Tier 2 — SP_USTradeReports) |
| `CID` | int | YES | Customer ID. (Tier 2 — SP_USTradeReports) |
| `Symbol` | varchar(max) | YES | Instrument ticker (`SymbolFull` from Dim_Instrument). (Tier 2 — SP_USTradeReports) |
| `Cusip or ISIN` | varchar(max) | YES | ISIN code. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Side` | varchar(2) | YES | 'B' or 'S'. Inverted for close orders. (Tier 2 — SP_USTradeReports) |
| `Executed QTY` | decimal(38,8) | YES | Executed shares from etoro_Hedge_ExecutionLog. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Unit Price/share` | decimal(38,8) | YES | Execution price from etoro_Hedge_ExecutionLog. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Gross Price (QTY x Share Price)` | decimal(38,8) | YES | `Units × ExecutionRate`. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Executing Broker` | varchar(50) | YES | Hardcoded 'Apex'. (Tier 2 — SP_USTradeReports) |
| `Order Creation Time` | datetime | YES | Order request time in UTC (not EDT). Special-character column. (Tier 2 — SP_USTradeReports) |
| `Time Order Executed or Cancelled` | datetime | YES | Execution time in EDT. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Fees` | money | YES | Hardcoded 0. (Tier 2 — SP_USTradeReports) |
| `Net Commission` | money | YES | Hardcoded 0. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Settlement Date` | date | YES | Always NULL. (Tier 2 — SP_USTradeReports) |
| `Qty: Shares Requested` | decimal(38,8) | YES | Shares requested from eToroLogs_Real_Hedge_OrderLog. Special-character column. (Tier 2 — SP_USTradeReports) |
| `Order Routed Time` | datetime | YES | Routing time in EDT. Special-character column. (Tier 2 — SP_USTradeReports) |
| `UpdateDate` | datetime | YES | ETL metadata: `GETDATE()`. |
| `IsCopy` | varchar(10) | YES | 'Copy' (MirrorID > 0) or 'Manual'. (Tier 2 — SP_USTradeReports) |

---

## 5. Data Quality Notes

- ⚠️ **STALE**: Data stopped 2025-01-13. SP not in OpsDB.
- **Single-day table**: TRUNCATE pattern means only the last processed day exists. Do NOT use for historical analysis — use `Dealing_US_DailyTradeBlotter` instead.
- **Includes Partial fills**: Unlike `Dealing_US_DailyTradeBlotter`, partial fills are included here.
- **PII**: `[Client Name]` contains full customer name.
- **`Order Creation Time` is UTC**: Same caveat as sibling table.
- Same special-character column quoting requirements as `Dealing_US_DailyTradeBlotter`.

---

## 6. Usage Notes

```sql
-- Current single day contents
SELECT [TradeDate], COUNT(*) AS Orders, COUNT(DISTINCT CID) AS UniqueCustomers
FROM Dealing_dbo.Dealing_US_DailyTradeBlotter_DailyCSV
GROUP BY [TradeDate];

-- Include both Filled and Partial orders
SELECT [TradeDate], CID, Symbol, Side, [Executed QTY], IsCopy
FROM Dealing_dbo.Dealing_US_DailyTradeBlotter_DailyCSV;
```

---

## 7. Known Issues

- TRUNCATE pattern: table loses data on each SP run. Historical data only in `Dealing_US_DailyTradeBlotter`.
- Stale since 2025-01-13 — SP scheduling unclear.

---

## 8. Sources & Confidence

| Source | Phase | Confidence |
|--------|-------|------------|
| SSDT DDL (`Dealing_dbo.Dealing_US_DailyTradeBlotter_DailyCSV.sql`) | P1 | High |
| SP Logic (`Dealing_dbo.SP_USTradeReports.sql`) | P9 | High |
| Live data sample (Synapse MCP) | P2 | High |
| OpsDB orchestration | P9B | Not in OpsDB |
| Atlassian knowledge scan | P10 | Not available |

**Quality Score: 6.5/10** — Clear ETL logic but stale and TRUNCATE pattern limits utility. Deducted: stale (−1), not in OpsDB (−0.5), no Atlassian (−1), TRUNCATE single-day limitation (−0.5), PII (−0.5).
