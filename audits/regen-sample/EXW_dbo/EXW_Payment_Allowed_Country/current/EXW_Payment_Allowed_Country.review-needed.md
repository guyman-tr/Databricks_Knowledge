---
object: EXW_dbo.EXW_Payment_Allowed_Country
review_priority: LOW
batch: 9
---

# EXW_Payment_Allowed_Country — Review Flags

## Flags

| # | Flag | Severity | Detail |
|---|------|----------|--------|
| 1 | All PaymentAllowed = 0 — confirm business context | LOW | All rows currently have PaymentAllowed=0. Confirmed as expected (Simplex payments discontinued). No data quality issue. |
| 2 | AllowedUser vs Cryptos ResourceId — SP source not fully confirmed | LOW | The exact EXW_Settings ResourceId values for AllowedUser* and Cryptos* columns were not confirmed from SP line 1515 context. Verify against SP_EXW_WalletElligibleCountries around line 1515. |
| 3 | Crypto lookup source unknown | LOW | Same as Staking table — source table for Crypto name not identified. |

## No blocking issues. File is complete.
