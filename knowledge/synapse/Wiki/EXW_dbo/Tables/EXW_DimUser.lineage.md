# EXW_dbo.EXW_DimUser — Column Lineage

Generated: 2026-04-20 | Pipeline: DWH Semantic Doc Phase 10B

## ETL Summary

| Property | Value |
|----------|-------|
| **Synapse Target** | EXW_dbo.EXW_DimUser |
| **Writer SP** | EXW_dbo.SP_DimUser |
| **ETL Type** | Incremental merge SCD Type 1 (overwrite) — INSERT new Wallet users + UPDATE changed attributes |
| **Primary Source** | EXW_Wallet.CustomerWalletsView (Wallet user list) → DWH_dbo.Dim_Customer (attributes) |
| **Origin** | etoro.Customer.CustomerStatic (via Dim_Customer) |
| **Refresh Pattern** | Daily; UpdateDate: 2021-05-24 to 2026-04-12 |
| **Row Count** | 699,692 |
| **UC Target** | _Not_Migrated (to be verified) |

## Column Lineage

| # | Synapse Column | Source Type | Source Table | Source Column | Transform | Confidence Tier |
|---|---------------|-------------|--------------|---------------|-----------|-----------------|
| 1 | GCID | Passthrough | DWH_dbo.Dim_Customer | GCID | Direct passthrough; HASH distribution key and CLUSTERED INDEX | Tier 1 — Customer.CustomerStatic |
| 2 | RealCID | Passthrough | DWH_dbo.Dim_Customer | RealCID | Direct passthrough | Tier 1 — Customer.CustomerStatic |
| 3 | Username | Passthrough | DWH_dbo.Dim_Customer | UserName | Renamed (capitalization only); COLLATE Latin1_General_100_BIN applied on UPDATE | Tier 1 — Customer.CustomerStatic |
| 4 | FirstName | Passthrough | DWH_dbo.Dim_Customer | FirstName | Direct passthrough; COLLATE Latin1_General_100_BIN applied on UPDATE | Tier 1 — Customer.CustomerStatic |
| 5 | LastName | Passthrough | DWH_dbo.Dim_Customer | LastName | Direct passthrough; COLLATE Latin1_General_100_BIN applied on UPDATE | Tier 1 — Customer.CustomerStatic |
| 6 | PlayerLevelID | Passthrough | DWH_dbo.Dim_Customer | PlayerLevelID | Direct passthrough | Tier 1 — Customer.CustomerStatic |
| 7 | VerificationLevelID | Passthrough | DWH_dbo.Dim_Customer | VerificationLevelID | Direct passthrough | Tier 1 — BackOffice.Customer |
| 8 | CountryID | Passthrough | DWH_dbo.Dim_Customer | CountryID | Direct passthrough | Tier 1 — Customer.CustomerStatic |
| 9 | Country | Join-derived | DWH_dbo.Dim_Country | Name | JOIN on CC.CountryID = Dim_Country.CountryID; denormalized name | Tier 2 — SP_DimUser |
| 10 | RegionID | Join-derived | DWH_dbo.Dim_Country | MarketingRegionID | JOIN on CountryID; marketing region id derived from country | Tier 2 — SP_DimUser |
| 11 | Region | Join-derived | DWH_dbo.Dim_Country | Region | JOIN on CountryID; marketing region name from Dim_Country | Tier 2 — SP_DimUser |
| 12 | IsTestAccount | Computed | EXW_dbo.EXW_TestUsers | GCID | CASE WHEN etu.GCID IS NOT NULL THEN 1 ELSE 0 END; LEFT JOIN on CC.GCID = EXW_TestUsers.GCID | Tier 2 — SP_DimUser |
| 13 | CreditReportValid | Passthrough | DWH_dbo.Dim_Customer | IsCreditReportValidCB | Renamed; DWH-computed in Dim_Customer (AccountTypeID≠2 + CID exceptions) | Tier 2 — SP_Dim_Customer |
| 14 | UpdateDate | Computed | — | — | GETDATE() on INSERT and on UPDATE when any attribute changes | Tier 2 — SP_DimUser |
| 15 | IsValidCustomer | Passthrough | DWH_dbo.Dim_Customer | IsValidCustomer | Passthrough of DWH-computed column; 1 when PlayerLevelID≠4, LabelID NOT IN (26,30), CountryID≠250 | Tier 2 — SP_Dim_Customer |
| 16 | RegulationID | Passthrough | DWH_dbo.Dim_Customer | RegulationID | Direct passthrough | Tier 1 — BackOffice.Customer |
| 17 | Regulation | Join-derived | DWH_dbo.Dim_Regulation | Name | JOIN on r.DWHRegulationID = CC.RegulationID; denormalized regulation name | Tier 2 — SP_DimUser |
| 18 | UserRegionID | Passthrough | DWH_dbo.Dim_Customer | RegionID | Renamed (RegionID → UserRegionID); state/province region by IP | Tier 1 — Customer.CustomerStatic |
| 19 | UserRegion_State | Join-derived | DWH_dbo.Dim_State_and_Province | Name | JOIN on CC.RegionID = p.RegionByIP_ID; state/province name | Tier 2 — SP_DimUser |
| 20 | Club | Join-derived | DWH_dbo.Dim_PlayerLevel | Name | JOIN on CC.PlayerLevelID = dpl.PlayerLevelID; COLLATE Latin1_General_100_BIN on UPDATE | Tier 2 — SP_DimUser |
| 21 | ComplianceClosureEvent | Computed | EXW_dbo.EXW_WalletClosedCountryProjects | CountryID | CASE WHEN cp.CountryID IS NOT NULL THEN 1 ELSE 0 END; LEFT JOIN on CC.CountryID + RegulationID with NULL-coalesce | Tier 2 — SP_DimUser |

## Source Objects

| Source | Object | Role |
|--------|--------|------|
| EXW_Wallet.CustomerWalletsView | Wallet user GCID source — defines which GCIDs are Wallet users | Filter/driver |
| DWH_dbo.Dim_Customer | Primary attribute source (customer identifiers, profile, compliance, level) | Main JOIN |
| DWH_dbo.Dim_Country | Denormalized country name, marketing region | JOIN (CountryID) |
| DWH_dbo.Dim_Regulation | Denormalized regulation name | JOIN (RegulationID) |
| DWH_dbo.Dim_State_and_Province | State/province name for US and provincial users | JOIN (RegionByIP_ID) |
| DWH_dbo.Dim_PlayerLevel | Club label (Bronze/Silver/Gold/Platinum/Diamond etc.) | JOIN (PlayerLevelID) |
| EXW_dbo.EXW_TestUsers | Test user flag source | LEFT JOIN (GCID) |
| EXW_dbo.EXW_WalletClosedCountryProjects | Compliance closure flag source | LEFT JOIN (CountryID + RegulationID) |

## Consumers (Downstream)

| Object | Usage |
|--------|-------|
| EXW_dbo.SP_EXW_AMLProviderID | Source of user identifiers (GCID, RealCID) for AML mapping |
| EXW_dbo.SP_EXW_FactBalance | Joins on GCID for user-level balance reporting |
| EXW_dbo.SP_EXW_WalletRegulation | Source of GCID and RealCID for wallet regulation tracking |
| Multiple EXW_dbo SPs (depth 4-5) | Common dimension JOIN source across the EXW analytics layer |
