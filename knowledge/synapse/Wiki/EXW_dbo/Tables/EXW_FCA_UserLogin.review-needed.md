---
object: EXW_dbo.EXW_FCA_UserLogin
review_priority: LOW
batch: 9
---

# EXW_FCA_UserLogin — Review Flags

## Flags

| # | Flag | Severity | Detail |
|---|------|----------|--------|
| 1 | "FCA" naming is a misnomer | LOW | Table name implies FCA-only users but all wallet users' login events are included. Downstream consumers may incorrectly assume FCA regulation scope. Consider documenting this in any external consumer documentation. |
| 2 | StatusID NULL fraction unknown for EXW subset | LOW | FCA wiki notes "NULL for ~2M rows" (FCA-wide). The NULL fraction for the EXW wallet subset is unknown. For compliance reporting, confirm NULL StatusID rows are handled correctly. |
| 3 | PlatformID → Dim_Product join | LOW | PlatformID references Dim_Product.ProductID (despite the misleading column name). Any consumer joining on PlatformID should use DWH_dbo.Dim_Product, not a "platform" dimension. |
| 4 | CountryIDByIP vs user's registered country | LOW | CountryIDByIP reflects login-time geolocation, which may differ from user's registered country (EXW_DimUser.CountryID). FCA compliance analysis should clarify which country is required: registered or login-time. |

## No blocking issues. File is complete.
