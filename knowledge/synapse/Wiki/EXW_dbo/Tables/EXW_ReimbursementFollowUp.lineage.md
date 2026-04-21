# EXW_dbo.EXW_ReimbursementFollowUp — Column Lineage

**Generated**: 2026-04-20 | **ETL SP**: SP_EXW_CompensationClosingCountries | **Load Pattern**: TRUNCATE + INSERT (no date param — @d = MAX(BalanceDate) from EXW_FinanceReportsBalancesNew)

## ETL Pipeline

```
Google Sheets (Fivetran) → BI_DB_dbo External Tables
  aml_reasons_compensated_users / wallet_aml_us_compensations / wallet_closureandreimbursementseea_cysec_2025
    |
    | SP_EXW_CompensationClosingCountries (UPSERT + dedup)
    v
EXW_dbo.EXW_CompensationClosingCountries (compensation registry — documented, Batch 5)
  |
  + DWH_dbo.Dim_Customer (AccountStatusID, PlayerStatusID, VerificationLevelID)
  + DWH_dbo.Fact_CustomerAction (ActionTypeID=36, CompensationReasonID IN (101,102))
  + DWH_dbo.Dim_AccountStatus, Dim_PlayerStatus, Dim_PlayerStatusReasons, Dim_PlayerStatusSubReasons
  + EXW_dbo.EXW_DimUser (Current Country, Regulation, Club, UserRegion_State, IsTestAccount)
  + EXW_dbo.EXW_UserSettingsWalletAllowance (UserWalletAllowance, AllowanceBeginDate)
  + EXW_dbo.EXW_FinanceReportsBalancesNew (current balance snapshot at @d)
  + EXW_dbo.EXW_FactTransactions (TransactionTypeID=13, TranStatusID=2 — extractions since 2024-01-18)
  + EXW_Wallet.EXW_PriceDaily (AvgPrice at @d_i — current rate)
  + EXW_dbo.EXW_WalletEntity (WalletEntity at CompensationDate + most recent Date)
    |-- SP_EXW_CompensationClosingCountries
    |   TRUNCATE EXW_ReimbursementFollowUp
    |   INSERT WHERE [Reimbursement Coin Balance] <> 0 ---|
    v
EXW_dbo.EXW_ReimbursementFollowUp
  |-- (no UC migration) ---|
  v
_Not_Migrated

Note: Same SP also writes EXW_dbo.EXW_ReimbursementSumTable (7-population summary) after inserting to EXW_ReimbursementFollowUp.
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Tier |
|---|---|---|---|---|
| CID | DWH_dbo.Dim_Customer (via EXW_DimUser) | RealCID | Passthrough as CID | Tier 2 — SP_EXW_CompensationClosingCountries |
| GCID | EXW_dbo.EXW_CompensationClosingCountries | GCID | Passthrough — distribution key | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Reimbursement Rate] | EXW_dbo.EXW_CompensationClosingCountries | Rate | Passthrough (exchange_rate from Google Sheets) | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Date Rate For  Reimbursement] | EXW_dbo.EXW_CompensationClosingCountries | RateDate | Passthrough (exchange_date from Google Sheets); NOTE: double space in name | Tier 2 — SP_EXW_CompensationClosingCountries |
| CryptoName | EXW_dbo.EXW_CompensationClosingCountries | CryptoName | Passthrough | Tier 2 — SP_EXW_CompensationClosingCountries |
| CryptoId | EXW_dbo.EXW_CompensationClosingCountries | CryptoId | Passthrough | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Reimbursement Coin Balance] | EXW_dbo.EXW_CompensationClosingCountries | FinalBalance | Passthrough (crypto units at compensation) | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Reimbursement USD Balance] | EXW_dbo.EXW_CompensationClosingCountries | USD_FinalBalance | Passthrough (FinalBalance × Rate from Google Sheets) | Tier 2 — SP_EXW_CompensationClosingCountries |
| WalletId | EXW_dbo.EXW_CompensationClosingCountries | WalletId | Passthrough (from EXW_Wallet.EXW_CustomerWalletsView.Id) | Tier 2 — SP_EXW_CompensationClosingCountries |
| Address | EXW_dbo.EXW_CompensationClosingCountries | Address | Passthrough (from EXW_Wallet.EXW_CustomerWalletsView.Address) | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Reimbursement Country] | EXW_dbo.EXW_CompensationClosingCountries | Country | Passthrough (country name at time of compensation) | Tier 2 — SP_EXW_CompensationClosingCountries |
| ReimbursementCountryID | EXW_dbo.EXW_CompensationClosingCountries | CountryID | Passthrough | Tier 2 — SP_EXW_CompensationClosingCountries |
| ReportFromDate | EXW_dbo.EXW_CompensationClosingCountries | ReportFromDate | Passthrough — NULL for AML* projects | Tier 2 — SP_EXW_CompensationClosingCountries |
| ReportId | EXW_dbo.EXW_CompensationClosingCountries | ReportId | Passthrough — NULL for AML* projects | Tier 2 — SP_EXW_CompensationClosingCountries |
| Project | EXW_dbo.EXW_CompensationClosingCountries | Project | Passthrough (AML, AML_US, AML_EEA, legacy closure projects) | Tier 2 — SP_EXW_CompensationClosingCountries |
| CompensationDate | EXW_dbo.EXW_CompensationClosingCountries | CompensationDate | Passthrough | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Reimbursement Regulation] | EXW_dbo.EXW_CompensationClosingCountries | Regulation | Passthrough (regulation name at time of compensation) | Tier 2 — SP_EXW_CompensationClosingCountries |
| ReimbursementRegulationID | EXW_dbo.EXW_CompensationClosingCountries | RegulationID | Passthrough | Tier 2 — SP_EXW_CompensationClosingCountries |
| AMLStatus | EXW_dbo.EXW_CompensationClosingCountries | AMLStatus | Passthrough (compensated/reimbursed/completed filter applied upstream) | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Current Country] | EXW_dbo.EXW_DimUser | Country | Passthrough (denormalized Dim_Country.Name) | Tier 2 — SP_DimUser via EXW_DimUser |
| CurrentCountryID | EXW_dbo.EXW_DimUser | CountryID | Passthrough | Tier 1 — Customer.CustomerStatic upstream wiki |
| CurrentRegulation | EXW_dbo.EXW_DimUser | Regulation | Passthrough (denormalized Dim_Regulation.Name) | Tier 2 — SP_DimUser via EXW_DimUser |
| CurrentRegulationID | EXW_dbo.EXW_DimUser | RegulationID | Passthrough | Tier 1 — BackOffice.Customer upstream wiki |
| CurrentClub | EXW_dbo.EXW_DimUser | Club | Passthrough (Dim_PlayerLevel.Name — Bronze/Silver/Gold/Platinum/Diamond) | Tier 2 — SP_DimUser via EXW_DimUser |
| UserRegion_State | EXW_dbo.EXW_DimUser | UserRegion_State | Passthrough (Dim_State_and_Province.Name — US/Canada/Australia mainly) | Tier 2 — SP_DimUser via EXW_DimUser |
| IsTestAccount | EXW_dbo.EXW_DimUser | IsTestAccount | Passthrough (1 if in EXW_TestUsers, else 0) | Tier 2 — SP_DimUser via EXW_DimUser |
| AccountStatusName | DWH_dbo.Dim_AccountStatus | AccountStatusName | Passthrough — joined on AccountStatusID | Tier 2 — SP_EXW_CompensationClosingCountries |
| AccountStatusID | DWH_dbo.Dim_Customer | AccountStatusID | Passthrough | Tier 2 — SP_EXW_CompensationClosingCountries via Dim_Customer |
| PlayerStatusID | DWH_dbo.Dim_Customer | PlayerStatusID | Passthrough | Tier 2 — SP_EXW_CompensationClosingCountries via Dim_Customer |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Passthrough — joined on PlayerStatusID | Tier 2 — SP_EXW_CompensationClosingCountries |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | Passthrough — joined on PlayerStatusReasonID | Tier 2 — SP_EXW_CompensationClosingCountries |
| PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Passthrough — joined on PlayerStatusSubReasonID | Tier 2 — SP_EXW_CompensationClosingCountries |
| CurrentUSDRate | EXW_Wallet.EXW_PriceDaily | AvgPrice | Passthrough (rate for CryptoID at @d = MAX(BalanceDate)) | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Date of Current User Balance] | EXW_dbo.EXW_FinanceReportsBalancesNew | BalanceDate | Passthrough (date of the current balance snapshot used) | Tier 2 — SP_EXW_CompensationClosingCountries |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough | Tier 1 — BackOffice.Customer upstream wiki |
| UserWalletAllowance | EXW_dbo.EXW_UserSettingsWalletAllowance | UserWalletAllowance | Passthrough | Tier 2 — SP_EXW_CompensationClosingCountries |
| UserWalletAllowanceBeginDate | EXW_dbo.EXW_UserSettingsWalletAllowance | AllowanceBeginDate | Passthrough | Tier 2 — SP_EXW_CompensationClosingCountries |
| DateForCurrentBalanceRate | EXW_dbo.EXW_FinanceReportsBalancesNew | BalanceDate | MAX(BalanceDate) — scalar ETL variable @d applied uniformly | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Current Coin Balance] | EXW_dbo.EXW_FinanceReportsBalancesNew | Balance | ISNULL(Balance, 0) — 0 if no balance record at @d | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Current USD Balance by Reimbursement Rate] | computed | [Current Coin Balance] × [Reimbursement Rate] | [Current Coin Balance] × [Reimbursement Rate] | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Current USD Balance by Current Rate] | computed | [Current Coin Balance] × CurrentUSDRate | [Current Coin Balance] × CurrentUSDRate | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Regulation Changed] | computed | CurrentRegulationID vs ReimbursementRegulationID | CASE: 'True' if IDs differ, 'False' otherwise | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Country Changed] | computed | CurrentCountryID vs ReimbursementCountryID | CASE: 'True' if IDs differ, 'False' otherwise | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Amount Change] | computed | [Reimbursement Coin Balance] vs [Current Coin Balance] | CASE: 'True' if ISNULL values differ, 'False' otherwise | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Any Change] | computed | [Regulation Changed], [Country Changed], [Amount Change] | CASE: 'True' if any of the three change flags is True | Tier 2 — SP_EXW_CompensationClosingCountries |
| [Non Zero Wallet] | computed | [Current Coin Balance], [Reimbursement Coin Balance] | CASE: 'True' if either current or reimbursement coin balance > 0 | Tier 2 — SP_EXW_CompensationClosingCountries |
| UpdateDate | GETDATE() | — | ETL timestamp | Tier 2 — SP_EXW_CompensationClosingCountries |
| PlatformUSDCompensationPerGCID | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) per GCID WHERE ActionTypeID=36, CompensationReasonID IN (101,102), Occurred≥'2022-05-01' | Tier 2 — SP_EXW_CompensationClosingCountries |
| WalletDataUSDReimbursementPerGCID | EXW_dbo.EXW_CompensationClosingCountries | USD_FinalBalance | SUM([Reimbursement USD Balance]) per GCID (all crypto) | Tier 2 — SP_EXW_CompensationClosingCountries |
| WalletVsPlatform | computed | PlatformUSDCompensationPerGCID vs WalletDataUSDReimbursementPerGCID | CASE: 'No Gap' / 'Wallet Above Platform Record for Reason 101,102' / 'Only Platform' / 'Only Wallet Side' / 'Dups' / 'ToCheck' | Tier 2 — SP_EXW_CompensationClosingCountries |
| MaxPlatformCreditDate | DWH_dbo.Fact_CustomerAction | Occurred | MAX(CreditDate) per GCID, same filter as PlatformUSDCompensationPerGCID | Tier 2 — SP_EXW_CompensationClosingCountries |
| TotalExtractedUnitsPerCrypto | EXW_dbo.EXW_FactTransactions | Amount | SUM(Amount) per GCID+CryptoId WHERE TransactionTypeID=13, TranStatusID=2, TranDate>'2024-01-18' | Tier 2 — SP_EXW_CompensationClosingCountries |
| TotalExtractedUSDPerCrypto | EXW_dbo.EXW_FactTransactions | AmountUSD | SUM(AmountUSD) per GCID+CryptoId, same filter | Tier 2 — SP_EXW_CompensationClosingCountries |
| LastExtractionDatePerCrypto | EXW_dbo.EXW_FactTransactions | TranDate | MAX(TranDate) per GCID+CryptoId, same filter | Tier 2 — SP_EXW_CompensationClosingCountries |
| LastWalletEntity | EXW_dbo.EXW_WalletEntity | WalletEntity | Most recent EXW_WalletEntity.WalletEntity per GCID (at MAX(Date)) | Tier 2 — SP_EXW_CompensationClosingCountries |
| WalletEntity | EXW_dbo.EXW_WalletEntity | WalletEntity | EXW_WalletEntity.WalletEntity at CompensationDate | Tier 2 — SP_EXW_CompensationClosingCountries |

## Source Objects

| Object | Role |
|---|---|
| EXW_dbo.EXW_CompensationClosingCountries | Primary input — compensation registry (19 columns passed through) |
| DWH_dbo.Dim_Customer | Source of AccountStatusID, PlayerStatusID, VerificationLevelID, PlayerStatusReasonID, PlayerStatusSubReasonID |
| DWH_dbo.Fact_CustomerAction | Source of platform compensation amounts (ActionTypeID=36, CompensationReasonID 101/102) |
| DWH_dbo.Dim_AccountStatus | Lookup for AccountStatusName |
| DWH_dbo.Dim_PlayerStatus | Lookup for PlayerStatus (Name) |
| DWH_dbo.Dim_PlayerStatusReasons | Lookup for PlayerStatusReason (Name) |
| DWH_dbo.Dim_PlayerStatusSubReasons | Lookup for PlayerStatusSubReason (PlayerStatusSubReasonName) |
| EXW_dbo.EXW_DimUser | Source of Current Country, Regulation, Club, UserRegion_State, IsTestAccount |
| EXW_dbo.EXW_UserSettingsWalletAllowance | Source of UserWalletAllowance, UserWalletAllowanceBeginDate |
| EXW_dbo.EXW_FinanceReportsBalancesNew | Source of current balance snapshot (Balance, BalanceDate at @d) |
| EXW_dbo.EXW_FactTransactions | Source of extraction activity (TransactionTypeID=13 since 2024-01-18) |
| EXW_Wallet.EXW_PriceDaily | Source of CurrentUSDRate (AvgPrice at @d) |
| EXW_dbo.EXW_WalletEntity | Source of WalletEntity (at CompensationDate) and LastWalletEntity (most recent) |
| EXW_dbo.SP_EXW_CompensationClosingCountries | Writer SP — also writes EXW_ReimbursementSumTable in same run |

## Tier Summary

| Tier | Count | Columns |
|---|---|---|
| Tier 1 | 3 | CurrentCountryID, CurrentRegulationID, VerificationLevelID |
| Tier 2 | 53 | All remaining columns — SP-derived, computed, aggregated, or lookup-enriched |
