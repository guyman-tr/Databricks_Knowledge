# BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions — Review Needed

## Tier 4 Items

None — all columns traced to DWH_dbo facts/dimensions or ETL logic.

## Questions for Reviewer

1. **No Internal exclusion**: Unlike most BI_DB population tables, this SP does NOT exclude PlayerLevelID=4 (Internal accounts). Is this intentional?
2. **Negative Amount**: Amount values are stored as negative numbers. Is this the standard convention from Fact_CustomerAction, or should they be stored as positive?
3. **IsBuy NULL on Copy Opens**: IsBuy comes from a LEFT JOIN to Dim_Position. For ActionTypeID=17 (Copy Open), the PositionID may not match a Dim_Position row, leaving IsBuy NULL. Is this expected?

## Cross-Object Consistency Notes

- **RealCID**: Description matches DWH_dbo.Dim_Customer wiki verbatim (Tier 1 — Customer.CustomerStatic).
- This table feeds BI_DB_CustomerCross and BI_DB_CustomerCross_New (same SP, exclusion logic).

## Validation

- Element count: 11 (DDL) = 11 (wiki) — MATCH
- All tier suffixes present: YES
- .lineage.md written: YES
