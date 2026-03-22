# Lineage — Dealing_dbo.V_Dealing_DealingDashboard_Clients

## Source Mapping

| Layer | Object | Method |
|-------|--------|--------|
| **View** | `Dealing_dbo.Dealing_DealingDashboard_Clients` | SELECT * WITH (NOLOCK) WHERE DateID > 20211231 |

## Column Lineage

All columns pass through from `Dealing_DealingDashboard_Clients` — see [base table lineage](../Tables/Dealing_DealingDashboard_Clients.lineage.md).

## Downstream Consumers

| Consumer | Usage |
|----------|-------|
| `SP_Regime_Flags` | Reads TotalZero, TotalVolume, NOP for client regime classification |
| Dealing Dashboard (Tableau/BI) | Primary data source for dashboard visualizations |

---

*Generated: 2026-03-21 | Batch 20*
