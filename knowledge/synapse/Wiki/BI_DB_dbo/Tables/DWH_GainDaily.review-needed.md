# BI_DB_dbo.DWH_GainDaily — Review Needed

## Tier 4 Items (Low Confidence)

None — all columns traced to SP code.

## Questions for Reviewer

1. **6.25B rows**: The largest BI_DB table. Archival of pre-2020 data would reduce by ~50%. Is historical daily gain used by any active consumer?
2. **ObjectID=4**: What are the other ObjectIDs in the Ranking_Execution table? Are there other gain flavors (e.g., risk-adjusted, per-instrument)?
3. **IntervalTypeID completeness**: Sample shows some Gain_w and Gain_d as NULL even for recent dates. Is this expected (customer hasn't traded in the interval period)?
4. **Gain <> 0 filter**: Excluding zero-gain rows means dormant customers have no row for that date. Is this the desired behavior for consumers that need a "full population" view?
5. **HASH(CID) distribution**: This is unusual for BI_DB_dbo tables (most are ROUND_ROBIN). Was this chosen specifically for co-located JOINs?

## Corrections Applied

- DDL shows 13 columns (batch assignment said 14 — confirmed 13 from SSDT DDL).
