# DWH_dbo.V_Fact_RegulationTransfer

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[V_Fact_RegulationTransfer]` |
| **Type** | View |
| **Base Tables** | `Fact_RegulationTransfer` |
| **Purpose** | Converts the bidirectional regulation transfer table (From/To regulation) into a unidirectional format with a signed `TransferDirection` indicator (+1 inbound, −1 outbound) and a unified `RegulationID`. |

## 2. Business Context

When a customer is transferred between regulatory jurisdictions (e.g., EU to UK entity), `Fact_RegulationTransfer` stores a single row with both `FromRegulationID` and `ToRegulationID`. This view **doubles each row** via UNION ALL:

1. **Inbound** (`TransferDirection = 1`): `RegulationID` = `ToRegulationID` — the regulation receiving the customer
2. **Outbound** (`TransferDirection = -1`): `RegulationID` = `FromRegulationID` — the regulation losing the customer

This enables regulation-centric aggregation: each regulation sees its inflows and outflows as separate signed rows, facilitating net transfer calculations with `SUM(TransferDirection * Amount)`.

### Financial Snapshot at Transfer
Each transfer captures a full equity snapshot at the moment of transfer: positions, cash, mirror positions, stock orders, credit, AUM, and liability breakdowns. This ensures regulatory accounting can reconstruct balances pre- and post-transfer.

## 3. Elements

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | `TransferDirection` | int | `+1` = inbound (customer arriving), `−1` = outbound (customer leaving). Computed in view. (Tier 1 — view DDL) |
| 2 | `RegulationID` | int | Unified regulation FK. Maps to `ToRegulationID` for inbound, `FromRegulationID` for outbound. FK to Dim_Regulation. (Tier 1 — view DDL) |
| 3 | `Occurred` | datetime | Timestamp of the regulation transfer event. (Tier 2 — view DDL) |
| 4 | `DateID` | int | Date key (YYYYMMDD) of the transfer. (Tier 2 — view DDL) |
| 5 | `UnrealizedPnL` | money | Unrealized P&L at transfer time. (Tier 2 — view DDL) |
| 6 | `ActualNWA` | money | Net Withdrawable Amount at transfer time. (Tier 2 — view DDL) |
| 7 | `RealizedEquity` | money | Realized equity at transfer time. (Tier 2 — view DDL) |
| 8 | `CID` | int | Customer ID being transferred. FK to Dim_Customer. (Tier 2 — view DDL) |
| 9 | `TotalPositionsAmount` | money | Total CFD/manual position value. (Tier 2 — view DDL) |
| 10 | `TotalCash` | money | Cash balance. (Tier 2 — view DDL) |
| 11 | `InProcessCashouts` | money | Pending withdrawal amount. (Tier 2 — view DDL) |
| 12 | `TotalMirrorPositionsAmount` | money | Total copy-trading position value. (Tier 2 — view DDL) |
| 13 | `TotalMirrorCash` | money | Copy-trading cash balance. (Tier 2 — view DDL) |
| 14 | `TotalStockOrders` | money | Total stock order value. (Tier 2 — view DDL) |
| 15 | `TotalMirrorStockOrders` | money | Copy-trading stock orders. (Tier 2 — view DDL) |
| 16 | `Credit` | money | Credit balance. (Tier 2 — view DDL) |
| 17 | `AUM` | money | Assets Under Management. (Tier 2 — view DDL) |
| 18 | `BonusCredit` | money | Bonus credit balance. (Tier 2 — view DDL) |
| 19 | `TotalLiability` | money | Total company liability to customer. (Tier 2 — view DDL) |
| 20 | `WithdrawableLiability` | money | Withdrawable portion of liability. (Tier 2 — view DDL) |
| 21 | `LiabilityInUsedMargin` | money | Liability locked in used margin. (Tier 2 — view DDL) |
| 22 | `InvestedRealStocks` | money | Real (non-CFD) stock investment. (Tier 2 — view DDL) |
| 23 | `InvestedRealCrypto` | money | Real crypto investment. (Tier 2 — view DDL) |
| 24 | `PositionPnLStocksReal` | money | Unrealized P&L on real stocks. (Tier 2 — view DDL) |
| 25 | `PositionPnLCryptoReal` | money | Unrealized P&L on real crypto. (Tier 2 — view DDL) |
| 26 | `InvestedRealFutures` | money | Real futures investment. (Tier 2 — view DDL) |
| 27 | `PositionPnLFuturesReal` | money | Unrealized P&L on real futures. (Tier 2 — view DDL) |
| 28 | `InvestedStocksMargin` | money | Margin stock investment. (Tier 2 — view DDL) |
| 29 | `PositionPnLStocksMargin` | money | Unrealized P&L on margin stocks. (Tier 2 — view DDL) |
| 30 | `TotalStockMarginLoanValue` | money | Outstanding stock margin loan. (Tier 2 — view DDL) |

## 4. Known Issues

| Issue | Severity | Details |
|-------|----------|---------|
| NOLOCK hint | Medium | Both UNION ALL branches use `WITH (NOLOCK)` — may read uncommitted transfer records. |
| Row doubling | Info | Every base row produces 2 view rows — consumers must account for this when counting transfers vs. transfer events. |

---
*Generated: 2026-03-19 | Quality: 8.5/10 | Directional regulation transfer view*
