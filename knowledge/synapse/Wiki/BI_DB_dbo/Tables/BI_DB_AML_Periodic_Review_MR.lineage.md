# BI_DB_dbo.BI_DB_AML_Periodic_Review_MR — Lineage

**Generated**: 2026-04-22  
**Writer SP**: SP_AML_Periodic_Review  
**Load Pattern**: TRUNCATE + INSERT daily  

---

## Source Objects

| Object | Schema | Type | Role |
|---|---|---|---|
| Dim_Customer | DWH_dbo | Dimension | Base population; CID, GCID, Age, FTD, regulation, country, HasWallet, IsEDD, POI/POA expiry |
| Dim_Regulation | DWH_dbo | Dimension | Regulation name (via Dim_Customer.RegulationID) |
| Dim_Country | DWH_dbo | Dimension | Country/POB name + RiskGroupID (CountryRank) |
| Dim_PlayerStatus | DWH_dbo | Dimension | PlayerStatus name; excludes status IDs 2 (Blocked) and 4 (Blocked Upon Request) |
| Dim_PlayerLevel | DWH_dbo | Dimension | Club/loyalty tier name |
| Dim_EvMatchStatus | DWH_dbo | Dimension | Electronic verification match status name |
| Dim_ScreeningStatus | DWH_dbo | Dimension | Screening status name; drives IsHighRisk_Screening flag |
| Fact_CustomerAction | DWH_dbo | Fact | Deposits ActionTypeID=7 (MOP check, 2023+), cashouts ActionTypeID=8 (Total_Withdraw), logins ActionTypeID=14 (Login_Rank1_2023) |
| Dim_FundingType | DWH_dbo | Dimension | MOP name for high-risk deposit method classification |
| eMoney_Dim_Account | eMoney_dbo | Dimension | AccountProgram (LEFT JOIN via CID) |
| External_RiskClassification_dbo_V_RiskClassificationDataLake | BI_DB_dbo | External | RiskScoreName, RiskScore_Explanation — external risk classification engine output |
| External_Fivetran_google_sheets_grc_list | BI_DB_dbo | External | aml_compliance flag and country risk data (Google Sheets via Fivetran) |
| External_UserApiDB_Ev_CustomerResult | BI_DB_dbo | External | EV status ID and latest EV transaction date (latest by TransactionDate per GCID) |
| External_etoro_BackOffice_CustomerDocument | BI_DB_dbo | External | Selfie documents (Has_Selfie), Proof of Income documents (Has_Proof_Of_Income, Has_Proof_Of_Income_FromLastYear) |
| External_etoro_BackOffice_CustomerDocumentToDocumentType | BI_DB_dbo | External | Document → document type mapping |
| External_etoro_Dictionary_DocumentType | BI_DB_dbo | External | Document type name lookup |
| External_etoro_Dictionary_DocumentRejectReason | BI_DB_dbo | External | Document reject reason filter (rejected documents excluded) |
| BI_DB_KYC_Panel | BI_DB_dbo | Table | Q14 planned investment, Q18 occupation (Occupation_Answer, Is_HighRisk_Occupation), Q26 SOF (SOF_Q26_Answer, Is_High_Risk_SOF) |
| BI_DB_AML_KYC_SOF | BI_DB_dbo | Table | SOF prediction: Is_SOF_needed, ReasonType, HasBusinessPotential, HasSOFLast6Months |
| BI_DB_SF_Cases_Panel | BI_DB_dbo | Table | Has_Open_AML_SF_Case (open AML tickets not Closed/Solved) |
| SolarisBankIdentDb_SolarisBankIdent | general | External | Bank identity verification; contributes to Has_Passed_VI_or_BI (GlobalStatus='successful') |
| VideoIdentDb_VideoIdent | general | External | Video identity verification; contributes to Has_Passed_VI_or_BI (Status='Success') |

---

## Writer

| SP | Author | Date | Load Pattern |
|---|---|---|---|
| SP_AML_Periodic_Review | Eyal Boas | 2025-04-27 | TRUNCATE TABLE + INSERT from #final_pop4 |

---

## Downstream Consumers

None identified in the SSDT repository. This table is an AML compliance operational feed consumed directly by the AML team.

---

## Sibling Tables (same SP, same run)

| Table | Subset Definition |
|---|---|
| BI_DB_AML_Periodic_Review_AR | All-risk population (no RiskScoreName or FTD filter beyond base #pop) |
| BI_DB_AML_Periodic_Review_HR | High Risk, PlayerStatus IN (Normal/Warning), FTD <= 1 year ago |
| BI_DB_AML_Periodic_Review_MR | **This table** — High Risk, PlayerStatus IN (Normal/Warning), FTD <= 3 years ago (subset of HR) |

---

## ETL Data Flow

```
[Risk Score Engine]
External_RiskClassification_dbo_V_RiskClassificationDataLake
  → #risk_score (CID, RiskScoreName, RiskScore_Explanation)

[AML Country Reference]
External_Fivetran_google_sheets_grc_list
  → #fivetran (country_id, aml_compliance, hrc, risk_group)

[EV Date]
External_UserApiDB_Ev_CustomerResult
  ROW_NUMBER() OVER (PARTITION BY GCID ORDER BY TransactionDate DESC) = 1
  → #evdate (latest EV per GCID)

[Base Population]
DWH_dbo.Dim_Customer (IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3)
  JOIN Dim_Regulation (via RegulationID)
  JOIN Dim_Country dc1 (via CountryID) → Country, CountryRank
  JOIN Dim_PlayerStatus (PlayerStatusID NOT IN 2,4)
  JOIN Dim_PlayerLevel (via PlayerLevelID) → Club
  LEFT JOIN Dim_EvMatchStatus (via EvMatchStatus) → EvMatchStatusName
  LEFT JOIN Dim_ScreeningStatus (via ScreeningStatusID) → ScreeningStatus, IsHighRisk_Screening
  LEFT JOIN #risk_score (via CID) → RiskScoreName, RiskScore_Explanation
  LEFT JOIN #fivetran (via CountryID) → aml_compliance
  LEFT JOIN #fivetran (via POBCountryID) → aml_compliance_POB
  LEFT JOIN eMoney_Dim_Account (via CID) → AccountProgram
  LEFT JOIN Dim_Country dc2 (via POBCountryID) → POB_Country
  LEFT JOIN #evdate (via GCID) → EvStatusId, EV_Date
  → #pop (base: all valid, deposited, VerificationLevel=3 customers)

CREATE CLUSTERED INDEX #pop ON #pop (CID)

[MR Subset Filter]
#pop WHERE RiskScoreName='High'
       AND PlayerStatus IN ('Normal','Warning')
       AND CAST(Original_FTD AS DATE) <= @3YearsAgo_Date   ← 3-year FTD cutoff
  → #pop3 (MR-eligible CIDs)

[Document / Compliance Enrichment Temp Tables]
DWH_dbo.Dim_Customer JOIN #pop → #poi (POI_ExpiryDate, POA_ExpiryDate, Is_POI_ExpiryDate, Is_POA_ExpiryDate)
BI_DB_KYC_Panel (Q26) JOIN #pop → #Q26_SOF (Is_High_Risk_SOF, SOF_Q26_Answer)
Fact_CustomerAction (ActionTypeID=7, 2023+, non-standard FundingTypeID) → #mop (high-risk MOP deposits)
BackOffice_CustomerDocument (Selfie/SelfieLiveliness, not rejected) → #Selfie → #selfie_final (latest per CID)
Dim_Customer + SolarisBankIdentDb_SolarisBankIdent → #bankIdent → #bankIdent2 (Is_Pass_BankIdent)
Dim_Customer + VideoIdentDb_VideoIdent → #videoident → #videoident2 (Is_Pass_VideoIdent)
BI_DB_KYC_Panel (Q18) JOIN #pop → #Occupation (Occupation_Answer, Is_HighRisk_Occupation)
BackOffice_CustomerDocument (Proof of Income, not rejected) → #income → #ProofOfIncome (latest per CID)
BI_DB_SF_Cases_Panel (AML, not Closed/Solved) → #amlSF (open AML SF cases)
BI_DB_KYC_Panel (Q14) JOIN #pop → #Planned_Invested_Amount
Fact_CustomerAction (ActionTypeID=8, cashout) → #totalco (Total_Withdraw per CID)
Fact_CustomerAction (ActionTypeID=14, login, CountryIDByIP=1, 2023+) → #login
BI_DB_AML_KYC_SOF JOIN #pop → #sofredflag (Is_SOF_needed, ReasonType, HasBusinessPotential, HasSOFLast6Months)

[MR Intermediate Assembly]
#pop JOIN #pop3              ← MR filter
LEFT JOIN #poi               → POI_ExpiryDate, POA_ExpiryDate, Is_POI_ExpiryDate, Is_POA_ExpiryDate
LEFT JOIN #Q26_SOF           → Is_High_Risk_SOF, SOF_Q26_Answer
LEFT JOIN #mop               → Is_High_MOP_Deposit
  → #final_pop_mr

#final_pop_mr
LEFT JOIN #selfie_final      → Has_Selfie
LEFT JOIN #videoident2       → contributes to Has_Passed_VI_or_BI
LEFT JOIN #bankIdent2        → contributes to Has_Passed_VI_or_BI
LEFT JOIN #Occupation        → Occupation_Answer, Is_HighRisk_Occupation
LEFT JOIN #ProofOfIncome     → Has_Proof_Of_Income, Has_Proof_Of_Income_FromLastYear (>= @YearAgo_Date)
LEFT JOIN #sofredflag        → ReasonType, HasBusinessPotential, HasSOFLast6Months, Is_SOF_needed
LEFT JOIN #login             → Login_Rank1_2023
LEFT JOIN #totalco           → Total_Withdraw
LEFT JOIN #amlSF             → Has_Open_AML_SF_Case
LEFT JOIN #Planned_Invested  → Planned_Invested_Amount_Q14
  → #final_MR

[Final Decision]
#final_MR + CASE logic:
  Orange: Is_POI_ExpiryDate=1 OR Is_POA_ExpiryDate=1
  Red:    IsHighRisk_Screening=1
          OR (Is_High_Risk_SOF=1 AND Has_Proof_Of_Income_FromLastYear=0)
          OR Is_High_MOP_Deposit=1
  Green:  else
  → #final_pop4

TRUNCATE BI_DB_dbo.BI_DB_AML_Periodic_Review_MR
INSERT INTO BI_DB_dbo.BI_DB_AML_Periodic_Review_MR FROM #final_pop4
```
