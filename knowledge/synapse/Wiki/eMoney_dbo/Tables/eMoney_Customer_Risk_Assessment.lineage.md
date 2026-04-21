# eMoney_dbo.eMoney_Customer_Risk_Assessment — Production Lineage Map

## Source Resolution

| Property | Value |
|----------|-------|
| **Production Database** | eToro Money operational data (eTM); DWH_dbo enrichment; BI_DB_dbo BackOffice/KYC externals |
| **Population Seed** | eMoney_dbo.eMoney_Dim_Account (all CID/GCID pairs with eTM account) |
| **Primary Customer Source** | DWH_dbo.Dim_Customer (joined via RealCID=CID) |
| **Risk Classification Source** | eMoney_dbo.emoney_customer_risk_assessment_classification_table (Fivetran/Google Sheets) |
| **Country HRC Source** | BI_DB_dbo.External_Fivetran_google_sheet_cracountryriskmapping (Fivetran/Google Sheets) |
| **Manual Override Source** | BI_DB_dbo.External_Fivetran_google_sheets_eMoney_Customer_Risk_Assessment_Manual_Override_Table |
| **KYC Source** | BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data (QuestionID 10,11,14,15,18,26) |
| **TIN Source** | BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField (FieldId=6) |
| **Document Source** | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument + CustomerDocumentToDocumentType |
| **IBAN MIMO Source** | eMoney_dbo.eMoney_Dim_Transaction (TxTypeID=5/7/8, IsTxSettled=1) |
| **TP MIMO Source** | DWH_dbo.Fact_CustomerAction (ActionTypeID=7/8, FundingTypeID≠33) |
| **VPN/TOR Source** | DWH_dbo.STS_User_Operations_Data_History (login events) |
| **History Source** | eMoney_dbo.eMoney_Customer_Risk_Assessment_History (previous classification) |
| **ETL SP** | SP_eMoney_Customer_Risk_Assessment (1729 lines, TRUNCATE + INSERT daily) |
| **Upstream Wiki** | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md |
| **UC Target** | _Not_Migrated |

## ETL Pipeline Summary

```
Step 01: #temp — copy of emoney_customer_risk_assessment_classification_table (Fivetran)
         @RiskLowerCut = ParameterWeight * 100 WHERE ParameterID=98 (dynamic Low/Medium threshold)
         @RiskUpperCut = ParameterWeight * 100 WHERE ParameterID=99 (dynamic Medium/High threshold)

Step 02: #risk_classification_table — HASH(ParameterID); all P1-P32 rows (excludes ParameterID 98/99)
         #risk_manual_override_table — HASH(CID); CID-level manual ClientRisk overrides from Google Sheets
         #manual_country_risk_classification — HASH(eToroDWHCountryID); IsHighRiskCountry per country from Google Sheets
         #dim_country — HASH(CountryID); Dim_Country + eMoney_Country_Codes_Mapping_ISO + HRC flags

Step 03: #pop — DISTINCT CID, GCID from eMoney_Dim_Account (all eTM customers)

Step 04: #dim_customer — HASH(GCID); full trading platform customer profile
         Source: Dim_Customer INNER JOIN #pop ON RealCID=CID
         Lookups: Dim_AccountType, Dim_Regulation, Dim_PlayerLevel, #dim_country (×3),
                  Dim_AccountStatus, Dim_PlayerStatus, Dim_PlayerStatusReasons, Dim_PlayerStatusSubReasons,
                  Dim_ScreeningStatus, Dim_EvMatchStatus, Dim_RiskStatus, Dim_DocumentStatus, Dim_PhoneVerified
         Computes: ClientAge (DATEDIFF YEAR; 99999 if >120/≤0/NULL)
                   DateOfBirth = CAST(BirthDate AS DATE)
                   DateOfReg = CAST(RegisteredReal AS DATE)
                   DateOfFTD = CAST(FirstDepositDate AS DATE)
                   BusinessDuration (CASE: 99999 if sentinel/NULL, 1 if <1yr, 2 if 1-3yr, 3 if >3yr)
                   CountryAddress/Citizenship/POB IsHRC = ISNULL(CRA_IsHighRiskCountry, 99999)
                   P28 = Citizenship == POB (0/1/99999)
                   P29 = Citizenship == Address (0/1/99999)
                   ScreeningStatusID/EVStatusID = ISNULL(raw ID, 99999)
                   IsIDProof/IsAddressProof = ISNULL(raw, 99999)

Step 05: #dim_account — HASH(CID); eTM account snapshot for each CID
         Source: eMoney_Dim_Account INNER JOIN #pop (GCID_Unique_Count=1)
                 INNER JOIN eMoney_Panel_FirstDates ON AccountID (FMI/FMO dates)
         Dedup: ROW_NUMBER() PARTITION BY CID ORDER BY CID DESC → RN_Duplicates=1

Step 06: #risk_customer_info — P1/2/3/4/11/28/29 scores
         P1 = ClientAge → ParameterID=1 (Client Age)
         P2 = CountryAddress_IsHRC → ParameterID=2 (Address Country HRC)
         P3 = CountryCitizenship_IsHRC → ParameterID=3 (Citizenship Country HRC)
         P4 = CountryPOB_IsHRC → ParameterID=4 (POB Country HRC)
         P11 = BusinessDuration → ParameterID=11 (Business Duration)
         P28 = CitizenshipCountryID==POBCountryID → ParameterID=28
         P29 = CitizenshipCountryID==CountryID → ParameterID=29

Steps 07-08: KYC Q&A compilation and leveling
         Source: BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data
         Questions: Q10=Annual Income, Q11=Total Assets, Q14=Planned Investment,
                    Q15=Main SoI, Q18=Occupation, Q26=Source of Funds [Q46 CANCELLED]
         Leveled: MAX per GCID, ISNULL(answer, 99999)

Step 09: #risk_kyc — P5/6/7/8/9/10/30 scores
         P5 = Q10_AnswerID → ParameterID=5 (Annual Income)
         P6 = Q11_AnswerID → ParameterID=6 (Total Assets)
         P7 = Q14_AnswerID → ParameterID=7 (Planned Investment)
         P8 = Q15_AnswerID → ParameterID=8 (Main Source of Income)
         P9 = Q18_AnswerID → ParameterID=9 (Occupation Category)
         P10 = ALWAYS NULL (Q46 Citizenship By Investment Program — CANCELLED)
         P30 = Q26_AnswerID → ParameterID=30 (Source of Funds)

Steps 10-11: TIN compilation and leveling
         Source: BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField (FieldId=6, GCID join)
         Priority: matching address country > HRC country > non-HRC country
         Resolves: CountryTIN, CountryTIN_IsHRC, IsKYCCountryMatchingTINCountry

Step 12: #risk_tin — P16/17 scores
         P16 = CountryTIN_IsHRC → ParameterID=16 (TIN Country HRC)
         P17 = IsKYCCountryMatchingTINCountry → ParameterID=17 (TIN = Address Country)

Steps 13-14: BackOffice document compilation (Selfie + Source of Income)
         Source: External_etoro_BackOffice_CustomerDocument + CustomerDocumentToDocumentType
         Filter: SuggestedDocTypeID or Response_DocTypeID IN (7=SOI, 15=Selfie, 18=Selfie) AND RejectReasonID IS NULL
         Selfie: DocType 15 or 18; IsSelfieProvided=1/0
         SOI: DocType 7; IsSourceOfIncomeProvided=1/2/3 (1=provided; 2=absent≤50K; 3=absent>50K IBAN in)

Step 15: #risk_selfie — P13 score
         P13 = IsSelfieProvided → ParameterID=13 (Selfie Verification)

Step 16: #risk_backoffice — P14/15/18/19 scores
         P14 = ScreeningStatusID → ParameterID=14 (Screening Status)
         P15 = EVStatusID → ParameterID=15 (Electronic Verification)
         P18 = IsIDProof → ParameterID=18 (Proof of Identity)
         P19 = IsAddressProof → ParameterID=19 (Proof of Address)

Steps 17-21: IBAN MIMO processing
         Source: eMoney_Dim_Transaction (TxTypeID=5 card_load, 7=IBAN_load, 8=IBAN_unload; IsTxSettled=1)
         Country match: TxLocalCountryNumericISO → ISO_CountryNumericCode → #dim_country
         Aggregates: count/sum per TxTypeID; distinct countries; last country IsHRC; MoneyIn_IBAN = TxTypeID IN (5,7)
         P20 = IBAN load countries count (11/22/33/44/55 codes) → ParameterID=20
         P21 = last IBAN load country == KYC address → ParameterID=21
         P22 = last IBAN load country IsHRC → ParameterID=22
         P23 = IBAN unload countries count → ParameterID=23
         P24 = last IBAN unload country == KYC address → ParameterID=24
         P25 = last IBAN unload country IsHRC → ParameterID=25
         P26 = MoneyIn_IBAN >500000 USD → ParameterID=26 (High Net Worth)
         P32 = MoneyIn_IBAN buckets ≤10K/≤200K/>200K → ParameterID=32

Steps 22-23: Source of income document — P12
         P12 = IsSourceOfIncomeProvided → ParameterID=12

Steps 24-25: TP MIMO (trading platform deposits/cashouts) — P31
         Source: Fact_CustomerAction (ActionTypeID=7=deposit, 8=cashout; FundingTypeID≠33)
         MoneyIn_Total = TP deposits + IBAN loads; vs Q10 declared max income
         P31 = Declared/Actual ratio buckets → ParameterID=31

Step 26: VPN/TOR — P27
         Source: STS_User_Operations_Data_History (LoginTypeName IN (TokenExchange,Login,Authenticate,DeviceAdded,FirstLogin))
         P27 = Count_VPN_TOR_Proxy/Count_Total >0.4 → ParameterID=27

Step 27: #eMoney_Customer_Risk_Assessment_History — latest history row per CID
         Source: eMoney_Customer_Risk_Assessment_History (ROW_NUMBER PARTITION BY CID ORDER BY ClientRiskDate DESC WHERE LastRiskRow=1)

Step 28: #final — assembles all sources; computes final risk classification
         Risk_Final_Result = SUM(P1_RiskID×P1_Weight + P2_RiskID×P2_Weight + … + P32_RiskID×P32_Weight)
         ClientRisk = 'Low' (≤LowerCut) / 'Medium' (>LowerCut ≤UpperCut) / 'High' (≥UpperCut) / 'Error' (else)
         ClientRiskDate = preserved if ClientRisk unchanged, else @Date (today)
         ClientRiskAssignmentType = 'Regular'
         PreviousClientRisk = ISNULL(hst.ClientRisk, 'None')
         PreviousClientRiskDate = hst.ClientRiskDate

Step 29: UPDATE #final — override logic (applied after Regular calculation)
         PEP Override: SET ClientRisk='High', ClientRiskAssignmentType='PEP Override' WHERE ScreeningStatus='PEP'
         Manual Override: SET ClientRisk=override_value, ClientRiskAssignmentType='Manual Override' WHERE CID in override table

Step 30: TRUNCATE TABLE eMoney_Customer_Risk_Assessment
         (Changed 2024-07-22 by EitanLi from DELETE FROM)

Step 31: INSERT INTO eMoney_Customer_Risk_Assessment (all 120 columns) FROM #final + GETDATE() as UpdateDate

Step 32: INSERT INTO eMoney_Customer_Risk_Assessment_History FROM #final
         WHERE trg.CID IS NULL OR (src.ClientRisk <> trg.ClientRisk)
         (Reverted 2025-03-12 from score-change trigger back to class-change trigger)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform |
|---|-----------|-------------|---------------|-----------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Rename: RealCID→CID |
| 2 | GCID | DWH_dbo.Dim_Customer | GCID | Passthrough |
| 3 | ClientRiskDate | eMoney_Customer_Risk_Assessment_History | ClientRiskDate | Preserved if ClientRisk unchanged; else @Date |
| 4 | ClientRisk | Fivetran classification table | RiskText thresholds | CASE on Risk_Final_Result vs @RiskLowerCut/@RiskUpperCut; overridden by PEP/Manual |
| 5 | ClientRiskAssignmentType | Computed | — | 'Regular' (default); 'PEP Override'; 'Manual Override' |
| 6 | Risk_Final_Result | Fivetran classification table | RiskID × ParameterWeight | SUM(P1_RiskID×P1_Weight + … + P32_RiskID×P32_Weight) |
| 7 | PreviousClientRisk | eMoney_Customer_Risk_Assessment_History | ClientRisk | Latest history row (ROW_NUMBER DESC); ISNULL→'None' |
| 8 | PreviousClientRiskDate | eMoney_Customer_Risk_Assessment_History | ClientRiskDate | Latest history row (ROW_NUMBER DESC) |
| 9 | VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough |
| 10 | IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer | Passthrough |
| 11 | IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | Passthrough |
| 12 | AccountType | DWH_dbo.Dim_AccountType | Name | JOIN on AccountTypeID |
| 13 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on RegulationID |
| 14 | Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on PlayerLevelID |
| 15 | ClientAge | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(YEAR, BirthDate, @Date); 99999 if >120/≤0/NULL |
| 16 | DateOfBirth | DWH_dbo.Dim_Customer | BirthDate | CAST(BirthDate AS DATE) — rename from BirthDate |
| 17 | DateOfReg | DWH_dbo.Dim_Customer | RegisteredReal | CAST(RegisteredReal AS DATE) — rename |
| 18 | DateOfFTD | DWH_dbo.Dim_Customer | FirstDepositDate | CAST(FirstDepositDate AS DATE) |
| 19 | BusinessDuration | DWH_dbo.Dim_Customer | FirstDepositDate | CASE: 99999 sentinel/NULL; 1=<1yr; 2=1-3yr; 3=>3yr |
| 20 | CountryAddress | #dim_country | CountryName | JOIN on CountryID (KYC address country) |
| 21 | CountryCitizenship | #dim_country | CountryName | JOIN on CitizenshipCountryID |
| 22 | CountryPOB | #dim_country | CountryName | JOIN on POBCountryID |
| 23 | CountryTIN | #dim_country | CountryName | JOIN via TIN priority resolution (matching/HRC/non-HRC) |
| 24 | CountryAddress_IsHRC | Fivetran country risk map | IsHighRiskCountry | ISNULL(CRA_IsHighRiskCountry, 99999) for address country |
| 25 | CountryCitizenship_IsHRC | Fivetran country risk map | IsHighRiskCountry | ISNULL(CRA_IsHighRiskCountry, 99999) for citizenship country |
| 26 | CountryPOB_IsHRC | Fivetran country risk map | IsHighRiskCountry | ISNULL(CRA_IsHighRiskCountry, 99999) for POB country |
| 27 | CountryTIN_IsHRC | Fivetran country risk map | IsHighRiskCountry | ISNULL(CRA_IsHighRiskCountry, 99999) for TIN country |
| 28 | AccountStatus | DWH_dbo.Dim_AccountStatus | AccountStatusName | JOIN on AccountStatusID |
| 29 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN on PlayerStatusID |
| 30 | PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | JOIN on PlayerStatusReasonID |
| 31 | PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | JOIN on PlayerStatusSubReasonID |
| 32 | ScreeningStatus | DWH_dbo.Dim_ScreeningStatus | Name | JOIN on ScreeningStatusID (ISNULL→99999 before join) |
| 33 | EVStatus | DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | JOIN on EvMatchStatus (ISNULL→99999 before join) |
| 34 | DocumentStatus | DWH_dbo.Dim_DocumentStatus | DocumentStatusName | JOIN on DocumentStatusID |
| 35 | PhoneStatus | DWH_dbo.Dim_PhoneVerified | PhoneVerifiedName | JOIN on PhoneVerifiedID |
| 36 | DocsOK | DWH_dbo.Dim_Customer | DocsOK | Passthrough |
| 37 | IsIDProof | DWH_dbo.Dim_Customer | IsIDProof | ISNULL(IsIDProof, 99999) |
| 38 | IsAddressProof | DWH_dbo.Dim_Customer | IsAddressProof | ISNULL(IsAddressProof, 99999) |
| 39 | IsPhoneVerified | DWH_dbo.Dim_Customer | IsPhoneVerified | Passthrough |
| 40 | IsValidETM | eMoney_dbo.eMoney_Dim_Account | IsValidETM | Passthrough (primary row, RN_Duplicates=1) |
| 41 | eTM_CurrencyBalanceID | eMoney_dbo.eMoney_Dim_Account | CurrencyBalanceID | Passthrough — rename |
| 42 | eTM_CurrencyBalanceCreateDate | eMoney_dbo.eMoney_Dim_Account | CurrencyBalanceCreateDate | Passthrough — rename |
| 43 | eTM_CurrencyBalanceStatus | eMoney_dbo.eMoney_Dim_Account | CurrencyBalanceStatus | Passthrough — rename |
| 44 | eTM_AccountID | eMoney_dbo.eMoney_Dim_Account | AccountID | Passthrough — rename |
| 45 | eTM_AccountCreateDate | eMoney_dbo.eMoney_Dim_Account | AccountCreateDate | Passthrough — rename |
| 46 | eTM_AccountStatus | eMoney_dbo.eMoney_Dim_Account | AccountStatus | Passthrough — rename |
| 47 | eTM_AccountProgram | eMoney_dbo.eMoney_Dim_Account | AccountProgram | Passthrough — rename |
| 48 | eTM_AccountSubProgram | eMoney_dbo.eMoney_Dim_Account | AccountSubProgram | Passthrough — rename |
| 49 | eTM_HasCard | eMoney_dbo.eMoney_Dim_Account | HasCard | Passthrough — rename |
| 50 | eTM_CardStatus | eMoney_dbo.eMoney_Dim_Account | CardStatus | Passthrough — rename |
| 51 | eTM_ProviderHolderID | eMoney_dbo.eMoney_Dim_Account | ProviderHolderID | Passthrough — rename |
| 52 | eTM_FMI_Date | eMoney_dbo.eMoney_Panel_FirstDates | FMI_Date | Passthrough via JOIN on AccountID — rename |
| 53 | eTM_FMI_Source | eMoney_dbo.eMoney_Panel_FirstDates | FMI_Source | Passthrough via JOIN on AccountID — rename |
| 54 | eTM_FMO_Date | eMoney_dbo.eMoney_Panel_FirstDates | FMO_Date | Passthrough via JOIN on AccountID — rename |
| 55 | eTM_FMO_Target | eMoney_dbo.eMoney_Panel_FirstDates | FMO_Target | Passthrough via JOIN on AccountID — rename |
| 56 | P1_Response | Fivetran classification table | ResponseDescription | ParameterID=1 (Client Age); ResponseID=ClientAge |
| 57 | P1_Risk | Fivetran classification table | RiskText | ParameterID=1 |
| 58 | P2_Response | Fivetran classification table | ResponseDescription | ParameterID=2 (Address Country HRC); ResponseID=CountryAddress_IsHRC |
| 59 | P2_Risk | Fivetran classification table | RiskText | ParameterID=2 |
| 60 | P3_Response | Fivetran classification table | ResponseDescription | ParameterID=3 (Citizenship Country HRC); ResponseID=CountryCitizenship_IsHRC |
| 61 | P3_Risk | Fivetran classification table | RiskText | ParameterID=3 |
| 62 | P4_Response | Fivetran classification table | ResponseDescription | ParameterID=4 (POB Country HRC); ResponseID=CountryPOB_IsHRC |
| 63 | P4_Risk | Fivetran classification table | RiskText | ParameterID=4 |
| 64 | P5_Response | Fivetran classification table | ResponseDescription | ParameterID=5 (KYC Q10 Annual Income); ResponseID=Q10_AnswerID |
| 65 | P5_Risk | Fivetran classification table | RiskText | ParameterID=5 |
| 66 | P6_Response | Fivetran classification table | ResponseDescription | ParameterID=6 (KYC Q11 Total Assets); ResponseID=Q11_AnswerID |
| 67 | P6_Risk | Fivetran classification table | RiskText | ParameterID=6 |
| 68 | P7_Response | Fivetran classification table | ResponseDescription | ParameterID=7 (KYC Q14 Planned Investment); ResponseID=Q14_AnswerID |
| 69 | P7_Risk | Fivetran classification table | RiskText | ParameterID=7 |
| 70 | P8_Response | Fivetran classification table | ResponseDescription | ParameterID=8 (KYC Q15 Main Source of Income); ResponseID=Q15_AnswerID |
| 71 | P8_Risk | Fivetran classification table | RiskText | ParameterID=8 |
| 72 | P9_Response | Fivetran classification table | ResponseDescription | ParameterID=9 (KYC Q18 Occupation Category); ResponseID=Q18_AnswerID |
| 73 | P9_Risk | Fivetran classification table | RiskText | ParameterID=9 |
| 74 | P10_Response | CANCELLED | — | Always NULL (KYC Q46 Citizenship By Investment Program cancelled) |
| 75 | P10_Risk | CANCELLED | — | Always NULL |
| 76 | P11_Response | Fivetran classification table | ResponseDescription | ParameterID=11 (Business Duration); ResponseID=BusinessDuration |
| 77 | P11_Risk | Fivetran classification table | RiskText | ParameterID=11 |
| 78 | P12_Response | Fivetran classification table | ResponseDescription | ParameterID=12 (Source of Income doc); ResponseID=IsSourceOfIncomeProvided |
| 79 | P12_Risk | Fivetran classification table | RiskText | ParameterID=12 |
| 80 | P13_Response | Fivetran classification table | ResponseDescription | ParameterID=13 (Selfie doc); ResponseID=IsSelfieProvided |
| 81 | P13_Risk | Fivetran classification table | RiskText | ParameterID=13 |
| 82 | P14_Response | Fivetran classification table | ResponseDescription | ParameterID=14 (Screening Status); ResponseID=ScreeningStatusID |
| 83 | P14_Risk | Fivetran classification table | RiskText | ParameterID=14 |
| 84 | P15_Response | Fivetran classification table | ResponseDescription | ParameterID=15 (Electronic Verification); ResponseID=EVStatusID |
| 85 | P15_Risk | Fivetran classification table | RiskText | ParameterID=15 |
| 86 | P16_Response | Fivetran classification table | ResponseDescription | ParameterID=16 (TIN Country HRC); ResponseID=CountryTIN_IsHRC |
| 87 | P16_Risk | Fivetran classification table | RiskText | ParameterID=16 |
| 88 | P17_Response | Fivetran classification table | ResponseDescription | ParameterID=17 (TIN Country = Address Country); ResponseID=IsKYCCountryMatchingTINCountry |
| 89 | P17_Risk | Fivetran classification table | RiskText | ParameterID=17 |
| 90 | P18_Response | Fivetran classification table | ResponseDescription | ParameterID=18 (Proof of Identity); ResponseID=IsIDProof |
| 91 | P18_Risk | Fivetran classification table | RiskText | ParameterID=18 |
| 92 | P19_Response | Fivetran classification table | ResponseDescription | ParameterID=19 (Proof of Address); ResponseID=IsAddressProof |
| 93 | P19_Risk | Fivetran classification table | RiskText | ParameterID=19 |
| 94 | P20_Response | Fivetran classification table | ResponseDescription | ParameterID=20 (IBAN Load Countries count); ResponseID from IBAN load country count buckets |
| 95 | P20_Risk | Fivetran classification table | RiskText | ParameterID=20 |
| 96 | P21_Response | Fivetran classification table | ResponseDescription | ParameterID=21 (IBAN Load Country = KYC Address); last IBAN load country vs CountryIDAddress |
| 97 | P21_Risk | Fivetran classification table | RiskText | ParameterID=21 |
| 98 | P22_Response | Fivetran classification table | ResponseDescription | ParameterID=22 (IBAN Load Country HRC); last IBAN load country IsHighRiskCountry |
| 99 | P22_Risk | Fivetran classification table | RiskText | ParameterID=22 |
| 100 | P23_Response | Fivetran classification table | ResponseDescription | ParameterID=23 (IBAN Unload Countries count); ResponseID from IBAN unload country count buckets |
| 101 | P23_Risk | Fivetran classification table | RiskText | ParameterID=23 |
| 102 | P24_Response | Fivetran classification table | ResponseDescription | ParameterID=24 (IBAN Unload Country = KYC Address); last IBAN unload country vs CountryIDAddress |
| 103 | P24_Risk | Fivetran classification table | RiskText | ParameterID=24 |
| 104 | P25_Response | Fivetran classification table | ResponseDescription | ParameterID=25 (IBAN Unload Country HRC); last IBAN unload country IsHighRiskCountry |
| 105 | P25_Risk | Fivetran classification table | RiskText | ParameterID=25 |
| 106 | P26_Response | Fivetran classification table | ResponseDescription | ParameterID=26 (High Net Worth Individual); MoneyIn_IBAN > 500000 USD threshold |
| 107 | P26_Risk | Fivetran classification table | RiskText | ParameterID=26 |
| 108 | P27_Response | Fivetran classification table | ResponseDescription | ParameterID=27 (VPN/TOR Usage); VPN+TOR login ratio > 40% = high |
| 109 | P27_Risk | Fivetran classification table | RiskText | ParameterID=27 |
| 110 | P28_Response | Fivetran classification table | ResponseDescription | ParameterID=28 (Citizenship = POB Country); CitizenshipCountryID == POBCountryID |
| 111 | P28_Risk | Fivetran classification table | RiskText | ParameterID=28 |
| 112 | P29_Response | Fivetran classification table | ResponseDescription | ParameterID=29 (Citizenship = Address Country); CitizenshipCountryID == CountryID |
| 113 | P29_Risk | Fivetran classification table | RiskText | ParameterID=29 |
| 114 | P30_Response | Fivetran classification table | ResponseDescription | ParameterID=30 (KYC Q26 Source of Funds); ResponseID=Q26_AnswerID |
| 115 | P30_Risk | Fivetran classification table | RiskText | ParameterID=30 |
| 116 | P31_Response | Fivetran classification table | ResponseDescription | ParameterID=31 (Total Ecosystem vs Declared); MoneyIn_Total vs Q10_MaxDeclaredNumber |
| 117 | P31_Risk | Fivetran classification table | RiskText | ParameterID=31 |
| 118 | P32_Response | Fivetran classification table | ResponseDescription | ParameterID=32 (IBAN Total MoneyIn); MoneyIn_IBAN buckets ≤10K/≤200K/>200K |
| 119 | P32_Risk | Fivetran classification table | RiskText | ParameterID=32 |
| 120 | UpdateDate | Computed | GETDATE() | SP execution timestamp — not a business date |
