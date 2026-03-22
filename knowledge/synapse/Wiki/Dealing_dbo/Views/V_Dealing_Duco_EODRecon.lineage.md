# Lineage — Dealing_dbo.V_Dealing_Duco_EODRecon

## Source Mapping

| Layer | Object | Method |
|-------|--------|--------|
| **View** | `Dealing_dbo.Dealing_Duco_EODRecon` | SELECT DISTINCT * + alias WHERE Date >= '2023-01-01' |

## Column Lineage

All columns pass through from `Dealing_Duco_EODRecon` plus one alias:

| Column | Source | Confidence |
|--------|--------|------------|
| BuyOrSell | Alias for `[Buy/Sell]` column | Tier 2 — DDL |

See [base table lineage](../Tables/Dealing_Duco_EODRecon.lineage.md) for all other columns.

## Downstream Consumers

| Consumer | Usage |
|----------|-------|
| Duco reconciliation platform | Automated EOD recon |

---

*Generated: 2026-03-21 | Batch 20*
