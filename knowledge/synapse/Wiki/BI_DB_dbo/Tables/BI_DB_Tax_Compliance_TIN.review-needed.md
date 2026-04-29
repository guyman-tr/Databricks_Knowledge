# BI_DB_dbo.BI_DB_Tax_Compliance_TIN — Review Sidecar

## Tier 4 Items (None)

No Tier 4 columns in this object.

## Open Questions

1. **UPDATE-only ETL**: The MERGE statement (INSERT/UPDATE/DELETE) is commented out and replaced with UPDATE JOIN only. How are new customer TIN records initially inserted? Is there a separate process for initial population, or was the MERGE the original mechanism that was disabled?
2. **NoTIN_ReasonID JSON parsing**: The SP uses a simplistic `SUBSTRING(..., 1, 1)` approach that only captures single-digit reason IDs (0-9). If reason IDs ever exceed 9, the parse would break. Currently safe (max ReasonID=5).
3. **TIN_Value PII**: This column contains actual tax identification numbers (SSNs, tax IDs). Ensure UC table access is appropriately restricted for PII compliance.

## Reviewer Corrections

None pending.

## Cross-Object Consistency

- CID description matches DWH_dbo.Dim_Customer.RealCID (Tier 1 — Customer.CustomerStatic) ✓
- GCID description matches DWH_dbo.Dim_Customer.GCID (Tier 1 — Customer.CustomerStatic) ✓
- TIN_CountryName description matches DWH_dbo.Dim_Country.Name (Tier 1 — Dictionary.Country) ✓
