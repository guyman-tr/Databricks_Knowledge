# Lineage — Dealing_dbo.External_Fivetran_dealing_overnight_fees

## Source Mapping

| Layer | Object | Method |
|-------|--------|--------|
| **Fivetran** | Bloomberg futures pricing connector | Fivetran sync to Synapse |
| **External** | Bloomberg terminal / data feed | Futures closing prices |

## Column Lineage

| Column | Source | Confidence |
|--------|--------|------------|
| _row | Fivetran metadata | Tier 3 |
| _fivetran_synced | Fivetran metadata | Tier 3 |
| future_short_cut | Bloomberg root ticker | Tier 2 — SP logic confirms partitioning role |
| ticker | Bloomberg full ticker | Tier 2 — SP logic confirms sort-based front/next assignment |
| days | Bloomberg contract metadata | Tier 2 — SP uses as fee denominator |
| close | Bloomberg closing price | Tier 2 — SP uses for fee numerator (Next - Front) |
| instrument_id | Mapped to eToro InstrumentID | Tier 2 — SP joins on this to positions |
| date | Bloomberg trading date | Tier 2 — SP filters by date |
| update_date | Source update timestamp | Tier 2 — SP uses for deduplication |

## Downstream Consumers

| Consumer | Usage |
|----------|-------|
| `SP_Islamic_Spot_Price_Adjustment` | Primary: reads front/next futures prices to calculate Islamic spot price adjustment fees |
| `SP_Islamic_Spot_Price_Adjustment_Backup` | Backup version of the same SP |
| `Dealing_Islamic_Daily_Spot_Price_Adjustment` | Output: receives calculated fees |
| `Dealing_Islamic_Daily_Spot_Price_Adjustment_Email` | Alert: notified when no data for a trading day |

---

*Generated: 2026-03-21 | Batch 19*
