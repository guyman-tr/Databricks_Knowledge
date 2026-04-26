# BI_DB_dbo.BI_DB_LimitedAccountsWithReasonsNEW — Review Needed

## Tier 4 Items

None.

## Reviewer Questions

1. **SLA rules maintenance**: The ~60 SLA rules are hardcoded in the SP. Are these rules documented elsewhere (e.g., a compliance policy document)? Changes to SLA windows require SP modification.
2. **98.4% OUT of SLA**: Is this expected? If the vast majority of blocks exceed SLA, is the SLA definition still meaningful, or have SLA windows changed since the SP was written?
3. **DesignatedRegulation vs Regulation**: Some customers may have different designated vs current regulation. Is DesignatedRegulation always the more relevant one for compliance purposes?
4. **FCA-specific SLA**: The SP has special rules for FCA (DesignatedRegulationID=2) with 21-day SLA for AML Trigger and Investigation. Are there similar regulation-specific rules that should be added for other entities?
