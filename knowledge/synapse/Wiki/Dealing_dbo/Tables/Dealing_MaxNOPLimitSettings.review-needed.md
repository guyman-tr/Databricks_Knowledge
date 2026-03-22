---
object: Dealing_MaxNOPLimitSettings
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_MaxNOPLimitSettings — Review Notes

## Auto-Generated Flags

- **MaxNOP currency**: Is MaxNOP stored in USD, or instrument-native currency? CID-level overrides may be in different currencies. Reviewer: confirm and update.
- **EXW_Settings schema ownership**: EXW_Settings is a separate schema from BI_DB_dbo.External_SettingsDB. Who owns/maintains EXW_Settings — is it the EXW (execution) team, Risk, or Dealing?
- **TagType values**: Only 'Customer' is documented for CID overrides. Are there other TagType values (e.g., 'Country', 'AccountType', 'Group')? Enumerate all used values.
- **RestrictionWeight range**: What is the typical range of RestrictionWeight values? Is weight=1 lowest priority, or is there a documented scale?
- **Column list accuracy**: Column list inferred from SP logic and partial DDL read — reviewer should verify against actual DDL for any additional columns.
- **IsActive vs. date filter**: If IsActive=0 rows are retained historically, consumers should filter IsActive=1 to get current limits. Confirm whether inactive rows are pruned or kept.
- **3M rows**: At daily cadence with ~3M rows, this suggests thousands of distinct scope combinations. Is this expected, or indicative of a settings explosion?

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
