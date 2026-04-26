# Review Notes: BI_DB_dbo.BI_DB_Transactions_Per_Time_Unit

**Generated**: 2026-04-22 | **Batch**: 34 | **Quality**: 9.6/10

## Tier 4 / Uncertain Items

None — all 14 columns traced to SP logic (SP_Transactions_Per_Time_Unit code fully read).

## Questions for SME Review

1. **ClosePositionReasonID != 10**: Closed positions with ClosePositionReasonID=10 are excluded from the counts. What does reason ID 10 represent? (Common values: 1=manual close, 2=stop-loss, 3=take-profit, 10=?) This affects the accuracy of the "total transactions" description.

2. **Customers_Cnt not scoped to @Date**: The Customers_Cnt subquery counts the total valid/deposited/KYC-verified customer base at ETL execution time — not customers who traded on @Date. If this is intentional (showing "addressable market size" alongside daily activity), confirm this design is expected. If the intent was to count active customers on that specific date, the SP has a logic issue.

3. **No change history**: The SP has no author/date header or change log. Who created this table, and when? Are there any known changes to the filter logic (e.g., was the commented-out `RegulationIDOnOpen=8` filter ever active in production)?

4. **UNION deduplication**: The SP uses UNION (not UNION ALL) to combine opens and closes. This deduplicates full-row identical records. For a position opened and closed at exactly the same timestamp with identical attributes, only one event would be counted. Is this the intended behavior, or should it be UNION ALL?

5. **Downstream consumers**: No SP or table references found in the SSDT scan. Is this consumed by a specific dashboard, Tableau/Power BI report, or operations team tool?

## Corrections Applied

- Changed `OFFSET/FETCH` syntax in Sample Queries to `TOP N` (Synapse SQL Pool does not support OFFSET clause syntax in DWH contexts).

## Ghost Columns

None identified. All 14 DDL columns are present in the SP INSERT list.
