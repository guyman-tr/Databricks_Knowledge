# Review Needed: Dealing_US_Stocks_SmartPortfolio

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 17 |
| **Quality Score** | 7.5/10 |

## Automated Flags

- [ ] Special-character column `[Units_NOP/Shares Outstanding]` requires bracket quoting in all queries.
- [ ] `IsBuy` is stored as a bit (1/0), not varchar 'Buy'/'Sell' — unlike most Dealing schema tables. Confirm whether downstream dashboards handle this correctly.
- [ ] Rankings data (ADV, SharesOutstanding) comes from `CopyFromLake.Rankings_StockInfo_InstrumentData` — confirm freshness cadence and whether stale Rankings data would silently produce incorrect concentration ratios.
- [ ] Exchange normalization: any exchange not matching Nasdaq/OTCMKTS variants defaults to 'NYSE'. Confirm whether this catches all edge cases (e.g., new exchange types added after the SP was written).
- [ ] Alert email logic: SP sends email when `Units_NOP/Shares Outstanding > 5`. Confirm current recipient list and whether alerts are still being sent post-migration (SR-234222, Feb 2024).
- [ ] `BI_DB_dbo.BI_DB_PositionPnL` is the position source — confirm whether this is the canonical position view or if there are known lag/staleness issues with this source for SmartPortfolio positions.
- [ ] Atlassian MCP unavailable during documentation — Phase 10 skipped.

## Reviewer Corrections

<!-- Add reviewer corrections here. Mark resolved items with [RESOLVED] -->
