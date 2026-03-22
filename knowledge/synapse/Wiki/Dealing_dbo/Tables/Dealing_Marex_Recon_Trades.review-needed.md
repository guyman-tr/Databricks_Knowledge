# Review Needed — Dealing_Marex_Recon_Trades

**Generated**: 2026-03-21
**Quality Score**: 7.3/10

## Items for Human Review

1. **Marex trade source** — Documentation states Marex trade data comes from `CopyFromLake.etoro_Hedge_ExecutionLog`. Confirm whether this is eToro's own execution log (reflecting Marex-routed orders) rather than a Marex-provided file. If so, this table's "Marex_Units" actually represents eToro's view of Marex executions, not Marex's own reported trade volume.

2. **No direction column** — Unlike IG and Vision trade tables, there is no Buy/Sell or IsBuy column. Confirm whether this is intentional (trades reconciled net) or a structural gap. If net, confirm that buys and sells are signed opposite in the aggregation.

3. **Marex_Rate column absent** — Unlike IG, JPM, and Vision trade tables, there is no `Marex_Rate` execution price column. Confirm whether execution price reconciliation is out of scope for Marex trades, or if it is tracked elsewhere.

4. **CopyFromLake schema** — `CopyFromLake.etoro_Hedge_ExecutionLog` uses a non-standard schema name. Confirm this is an external data source accessed via linked service or external table, and whether it has any latency or availability SLA that could delay the Marex trade reconciliation.

## Reviewer Corrections

_None yet._
