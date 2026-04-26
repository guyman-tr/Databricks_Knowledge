# BI_DB_dbo.BI_DB_Investment_Monthly_Data — Review Needed

## Tier 4 Items

None — no Tier 4 descriptions in this wiki.

## Review Questions

1. **Only 3 months of data**: Table was created Apr 2024 per SP header, but only has Jan-Mar 2026 data. Was historical data purged, or is this a recent-only table?

2. **AirDrop exclusion hardcoded dates**: The SP has hardcoded `dp2.OpenDateID<=20231031 AND dp2.CloseDateID>20231001` for AirDrop copy detection. This seems frozen to Oct 2023 — should it be parameterized?

3. **Num_CopiedInstruments uses COUNT vs COUNT DISTINCT**: The copied person's instrument count uses `COUNT(InstrumentID)` (not DISTINCT), while the copier's uses `COUNT(DISTINCT InstrumentID)`. This asymmetry means %ofCopiedInstruments can exceed 100%. Is this intentional?

4. **Google Sheets reference**: SP comment references a Google Sheet for the spec. Consider documenting the sheet URL in Confluence for permanent reference.

## Reviewer Corrections

None yet.
