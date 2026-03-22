# Review Needed: Dealing_US_DailyTradeBlotter

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 17 |
| **Quality Score** | 6.5/10 |

## Automated Flags

- [ ] ⚠️ **STALE**: Data stopped 2025-01-13. SP_USTradeReports is not in OpsDB. Confirm whether this SP is still run on demand, was decommissioned, or moved to a different scheduler.
- [ ] **PII**: `[Client Name]` contains customer full name (FirstName + LastName). Confirm data access controls and whether this table is excluded from any data residency/GDPR scans.
- [ ] `[Order Creation Time]` is stored in UTC (not EDT), unlike all other time columns which are in EDT (`DATEADD(HOUR,-4,...)`). Flag for downstream report consumers to avoid mixed-timezone comparisons.
- [ ] Settlement Date is always NULL — confirm whether this is by design (Apex settlement not tracked in DWH) or a gap.
- [ ] Fees and Net Commission are hardcoded to 0 — confirm this is expected (no fee capture) or if these should be populated from a different source.
- [ ] `IsCopy` logic: 'Copy' when `MirrorID > 0`. Confirm whether this accurately reflects all copy/mirror portfolio scenarios, especially after any CopyTrading model changes.
- [ ] Side inversion logic for close orders: `CASE WHEN c.ExecutionID IS NOT NULL AND IsBuy=1 THEN 'S' ELSE 'B' END` — confirm this is correct for regulatory reporting (selling to close = 'S').
- [ ] 408.7M rows: Confirm table size management approach — is there a retention policy or archive plan?
- [ ] Multiple special-character column names require bracket quoting in all downstream SQL.
- [ ] Atlassian MCP unavailable during documentation — Phase 10 skipped. This table likely has Confluence documentation given it is a regulatory report.

## Reviewer Corrections

<!-- Add reviewer corrections here. Mark resolved items with [RESOLVED] -->
