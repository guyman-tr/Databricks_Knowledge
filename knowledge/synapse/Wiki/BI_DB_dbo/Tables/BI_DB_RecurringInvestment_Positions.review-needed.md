# Review Needed: BI_DB_dbo.BI_DB_RecurringInvestment_Positions

## Tier 4 Items

None — simple passthrough, all columns traced.

## Review Questions

1. **External source schema**: The source `External_bi_db_recurringinvestment_positions_parquet` is a parquet file from the RecurringInvestment service. No production database wiki exists for this source. The column names (PositionID, DepositID) are inferred from the external table.

2. **No history retention**: TRUNCATE+INSERT means only current state is captured. If positions are removed from recurring investment, they disappear from this table. Is there a need for historical tracking?

3. **DepositID FK verification**: Confirm that DepositID maps to Fact_BillingDeposit.DepositID or a different deposit table.

## Corrections Applied

None.
