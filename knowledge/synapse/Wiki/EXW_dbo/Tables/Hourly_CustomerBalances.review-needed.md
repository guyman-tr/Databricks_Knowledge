# EXW_dbo.Hourly_CustomerBalances — Review Needed

**Generated**: 2026-04-20 | **Quality**: 8.7/10 | **Phase 16 evaluator**: Pending

## Tier 4 Items (Low-Confidence — Reviewer Verification Needed)

None — all 7 columns are Tier 2 with clear SP traceability. No upstream wiki exists for WalletDB_Wallet_V_BI_WalletBalances.

## Open Questions for Reviewer

1. **today-2 missing Balance <> 0 filter**: The SP applies `AND Balance <> 0` for today, today-1, and today-3 snapshots, but the today-2 UNION ALL member has no such filter. Confirm whether this is intentional (to capture zero-balance states at T-2 for change detection) or an oversight from an SP edit.

2. **No documented downstream consumer**: The SP description mentions Tableau KPI dashboards but no specific Tableau workbook or Synapse consumer SP is referenced. Confirm the current Tableau workbook(s) that query this table, so that schema changes can be assessed for impact.

3. **USDBalance uses daily price, not hourly**: Despite the SP running hourly, USDBalance = UnitBalance × #DailyPrices.AvgPrice (daily granularity). Confirm whether the Tableau dashboard consuming this table expects hourly or daily price precision for USD values.

4. **6 hardcoded BlockchainProviderWalletId exclusions**: The SP excludes 6 specific provider wallet IDs (e.g., '3DaGV5NoQqTANQjT3ZgCQVzvnyntgyiXFT'). Confirm whether these are static internal/hot wallets that will not change, or whether this exclusion list needs periodic maintenance as the wallet infrastructure evolves.

## Carry-Forward Notes

- Per-crypto aggregate only — no GCID-level breakdown available in this table.
- Rolling 4-day window; history beyond 4 days must be sourced from EXW_FactBalance.
- today-2 zero-balance inconsistency flagged above.
- HASH(CryptoID) distribution is unusual given low cardinality — full scans are inexpensive.
