---
object: EXW_dbo.EXW_EOMReportingBalances
review_date: 2026-04-20
batch: 12
priority: MEDIUM — decommissioned table, all Tier 4
---

# Review Notes — EXW_EOMReportingBalances

## Key Observations

1. **DECOMMISSIONED**: Last data is Sep-2023 (loaded 2023-10-15). No new data expected. Historical archive only.

2. **No writer SP in SSDT**: External ETL pipeline (Python/ADF) is the only writer. All 44 columns are Tier 4 — no SP code to trace the exact transformation logic.

3. **All 44 columns Tier 4**: Quality score 7.8/10 reflects the limitation. To improve, the external ETL code would need to be found and analyzed.

## Tier 4 Items Needing Clarification

4. **[Reporting Balance] vs [Closing Units Balance] rule**: Is the exact rule for KnownIssueWallet correction: `IF KnownIssueWallet=1 THEN use DevReportBalance ELSE use ClosingBalance`? Confirm from the ETL code.

5. **[TrackerBalance] source**: BitGo or Blox? In EXW_FinanceReportsBalancesNew, both BitGo (ProviderValue) and Blox (WalletTrackerValue) are used with a priority rule. The EOM table has only one TrackerBalance column — which provider is it?

6. **KnownIssueWallet=1 meaning**: What makes a wallet a "known issue"? Is it a curated list, or automatically flagged by the reconciliation engine?

7. **[Test accounting classifier] values**: Observed 0 and 1 in the data. Any other valid values?

8. **XRP Destination Tag format**: `rGREA8Ffr5XhaHCxgyDoTkqwpnvWunLGwc?dt=0` — confirm this is the standard format for all XRP addresses in this table.

9. **EXW_ReportingBalances relationship**: The DDL structure suggests EXW_ReportingBalances was prepared as the successor. Was the EOM table explicitly deprecated and replaced? Or was the whole regulatory reporting process moved to a different system entirely?

## DDL Notes

- `[ Closing Balance Date]` has a leading space — DDL typo
- `[LTD Units Recieved]` and `[MTD Units Recieved]` — missing 'n' — DDL typo (same in both tables)
- Multiple columns use `0E-8` representation for zero decimal values (normal SQL behavior for numeric/decimal types)
- `[UserWalletAllowance]` is nchar(50) — trailing space padding makes exact-match queries fail without RTRIM
