# BI_DB_dbo.BI_DB_RAF_Invitees_KPIs — Review Needed

## Tier 4 Items

13 columns classified as Tier 4 (legacy). All are columns not populated by the current SP_RAF_InviteeAbuser:

| Column | Notes |
|--------|-------|
| FunnelName | varchar(255), older rows may have data from prior SP version |
| DesignatedRegulationID | int, older rows may have data |
| RevenueFromUser | decimal(18,0), older rows may have data |
| NoOfTotalCashout | int, older rows may have data |
| FirstPosOpenDate | datetime, older rows may have data |
| Cashout_request | datetime, older rows may have data |
| Cashout_date | datetime, older rows may have data |
| Revenue14days | decimal(38,2), older rows may have data |
| FTDMeanOfPayment | nvarchar(max), older rows may have data |
| LastCashoutDate | datetime, older rows may have data |
| TradesAmount | decimal(38,2), older rows may have data |
| TradesAmount_tillRAFbonus | decimal(38,2), older rows may have data |
| Date_AccTrade100_Invitee | date, older rows may have data |
| Date_AccTrade100_Inviter | date, older rows may have data |

## Questions for Reviewer

1. **14 legacy columns -- should they be dropped?** These columns are not populated by the current SP_RAF_InviteeAbuser (Nitsan Sharabi, 2022-04-07). Some contain historical data from prior SP versions for older rows, but all newer rows are NULL. Can these be safely removed from the DDL, or are there downstream consumers still reading old data?

2. **INSERT syntax uses table alias in column list**: The SP appears to use `f.Invitee` (table alias) in the INSERT column list. This is syntactically unusual -- standard SQL INSERT column lists do not use aliases. Verify whether this is a Synapse-specific syntax allowance or a latent bug that happens to work.

3. **Column name typo -- MatualIPAdress30Days**: "Matual" should be "Mutual" and "Adress" should be "Address". This typo is preserved in the DDL for backward compatibility. Should this be renamed with an ALTER + downstream consumer update?

4. **SP calls sub-SP SP_History_Credit_Range**: The writer SP calls `SP_History_Credit_Range` as a dependency to refresh History_Credit_Range before reading from it. Confirm this sub-SP is tracked in OpsDB and runs before SP_RAF_InviteeAbuser, or whether the embedded EXEC call is the sole trigger.

5. **Column count discrepancy**: Batch assignment stated 39 columns but DDL analysis yields 38. Verified by counting DDL lines. Confirm the correct count.

6. **314K rows with NULL abuse flags**: These legacy rows (registered before ~2022) have no isAbuser, MatualIPAdress30Days, or isCashoutAfterCompensation values. Should these be backfilled with the current SP logic, or are they considered historical and intentionally left as-is?

7. **Rolling 2-month window gap risk**: The refresh only covers `registered >= @Last2months`. If the SP fails for an extended period, invitees who age past the 2-month window will never be refreshed again. Is there a backfill mechanism or alerting for missed runs?

## Tier Summary

- **Tier 2 (24 columns)**: All active columns populated by SP_RAF_InviteeAbuser (Invitee, Country, State, Inviter, registered, FirstDepositDate, FirstDepositAmount, PaymentToInvitee, PaymentToInviter, NoOfTotalDeposits, TotalDepositAmount, TotalCashoutAmount, Compensation_date, NewTrades, MatualIPAdress30Days, NoOfTotalCashout14DaysFromFTD, TotalCashoutAmount14DaysFromFTD, IsFundedAfter14Days, TotalCashoutAmountAfterCompensation, EligibleForCompensation, isCashoutAfterCompensation, isFTD30days, isAbuser)
- **Tier 4 (13 columns)**: All legacy columns not populated by current SP
- **Tier 5 (1 column)**: UpdateDate (ETL metadata)
