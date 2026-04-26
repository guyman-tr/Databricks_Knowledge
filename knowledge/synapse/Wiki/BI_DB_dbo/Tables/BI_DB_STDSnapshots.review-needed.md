# Review Notes: BI_DB_dbo.BI_DB_STDSnapshots

**Generated**: 2026-04-22 | **Batch**: 34 | **Quality**: 9.5/10

## Tier 4 / Uncertain Items

None — all 5 columns traced to SP_User_Segment_Snapshot and Fact_CustomerUnrealized_PnL.

## Questions for SME Review

1. **Confluence page**: Section 8 notes no Confluence page found for this table. Is there a page for the user segmentation or risk scoring pipeline that documents the STD snapshot concept? If so, it should be linked.

2. **RiskIndex threshold values**: The SP uses specific AvgSTD thresholds (0.0011 through 0.0475) to bucket customers into RiskIndex 1–10. Are these thresholds static/hardcoded (as seen in the SP), or are they periodically reviewed and adjusted by the risk/analytics team?

3. **StandardDeviation data quality**: Live data shows a max StandardDeviation of ~36.4 against an average of ~0.007. The max is several hundred standard deviations above the mean — is this an expected outlier (extreme position on a single volatile instrument) or a known data quality issue in Fact_CustomerUnrealized_PnL?

4. **PositionPnL aggregation**: The DDL has `PositionPnL DECIMAL(16,2) NOT NULL` but the source `Fact_CustomerUnrealized_PnL` likely contains per-position rows. Is the SP doing a pre-aggregation (SUM by CID) or is Fact_CustomerUnrealized_PnL already one-row-per-customer? The SP reads `A.PositionPnL` directly without SUM — if the source is position-grain, this may produce duplicate CID rows.

## Corrections Applied

- None required. All columns confirmed from SP code.

## Ghost Columns

None identified. All 5 DDL columns are present in the SP INSERT list.
