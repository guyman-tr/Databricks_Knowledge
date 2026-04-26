# Lineage: BI_DB_dbo.BI_DB_Blocked_Customers

## Object Metadata

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object** | BI_DB_Blocked_Customers |
| **Type** | Table |
| **Writer SP** | BI_DB_dbo.SP_Blocked_Customers |
| **Primary Source** | DWH_dbo.Dim_Customer (WHERE PlayerStatusID <> 1) |
| **Secondary Source** | DWH_dbo.V_Liabilities (per-customer daily financials) |
| **Tertiary Source** | BI_DB_dbo.BI_DB_CIDFirstDates (LastLoggedIn aging) |
| **Upstream Wiki** | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md |
| **UC Target** | _Not_Migrated |

## ETL Chain

```
DWH_dbo.Dim_Customer (WHERE PlayerStatusID <> 1)
  + DWH_dbo.V_Liabilities (@DateID filter)
  + BI_DB_dbo.BI_DB_CIDFirstDates (LastLoggedIn_Group aging)
  + DWH_dbo.Dim_Regulation, Dim_Country, Dim_AccountStatus, Dim_AccountType,
    Dim_MifidCategorization, Dim_PlayerStatus, Dim_PlayerLevel,
    Dim_PlayerStatusReasons, Dim_PlayerStatusSubReasons (name resolution JOINs)
  |-- SP_Blocked_Customers @Date (TRUNCATE + INSERT GROUP BY) ---|
  v
BI_DB_dbo.BI_DB_Blocked_Customers (234,804 rows — pre-aggregated segments)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | RegulationID | DWH_dbo.Dim_Customer | RegulationID | Passthrough as GROUP BY key | Tier 1 |
| 2 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on RegulationID=DWHRegulationID, resolved name | Tier 2 |
| 3 | CountryID | DWH_dbo.Dim_Customer | CountryID | Passthrough as GROUP BY key | Tier 1 |
| 4 | Country | DWH_dbo.Dim_Country | Name | JOIN on CountryID, resolved name | Tier 2 |
| 5 | Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on dc.PlayerLevelID, resolved club name | Tier 2 |
| 6 | AccountStatusID | DWH_dbo.Dim_Customer | AccountStatusID | Passthrough as GROUP BY key | Tier 1 |
| 7 | AccountStatusName | DWH_dbo.Dim_AccountStatus | AccountStatusName | JOIN on AccountStatusID, resolved name | Tier 2 |
| 8 | AccountTypeID | DWH_dbo.Dim_Customer | AccountTypeID | Passthrough as GROUP BY key | Tier 1 |
| 9 | AccountType | DWH_dbo.Dim_AccountType | Name | JOIN on AccountTypeID, resolved name | Tier 2 |
| 10 | MifidCategorizationID | DWH_dbo.Dim_Customer | MifidCategorizationID | Passthrough as GROUP BY key | Tier 1 |
| 11 | MifidCategorizationName | DWH_dbo.Dim_MifidCategorization | Name | JOIN on MifidCategorizationID, resolved name | Tier 2 |
| 12 | PlayerStatusID | DWH_dbo.Dim_Customer | PlayerStatusID | Passthrough as GROUP BY key (filter: PlayerStatusID <> 1) | Tier 1 |
| 13 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN on PlayerStatusID, resolved name | Tier 2 |
| 14 | PlayerStatusReasonID | DWH_dbo.Dim_Customer | PlayerStatusReasonID | Passthrough as GROUP BY key | Tier 1 |
| 15 | PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | JOIN on PlayerStatusReasonID, resolved name | Tier 2 |
| 16 | PlayerStatusSubReasonID | DWH_dbo.Dim_Customer | PlayerStatusSubReasonID | ISNULL(..., 0) — 0 replaces NULL (no sub-reason) | Tier 1 |
| 17 | PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | LEFT JOIN, ISNULL(..., 'None') — 'None' if no sub-reason | Tier 2 |
| 18 | RiskGroupID | DWH_dbo.Dim_Country | RiskGroupID | JOIN on CountryID | Tier 2 |
| 19 | EU | DWH_dbo.Dim_Country | EU | JOIN on CountryID | Tier 2 |
| 20 | IsEuropeanCountry | DWH_dbo.Dim_Country | IsEuropeanCountry | JOIN on CountryID | Tier 2 |
| 21 | VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough as GROUP BY key | Tier 1 |
| 22 | IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer | Passthrough (DWH-computed in Dim_Customer — Tier 2 origin) | Tier 2 |
| 23 | IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | Passthrough (DWH-computed in Dim_Customer — Tier 2 origin) | Tier 2 |
| 24 | CurrAge | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(YEAR, BirthDate, GETDATE()-1) — age in years at run time | Tier 2 |
| 25 | LastLoggedIn_Group | BI_DB_dbo.BI_DB_CIDFirstDates | LastLoggedIn | CASE age bucket: 0-7/8-15/16-30/31-60/61+/N/A days since last login | Tier 2 |
| 26 | IsOpenPosition | DWH_dbo.V_Liabilities | TotalPositionsAmount | CASE WHEN TotalPositionsAmount <> 0 THEN 1 ELSE 0 END per segment | Tier 2 |
| 27 | UnRealizedEquity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | SUM(ISNULL(Liabilities,0) + ISNULL(ActualNWA,0)) per segment | Tier 2 |
| 28 | RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | SUM(ISNULL(RealizedEquity,0)) per segment | Tier 2 |
| 29 | Credit | DWH_dbo.V_Liabilities | Credit | SUM(ISNULL(Credit,0)) per segment | Tier 2 |
| 30 | TotalPositionsAmount | DWH_dbo.V_Liabilities | TotalPositionsAmount | SUM(ISNULL(TotalPositionsAmount,0)) per segment | Tier 2 |
| 31 | TotalPositionPnL | DWH_dbo.V_Liabilities | PositionPnL | SUM(ISNULL(PositionPnL,0)) per segment | Tier 2 |
| 32 | TotalCustomers | DWH_dbo.Dim_Customer | RealCID | COUNT(DISTINCT RealCID) per segment | Tier 2 |

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 9 | RegulationID, CountryID, AccountStatusID, AccountTypeID, MifidCategorizationID, PlayerStatusID, PlayerStatusReasonID, PlayerStatusSubReasonID, VerificationLevelID — from Dim_Customer wiki |
| Tier 2 | 23 | Resolved names, computed fields, financial aggregates, Dim_Country fields, DWH-computed columns |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

## Source Tables Referenced

| Source Object | Type | Role |
|---------------|------|------|
| DWH_dbo.Dim_Customer | Table | Primary — population filter + GROUP BY dimensions |
| DWH_dbo.V_Liabilities | View | Financial metrics per customer per date |
| BI_DB_dbo.BI_DB_CIDFirstDates | Table | LastLoggedIn date for aging bucket |
| DWH_dbo.Dim_Regulation | Table | Regulation name lookup |
| DWH_dbo.Dim_Country | Table | Country name, EU flag, RiskGroupID |
| DWH_dbo.Dim_AccountStatus | Table | Account status name |
| DWH_dbo.Dim_AccountType | Table | Account type name |
| DWH_dbo.Dim_MifidCategorization | Table | MiFID II category name |
| DWH_dbo.Dim_PlayerStatus | Table | Player status name |
| DWH_dbo.Dim_PlayerLevel | Table | Club tier name |
| DWH_dbo.Dim_PlayerStatusReasons | Table | Player status reason name |
| DWH_dbo.Dim_PlayerStatusSubReasons | Table | Player status sub-reason name (LEFT JOIN) |
