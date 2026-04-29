# BI_DB_dbo.BI_DB_W_AML_PEP_Customers — Review Needed

## Tier 4 Items (needs human verification)

- None — all columns resolved to Tier 1, Tier 2, Tier 3, or Tier 5.

## Questions for Reviewer

1. **Column typo "Regualtion"**: Should this be corrected in a future DDL change, or is it intentionally preserved for downstream compatibility?
2. **ScreeningStatus constant**: This column is always 'PEP' due to the ScreeningStatusID=3 filter. Is it still useful in the output, or is it kept for schema consistency with other AML tables?
3. **RiskScoreName coverage**: Only "High" and "Medium" observed in PEP population. Are there other expected values (Low, etc.) for non-PEP populations in the RiskClassification system?

## Reviewer Corrections

(none yet)

---

*Generated: 2026-04-27 | Object: BI_DB_dbo.BI_DB_W_AML_PEP_Customers*
