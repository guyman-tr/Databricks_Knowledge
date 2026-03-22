# Review Needed — Dealing_CopierAnalysis

## Open Questions

1. **CopyingAmountGroup typo**: The SP has a label bug — the 1000-5000 amount band is labelled `'1001-500'` instead of `'1001-5000'`. This typo exists in the deployed SP. Confirm whether this has been flagged and whether a correction is planned (would require backfilling historical data or accepting label inconsistency).

2. **Only active mirrors stored**: The table only contains rows for `IsActive=1` copy relationships. Closed/churned mirrors are absent. Confirm whether there is a separate historical store for closed copy relationships, or if analysts should query `Dim_Mirror` / `etoro_History_Mirror` directly for churn analysis.

3. **FirstName and Email columns always NULL**: The SP explicitly inserts NULL for these PII columns. Confirm whether these columns can be dropped from the DDL, or whether they must remain for downstream schema compatibility (e.g., Power BI reports that reference them by name).

4. **V_Liabilities for TotalEquity**: TotalEquity = `ABS(ActualNWA + Liabilities)` from DWH_dbo.V_Liabilities. Confirm whether this is the same TotalEquity definition used in other copy-trading dashboards, or if there are cases where negative equity (ABS) masks meaningful negative values.

5. **Copy Portfolios (CopyFund) RiskScore**: CopyFund rows get `RiskScore = 0` from the PI data (hardcoded in SP). Confirm whether this is intentional (Copy Portfolios do not have a standard risk score) or if a separate risk lookup for CopyFunds is planned.

6. **633M rows and query performance**: At current growth rate (~1M rows/day across all active mirrors), the table will continue to grow. Confirm whether there is a data retention policy (e.g., keep only N months of history) or if the full history must be preserved indefinitely for longitudinal analysis.
