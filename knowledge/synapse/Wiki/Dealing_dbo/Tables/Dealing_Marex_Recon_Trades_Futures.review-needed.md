# Review Needed — Dealing_Marex_Recon_Trades_Futures

**Generated**: 2026-03-21
**Quality Score**: 7.0/10

## Items for Human Review

1. **Marex futures trade source** — The exact LP staging table for the Marex futures trade file is not confirmed (SP partially read). Confirm the table name (likely `LP_EdnF_*` or a dedicated futures table) and whether it is distinct from the base Marex trade source used by `Dealing_Marex_Recon_Trades`.

2. **eToroRate_AfterADJ** — This column exists in Trades_Futures but NOT in EODHoldings_Futures. Confirm what "ADJ" means for the eToro rate specifically (vs the Marex FX rate ADJ). Is this an exchange settlement adjustment, a P&L adjustment, or something else?

3. **IsOpen semantics for closing trades** — For `IsOpen=0` (closing trades), confirm whether `Marex_Units` and `ClientUnits` are stored as positive values (with sign meaning derived from `IsBuy`) or as signed negative values. This affects how net position changes should be calculated from this table.

4. **CHIT NUMBER usage** — `[CHIT NUMBER]` is described as a Marex trade reference. Confirm whether this is a unique execution reference (like `ExecutionID`) or a batch/ticket reference that can span multiple executions. Clarify when to use `ExecutionID` vs `CHIT NUMBER` for trade lookups.

5. **Column naming with spaces** — Several columns (`[CHIT NUMBER]`, `[MULTIPLICATION FACTOR]`, `[LST TRD DATE]`, `[CURRENCY SYMBOL]`) have spaces. Confirm these will be preserved in the UC/Delta Lake migration or whether they will be renamed (column renames would be a breaking change for existing queries).

6. **Three-way vs two-way recon split** — EODHoldings_Futures has Marex-Clients only; Trades_Futures has both Marex-Clients and Marex-eToro. Confirm this difference is intentional: is eToro's hedge book only relevant for trade activity (not EOD position)?

## Reviewer Corrections

_None yet._
