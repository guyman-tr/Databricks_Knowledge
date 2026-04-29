# BI_DB_dbo.BI_DB_RiskAlertManagementTool — Review Needed

## Tier 4 Items (Low Confidence)

81 columns (cols 23-103) are extracted from JSON fields and documented based on field name inference only. No upstream AlertServiceDB documentation exists. All are marked Tier 4.

**High-priority Tier 4 items needing verification**:
1. **SiftScore**: Confirmed as Sift Science ML fraud score from AlertType distribution, but exact scale (0-100? 0-1000?) unknown.
2. **TelesignScore / AllowedTelesignScore**: Phone verification risk scores — threshold relationship unclear.
3. **NameConflictScore**: Numeric score for name mismatch — scale and interpretation unknown.
4. **RiskClassification / RiskClassification1**: Customer risk level — possible values unknown (Low/Medium/High? Numeric?).
5. **CurrenctISON**: Typo in column name (source JSON field is also misspelled).

## Questions for Reviewer

1. **Element count**: DDL has 105 columns but wiki documents 103. Two columns (cols 19-20 in the DDL are `Tables` which is documented, and line 22 `RN1` and `UpdateDate`) — need to verify the mapping is complete. The wiki covers AlertID through RiskClassification1 = 103 rows in Elements table. DDL positions map: UpdateDate is at position 22 in DDL but documented as col 22 here. The 2 extra DDL columns vs 103 elements needs reconciliation.
2. **Historical table**: The `Tables` column is always 'Current'. Was there a Historical variant that was decommissioned?
3. **Assignee/ModifiedBy IDs**: What lookup table resolves these to names? Are they internal AlertServiceDB user IDs or etoro employee IDs?
4. **Column count drift**: The SP was extended in November 2025 to add 81 JSON columns. Are more JSON fields planned? The EvaluationContext has many more fields than the 44 currently extracted.
5. **PII concern**: CustomerName, KycCustomerName, DepositCustomerName, AmopCustomerName, NameOnMop1 — are these full names? Should they be masked for non-compliance users?

## Upstream Verification

No upstream wiki exists for AlertServiceDB. All non-core columns are Tier 4 (JSON field name inference).
