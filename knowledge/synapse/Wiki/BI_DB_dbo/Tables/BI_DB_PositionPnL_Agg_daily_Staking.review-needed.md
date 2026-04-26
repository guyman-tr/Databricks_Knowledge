# Review Needed — BI_DB_dbo.BI_DB_PositionPnL_Agg_daily_Staking

**Generated**: 2026-04-21 | **Batch**: 12 | **Quality**: 8.5/10

## Tier 4/5 Items Requiring Review

### 1. IsSettled semantics (Tier 2 — review desirable)
- Described as "1 = real/settled asset, 0 = CFD". This matches BI_DB_PositionPnL's Tier 5 characterisation. For staking instruments (ADA, TRX), only real/settled positions make business sense — but distribution shows IsSettled=0 exists (623K + 413K rows). Reviewer should confirm whether IsSettled=0 for staking instruments represents a CFD staking product or a data anomaly.

### 2. UK prohibition date threshold
- Hard-coded as `>= '2022-02-08'` in SP. The actual FCA ban on retail crypto products was announced in January 2021 and took effect October 2021 for most products; staking/yield products may have a different effective date. Reviewer should confirm the 2022-02-08 threshold is the correct FCA staking restriction date for eToro.

### 3. UpdateDate NULL pattern
- UpdateDate is NULL for new inserts (SP does not SET it). Legacy rows have values around 2022-02-27. Reviewer should confirm whether the NULL pattern is intentional or a bug — if intentional, UpdateDate effectively means nothing for recent data.

### 4. CountryID=218 = UK
- Assumed CountryID=218 is United Kingdom based on FCA regulatory context. Reviewer should verify this against DWH_dbo.Dim_Country if accuracy is critical.

## Questions for Domain Expert

1. Are both ADA (100017) and TRX (100026) the complete set of staking instruments, or will other crypto staking instruments be added in the future? (The SP is hard-coded — adding new instruments requires SP code change.)
2. Does `SP_Staking_Daily_Email_for_labs` send this data to an internal Labs Slack/email? What is the downstream consumption pattern?
3. Is this table used in any regulatory submissions directly, or only as an input to compliance reports?

## No ALTER Script Generated

ALTER script deferred to `/generate-alter-dwh` pass. UC Target = `_Not_Migrated`, so no ALTER will be generated unless UC migration occurs.
