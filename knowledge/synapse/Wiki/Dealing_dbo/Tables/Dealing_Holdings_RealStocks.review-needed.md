# Review Needed: Dealing_Holdings_RealStocks

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 17 |
| **Quality Score** | 8.0/10 |

## Automated Flags

- [ ] HedgeServer IDs hardcoded: Real HS (3,9,102,128,112,125,126) and CFD HS (2,101,129). Confirm whether all currently active hedge servers are included. If new accounts were added after the SP was last modified (SR-218293, Nov 2023), they may be missing.
- [ ] `ISIN` column named differently from `ISINCode` used in most other Dealing schema tables — flag for join queries across schemas.
- [ ] `Amount_USD` uses eToro's internal Fact_CurrencyPriceWithSplit EOD prices (Bid/Ask), not SAXO LP rates. Confirm whether BNY Mellon expects eToro prices or market prices for this report.
- [ ] CFD positions (IsSettled='CFD') included in this table — confirm whether BNY Mellon requires CFD data or only Real positions.
- [ ] Temporal reconstruction boundary: `UpdateTime < @Date+1` for current table; `SysEndTime >= @Date+1` for history. Confirm there are no gaps or overlaps at midnight boundaries.
- [ ] Atlassian MCP unavailable during documentation — Phase 10 skipped. This table likely has Confluence documentation given it is a BNY Mellon custodian report.

## Reviewer Corrections

<!-- Add reviewer corrections here. Mark resolved items with [RESOLVED] -->
