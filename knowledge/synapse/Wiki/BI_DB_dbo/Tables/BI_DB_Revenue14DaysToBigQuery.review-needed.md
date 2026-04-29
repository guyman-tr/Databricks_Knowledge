# BI_DB_dbo.BI_DB_Revenue14DaysToBigQuery — Review Needed

## Tier 4 Items (Low Confidence)

None — all columns traced to documented upstream sources.

## Questions for Reviewer

1. **BigQuery export mechanism**: How is this table exported to BigQuery? (ADF pipeline, scheduled export, Dataflow?) The SP populates the Synapse table, but the export mechanism is not visible in SSDT code.
2. **Column name typo**: `FirstDepositeDate` has an extra 'e'. Is this intentional or should it be corrected? (Would require coordinating with BigQuery consumers.)
3. **NULL Revenue semantics**: Confirmed 12% NULL from Phase 3. Is this expected or are some rows being inserted before Revenue14days is calculated in BI_DB_CID_BalanceDays?

## Upstream Verification

| Column | Source | Verified |
|--------|--------|----------|
| CID | Dim_Customer.RealCID wiki (Tier 1) | Yes — verbatim from Customer.CustomerStatic |
| FirstDepositeDate | Dim_Customer.FirstDepositDate wiki (Tier 2) | Yes — SP_Dim_Customer computed |
| Revenue | BI_DB_CID_BalanceDays.Revenue14days wiki (Tier 2) | Yes — SP_CID_BalanceDays computed |
| UpdateDate | GETDATE() | N/A — ETL metadata |
