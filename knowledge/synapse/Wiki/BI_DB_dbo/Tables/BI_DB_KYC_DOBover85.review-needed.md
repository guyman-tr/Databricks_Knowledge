# BI_DB_dbo.BI_DB_KYC_DOBover85 — Review Needed

## Tier 4 Items

None.

## Reviewer Questions

1. **Age 126 outlier**: Maximum age of 126 years suggests possible data quality issue with BirthDate in source production systems. Should these be flagged or excluded?
2. **IsSelfielivelinessProof inverted naming**: 1 = proof missing, 0 = proof exists. Is this intentional or a coding error in the SP? The naming convention suggests the opposite meaning.
3. **IsAddressProof/IsIDProof NULLs for US**: 67% of rows have NULL for these columns, primarily US regulation customers. Is this because US KYC doesn't track these fields, or is it a data gap?
4. **DATEDIFF(year) precision**: The SP uses DATEDIFF(year) which counts year boundary crossings, not actual birthday anniversaries. A customer born Dec 31, 1940 who registered Jan 1, 2026 shows AgeAtReg=86 despite being ~85 years old. Is this acceptable for compliance purposes?

## Cross-Object Consistency

- CID, BirthDate, Registered descriptions inherit from DWH_dbo.Dim_Customer wiki (Tier 1 columns traced to Customer.CustomerStatic).
- VerificationLevelID description inherits from DWH_dbo.Dim_Customer wiki (Tier 1 — BackOffice.Customer).
