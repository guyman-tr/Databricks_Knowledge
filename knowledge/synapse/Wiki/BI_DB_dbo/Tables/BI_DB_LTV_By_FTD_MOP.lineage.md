# BI_DB_dbo.BI_DB_LTV_By_FTD_MOP — Column Lineage

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|----------------|-------------|---------------|-----------|------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough | Tier 2 |
| FTDDate | DWH_dbo.Dim_Customer | FirstDepositDate | CAST to DATE | Tier 2 |
| FTDDateTime | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough datetime | Tier 2 |
| FTDDateID | DWH_dbo.Dim_Customer | FirstDepositDate | CAST to YYYYMMDD int | Tier 2 |
| Current_Country | DWH_dbo.Dim_Country | Name | JOIN on Dim_Customer.CountryID (current) | Tier 2 |
| Current_Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on Dim_Customer.PlayerLevelID (current) | Tier 2 |
| Current_Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on Dim_Customer.RegulationID (current) | Tier 2 |
| Current_Region | DWH_dbo.Dim_Country | MarketingRegionManualName | JOIN on Dim_Customer.CountryID (current) | Tier 2 |
| Is_Currently_BlockedInd | SP computed | Dim_Customer.PlayerStatusID | CASE WHEN IN (2,4,14,15) THEN 1 ELSE 0 | Tier 2 |
| Currently_HighRiskInd | BI_DB_RiskClassification | RiskScoreName | CASE WHEN 'High' THEN 1 ELSE 0 | Tier 2 |
| FTD_Country | DWH_dbo.Dim_Country | Name | JOIN on Fact_SnapshotCustomer.CountryID at FTD date | Tier 2 |
| FTD_Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on Fact_SnapshotCustomer.PlayerLevelID at FTD date | Tier 2 |
| FTD_Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on Fact_SnapshotCustomer.RegulationID at FTD date | Tier 2 |
| FTD_Region | DWH_dbo.Dim_Country | MarketingRegionManualName | JOIN on Fact_SnapshotCustomer.CountryID at FTD date | Tier 2 |
| FTD Method | DWH_dbo.Dim_FundingType | Name | JOIN on Fact_BillingDeposit.FundingTypeID WHERE IsFTD=1 | Tier 2 |
| FTD Provider | DWH_dbo.Dim_BillingDepot | Name | JOIN on Fact_BillingDeposit.DepotID WHERE IsFTD=1 | Tier 2 |
| Revenue30days | BI_DB_dbo.BI_DB_First5Actions | Revenue30days | LEFT JOIN on CID | Tier 2 |
| Revenue60days | BI_DB_dbo.BI_DB_First5Actions | Revenue60days | LEFT JOIN on CID | Tier 2 |
| Revenue90days | BI_DB_dbo.BI_DB_First5Actions | Revenue90days | LEFT JOIN on CID | Tier 2 |
| Revenue180days | BI_DB_dbo.BI_DB_First5Actions | Revenue180days | LEFT JOIN on CID | Tier 2 |
| Revenue360days | BI_DB_dbo.BI_DB_First5Actions | Revenue360days | LEFT JOIN on CID | Tier 2 |
| Current_LTV | BI_DB_dbo.BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New | LEFT JOIN on CID | Tier 2 |
| Current_LTV_NoExtreme | BI_DB_dbo.BI_DB_LTV_BI_Actual | Revenue8Y_LTV_NoExtreme_New | LEFT JOIN on CID | Tier 2 |
| UpdateDate | SP | GETDATE() | ETL timestamp | Tier 5 |

## Source Objects

| Source Object | Role | Schema |
|---------------|------|--------|
| DWH_dbo.Dim_Customer | Customer demographics, FTD date, validity | DWH_dbo |
| DWH_dbo.Fact_SnapshotCustomer | Historical snapshot at FTD date | DWH_dbo |
| DWH_dbo.Fact_BillingDeposit | FTD payment method and provider (IsFTD=1) | DWH_dbo |
| BI_DB_dbo.BI_DB_RiskClassification | Risk score classification | BI_DB_dbo |
| BI_DB_dbo.BI_DB_First5Actions | Revenue windows (30/60/90/180/360 days) | BI_DB_dbo |
| BI_DB_dbo.BI_DB_LTV_BI_Actual | 8-year LTV calculations | BI_DB_dbo |
| DWH_dbo.Dim_Country, Dim_PlayerLevel, Dim_Regulation, Dim_FundingType, Dim_BillingDepot | Dimension lookups | DWH_dbo |
