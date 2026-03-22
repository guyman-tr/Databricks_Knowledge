# Review Needed: Dealing_SAXORecon_Trades

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 17 |
| **Quality Score** | 7.5/10 |

## Automated Flags

- [ ] Special-character column names (`[Buy/Sell]`, `[SAXO-eToro_Units]`, `[SAXO-Clients_Units]`, `[SAXO-eToro_Rate]`, `[SAXO-eToro_LocalAmount]`, `[SAXO-eToro_AmountUSD]`, `[SAXO-Clients_AmountUSD]`) require bracket quoting in all queries. Flag for downstream query authors.
- [ ] Note `eToro_AmountUSD` here has NO typo (unlike the sibling `eToro_AmounUSD` in `Dealing_SAXORecon_EODHoldings`). Verify that downstream queries don't accidentally use the wrong column name from the wrong table.
- [ ] GBX→GBP currency normalization in join logic was added July 2024 — confirm whether historical rows prior to that date may have mismatched joins (GBX rows unmatched with SAXO GBP rows).
- [ ] `Total_Commission` and `Total_Commission_Dollar` were added May 2023 — rows before that date will have NULL or 0 for these columns.
- [ ] HedgeServerID values (35, 128) — confirm current active SAXO account mapping via Fivetran. Same concern as EODHoldings.
- [ ] Atlassian MCP unavailable during documentation — Phase 10 skipped. Review for any Confluence/Jira context about this table.

## Reviewer Corrections

<!-- Add reviewer corrections here. Mark resolved items with [RESOLVED] -->
