# Review Notes: Dealing_Best_Execution_Compensation_HBC

**Batch**: 5 | **Date**: 2026-03-21 | **Quality Score**: 7.0

## Items Requiring Human Review

1. **⚠️ PIPELINE DECOMMISSION STATUS**: Same as CBH — max date 2025-01-11. See CBH review notes for the critical decommission questions. Both tables share the same decommission event.

2. **HBC spread formula**: Documented as `(CommissionByUnits / (AmountInUnitsDecimal × ConversionRate)) / 2`. Confirm this matches the current SP implementation (it was changed multiple times historically). Also confirm which column from `Dim_Position` supplies `CommissionByUnits` for opens vs `CommissionOnClose` for closes.

3. **HBC LiquidityAccountID source**: HBC positions get `LiquidityAccountID` from `Dealing_Daily_Latency_Compensation` (where `HedgingType = 'HBC'`). Confirm that HBC positions always appear in the latency table (i.e., the LEFT JOIN from slippage to latency doesn't result in NULL LiquidityAccountID for HBC rows).

4. **Row count discrepancy (5× fewer than CBH)**: ~818K HBC vs ~4.2M CBH. Confirm this ratio reflects the actual LP routing split in production — is HBC routing significantly less common, or is there a population difference in what gets flagged for compensation?

5. **Write order**: SP_Best_Execution writes HBC first, then CBH. Confirm this order is maintained and there's no data dependency between the two inserts.

6. **Identical DDL**: Both CBH and HBC tables have exactly the same DDL. Confirm this is intentional and that no additional columns are planned for either table (e.g., to distinguish the HBC-specific commission source).

## Low-Confidence Fields

- **Spread**: HBC-specific commission-based formula — confirm with Dealing team that this correctly captures the economic spread for HBC routing.
- **LiquidityAccountID**: May be NULL for HBC positions that don't appear in the latency table. Confirm NULL rate for HBC.
