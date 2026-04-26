# Lineage: BI_DB_dbo.AML_German_Video_Ident

## Chain Summary

DWH_dbo.Dim_Customer (German, KYC3, depositor) + 13 source tables → SP_AML_German_Video_Ident → AML_German_Video_Ident

## ETL Hops

| Hop | Object | Type | Notes |
|-----|--------|------|-------|
| 1 | DWH_dbo.Dim_Customer | DWH dimension | Base population: CountryID=79 (Germany), VerificationLevelID=3, IsValidCustomer=1, IsDepositor=1, PlayerStatusID NOT IN (2,4) |
| 2 | DWH_dbo.Dim_Regulation | DWH dimension | JOIN ON RegulationID → Regulation text |
| 3 | DWH_dbo.Dim_PlayerStatus | DWH dimension | JOIN ON PlayerStatusID → PlayerStatus text |
| 4 | DWH_dbo.Dim_PlayerLevel | DWH dimension | JOIN ON PlayerLevelID → Club (level name) |
| 5 | DWH_dbo.Dim_Country (×3) | DWH dimension | LEFT JOIN ON CountryID/POBCountryID/CitizenshipCountryID → Country/POBCountry/CitizenshipCountry |
| 6 | DWH_dbo.Dim_EvMatchStatus | DWH dimension | LEFT JOIN ON EvMatchStatus → EvMatchStatusName |
| 7 | DWH_dbo.Dim_ScreeningStatus | DWH dimension | LEFT JOIN ON ScreeningStatusID → ScreeningStatus |
| 8 | BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | External table (BI_DB_dbo) | LEFT JOIN ON CID → RiskScoreName, RiskScore_Explanation |
| 9 | BI_DB_dbo.BI_DB_PositionPnL | BI_DB fact table | JOIN ON CID WHERE IsSettled=1; JOIN Dim_Instrument WHERE InstrumentTypeID=10 → Has_Open_RealCrypto flag |
| 10 | DWH_dbo.Fact_CustomerAction | DWH fact table | JOIN ON RealCID WHERE ActionTypeID=7 (Deposit) → TotalDeposit (SUM) |
| 11 | DWH_dbo.V_Liabilities | DWH view | JOIN ON CID WHERE DateID=@DateID → TotalEquity (Liabilities + ActualNWA) |
| 12 | general.SolarisBankIdentDb_SolarisBankIdent | External DB (general schema) | LEFT JOIN ON GCID, ranked by _ts DESC → Is_Pass_BankIdent (GlobalStatus='successful') |
| 13 | general.VideoIdentDb_VideoIdent | External DB (general schema) | LEFT JOIN ON GCID, ranked by UpdatedOn DESC → Is_Pass_VideoIdent (Status='Success') |
| 14 | SP_AML_German_Video_Ident | Stored Procedure (BI_DB_dbo) | TRUNCATE + INSERT. @Date parameter. Multi-step: #pop → #crypto → #finalpop → #deposit + #equity + #bankIdent2 + #videoident2 → #finaltable |
| 15 | BI_DB_dbo.AML_German_Video_Ident | Target (ROUND_ROBIN HEAP) | 198,613 rows (2026-04-23 sample). 23 columns (EquityRealCrypto always NULL). |

## Column Lineage

| Column | Source | Source Column | Transform |
|--------|--------|---------------|-----------|
| GCID | etoro.Customer.CustomerStatic | GCID | Via Dim_Customer |
| CID | etoro.Customer.CustomerStatic | RealCID | Renamed to CID |
| Regulation | Dictionary.Regulation | Name | Dim_Regulation JOIN |
| PlayerStatus | Dictionary.PlayerStatus | Name | Dim_PlayerStatus JOIN |
| Club | Dictionary.PlayerLevel | Name | Dim_PlayerLevel JOIN |
| Country | Dictionary.Country | Name | Dim_Country JOIN (CountryID=79) |
| POBCountry | Dictionary.Country | Name | Dim_Country LEFT JOIN (POBCountryID) |
| CitizenshipCountry | Dictionary.Country | Name | Dim_Country LEFT JOIN (CitizenshipCountryID) |
| EvMatchStatusName | Dictionary.EvMatchStatus | EvMatchStatusName | Dim_EvMatchStatus LEFT JOIN |
| RegisteredReal | Customer.CustomerStatic | Registered | Via Dim_Customer |
| FirstDepositDate | CustomerFinanceDB | — | Via Dim_Customer |
| FirstDepositAmount | CustomerFinanceDB | FTDAmountInUsd | Via Dim_Customer |
| HasWallet | BackOffice.Customer | HasWallet | Via Dim_Customer |
| ScreeningStatus | ScreeningService | — | Dim_ScreeningStatus LEFT JOIN |
| RiskScoreName | RiskClassification data lake | RiskScoreName | External_RiskClassification LEFT JOIN |
| RiskScore_Explanation | RiskClassification data lake | RiskScore_Explanation | External_RiskClassification LEFT JOIN |
| Has_Open_RealCrypto | BI_DB_dbo.BI_DB_PositionPnL | Amount, PositionPnL | CASE flag, InstrumentTypeID=10, IsSettled=1 |
| EquityRealCrypto | — | — | ALWAYS NULL — not inserted by SP |
| TotalDeposit | DWH_dbo.Fact_CustomerAction | Amount | SUM WHERE ActionTypeID=7 |
| TotalEquity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | ISNULL sum on DateID=@DateID |
| Is_Pass_BankIdent | general.SolarisBankIdentDb_SolarisBankIdent | GlobalStatus | MAX CASE WHERE RN=1 AND GlobalStatus='successful' |
| Is_Pass_VideoIdent | general.VideoIdentDb_VideoIdent | Status | MAX CASE WHERE RN=1 AND Status='Success' |
| UpdateDate | — | GETDATE() | ETL load timestamp |

## Downstream

| Consumer | Notes |
|----------|-------|
| AML team email/reporting processes | Primary consumer — German crypto customer monitoring |
| BI_DB_dbo.BI_DB_AMLPeriodicReview | Sibling AML table covering broader periodic review population |
