# BI_DB_dbo.BI_DB_PR_MonthlyData — Review Needed

## Tier 4 Items

None.

## Open Questions

1. **PR use case**: Confirm that "PR" refers to Public Relations reporting. The data structure (demographics, instrument types, temporal patterns) suggests marketing/PR content generation.
2. **Age_Group recalculation**: Age is computed at GETDATE() execution time, not at position open time. Historical re-runs will shift customers between age bands. Confirm if this is intentional or a known limitation.
3. **Gender default**: NULL/unknown genders default to 'Male'. This introduces bias in gender-based analysis. Confirm if downstream consumers account for this.
4. **WITH(NOLOCK)**: SP uses NOLOCK on all JOINs. Confirm data consistency is acceptable for monthly reporting cadence.

## Reviewer Corrections

None pending.

## Cross-Object Consistency Notes

- CID description inherited from BI_DB_CIDFirstDates wiki (Tier 1 — Customer.CustomerStatic).
- Country inherited from BI_DB_CIDFirstDates wiki.
- Dim_Position columns (PositionID, OpenDateID, OpenOccurred, Amount) descriptions aligned with Dim_Position wiki.
