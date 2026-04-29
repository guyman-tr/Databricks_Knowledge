# BI_DB_dbo.BI_DB_AffiliateLifeCycle — Review Needed

## Tier 4 Items (require human verification)

| Column | Current Tier | Question |
|--------|-------------|----------|
| All 31 non-ETL columns | Tier 4 | No writer SP, no data — descriptions inferred from column names and lifecycle domain patterns |

## Questions for Reviewer

1. **Decommission candidate**: 0 rows, no SP references. Should this table be dropped?
2. **Was this ever populated?**: Was the lifecycle analysis active on on-prem BI_DB? What tool/system runs it now?
3. **Segment values**: What are the actual segment classifications? Numeric ranges (0, 1-5, 6-20)? Named tiers?
4. **ActivitySegment values**: What are the valid states? Active/Sleeping/Churned/New? Or different?
5. **TrafficActivity values**: What are the traffic levels? High/Medium/Low/Dormant? Numeric thresholds?
6. **Financial columns as int**: TotalCost/RevShare/TotalRevenues stored as int — were these in whole currency units? Or were they multiplied by 100?
7. **rn column**: Was this a window function ROW_NUMBER() used for dedup? Or a meaningful business field?

## Dormant Table Assessment

- **Evidence**: 0 rows, no writer SP, no reader SP, no references in any SP
- **Most complex affiliate table**: 33 columns with state machine, cohort analysis, and P&L
- **Recommendation**: Despite being the most analytically rich affiliate table, it's never been populated in Synapse. Either the logic lives elsewhere or the project was abandoned.
