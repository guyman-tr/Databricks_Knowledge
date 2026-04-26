# BI_DB_dbo.BI_DB_Affiliates_VerificationSLA — Column Lineage

*Generated: 2026-04-21 | Phase 10B output — written BEFORE wiki*

## Source Objects

| Source | Type | Description |
|--------|------|-------------|
| DWH_dbo.Dim_Customer | DWH Dimension | Customer master — provides RealCID, RegisteredReal, VerificationLevelID, CountryID, DesignatedRegulationID, AccountTypeID, PlayerStatusID, IsValidCustomer |
| BI_DB_dbo.External_etoro_BackOffice_Customer | External Table | BackOffice customer gateway — used to filter affiliate accounts by AccountTypeID (6=Affiliate Private, 15=Affiliate Corporate) |
| [general].[etoro_History_BackOfficeCustomer] | Shared History | BackOffice customer history — provides VerificationLevel history (ValidFrom per VerificationLevelID) |
| DWH_dbo.Dim_Country | DWH Dimension | Country master — provides Region (marketing region) and Name (country name) via JOIN on CountryID |
| DWH_dbo.Dim_Regulation | DWH Dimension | Regulation master — provides regulation name via JOIN on DesignatedRegulationID |
| DWH_dbo.Dim_AccountType | DWH Dimension | Account type master — provides account type name via JOIN on AccountTypeID |
| DWH_dbo.Dim_PlayerStatus | DWH Dimension | Player status master — provides status name via JOIN on PlayerStatusID |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|------------|---------------|---------------|-----------|------|
| 1 | RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough — JOIN on RealCID | Tier 1 — Customer.CustomerStatic |
| 2 | RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Passthrough | Tier 1 — Customer.CustomerStatic |
| 3 | VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough — current level (only levels 2 and 3 present in this table due to filter on VerificationLevel2Date) | Tier 1 — BackOffice.Customer |
| 4 | VerificationLevel2Date | [general].[etoro_History_BackOfficeCustomer] | ValidFrom | COMPUTED: MIN(ValidFrom) WHERE VerificationLevelID=2 GROUP BY CID | Tier 2 — SP_Affiliates_VerificationSLA |
| 5 | VerificationLevel3Date | [general].[etoro_History_BackOfficeCustomer] | ValidFrom | COMPUTED: MIN(ValidFrom) WHERE VerificationLevelID=3 GROUP BY CID. NULL if customer has not yet reached Level 3 | Tier 2 — SP_Affiliates_VerificationSLA |
| 6 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN resolution: Dim_Customer.PlayerStatusID → Dim_PlayerStatus.Name | Tier 1 — Dictionary.PlayerStatus |
| 7 | Region | DWH_dbo.Dim_Country | Region | JOIN resolution: Dim_Customer.CountryID → Dim_Country.Region (marketing region label from etoro.Dictionary.MarketingRegion) | Tier 2 — SP_Dictionaries_Country_DL_To_Synapse |
| 8 | Country | DWH_dbo.Dim_Country | Name | JOIN resolution: Dim_Customer.CountryID → Dim_Country.Name | Tier 1 — Dictionary.Country |
| 9 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN resolution: Dim_Customer.DesignatedRegulationID → Dim_Regulation.Name | Tier 2 — SP_Affiliates_VerificationSLA (via Dim_Regulation JOIN) |
| 10 | AccountType | DWH_dbo.Dim_AccountType | Name | JOIN resolution: Dim_Customer.AccountTypeID → Dim_AccountType.Name | Tier 2 — SP_Affiliates_VerificationSLA (via Dim_AccountType JOIN) |
| 11 | SLA | Computed | N/A | CASE logic: Private ≤48h (business-hour-aware, weekday offset for Fri/Sat/Sun); Corporate ≤5 business days. 1=met SLA, 0=missed or Level 3 not yet reached | Tier 2 — SP_Affiliates_VerificationSLA |
| 12 | HourDifference | Computed | N/A | DATEDIFF(HOUR, VerificationLevel2Date, VerificationLevel3Date). NULL when VerificationLevel3Date IS NULL | Tier 2 — SP_Affiliates_VerificationSLA |
| 13 | DayDifference | Computed | N/A | DATEDIFF(day, VerificationLevel2Date, VerificationLevel3Date). NULL when VerificationLevel3Date IS NULL | Tier 2 — SP_Affiliates_VerificationSLA |
| 14 | UpdateDate | ETL | N/A | GETDATE() at SP execution time | Tier 2 — SP_Affiliates_VerificationSLA |

## ETL Pipeline Summary

```
eToro BackOffice (etoroDB-REAL)
  BI_DB_dbo.External_etoro_BackOffice_Customer  [AccountTypeID IN (6,15)]
  [general].[etoro_History_BackOfficeCustomer]  [ValidFrom per VerificationLevelID]
  DWH_dbo.Dim_Customer                          [customer attributes]
  DWH_dbo.Dim_Country                           [Region, Country name]
  DWH_dbo.Dim_Regulation                        [Regulation name]
  DWH_dbo.Dim_AccountType                       [AccountType name]
  DWH_dbo.Dim_PlayerStatus                      [PlayerStatus name]
    |-- SP_Affiliates_VerificationSLA (TRUNCATE+INSERT, daily, 4-month window) ---|
    v
BI_DB_dbo.BI_DB_Affiliates_VerificationSLA  [571 rows — affiliate KYC SLA tracking]
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 4 | RealCID, RegisteredReal, VerificationLevelID, PlayerStatus, Country |
| Tier 2 | 10 | VerificationLevel2Date, VerificationLevel3Date, Region, Regulation, AccountType, SLA, HourDifference, DayDifference, UpdateDate |

> Note: PlayerStatus and Country bring Tier 1 descriptions from their respective dimension table wikis (Dim_PlayerStatus, Dim_Country). Tier count above reflects 5 Tier 1 columns total (RealCID, RegisteredReal, VerificationLevelID, PlayerStatus, Country).
