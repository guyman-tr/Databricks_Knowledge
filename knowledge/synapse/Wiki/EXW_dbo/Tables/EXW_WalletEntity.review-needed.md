---
object: EXW_dbo.EXW_WalletEntity
review_priority: LOW
batch: 9
---

# EXW_WalletEntity — Review Flags

## Flags

| # | Flag | Severity | Detail |
|---|------|----------|--------|
| 1 | WalletEntity entity name list may be incomplete | LOW | BI_DB_dbo.External_WalletDB_Dictionary_EtoroLegalEntities drives entity names. New entities may be added without SP changes. Verify current distinct values in the table. |
| 2 | TermsAndConditionTime column type mismatch | LOW | Column is DDL-typed as `datetime`, but the name implies time-only. Confirm analysts are not incorrectly treating it as a time column. The full acceptance datetime is stored. |
| 3 | JoinDate vs. EXW_DimUser.UpdateDate | LOW | JoinDate in this table = MIN(EXW_Wallet.CustomerWalletsView.Occurred) per Gcid. The EXW_DimUser wiki notes this is wallet activation date, not eToro registration. Confirm this matches intended usage in downstream reports. |
| 4 | CountryID=169 (Excluded) — verify mapping | LOW | The SP excludes CountryID=169 from settings-based entity assignment. Verify 169 = the intended OFAC/restricted country code in Dim_Country. |

## No blocking issues. File is complete.
