# Review Sidecar — DWH_dbo.Fact_SnapshotEquity

## Unverified Claims

| # | Column | Claim | Confidence | Source | Needs |
|---|--------|-------|------------|--------|-------|
| 1 | TotalCash | Running balance formula replaced direct History.Credit.TotalCash read in 2020-06-07 | HIGH | SP change log line 20 | Confirm with DWH team that the running balance approach is still current |
| 2 | RealizedEquity | Fallback formula (TotalCash+TotalPositionsAmount+InProcessCashouts) used when source RealizedEquity=0 | HIGH | SP_Fact_SnapshotEquity line 148-152 | Verify business intent of the fallback |
| 3 | AUM | Confluence says "AUC (or AUM) on PI Dashboard" — unclear if AUC and AUM are synonymous | MEDIUM | Confluence: DWH View Fact_SnapshotEquity | Clarify AUC vs AUM terminology |
| 4 | TotalStockOrders | Documented as legacy/hardcoded 0 since 2019 | HIGH | SP change log line 19, SP code line 158 | Confirm column can be deprecated |
| 5 | TotalMirrorStockOrders | Same as TotalStockOrders | HIGH | Same | Same |
| 6 | DateRangeID | Encoded as YYYYMMDDYYYY (12 digits) — the exact format may vary by year-end vs mid-year | MEDIUM | SP code analysis | Verify encoding with DWH team |
| 7 | TotalRealCryptoLoan | Uses InitialAmount (changed 2020-03-25 from Amount) | MEDIUM | SP change log line 21 | Confirm InitialAmount is still the correct basis |
| 8 | TotalStockMarginLoanValue | Formula changed 2025-12-10 to use InitConversionRate | HIGH | SP change log line 28 | Recently changed — verify with Daniel Kaplan |

## Reviewer Corrections

*None yet.*
