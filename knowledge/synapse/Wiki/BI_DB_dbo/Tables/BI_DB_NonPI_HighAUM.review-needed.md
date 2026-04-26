# BI_DB_dbo.BI_DB_NonPI_HighAUM — Review Needed

## Tier 4 Items

None — all columns traced to SP code (Tier 2).

## Questions for Reviewer

1. **Column count**: DDL has 10 columns, batch assignment said 11. Verified: 10 in DDL and INSERT.
2. **BI_DB_NonPI_HighAUM column**: Column has same name as the table. Both it and UpdateDate are set to GETDATE(). One is redundant.
3. **AUM column name in DDL**: DDL has trailing space in the SP (`'AUM '` — space after AUM). May cause subtle issues.
4. **GuruStatusID filter**: GuruStatusID IN (0,1) or NULL excludes Popular Investors (GuruStatusID=2+). Verify this is the correct non-PI definition.
5. **PlayerLevelID<>4**: What is PlayerLevelID=4? Likely a specific tier being excluded. Verify.
6. **AccountTypeID!=9**: What is AccountTypeID=9? Likely analyst/demo accounts.
7. **72 rows**: Very small table — only 72 non-PI CopyTrader parents with AUM>$15K and copiers. Is this expected?
8. **UC migration**: _Not_Migrated.

## Corrections Applied

- Column count corrected from 11 to 10.
