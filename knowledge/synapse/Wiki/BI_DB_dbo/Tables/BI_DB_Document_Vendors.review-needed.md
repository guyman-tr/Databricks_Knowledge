# BI_DB_dbo.BI_DB_Document_Vendors — Review Needed

## Tier 4 Items
None — all columns traced to SP code and External table sources.

## Reviewer Questions

1. **Empty FinalOutcome**: 252 rows have blank (not NULL) FinalOutcome — these are edge cases not covered by the CASE logic. Which combinations of Classification/ClassifiedBy/Vendor produce this gap?

2. **Au10tix nearly extinct**: Only 206 rows use Au10tix vendor. Is Au10tix being deprecated? The selfie handling code path for Au10tix is substantial — worth reviewing if the vendor is being phased out.

3. **DocumentTypeID filter**: The SP filters to DocumentTypeID IN (1,2,15,6,18,23). What are these IDs? The wiki assumes POI/POA/Selfie/SelfieLiveliness/Selfie Motion based on the CASE logic, but the mapping is not explicit in the SP.

4. **OriginalOutcome vs FinalOutcome semantics**: For multi-event documents, "original" = first event's vendor decision, "final" = last event. But the FinalOutcome CASE uses `fdda` (first definition) and `ldd` (last definition) — the logic is counterintuitive. Confirm the business intent.

5. **No date column**: Unlike most BI_DB tables, this one has no DateID column for date-based partitioning. The TRUNCATE+INSERT pattern means no historical data is retained.

## Corrections Applied
- Column count matches DDL: 20 columns including IDENTITY ID.

## Data Quality Notes
- FinalOutcome: Auto-Accepted (60.0%), Auto-Rejected (17.9%), Manually Rejected (11.6%), Manually Accepted (8.5%), Slow response (1.6%), Other (0.4%)
- DocumentTypeCategory: POI (56.9%), POA (36.3%), Selfie Motion (3.9%), SelfieLiveliness (2.9%), Selfie (~0%)
- All varchar(max) columns — potential performance concern for large-scale analytics
