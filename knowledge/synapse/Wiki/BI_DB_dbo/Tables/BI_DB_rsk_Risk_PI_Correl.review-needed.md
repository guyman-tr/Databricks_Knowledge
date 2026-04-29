# BI_DB_dbo.BI_DB_rsk_Risk_PI_Correl — Review Needed

## Questions for Reviewer

1. The Cartesian product generates symmetric pairs (A,B) and (B,A) — is deduplication handled at the dashboard level?
2. Self-pairs (CID1=CID2, Pearson=1.0) are stored — are they used or should they be filtered?
3. SampleSize >= 200 filter on Dim_Instrument_Correlation — what happens for new/illiquid instruments?
4. The 2-year rolling retention purges old data — is there a historical archive?

## Validation Notes

- Column count: 22 DDL = 22 wiki elements (MATCH)
- All 8 sections present
- Tier distribution: 0 T1, 21 T2, 0 T3, 0 T4, 1 T5
