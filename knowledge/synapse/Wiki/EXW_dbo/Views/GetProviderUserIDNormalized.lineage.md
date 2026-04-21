# EXW_dbo.GetProviderUserIDNormalized — Column Lineage

**Object Type**: View
**Schema**: EXW_dbo
**Generated**: 2026-04-20
**Pipeline Phase**: 10B

## View Definition Summary

Query-time join view over `EXW_dbo.EXW_AMLProviderID` (base table, 206,407 rows) enriched with:
- `DWH_dbo.Dim_Customer` → `Dim_Country` → country name
- `DWH_dbo.Dim_Customer` → `Dim_Regulation` → regulation name
- `DWH_dbo.Dim_Customer` → `Dim_PlayerStatus` → player status name
- `EXW_dbo.EXW_UserSettingsWalletAllowance` → wallet allowance decision

No ETL SP writer. No physical storage — results are computed at query time.
INNER JOIN on Dim_Country and Dim_Regulation (excludes AML users without DWH customer coverage).
Row count = 206,407 (100% match with EXW_AMLProviderID — no orphan exclusions observed).

## Column Lineage

| # | View Column | Source Object | Source Column | Transform | Confidence |
|---|-------------|---------------|---------------|-----------|------------|
| 1 | CID | EXW_dbo.EXW_AMLProviderID | RealCID | Alias rename only | Tier 1 — Customer.CustomerStatic |
| 2 | GCID | EXW_dbo.EXW_AMLProviderID | GCID | Direct passthrough | Tier 2 — SP_EXW_AMLProviderID |
| 3 | Country | DWH_dbo.Dim_Country | Name | JOIN via Dim_Customer.CountryID = Dim_Country.CountryID | Tier 3 — Dim_Country |
| 4 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN via Dim_Customer.RegulationID = Dim_Regulation.DWHRegulationID | Tier 3 — Dim_Regulation |
| 5 | ProviderUserIDNormalized | EXW_dbo.EXW_AMLProviderID | ProviderUserIDNormalized | Direct passthrough | Tier 2 — SP_EXW_AMLProviderID |
| 6 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN via Dim_Customer.PlayerStatusID = Dim_PlayerStatus.PlayerStatusID | Tier 3 — Dim_PlayerStatus |
| 7 | UserWalletAllowance | EXW_dbo.EXW_UserSettingsWalletAllowance | UserWalletAllowance | Direct passthrough (LEFT JOIN) | Tier 2 — SP_EXW_UserSettingsWalletAllowance |

## Source Objects

| Source Object | Relationship | Notes |
|---------------|-------------|-------|
| EXW_dbo.EXW_AMLProviderID | Primary base table (driving FROM clause) | 206,407 rows; provides CID, GCID, ProviderUserIDNormalized |
| DWH_dbo.Dim_Customer | LEFT JOIN on RealCID | Bridge to DWH dimension context |
| DWH_dbo.Dim_Country | INNER JOIN via Dim_Customer.CountryID | Resolves CountryID → Country name; excludes users with no Dim_Customer match |
| DWH_dbo.Dim_Regulation | INNER JOIN via Dim_Customer.RegulationID | Resolves RegulationID → Regulation name |
| DWH_dbo.Dim_PlayerStatus | LEFT JOIN via Dim_Customer.PlayerStatusID | Resolves PlayerStatusID → PlayerStatus name |
| EXW_dbo.EXW_UserSettingsWalletAllowance | LEFT JOIN on GCID | Provides UserWalletAllowance; NULL if user not in allowance table |

## UC Lineage

UC Target: `_Not_Migrated`
No UC entity exists for this view. Documentation is for knowledge purposes only.
