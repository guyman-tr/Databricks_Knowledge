---
object: EXW_dbo.EXW_WalletUsers_30_Days
type: Table
batch: 9
---

# EXW_WalletUsers_30_Days — Column Lineage

| DWH Column | Source Column | Source Object | Transform | Tier |
|-----------|---------------|---------------|-----------|------|
| GCID | GCID | `EXW_dbo.EXW_DimUser` → `etoro.Customer.CustomerStatic` | Passthrough via EXW_DimUser | Tier 1 |
| RealCID | RealCID | `EXW_dbo.EXW_DimUser` → `etoro.Customer.CustomerStatic` | Passthrough via EXW_DimUser | Tier 1 |
| VerificationLevelID | VerificationLevelID | `EXW_dbo.EXW_DimUser` → `etoro.BackOffice.Customer` | Passthrough via EXW_DimUser | Tier 1 |
| Club | Club | `EXW_dbo.EXW_DimUser` (SP_DimUser: `Dim_PlayerLevel.Name`) | Passthrough of SP_DimUser–computed label | Tier 2 |
| Country | Country | `EXW_dbo.EXW_DimUser` (SP_DimUser: `Dim_Country.Name`) | Passthrough of SP_DimUser–derived text label | Tier 2 |
| Region | Region | `EXW_dbo.EXW_DimUser` (SP_DimUser: `Dim_Country.Region`) | Passthrough of SP_DimUser–derived marketing region name | Tier 2 |
| Continent | Continent | Hardcoded `#countryandcontinent` ISO table in SP + `DWH_dbo.Dim_Country.Abbreviation` | `LEFT JOIN Dim_Country ON edu.CountryID = dc.CountryID, LEFT JOIN #countryandcontinent ON dc.Abbreviation = c.CountryCode → CASE WHEN Country='eToro' THEN 'eToro' ELSE Continent END` | Tier 2 |
| LoggedIn30Days | LastLoggedIn | `BI_DB_dbo.BI_DB_CIDFirstDates` | `CASE WHEN fca.GCID IS NOT NULL THEN 1 ELSE 0` where fca = CIDFirstDates `WHERE LastLoggedIn >= CAST(GETDATE()-31 AS DATE)` | Tier 2 |
| Transaction30Days | GCID | `EXW_dbo.EXW_FactTransactions` | `CASE WHEN eft.GCID IS NOT NULL THEN 1 ELSE 0` where eft has `TranDateID >= CAST(CONVERT(VARCHAR(8), GETDATE()-31, 112) AS INT) AND TransactionTypeID NOT IN(10,13)` | Tier 2 |
| UpdateDate | — | SP_EXW_WalletUsers_30_Days | `GETDATE()` at insert time | Tier 2 |

## ETL Pipeline

```
etoro.Customer.CustomerStatic + BackOffice.Customer (production OLTP)
  └─ DWH_dbo.Dim_Customer → EXW_dbo.EXW_DimUser (699K wallet users)
       ├─ GCID, RealCID, VerificationLevelID, Club, Country, Region (passthrough)
       └─ CountryID → JOIN DWH_dbo.Dim_Country ON CountryID → #countryandcontinent (Continent)

BI_DB_dbo.BI_DB_CIDFirstDates
  └─ WHERE LastLoggedIn >= GETDATE()-31 → LoggedIn30Days flag

EXW_dbo.EXW_FactTransactions
  └─ WHERE TranDateID >= GETDATE()-31 AND TransactionTypeID NOT IN(10,13) → Transaction30Days flag

TRUNCATE TABLE EXW_dbo.EXW_WalletUsers_30_Days
INSERT ... SELECT DISTINCT from #users (no date parameter — always current-state)
```
