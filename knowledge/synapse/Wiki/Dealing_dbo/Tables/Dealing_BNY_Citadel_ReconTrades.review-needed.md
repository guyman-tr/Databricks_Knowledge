# Review Needed — Dealing_BNY_Citadel_ReconTrades

**Generated**: 2026-03-21
**Quality Score**: 7.5/10

## Items for Human Review

1. **Account_Number is NULL in live sample** — BNY_Citadel records show NULL Account_Number in recent data. Confirm whether this is expected (BNY account removed but Citadel data persists) or a data quality issue.

2. **Citadel relationship** — Citadel Securities appears as a separate LP but shares the same BNY custody infrastructure. Confirm if Citadel and BNY represent separate execution paths or different views of the same trades.

3. **VIRTU presence in BNY_Detailed vs absent in this table** — VIRTU rows appear in `Dealing_BNY_Detailed` but VIRTU is not a named column in `Dealing_BNY_Citadel_ReconTrades`. Clarify how VIRTU trades are classified vs Citadel trades.
