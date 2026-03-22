# Review Needed: Dealing_SAXORecon_EODHoldings

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 17 |
| **Quality Score** | 7.5/10 |

## Automated Flags

- [ ] `eToro_AmounUSD` column name has a typo (missing 't'). Confirm this is intentional/preserved from DDL — do NOT rename if downstream queries rely on it.
- [ ] Special-character column names (`[Buy/Sell]`, `[SAXO-eToro_Units]`, `[SAXO-Clients_Units]`, `[eToro-SAXO_Rate]`, `[illiquid/liquid]`, `[Reality-Supposed]`, `[Reality-Client]`) require bracket quoting in all queries. Flag for downstream query authors.
- [ ] HedgeServerID values (35, 128, NULL) — confirm current active SAXO account mapping. The SP now uses Fivetran mapping (SR-282189, Nov 2024). Verify that HS 35 and 128 are still the active accounts.
- [ ] SAXO LP file date staleness guard: if SAXO doesn't deliver a file for a given date, the SP silently uses the previous available date. This can cause the table to have incorrect dates. Confirm if this is expected behavior.
- [ ] `MaxTradeDate` is in YYYYMMDD integer format (e.g., 20260212) — confirm whether consuming dashboards handle this correctly.
- [ ] Atlassian MCP unavailable during documentation — Phase 10 skipped. Review for any Confluence/Jira context about this table.

## Reviewer Corrections

<!-- Add reviewer corrections here. Mark resolved items with [RESOLVED] -->
