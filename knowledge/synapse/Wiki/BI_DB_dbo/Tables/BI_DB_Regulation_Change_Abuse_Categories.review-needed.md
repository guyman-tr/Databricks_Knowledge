# Review Needed: BI_DB_dbo.BI_DB_Regulation_Change_Abuse_Categories

## Known Anomalies

- **NULL = zero changes (not missing data)**: `Total_RegChangeCount IS NULL` means the customer group has zero detected regulation changes, due to the LEFT JOIN from the depositor population to the change-detection results. This is intentional design, not a data quality issue. Queries that filter `WHERE Total_RegChangeCount IS NOT NULL` exclude the zero-change majority.

- **Demographic attributes reflect CURRENT state, not historical**: The Regulation, Country, AccountType, PlayerLevel, and PlayerStatus columns show the customer's **current** attributes at run time. A CySEC customer who previously changed from FSA Seychelles will appear under CySEC. The table does not preserve the regulation at the time of change — that detail is in Fact_SnapshotCustomer.

- **FTDMonthYear format**: The exact text format for FTDMonthYear was not confirmed from SP code (e.g., 'Jan-2024' vs. '2024-01' vs. '202401'). Data samples showed values consistent with 'Mon-YYYY' format. Verify format before using in GROUP BY or string comparisons.

- **FinCEN outlier (max 46 changes)**: The distribution data shows one CID with 46 regulation changes under FinCEN. This may be a data anomaly (system account, test account, or edge case in the LAG logic) or a genuine extreme case. Any analysis of FinCEN max changes should validate this row separately.

## Tier 4 / Low-Confidence Items

No Tier 4 columns. All columns traced to SP code or upstream dimension wikis.

## Reviewer Questions

1. **Regulation attribute: current or at-change-time?** Confirmed from SP code that demographics come from Dim_Customer (current state). Confirm: is this intentional for the use case? If analysts need to know "what regulation was this customer in when they changed?", this table cannot answer that — they would need to query Fact_SnapshotCustomer with the LAG logic directly.

2. **FTDMonthYear: depositors with no FTD?** The population includes `IsDepositor=1`, so all customers should have a valid FTD date. Confirm: can FTDMonthYear be NULL or a sentinel value (e.g., '1900-01') for any rows, or is it always a valid month label?

3. **Total_RegChangeCount = 0 vs. NULL**: The SP uses a LEFT JOIN, so non-changers get NULL not 0. Confirm: is there a separate path in the SP that would produce Total_RegChangeCount=0 (as opposed to NULL)? Checking whether both 0 and NULL exist in the data would clarify the handling.

4. **Change threshold for the companion CIDs table**: The companion `BI_DB_Regulation_Change_Abuse_CIDs` only includes customers with Total_RegChangeCount >= 6. Is the threshold of 6 a business-defined abuse threshold, or an arbitrary cutoff? Understanding the threshold definition affects how to interpret the Categories table for "abusive" segments.

5. **"Current regulation" denominator issue**: When computing "% of CySEC customers with 2+ changes", should the denominator be all current CySEC customers or all customers who were EVER in CySEC? This table uses current CySEC, which would undercount customers who changed away from CySEC.
