# Column Lineage — eMoney_dbo.v_eMoney_Dim_Account

Generated: 2026-04-21

## Source Objects

| Object | Type | Role |
|--------|------|------|
| `eMoney_dbo.eMoney_Dim_Account` | Table | Base table — all 78 columns are direct SELECT pass-throughs |

## View Behaviour

- `WITH a AS (SELECT MAX(UpdateDate) FROM eMoney_Dim_Account)` — CTE to get today's max update date
- `WHERE CAST(GETDATE() AS DATE) = (SELECT CAST(UpdateDate AS DATE) FROM a)` — live date filter: returns rows only on the day SP_eMoney_Dim_Account ran
- `TOP (1000)` — limits output to 1,000 rows (no ORDER BY — arbitrary selection)
- On non-SP-run days the view returns 0 rows (current state: 0 rows as of 2026-04-21; base table last updated 2026-04-13)

## Column Lineage

All 78 columns are direct SELECT pass-throughs from `eMoney_dbo.eMoney_Dim_Account` with no transformation.
Excluded from view: RegAccountProgramID, RegAccountProgram, RegAccountSubProgramID, RegAccountSubProgram, HasAccountProgramChanged, HasAccountSubProgramChanged, AccountPropertiesTime, AccountPropertiesDate, CountAccountProgramChanges, CountAccountSubProgramChanges, Entity (11 columns).

| # | View Column | Base Table Column | Source | Tier |
|---|------------|------------------|--------|------|
| 1 | CurrencyBalanceID | eMoney_Dim_Account.CurrencyBalanceID | dbo.FiatCurrencyBalances | 1 |
| 2 | AccountID | eMoney_Dim_Account.AccountID | dbo.FiatAccount | 1 |
| 3 | GCID | eMoney_Dim_Account.GCID | dbo.FiatAccount | 1 |
| 4 | CID | eMoney_Dim_Account.CID | Customer.CustomerStatic | 1 |
| 5 | ClubID | eMoney_Dim_Account.ClubID | Customer.CustomerStatic | 1 |
| 6 | Club | eMoney_Dim_Account.Club | SP_eMoney_Dim_Account | 2 |
| 7 | ClubCategory | eMoney_Dim_Account.ClubCategory | SP_eMoney_Dim_Account | 2 |
| 8 | RegulationID | eMoney_Dim_Account.RegulationID | BackOffice.Customer | 1 |
| 9 | Regulation | eMoney_Dim_Account.Regulation | SP_eMoney_Dim_Account | 2 |
| 10 | CountryID | eMoney_Dim_Account.CountryID | Customer.CustomerStatic | 1 |
| 11 | Country | eMoney_Dim_Account.Country | SP_eMoney_Dim_Account | 2 |
| 12 | Region | eMoney_Dim_Account.Region | SP_eMoney_Dim_Account | 2 |
| 13 | PlayerStatusID | eMoney_Dim_Account.PlayerStatusID | Customer.CustomerStatic | 1 |
| 14 | PlayerStatus | eMoney_Dim_Account.PlayerStatus | SP_eMoney_Dim_Account | 2 |
| 15 | IsValidETM | eMoney_Dim_Account.IsValidETM | SP_eMoney_Dim_Account | 2 |
| 16 | IsValidCustomer | eMoney_Dim_Account.IsValidCustomer | SP_Dim_Customer | 2 |
| 17 | IsTestAccount | eMoney_Dim_Account.IsTestAccount | SP_eMoney_Dim_Account | 2 |
| 18 | IsCancelledAccount | eMoney_Dim_Account.IsCancelledAccount | SP_eMoney_Dim_Account | 2 |
| 19 | GCID_Unique_Count | eMoney_Dim_Account.GCID_Unique_Count | SP_eMoney_Dim_Account | 2 |
| 20 | TP_RegDate | eMoney_Dim_Account.TP_RegDate | Customer.CustomerStatic | 1 |
| 21 | TP_FTDDate | eMoney_Dim_Account.TP_FTDDate | SP_Dim_Customer | 2 |
| 22 | RegClubID | eMoney_Dim_Account.RegClubID | SP_eMoney_Dim_Account | 2 |
| 23 | RegClub | eMoney_Dim_Account.RegClub | SP_eMoney_Dim_Account | 2 |
| 24 | RegClubCategory | eMoney_Dim_Account.RegClubCategory | SP_eMoney_Dim_Account | 2 |
| 25 | RegRegulationID | eMoney_Dim_Account.RegRegulationID | SP_eMoney_Dim_Account | 2 |
| 26 | RegRegulation | eMoney_Dim_Account.RegRegulation | SP_eMoney_Dim_Account | 2 |
| 27 | RegCountryID | eMoney_Dim_Account.RegCountryID | SP_eMoney_Dim_Account | 2 |
| 28 | RegCountry | eMoney_Dim_Account.RegCountry | SP_eMoney_Dim_Account | 2 |
| 29 | RegRegion | eMoney_Dim_Account.RegRegion | SP_eMoney_Dim_Account | 2 |
| 30 | RegPlayerStatusID | eMoney_Dim_Account.RegPlayerStatusID | SP_eMoney_Dim_Account | 2 |
| 31 | RegPlayerStatus | eMoney_Dim_Account.RegPlayerStatus | SP_eMoney_Dim_Account | 2 |
| 32 | HasCustomerInfoChanged | eMoney_Dim_Account.HasCustomerInfoChanged | SP_eMoney_Dim_Account | 2 |
| 33 | HasClubChanged | eMoney_Dim_Account.HasClubChanged | SP_eMoney_Dim_Account | 2 |
| 34 | HasRegulationChanged | eMoney_Dim_Account.HasRegulationChanged | SP_eMoney_Dim_Account | 2 |
| 35 | HasCountryChanged | eMoney_Dim_Account.HasCountryChanged | SP_eMoney_Dim_Account | 2 |
| 36 | HasPlayerStatusChanged | eMoney_Dim_Account.HasPlayerStatusChanged | SP_eMoney_Dim_Account | 2 |
| 37 | CurrencyBalanceISOCode | eMoney_Dim_Account.CurrencyBalanceISOCode | dbo.FiatCurrencyBalances | 1 |
| 38 | CurrencyBalanceISODesc | eMoney_Dim_Account.CurrencyBalanceISODesc | SP_eMoney_Dim_Account | 2 |
| 39 | CurrencyBalanceCreateTime | eMoney_Dim_Account.CurrencyBalanceCreateTime | dbo.FiatCurrencyBalances | 1 |
| 40 | CurrencyBalanceCreateDate | eMoney_Dim_Account.CurrencyBalanceCreateDate | SP_eMoney_Dim_Account | 2 |
| 41 | CurrencyBalanceCreateDateID | eMoney_Dim_Account.CurrencyBalanceCreateDateID | SP_eMoney_Dim_Account | 2 |
| 42 | CurrencyBalanceStatusID | eMoney_Dim_Account.CurrencyBalanceStatusID | SP_eMoney_Dim_Account | 2 |
| 43 | CurrencyBalanceStatus | eMoney_Dim_Account.CurrencyBalanceStatus | SP_eMoney_Dim_Account | 2 |
| 44 | CurrencyBalanceStatusTime | eMoney_Dim_Account.CurrencyBalanceStatusTime | SP_eMoney_Dim_Account | 2 |
| 45 | ProviderDesc | eMoney_Dim_Account.ProviderDesc | SP_eMoney_Dim_Account | 2 |
| 46 | ProviderCurrencyBalanceID | eMoney_Dim_Account.ProviderCurrencyBalanceID | SP_eMoney_Dim_Account | 2 |
| 47 | BankAccountID | eMoney_Dim_Account.BankAccountID | dbo.FiatBankAccount | 1 |
| 48 | BankAccountIsExternal | eMoney_Dim_Account.BankAccountIsExternal | dbo.FiatBankAccount | 1 |
| 49 | BankAccountName | eMoney_Dim_Account.BankAccountName | dbo.FiatBankAccount | 1 |
| 50 | BankAccountNumber | eMoney_Dim_Account.BankAccountNumber | dbo.FiatBankAccount | 1 |
| 51 | BankAccountSortCode | eMoney_Dim_Account.BankAccountSortCode | dbo.FiatBankAccount | 1 |
| 52 | BankAccountIBAN | eMoney_Dim_Account.BankAccountIBAN | dbo.FiatBankAccount | 1 |
| 53 | BankAccountBIC | eMoney_Dim_Account.BankAccountBIC | dbo.FiatBankAccount | 1 |
| 54 | AccountCreateTime | eMoney_Dim_Account.AccountCreateTime | dbo.FiatAccount | 1 |
| 55 | AccountCreateDate | eMoney_Dim_Account.AccountCreateDate | SP_eMoney_Dim_Account | 2 |
| 56 | AccountCreateDateID | eMoney_Dim_Account.AccountCreateDateID | SP_eMoney_Dim_Account | 2 |
| 57 | AccountStatusID | eMoney_Dim_Account.AccountStatusID | dbo.FiatAccountStatuses | 1 |
| 58 | AccountStatus | eMoney_Dim_Account.AccountStatus | SP_eMoney_Dim_Account | 2 |
| 59 | AccountStatusTime | eMoney_Dim_Account.AccountStatusTime | SP_eMoney_Dim_Account | 2 |
| 60 | AccountProgramID | eMoney_Dim_Account.AccountProgramID | dbo.FiatAccount | 1 |
| 61 | AccountProgram | eMoney_Dim_Account.AccountProgram | SP_eMoney_Dim_Account | 2 |
| 62 | AccountSubProgramID | eMoney_Dim_Account.AccountSubProgramID | dbo.FiatAccount | 1 |
| 63 | AccountSubProgram | eMoney_Dim_Account.AccountSubProgram | SP_eMoney_Dim_Account | 2 |
| 64 | ProviderHolderID | eMoney_Dim_Account.ProviderHolderID | SP_eMoney_Dim_Account | 2 |
| 65 | Seniority_TP_RegDate | eMoney_Dim_Account.Seniority_TP_RegDate | SP_eMoney_Dim_Account | 2 |
| 66 | Seniority_TP_FTDDate | eMoney_Dim_Account.Seniority_TP_FTDDate | SP_eMoney_Dim_Account | 2 |
| 67 | Seniority_eTM_RegDate | eMoney_Dim_Account.Seniority_eTM_RegDate | SP_eMoney_Dim_Account | 2 |
| 68 | HasCard | eMoney_Dim_Account.HasCard | SP_eMoney_Dim_Account | 2 |
| 69 | CardID | eMoney_Dim_Account.CardID | dbo.FiatCards | 1 |
| 70 | CardCreateTime | eMoney_Dim_Account.CardCreateTime | dbo.FiatCards | 1 |
| 71 | CardCreateDate | eMoney_Dim_Account.CardCreateDate | SP_eMoney_Dim_Account | 2 |
| 72 | CardCreateDateID | eMoney_Dim_Account.CardCreateDateID | SP_eMoney_Dim_Account | 2 |
| 73 | CardStatusID | eMoney_Dim_Account.CardStatusID | dbo.FiatCardStatuses | 1 |
| 74 | CardStatus | eMoney_Dim_Account.CardStatus | SP_eMoney_Dim_Account | 2 |
| 75 | CardStatusExpirationTime | eMoney_Dim_Account.CardStatusExpirationTime | dbo.FiatCardStatuses | 1 |
| 76 | CardStatusTime | eMoney_Dim_Account.CardStatusTime | dbo.FiatCardStatuses | 1 |
| 77 | ProviderCardID | eMoney_Dim_Account.ProviderCardID | SP_eMoney_Dim_Account | 2 |
| 78 | UpdateDate | eMoney_Dim_Account.UpdateDate | SP_eMoney_Dim_Account | 2 |

## External Lineage (UC)

UC Target: `_Not_Migrated`

This view has no Unity Catalog target. It is a live operational view, not included in the Databricks Gold layer.
