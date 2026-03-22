# Dealing_dbo.Dealing_Employee_Zero_StocksETFs — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Columns Needing Clarification

| Column / Topic | Question | Evidence |
|----------------|----------|----------|
| Table name vs scope | Table is named "StocksETFs" but includes all 6 instrument types. Should the table be renamed? | SP code: `--AND i.InstrumentTypeID IN (5,6)` — filter commented out |
| CountryID=250 | Is CountryID=250 confirmed as Israel? Are there employee accounts in other countries that should be tracked? | SP filter: `AND CountryID = 250` |
| AccountTypeID 13 | What is "Analyst (CF employees)" — are CF employees a specific team within eToro? | SP comment: `13- Analyst (CF employees)` |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
