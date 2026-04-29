# BI_DB_dbo.BI_DB_RiskPayPalDepositors — Review Needed

## Tier 3 Items (Require Verification)

- **Region** (Tier 3): Sourced from Dim_Country.MarketingRegionManualName which itself is Tier 3 (Ext_Dim_Country live data). Manual override — verify current mapping accuracy.
- **PEPStatus** (Tier 3): Sourced from Dim_ScreeningStatus.Name. ScreeningService dictionary — verify if upstream wiki becomes available.

## Questions for Reviewer

1. Is this table still actively used for risk monitoring? Last data is April 2026.
2. The SP filters FundingTypeID=3 for PayPal — should other e-wallet types (e.g., Skrill, Neteller) be included?
3. RiskStatus comes from External_etoro_BackOffice_CustomerRisk which is a production external table — is this the current authoritative risk source or has it been superseded?
4. TotalDeposits is ALL approved deposits (not just PayPal) — is this intentional or should it be PayPal-only?

## Validation Notes

- Column count: 18 DDL = 18 wiki elements (MATCH)
- All 8 sections present
- Tier distribution: 8 T1, 7 T2, 2 T3, 0 T4, 1 T5
