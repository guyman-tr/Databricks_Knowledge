# BI_DB_dbo.BI_DB_CustomerCross — Review Needed

## Tier 4 Items

None — all columns traced to SP logic or DWH_dbo dimensions.

## Questions for Reviewer

1. **Single blank ActionType_Detailed row**: One row has empty/blank ActionType_Detailed. Is this a data quality issue or an expected edge case (e.g., an action that matched no classification)?
2. **Hardcoded CopyFund CIDs**: Six specific CIDs (4657450, 4657433, 4657429, 4657444, 4657439, 4657462) are always treated as CopyFund. Are these still relevant, or should they be removed?
3. **CFD vs Real distinction**: The Real vs CFD Stocks/ETFs split uses IsBuy from Dim_Position (LEFT JOIN, may be NULL). If IsBuy is NULL, the action falls through to Copy/NULL. Is this the intended behavior?

## Cross-Object Consistency Notes

- **RealCID**: Description matches DWH_dbo.Dim_Customer wiki verbatim (Tier 1 — Customer.CustomerStatic).
- Sibling table: BI_DB_CustomerCross_New uses same SP, same population, different ActionType grouping.

## Validation

- Element count: 5 (DDL) = 5 (wiki) — MATCH
- All tier suffixes present: YES
- .lineage.md written: YES
