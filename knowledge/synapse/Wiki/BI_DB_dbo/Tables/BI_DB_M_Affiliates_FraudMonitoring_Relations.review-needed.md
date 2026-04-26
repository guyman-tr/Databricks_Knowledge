# BI_DB_dbo.BI_DB_M_Affiliates_FraudMonitoring_Relations — Review Needed

## Tier 4 Items

None.

## Reviewer Questions

1. **PII exposure**: ClientName (FirstName + LastName) is stored in plain text. Is this appropriate for a table that may be accessed by analysts, or should it be masked/hashed?
2. **PersonalDetailsRelation false positives**: Common name+DOB combinations will flag unrelated customers. Is there a secondary validation step?
3. **FundingID = 1 exclusion**: What does FundingID = 1 represent? Why is it excluded from relation detection?
4. **Monthly reprocessing**: Each run reprocesses the entire month. Does this mean late-arriving deposits can change FundingRelation flags for previously processed CIDs?
