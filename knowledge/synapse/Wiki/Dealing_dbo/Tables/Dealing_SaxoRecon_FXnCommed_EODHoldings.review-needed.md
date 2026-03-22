# Review Needed: Dealing_SaxoRecon_FXnCommed_EODHoldings

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 17 |
| **Quality Score** | 7.0/10 |

## Automated Flags

- [ ] Special-character column names (`[SAXO-eToro_Units]`, `[SAXO-Clients_Units]`, `[SAXO-eToro_LocalAmount]`, `[SAXO-eToro_AmountUSD]`, `[SAXO-Clients_AmountUSD]`, `[SAXO-eToro_Rate]`) require bracket quoting in all queries.
- [ ] FX sign convention: `SAXO_LocalAmount = -QuotedValue` and `SAXO_AmountUSD = -Amount × EODRate × InstrumentToAccountRate`. Confirm whether downstream dashboards expect positive or signed values.
- [ ] Data only starts 2024-04-12 — confirm if this is expected (new table/process) or if there is pre-April-2024 data in a different table/location.
- [ ] `Account_Number` (with underscore) differs from `AccountNumber` in the Stocks Recon tables — flag for query authors joining across schemas.
- [ ] `eToro_FXRate` uses multi-step Bid/Ask chain for USD conversion — confirm this logic produces accurate values for exotic FX pairs.
- [ ] Fivetran mapping filter is `activity IN ('Currencies', 'Commodities')` — confirm current active HS/LA IDs. The mapping uses `DENSE_RANK() by update_date` to get the latest snapshot.
- [ ] Companion `Dealing_SaxoRecon_FXnCommed_Trades` is orphaned — confirm no FX trade-level reconciliation is being done, or identify where it moved.
- [ ] Atlassian MCP unavailable during documentation — Phase 10 skipped.

## Reviewer Corrections

<!-- Add reviewer corrections here. Mark resolved items with [RESOLVED] -->
