# Review Needed: BI_DB_dbo.BI_DB_ProfessionalCustomersDocuments

## Tier 4 Items

- **SuggestedDocumentTypeID = 21**: Assumed to mean "professional customer application" based on context. No Dictionary table lookup available to confirm the exact document type name.
- **Dim_Regulation.Name values**: Regulation names like "ASIC & GAML", "FSA Seychelles", "FinCEN+FINRA" are taken from live data. No upstream wiki exists for Dim_Regulation to confirm canonical names.

## Questions for Reviewer

1. What exactly is SuggestedDocumentTypeID = 21? Is there a Dictionary.DocumentType table that maps this ID?
2. The SP has no author/change history header -- who maintains this SP?
3. ProfessionalStatus shows 77% Retail at submission time. Is this expected (documents submitted before MiFID upgrade)?

## Confidence Notes

- CID is Tier 1 (passthrough from Fact_SnapshotCustomer.RealCID, origin Customer.CustomerStatic)
- ClubTier is Tier 1 (dim-lookup passthrough from Dim_PlayerLevel.Name, origin Dictionary.PlayerLevel)
- ProfessionalStatus could arguably be Tier 1 from Dim_MifidCategorization but no upstream wiki exists for that dimension to confirm descriptions
- Regulation could arguably be Tier 1 from Dim_Regulation but no upstream wiki exists
