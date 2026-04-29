# BI_DB_dbo.BI_DB_Stocks_Opportunities — Review Needed

## Tier 4 / Unverified Items

- None — all columns traced to SP code and upstream wikis.

## Questions for Reviewer

1. **FirstAction JOIN by Name**: The SP joins BI_DB_First5Actions on `di.Name = fa.FirstInstrument` (instrument name string match, not InstrumentID). Could this miss instruments where Name differs from FirstInstrument? Is this intentional?
2. **14-day retention**: Is the 14-day window sufficient for marketing analysis, or do downstream consumers need longer history?
3. **IndustryGroup fallback**: ISNULL(IndustryGroup, Industry) — are there cases where both are NULL, leaving IndustryGroup empty for instrument-level rows?
4. **UC migration**: Not in Generic Pipeline mapping. Is migration planned?

## Corrections Applied

- None.

## Atlassian

- Atlassian search unavailable (permission denied).
