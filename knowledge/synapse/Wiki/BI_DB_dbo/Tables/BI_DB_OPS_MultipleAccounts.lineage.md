# BI_DB_dbo.BI_DB_OPS_MultipleAccounts — Column Lineage

## Writer SP
`BI_DB_dbo.SP_OPS_MultipleAccounts` — daily TRUNCATE+INSERT

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Dim_Customer | DWH_dbo | Primary — customer identity, demographics, compliance attributes |
| DWH_dbo.Dim_Country | DWH_dbo | Dim-lookup — Country name from CountryID |
| DWH_dbo.Dim_PlayerStatus | DWH_dbo | Dim-lookup — PlayerStatus name from PlayerStatusID |
| DWH_dbo.Dim_PlayerStatusReasons | DWH_dbo | Dim-lookup — PlayerStatusReason name from PlayerStatusReasonID |
| DWH_dbo.Dim_PlayerStatusSubReasons | DWH_dbo | Dim-lookup — PlayerStatusSubReasonName from PlayerStatusSubReasonID |
| DWH_dbo.Dim_PlayerLevel | DWH_dbo | Dim-lookup — PlayerLevel/Club name from PlayerLevelID |
| DWH_dbo.Dim_Regulation | DWH_dbo | Dim-lookup — Regulation name from RegulationID |
| DWH_dbo.Dim_GuruStatus | DWH_dbo | Dim-lookup — GuruStatusName from GuruStatusID |
| DWH_dbo.Dim_PendingClosureStatus | DWH_dbo | Dim-lookup — PendingClosureStatusName from PendingClosureStatusID |
| DWH_dbo.V_Liabilities | DWH_dbo | TotalEquity = Liabilities + ActualNWA |
| EXW_dbo.EXW_FinanceReportsBalancesNew | EXW_dbo | WalletBalanceUSD = SUM(BalanceUSD) by RealCID |
| BI_DB_dbo.BI_DB_CIDFirstDates | BI_DB_dbo | LastLoggedIn, VerificationLevel3Date |
| DWH_dbo.Dim_Position | DWH_dbo | HasOpenTrades (open positions), HasOpenRealCryptoPosition (InstrumentTypeID=10) |
| DWH_dbo.Dim_Instrument | DWH_dbo | InstrumentTypeID=10 filter for crypto |
| eMoney_dbo.eMoney_Dim_Account | eMoney_dbo | HaseMoney flag |
| BI_DB_dbo.External_etoro_BackOffice_Customer | BI_DB_dbo | MasterAccountCID for account type classification |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| ID | (computed) | — | DENSE_RANK() OVER (ORDER BY FN+LN+Country+BirthDate+Gender DESC) |
| CID | DWH_dbo.Dim_Customer | RealCID | rename (RealCID → CID) |
| FirstName | DWH_dbo.Dim_Customer | FirstName | LOWER() applied |
| LastName | DWH_dbo.Dim_Customer | LastName | LOWER() applied |
| BirthDate | DWH_dbo.Dim_Customer | BirthDate | passthrough |
| Gender | DWH_dbo.Dim_Customer | Gender | passthrough |
| Country | DWH_dbo.Dim_Country | Name | dim-lookup passthrough (JOIN on CountryID) |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | passthrough (always 3 due to WHERE filter) |
| NoOfRelations | (computed) | — | COUNT(DISTINCT CID) - 1 per PII group |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | dim-lookup passthrough (JOIN on PlayerStatusID) |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Name | dim-lookup passthrough (JOIN on PlayerLevelID) |
| Regulation | DWH_dbo.Dim_Regulation | Name | dim-lookup passthrough (JOIN on RegulationID) |
| FN_LN_Country_BirthDate_Gender | (computed) | — | CONCAT(LOWER(FirstName), LOWER(LastName), Country, BirthDate, Gender) |
| TotalEquity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | computation (sum of two fields) |
| WalletBalanceUSD | EXW_dbo.EXW_FinanceReportsBalancesNew | BalanceUSD | SUM(BalanceUSD) WHERE Balance>0 by RealCID |
| TP_and_Wallet_Equity | (computed) | — | ISNULL(TotalEquity, 0) + ISNULL(WalletBalanceUSD, 0) |
| LastLoggedIn | BI_DB_dbo.BI_DB_CIDFirstDates | LastLoggedIn | passthrough |
| PendingClosureStatusName | DWH_dbo.Dim_PendingClosureStatus | PendingClosureStatusName | dim-lookup passthrough (JOIN on PendingClosureStatusID) |
| GuruStatusName | DWH_dbo.Dim_GuruStatus | GuruStatusName | dim-lookup passthrough (JOIN on GuruStatusID) |
| HasOpenTrades | DWH_dbo.Dim_Position | CID | MAX(CASE WHEN dp.CID IS NOT NULL THEN 1 ELSE 0 END) — open positions check |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | dim-lookup passthrough (JOIN on PlayerStatusReasonID) |
| PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | dim-lookup passthrough (JOIN on PlayerStatusSubReasonID) |
| Club | DWH_dbo.Dim_PlayerLevel | Name | dim-lookup passthrough (same as PlayerLevel — from initial #List_Init) |
| VerificationLevel3Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel3Date | passthrough |
| HasOpenRealCryptoPosition | DWH_dbo.Dim_Position + Dim_Instrument | CID | CASE WHEN open crypto position exists (InstrumentTypeID=10, CloseDateID=0, IsSettled=1) |
| Rank | (computed) | — | ROW_NUMBER() PARTITION BY ID ORDER BY equity priority + last login |
| ClubNonClubPhysicalPerson | (computed) | — | CASE WHEN any group member is above Bronze THEN 'Club' ELSE 'Not Club' |
| Keep Y/N | (computed) | — | CASE: Club + Rank<6='Yes', Not Club + Rank<2='Yes', else 'No' |
| RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | passthrough |
| HasWallet | DWH_dbo.Dim_Customer | HasWallet | passthrough |
| HaseMoney | eMoney_dbo.eMoney_Dim_Account | CID | CASE WHEN em.CID IS NOT NULL THEN 1 ELSE 0 END |
| MasterAccountCID | External_etoro_BackOffice_Customer | MasterAccountCID | passthrough |
| AccountType | (computed) | — | CASE: NULL='Null', CID=MasterAccountCID='Master', else 'SubAccount' |
| GCID | DWH_dbo.Dim_Customer | GCID | passthrough |
| UpdateDate | (computed) | — | GETDATE() — ETL execution timestamp |

**PHASE 10B CHECKPOINT: PASS**
