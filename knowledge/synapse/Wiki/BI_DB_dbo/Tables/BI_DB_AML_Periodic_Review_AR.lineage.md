# Lineage: BI_DB_dbo.BI_DB_AML_Periodic_Review_AR

**Writer SP**: `BI_DB_dbo.SP_AML_Periodic_Review @Date [DATE]`
**ETL Pattern**: TRUNCATE + INSERT (daily full refresh)
**Source DB**: Synapse sql_dp_prod_we (DWH_dbo + BI_DB_dbo + External schemas)

---

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | `DWH_dbo.Dim_Customer` | Dimension | Base population gate + demographics (CID, GCID, Age, Regulation, Country, POB_Country, PlayerStatus, Club, HasWallet, AccountProgram, IsEDD, POI/POA expiry dates) |
| 2 | `External_RiskClassification_dbo_V_RiskClassificationDataLake` | External View | AML risk score and screening results (RiskScoreName, RiskScore_Explanation, ScreeningStatus, IsHighRisk_Screening, PreviousRisk) |
| 3 | `External_Fivetran_google_sheets_grc_list` | External Table (Fivetran) | AML compliance status per country from GRC Google Sheet (aml_compliance, aml_compliance_POB, CountryRank) |
| 4 | `External_UserApiDB_Ev_CustomerResult` | External Table | Enhanced Verification (EV) result per customer — latest result per GCID via ROW_NUMBER (EvMatchStatusName, EvStatusId, EV_Date) |
| 5 | `BI_DB_dbo.BI_DB_KYC_Panel` | BI_DB Table | Q26 SOF risk (Is_High_Risk_SOF, SOF_Q26_Answer), Q18 Occupation (Occupation_Answer, Is_HighRisk_Occupation), Q14 Planned Investment (Planned_Invested_Amount_Q14) |
| 6 | `BI_DB_dbo.BI_DB_AML_KYC_SOF` | BI_DB Table | SOF status and business potential (ReasonType, HasBusinessPotential, HasSOFLast6Months, Is_SOF_needed) |
| 7 | `BI_DB_dbo.BI_DB_SF_Cases_Panel` | BI_DB Table | Open AML Salesforce cases (Has_Open_AML_SF_Case) |
| 8 | `DWH_dbo.Fact_CustomerAction` (ActionTypeID=8) | Fact Table | Total cashout amount (Total_Withdraw) |
| 9 | `DWH_dbo.Fact_CustomerAction` (ActionTypeID≠std, post-2023) | Fact Table | High-risk payment method detection (Is_High_MOP_Deposit) |
| 10 | `DWH_dbo.Fact_CustomerAction` (login events, CountryIDByIP) | Fact Table | Logins from Rank-1 AML countries after 2023 (Login_Rank1_2023) |
| 11 | `External_etoro_BackOffice_CustomerDocument` | External Table | Proof of Income documents (Has_Proof_Of_Income, Has_Proof_Of_Income_FromLastYear) |
| 12 | `External_etoro_BackOffice_CustomerDocument` | External Table | Selfie/liveness check documents (Has_Selfie) |
| 13 | `SolarisBankIdentDb` | External DB | Bank identification result (part of Has_Passed_VI_or_BI) |
| 14 | `VideoIdentDb` | External DB | Video identification result (part of Has_Passed_VI_or_BI) |

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform |
|---|--------|--------------|---------------|-----------|
| 1 | CID | Dim_Customer | RealCID | Passthrough — platform CID |
| 2 | GCID | Dim_Customer | GCID | Passthrough — group identity key |
| 3 | Age | Dim_Customer | BirthDate | `DATEDIFF(YEAR, BirthDate, GETDATE())` — simple year-diff, may be off by 1 pre-birthday |
| 4 | Age_Group | derived from Age | — | CASE: '18-21 Age' (18-21), 'Over 75' (>75), 'No Risk Age' (all others) |
| 5 | Original_FTD | Dim_Customer | FirstDepositDate | Passthrough — first deposit date |
| 6 | Regulation | Dim_Regulation | Name | Passthrough via Dim_Customer.RegulationID JOIN |
| 7 | Country | Dim_Country | Name | Passthrough — country of residence |
| 8 | POB_Country | Dim_Customer | CountryOfBirth (resolved) | Passthrough — country of birth; empty for many legacy accounts |
| 9 | aml_compliance_POB | External_Fivetran_google_sheets_grc_list | aml_compliance | GRC lookup by POB_Country — AML compliance status of birth country |
| 10 | CountryRank | External_Fivetran_google_sheets_grc_list | country_rank | Country AML risk tier from GRC list; 0=no tier assigned (majority), 1=highest risk (42 rows), 2-4=intermediate tiers |
| 11 | aml_compliance | External_Fivetran_google_sheets_grc_list | aml_compliance | GRC lookup by Country — AML compliance status of residence country |
| 12 | PlayerStatus | Dim_PlayerStatus | Name | Passthrough via Dim_Customer.PlayerStatusID JOIN |
| 13 | Club | Dim_PlayerLevel | Name | Passthrough — customer tier (Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond) |
| 14 | EvMatchStatusName | External_UserApiDB_Ev_CustomerResult | EvMatchStatusName | Latest EV result per GCID via ROW_NUMBER (OccurredAt DESC) |
| 15 | EvStatusId | External_UserApiDB_Ev_CustomerResult | StatusID | Latest EV StatusID per GCID |
| 16 | EV_Date | External_UserApiDB_Ev_CustomerResult | OccurredAt | Timestamp of latest EV event per GCID |
| 17 | ScreeningStatus | External_RiskClassification_dbo_V_RiskClassificationDataLake | ScreeningStatus | Sanctions/PEP/risk screening result — NoMatch (99.5%), PendingInvestigation, PEP, RiskMatch, SanctionsMatch |
| 18 | RiskScoreName | External_RiskClassification_dbo_V_RiskClassificationDataLake | RiskScoreName | AML risk score band — Medium (95.3%), High (3.0%), Low (1.5%) |
| 19 | RiskScore_Explanation | External_RiskClassification_dbo_V_RiskClassificationDataLake | RiskScore_Explanation | Comma-separated list of risk factors driving the score |
| 20 | HasWallet | Dim_Customer | HasWallet | 1 if customer has an active eToroMoney wallet (12.2% of population) |
| 21 | AccountProgram | Dim_Customer | AccountProgram | Payment account program: NULL=standard (62.7%), 'iban'=bank account (35.3%), 'card'=card program (1.9%) |
| 22 | IsHighRisk_Screening | External_RiskClassification | derived | 1 when ScreeningStatus NOT IN ('NoMatch', 'Unknown', NULL) — 0.3% of population |
| 23 | IsEDD | Dim_Customer | IsEDD | 1 if customer is subject to Enhanced Due Diligence (36.8% of population) |
| 24 | POI_ExpiryDate | Dim_Customer | IsIDProofExpiryDate | Expiry datetime of customer's Proof of Identity document; NULL if not set |
| 25 | POA_ExpiryDate | Dim_Customer | IsAddressProofExpiryDate | Expiry datetime of customer's Proof of Address document; NULL if not set |
| 26 | Is_POI_ExpiryDate | derived from POI_ExpiryDate | — | 1 if POI document is expired (POI_ExpiryDate < current date); 12.7% of population |
| 27 | Is_POA_ExpiryDate | derived from POA_ExpiryDate | — | 1 if POA document is expired (POA_ExpiryDate < current date); 23.5% of population |
| 28 | Is_High_Risk_SOF | BI_DB_KYC_Panel | Q26_AnswerText | 1 if Q26_AnswerText IN ('Family financial support', 'Social Security') — high-risk SOF source types |
| 29 | SOF_Q26_Answer | BI_DB_KYC_Panel | Q26_AnswerText | Customer's declared source of funds from Q26 (multi-select, STRING_AGG) |
| 30 | Is_High_MOP_Deposit | Fact_CustomerAction | FundingTypeID | 1 if any deposit after 2023-01-01 used a non-standard/high-risk payment method (FundingTypeID not in standard set) |
| 31 | Occupation_Answer | BI_DB_KYC_Panel | Q18_AnswerText | Customer's Q18 occupation category text |
| 32 | Is_HighRisk_Occupation | derived from Occupation_Answer | — | 1 if Occupation_Answer IN ('None', 'Gambling Industry', 'Gaming/Casino/Card Club', 'Student') |
| 33 | ReasonType | BI_DB_AML_KYC_SOF | ReasonType | SOF reason category — see BI_DB_AML_KYC_SOF wiki for exact stored strings (contains spelling errors) |
| 34 | HasBusinessPotential | BI_DB_AML_KYC_SOF | HasBusinessPotential | 1 if ≥85% of Q14 planned investment ceiling not yet deposited — high growth potential |
| 35 | HasSOFLast6Months | BI_DB_AML_KYC_SOF | HasSOFLast6Months | 1 if qualifying Proof of Income document submitted within last 6 months |
| 36 | Is_SOF_needed | BI_DB_AML_KYC_SOF | SOF_Predication | 1 when SOF_Predication != 'Do not check SOF' (i.e., SOF review is required or recommended) |
| 37 | Planned_Invested_Amount_Q14 | BI_DB_KYC_Panel | Q14_AnswerText | Customer's Q14 answer text for planned annual investment amount bracket |
| 38 | Total_Withdraw | Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=8 (cashout) — all-time total cashout in USD |
| 39 | Login_Rank1_2023 | Fact_CustomerAction (login) | CountryIDByIP | Count of login events from Rank-1 AML risk countries after 2023-01-01; 1 for 558 customers (0.01%) |
| 40 | Has_Open_AML_SF_Case | BI_DB_SF_Cases_Panel | — | 1 if customer has an open AML-type Salesforce case; 0.03% of population (1,426 rows) |
| 41 | Has_Proof_Of_Income | External_etoro_BackOffice_CustomerDocument | DocumentType | 1 if 'Proof of Income' doc exists (approved or 'Not Accepted' with SuggestedDocumentType='Proof of Income') |
| 42 | Has_Selfie | External_etoro_BackOffice_CustomerDocument | DocumentType | 1 if approved selfie or liveness check document exists in BackOffice |
| 43 | Has_Passed_VI_or_BI | SolarisBankIdentDb / VideoIdentDb | GlobalStatus / Status | 1 if customer passed bank identification (SolarisBankIdentDb GlobalStatus='successful') OR video identification (VideoIdentDb Status='Success') |
| 44 | UpdateDate | — | — | `GETDATE()` at SP execution time — ETL metadata timestamp |
| 45 | Has_Proof_Of_Income_FromLastYear | External_etoro_BackOffice_CustomerDocument | DocumentDateAdded | 1 if qualifying Proof of Income document was submitted within the last calendar year |

---

## ETL Flow

```
Dim_Customer (IsValidCustomer=1, IsDepositor=1, VL=3, PlayerStatusID NOT IN(2,4))
  → #pop (base population: ~4.65M depositing VL3 customers, all risk levels)

External_RiskClassification_dbo_V_RiskClassificationDataLake
  → #risk_score (RiskScoreName, RiskScore_Explanation, ScreeningStatus, PreviousRisk)

External_Fivetran_google_sheets_grc_list
  → #fivetran (aml_compliance by Country + CountryRank, aml_compliance by POB_Country)

External_UserApiDB_Ev_CustomerResult (ROW_NUMBER by GCID, OccurredAt DESC)
  → #evdate (latest EV result per GCID)

Dim_Customer (IsIDProofExpiryDate, IsAddressProofExpiryDate)
  → #poi (POI/POA expiry dates)

BI_DB_KYC_Panel (Q26_AnswerText IN ('Family financial support','Social Security'))
  → #Q26_SOF (Is_High_Risk_SOF flag, SOF_Q26_Answer)

Fact_CustomerAction (ActionTypeID=7, non-standard FundingTypeID, post-2023)
  → #mop (Is_High_MOP_Deposit flag)

BackOffice CustomerDocument (selfie/liveness, approved)
  → #Selfie → #selfie_final (Has_Selfie)

SolarisBankIdentDb (GlobalStatus='successful') + VideoIdentDb (Status='Success')
  → #bankIdent, #videoident (Has_Passed_VI_or_BI)

BI_DB_KYC_Panel (Q18_AnswerText = occupation)
  → #Occupation (Occupation_Answer, Is_HighRisk_Occupation)

BackOffice CustomerDocument (DocumentType='Proof of Income')
  → #ProofOfIncome (Has_Proof_Of_Income, Has_Proof_Of_Income_FromLastYear)

BI_DB_SF_Cases_Panel (open AML cases)
  → #amlSF (Has_Open_AML_SF_Case)

BI_DB_KYC_Panel (Q14_AnswerText WITH NOLOCK)
  → #Planned_Invested_Amount (Planned_Invested_Amount_Q14)

Fact_CustomerAction (ActionTypeID=8 WITH NOLOCK)
  → #totalco (Total_Withdraw)

Fact_CustomerAction (login, CountryIDByIP IN Rank-1 countries, post-2023)
  → #login (Login_Rank1_2023)

BI_DB_AML_KYC_SOF (JOIN #pop)
  → #sofredflag (ReasonType, HasBusinessPotential, HasSOFLast6Months, SOF_Predication→Is_SOF_needed)

ALL temp tables assembled → #final_AR (all #pop rows, no risk filter)

TRUNCATE BI_DB_AML_Periodic_Review_AR;
INSERT FROM #final_AR + GETDATE() as UpdateDate

OpsDB: SP_AML_Periodic_Review | Priority 0 | Daily
```

*Batch 49 | Generated 2026-04-22*
