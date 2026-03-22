# Review Needed: Dealing_SaxoRecon_FXnCommed_Trades

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 17 |
| **Quality Score** | 4.0/10 |

## Automated Flags

- [ ] ⛔ **ORPHANED TABLE** — No writer SP in SSDT codebase. Data stopped 2023-12-05. Confirm whether this table has been formally decommissioned.
- [ ] All column descriptions are Tier 4 (inferred) — no SP code available to verify. Treat all descriptions as approximations.
- [ ] Special-character column names (`[SAXO-eToro_Units]`, `[SAXO-Clients_Units]`, `[SAXO-eToro_Rate]`, `[SAXO-eToro_AmountUSD]`, `[SAXO-Clients_AmountUSD]`) require bracket quoting.
- [ ] `Commission` column currency is unknown (USD or local?) — no SP code to verify.
- [ ] `Side` column values — confirm 'Buy'/'Sell' or some other string.
- [ ] Atlassian MCP unavailable during documentation — Phase 10 skipped.

## Reviewer Corrections

<!-- Add reviewer corrections here. Mark resolved items with [RESOLVED] -->
