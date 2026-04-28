# Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX

> **DEPRECATED (HOLD)** — eToroX exchange trade log, retired since SR-239249 (2024-03-04).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (HOLD) |
| **Status** | **Deprecated** |
| **Production Source** | Was: `MarketMaker.ExchangesData.Trades` |
| **Refresh** | None — no longer loaded |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on Date |

---

## 1. Business Meaning

This table recorded eToroX exchange hedge trade executions — the companion to `Dealing_MarketMakerAllTrade` (which covers standard LP trades). It was deprecated when the eToroX exchange was decommissioned.

The DDL file has been renamed to `HOLD_Dealing_MarketMakerAllTradeEtoroX.sql`. The loading section in `SP_MarketMakerAllTrade` is fully commented out since SR-239249 (2024-03-04, author: Gili).

---

## 2. Elements (Historical)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date |
| 2 | Id | int | YES | Trade ID from ExchangesData.Trades |
| 3 | CreationTime | datetime | YES | Trade creation time (note: different from ExecutionTime in parent table) |
| 4 | Instrument_Name | char(50) | YES | Instrument name |
| 5 | Name | char(50) | YES | Exchange name |
| 6 | Side | char(50) | YES | Buy/Sell |
| 7 | Price | float | YES | Trade price |
| 8 | Quantity | float | YES | Trade quantity |
| 9 | Funds | float | YES | `Price * Quantity` |
| 10 | ApiPrice | float | YES | API-requested price |
| 11 | APiQuantity | float | YES | API-requested quantity |
| 12 | ApiFunds | float | YES | `ApiPrice * ApiQuantity` |
| 13 | Fee | float | YES | Trade fee |
| 14 | FeeCurrency | char(50) | YES | Fee currency |
| 15 | PartyName | char(50) | YES | Counter-party |
| 16 | InsertTime | datetime | YES | Record insert time |
| 17 | OrderId | char(70) | YES | Order ID |
| 18 | TradeId | char(70) | YES | eToroX trade ID (unique to this table) |
| 19 | Unit | float | YES | Signed units |
| 20 | Value | float | YES | Net trade value |
| 21 | UpdateDate | datetime | YES | ETL timestamp |

---

*Generated: 2026-03-21 | Quality: 5.0/10 (★★☆☆☆) | Phases: 4/14*
*Status: DEPRECATED (HOLD) since SR-239249 | No new data since 2024-03-04*
*Object: Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX | Type: Table (HOLD)*
