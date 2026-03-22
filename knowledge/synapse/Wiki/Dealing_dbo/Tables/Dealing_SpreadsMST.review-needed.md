# Dealing_dbo.Dealing_SpreadsMST — Review Needed

| Property | Value |
|----------|-------|
| **Wiki File** | [Dealing_SpreadsMST.md](Dealing_SpreadsMST.md) |
| **Quality Score** | 8.0/10 |
| **Review Priority** | Low |

---

## Open Questions

1. **MST threshold business meaning**: What determines the `MarketSpreadThreshold` value per instrument? Is it set manually by the Dealing desk, derived from a formula, or sourced from a third-party? The SP sources it from `External_Etoro_Trade_InstrumentSpread` but no documentation exists on how the upstream value is set.

2. **'PrecentageSpread' typo in source**: The SpreadsType value 'PrecentageSpread' (89% of rows) is a known typo in `External_Etoro_Dictionary_SpreadType.Name`. Has there been any effort to fix this at the source? Any downstream systems that depend on the exact string value would break if corrected.

3. **VisibleInternallyOnly=1 instruments**: What are the ~23.5% of rows with `VisibleInternallyOnly = 1`? Are these instruments in a specific test/pilot state, or are they permanently internal? Is the Dealing team actively monitoring spreads on these?

4. **ReferenceBid / ReferenceAsk source**: Where do the reference bid/ask prices come from in `External_Etoro_Trade_InstrumentSpread`? Is this a separate pricing feed, a prior-day close, or something configured manually?

5. **SpreadThresholdTypeID always 1**: Is there a plan to use other threshold types? If this field will never vary, should it be dropped in a future schema version?

---

## Verification Needed

- Confirm that `SP_SpreadsMST` is the only writer (no bulk loads or manual inserts).
- Confirm that the `FeedID = 1` filter in the SP matches the intent — are there multi-feed instruments that should be included?
