# BI_DB_ASIC_Monthly_Positions — Review Notes

**Object**: BI_DB_dbo.BI_DB_ASIC_Monthly_Positions
**Batch**: 15 | **Date**: 2026-04-21 | **Reviewer Needed**: ASIC Compliance team / Analytics

## Tier 4 Items / Reviewer Questions

1. **Volume formula asymmetry**: Open positions use `InitialAmountCents/100 × Leverage` while close positions use `Amount × Leverage`. This means TotalVolume is not directly comparable between open and close groups — they measure different things (initial investment vs. close-time amount). Reviewer: is this the intended ASIC regulatory reporting definition, or should both use the same base?

2. **Partial close child exclusion asymmetry**: `IsPartialCloseChild` is excluded from open position count but not close position count. This creates a structural asymmetry — reviewer confirm this matches ASIC regulatory requirements.

3. **Dual regulation attribution**: A position can qualify for both RegulationIDOnOpen = ASIC (open row) AND RegulationOnClose = ASIC (close row) in the same month. The SP intentionally keeps these as separate rows, potentially double-counting the same position in the aggregate. Reviewer: is this intentional for ASIC reporting (open and close are separate regulatory categories)?

4. **ASIC_Client_Group varchar(500)**: Column declared as varchar(500) but only ever contains one of 4 short enum values (~17 chars max). varchar(500) is oversized — potential future extensibility or historical DDL padding.

5. **TotalVolume as bigint**: InitialAmount × Leverage can produce large numbers for high-leverage crypto positions. Bigint (max ~9.2 × 10^18) should be sufficient. Reviewer confirm there's no overflow risk for very large positions.

6. **No consumers identified**: This table has no SP or view consumers in the Synapse SSDT repo. It is likely exported to BI tools (Power BI, Tableau) or Excel reports directly for ASIC regulatory submission. If there are downstream consumers outside Synapse, document them here.

## No Issues

- All 5 columns documented with Tier 2 suffixes (no upstream wiki inheritance — all aggregated/computed)
- Row count (400), date range (201801–202604), and 4 enum values for ASIC_Client_Group confirmed from live data
- Column [NO.Positions] dot-notation gotcha documented
- Section 2 documents partial-close exclusion asymmetry
