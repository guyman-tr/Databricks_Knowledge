# Review Needed: Dealing_dbo.Dealing_Execution_Slippage

## Pipeline Staleness

- **STALE since 2024-10-03**. Root cause: Kusto LP price feed (`CopyFromLake.PricesFromProvider_MarketCurrencyPrice`) stopped supplying data. The RequestTime variant (`Dealing_Execution_Slippage_RequestTime`) continued until 2025-01-11 as it does not depend on Kusto.
- Confirm whether this pipeline will be restored or formally deprecated in favor of the RequestTime variant.

## Hedging Mode Change

- HBC (Hedge By Company) hedging mode disappeared from data after 2023-12-19. Only CBH remains in 2024. Confirm whether this is a business change (HBC routing discontinued) or a data issue.

## InstrumentID Tier Assignment

- InstrumentID assigned Tier 1 (Trade.Instrument) for consistency with sibling table `Dealing_Execution_Slippage_RequestTime`. The column value originates from `Dealing_staging.Etoro_Hedge_ExecutionLog` (unresolved) but represents the same InstrumentID FK used across the platform. Reviewer may prefer Tier 2 if strict provenance from ExecutionLog is desired.

## UC Migration

- No Generic Pipeline mapping exists for this table. UC target marked as `_Not_Migrated`. Confirm whether migration is planned or if this table is considered legacy given its stale status.

## Unresolved Staging Sources

The following staging/lake tables have no wiki documentation:
- `Dealing_staging.Etoro_Hedge_ExecutionLog` — raw hedge execution records
- `CopyFromLake.PriceLog_History_CurrencyPrice` — eToro price snapshots
- `CopyFromLake.PricesFromProvider_MarketCurrencyPrice` — Kusto LP market prices
- `Dealing_staging.Etoro_Hedge_HBCOrderLog` — HBC order classification

Column descriptions for columns sourced from these tables are Tier 2 (derived from SP code analysis). If wikis become available for these sources, descriptions could be upgraded to Tier 1.

## Slippage Sign Convention

- The opposite-sign convention between `Slippage` (points, positive = cost) and `SlippageInDollar` (USD, positive = gain) is documented but may confuse analysts. Consider adding a view or computed column for clarity if this table is actively used.
