# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end — Review Needed

## Tier 4 Items

None — all columns resolved to Tier 1, Tier 2, or Tier 3.

## Questions for Reviewer

1. **Is_Closed_Account logic**: The compound condition `PlayerStatusID IN (2,4) AND PlayerStatusReasonID IN (3,6,40)` identifies closed accounts. Are reasons 3, 6, and 40 the complete set of "genuine" closure reasons, or should additional reason IDs be included?
2. **Is_Suspended_Account logic**: `PlayerStatusID NOT IN (1,2,4,5)` — this captures everything except Normal (1), Blocked (2), Blocked Upon Request (4), and one other status (5). What is PlayerStatusID=5 and why is it excluded from "suspended"?
3. **Investor type flags exclusivity**: The four investor type flags (Seychelles/US/EU/Other) appear mutually exclusive, but a Seychelles customer could theoretically also be in the EU. Confirm the priority order: Seychelles > US > EU > Other.
4. **Report_End_Date as int**: The quarter-end date is stored as an integer (e.g., 20240331). Is there a risk of non-quarter-end dates being inserted if the SP is run with incorrect parameters?
5. **DepositesOrCashout typo**: The column name contains a spelling error ("Deposites" instead of "Deposits"). Is this a known legacy issue or should it be corrected in DDL?
6. **RiskGroupID**: This column is passed through from Fact_SnapshotCustomer but its business meaning is not fully documented. What are the possible values and their regulatory significance?
7. **Desk column (Tier 3)**: Desk is inferred from Dim_Country but the exact source column name needs verification. Confirm it maps to Dim_Country.Desk.

## Corrections Applied

- None required — column count matches DDL (32 columns).

## Tier Summary

- **Tier 1 (2 columns)**: CID (Customer.CustomerStatic), Country (Dictionary.Country)
- **Tier 2 (29 columns)**: Regulation, PlayerStatus, PlayerStatusReasons, PlayerStatusSubReasonName, EU, Region, RiskGroupID, SeychellesCategorization, Account_Type_Group, Account_Type, Age_Group, Age, MifidCategorization, ScreeningStatus, Is_PEP, Is_Closed_Account, Is_Suspended_Account, Is_Seychelles_Investor, Is_United_States_Investor, Is_EU_Investor, Is_Other_Country_Investor, OpenedOrClosedPos, DepositesOrCashout, Is_Active, Is_High_Net_Worth, UnrealizedEquity, RealizedEquity, Report_End_Date, UpdateDate
- **Tier 3 (1 column)**: Desk (inferred from Dim_Country)

## Reviewer Instructions

1. Verify the exact SP parameters used for quarterly runs (date parameters, RegulationID confirmation)
2. Confirm investor type flag priority/exclusivity logic
3. Validate Is_Closed_Account and Is_Suspended_Account PlayerStatusID sets
4. Check if RiskGroupID has a dictionary/dimension table for value descriptions
