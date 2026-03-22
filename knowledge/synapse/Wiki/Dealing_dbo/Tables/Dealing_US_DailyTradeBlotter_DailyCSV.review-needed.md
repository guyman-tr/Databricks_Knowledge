# Review Needed: Dealing_US_DailyTradeBlotter_DailyCSV

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 17 |
| **Quality Score** | 6.5/10 |

## Automated Flags

- [ ] ⚠️ **STALE**: Data stopped 2025-01-13. SP_USTradeReports is not in OpsDB. Confirm SP scheduling status.
- [ ] **TRUNCATE pattern**: Every SP run truncates this table — all historical data is lost. Confirm this is expected behavior (CSV export use case).
- [ ] **PII**: `[Client Name]` contains customer full name. Confirm access controls.
- [ ] Includes 'Partial' fills (unlike `Dealing_US_DailyTradeBlotter` which is Filled-only). Confirm whether this is the intended distinction for the CSV export.
- [ ] `[Order Creation Time]` is UTC, other time columns are EDT — same issue as sibling table.
- [ ] Settlement Date always NULL and Fees/Net Commission always 0 — confirm this is expected.
- [ ] Atlassian MCP unavailable during documentation — Phase 10 skipped.

## Reviewer Corrections

<!-- Add reviewer corrections here. Mark resolved items with [RESOLVED] -->
