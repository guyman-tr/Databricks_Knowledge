# BI_DB_dbo.BI_DB_CustomerCross_New — Review Needed

## Tier 4 Items

None — all columns traced to SP logic or DWH_dbo dimensions.

## Questions for Reviewer

1. **Grouping rationale**: Why does ActionTypeNew group Indices (type 4) with Stocks/ETFs instead of FX/Commodities? Is there a business reason for having two cross tables with different groupings?
2. **Single blank row**: Same edge case as CustomerCross — one row with empty ActionTypeNew.

## Cross-Object Consistency Notes

- **RealCID**: Description matches DWH_dbo.Dim_Customer wiki verbatim (Tier 1 — Customer.CustomerStatic).
- Sibling: BI_DB_CustomerCross — same SP, same population, different classification.

## Validation

- Element count: 5 (DDL) = 5 (wiki) — MATCH
- All tier suffixes present: YES
- .lineage.md written: YES
