# Review: Dealing_dbo.Dealing_MIMO_Zero

## Unverified Claims
1. **"Zero" terminology**: Interpreted as "implicit FX revenue with zero explicit fee" — confirm with dealing desk
2. **Net formula correction (2023-08-06)**: Changed from `Deposits - Withdraws` to `Deposits + Withdraws` — confirm this is because Withdraws are stored negative in the source

## Questions for Domain Expert
1. How does this relate to the "Zero" calculations in BI_DB tables (e.g., BI_DB_Crypto_Zero, BI_DB_DailyZero_TreeSize_NEW)?
2. Is the rolling total (Net_Rolling_Zero) used in any financial reporting?
3. Are there any currencies excluded beyond crypto (600-610)?

## Reviewer Corrections
_(none yet)_
