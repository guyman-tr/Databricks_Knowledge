# Review Needed: Dealing_SAXORecon_Hedging

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 17 |
| **Quality Score** | 4.5/10 |

## Automated Flags

- [ ] ⛔ **ORPHANED TABLE** — No writer SP in SSDT codebase. Data stopped 2023-05-17. Confirm whether this table has been formally decommissioned or if there is a replacement outside of SSDT.
- [ ] All column descriptions are Tier 4 (inferred) — no SP code available to verify. All descriptions should be treated as approximations only.
- [ ] Special-character column `[Buy/Sell]` requires bracket quoting in queries.
- [ ] Confirm whether hedging monitoring logic was absorbed into `Dealing_SAXORecon_EODHoldings.[SAXO-eToro_Units]` / `[Reality-Supposed]` as inferred from the May 2023 SP restructuring.
- [ ] Atlassian MCP unavailable during documentation — Phase 10 skipped. Review for any Confluence/Jira context about decommissioning.

## Reviewer Corrections

<!-- Add reviewer corrections here. Mark resolved items with [RESOLVED] -->
