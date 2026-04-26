# BI_DB_dbo.BI_DB_Employees_Program — Review Needed

## Tier 4 Items
None — all columns traced to SP code.

## Reviewer Questions

1. **OpsDB says Monthly, SP runs daily**: OpsDB lists FrequencySP='Monthly' but the SP has no date guard (unlike SP_Diversification which checks EOM/15th). Confirm actual execution frequency.

2. **PII exposure**: Table contains FirstName, LastName, UserName, Email. Is this appropriate for the BI_DB schema, or should PII be masked?

3. **Program year start date drift**: The reset date has changed 3 times (May 9 → Apr 7 → Apr 5). Is this driven by fiscal year changes?

4. **RealCID 149**: Same hardcoded special account as Employee_Crypto_NWA. Confirm purpose.

5. **IsEligible criteria**: Two paths (50% invested OR 100+ actions with 10x volume/equity). Are these thresholds documented in an HR policy?

6. **DDL column count = 24**: Matches the batch assignment. Element 1 is the ID column — wait, there's no ID column here. DDL has exactly 24 columns.

## Data Quality Notes
- 2,076 rows, all from 2026-03-31 (TRUNCATE+INSERT, only latest snapshot)
- 1,197 eligible (57.7%), 879 not eligible (42.3%)
- PII columns: FirstName, LastName, UserName, Email present
