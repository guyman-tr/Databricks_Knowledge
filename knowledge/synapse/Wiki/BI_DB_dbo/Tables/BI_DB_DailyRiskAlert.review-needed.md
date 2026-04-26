# BI_DB_dbo.BI_DB_DailyRiskAlert — Review Needed

## Data Quality Issues

1. **InactiveFeedPoster = 1 for ALL 5,433 rows**: The ISNULL(LastPublishedPostDate, '1900-01-01') default causes universal trigger. Either LastPublishedPostDate is always NULL in BI_DB_CIDFirstDates, or this flag is broken. Review with Bar (SP author).

2. **BuyPercent/SellPercent labels are SWAPPED**: SP maps IsBuy=0 → BuyPercent and IsBuy=1 → SellPercent. In eToro convention, IsBuy=1 means Buy. The labels in the SP code are reversed. This may be intentional (legacy behavior) or a bug — verify with the risk team.

3. **DDL typos**: `MaxRisckScore2Months` ("Risck") and `Value_percenet` ("percenet") are preserved from production DDL. Not actionable — just awareness.

4. **Stale SELECT statement in SP**: Line 382 `select * from #ActiveloginPIs WHERE RealCID=5564235` — debug statement left in production SP code. Returns results that are discarded. No functional impact but should be cleaned up.

## Open Questions

1. Is the InactiveFeedPoster flag supposed to be this broadly triggered, or should it exclude PIs who never posted?
2. Are BuyPercent/SellPercent consumed by any downstream dashboard with the current (swapped) labeling? Fixing the SP might break downstream consumers.
3. The SP uses no @date parameter — it hardcodes `DECLARE @date DATE = GETDATE()-1`. Unlike other SPs, it cannot be re-run for historical dates.
4. Tier=NULL for 25% of PIs means BI_DB_DailyPanel_Copy doesn't have their DateID row. Is this a timing issue (DailyRiskAlert runs before DailyPanel_Copy)?

## Cross-Object Consistency

- CID description matches DWH_dbo.Dim_Customer wiki for RealCID (Tier 1) ✓
- UserName description matches Dim_Customer wiki (Tier 1) ✓
- RiskScore derived from DWH_CIDsDailyRisk — no wiki for that table yet
