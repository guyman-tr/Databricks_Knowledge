# BI_DB_dbo.BI_DB_Vulnerable_Customers — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **Column name typo**: `Appropriatness_Status` is missing an 'e' (should be "Appropriateness"). This typo originates from the SP and DDL.
2. **DWHRegulationID vs ID**: The SP joins Dim_Regulation on DWHRegulationID (not the standard ID column). Are there cases where these differ?
3. **DWHCountryID vs CountryID**: Similar to above — the SP joins Dim_Country on DWHCountryID rather than CountryID.
4. **No GCID in Dim_Customer wiki Elements section**: The GCID column from KYC is joined to Dim_Customer.GCID, but the Dim_Customer wiki Elements section may not document GCID. Verify this mapping.
5. **Population gap**: Answer dates start at 2022-07-06 despite the filter being OccurredAt >= '20210401'. This suggests the KYC question was introduced later or data was backfilled from a later date.

## Cross-Object Consistency

- **CID** description inherited from Dim_Customer.RealCID wiki (Tier 1 — Customer.CustomerStatic)
- **Regulation** description inherited from Dim_Regulation.Name wiki (Tier 1 — Dictionary.Regulation)
- **DesignatedRegulation** uses same Dim_Regulation.Name description (Tier 1 — Dictionary.Regulation)
- **Country** description inherited from Dim_Country.Name wiki (Tier 1 — Dictionary.Country)
