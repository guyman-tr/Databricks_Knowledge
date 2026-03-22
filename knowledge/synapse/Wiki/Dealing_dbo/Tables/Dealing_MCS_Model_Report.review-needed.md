# Review Notes — Dealing_dbo.Dealing_MCS_Model_Report

**Status**: Active ✅

## Items Requiring Human Review

1. **MCS model definition**: "Market Coverage Score" is an inferred name — confirm the official meaning of the MCS acronym and what the model validates.

2. **1.116B row scale**: COUNT(*) on this table requires COUNT_BIG(*) — confirm all downstream consumers use COUNT_BIG to avoid silent truncation errors.

3. **IsValidCustomer=1 filter**: The SP filters to IsValidCustomer=1. Confirm whether this filter should change if eToro's employee/test account classification changes.

4. **InstrumentTypeID scope**: Table covers only types 5 (Real Stocks) and 6 (ETFs). If new Real asset types are added (e.g., Real Bonds), confirm whether the SP should be extended.

5. **Date range check**: Data starts 2023-09-01 — confirm whether pre-September 2023 historical data exists elsewhere, or if this represents the program start date.
