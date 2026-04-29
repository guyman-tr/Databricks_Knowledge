# BI_DB_dbo.BI_DB_StocksETFs_SignificantAllocation — Review Needed

## Tier 4 / Unverified Items

- None — all columns traced to SP code and upstream wikis.

## Questions for Reviewer

1. **Table currently empty (0 rows)**: Is this expected? The INNER JOIN to #Contact (BI_DB_UsageTracking_SF) means customers without any email/phone contact history are excluded. Could this be filtering out all qualifying customers?
2. **SP description mismatch**: SP header says "Insert Data into BI_DB_CID_DailyPanel_Club" but writes to BI_DB_StocksETFs_SignificantAllocation. Copy-paste from a different SP?
3. **Balance/Equity truncated to int**: Values from V_Liabilities.Credit and RealizedEquity (money type) are cast to int, losing fractional cents. Is this intentional?
4. **Is this table still actively used?** 0 rows suggests it may be deprecated or the SP may not be running.

## Corrections Applied

- None.

## Atlassian

- Atlassian search unavailable (permission denied).
