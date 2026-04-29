# BI_DB_dbo.BI_DB_W_AML_PEP_Customers_Trun — Column Lineage

## Source Objects

| Source Object | Schema | Role | Join Condition |
|--------------|--------|------|----------------|
| DWH_dbo.Dim_Customer | DWH_dbo | Primary — PEP depositor population | IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3 |
| DWH_dbo.Dim_ScreeningStatus | DWH_dbo | Dim lookup — screening name | ScreeningStatusID = dc.ScreeningStatusID AND ScreeningStatusID=3 (PEP) |
| DWH_dbo.Dim_Regulation | DWH_dbo | Dim lookup — regulation name | DWHRegulationID = dc.RegulationID |
| DWH_dbo.Dim_PlayerStatus | DWH_dbo | Dim lookup — player status name | PlayerStatusID = dc.PlayerStatusID |
| DWH_dbo.Dim_Country | DWH_dbo | Dim lookup — country name + risk | DWHCountryID = dc.CountryID |
| BI_DB_dbo.BI_DB_AML_Documents_Request | BI_DB_dbo | LEFT JOIN — selfie/SOF docs | CID = dc.RealCID |
| External_RiskClassification_dbo_V_RiskClassificationDataLake | BI_DB_dbo | LEFT JOIN — risk score | CID = dc.RealCID |
| eMoney_dbo.eMoney_Dim_Account | eMoney_dbo | LEFT JOIN — eMoney account check | CID match, IsValidETM=1, IsTestAccount=0, CurrencyBalanceStatusID<>4 |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Rename: RealCID → CID |
| ScreeningStatus | DWH_dbo.Dim_ScreeningStatus | Name | Passthrough (always 'PEP' due to filter) |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Passthrough via dim lookup |
| Regualtion | DWH_dbo.Dim_Regulation | Name | Passthrough via dim lookup (column name typo preserved) |
| RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Passthrough |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough |
| FirstDepositAmount | DWH_dbo.Dim_Customer | FirstDepositAmount | Passthrough |
| Country | DWH_dbo.Dim_Country | Name | Passthrough via dim lookup |
| AML_Rank | DWH_dbo.Dim_Country | RiskGroupID | Rename: RiskGroupID → AML_Rank |
| Has_Selfie | BI_DB_dbo.BI_DB_AML_Documents_Request | DocumentDateAdded_Selfie | CASE WHEN IS NOT NULL THEN 1 ELSE 0 |
| Selfie_Date | BI_DB_dbo.BI_DB_AML_Documents_Request | DocumentDateAdded_Selfie | CAST AS DATE |
| Has_SOF | BI_DB_dbo.BI_DB_AML_Documents_Request | DocumentDateAdded_POIncome | CASE WHEN IS NOT NULL THEN 1 ELSE 0 |
| SOF_Date | BI_DB_dbo.BI_DB_AML_Documents_Request | DocumentDateAdded_POIncome | CAST AS DATE |
| Selfie_and_SOF_Valid | BI_DB_dbo.BI_DB_AML_Documents_Request | DocumentDateAdded_Selfie, DocumentDateAdded_POIncome | CASE: 'Yes' if both dates >= 12 months ago, else 'No' |
| HasWallet | DWH_dbo.Dim_Customer | HasWallet | Passthrough |
| ReportDate | SP parameter | @WeekEndDate | Computed: Monday-Sunday week end date |
| Has_eMoney_Account | eMoney_dbo.eMoney_Dim_Account | CID | CASE WHEN CID IS NOT NULL THEN 1 ELSE 0 |
| eMoney_BalanceStatus | eMoney_dbo.eMoney_Dim_Account | CurrencyBalanceStatus | Passthrough |
| UpdateDate | ETL | GETDATE() | ETL metadata timestamp |
| RiskScoreName | External_RiskClassification_dbo_V_RiskClassificationDataLake | RiskScoreName | Passthrough |

*Generated: 2026-04-27*
