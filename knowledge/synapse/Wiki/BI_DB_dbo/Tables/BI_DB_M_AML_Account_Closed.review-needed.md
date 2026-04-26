# Review Needed: BI_DB_dbo.BI_DB_M_AML_Account_Closed

## Tier 4 Items (Needs Verification)

- None. All columns traced to SP code (Tier 2) or ETL metadata (Tier 5).

## Questions for Reviewer

1. **Data freshness**: Last EOM in the table is 2024-04-30 (2,060 total rows). The SP appears to have stopped running after April 2024. Is this intentional? Has this report been replaced by another object?
2. **Column typo**: `Regualtion` is misspelled in the DDL. Should this be corrected via ALTER TABLE, or is it preserved intentionally for backward compatibility?
3. **ValidFrom/ValidTo as varchar**: These columns store formatted datetime strings as varchar(250). The source is general.etoro_History_BackOfficeCustomer which may store them this way. Was this a deliberate design choice or an oversight?
4. **Salesforce filter semantics**: All rows in the output have passed the SF case AML filter (ActionType_AtOpen LIKE '%AML%' within 30 days). This means rows with Is_AML_Reason=0 are NOT "non-AML" — they have AML-correlated SF cases but a different PlayerStatusReason text. Is this the intended business logic?

## Cross-Object Consistency

- CID: consistent with BI_DB_dbo convention (int, from Fact_SnapshotCustomer.RealCID)
- Regulation values: 8 distinct — same set as other BI_DB AML objects

## Corrections Applied

- None.
