# BI_DB_dbo.BI_DB_FB_Report — Review Needed

## Tier 4 Items

None — all columns traced to SP code.

## Open Questions

1. **FB source inactive since 2026-01-07**: BI_DB_FB_Performance and BI_DB_FB_Conversion stopped loading. Is this table still useful in its current DB-only mode, or should it be decommissioned?
2. **Column count**: DDL has 16 columns, batch assignment listed 17. Verified 16 from SSDT.
3. **'Not valid region' dominance**: 65% of recent rows get this label because DB-only rows have NULL Country. Is this expected behavior?
4. **Cost as int**: Spend is stored as int (whole dollars). This truncates sub-dollar granularity from the FB API.

## Corrections for Reviewer

- FB_V2 description references custom event ID 384730099048186 from the BI_DB_FB_Conversion wiki (batch 24).
- Smartly-only filter confirmed from SP code (account_name = 'eToro ALL 2 (Smartly)').
