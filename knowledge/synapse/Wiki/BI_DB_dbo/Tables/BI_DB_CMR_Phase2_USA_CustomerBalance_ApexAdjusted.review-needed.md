# Review Notes — BI_DB_dbo.BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted

**Batch**: 60 | **Date**: 2026-04-23 | **Status**: Ready for SME review

## Items for SME Review

1. **ClosingBalanceCalculated vs CycleCalculation**: The table provides both a transaction-flow-based cycle calculation (ExcelOrder=35) and a balance-sheet-component-based closing balance (ExcelOrder=36). Confirm the intended reconciliation relationship: should ExcelOrder 34 (ClosingBalanceAdjusted) = ExcelOrder 35 (CycleCalculation) = ExcelOrder 36 (ClosingBalanceCalculated), or are discrepancies between these three expected?

2. **GapTotal = Gap + GapFinra**: Metric 38 (GapTotal) is computed as `Gap + GapFinra`. Confirm that GapFinra represents the incremental FINRA-specific gap (i.e., adding GapFinra to the non-FINRA gap gives the total), not a standalone measurement.

3. **Regulation filter includes eToroUS**: The scope includes eToroUS in addition to FinCEN and FinCEN+FINRA. Confirm whether eToroUS customers hold real stocks through Apex and whether Apex adjustments (which only apply to FinCEN+FINRA in the SP) are correctly handled for eToroUS rows.

4. **No segment columns in output**: Unlike the LiabilityDecomp table, this table has no Regulation/PlayerStatus columns in the output (all segment dimensions are aggregated away in Phase 2 of the SP). Confirm this is the intended output grain for the Excel report (total US, not segmented).

5. **40 ExcelOrder metrics**: The table contains 40 metrics, which is considerably more than the other CMR Phase 2 tables (11–34 metrics). Confirm the Excel workbook consumes all 40, or whether some are intermediate calculations used internally.

6. **Duplicate date 2025-01-13**: Live data shows 80 rows for 2025-01-13 (expected 40 — one per metric per date). This indicates a double-load for that specific date. Confirm whether the DELETE WHERE Date=@date guard failed on that ETL run, and whether any corrective action is needed.

7. **GapNonFinra = Gap**: Live data on 2026-04-12 shows GapNonFinra = $0 and Gap = $0. Reviewing the SP code, GapNonFinra uses the same formula as Gap (ClosingBalance − CycleCalculation). Confirm whether GapNonFinra is intended to equal Gap − GapFinra (which would be the "non-FINRA portion of the gap"), and whether the SP needs updating.
