# Review Needed — Dealing_VisionRecon_Trades

**Generated**: 2026-03-21
**Quality Score**: 7.5/10

## Items for Human Review

1. **IsBuy encoding** — Vision trade data encodes direction as order type codes; SP maps B/C → IsBuy=1 (Buy), others → IsBuy=0 (Sell). Confirm the full set of Vision order type codes and whether any codes represent cancellations, amendments, or partial fills that should be excluded from reconciliation.

2. **No boundary tolerance** — Unlike `Dealing_VisionRecon_EODHoldings`, the trades table has no `LowerBoundary`/`UpperBoundary` columns. Confirm whether tolerance thresholds are intentionally not applied to trade activity reconciliation, or if this is a gap.

3. **Client_Units naming** — This column is `Client_Units` (singular), while the EODHoldings companion uses `Clients_Units` (plural). Confirm both columns map to the same source (`Dealing_Duco_ActivityRecon.ClientUnits`) and the naming difference is cosmetic.

4. **Vision-Client vs Vision-Clients naming** — The diff columns are `Vision-Clients_Units` and `Vision-Client_AmountUSD` — mixing singular and plural. Confirm this is intended and consistent with downstream dashboard queries.

## Reviewer Corrections

_None yet._
