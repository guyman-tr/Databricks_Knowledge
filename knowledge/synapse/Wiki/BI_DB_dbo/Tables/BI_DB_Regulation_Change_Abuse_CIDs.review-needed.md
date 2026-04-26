# Review Needed: BI_DB_dbo.BI_DB_Regulation_Change_Abuse_CIDs

## Known Anomalies

- **No audit trail of first-flag date**: The MERGE DELETE clause removes ex-abusers from the table. There is no history of when a CID was first added, how long they appeared, or when they were removed. If a customer reduces their change count below 6 (e.g., due to data correction in Fact_SnapshotCustomer), their record disappears with no trace.

- **RC columns capture the regulation moved TO, not from**: RC1='CySEC' means "the customer changed to CySEC on their 1st change event", not "they changed away from CySEC". The regulation they came FROM is not stored directly — it would be the customer's Regulation attribute or inferred from the prior RC value.

- **Customers with >15 changes lose history**: RC15 is the maximum captured. Three customers in the current snapshot have more than 15 changes (max 46, 28). Their changes beyond RC15 are invisible in this table. For a complete history, query Fact_SnapshotCustomer directly with the LAG logic.

- **Financial exposure columns are ISNULL(x, 0)**: RealizedEquity, UnRealizedEquity, and TotalPositionsAmount are coalesced to 0 for customers not in DWH_dbo.V_Liabilities on @DateID. Old/inactive abusers will show 0 for all three — this is NOT necessarily their actual exposure; it may mean they had no positions on that date or V_Liabilities didn't cover them.

- **CySEC extreme outlier (max 21 in Categories, FinCEN max 46 in CIDs)**: The customer with 46 regulation changes is under FinCEN regulation in the current state. This is an extreme outlier (2x the second-highest). It may represent a system/test account or an automated process cycling jurisdictions. Manual review recommended.

- **MostRecentOpenPosition includes closed positions**: The column is `MAX(CAST(OpenOccurred AS DATE))` across ALL Dim_Position rows (not filtered to open positions). It shows when the most recent position was OPENED, not when any position was last active. A customer who opened a position 3 years ago (long since closed) could still show a 3-year-old MostRecentOpenPosition.

## Tier 4 / Low-Confidence Items

No Tier 4 columns. All 32 columns fully traced to SP code.

## Reviewer Questions

1. **Abuse threshold business definition**: Why is 6 the threshold? Is this a compliance-defined threshold (tied to a specific regulatory requirement) or an operational/heuristic value chosen by the data team? Understanding the definition affects whether customers with 5 changes should be considered "at risk" or definitively innocent.

2. **RC direction (to vs. from)**: Please confirm — does RC1 contain the regulation the customer MOVED TO (new regulation) or MOVED FROM (old regulation) on their first change event? From the SP CASE logic (`rgc.RegDesc` where `rgc.RegChangeRowNum=1`), it appears to be the regulation associated with the change event row in #regulation02, which is the NEW regulation.

3. **V_Liabilities DateID scope**: The SP queries `V_Liabilities WHERE DateID=@DateID`. For an abuser who has no positions open on @DateID (all closed long ago), will V_Liabilities return NULL (giving 0 via ISNULL) or a row with zeros? If V_Liabilities only covers active-position customers, the financial exposure for dormant abusers is silently coerced to 0.

4. **Decrease in Total_RegChangeCount**: Can a customer's change count decrease (e.g., if Fact_SnapshotCustomer is corrected retroactively)? If so, the DELETE clause would remove their record. Has this ever happened? Knowing whether deletions are purely organic (customer leaves eToro) or also corrections-driven affects trust in the historical consistency of this table.

5. **FTDMonthYear format consistency with Categories**: Confirm whether FTDMonthYear in this table uses the same text format as in BI_DB_Regulation_Change_Abuse_Categories (they should match for JOINs to work cleanly).
