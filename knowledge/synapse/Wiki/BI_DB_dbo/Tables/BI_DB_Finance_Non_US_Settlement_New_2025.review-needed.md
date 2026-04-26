# BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025 — Review Needed

## Tier 4 Items (None)

No Tier 4 items — all columns traced to SP code or upstream wikis.

## Questions for Reviewer

1. **Column count discrepancy**: Batch assignment listed 45 columns, DDL shows 44. Verified against SSDT DDL — 44 is correct. Note: DDL has no SettlementTypeID column, but the SP uses it internally as a grouping key in #final and filters for TotalStockMarginLoan computation; it does not appear in the final INSERT list.

2. **Close_PriceType values**: Live data shows 1, 2, 3, NULL. Close_PriceType=2 dominates at 83%. What do these values mean? Assumed: 1=EOD close, 2=current, 3=other. Confirm with finance team.

3. **Provider name consistency**: The 2025 SP uses Karen's Fivetran mapping + etoro LA mapping + CASE normalization. The 2023 SP uses a hardcoded temp table. Provider names overlap but are not identical — 2025 adds UBS, Marex, Gdax, GS, DLT, COINBASE, eToroX, JP. Should Provider names be reconciled?

4. **TotalStockMarginLoan semantics**: Only nonzero for SettlementTypeID=5 AND Leverage<>1. The formula (InitForexRate × Units × ConversionRate - Amount) represents the loan component of a leveraged position. Confirm this interpretation.

5. **This SP also writes BI_DB_Finance_eToro_vs_Positions**: Already documented in batch 87 (quality 8.0). The eToro_vs_Positions wiki references this SP correctly.

## Corrections Applied

- None required.

## Cross-Object Consistency

- InstrumentID, HedgeServerID, IsDiscounted descriptions match Dim_Instrument/Dim_Position wikis verbatim.
- IsCreditReportValidCB, IsValidCustomer descriptions match Fact_SnapshotCustomer wiki.
- IsSettled description matches Dim_Position wiki (Tier 5).
- Columns shared with BI_DB_Finance_Non_US_Settlement_New_2023 have consistent descriptions.

*Generated: 2026-04-26*
