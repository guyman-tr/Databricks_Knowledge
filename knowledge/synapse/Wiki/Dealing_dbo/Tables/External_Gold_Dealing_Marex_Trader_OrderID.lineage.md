# Lineage — Dealing_dbo.External_Gold_Dealing_Marex_Trader_OrderID

## Source Mapping

| Layer | Object | Method |
|-------|--------|--------|
| **Gold (Data Lake)** | `Gold/Dealing/Marex_Trader_OrderID/*.parquet` | External table (Synapse PolyBase) |
| **Databricks** | Gold layer pipeline | Curates mappings from hedge execution logs + Marex confirmations |
| **Production** | `etoro_Hedge_ExecutionLog` + Marex PFDFST4 | Raw source data |

## Column Lineage

| Column | Source | Confidence |
|--------|--------|------------|
| Trader | Marex LP trade records (CHIT NUMBER equivalent) | Tier 2 — SP_Marex_Recon join confirms |
| ExecutionID | `etoro_Hedge_ExecutionLog.EMSOrderID` | Tier 2 — SP_Marex_Recon join confirms |
| PositionID | `DWH_dbo.Dim_Position.PositionID` | Tier 2 — DDL |
| OrderID | `DWH_dbo.Dim_Position.OrderID` | Tier 2 — SP_Marex_Recon primary join key |
| ExitOrderID | Close-leg order ID from position lifecycle | Tier 3 |
| OpenDateID | Position open date | Tier 2 — DDL (NOT NULL) |
| CloseDateID | Position close date | Tier 2 — DDL |
| UpdateDate | Pipeline processing timestamp | Tier 3 |

## Downstream Consumers

| Consumer | Usage |
|----------|-------|
| `SP_Marex_Recon` | Primary: joins Trader↔OrderID for client-side trade matching; joins Trader↔ExecutionID for hedge-side matching |
| `SP_Marex_Recon_only_for_rerun` | Rerun variant of the same reconciliation |
| `Dealing_Marex_Recon_Trades_Futures` | Output: reconciliation results (trades) |
| `Dealing_Marex_Recon_EODHoldings_Futures` | Output: reconciliation results (EOD) |

---

*Generated: 2026-03-21 | Batch 19*
