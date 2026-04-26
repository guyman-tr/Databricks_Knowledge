# Review Needed — BI_DB_dbo.BI_DB_rsk_Portfolio

**Generated**: 2026-04-23 | **Batch**: 70 | **Quality**: 8.7/10

## Tier 4 Items (Undetermined — Pending Review)

None. All columns resolved to Tier 1 or Tier 2.

## Questions for Domain Expert

1. **OpsDB writer attribution**: OpsDB maps `SP_rsk_AgregatedRisk → BI_DB_rsk_Portfolio`, but the SSDT code shows `SP_rsk_Portfolio` is the actual writer and `SP_rsk_AgregatedRisk` is the reader. Please confirm the OpsDB metadata is incorrect and that `SP_rsk_Portfolio` is the ETL writer.

2. **Date range**: Earliest data shows 2021-01-01. Was the table created as part of the Risk Dashboard project in 2023 (per SP author date) with historical backfill, or was it originally populated differently?

3. **Zero Net_USD_Vol rows** (0.8%): These likely represent fully hedged positions (long + short netting to zero for the same instrument). Should they be excluded from risk calculations or treated as meaningful exposure signals?

4. **`SP_rsk_RiskCorelation_PIs`**: This SP also reads from `BI_DB_rsk_Portfolio` but its output table is not in OpsDB. Please confirm what `BI_DB_rsk_RiskCorelation` tracks and whether it has a UC migration plan.

## Propagation Metadata

- `UpdateDate` is ETL metadata (GETDATE() from SP) — confirmed Propagation tier.

## Corrections Log

*(Empty — no reviewer corrections yet)*
