# Review Needed: BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType

## Open Questions

1. **No US investors observed**: The SP supports `Investor_Type = 'US'` (CountryID=219), but no rows with this value exist across any quarter. Confirm whether US investors are intentionally excluded from the FSA Seychelles population (RegulationID=9 filter would logically exclude them) or if this is a data gap.

2. **No 'Unclassified' rows**: The SP CASE has an ELSE branch for 'Unclassified', but no rows appear with this value. This is expected if the four investor type flags (Seychelles/US/EU/Other) are collectively exhaustive — confirm this is the case.

3. **TradingVolume units interpretation**: TradingVolume aggregates InitialUnits (opens) + AmountInUnitsDecimal (closes) across ALL instrument types. Since units vary (shares vs. crypto coins vs. CFD lots), the aggregate is not directly comparable across quarters if instrument mix shifts significantly. Confirm whether regulatory consumers normalize this metric.

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 5 | Investor_Type, EndDateID, TradingVolume, TradingValueUSD, UpdateDate |

All columns are ETL-computed aggregations — no direct passthrough from any upstream wiki. This is expected for a summary/aggregation table.

## Bundle Inheritance

Bundle was used to understand the SP logic and sibling table structure. No Tier 1 inheritance applicable — all columns are computed aggregations with no upstream wiki equivalent.
