# BI_DB_dbo.BI_DB_rsk_Risk_PI_Stats — Review Needed

## Questions for Reviewer

1. IsBuyPercent uses MirrorID=0 (manual positions only) — should copy positions also be considered?
2. TotalProfit uses MirrorTypeID=1 for closed position NetProfit — does this exclude copyfund closes?
3. The %AUM denominator is SUM(AUM) across the PI population — is this cross-validated with BI_DB_rsk_DailyRiskAgg.CopyAUM?

## Validation Notes

- Column count: 25 DDL = 25 wiki elements (MATCH)
- All 8 sections present
- Tier distribution: 0 T1, 24 T2, 0 T3, 0 T4, 1 T5
