# EXW_dbo.EXW_AML_Users_Report — Column Lineage

**Writer SP**: `EXW_dbo.SP_EXW_UserSettingsWalletAllowance`
**Load Pattern**: TRUNCATE + INSERT (full daily refresh, co-written with EXW_UserSettingsWalletAllowance)
**Generated**: 2026-04-20

---

## ETL Source Objects

| Object | Role |
|--------|------|
| `EXW_dbo.EXW_DimUser` | User scope base (#user): GCID, RealCID, IsTestAccount |
| `EXW_dbo.EXW_DimUser_Enriched` | Enriched user dimension: Country, IsValidCustomer, VerificationLevelID, JoinDate, StatusChangeDate, WalletBalanceUSD |
| `DWH_dbo.Dim_Customer` | Customer master (WHERE HasWallet=1 via #dim): PlayerStatusID, CountryID, BirthDate, EvMatchStatus, FirstDepositDate, ScreeningStatusID, RiskClassificationID, AccountStatusID, AccountTypeID, PlayerLevelID, RegulationID, CountryIDByIP, RiskStatusID |
| `EXW_dbo.EXW_UserSettingsWalletAllowance` | Wallet allowance decision passthrough: UserWalletAllowance, ClosingProject (Project) |
| `EXW_dbo.EXW_AMLProviderID` | AML provider registry: ProviderUserIDNormalized, ProviderUserID, AMLProviderID |
| `DWH_dbo.Dim_PlayerStatus` | Player status name resolution: CurrentPlayerStatus |
| `DWH_dbo.Dim_RiskStatus` | Risk status name resolution: RiskStatus |
| `DWH_dbo.Dim_ScreeningStatus` | Screening status label resolution (DWH + external): ScreeningStatus, ScreeningStatusExt |
| `DWH_dbo.Dim_Country` | Country name (CountryByIP) and country risk rank (CountryRankID = RiskGroupID) |
| `DWH_dbo.Dim_PlayerStatusReasons` | Player status reason label: PlayerStatusReason |
| `DWH_dbo.Dim_PlayerStatusSubReasons` | Player status sub-reason label: PlayerStatusSubReason |
| `DWH_dbo.Dim_RiskClassification` | Risk classification name: RiskClassificationName |
| `DWH_dbo.Dim_AccountStatus` | Account status label: AccountStatus |
| `DWH_dbo.Dim_AccountType` | Account type label: AccountType |
| `DWH_dbo.Dim_PlayerLevel` | Player level label (Club): Bronze/Silver/Gold/Platinum/Diamond |
| `DWH_dbo.Dim_Regulation` | Regulation name: Regulation |
| `BI_DB_dbo.External_etoro_BackOffice_Customer` | BackOffice CRM AML/Risk free-text notes: AMLComment, RiskComment |
| `BI_DB_dbo.BI_DB_KYC_Panel` | KYC Q18 occupation answer: Occupation |
| `BI_DB_dbo.BI_DB_RiskClassification` | Automated AML risk score and name: RiskScore, RiskScore_Explanation, RiskScoreName |
| `EXW_dbo.EXW_FactTransactions` | Crypto transfer and payment activity: HasCryptoTransfer, HasPayments, FirstTxDate, LastTxDate |
| `DWH_dbo.Fact_CustomerAction` + `DWH_dbo.Dim_Country` | Login activity from high-risk countries (last 60 days): HasRiskCountryLogins |
| `BI_DB_dbo.External_ScreeningService_Screening_UserScreening` | External screening service result: ScreeningStatusID_Ext, ScreeningBeginTime_Ext |

---

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | GCID | EXW_dbo.EXW_DimUser_Enriched | GCID | Passthrough via #all (du.GCID); ultimate source Customer.CustomerStatic | Tier 1 — Customer.CustomerStatic |
| 2 | RealCID | EXW_dbo.EXW_DimUser_Enriched | RealCID | Passthrough via #all (du.RealCID); ultimate source Customer.CustomerStatic | Tier 1 — Customer.CustomerStatic |
| 3 | Country | EXW_dbo.EXW_DimUser_Enriched | Country | Passthrough (already Dim_Country.Name join-resolved in SP_EXW_DimUser_Enriched) | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 4 | IsValidCustomer | EXW_dbo.EXW_DimUser_Enriched | IsValidCustomer | Passthrough (DWH-computed flag in SP_Dim_Customer) | Tier 2 — SP_Dim_Customer |
| 5 | VerificationLevelID | EXW_dbo.EXW_DimUser_Enriched | VerificationLevelID | Passthrough; ultimate source BackOffice.Customer | Tier 1 — BackOffice.Customer |
| 6 | JoinDate | EXW_dbo.EXW_DimUser_Enriched | JoinDate | CAST(JoinDate AS DATE); JoinDate is MIN(Allocated) per GCID from EXW_WalletInventory in SP_EXW_DimUser_Enriched | Tier 2 — SP_EXW_DimUser_Enriched |
| 7 | PlayerStatusID | DWH_dbo.Dim_Customer | PlayerStatusID | Passthrough via #dim (WHERE HasWallet=1); ultimate source Customer.CustomerStatic | Tier 1 — Customer.CustomerStatic |
| 8 | CurrentPlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN on #dim.PlayerStatusID = Dim_PlayerStatus.PlayerStatusID | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 9 | StatusChangeDate | EXW_dbo.EXW_DimUser_Enriched | StatusChangeDate | Passthrough (LAG-based status change date from SP_EXW_DimUser_Enriched) | Tier 2 — SP_EXW_DimUser_Enriched |
| 10 | CountryByIP | DWH_dbo.Dim_Country | Name | JOIN on Dim_Customer.CountryIDByIP = Dim_Country.CountryID (c1 alias) | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 11 | PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | JOIN on Dim_Customer.PlayerStatusReasonID = Dim_PlayerStatusReasons.PlayerStatusReasonID | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 12 | PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | JOIN on Dim_Customer.PlayerStatusSubReasonID | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 13 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on EXW_DimUser_Enriched.RegulationID = Dim_Regulation.DWHRegulationID | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 14 | CountryID | DWH_dbo.Dim_Customer | CountryID | Passthrough via #dim; ultimate source Customer.CustomerStatic | Tier 1 — Customer.CustomerStatic |
| 15 | RiskClassificationID | DWH_dbo.Dim_Customer | RiskClassificationID | Passthrough via #dim; ultimate source BackOffice.Customer | Tier 1 — BackOffice.Customer |
| 16 | IsUS | (computed) | — | CASE: 'Y' when Dim_Customer.RegulationID IN (6,7,8) OR CountryID=219 (Tuvalu mapped to US); else 'No' | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 17 | Age | (computed) | — | DATEDIFF(YEAR, Dim_Customer.BirthDate, GETDATE()) at INSERT time; integer years | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 18 | BirthDate | DWH_dbo.Dim_Customer | BirthDate | CAST(BirthDate AS DATE); ultimate source Customer.CustomerStatic | Tier 1 — Customer.CustomerStatic |
| 19 | RiskStatus | DWH_dbo.Dim_RiskStatus | Name | JOIN on Dim_Customer.RiskStatusID = Dim_RiskStatus.RiskStatusID | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 20 | ScreeningStatus | DWH_dbo.Dim_ScreeningStatus | Name | JOIN on Dim_Customer.ScreeningStatusID (DWH internal screening status label) | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 21 | ScreeningStatusID | DWH_dbo.Dim_Customer | ScreeningStatusID | Passthrough via #dim; updated from ScreeningService in SP_Dim_Customer | Tier 2 — SP_Dim_Customer |
| 22 | RiskClassificationName | DWH_dbo.Dim_RiskClassification | RiskClassificationName | JOIN on Dim_Customer.RiskClassificationID | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 23 | ProviderUserIDNormalized | EXW_dbo.EXW_AMLProviderID | ProviderUserIDNormalized | LEFT JOIN on GCID; base64-encoded GCID with trailing '=' stripped | Tier 2 — SP_EXW_AMLProviderID |
| 24 | ProviderUserID | EXW_dbo.EXW_AMLProviderID | ProviderUserID | LEFT JOIN on GCID; raw base64-encoded GCID string | Tier 2 — SP_EXW_AMLProviderID |
| 25 | AMLProviderID | EXW_dbo.EXW_AMLProviderID | AMLProviderID | LEFT JOIN on GCID; NULL if user not in EXW_AMLProviderID (493,445 users have NULL) | Tier 2 — SP_EXW_AMLProviderID |
| 26 | IsRealUser | (computed) | — | CASE: 'TestUser' if EXW_DimUser.IsTestAccount=1; 'eTorian' if IsValidCustomer=0; else 'RealUser' | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 27 | UserWalletAllowance | EXW_dbo.EXW_UserSettingsWalletAllowance | UserWalletAllowance | LEFT JOIN on GCID; Allowed/ReadOnly/NotAllowed resolved allowance string | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 28 | AccountStatus | DWH_dbo.Dim_AccountStatus | AccountStatusName | JOIN on Dim_Customer.AccountStatusID | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 29 | AccountType | DWH_dbo.Dim_AccountType | Name | JOIN on Dim_Customer.AccountTypeID | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 30 | Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on Dim_Customer.PlayerLevelID; values Bronze/Silver/Gold/Platinum/Diamond | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 31 | FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough via #dim; updated from FTD recovery logic in SP_Dim_Customer | Tier 2 — SP_Dim_Customer |
| 32 | EvMatchStatus | DWH_dbo.Dim_Customer | EvMatchStatus | Passthrough via #dim; electronic verification match result from BackOffice | Tier 1 — BackOffice.Customer |
| 33 | ClosingProject | EXW_dbo.EXW_UserSettingsWalletAllowance | Project | Renamed from Project; closure project letter from EXW_CompensationClosingCountries | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 34 | CountryRankID | DWH_dbo.Dim_Country | RiskGroupID | JOIN on Dim_Customer.CountryID; 0=none, 1=No Business Allowed, 2=Open For Existing, 3=High Risk EDD | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 35 | AMLComment | BI_DB_dbo.External_etoro_BackOffice_Customer | AMLComment | JOIN on RealCID=CID; BackOffice free-text AML flag note; NULL when no comment | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 36 | RiskComment | BI_DB_dbo.External_etoro_BackOffice_Customer | RiskComment | JOIN on RealCID=CID; BackOffice free-text risk note; NULL when no comment | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 37 | CountryRankDescription | (computed) | — | CASE on CountryRankID: 0=Open, 1=No Business Allowed, 2=Open For Existing Customers, 3=High Risk clients flow-EDD, else=NA | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 38 | Occupation | BI_DB_dbo.BI_DB_KYC_Panel | Q18_AnswerText | JOIN on RealCID; KYC Question 18 (occupation) free-text answer; NULL if unanswered | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 39 | HasCryptoTransfer | EXW_dbo.EXW_FactTransactions | IsRedeem | 1 if GCID has a completed (TranStatusID=2) outbound crypto redeem transaction (IsRedeem=1) excluding types 10 and 13; 0 otherwise | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 40 | HasPayments | EXW_dbo.EXW_FactTransactions | IsPayment | 1 if GCID has any completed payment transaction (IsPayment=1, TranStatusID=2); 0 otherwise | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 41 | HasRiskCountryLogins | DWH_dbo.Fact_CustomerAction | CountryIDByIP | 1 if RealCID has a login action (ActionTypeID=14) from a high-risk country (Dim_Country.IsHighRiskCountry=1) in the last 60 days; 0 otherwise | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 42 | IsAMLProblematic | (computed) | — | 1 if any of 7 conditions met: PlayerStatusID NOT IN (5,1,12); CountryRankID≠0; ScreeningStatusID NOT IN (0,1); RiskScoreName NOT IN (Low, Medium); RiskClassificationID NOT IN (1,2); UserWalletAllowance≠Allowed; Age≤25 or Age≥65 | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 43 | RelatedCIDs | (computed) | — | Concatenated GCID list of users sharing the same biometric key (FirstName+LastName+BirthDate+Gender+Zip+CountryID); NULL if no matches; flags potential linked/duplicate accounts | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 44 | UpdateDate | (computed) | — | GETDATE() at INSERT; all rows share the same UpdateDate per daily run | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 45 | RiskScore | BI_DB_dbo.BI_DB_RiskClassification | RiskScore | JOIN on RealCID; automated AML risk score integer; NULL if not scored | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 46 | RiskScore_Explanation | BI_DB_dbo.BI_DB_RiskClassification | RiskScore_Explanation | JOIN on RealCID; free-text explanation of the AML risk score | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 47 | RiskScoreName | BI_DB_dbo.BI_DB_RiskClassification | RiskScoreName | JOIN on RealCID; Low/Medium/High label for the risk score; NULL if not scored | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 48 | FirstTxDate | EXW_dbo.EXW_FactTransactions | TranDate | MIN(TranDate) per GCID for completed (TranStatusID=2) transactions from the designated sender address, excluding TransactionTypeID IN (10,13) | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 49 | LastTxDate | EXW_dbo.EXW_FactTransactions | TranDate | MAX(TranDate) per GCID; same filter as FirstTxDate | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 50 | ScreeningStatusID_Ext | BI_DB_dbo.External_ScreeningService_Screening_UserScreening | ScreeningStatusID | External screening service status ID for GCID (separate from DWH ScreeningStatusID) | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 51 | ScreeningStatusExt | DWH_dbo.Dim_ScreeningStatus | Name | JOIN on ScreeningStatusID_Ext; human-readable label from external screening service result | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 52 | ScreeningBeginTime_Ext | BI_DB_dbo.External_ScreeningService_Screening_UserScreening | BeginTime | Timestamp when the external screening session began | Tier 2 — SP_EXW_UserSettingsWalletAllowance |
| 53 | WalletBalanceUSD | EXW_dbo.EXW_DimUser_Enriched | TotalBalanceUSD | Passthrough of TotalBalanceUSD (SUM BalanceUSD at max BalanceDateID from EXW_FinanceReportsBalancesNew) | Tier 2 — SP_EXW_DimUser_Enriched |

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 8 | GCID, RealCID, VerificationLevelID, PlayerStatusID, CountryID, BirthDate, EvMatchStatus, RiskClassificationID |
| Tier 2 | 45 | All remaining 45 columns |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

**PHASE 10B CHECKPOINT: PASS**
