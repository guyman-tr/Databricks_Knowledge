# Review Notes: Dealing_FactSet_Daily

## Auto-generated flags

| # | Flag | Detail |
|---|------|--------|
| 1 | STALE since 2024-06-04 | Confirm with Dealing team whether FactSet integration was officially discontinued or paused — and whether there is a replacement data feed |
| 2 | TRUNCATE pattern | Table always contains only current snapshot — confirm downstream tools are aware that historical date-filtered queries will return no data for past dates |
| 3 | Not a PI anymore rows | Special deregistration rows have NULL position columns — confirm downstream FactSet consumers handle this gracefully |
| 4 | DailyLastSentDate tracking | SP_FactSet_Daily uses DailyLastSentDate<@Date — after TRUNCATE, does it update DailyLastSentDate in the management table? |
