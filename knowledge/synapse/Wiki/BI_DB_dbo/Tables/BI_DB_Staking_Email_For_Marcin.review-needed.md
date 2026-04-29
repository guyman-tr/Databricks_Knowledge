# BI_DB_dbo.BI_DB_Staking_Email_For_Marcin — Review Needed

## Questions for Reviewer

1. Named after a specific person ("Marcin") — is the recipient still active? Should the table be renamed?
2. All numeric columns stored as nvarchar(max) formatted strings — is this intentional for email embedding?
3. TRUNCATE+INSERT loses all history — should a date-partitioned version exist for trend analysis?
4. Only ADA and TRX — are other staking-eligible crypto instruments (e.g., ETH2) excluded intentionally?
5. UK post-Feb-2022 exclusion — is this date threshold still current?

## Validation Notes

- Column count: 8 DDL = 8 wiki elements (MATCH)
- All 8 sections present
- Tier distribution: 0 T1, 7 T2, 0 T3, 0 T4, 1 T5
