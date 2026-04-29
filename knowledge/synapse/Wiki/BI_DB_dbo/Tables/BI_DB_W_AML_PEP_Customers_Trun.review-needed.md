# BI_DB_dbo.BI_DB_W_AML_PEP_Customers_Trun — Review Needed

## Tier 4 Items (needs human verification)

- None — all columns resolved to Tier 1, Tier 2, Tier 3, or Tier 5.

## Questions for Reviewer

1. **UpdateDate nullable difference**: This table has UpdateDate as nullable (NULL) while the accumulating parent BI_DB_W_AML_PEP_Customers has it as NOT NULL. Both are populated with GETDATE() by the same SP — is the DDL difference intentional?
2. **Usage pattern**: Is this TRUNCATE table primarily used for dashboard consumption (current PEP snapshot), or does it serve a different operational purpose?

## Reviewer Corrections

(none yet)

---

*Generated: 2026-04-27 | Object: BI_DB_dbo.BI_DB_W_AML_PEP_Customers_Trun*
