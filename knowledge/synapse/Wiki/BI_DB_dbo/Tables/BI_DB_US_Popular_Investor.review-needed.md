# BI_DB_dbo.BI_DB_US_Popular_Investor — Review Needed

## Tier 4 Items

1. **AllowDisplayFullName** (Tier 4): Column exists in DDL but is never populated by SP_US_Popular_Investor INSERT. Always NULL. Should it be dropped from DDL or is there a future plan to populate it?

## Questions for Reviewer

1. **AllowDisplayFullName orphan column**: The SP INSERT statement does not include this column. Is this intentional or a bug? Is another process expected to UPDATE it?
2. **35/35 activity requirement**: The SP requires SUM(Active)=35 over the last 35 days — zero tolerance for inactivity. Is this the correct threshold or should it be configurable?
3. **Risk score threshold mapping**: The StandardDeviation-to-score mapping uses hardcoded CASE WHEN brackets. Are these thresholds documented externally or subject to periodic review?
4. **Equity >= $100 gate**: The equity threshold is hardcoded at $100. Is this the official PI program minimum for US customers?
5. **No @Date parameter**: Unlike most SPs, this one uses yesterday internally. This prevents backfill or re-run for a specific date. Is this by design?
