# Review Needed — Dealing_dbo.Dealing_Staking_OptedOut_PerCID

**Batch**: 10 | **Date**: 2026-03-21 | **Quality**: 8.5/10

## Open Questions

1. **590M row retention policy**: At ~13M rows/day, this table will reach 1B rows within ~3 months. Is there a retention/purge policy? The SSDT DDL shows no partitioning. Queries on this table without Date predicates will time out.

2. **USD_Rate source**: The SP doesn't show an explicit external table source for USD rates. Where do exchange rates come from — a Dealing_staging table, an external table, or a different lookup?

3. **#OptedOut_PerCID build path**: The full lineage from BI_DB_dbo.BI_DB_PositionPnL → #OpenPositions → #OptedOut_PerCID involves multiple temp table transformations. A deeper read of SP_Staking_DailyPool (lines 90-250) would clarify the opt-in flag logic and the intro-day filtering. Recommend reading the full #EligiblePool and waiver join section for complete lineage.

4. **Consumer queries**: Does SP_Staking read this table directly, or does it use the #OptedOut_PerCID temp table recomputed each run? If it reads the stored table, queries need Date range predicates for performance.
