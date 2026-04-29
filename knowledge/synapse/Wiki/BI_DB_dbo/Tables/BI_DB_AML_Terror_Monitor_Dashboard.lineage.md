# BI_DB_dbo.BI_DB_AML_Terror_Monitor_Dashboard — Lineage

## Source Objects

| # | Object | Schema | Kind | Role in ETL |
|---|--------|--------|------|-------------|
| 1 | SP_AML_Terror_Monitor_Dashboard | BI_DB_dbo | Stored Procedure | Orchestrator — TRUNCATE + INSERT, 7-step pipeline |
| 2 | Dim_Customer | DWH_dbo | Table | Primary population source: CID, HasWallet, RegisteredReal, FirstDepositDate, FirstDepositAmount, country FKs, regulation FK, player status FK, player level FK, screening FK |
| 3 | Dim_Regulation | DWH_dbo | Table | Dimension lookup: resolves RegulationID → Regulation name |
| 4 | Dim_PlayerStatus | DWH_dbo | Table | Dimension lookup: resolves PlayerStatusID → PlayerStatus name; also serves as population filter (IN 1,5) |
| 5 | Dim_PlayerLevel | DWH_dbo | Table | Dimension lookup: resolves PlayerLevelID → Club name |
| 6 | Dim_Country | DWH_dbo | Table | Dimension lookup (×4): resolves CountryID→KYC_Country, CitizenshipCountryID→CitizenshipCountry, POBCountryID→POBCountry, CountryIDByIP→CountryByIP_Residency |
| 7 | Dim_ScreeningStatus | DWH_dbo | Table | Dimension lookup: resolves ScreeningStatusID → ScreeningStatus name |
| 8 | External_RiskClassification_dbo_V_RiskClassificationDataLake | BI_DB_dbo | External view | LEFT JOIN on CID → RiskScoreName; wiki unresolved |
| 9 | BI_DB_AML_SubEntity_Categorization | BI_DB_dbo | Table | LEFT JOIN on CID → AMLEntity, AMLSubEntity, AMLSubEntity_2 |
| 10 | V_Liabilities | DWH_dbo | View | Equity computation: ISNULL(Liabilities,0)+ISNULL(ActualNWA,0) at DateID=yesterday |
| 11 | Fact_CustomerAction | DWH_dbo | Table | Total_Deposits (ActionTypeID=7) and Total_CO (ActionTypeID=8) aggregations |
| 12 | eMoney_Dim_Account | eMoney_dbo | Table | Has_eMoney_Account flag: existence check (IsValidETM=1, IsTestAccount=0, CurrencyBalanceStatusID≠4) |

---

## Column Lineage

| # | Column | Type | Nullable | Source Object | Source Column | Transform | Tier | Wiki Path |
|---|--------|------|----------|---------------|---------------|-----------|------|-----------|
| 1 | CID | int | YES | DWH_dbo.Dim_Customer | RealCID | Rename passthrough | Tier 1 | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md |
| 2 | Regulation | varchar(250) | YES | DWH_dbo.Dim_Regulation | Name | Dim-lookup via Dim_Customer.RegulationID=DWHRegulationID | Tier 1 | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Regulation.md |
| 3 | KYC_Country | varchar(250) | YES | DWH_dbo.Dim_Country | Name | Dim-lookup via Dim_Customer.CountryID=DWHCountryID | Tier 1 | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md |
| 4 | CitizenshipCountry | varchar(250) | YES | DWH_dbo.Dim_Country | Name | LEFT JOIN dim-lookup via Dim_Customer.CitizenshipCountryID=DWHCountryID | Tier 1 | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md |
| 5 | POBCountry | varchar(250) | YES | DWH_dbo.Dim_Country | Name | LEFT JOIN dim-lookup via Dim_Customer.POBCountryID=DWHCountryID | Tier 1 | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md |
| 6 | CountryByIP_Residency | varchar(250) | YES | DWH_dbo.Dim_Country | Name | LEFT JOIN dim-lookup via Dim_Customer.CountryIDByIP=DWHCountryID | Tier 1 | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md |
| 7 | PlayerStatus | varchar(250) | YES | DWH_dbo.Dim_PlayerStatus | Name | Dim-lookup (INNER JOIN, filtered to PlayerStatusID IN (1,5)) | Tier 1 | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerStatus.md |
| 8 | Club | varchar(250) | YES | DWH_dbo.Dim_PlayerLevel | Name | Dim-lookup via Dim_Customer.PlayerLevelID | Tier 1 | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerLevel.md |
| 9 | HasWallet | int | YES | DWH_dbo.Dim_Customer | HasWallet | Passthrough | Tier 1 | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md |
| 10 | RegisteredReal | datetime | YES | DWH_dbo.Dim_Customer | RegisteredReal | Passthrough | Tier 1 | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md |
| 11 | FirstDepositDate | datetime | YES | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough | Tier 1 | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md |
| 12 | FirstDepositAmount | money | YES | DWH_dbo.Dim_Customer | FirstDepositAmount | Passthrough | Tier 1 | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md |
| 13 | ScreeningStatus | varchar(250) | YES | DWH_dbo.Dim_ScreeningStatus | Name | LEFT JOIN dim-lookup via Dim_Customer.ScreeningStatusID | Tier 1 | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_ScreeningStatus.md |
| 14 | RiskScoreName | varchar(250) | YES | BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | RiskScoreName | LEFT JOIN on CID | Tier 3 | — (unresolved) |
| 15 | Equity | money | YES | DWH_dbo.V_Liabilities | Liabilities, ActualNWA | `ISNULL(Liabilities,0) + ISNULL(ActualNWA,0)` at DateID=CAST(CONVERT(CHAR(8),GETDATE()-1,112) AS INT) | Tier 2 | knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md |
| 16 | Total_Deposits | money | YES | DWH_dbo.Fact_CustomerAction | Amount | `SUM(Amount) WHERE ActionTypeID=7 (Deposit)` | Tier 2 | knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md |
| 17 | Total_CO | money | YES | DWH_dbo.Fact_CustomerAction | Amount | `SUM(Amount) WHERE ActionTypeID=8 (Cashout)` | Tier 2 | knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md |
| 18 | Has_eMoney_Account | int | YES | eMoney_dbo.eMoney_Dim_Account | CID | `CASE WHEN CID present (IsValidETM=1, IsTestAccount=0, CurrencyBalanceStatusID≠4) THEN 1 ELSE 0` | Tier 2 | knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Dim_Account.md |
| 19 | UpdateDate | datetime | YES | ETL system | — | `GETDATE()` at TRUNCATE+INSERT time | Tier 2 | — |
| 20 | AMLEntity | varchar(250) | YES | BI_DB_dbo.BI_DB_AML_SubEntity_Categorization | AMLEntity | Passthrough | Tier 1 | knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AML_SubEntity_Categorization.md |
| 21 | AMLSubEntity | varchar(250) | YES | BI_DB_dbo.BI_DB_AML_SubEntity_Categorization | AMLSubEntity | Passthrough | Tier 1 | knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AML_SubEntity_Categorization.md |
| 22 | AMLSubEntity_2 | varchar(250) | YES | BI_DB_dbo.BI_DB_AML_SubEntity_Categorization | AMLSubEntity_2 | Passthrough | Tier 1 | knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AML_SubEntity_Categorization.md |

---

*Lineage generated: 2026-04-28 | SP source: BI_DB_dbo.SP_AML_Terror_Monitor_Dashboard*
