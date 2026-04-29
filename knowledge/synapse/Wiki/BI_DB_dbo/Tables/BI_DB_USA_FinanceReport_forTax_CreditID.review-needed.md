# BI_DB_dbo.BI_DB_USA_FinanceReport_forTax_CreditID — Review Needed

## Tier 4 Items

None — no Tier 4 descriptions in this wiki.

## Questions for Reviewer

1. **SSN masking**: The DDL does not show dynamic data masking on SSN (unlike the sibling table BI_DB_USA_FinanceReport_forTax). Should masking be applied here too?
2. **CID vs RealCID naming**: This table uses `CID` (from History.Credit) while the sibling uses `RealCID` (from Dim_Customer). Both map to the same customer. Is the naming inconsistency intentional?
3. **History.Credit no upstream wiki**: The primary source (etoro.History.Credit) has no upstream wiki. Columns CID, CreditID, Amount (Payment), Time (Occurred), Note (Description) are Tier 2 — could be elevated to Tier 1 if an upstream wiki is built.

## Corrections Log

- DDL shows 11 columns (batch assignment estimated 12). Documented 11.

## Cross-Object Consistency

- **Credit** column: Description inherited verbatim from Dim_CreditType.CreditTypeName wiki (Tier 1 — Dictionary.CreditType)
- **Category** column: Description inherited verbatim from Dim_CompensationReason.Name wiki (Tier 1 — BackOffice.CompensationReason)
- **Reason** column: Description inherited verbatim from Dictionary.MoveMoneyReason wiki (Tier 1 — Dictionary.MoveMoneyReason)
