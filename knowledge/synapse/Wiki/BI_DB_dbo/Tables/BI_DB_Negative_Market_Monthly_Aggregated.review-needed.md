# Review Needed: BI_DB_dbo.BI_DB_Negative_Market_Monthly_Aggregated

## Tier 4 / Low-Confidence Items

No Tier 4 columns in this table. All columns traced to SP code (Tier 2) or DWH dimension wikis (Tier 1).

## Reviewer Questions

1. **Single-month retention confirmed?** The TRUNCATE+INSERT design means only the latest EOM is retained. Is this intentional for compliance reporting, or is there a separate historical archive table?

2. **`ASIC & GAML` regulation label**: This appears as a combined regulation string (330 rows, 1.69M customers for March 2026). Is "ASIC & GAML" an official regulatory designation or a legacy label? Should it be split or renamed?

3. **`DspositorInd` column name typo**: DDL column is `DspositorInd` (missing 'e' — "Depositor" vs "Dspositor"). This typo exists in both DDL and SP. All queries must use the misspelled name. Is there a plan to rename this?

4. **Relation to BI_DB_Scored_Appropriateness_Negative_Market**: The documented table is a monthly EOM aggregation of the parent. If the parent table is queried directly with GROUP BY, the results should match. Verify this assertion with compliance team.

5. **EOM trigger**: The SP includes an EOM block (`IF @Date=EOMONTH(@Date)`). If the daily run fails on the last day of the month, the monthly snapshot will be missed. Is there a re-run mechanism for EOM failures?

## Known Anomalies

- `DspositorInd` DDL type is int, but SP inserts varchar literals `'0'`/`'1'` — implicit conversion. No data corruption observed, but type mismatch is a code smell.
- `[Total Customers]` column name has a space — requires bracket-quoting in all queries.
- March 2026 only — no historical data. Table is not suitable for trend analysis without external data archiving.
