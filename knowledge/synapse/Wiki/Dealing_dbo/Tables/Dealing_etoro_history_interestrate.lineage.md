# Lineage — Dealing_dbo.Dealing_etoro_history_interestrate

## Source Mapping

| Layer | Object | Method |
|-------|--------|--------|
| **Bronze (Data Lake)** | `/Bronze/etoro/History/InterestRate/**` | External table (Synapse PolyBase) |
| **Production** | `etoro.History.InterestRate` | Fivetran/pipeline ingestion to Bronze |

## Column Lineage

| Column | Source | Confidence |
|--------|--------|------------|
| InterestRateID | History.InterestRate.InterestRateID | Tier 3 |
| InterestRateName | History.InterestRate.InterestRateName | Tier 3 |
| InterestRate | History.InterestRate.InterestRate | Tier 3 |
| UpdatedByUser | History.InterestRate.UpdatedByUser | Tier 3 |
| BeginTime | History.InterestRate.SysStartTime (temporal) | Tier 3 |
| EndTime | History.InterestRate.SysEndTime (temporal) | Tier 3 |
| InstrumentTypeID | History.InterestRate.InstrumentTypeID | Tier 3 |
| InterestRateBuy | History.InterestRate.InterestRateBuy | Tier 3 |
| InterestRateSell | History.InterestRate.InterestRateSell | Tier 3 |
| MarkupBuy | History.InterestRate.MarkupBuy | Tier 3 |
| MarkupSell | History.InterestRate.MarkupSell | Tier 3 |
| OverNightFeePatternID | History.InterestRate.OverNightFeePatternID | Tier 3 |
| SettlementTypeID | History.InterestRate.SettlementTypeID | Tier 3 |

## Downstream Consumers

| Consumer | Usage |
|----------|-------|
| `SP_Islamic_Spot_Price_Adjustment` | Rate configuration reference (conceptual — SP uses `External_Fivetran_dealing_overnight_fees` for futures prices) |
| `SP_Islamic_Spot_Price_Adjustment_Backup` | Backup version of the same SP |

---

*Generated: 2026-03-21 | Batch 19*
