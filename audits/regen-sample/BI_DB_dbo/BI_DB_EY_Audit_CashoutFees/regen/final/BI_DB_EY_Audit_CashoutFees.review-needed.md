# Review Needed: BI_DB_dbo.BI_DB_EY_Audit_CashoutFees

## Open Questions

1. **Commission predominantly 0.0**: In the sampled data, Commission is 0.0 for all visible rows. Confirm whether processed cashouts (ActionTypeID=30) typically carry zero commission, or whether fee-bearing cashouts are a small minority. The SP negates and sums `ca.Commission` — verify that the source Commission column on ActionTypeID=30 rows is the correct fee field for EY audit purposes.

2. **Data ends at 2025-10-27**: The last loaded DateID is 20251027. Confirm whether this table's daily refresh is still active or has been paused. The SP includes gap-fill logic, so if restarted it would backfill automatically.

3. **IsCreditReportValidCB scope**: The filter restricts the audit population to credit-report-valid customers. Confirm this is the intended EY audit scope and not an overly restrictive filter that excludes relevant cashouts.

## Tier 1 Inheritance Verification

All 7 Tier 1 columns were inherited from upstream dimension wikis via dim-lookup passthrough:
- RealCID: from Fact_CustomerAction wiki (origin: Customer.CustomerStatic)
- WithdrawID: from Fact_CustomerAction wiki (origin: History.Credit)
- Occurred: from Fact_CustomerAction wiki (origin: source-dependent)
- Regulation: from Dim_Regulation wiki (origin: Dictionary.Regulation)
- Club: from Dim_PlayerLevel wiki (origin: Dictionary.PlayerLevel)
- Country: from Dim_Country wiki (origin: Dictionary.Country)
- AccountType: from Dim_AccountType wiki (origin: Dictionary.AccountType)
- PopularInvestors: from Dim_GuruStatus wiki (origin: Dictionary.GuruStatus)

No Tier 4 columns. No unresolved lineage gaps.
