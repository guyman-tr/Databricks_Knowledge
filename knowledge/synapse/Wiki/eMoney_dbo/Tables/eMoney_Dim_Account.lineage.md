# eMoney_dbo.eMoney_Dim_Account — Production Lineage Map

## Source Resolution

| Property | Value |
|----------|-------|
| **Production Database** | FiatDwhDB (eToro Money fiat platform DWH) |
| **Production Tables** | dbo.FiatCurrencyBalances, dbo.FiatAccount, dbo.FiatAccountStatuses, dbo.FiatAccountsProperties, dbo.FiatBankAccount, dbo.FiatCards, dbo.FiatCardStatuses, dbo.FiatCurrencyBalancesStatuses |
| **DWH Enrichment Sources** | DWH_dbo.Dim_Customer, DWH_dbo.Dim_PlayerLevel, DWH_dbo.Dim_Regulation, DWH_dbo.Dim_Country, DWH_dbo.Dim_PlayerStatus, DWH_dbo.Fact_SnapshotCustomer |
| **Staging Join Table** | eMoney_dbo.eMoney_Account_Mappings (SP_eMoney_Account_Mappings, 168 lines) |
| **ETL SP** | SP_eMoney_Dim_Account (11-step pipeline, DELETE + INSERT daily, @Date=yesterday) |
| **Upstream Wiki** | BankingDBs/FiatDwhDB/Wiki/ (6 tables with wikis) + knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account |

## ETL Pipeline Summary

```
Step 01: #account_program — latest FiatAccountsProperties per AccountId (RNDesc=1 by Created)
         Joined: eMoney_Dictionary_AccountProgram, SubPrograms
Step 02: #account_program_change_count — COUNT DISTINCT program/subprogram changes per AccountId
Step 03: #currency_balance_status — latest FiatCurrencyBalancesStatuses per CurrencyBalanceId (RNDesc=1 by EventTimestamp)
Step 04: #account_status — latest FiatAccountStatuses per AccountId (RNDesc=1 by Created)
Step 05: #card_status — latest FiatCardStatuses per CardId (RNDesc=1 by EventTimestamp)
Step 06: #fivetran_test_users — GCID list from eMoney_google_sheets.emoney_test_users (Fivetran)
Step 07: #account_mapping — central join of eMoney_Account_Mappings + all above temp tables
         Computes: GCID_Unique_Count (ROW_NUMBER PARTITION BY GCID ORDER BY AccountCreateTime DESC)
                   HasCard (CardID IS NOT NULL), IsTestAccount (Fivetran lookup), IsCancelledAccount (GCID=0)
Step 08: #customer_current — current DWH attributes for primary account (GCID_Unique_Count=1)
         Source: Dim_Customer INNER JOIN Dim_PlayerLevel + Dim_Regulation + Dim_Country + Dim_PlayerStatus
         Computes: ClubCategory (CASE on PlayerLevelID), Seniority_TP_RegDate/FTDDate (DATEDIFF MONTH)
Step 09: #customer_snapshot — registration-time DWH attributes (GCID_Unique_Count=1)
         Source: Fact_SnapshotCustomer INNER JOIN Dim_Range (AccountCreateDateID between From/To) + Dim_*
Step 10: #final — combines all sources; adds HasCustomerInfoChanged + component change flags
         Entity from eMoney_EntityByCurrencyISO_MappingStatic (via CurrencyBalanceISOCode)
Step 11: DELETE FROM eMoney_Dim_Account + INSERT from #final
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform |
|---|-----------|-------------|---------------|-----------|
| 1 | CurrencyBalanceID | dbo.FiatCurrencyBalances | Id | Passthrough via Account_Mappings |
| 2 | AccountID | dbo.FiatAccount | Id | Passthrough via Account_Mappings |
| 3 | GCID | dbo.FiatAccount | Gcid | Passthrough via Account_Mappings |
| 4 | CID | DWH_dbo.Dim_Customer | RealCID | Passthrough (rename: RealCID→CID) |
| 5 | ClubID | DWH_dbo.Dim_Customer | PlayerLevelID | Passthrough (rename: PlayerLevelID→ClubID) |
| 6 | Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN lookup on PlayerLevelID |
| 7 | ClubCategory | Computed | — | CASE on PlayerLevelID: 1=NoClub, 3/5=LowClub, 2/6/7=HighClub, 4=Internal |
| 8 | RegulationID | DWH_dbo.Dim_Customer | RegulationID | Passthrough |
| 9 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN lookup on RegulationID |
| 10 | CountryID | DWH_dbo.Dim_Customer | CountryID | Passthrough |
| 11 | Country | DWH_dbo.Dim_Country | Name | JOIN lookup on CountryID |
| 12 | Region | DWH_dbo.Dim_Country | Region | JOIN lookup on CountryID |
| 13 | PlayerStatusID | DWH_dbo.Dim_Customer | PlayerStatusID | Passthrough |
| 14 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN lookup on PlayerStatusID |
| 15 | IsValidETM | Computed | — | CASE: IsValidCustomer=1 AND IsTestAccount=0 AND IsCancelledAccount=0 |
| 16 | IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer | Passthrough (originally computed in SP_Dim_Customer) |
| 17 | IsTestAccount | eMoney_google_sheets.emoney_test_users | gcid | CASE: GCID in Fivetran test user list → 1 else 0 |
| 18 | IsCancelledAccount | Computed | — | CASE WHEN GCID=0 THEN 1 ELSE 0 (cancelled accounts have GCID=0) |
| 19 | GCID_Unique_Count | Computed | — | ROW_NUMBER() PARTITION BY GCID ORDER BY AccountCreateTime DESC |
| 20 | TP_RegDate | DWH_dbo.Dim_Customer | RegisteredReal | CAST(RegisteredReal AS DATE) |
| 21 | TP_FTDDate | DWH_dbo.Dim_Customer | FirstDepositDate | CAST(FirstDepositDate AS DATE) |
| 22 | RegClubID | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | Snapshot at AccountCreateDateID range |
| 23 | RegClub | DWH_dbo.Dim_PlayerLevel | Name | JOIN on RegClubID |
| 24 | RegClubCategory | Computed | — | CASE on RegClubID (same mapping as ClubCategory) |
| 25 | RegRegulationID | DWH_dbo.Fact_SnapshotCustomer | RegulationID | Snapshot at AccountCreateDateID range |
| 26 | RegRegulation | DWH_dbo.Dim_Regulation | Name | JOIN on RegRegulationID |
| 27 | RegCountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | Snapshot at AccountCreateDateID range |
| 28 | RegCountry | DWH_dbo.Dim_Country | Name | JOIN on RegCountryID |
| 29 | RegRegion | DWH_dbo.Dim_Country | Region | JOIN on RegCountryID |
| 30 | RegPlayerStatusID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | Snapshot at AccountCreateDateID range |
| 31 | RegPlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN on RegPlayerStatusID |
| 32 | RegAccountProgramID | dbo.FiatAccount | AccountProgramId | Original program at account creation (from Account_Mappings baseline) |
| 33 | RegAccountProgram | eMoney_dbo.eMoney_Dictionary_AccountProgram | AccountProgram | JOIN lookup on RegAccountProgramID |
| 34 | RegAccountSubProgramID | dbo.FiatAccount | SubProgramId | Original sub-program at account creation (from Account_Mappings baseline) |
| 35 | RegAccountSubProgram | eMoney_dbo.SubPrograms | Name | JOIN lookup on RegAccountSubProgramID |
| 36 | HasCustomerInfoChanged | Computed | — | CASE: 0 if all current vs reg attributes match, else 1 |
| 37 | HasClubChanged | Computed | — | CASE WHEN ClubID <> RegClubID |
| 38 | HasRegulationChanged | Computed | — | CASE WHEN RegulationID <> RegRegulationID |
| 39 | HasCountryChanged | Computed | — | CASE WHEN CountryID <> RegCountryID |
| 40 | HasPlayerStatusChanged | Computed | — | CASE WHEN PlayerStatusID <> RegPlayerStatusID |
| 41 | HasAccountProgramChanged | Computed | — | CASE WHEN AccountProgramID <> RegAccountProgramID |
| 42 | HasAccountSubProgramChanged | Computed | — | CASE WHEN AccountSubProgramID <> RegAccountSubProgramID |
| 43 | CurrencyBalanceISOCode | dbo.FiatCurrencyBalances | CurrencyISON | Passthrough (rename: CurrencyISON→CurrencyBalanceISOCode) |
| 44 | CurrencyBalanceISODesc | eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static | Currency | JOIN on CurrencyISON WHERE SellCurrencyID=1 |
| 45 | CurrencyBalanceCreateTime | dbo.FiatCurrencyBalances | Created | Passthrough (rename: Created→CurrencyBalanceCreateTime) |
| 46 | CurrencyBalanceCreateDate | Computed | — | CAST(CurrencyBalanceCreateTime AS DATE) |
| 47 | CurrencyBalanceCreateDateID | Computed | — | CONVERT(VARCHAR(8), CurrencyBalanceCreateTime, 112)::INT (YYYYMMDD) |
| 48 | CurrencyBalanceStatusID | dbo.FiatCurrencyBalancesStatuses | StatusType | Latest status per CurrencyBalanceId (RNDesc=1 by EventTimestamp) |
| 49 | CurrencyBalanceStatus | eMoney_dbo.eMoney_Dictionary_CurrencyBalanceStatus | CurrencyBalanceStatus | JOIN lookup on CurrencyBalanceStatusID |
| 50 | CurrencyBalanceStatusTime | dbo.FiatCurrencyBalancesStatuses | EventTimestamp | Latest event timestamp (RNDesc=1) |
| 51 | ProviderDesc | eMoney_dbo.eMoney_Account_Mappings | ProviderDesc | Passthrough (from AccountsProviderHoldersMapping) |
| 52 | ProviderCurrencyBalanceID | eMoney_dbo.eMoney_Account_Mappings | ProviderCurrencyBalanceID | Passthrough (from CurrencyBalancesProvidersMapping) |
| 53 | BankAccountID | dbo.FiatBankAccount | Id | Passthrough via Account_Mappings.BankAccountID |
| 54 | BankAccountIsExternal | dbo.FiatBankAccount | IsExternal | Passthrough |
| 55 | BankAccountName | dbo.FiatBankAccount | FullName | Passthrough (rename: FullName→BankAccountName) |
| 56 | BankAccountNumber | dbo.FiatBankAccount | BankAccountNumber | Passthrough |
| 57 | BankAccountSortCode | dbo.FiatBankAccount | SortCode | Passthrough |
| 58 | BankAccountIBAN | dbo.FiatBankAccount | Iban | Passthrough |
| 59 | BankAccountBIC | dbo.FiatBankAccount | Bic | Passthrough |
| 60 | AccountCreateTime | dbo.FiatAccount | Created | Passthrough (rename: Created→AccountCreateTime) |
| 61 | AccountCreateDate | Computed | — | CAST(AccountCreateTime AS DATE) |
| 62 | AccountCreateDateID | Computed | — | CONVERT(VARCHAR(8), AccountCreateTime, 112)::INT (YYYYMMDD) |
| 63 | AccountStatusID | dbo.FiatAccountStatuses | StatusType | Latest status per AccountId (RNDesc=1 by Created) |
| 64 | AccountStatus | eMoney_dbo.eMoney_Dictionary_AccountStatus | AccountStatus | JOIN lookup on AccountStatusID |
| 65 | AccountStatusTime | dbo.FiatAccountStatuses | Created | Latest Created timestamp (RNDesc=1) |
| 66 | AccountProgramID | dbo.FiatAccount / dbo.FiatAccountsProperties | AccountProgramId | ISNULL(latest from FiatAccountsProperties, original from FiatAccount) |
| 67 | AccountProgram | eMoney_dbo.eMoney_Dictionary_AccountProgram | AccountProgram | JOIN lookup on AccountProgramID |
| 68 | AccountSubProgramID | dbo.FiatAccount / dbo.FiatAccountsProperties | SubProgramId | ISNULL(latest from FiatAccountsProperties, original from FiatAccount) |
| 69 | AccountSubProgram | eMoney_dbo.SubPrograms | Name | JOIN lookup on AccountSubProgramID |
| 70 | AccountPropertiesTime | dbo.FiatAccountsProperties | Created | Latest Created timestamp (RNDesc=1 by Created) |
| 71 | AccountPropertiesDate | Computed | — | CAST(AccountPropertiesTime AS DATE) |
| 72 | CountAccountProgramChanges | Computed | — | COUNT DISTINCT AccountProgramId per AccountId; CASE WHEN ≤1 THEN 0 |
| 73 | CountAccountSubProgramChanges | Computed | — | COUNT DISTINCT SubProgramId per AccountId; CASE WHEN ≤1 THEN 0 |
| 74 | ProviderHolderID | eMoney_dbo.eMoney_Account_Mappings | ProviderHolderID | Passthrough (from AccountsProviderHoldersMapping) |
| 75 | Seniority_TP_RegDate | Computed | — | DATEDIFF(MONTH, Dim_Customer.RegisteredReal, @Date) |
| 76 | Seniority_TP_FTDDate | Computed | — | DATEDIFF(MONTH, Dim_Customer.FirstDepositDate, @Date) |
| 77 | Seniority_eTM_RegDate | Computed | — | DATEDIFF(MONTH, FiatAccount.Created, @Date) |
| 78 | HasCard | Computed | — | CASE WHEN CardID IS NOT NULL THEN 1 ELSE 0 |
| 79 | CardID | dbo.FiatCards | Id | Passthrough via Account_Mappings.CardID |
| 80 | CardCreateTime | dbo.FiatCards | Created | Passthrough (rename: Created→CardCreateTime) |
| 81 | CardCreateDate | Computed | — | CAST(CardCreateTime AS DATE) |
| 82 | CardCreateDateID | Computed | — | CONVERT(VARCHAR(8), CardCreateTime, 112)::INT (YYYYMMDD) |
| 83 | CardStatusID | dbo.FiatCardStatuses | CardStatusId | Latest status per CardId (RNDesc=1 by EventTimestamp) |
| 84 | CardStatus | eMoney_dbo.eMoney_Dictionary_CardStatus | CardStatus | JOIN lookup on CardStatusID |
| 85 | CardStatusExpirationTime | dbo.FiatCardStatuses | ExpirationDate | Latest ExpirationDate (RNDesc=1) |
| 86 | CardStatusTime | dbo.FiatCardStatuses | EventTimestamp | Latest EventTimestamp (RNDesc=1) |
| 87 | ProviderCardID | eMoney_dbo.eMoney_Account_Mappings | ProviderCardID | Passthrough (from CardsProvidersMapping) |
| 88 | UpdateDate | Computed | — | GETDATE() at INSERT time |
| 89 | Entity | eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic | Entity | LEFT JOIN on CurrencyBalanceISOCode; ISNULL(Entity, 'N/A') |

## Tier 1 Coverage Check

| Metric | Value |
|--------|-------|
| Total columns | 89 |
| Tier 1 (verbatim / T1+DWH note) | 29 |
| Tier 2 (computed/lookup/no-wiki) | 60 |
| Tier 1 % | 32.6% |
| Upstream wiki column count (FiatDwhDB) | 25 documented columns matched |
| HARD FAIL check (>20 upstream AND tier1=0) | PASS — 29 Tier 1 columns assigned |

PHASE 10B CHECKPOINT: PASS
