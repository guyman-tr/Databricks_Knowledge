# Column Lineage — eMoney_dbo.eMoney_Customer_Risk_Assessment

**Generated**: 2026-04-21 | **Writer SP**: SP_eMoney_Customer_Risk_Assessment (1730 lines, 32 steps)
**ETL Pattern**: Daily TRUNCATE TABLE + INSERT; runs after Group One pipeline
**Distribution**: HASH(CID) | **Index**: HEAP

---

## Source Objects

| Source Object | Role | Schema |
|---------------|------|--------|
| `eMoney_dbo.eMoney_Dim_Account` | eTM account identity (GCID_Unique_Count=1 only) | eMoney_dbo |
| `eMoney_dbo.eMoney_Panel_FirstDates` | FMI/FMO dates for eTM account | eMoney_dbo |
| `eMoney_dbo.eMoney_Dim_Transaction` | IBAN MIMO settlement transactions (TxTypeID 5,7,8) | eMoney_dbo |
| `DWH_dbo.Dim_Customer` | Trading platform customer profile (RealCID, GCID, compliance, dates) | DWH_dbo |
| `DWH_dbo.Dim_AccountType` | AccountType name lookup | DWH_dbo |
| `DWH_dbo.Dim_Regulation` | Regulation name lookup | DWH_dbo |
| `DWH_dbo.Dim_PlayerLevel` | Club/PlayerLevel name lookup | DWH_dbo |
| `DWH_dbo.Dim_AccountStatus` | AccountStatus name lookup | DWH_dbo |
| `DWH_dbo.Dim_PlayerStatus` | PlayerStatus name lookup | DWH_dbo |
| `DWH_dbo.Dim_PlayerStatusReasons` | PlayerStatusReason name lookup | DWH_dbo |
| `DWH_dbo.Dim_PlayerStatusSubReasons` | PlayerStatusSubReason name lookup | DWH_dbo |
| `DWH_dbo.Dim_ScreeningStatus` | ScreeningStatus name lookup | DWH_dbo |
| `DWH_dbo.Dim_EvMatchStatus` | EVStatus name lookup | DWH_dbo |
| `DWH_dbo.Dim_DocumentStatus` | DocumentStatus name lookup | DWH_dbo |
| `DWH_dbo.Dim_PhoneVerified` | PhoneStatus name lookup | DWH_dbo |
| `DWH_dbo.Fact_CustomerAction` | TP deposit/cashout amounts (ActionTypeID 7,8; FundingTypeID<>33) | DWH_dbo |
| `DWH_dbo.STS_User_Operations_Data_History` | VPN/TOR login detection | DWH_dbo |
| `DWH_dbo.Dim_Country` | Country name resolution for address/citizenship/POB/TIN | DWH_dbo |
| `eMoney_dbo.eMoney_Country_Codes_Mapping_ISO` | ISO numeric → DWH CountryID bridge | eMoney_dbo |
| `eMoney_dbo.eMoney_Customer_Risk_Assessment_History` | Previous risk classification lookup (Step 27) | eMoney_dbo |
| `BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data` | KYC answers (Q10,Q11,Q14,Q15,Q18,Q26) | BI_DB_dbo |
| `BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField` | TIN country data (FieldId=6) | BI_DB_dbo |
| `BI_DB_dbo.External_Fivetran_google_sheets_emoney_customer_risk_assessment_classification_table` | Risk classification weights (Fivetran → Google Sheets) | BI_DB_dbo |
| `BI_DB_dbo.External_Fivetran_google_sheets_eMoney_Customer_Risk_Assessment_Manual_Override_Table` | Manual risk override entries | BI_DB_dbo |
| `BI_DB_dbo.External_Fivetran_google_sheet_cracountryriskmapping` | Country HRC mapping (Google Sheets) | BI_DB_dbo |
| `BI_DB_dbo.External_etoro_BackOffice_CustomerDocument` | Selfie and source-of-income document records | BI_DB_dbo |
| `BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType` | Document type/status resolution | BI_DB_dbo |
| `BI_DB_dbo.External_etoro_Dictionary_DocumentType` | Document type dictionary | BI_DB_dbo |
| `BI_DB_dbo.External_etoro_Dictionary_DocumentRejectReason` | Reject reason dictionary | BI_DB_dbo |

---

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Rename only (Step 4: `dc.RealCID AS 'CID'`) | Tier 1 |
| 2 | GCID | DWH_dbo.Dim_Customer | GCID | Direct passthrough | Tier 1 |
| 3 | ClientRiskDate | ETL-computed | — | Same as PreviousClientRiskDate if risk unchanged, else GETDATE(); updated by Step 29 overrides | Tier 2 |
| 4 | ClientRisk | ETL-computed | — | Low/Medium/High based on @RiskLowerCut/@RiskUpperCut thresholds; overridden by Manual/PEP in Step 29 | Tier 2 |
| 5 | ClientRiskAssignmentType | ETL-computed | — | 'Regular' (default); 'Manual Override' (Google Sheets list); 'PEP Override' (ScreeningStatus='PEP') | Tier 2 |
| 6 | Risk_Final_Result | ETL-computed | — | Sum of (P_RiskID × P_Weight) for all 32 parameters; NULL when classification table has no match for any required parameter | Tier 2 |
| 7 | PreviousClientRisk | eMoney_Customer_Risk_Assessment_History | ClientRisk | Latest row per CID (Step 27: ROW_NUMBER PARTITION BY CID ORDER BY ClientRiskDate DESC) | Tier 2 |
| 8 | PreviousClientRiskDate | eMoney_Customer_Risk_Assessment_History | ClientRiskDate | Latest row per CID (same Step 27 window) | Tier 2 |
| 9 | VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Direct passthrough | Tier 1 |
| 10 | IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer | Direct passthrough (DWH-computed flag in Dim_Customer) | Tier 2 |
| 11 | IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | Direct passthrough (DWH-computed flag in Dim_Customer) | Tier 2 |
| 12 | AccountType | DWH_dbo.Dim_AccountType | Name | Name lookup via AccountTypeID | Tier 2 |
| 13 | Regulation | DWH_dbo.Dim_Regulation | Name | Name lookup via RegulationID | Tier 2 |
| 14 | Club | DWH_dbo.Dim_PlayerLevel | Name | Name lookup via PlayerLevelID | Tier 2 |
| 15 | ClientAge | ETL-computed | — | DATEDIFF(YEAR, BirthDate, today); 99999 if NULL, >120, or <=0 | Tier 2 |
| 16 | DateOfBirth | DWH_dbo.Dim_Customer | BirthDate | CAST to DATE (strip time) | Tier 1 |
| 17 | DateOfReg | DWH_dbo.Dim_Customer | RegisteredReal | CAST to DATE (strip time) | Tier 1 |
| 18 | DateOfFTD | DWH_dbo.Dim_Customer | FirstDepositDate | CAST to DATE (DWH-computed from FTD data) | Tier 2 |
| 19 | BusinessDuration | ETL-computed | — | Categorical from FTD tenure: 1=<1yr, 2=1-3yr, 3=>3yr, 99999=no deposit or error | Tier 2 |
| 20 | CountryAddress | DWH_dbo.Dim_Country (via #dim_country) | CountryName | Name lookup via CountryID (from Dim_Customer.CountryID) | Tier 2 |
| 21 | CountryCitizenship | DWH_dbo.Dim_Country (via #dim_country) | CountryName | Name lookup via CitizenshipCountryID | Tier 2 |
| 22 | CountryPOB | DWH_dbo.Dim_Country (via #dim_country) | CountryName | Name lookup via POBCountryID | Tier 2 |
| 23 | CountryTIN | ETL-computed (Steps 10-11) | — | TIN country resolved via BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField FieldId=6; COALESCE priority: matching-address > HRC-different > non-HRC-different | Tier 2 |
| 24 | CountryAddress_IsHRC | ETL-computed (#dim_country) | — | 0=not high risk, 1=high risk per Fivetran Google Sheets country risk mapping; ISNULL→99999 | Tier 2 |
| 25 | CountryCitizenship_IsHRC | ETL-computed (#dim_country) | — | Same HRC logic applied to CitizenshipCountryID | Tier 2 |
| 26 | CountryPOB_IsHRC | ETL-computed (#dim_country) | — | Same HRC logic applied to POBCountryID | Tier 2 |
| 27 | CountryTIN_IsHRC | ETL-computed (Step 12) | — | HRC flag for resolved TIN country | Tier 2 |
| 28 | AccountStatus | DWH_dbo.Dim_AccountStatus | AccountStatusName | Name lookup via AccountStatusID | Tier 2 |
| 29 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Name lookup via PlayerStatusID | Tier 2 |
| 30 | PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | Name lookup via PlayerStatusReasonID | Tier 2 |
| 31 | PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Name lookup via PlayerStatusSubReasonID | Tier 2 |
| 32 | ScreeningStatus | DWH_dbo.Dim_ScreeningStatus | Name | Name lookup via ScreeningStatusID; ISNULL→99999 before lookup | Tier 2 |
| 33 | EVStatus | DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | Name lookup via EvMatchStatus; ISNULL→99999 before lookup | Tier 2 |
| 34 | DocumentStatus | DWH_dbo.Dim_DocumentStatus | DocumentStatusName | Name lookup via DocumentStatusID | Tier 2 |
| 35 | PhoneStatus | DWH_dbo.Dim_PhoneVerified | PhoneVerifiedName | Name lookup via PhoneVerifiedID | Tier 2 |
| 36 | DocsOK | DWH_dbo.Dim_Customer | DocsOK | Direct passthrough | Tier 2 |
| 37 | IsIDProof | DWH_dbo.Dim_Customer | IsIDProof | ISNULL(dc.IsIDProof, 99999) | Tier 2 |
| 38 | IsAddressProof | DWH_dbo.Dim_Customer | IsAddressProof | ISNULL(dc.IsAddressProof, 99999) | Tier 2 |
| 39 | IsPhoneVerified | DWH_dbo.Dim_Customer | IsPhoneVerified | Direct passthrough | Tier 2 |
| 40 | IsValidETM | eMoney_dbo.eMoney_Dim_Account | IsValidETM | Direct passthrough (NULL when GCID_Unique_Count>1 or Panel_FirstDates INNER JOIN excludes) | Tier 2 |
| 41 | eTM_CurrencyBalanceID | eMoney_dbo.eMoney_Dim_Account | CurrencyBalanceID | Direct passthrough | Tier 2 |
| 42 | eTM_CurrencyBalanceCreateDate | eMoney_dbo.eMoney_Dim_Account | CurrencyBalanceCreateDate | Direct passthrough | Tier 2 |
| 43 | eTM_CurrencyBalanceStatus | eMoney_dbo.eMoney_Dim_Account | CurrencyBalanceStatus | Direct passthrough | Tier 2 |
| 44 | eTM_AccountID | eMoney_dbo.eMoney_Dim_Account | AccountID | Direct passthrough | Tier 2 |
| 45 | eTM_AccountCreateDate | eMoney_dbo.eMoney_Dim_Account | AccountCreateDate | Direct passthrough | Tier 2 |
| 46 | eTM_AccountStatus | eMoney_dbo.eMoney_Dim_Account | AccountStatus | Direct passthrough (name-resolved in Dim_Account) | Tier 2 |
| 47 | eTM_AccountProgram | eMoney_dbo.eMoney_Dim_Account | AccountProgram | Direct passthrough (name-resolved in Dim_Account) | Tier 2 |
| 48 | eTM_AccountSubProgram | eMoney_dbo.eMoney_Dim_Account | AccountSubProgram | Direct passthrough (name-resolved in Dim_Account) | Tier 2 |
| 49 | eTM_HasCard | eMoney_dbo.eMoney_Dim_Account | HasCard | Direct passthrough | Tier 2 |
| 50 | eTM_CardStatus | eMoney_dbo.eMoney_Dim_Account | CardStatus | Direct passthrough (name-resolved in Dim_Account) | Tier 2 |
| 51 | eTM_ProviderHolderID | eMoney_dbo.eMoney_Dim_Account | ProviderHolderID | Direct passthrough | Tier 2 |
| 52 | eTM_FMI_Date | eMoney_dbo.eMoney_Panel_FirstDates | FMI_Date | Direct passthrough | Tier 2 |
| 53 | eTM_FMI_Source | eMoney_dbo.eMoney_Panel_FirstDates | FMI_Source | Direct passthrough | Tier 2 |
| 54 | eTM_FMO_Date | eMoney_dbo.eMoney_Panel_FirstDates | FMO_Date | Direct passthrough | Tier 2 |
| 55 | eTM_FMO_Target | eMoney_dbo.eMoney_Panel_FirstDates | FMO_Target | Direct passthrough | Tier 2 |
| 56 | P1_Response | Fivetran risk classification table | ResponseDescription | ParameterID=1 (Client Age): matched on ClientAge value vs ResponseID | Tier 2 |
| 57 | P1_Risk | Fivetran risk classification table | RiskText | Risk level text for P1 response | Tier 2 |
| 58 | P2_Response | Fivetran risk classification table | ResponseDescription | ParameterID=2 (Address Country HRC) | Tier 2 |
| 59 | P2_Risk | Fivetran risk classification table | RiskText | Risk text for P2 | Tier 2 |
| 60 | P3_Response | Fivetran risk classification table | ResponseDescription | ParameterID=3 (Citizenship Country HRC) | Tier 2 |
| 61 | P3_Risk | Fivetran risk classification table | RiskText | Risk text for P3 | Tier 2 |
| 62 | P4_Response | Fivetran risk classification table | ResponseDescription | ParameterID=4 (POB Country HRC) | Tier 2 |
| 63 | P4_Risk | Fivetran risk classification table | RiskText | Risk text for P4 | Tier 2 |
| 64 | P5_Response | Fivetran risk classification table | ResponseDescription | ParameterID=5 (KYC Q10 Annual Income) | Tier 2 |
| 65 | P5_Risk | Fivetran risk classification table | RiskText | Risk text for P5 | Tier 2 |
| 66 | P6_Response | Fivetran risk classification table | ResponseDescription | ParameterID=6 (KYC Q11 Total Assets) | Tier 2 |
| 67 | P6_Risk | Fivetran risk classification table | RiskText | Risk text for P6 | Tier 2 |
| 68 | P7_Response | Fivetran risk classification table | ResponseDescription | ParameterID=7 (KYC Q14 Investment Amount) | Tier 2 |
| 69 | P7_Risk | Fivetran risk classification table | RiskText | Risk text for P7 | Tier 2 |
| 70 | P8_Response | Fivetran risk classification table | ResponseDescription | ParameterID=8 (KYC Q15 Main Source of Income) | Tier 2 |
| 71 | P8_Risk | Fivetran risk classification table | RiskText | Risk text for P8 | Tier 2 |
| 72 | P9_Response | Fivetran risk classification table | ResponseDescription | ParameterID=9 (KYC Q18 Occupation Category) | Tier 2 |
| 73 | P9_Risk | Fivetran risk classification table | RiskText | Risk text for P9 | Tier 2 |
| 74 | P10_Response | ETL-hardcoded NULL | — | ParameterID=10 (Citizenship By Investment) CANCELLED; always NULL | Tier 2 |
| 75 | P10_Risk | ETL-hardcoded NULL | — | CANCELLED; always NULL; weight=0 | Tier 2 |
| 76 | P11_Response | Fivetran risk classification table | ResponseDescription | ParameterID=11 (Business Duration) | Tier 2 |
| 77 | P11_Risk | Fivetran risk classification table | RiskText | Risk text for P11 | Tier 2 |
| 78 | P12_Response | Fivetran risk classification table | ResponseDescription | ParameterID=12 (Source of Income document): 1=provided, 2=not provided & IBAN<=50K, 3=not provided & IBAN>50K | Tier 2 |
| 79 | P12_Risk | Fivetran risk classification table | RiskText | Risk text for P12 | Tier 2 |
| 80 | P13_Response | Fivetran risk classification table | ResponseDescription | ParameterID=13 (Selfie verification): DocTypes 15 or 18 accepted | Tier 2 |
| 81 | P13_Risk | Fivetran risk classification table | RiskText | Risk text for P13 | Tier 2 |
| 82 | P14_Response | Fivetran risk classification table | ResponseDescription | ParameterID=14 (Screening Status): matched on ScreeningStatusID | Tier 2 |
| 83 | P14_Risk | Fivetran risk classification table | RiskText | Risk text for P14 | Tier 2 |
| 84 | P15_Response | Fivetran risk classification table | ResponseDescription | ParameterID=15 (Electronic Verification): matched on EVStatusID | Tier 2 |
| 85 | P15_Risk | Fivetran risk classification table | RiskText | Risk text for P15 | Tier 2 |
| 86 | P16_Response | Fivetran risk classification table | ResponseDescription | ParameterID=16 (TIN Country HRC) | Tier 2 |
| 87 | P16_Risk | Fivetran risk classification table | RiskText | Risk text for P16 | Tier 2 |
| 88 | P17_Response | Fivetran risk classification table | ResponseDescription | ParameterID=17 (TIN Country matches Address Country): 1=match, 0=mismatch, 99999=no TIN | Tier 2 |
| 89 | P17_Risk | Fivetran risk classification table | RiskText | Risk text for P17 | Tier 2 |
| 90 | P18_Response | Fivetran risk classification table | ResponseDescription | ParameterID=18 (Proof of Identity): matched on IsIDProof | Tier 2 |
| 91 | P18_Risk | Fivetran risk classification table | RiskText | Risk text for P18 | Tier 2 |
| 92 | P19_Response | Fivetran risk classification table | ResponseDescription | ParameterID=19 (Proof of Address): matched on IsAddressProof | Tier 2 |
| 93 | P19_Risk | Fivetran risk classification table | RiskText | Risk text for P19 | Tier 2 |
| 94 | P20_Response | Fivetran risk classification table | ResponseDescription | ParameterID=20 (IBAN Load Multiple Countries): 11=no loads, 22=0 countries, 33=1 country, 44=2-3, 55=4+ | Tier 2 |
| 95 | P20_Risk | Fivetran risk classification table | RiskText | Risk text for P20 | Tier 2 |
| 96 | P21_Response | Fivetran risk classification table | ResponseDescription | ParameterID=21 (IBAN Load Country Matches KYC Country) | Tier 2 |
| 97 | P21_Risk | Fivetran risk classification table | RiskText | Risk text for P21 | Tier 2 |
| 98 | P22_Response | Fivetran risk classification table | ResponseDescription | ParameterID=22 (IBAN Load Country Is HRC) | Tier 2 |
| 99 | P22_Risk | Fivetran risk classification table | RiskText | Risk text for P22 | Tier 2 |
| 100 | P23_Response | Fivetran risk classification table | ResponseDescription | ParameterID=23 (IBAN Unload Multiple Countries) | Tier 2 |
| 101 | P23_Risk | Fivetran risk classification table | RiskText | Risk text for P23 | Tier 2 |
| 102 | P24_Response | Fivetran risk classification table | ResponseDescription | ParameterID=24 (IBAN Unload Country Matches KYC Country) | Tier 2 |
| 103 | P24_Risk | Fivetran risk classification table | RiskText | Risk text for P24 | Tier 2 |
| 104 | P25_Response | Fivetran risk classification table | ResponseDescription | ParameterID=25 (IBAN Unload Country Is HRC) | Tier 2 |
| 105 | P25_Risk | Fivetran risk classification table | RiskText | Risk text for P25 | Tier 2 |
| 106 | P26_Response | Fivetran risk classification table | ResponseDescription | ParameterID=26 (High Net Worth Individual): 11=MoneyIn_IBAN<=500K, 22=MoneyIn_IBAN>500K | Tier 2 |
| 107 | P26_Risk | Fivetran risk classification table | RiskText | Risk text for P26 | Tier 2 |
| 108 | P27_Response | Fivetran risk classification table | ResponseDescription | ParameterID=27 (VPN/TOR Usage): 11=>40% of logins are VPN/TOR, 22=<=40%, 99999=no login history | Tier 2 |
| 109 | P27_Risk | Fivetran risk classification table | RiskText | Risk text for P27 | Tier 2 |
| 110 | P28_Response | Fivetran risk classification table | ResponseDescription | ParameterID=28 (Citizenship = POB Country): 1=same, 0=different | Tier 2 |
| 111 | P28_Risk | Fivetran risk classification table | RiskText | Risk text for P28 | Tier 2 |
| 112 | P29_Response | Fivetran risk classification table | ResponseDescription | ParameterID=29 (Citizenship = KYC Country): 1=same, 0=different | Tier 2 |
| 113 | P29_Risk | Fivetran risk classification table | RiskText | Risk text for P29 | Tier 2 |
| 114 | P30_Response | Fivetran risk classification table | ResponseDescription | ParameterID=30 (KYC Q26 Source of Funds) | Tier 2 |
| 115 | P30_Risk | Fivetran risk classification table | RiskText | Risk text for P30 | Tier 2 |
| 116 | P31_Response | Fivetran risk classification table | ResponseDescription | ParameterID=31 (Declared vs Actual Income Match): from Fact_CustomerAction TP + IBAN vs KYC Q10 declared max | Tier 2 |
| 117 | P31_Risk | Fivetran risk classification table | RiskText | Risk text for P31 | Tier 2 |
| 118 | P32_Response | Fivetran risk classification table | ResponseDescription | ParameterID=32 (Sum Money Into IBAN): 11=<=10K, 22=10K-200K, 33=>200K | Tier 2 |
| 119 | P32_Risk | Fivetran risk classification table | RiskText | Risk text for P32 | Tier 2 |
| 120 | UpdateDate | ETL-computed | — | GETDATE() at INSERT time (Step 31) | Tier 2 |

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 5 | CID, GCID, VerificationLevelID, DateOfBirth, DateOfReg |
| Tier 2 | 115 | All remaining columns (ETL-computed scores, lookups, Fivetran classification, DWH-computed) |

---

## Key Lineage Notes

- **P10 always NULL**: ParameterID=10 (Citizenship by Investment Program) was CANCELLED; P10_Response and P10_Risk are hardcoded NULL/0 in the SP. Weight=0.
- **Risk threshold is dynamic**: @RiskLowerCut and @RiskUpperCut are derived from the Fivetran classification table at runtime (ParameterID=98/99 rows). Thresholds can change without code changes.
- **Step 32 conditional insert**: History receives a new row only if `trg.CID IS NULL OR src.ClientRisk <> trg.ClientRisk` (class-change-only, not score-change). This was reverted from a score-change trigger on 2025-03-12 (too many new rows per day for Tribe system).
- **GCID_Unique_Count=1 filter**: Only primary eTM accounts (one per customer) contribute eTM data. Customers with multiple eTM accounts contribute only the primary account's data.
- **NULL risk score ('Error' class)**: When ALL parameter joins fail (all P_RiskID=NULL), the composite sum is NULL → Risk_Final_Result=NULL → ClientRisk='Error'. 2,043 rows affected as of 2026-04-12.
