# BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **Table size at 10.6 billion rows**: With ~10.59B rows and growing daily via incremental INSERT, this is among the largest tables in the schema. Is there a retention policy or partition pruning strategy planned? At current growth rates, storage and query performance may degrade.
2. **DateID=0 sentinel**: DateID=0 maps to Date='1900-01-01' and represents unknown/unresolvable dates. How many rows use this sentinel? Should these be excluded from the return calculation, or are they intentionally included in lifetime aggregations?
3. **UNION sparse structure**: Each row only populates one of the three metric groups (NetProfit OR RealizedEquity OR Revenue), leaving the others NULL. This triples the row count compared to a pivoted design. Was this chosen for incremental load simplicity, or could a pivoted structure reduce table size?
4. **RiskApetite typo propagation**: The parent table BI_DB_ReturnCalculation carries the `RiskApetite` column name typo (missing second 'p'). While Daily_Data itself does not have this column, consumers should be aware when joining upstream.
5. **No historical cleanup**: The incremental DELETE+INSERT pattern only handles overlapping DateID+RealCID for new batches. Historical corrections to closed positions or liabilities would not propagate unless the affected DateIDs are reprocessed.
