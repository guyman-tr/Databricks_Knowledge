---
object: EXW_dbo.EXW_Conversion_Allowed_Country
review_priority: LOW
batch: 9
---

# EXW_Conversion_Allowed_Country — Review Flags

## Flags

| # | Flag | Severity | Detail |
|---|------|----------|--------|
| 1 | All conversion flags = 0 — confirm business context | LOW | FromConversionAllowed and ToConversionAllowed are all 0. Confirmed as expected (crypto conversions discontinued). No data quality issue. |
| 2 | Column order anomaly | LOW | Country column precedes CountryID in the DDL (opposite to EXW_Staking and EXW_Payment tables). This is the original DDL order. Downstream consumers using SELECT * will see Country before CountryID. |
| 3 | CountryID nullable | LOW | In this table, CountryID is nullable (unlike the other two Allowed_Country tables where CountryID is NOT NULL). Confirm this is intentional in the DDL. |
| 4 | From vs To ResourceName — SP source not fully confirmed | LOW | The exact EXW_Settings ResourceId values for From* and To* direction settings were not confirmed. Verify against SP_EXW_WalletElligibleCountries around line 2287. |

## No blocking issues. File is complete.
