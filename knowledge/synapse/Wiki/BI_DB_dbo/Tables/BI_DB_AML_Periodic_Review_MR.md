# BI_DB_dbo.BI_DB_AML_Periodic_Review_MR

**Generated**: 2026-04-22  
**Schema**: BI_DB_dbo  
**Object Type**: Table  
**Writer SP**: SP_AML_Periodic_Review  
**Load Pattern**: TRUNCATE + INSERT daily  
**Distribution**: ROUND_ROBIN  
**Index**: HEAP  
**Column Count**: 46  
**Row Count**: 84,088  
**FTD Range**: 2008-05-12 to 2023-04-11 (3-year cutoff from run date)  
**Priority**: 0 (OpsDB)  
**Frequency**: Daily  
**UC Migration**: Not Migrated  

---

## 1. Overview

Daily AML risk review table for **High Risk customers whose first-time deposit (FTD) occurred at least 3 years ago**. This is the "MR" (most-restrictive / mature-risk) subset of the three tables written by `SP_AML_Periodic_Review`:

| Table | Subset Definition |
|---|---|
| BI_DB_AML_Periodic_Review_AR | All-risk base population |
| BI_DB_AML_Periodic_Review_HR | High Risk, FTD ≥ 1 year ago |
| **BI_DB_AML_Periodic_Review_MR** | **High Risk, FTD ≥ 3 years ago (this table)** |

MR is a strict subset of HR: every MR customer is also in HR. The 3-year FTD threshold captures customers with a longer trading history who are classified as High Risk — typically the AML team's highest-scrutiny review population.

**Population filters** (from base #pop, before MR subset):
- `IsValidCustomer = 1`, `IsDepositor = 1`, `VerificationLevelID = 3` (fully KYC-verified)
- `PlayerStatusID NOT IN (2, 4)` (excludes Blocked and Blocked Upon Request)

**MR-specific filter** (applied on top of #pop):
- `RiskScoreName = 'High'`
- `PlayerStatus IN ('Normal', 'Warning')`
- `CAST(Original_FTD AS DATE) <= @3YearsAgo_Date` (FTD at least 3 years before run date)

**Final_Decision triage** (applied last, priority order: Orange > Red > Green):
| Decision | Trigger | Count | % |
|---|---|---|---|
| Orange | Expired POI (Is_POI_ExpiryDate=1) OR expired POA (Is_POA_ExpiryDate=1) | 40,834 | 48.6% |
| Green | None of the Red/Orange conditions triggered | 32,996 | 39.2% |
| Red | IsHighRisk_Screening=1 OR (Is_High_Risk_SOF=1 AND no recent income proof) OR Is_High_MOP_Deposit=1 | 10,258 | 12.2% |

---

## 2. Column Inventory

| # | Column | Type | Nullable | Tier | Source |
|---|--------|------|----------|------|--------|
| 1 | CID | int | YES | T1 | DWH_dbo.Dim_Customer.RealCID |
| 2 | GCID | int | YES | T1 | DWH_dbo.Dim_Customer.GCID |
| 3 | Age | int | YES | T2 | DATEDIFF(YEAR, Dim_Customer.BirthDate, GETDATE()) |
| 4 | Age_Group | varchar(250) | YES | T2 | Computed: 18-21 Age / Over 75 / No Risk Age |
| 5 | Original_FTD | datetime | YES | T1 | CAST(Dim_Customer.FirstDepositDate AS DATE) |
| 6 | Regulation | nvarchar(4000) | YES | T1 | DWH_dbo.Dim_Regulation.Name |
| 7 | Country | varchar(250) | YES | T1 | DWH_dbo.Dim_Country.Name (via CountryID) |
| 8 | POB_Country | varchar(250) | YES | T1 | DWH_dbo.Dim_Country.Name (via POBCountryID) |
| 9 | aml_compliance_POB | nvarchar(4000) | YES | T2 | External_Fivetran_google_sheets_grc_list.aml_compliance (via POBCountryID) |
| 10 | CountryRank | int | YES | T2 | DWH_dbo.Dim_Country.RiskGroupID (via CountryID) |
| 11 | aml_compliance | varchar(250) | YES | T2 | External_Fivetran_google_sheets_grc_list.aml_compliance (via CountryID) |
| 12 | PlayerStatus | varchar(250) | YES | T1 | DWH_dbo.Dim_PlayerStatus.Name |
| 13 | Club | varchar(250) | YES | T1 | DWH_dbo.Dim_PlayerLevel.Name |
| 14 | EvMatchStatusName | nvarchar(4000) | YES | T1 | DWH_dbo.Dim_EvMatchStatus.EvMatchStatusName |
| 15 | EvStatusId | int | YES | T2 | External_UserApiDB_Ev_CustomerResult.EvStatusId (latest) |
| 16 | EV_Date | datetime | YES | T2 | External_UserApiDB_Ev_CustomerResult.TransactionDate (latest) |
| 17 | ScreeningStatus | nvarchar(4000) | YES | T1 | DWH_dbo.Dim_ScreeningStatus.Name |
| 18 | RiskScoreName | nvarchar(4000) | YES | T2 | External_RiskClassification_dbo_V_RiskClassificationDataLake.RiskScoreName |
| 19 | RiskScore_Explanation | nvarchar(4000) | YES | T2 | External_RiskClassification_dbo_V_RiskClassificationDataLake.RiskScore_Explanation |
| 20 | HasWallet | int | YES | T1 | DWH_dbo.Dim_Customer.HasWallet |
| 21 | AccountProgram | nvarchar(250) | YES | T2 | eMoney_dbo.eMoney_Dim_Account.AccountProgram |
| 22 | IsHighRisk_Screening | int | YES | T2 | Computed: 1 if ScreeningStatus <> 'NoMatch' |
| 23 | IsEDD | int | YES | T1 | DWH_dbo.Dim_Customer.IsEDD |
| 24 | POI_ExpiryDate | datetime | YES | T2 | DWH_dbo.Dim_Customer.IsIDProofExpiryDate |
| 25 | POA_ExpiryDate | datetime | YES | T2 | DWH_dbo.Dim_Customer.IsAddressProofExpiryDate |
| 26 | Is_POI_ExpiryDate | int | YES | T2 | Computed: 1 if POI_ExpiryDate < GETDATE() |
| 27 | Is_POA_ExpiryDate | int | YES | T2 | Computed: 1 if POA_ExpiryDate < GETDATE() |
| 28 | Is_High_Risk_SOF | int | YES | T2 | Computed: 1 if Q26_AnswerText LIKE '%Family financial support%' OR '%Social Security%' |
| 29 | SOF_Q26_Answer | nvarchar(4000) | YES | T2 | BI_DB_KYC_Panel.Q26_AnswerText |
| 30 | Is_High_MOP_Deposit | int | YES | T2 | Computed: 1 if customer has a non-standard-MOP deposit since 2023 |
| 31 | Occupation_Answer | nvarchar(250) | YES | T2 | BI_DB_KYC_Panel.Q18_AnswerText |
| 32 | Is_HighRisk_Occupation | int | YES | T2 | Computed: 1 if Q18 IN (None, Gambling Industry, Gaming/Casino/Card Club, Student) |
| 33 | ReasonType | nvarchar(4000) | YES | T2 | BI_DB_AML_KYC_SOF.ReasonType |
| 34 | HasBusinessPotential | int | YES | T2 | BI_DB_AML_KYC_SOF.HasBusinessPotential |
| 35 | HasSOFLast6Months | int | YES | T2 | BI_DB_AML_KYC_SOF.HasSOFLast6Months |
| 36 | Is_SOF_needed | int | YES | T2 | BI_DB_AML_KYC_SOF: 1 if SOF_Predication <> 'Do not check SOF' |
| 37 | Planned_Invested_Amount_Q14 | nvarchar(4000) | YES | T2 | BI_DB_KYC_Panel.Q14_AnswerText |
| 38 | Total_Withdraw | money | YES | T2 | SUM(Fact_CustomerAction.Amount) WHERE ActionTypeID=8 (cashout) |
| 39 | Login_Rank1_2023 | int | YES | T2 | Computed: 1 if customer has a login from a highest-risk country (CountryIDByIP=1) since 2023-01-01 |
| 40 | Has_Open_AML_SF_Case | int | YES | T2 | Computed: 1 if customer has an open AML Salesforce case (ActionType LIKE '%AML%', status not Closed/Solved) |
| 41 | Has_Proof_Of_Income | int | YES | T2 | Computed: 1 if any approved 'Proof of Income' document exists |
| 42 | Has_Selfie | int | YES | T2 | Computed: 1 if any approved Selfie/SelfieLiveliness document exists |
| 43 | Has_Passed_VI_or_BI | int | YES | T2 | Computed: 1 if latest VideoIdent Status='Success' OR latest BankIdent GlobalStatus='successful' |
| 44 | Final_Decision | nvarchar(4000) | YES | T2 | Computed CASE: Orange / Red / Green triage |
| 45 | UpdateDate | datetime | YES | — | ETL metadata: GETDATE() at insert time |
| 46 | Has_Proof_Of_Income_FromLastYear | int | YES | T2 | Computed: 1 if most recent 'Proof of Income' document was added >= @YearAgo_Date |

---

## 3. ETL Pipeline

```
[Population]
DWH_dbo.Dim_Customer (IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3, PlayerStatusID NOT IN 2,4)
  + Dim_Regulation, Dim_Country, Dim_PlayerStatus, Dim_PlayerLevel
  + Dim_EvMatchStatus, Dim_ScreeningStatus
  + External_RiskClassification (RiskScoreName, RiskScore_Explanation)
  + External_Fivetran_grc_list (aml_compliance)
  + External_UserApiDB_Ev_CustomerResult (EV date, latest)
  + eMoney_Dim_Account (AccountProgram)
→ #pop (base)

#pop WHERE RiskScoreName='High'
       AND PlayerStatus IN ('Normal','Warning')
       AND FTD <= @3YearsAgo_Date
→ #pop3 → #final_pop_mr

[Enrichment (same temp tables as HR)]
Dim_Customer → #poi (POI/POA expiry)
BI_DB_KYC_Panel Q26 → #Q26_SOF (SOF risk)
Fact_CustomerAction deposits (2023+) → #mop (high-risk MOP)
BackOffice_CustomerDocument → #selfie_final (selfie), #ProofOfIncome (income proof)
SolarisBankIdentDb → #bankIdent2 (bank ident)
VideoIdentDb → #videoident2 (video ident)
BI_DB_KYC_Panel Q18 → #Occupation
BI_DB_AML_KYC_SOF → #sofredflag
BI_DB_SF_Cases_Panel → #amlSF
BI_DB_KYC_Panel Q14 → #Planned_Invested_Amount
Fact_CustomerAction cashouts → #totalco
Fact_CustomerAction logins → #login

[Final Assembly]
#final_pop_mr LEFT JOIN all enrichment tables → #final_MR
#final_MR + Final_Decision CASE → #final_pop4

SP_AML_Periodic_Review (Eyal Boas, 2025-04-27):
  TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Periodic_Review_MR
  INSERT INTO BI_DB_dbo.BI_DB_AML_Periodic_Review_MR FROM #final_pop4
```

**Author note**: SP header shows date 2025-02-25 (copied from earlier SP); the Change History block shows "27/04/2025 Eyal Boas New SP" as the actual creation date.

---

## 4. Column Descriptions

### CID
**Type**: int NULL  
**Tier**: T1 — DWH_dbo.Dim_Customer (Tier 1 — Customer.CustomerStatic)  
**Description**: Customer ID — platform-internal primary key. Aliases `RealCID` in DWH dimensions. Assigned at registration.

---

### GCID
**Type**: int NULL  
**Tier**: T1 — DWH_dbo.Dim_Customer  
**Description**: Group Customer ID. Shared identifier used across group-level services (SolarisBankIdent, VideoIdent, eMoney). Multiple CIDs in the same regulated group may share a GCID.

---

### Age
**Type**: int NULL  
**Tier**: T2 — computed  
**Description**: Customer's current age in whole years, computed as `DATEDIFF(YEAR, BirthDate, GETDATE())` from `Dim_Customer.BirthDate`. Refreshed daily on each SP run.

---

### Age_Group
**Type**: varchar(250) NULL  
**Tier**: T2 — computed  
**Description**: Age-based risk grouping derived from Age. Three values:
- `18-21 Age` — young adult; elevated AML risk indicator
- `Over 75` — elderly; elevated AML risk indicator
- `No Risk Age` — all other ages (majority of population)

---

### Original_FTD
**Type**: datetime NULL  
**Tier**: T1 — DWH_dbo.Dim_Customer.FirstDepositDate  
**Description**: Date of the customer's first-ever deposit, cast from `FirstDepositDate` (date → datetime). The MR population filter applies `CAST(Original_FTD AS DATE) <= @3YearsAgo_Date`, so all MR customers made their first deposit at least 3 years before the run date. Range in live data: 2008-05-12 to 2023-04-11 (as of April 2026 run).

---

### Regulation
**Type**: nvarchar(4000) NULL  
**Tier**: T1 — DWH_dbo.Dim_Regulation.Name (Tier 1 — BackOffice.Customer)  
**Description**: Regulatory jurisdiction governing this customer. Values: FSA Seychelles (25.1%), FCA (23.9%), CySEC (22.0%), FinCEN+FINRA (18.0%), FinCEN (9.2%), FSRA (1.1%), ASIC&GAML (0.5%), ASIC (0.1%). Sourced via `Dim_Customer.RegulationID → Dim_Regulation.Name`.

---

### Country
**Type**: varchar(250) NULL  
**Tier**: T1 — DWH_dbo.Dim_Country.Name (Tier 1 — BackOffice.Customer)  
**Description**: Customer's current country of residence (KYC country). Sourced via `Dim_Customer.CountryID → Dim_Country.Name`. Used as the baseline for geographic risk comparisons throughout the SP.

---

### POB_Country
**Type**: varchar(250) NULL  
**Tier**: T1 — DWH_dbo.Dim_Country.Name (Tier 1 — BackOffice.Customer)  
**Description**: Customer's country of birth. Sourced via `Dim_Customer.POBCountryID → Dim_Country.Name`. NULL if not recorded. Used alongside Country for AML country-risk profiling.

---

### aml_compliance_POB
**Type**: nvarchar(4000) NULL  
**Tier**: T2 — External_Fivetran_google_sheets_grc_list  
**Description**: AML compliance classification of the customer's country of birth. Sourced from the GRC (Governance, Risk, Compliance) Google Sheet via Fivetran (`External_Fivetran_google_sheets_grc_list.aml_compliance`), joined on `Dim_Customer.POBCountryID`. NULL if POB country not in the GRC sheet.

---

### CountryRank
**Type**: int NULL  
**Tier**: T2 — DWH_dbo.Dim_Country.RiskGroupID  
**Description**: Country risk group of the customer's KYC country. Sourced from `Dim_Country.RiskGroupID`. Lower value = higher risk (1 = highest risk group). Used in `Login_Rank1_2023` detection logic and geographic risk scoring.

---

### aml_compliance
**Type**: varchar(250) NULL  
**Tier**: T2 — External_Fivetran_google_sheets_grc_list  
**Description**: AML compliance classification of the customer's KYC country. Sourced from the GRC Google Sheet via Fivetran, joined on `Dim_Customer.CountryID`. Indicates whether the country is on a monitored AML compliance list.

---

### PlayerStatus
**Type**: varchar(250) NULL  
**Tier**: T1 — DWH_dbo.Dim_PlayerStatus.Name (Tier 1 — BackOffice.Customer)  
**Description**: Customer's current account status. **All MR customers are 'Normal' or 'Warning'** — the MR population filter enforces this. Blocked (status 2) and Blocked Upon Request (status 4) are excluded from #pop entirely.

---

### Club
**Type**: varchar(250) NULL  
**Tier**: T1 — DWH_dbo.Dim_PlayerLevel.Name (Tier 1 — BackOffice.Customer)  
**Description**: Customer's loyalty/experience tier (Silver, Gold, Platinum, Diamond, etc.). Sourced via `Dim_Customer.PlayerLevelID → Dim_PlayerLevel.Name`. Used for business context during AML review.

---

### EvMatchStatusName
**Type**: nvarchar(4000) NULL  
**Tier**: T1 — DWH_dbo.Dim_EvMatchStatus.EvMatchStatusName (Tier 1 — BackOffice.Customer)  
**Description**: Electronic verification (EV) identity match status from the DWH dimension. Values: None, PartiallyVerified, Verified, NotVerified. Sourced via `Dim_Customer.EvMatchStatus → Dim_EvMatchStatus.EvMatchStatusName`.

---

### EvStatusId
**Type**: int NULL  
**Tier**: T2 — External_UserApiDB_Ev_CustomerResult  
**Description**: Numeric EV status ID from the UserAPI EV result table. The latest record per GCID is selected by `ROW_NUMBER() OVER (PARTITION BY GCID ORDER BY TransactionDate DESC) = 1`. Companion to EV_Date.

---

### EV_Date
**Type**: datetime NULL  
**Tier**: T2 — External_UserApiDB_Ev_CustomerResult.TransactionDate  
**Description**: Date of the customer's most recent electronic verification transaction. NULL if no EV record exists. Sourced from the latest UserAPI EV result per GCID.

---

### ScreeningStatus
**Type**: nvarchar(4000) NULL  
**Tier**: T1 — DWH_dbo.Dim_ScreeningStatus.Name (Tier 1 — ScreeningService.UserScreening)  
**Description**: Current AML screening outcome. Values: NoMatch, PendingInvestigation, PEP, RiskMatch, SanctionsMatch, Technical, MultipleMatch, Unknown. Drives `IsHighRisk_Screening = 1` for any value other than 'NoMatch'.

---

### RiskScoreName
**Type**: nvarchar(4000) NULL  
**Tier**: T2 — External_RiskClassification_dbo_V_RiskClassificationDataLake  
**Description**: Output of the external AML risk classification engine. **Always 'High' in this table** — the MR population filter requires `RiskScoreName = 'High'`. The value is propagated here for audit completeness and consistency with the AR/HR sibling tables.

---

### RiskScore_Explanation
**Type**: nvarchar(4000) NULL  
**Tier**: T2 — External_RiskClassification_dbo_V_RiskClassificationDataLake  
**Description**: Free-text explanation of why the risk engine assigned the High score to this customer. Sourced alongside RiskScoreName from the external risk classification view.

---

### HasWallet
**Type**: int NULL  
**Tier**: T1 — DWH_dbo.Dim_Customer.HasWallet (Tier 1 — BackOffice.Customer)  
**Description**: 1 if the customer has a crypto/digital wallet, 0 otherwise. Business context flag for AML review — wallet ownership can indicate additional asset movement channels.

---

### AccountProgram
**Type**: nvarchar(250) NULL  
**Tier**: T2 — eMoney_dbo.eMoney_Dim_Account.AccountProgram  
**Description**: eMoney account program type assigned to this customer (via LEFT JOIN on CID). NULL if the customer has no eMoney account record. Used for regulated account context during review.

---

### IsHighRisk_Screening
**Type**: int NULL  
**Tier**: T2 — computed  
**Description**: 1 if `ScreeningStatus <> 'NoMatch'` (i.e., customer has a screening hit of any kind — PEP, sanctions, risk match, etc.). 0 if ScreeningStatus = 'NoMatch'. **Contributes to Final_Decision = 'Red'** regardless of income proof status.  
**Profile**: 1,214 rows (1.4%) have IsHighRisk_Screening = 1.

---

### IsEDD
**Type**: int NULL  
**Tier**: T1 — DWH_dbo.Dim_Customer.IsEDD (Tier 1 — BackOffice.Customer)  
**Description**: Enhanced Due Diligence flag. 1 if the customer is subject to EDD requirements (politically exposed persons, high-risk countries, etc.). 0 otherwise.  
**Profile**: 30,546 rows (36.3%) have IsEDD = 1 — notably high given the 3-year high-risk FTD filter.

---

### POI_ExpiryDate
**Type**: datetime NULL  
**Tier**: T2 — DWH_dbo.Dim_Customer.IsIDProofExpiryDate  
**Description**: Expiry date of the customer's government-issued identity document (passport, national ID). Sourced from `Dim_Customer.IsIDProofExpiryDate`. NULL if no ID proof recorded. Used to compute `Is_POI_ExpiryDate`.

---

### POA_ExpiryDate
**Type**: datetime NULL  
**Tier**: T2 — DWH_dbo.Dim_Customer.IsAddressProofExpiryDate  
**Description**: Expiry date of the customer's address proof document. Sourced from `Dim_Customer.IsAddressProofExpiryDate`. NULL if no address proof recorded. Used to compute `Is_POA_ExpiryDate`.

---

### Is_POI_ExpiryDate
**Type**: int NULL  
**Tier**: T2 — computed  
**Description**: 1 if `POI_ExpiryDate < GETDATE()` (identity document has expired). 0 otherwise. **Contributes to Final_Decision = 'Orange'** (checked before Red conditions).  
**Profile**: 15,682 rows (18.6%) have Is_POI_ExpiryDate = 1.

---

### Is_POA_ExpiryDate
**Type**: int NULL  
**Tier**: T2 — computed  
**Description**: 1 if `POA_ExpiryDate < GETDATE()` (address proof has expired). 0 otherwise. **Contributes to Final_Decision = 'Orange'**.  
**Profile**: 38,618 rows (45.9%) have Is_POA_ExpiryDate = 1 — significantly higher than the AR table (23.5%) because MR captures older customers with more expired documents.

---

### Is_High_Risk_SOF
**Type**: int NULL  
**Tier**: T2 — computed from BI_DB_KYC_Panel.Q26_AnswerText  
**Description**: 1 if the customer's KYC Q26 "Source of Funds" answer includes 'Family financial support' or 'Social Security'. These are considered high-risk income sources under AML policy. **Contributes to Final_Decision = 'Red' only if `Has_Proof_Of_Income_FromLastYear = 0`** (no recent proof of income on file).  
**Profile**: 16,158 rows (19.2%) have Is_High_Risk_SOF = 1.

---

### SOF_Q26_Answer
**Type**: nvarchar(4000) NULL  
**Tier**: T2 — BI_DB_KYC_Panel.Q26_AnswerText  
**Description**: Raw KYC questionnaire answer to Q26 "What is your source of funds?". May contain comma-separated multiple answers. Used to derive `Is_High_Risk_SOF`. NULL if customer has no KYC panel record.

---

### Is_High_MOP_Deposit
**Type**: int NULL  
**Tier**: T2 — computed from DWH_dbo.Fact_CustomerAction  
**Description**: 1 if the customer made a deposit since 2023-01-01 using a non-standard method of payment (MOP). Standard MOP funding types (IDs 1,2,3,4,11,13,15,17,29,30,32,33,34,35,36,37,38) are whitelisted; any deposit with a FundingTypeID outside this list is considered high-risk. **Contributes to Final_Decision = 'Red'** regardless of income proof status.  
**Profile**: 980 rows (1.2%) have Is_High_MOP_Deposit = 1.

---

### Occupation_Answer
**Type**: nvarchar(250) NULL  
**Tier**: T2 — BI_DB_KYC_Panel.Q18_AnswerText  
**Description**: Raw KYC questionnaire answer to Q18 "What is your occupation?". Used to derive `Is_HighRisk_Occupation`. NULL if no KYC panel record.

---

### Is_HighRisk_Occupation
**Type**: int NULL  
**Tier**: T2 — computed from BI_DB_KYC_Panel.Q18_AnswerText  
**Description**: 1 if `Occupation_Answer IN ('None', 'Gambling Industry', 'Gaming/Casino/Card Club', 'Student')`. These occupations indicate potential for irregular income patterns under AML policy.  
**Profile**: 44,046 rows (52.4%) have Is_HighRisk_Occupation = 1 — the most prevalent flag in the MR population.

---

### ReasonType
**Type**: nvarchar(4000) NULL  
**Tier**: T2 — BI_DB_AML_KYC_SOF.ReasonType  
**Description**: SOF (Source of Funds) prediction reason classification from the AML KYC SOF model. Provides context for the SOF check recommendation. NULL if no SOF record exists for this customer.

---

### HasBusinessPotential
**Type**: int NULL  
**Tier**: T2 — BI_DB_AML_KYC_SOF.HasBusinessPotential  
**Description**: SOF model indicator: 1 if the customer profile has business-related income potential. Sourced from the `BI_DB_AML_KYC_SOF` table. Used in conjunction with ReasonType for SOF review context.

---

### HasSOFLast6Months
**Type**: int NULL  
**Tier**: T2 — BI_DB_AML_KYC_SOF.HasSOFLast6Months  
**Description**: 1 if a Source of Funds document was received within the last 6 months. Sourced from `BI_DB_AML_KYC_SOF`. Relevant to the AML team's assessment of whether a fresh SOF check is needed.

---

### Is_SOF_needed
**Type**: int NULL  
**Tier**: T2 — BI_DB_AML_KYC_SOF  
**Description**: 1 if `SOF_Predication <> 'Do not check SOF'` in `BI_DB_AML_KYC_SOF`. The SOF prediction model recommends whether a Source of Funds check should be requested for this customer. NULL if no SOF record (treated as 0 effectively).

---

### Planned_Invested_Amount_Q14
**Type**: nvarchar(4000) NULL  
**Tier**: T2 — BI_DB_KYC_Panel.Q14_AnswerText  
**Description**: KYC questionnaire answer to Q14 "How much do you plan to invest in the next 12 months?". Stored as raw text bracket (e.g., '$10K-$25K'). NULL if customer has no KYC panel record. Provides expected investment level context for deposit pattern analysis.

---

### Total_Withdraw
**Type**: money NULL  
**Tier**: T2 — DWH_dbo.Fact_CustomerAction  
**Description**: Lifetime total cashout amount in USD. Computed as `SUM(Fact_CustomerAction.Amount)` where `ActionTypeID = 8` (cashout). 0 if no cashout history (ISNULL → 0). Provides context for AML asset movement assessment.

---

### Login_Rank1_2023
**Type**: int NULL  
**Tier**: T2 — computed from DWH_dbo.Fact_CustomerAction  
**Description**: 1 if the customer has at least one login (ActionTypeID=14) since 2023-01-01 where `CountryIDByIP = 1`. The SP logic checks `fca.CountryIDByIP IN (SELECT pp.CountryRank FROM #pop pp WHERE pp.CountryRank = 1)` — since all CountryRank=1 entries return the value 1, this effectively filters on `CountryIDByIP = 1`.  
**Note**: See Quality Notes for a potential SP logic concern with mixing CountryIDByIP (country ID) and CountryRank (risk group ID) namespaces.

---

### Has_Open_AML_SF_Case
**Type**: int NULL  
**Tier**: T2 — BI_DB_dbo.BI_DB_SF_Cases_Panel  
**Description**: 1 if the customer has an open Salesforce case with an AML-related action type (`ActionType_AtOpen LIKE '%AML%'`) and ticket status NOT IN ('Closed', 'Solved'). 0 otherwise. Indicates an active AML investigation in progress.  
**Profile**: 137 rows (0.2%) have Has_Open_AML_SF_Case = 1.

---

### Has_Proof_Of_Income
**Type**: int NULL  
**Tier**: T2 — External_etoro_BackOffice_CustomerDocument  
**Description**: 1 if any non-rejected 'Proof of Income' document exists for this customer in the BackOffice document store. 0 otherwise. Based on `DocumentType = 'Proof of Income'` and `RejectReasonName IS NULL`. Most-recent document selected per CID by `ROW_NUMBER() ... ORDER BY DocumentDateAdded DESC`.  
**Profile**: 13,304 rows (15.8%) have Has_Proof_Of_Income = 1.

---

### Has_Selfie
**Type**: int NULL  
**Tier**: T2 — External_etoro_BackOffice_CustomerDocument  
**Description**: 1 if any non-rejected 'Selfie' or 'SelfieLiveliness' document exists for this customer. 0 otherwise. The most-recent document per CID is selected by `ROW_NUMBER() ... ORDER BY DocumentDateAdded DESC`. Used as a biometric identity verification indicator.  
**Profile**: 17,898 rows (21.3%) have Has_Selfie = 1.

---

### Has_Passed_VI_or_BI
**Type**: int NULL  
**Tier**: T2 — general.VideoIdentDb_VideoIdent + general.SolarisBankIdentDb_SolarisBankIdent  
**Description**: 1 if the customer has passed either Video Identification (`VideoIdentDb_VideoIdent.Status = 'Success'`) or Bank Identification (`SolarisBankIdentDb_SolarisBankIdent.GlobalStatus = 'successful'`). Most recent record per GCID selected for each. 0 if neither verification passed.  
**Profile**: 1,061 rows (1.3%) have Has_Passed_VI_or_BI = 1.

---

### Final_Decision
**Type**: nvarchar(4000) NULL  
**Tier**: T2 — computed CASE  
**Description**: AML compliance triage decision for this customer. Evaluated with priority order (Orange checked first):

| Value | Logic | Count | % |
|---|---|---|---|
| Orange | `Is_POI_ExpiryDate = 1 OR Is_POA_ExpiryDate = 1` | 40,834 | 48.6% |
| Red | `IsHighRisk_Screening = 1 OR (Is_High_Risk_SOF = 1 AND Has_Proof_Of_Income_FromLastYear = 0) OR Is_High_MOP_Deposit = 1` | 10,258 | 12.2% |
| Green | None of the above conditions triggered | 32,996 | 39.2% |

**Priority note**: A customer with both expired documents AND high screening is classified Orange, not Red. Orange indicates documentary compliance action required; Red indicates a more urgent AML risk flag.

---

### UpdateDate
**Type**: datetime NULL  
**Tier**: Propagation blacklist  
**Description**: ETL metadata timestamp. Set to `GETDATE()` at INSERT time. Reflects when the table was last refreshed, not a business event date.

---

### Has_Proof_Of_Income_FromLastYear
**Type**: int NULL  
**Tier**: T2 — External_etoro_BackOffice_CustomerDocument  
**Description**: 1 if the most recent approved 'Proof of Income' document was added on or after `@YearAgo_Date` (1 year before the run date). 0 if the most recent document is older than 1 year, or no document exists. This recency check is used in the Red condition: `Is_High_Risk_SOF = 1 AND Has_Proof_Of_Income_FromLastYear = 0` triggers Red only if the customer lacks a recent income proof.  
**Note**: Uses `@YearAgo_Date` (1-year window), not `@3YearsAgo_Date`. A customer with an income proof document can still trigger Red if that document is older than 1 year.

---

## 5. Relationships

| Relationship | Object | Join Key | Notes |
|---|---|---|---|
| Source (base population) | DWH_dbo.Dim_Customer | CID = RealCID | IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3 |
| Source (dimensions) | DWH_dbo.Dim_Regulation, Dim_Country, Dim_PlayerStatus, Dim_PlayerLevel, Dim_EvMatchStatus, Dim_ScreeningStatus | CID → various IDs | Name lookups for Regulation, Country, PlayerStatus, Club, EV status, Screening status |
| Source (transactions) | DWH_dbo.Fact_CustomerAction | CID = RealCID | Deposits (MOP check), cashouts (Total_Withdraw), logins (Login_Rank1_2023) |
| Source (risk engine) | BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | CID | RiskScoreName, RiskScore_Explanation |
| Source (country risk) | BI_DB_dbo.External_Fivetran_google_sheets_grc_list | CountryID | aml_compliance, country risk flags |
| Source (EV) | BI_DB_dbo.External_UserApiDB_Ev_CustomerResult | GCID | Latest EV status and date |
| Source (documents) | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | CID | POI/POA, Selfie, Proof of Income |
| Source (KYC) | BI_DB_dbo.BI_DB_KYC_Panel | CID = RealCID | Q14, Q18, Q26 questionnaire answers |
| Source (SOF model) | BI_DB_dbo.BI_DB_AML_KYC_SOF | CID | SOF prediction output |
| Source (SF cases) | BI_DB_dbo.BI_DB_SF_Cases_Panel | CID = CID_Last | Open AML Salesforce cases |
| Source (bank ident) | general.SolarisBankIdentDb_SolarisBankIdent | GCID | Bank identity verification |
| Source (video ident) | general.VideoIdentDb_VideoIdent | GCID | Video identity verification |
| Source (eMoney) | eMoney_dbo.eMoney_Dim_Account | CID | AccountProgram |
| Sibling (superset) | BI_DB_dbo.BI_DB_AML_Periodic_Review_HR | CID | HR superset — MR ⊆ HR (same filter plus 1yr→3yr FTD tightening) |
| Sibling | BI_DB_dbo.BI_DB_AML_Periodic_Review_AR | CID | All-risk table; written in same SP run |

---

## 6. Data Profile

| Metric | Value |
|---|---|
| Row count | 84,088 |
| Grain | One row per High Risk customer with FTD ≥ 3 years ago (daily full-refresh) |
| Original_FTD range | 2008-05-12 to 2023-04-11 |
| Last UpdateDate | 2026-04-12 05:56:28 |
| Final_Decision = Orange | 40,834 (48.6%) |
| Final_Decision = Green | 32,996 (39.2%) |
| Final_Decision = Red | 10,258 (12.2%) |
| Regulation: FSA Seychelles | 25.1% |
| Regulation: FCA | 23.9% |
| Regulation: CySEC | 22.0% |
| Regulation: FinCEN+FINRA | 18.0% |
| Regulation: FinCEN | 9.2% |
| Is_HighRisk_Occupation = 1 | 44,046 (52.4%) — highest flag rate |
| Is_POA_ExpiryDate = 1 | 38,618 (45.9%) |
| IsEDD = 1 | 30,546 (36.3%) |
| Has_Selfie = 1 | 17,898 (21.3%) |
| Is_High_Risk_SOF = 1 | 16,158 (19.2%) |
| Is_POI_ExpiryDate = 1 | 15,682 (18.6%) |
| Has_Proof_Of_Income = 1 | 13,304 (15.8%) |
| IsHighRisk_Screening = 1 | 1,214 (1.4%) |
| Has_Passed_VI_or_BI = 1 | 1,061 (1.3%) |
| Is_High_MOP_Deposit = 1 | 980 (1.2%) |
| Has_Open_AML_SF_Case = 1 | 137 (0.2%) |

---

## 7. Quality Notes

- **Full daily refresh**: TRUNCATE + INSERT — no history retained. The table always reflects the current-day state of the High Risk / 3-year FTD population.
- **MR ⊆ HR**: Every row in this table also appears in BI_DB_AML_Periodic_Review_HR. The only difference is the stricter FTD threshold (3 years vs 1 year). Analysts should query MR when they want the longest-tenured High Risk customers.
- **RiskScoreName is always 'High'**: The population filter guarantees this. The column is included for audit/consistency with AR table structure.
- **@3YearsAgo_DateID bug**: SP line 18 declares `@3YearsAgo_DateID = CAST(CONVERT(CHAR(8), @YearAgo_Date, 112) AS INT)` — uses `@YearAgo_Date` (1 year ago) instead of `@3YearsAgo_Date` (3 years ago). However, the MR population filter uses `CAST(Original_FTD AS DATE) <= @3YearsAgo_Date` (the DATE variable, not the DateID), so this bug does not affect the MR population selection. The DateID variable appears to be unused in the MR path.
- **Is_High_MOP_Deposit triggers Red unconditionally**: Unlike Is_High_Risk_SOF (which requires `Has_Proof_Of_Income_FromLastYear = 0`), Is_High_MOP_Deposit alone triggers Red regardless of income proof status. A customer with a non-standard deposit MOP is always Red.
- **Is_POA_ExpiryDate (45.9%) vs AR (23.5%)**: The much higher expired POA rate in MR vs the AR table reflects the 3-year FTD filter — older customers with longer registration histories are more likely to have outdated address documents.
- **Login_Rank1_2023 logic**: The SP subquery `SELECT pp.CountryRank FROM #pop pp WHERE pp.CountryRank = 1` returns the constant set {1}, making the effective filter `fca.CountryIDByIP = 1`. This mixes two ID namespaces (CountryIDByIP = DWH country ID, CountryRank = risk group ID). The original intent appears to be detecting logins from highest-risk-group countries, but the implementation may effectively filter on a single specific country (DWH country ID = 1).
- **SP header date mismatch**: The SP header shows "Date: 2025-02-25" (inherited from earlier SP); the actual creation date is "27/04/2025" per the Change History block.
- **Has_Proof_Of_Income_FromLastYear uses @YearAgo_Date**: The recency check window is 1 year, not 3 years — consistent with the HR table logic. Customers with income proof older than 1 year are treated the same as those with no income proof for purposes of the Red flag.

---

## 8. UC Migration Status

**Status**: Not Migrated  
**Reason**: AML compliance operational table. Reviewed directly by the AML team as part of the daily High Risk customer review workflow. No Unity Catalog target exists or is planned.
