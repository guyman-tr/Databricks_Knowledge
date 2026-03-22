# Dealing_dbo.External_Gold_Dealing_Marex_Trader_OrderID

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | External_Gold_Dealing_Marex_Trader_OrderID |
| **Type** | External Table |
| **Data Source** | `internal-sources` → `Gold/Dealing/Marex_Trader_OrderID/*.parquet` |
| **Columns** | 8 |
| **Primary Source** | Databricks Gold layer (Marex futures order mapping pipeline) |
| **Consuming SPs** | `Dealing_dbo.SP_Marex_Recon` |
| **Refresh** | Gold layer updated by Databricks pipeline |
| **PII** | NO |
| **Tags** | dealing, marex, futures, reconciliation, order-mapping, external-table, gold |

---

## 1. Business Meaning

`External_Gold_Dealing_Marex_Trader_OrderID` is a **mapping table** that links eToro order/execution identifiers to Marex trader identifiers. It enables the Marex reconciliation process (`SP_Marex_Recon`) to match client-side futures trades with the corresponding Marex liquidity provider executions.

Marex is eToro's liquidity provider for exchange-traded futures. When eToro executes a futures trade on behalf of a client, the trade flows through eToro's Hedge Execution system and is routed to Marex for market execution. Each trade gets:
- An eToro **OrderID** (from the trading platform)
- An eToro **ExecutionID** (from the hedge execution log — the EMS order ID)
- A Marex **Trader** identifier (the chit number / order reference on the Marex side)

This table stores the mapping so that the daily reconciliation SP can join all three sides: client positions, eToro hedge executions, and Marex LP records.

**Fix history**: SR-338875 (2025-10-23) changed the join from `PositionID` to `OrderID`, indicating that `OrderID` is the correct matching key for linking client positions to Marex trades.

---

## 2. Business Logic

### SP_Marex_Recon Usage

The SP uses this table in two critical join points:

1. **Client-side trades with Trader**: `#Clients_Trades_Futures_Total_Trader` — joins `External_Gold_Dealing_Marex_Trader_OrderID.OrderID = #Clients_Trades_Futures_Total.OrderID` to attach the `Trader` identifier to each client-side futures trade.

2. **eToro allocation with Trader**: `#etoroAllocation_Futures_Trader` — joins `External_Gold_Dealing_Marex_Trader_OrderID.ExecutionID = #etoroAllocation_Futures.EMSOrderID` to attach the `Trader` identifier to each hedge execution log entry.

The `Trader` field then becomes the matching key for joining with Marex's own records (via the `CHIT NUMBER` field in `LP_EdnF_PFDFST4_CUSTOM`).

### EOD Holdings

For EOD (end-of-day) holdings reconciliation, the same pattern repeats:
- `#Clients_EOD_Futures_Total_Trader` joins on `OrderID`
- Used to reconcile held futures positions across client, eToro hedge, and Marex LP sides

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `DWH_dbo.Dim_Position` | `OrderID`, `PositionID` | Client-side positions and orders |
| `CopyFromLake.etoro_Hedge_ExecutionLog` | `ExecutionID` → `EMSOrderID` | eToro hedge execution log |
| `Dealing_staging.LP_EdnF_PFDFST4_CUSTOM` | `Trader` → `CHIT NUMBER` | Marex trade records |
| `Dealing_staging.LP_EdnF_CorePosition` | `Trader` → `Trader` | Marex EOD position records |
| `Dealing_dbo.Dealing_Marex_Recon_Trades_Futures` | `OrderID` | Reconciliation output (trades) |
| `Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures` | `OrderID` | Reconciliation output (EOD holdings) |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Marex_Recon)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Trader | nvarchar(4000) | YES | Marex trader/chit identifier. This is the key that links eToro orders to Marex LP records. Format: `ETO-{alphanumeric}-{alphanumeric}` (e.g., `ETO-3YNN2H-KVRDPE`). Matched against `CHIT NUMBER` in Marex trade files. (Tier 2 — SP_Marex_Recon) |
| 2 | ExecutionID | bigint | YES | eToro Hedge Execution Management System (EMS) order ID. Joined to `etoro_Hedge_ExecutionLog.EMSOrderID` (after stripping the underscore suffix via `PATINDEX`). Uniquely identifies the hedge execution. (Tier 2 — SP_Marex_Recon) |
| 3 | PositionID | bigint | YES | eToro position ID from `Dim_Position`. Originally used as join key; replaced by `OrderID` in SR-338875. Still stored for reference but `OrderID` is the preferred join key. (Tier 2 — SP_Marex_Recon) |
| 4 | OrderID | int | YES | eToro platform order ID. **Primary join key** (since SR-338875) for linking to client-side futures positions in `Dim_Position.OrderID`. One position may have multiple orders (open + close). (Tier 2 — SP_Marex_Recon) |
| 5 | ExitOrderID | int | YES | eToro order ID for the position close. Together with `OrderID` (open), these represent both legs of a round-trip futures trade. NULL if the position is still open. (Tier 2 — DDL + live data) |
| 6 | OpenDateID | int | NOT NULL | DateID (YYYYMMDD) when the position was opened. The only NOT NULL column — every mapping must have an open date. (Tier 2 — DDL) |
| 7 | CloseDateID | int | YES | DateID (YYYYMMDD) when the position was closed. NULL if position is still open. (Tier 2 — DDL + live data) |
| 8 | UpdateDate | datetime2(7) | YES | Timestamp of the last update to this mapping row. Reflects when the Gold layer pipeline processed this record. (Tier 3 — live data) |

---

## 5. Usage Notes

**Join on OrderID, not PositionID**: Per SR-338875, always use `OrderID` for joining to client-side positions. The `PositionID` join was incorrect for futures because a single position can generate multiple orders.

**ExecutionID suffix stripping**: The SP strips the underscore suffix from EMSOrderID before joining: `CASE WHEN PATINDEX('%[_]%', EMSOrderID) > 0 THEN LEFT(EMSOrderID, CHARINDEX('_', EMSOrderID) - 1) ELSE EMSOrderID END`. The `ExecutionID` in this table is the clean numeric form.

**One Trader per OrderID**: The mapping is logically 1:1 between Trader and OrderID, but the SP uses `LEFT JOIN` and `DISTINCT` to handle any edge cases.

**Gold layer**: Data is curated in the Databricks Gold layer from production hedge execution logs and Marex confirmation data.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | Databricks Gold layer → `Gold/Dealing/Marex_Trader_OrderID/` |
| **Refresh** | Daily Gold layer pipeline (Databricks) |
| **SP Author** | Adar Cahlon (2024-04-18, SP_Marex_Recon) |
| **PII** | NO |
| **Owner** | Dealing / Quantitative Analytics |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Live Data | 5/5 | Active data with recent 2026-03 records |
| SP Logic | 5/5 | Full SP_Marex_Recon analyzed (1394 lines) — extensive join patterns documented |
| Upstream Wiki | 2/5 | No upstream wiki for Gold layer source |
| Business Context | 4/5 | Confluence pages on Marex futures recon found; SR-338875 fix documented |
| **Total** | **8.2/10** | |

---

*Generated: 2026-03-21 | Batch 19 | Schema: Dealing_dbo*
