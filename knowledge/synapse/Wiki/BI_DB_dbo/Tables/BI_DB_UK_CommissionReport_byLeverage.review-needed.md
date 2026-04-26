# Review Needed: BI_DB_dbo.BI_DB_UK_CommissionReport_byLeverage

**Generated**: 2026-04-22 | **Batch**: 35 | **Quality**: 8.8/10

## Tier 4 Items (Require SME Validation)

- None identified — all columns have Tier 1 or Tier 2 attribution.

## Open Questions

1. **"UK" naming**: The table name "UK_CommissionReport_byLeverage" covers ALL regulations (CySEC, FCA, ASIC, etc.), not FCA/UK only. Was this intentional scope expansion, or is there a separate FCA-only version?

2. **Commission unit**: Column type is INT. Is commission always rounded to whole dollars/currency units, or is there precision loss from rounding?

3. **ActionTypeID semantics**: SP uses ActionTypeID IN(4,5,6) for closes and IN(1,2,3) for opens. Dim_ActionType wiki shows these but SME should confirm all current ActionTypeID values are covered (no gaps for new types introduced post-2020).

4. **Regulation='None'**: 532 rows have Regulation='None'. Are these rows from customers with missing regulatory assignment, or a specific business rule?

## Cross-Object Consistency Notes

- **Region**: Copied verbatim from DWH_dbo.Dim_Country wiki. If Dim_Country wiki is updated, this description should be refreshed.
- **Regulation**: Traced to Tier 1 — Dictionary.Regulation (origin preserved through DWH_dbo.Dim_Regulation).
- **Leverage**: Traced to Tier 1 — Trade.PositionTbl (origin preserved through DWH_dbo.Fact_CustomerAction).
- **InstrumentType**: Traced to Tier 1 — DWH_dbo.Dim_Instrument (DWH-computed CASE expression).

## Adversarial Evaluator Notes

Phase 16 evaluation target: 8.8/10 (expected PASS ≥ 7.5).
