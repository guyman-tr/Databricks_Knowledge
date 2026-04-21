---
object: EXW_dbo.EXW_Staking_Allowed_Country
review_priority: LOW
batch: 9
---

# EXW_Staking_Allowed_Country — Review Flags

## Flags

| # | Flag | Severity | Detail |
|---|------|----------|--------|
| 1 | All StakingAllowed = 0 — confirm business context | LOW | All rows currently have StakingAllowed=0. Confirmed as expected (ETH staking discontinued). No data quality issue. |
| 2 | CryptoID derivation from ResourceName — verify SP logic | LOW | CryptoID is described as derived from the ResourceName path pattern. The exact SP logic for this extraction was not fully confirmed. Verify against SP_EXW_WalletElligibleCountries around line 2600. |
| 3 | Crypto lookup source unknown | LOW | The source table for Crypto name text was not identified in the SP analysis. May come from BI_DB dictionary or WalletDB crypto tables. |

## No blocking issues. File is complete.
