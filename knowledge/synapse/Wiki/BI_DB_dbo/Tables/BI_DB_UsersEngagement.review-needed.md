# BI_DB_dbo.BI_DB_UsersEngagement — Review Needed

## Tier 4 Items

None — no Tier 4 descriptions in this wiki.

## Questions for Reviewer

1. **ActionTypeID=5 exclusion**: What action type is ID=5? The SP filters it out but no comment explains why.
2. **CID 5052186**: Hardcoded exclusion in the SP. Is this still a valid test account?
3. **TotalDeposit always NULL**: Disabled since 2024-01-30 by Ofir Chloe Gal. Should this column be removed from the DDL?
4. **BI_DB_Social_Activity**: No wiki exists for this upstream source table. Many columns (ActionID, ActionType, ActionDate, MessageText, ActionDateID) are Tier 2 because of this gap. Building a wiki for Social_Activity would elevate 5 columns to Tier 1.
5. **Data freshness**: MAX(ActionDateID) = 20250223 (Feb 2025) — table appears to not be refreshing. Is the SP still running?

## Corrections Log

- DDL shows 20 columns (batch assignment estimated 24). Documented 20.

## Cross-Object Consistency

- **RealCID** description inherited verbatim from Dim_Customer wiki (Tier 1 — Customer.CustomerStatic)
- **UserName** description inherited verbatim from Dim_Customer wiki (Tier 1 — Customer.CustomerStatic)
- **Country** description inherited verbatim from Dim_Country.Name wiki (Tier 1 — Dictionary.Country)
- **Region** description inherited verbatim from Dim_Country.Region wiki (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse)
- **Channel** description inherited from BI_DB_CIDFirstDates wiki (Tier 2)
- **Blocked** description inherited from BI_DB_CIDFirstDates wiki (Tier 2)
- **FirstDepositDate** description inherited from BI_DB_CIDFirstDates wiki (Tier 2)
- **ActiveTrader** description inherited from BI_DB_CID_MonthlyPanel_FullData.Active wiki (Tier 2)
- **ActiveUser** description inherited from BI_DB_CID_MonthlyPanel_FullData.ActiveUser wiki (Tier 2)
