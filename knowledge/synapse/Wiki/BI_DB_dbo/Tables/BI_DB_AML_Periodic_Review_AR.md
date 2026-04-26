# BI_DB_dbo.BI_DB_AML_Periodic_Review_AR

> Daily full-refresh AML periodic review base table (4.65M rows) covering ALL depositing VL3 customers regardless of risk score, enriched with sanctions screening, EV status, KYC questionnaire answers, SOF assessment, identity document expiry flags, and document verification status — the "All Records" population for AML periodic review reporting.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Column Count** | 45 |
| **Row Count** | 4,647,549 (as of 2026-04-12) |
| **Grain** | One row per CID — all depositing VL3 customers |
| **Refresh** | Daily (OpsDB Priority 0 — base layer) |
| **Writer SP** | `BI_DB_dbo.SP_AML_Periodic_Review @Date [DATE]` |
| **ETL Pattern** | TRUNCATE + INSERT (full refresh) |
| **PII Columns** | CID, GCID, Age |
| **UC Target** | Not Migrated |

---

## 1. Business Meaning

`BI_DB_AML_Periodic_Review_AR` is the **"All Records"** (AR) output of the AML Periodic Review SP. It contains every depositing, fully-verified (VL3) eToro customer who is currently active (PlayerStatusID NOT IN 2=Blocked, 4=Deleted), regardless of their AML risk score. This is distinct from the companion tables:

- **`BI_DB_AML_Periodic_Review_HR`** — High Risk customers only (RiskScoreName='High', FTD ≤ 1 year ago, has Final_Decision)
- **`BI_DB_AML_Periodic_Review_MR`** — Medium/long-term population (RiskScoreName='High', FTD ≤ 3 years ago, has Final_Decision)

The AR table has **no risk score filter** — it serves as the full-universe reference for AML analysts who need to examine any depositor's KYC profile, risk indicators, document status, and SOF position, regardless of whether they are flagged as high-risk. It is rebuilt daily from scratch (TRUNCATE + INSERT).

**Key difference from HR/MR**: The AR table does NOT have a `Final_Decision` column (Red/Orange/Green). That traffic-light classification only applies to the HR and MR populations. The AR table is a data enrichment table, not a decision output.

### Who appears in this table

A customer appears if ALL of the following are true at SP run time:
- `Dim_Customer.IsValidCustomer = 1`
- `Dim_Customer.IsDepositor = 1`
- `Dim_Customer.VerificationLevelID = 3` (fully verified)
- `Dim_Customer.PlayerStatusID NOT IN (2, 4)` (not Blocked or Deleted)

As of 2026-04-12 this captures 4,647,549 customers. RiskScoreName distribution: Medium 95.3% (4.43M), High 3.0% (140K), Low 1.5% (68K), NULL/unscored 0.2% (9K).

---

## 2. Business Logic

### 2.1 Population Gate

**What**: All depositing, fully verified, active eToro customers.

**Rules**:
- `Dim_Customer.IsValidCustomer = 1` — excludes internal accounts, certain label IDs, CountryID=250
- `Dim_Customer.IsDepositor = 1` — must have at least one deposit
- `Dim_Customer.VerificationLevelID = 3` — fully verified (VL3)
- `Dim_Customer.PlayerStatusID NOT IN (2, 4)` — excludes Blocked and Deleted accounts
- All risk score levels included — Medium, High, Low, and unscored

**PlayerStatus distribution**: Normal 98.6% (4.58M), Block Deposit & Trading 0.8% (37K), Trade & MIMO Blocked 0.3% (14K), Warning 0.15% (7K), Deposit Blocked 0.11% (5K), Copy Block 0.01% (608).

### 2.2 Age Group Classification

**What**: Groups customers into AML-relevant age bands.

**Rules**:
- `'18-21 Age'` — age 18 to 21 (young/inexperienced, enhanced monitoring)
- `'Over 75'` — age over 75 (elderly, potential vulnerability)
- `'No Risk Age'` — all others (standard age range)

**Distribution**: No Risk Age 97.7% (4.54M), 18-21 Age 1.6% (76K), Over 75 0.6% (29K).

### 2.3 AML Country Risk (CountryRank)

**What**: AML risk tier assigned to the customer's country of residence from the GRC (Governance, Risk & Compliance) list maintained in a Google Sheet via Fivetran.

**Rule**: CountryRank is the country's risk tier from `External_Fivetran_google_sheets_grc_list`. 0 = no tier assigned (default, 98.6% of customers). Values 1–4 represent increasing risk levels in the GRC schema; CountryRank=1 is the rarest and highest-risk tier (42 rows — typically sanctioned or very high-risk jurisdictions).

**Note**: `Login_Rank1_2023` (column 39) is a separate flag — it identifies customers who have *logged in* from a Rank-1 country since 2023, regardless of their own country of residence.

### 2.4 Enhanced Verification (EV) Status

**What**: The latest Electronic Verification / Identity Verification result per customer.

**Columns**: `EvMatchStatusName`, `EvStatusId`, `EV_Date`

**Source**: `External_UserApiDB_Ev_CustomerResult` — latest record per GCID (ROW_NUMBER partitioned by GCID, ordered by OccurredAt DESC). Values observed: 'Verified', 'None' (no EV performed), and various EV result codes. `EvMatchStatusName='None'` and null `EV_Date` indicate no EV has been run for this customer.

### 2.5 Sanctions & PEP Screening

**What**: Result from the external risk classification / sanctions screening provider.

**Columns**: `ScreeningStatus`, `RiskScoreName`, `RiskScore_Explanation`, `IsHighRisk_Screening`

**Rule**: `IsHighRisk_Screening = 1` when ScreeningStatus is NOT 'NoMatch' or 'Unknown' (i.e., there is a potential sanctions, PEP, or risk match requiring investigation).

**ScreeningStatus distribution**: NoMatch 99.5% (4.63M), PendingInvestigation 0.36% (17K), PEP 0.01% (498), RiskMatch 0.003% (137), SanctionsMatch 0.0002% (11).

### 2.6 SOF Risk Indicators

**What**: Multiple columns assess each customer's Source of Funds (SOF) risk posture.

| Column | Logic |
|--------|-------|
| `Is_High_Risk_SOF` | Q26_AnswerText IN ('Family financial support', 'Social Security') |
| `Is_SOF_needed` | SOF_Predication != 'Do not check SOF' (from BI_DB_AML_KYC_SOF) |
| `Has_Proof_Of_Income` | Any Proof of Income doc in BackOffice |
| `Has_Proof_Of_Income_FromLastYear` | Proof of Income doc dated within last 12 months |
| `HasSOFLast6Months` | Proof of Income doc dated within last 6 months |

**Is_SOF_needed distribution**: 0 (no SOF needed) 85.2% (3.96M), 1 (SOF needed) 14.2% (661K), NULL 0.6% (26K — no KYC panel record).

### 2.7 Identity Document Expiry Flags

**What**: Identifies customers whose Proof of Identity (POI) or Proof of Address (POA) documents have expired.

**Columns**: `POI_ExpiryDate`, `POA_ExpiryDate`, `Is_POI_ExpiryDate`, `Is_POA_ExpiryDate`

**Rule**: `Is_POI_ExpiryDate = 1` when `POI_ExpiryDate < GETDATE()`. `Is_POA_ExpiryDate = 1` when `POA_ExpiryDate < GETDATE()`.

**Distribution**: Is_POI_ExpiryDate=1: 12.7% (590K), Is_POA_ExpiryDate=1: 23.5% (1.09M). These expired-document flags are inputs to the `Final_Decision` logic in the HR and MR tables (Orange outcome).

### 2.8 Occupation Risk Flag

**What**: Identifies customers in occupations that carry elevated AML/ML risk.

**Rule**: `Is_HighRisk_Occupation = 1` when `Occupation_Answer IN ('None', 'Gambling Industry', 'Gaming/Casino/Card Club', 'Student')`.

### 2.9 High-Risk Payment Method Flag (MOP)

**What**: Detects deposits made via non-standard or higher-risk payment methods (Method of Payment).

**Rule**: `Is_High_MOP_Deposit = 1` when any deposit after 2023-01-01 used a FundingTypeID that is not in the standard set (excludes common card/bank methods). Reflects enhanced scrutiny for unusual funding channels.

### 2.10 Identity Verification (Selfie, VI, BI)

**What**: Documents whether the customer has completed enhanced identity verification steps.

| Column | Source | Logic |
|--------|--------|-------|
| `Has_Selfie` | BackOffice CustomerDocument | Approved selfie or liveness check document |
| `Has_Passed_VI_or_BI` | SolarisBankIdentDb + VideoIdentDb | Passed bank identification (GlobalStatus='successful') OR video identification (Status='Success') |

---

## 3. Query Advisory

### 3.1 This is an ALL-population table — no risk filter

Unlike HR and MR variants, this table includes Medium, Low, and unscored customers. Always apply RiskScoreName filter if you only want High-risk analysis:

```sql
WHERE RiskScoreName = 'High'
```

### 3.2 No Final_Decision column

This table does NOT have `Final_Decision` (Red/Orange/Green). For traffic-light decisions, use `BI_DB_AML_Periodic_Review_HR` or `BI_DB_AML_Periodic_Review_MR`.

### 3.3 ReasonType string matching

`ReasonType` is propagated from `BI_DB_AML_KYC_SOF` verbatim, including its stored spelling errors. Match exactly:

| Intended | Stored |
|----------|--------|
| More than declared deposit | `'More then decleared deposit'` |
| Less than 15% left | `'Less then 15% left'` |
| HNWI | `'HNWI'` |
| Normal | `'Normal'` |

### 3.4 ROUND_ROBIN HEAP — full scan

No hash distribution key. All queries run a full scan. Filter early on high-cardinality columns (Regulation, RiskScoreName, PlayerStatus) to reduce data movement.

### 3.5 Daily refresh, no history

TRUNCATE + INSERT — only today's snapshot. No historical rows. `UpdateDate` is the same for all rows within a daily run.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| T1 | Upstream DWH wiki verbatim copy (Dim_Customer, Dim_Regulation, Dim_Country) or documented BI_DB upstream table |
| T2 | SP code derivation / business flag computed from T1/T3 sources |
| T3 | External raw source (Fivetran GRC, UserApiDB EV, BackOffice docs, external identity DBs) |
| Propagation | ETL metadata |

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 1 | CID | int | T1 | `DWH_dbo.Dim_Customer.RealCID` | Customer ID — platform-internal primary key. Assigned at registration. Universal customer identifier across all DWH tables. (Tier 1 — DWH_dbo.Dim_Customer.RealCID) |
| 2 | GCID | int | T1 | `DWH_dbo.Dim_Customer.GCID` | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — DWH_dbo.Dim_Customer.GCID) |
| 3 | Age | int | T2 | `SP_AML_Periodic_Review, Dim_Customer.BirthDate` | Customer age in years as of SP run date. `DATEDIFF(YEAR, BirthDate, GETDATE())`. May be off by 1 year for customers whose birthday has not yet occurred in the current year. (Tier 2 — SP_AML_Periodic_Review, Dim_Customer.BirthDate) |
| 4 | Age_Group | varchar(250) | T2 | `SP_AML_Periodic_Review CASE on Age` | AML age-band classification: '18-21 Age' (76K, 1.6%), 'Over 75' (29K, 0.6%), 'No Risk Age' (4.54M, 97.7%). (Tier 2 — SP_AML_Periodic_Review CASE on Age) |
| 5 | Original_FTD | datetime | T1 | `DWH_dbo.Dim_Customer.FirstDepositDate` | Date of customer's first deposit. DEFAULT='19000101' sentinel for non-depositors (not present here — population is depositors only). (Tier 1 — DWH_dbo.Dim_Customer.FirstDepositDate) |
| 6 | Regulation | varchar(250) | T1 | `DWH_dbo.Dim_Regulation.Name` | Short code for the regulatory jurisdiction. CySEC (54.2%), FCA (26.5%), FinCEN+FINRA (6.4%), FSA Seychelles (4.6%), ASIC & GAML (4.4%), others. (Tier 1 — DWH_dbo.Dim_Regulation.Name) |
| 7 | Country | varchar(250) | T1 | `DWH_dbo.Dim_Country.Name` | Full country name in English for the customer's country of residence. (Tier 1 — DWH_dbo.Dim_Country.Name) |
| 8 | POB_Country | varchar(250) | T2 | `DWH_dbo.Dim_Customer.CountryOfBirth (resolved)` | Country of birth (resolved to country name). Empty string for many legacy accounts where birth country was not captured. (Tier 2 — DWH_dbo.Dim_Customer, birth country resolved) |
| 9 | aml_compliance_POB | varchar(250) | T3 | `External_Fivetran_google_sheets_grc_list` | AML compliance classification for the customer's birth country from the GRC Google Sheet. NULL or empty when POB_Country is not in the GRC list. (Tier 3 — External_Fivetran_google_sheets_grc_list via POB_Country) |
| 10 | CountryRank | int | T3 | `External_Fivetran_google_sheets_grc_list` | AML risk tier of the customer's country of residence from the GRC list. 0=no tier assigned (98.6%), 1=highest-risk jurisdictions (42 rows), 2–4=intermediate risk tiers. (Tier 3 — External_Fivetran_google_sheets_grc_list) |
| 11 | aml_compliance | nvarchar(500) | T3 | `External_Fivetran_google_sheets_grc_list` | AML compliance status label for the customer's country of residence from the GRC Google Sheet. NULL when country is not in the GRC list. (Tier 3 — External_Fivetran_google_sheets_grc_list via Country) |
| 12 | PlayerStatus | varchar(250) | T1 | `DWH_dbo.Dim_PlayerStatus.Name` | Human-readable account restriction state label. Normal (98.6%), Block Deposit & Trading (0.8%), Trade & MIMO Blocked (0.3%), Warning (0.15%), others. (Tier 1 — DWH_dbo.Dim_PlayerStatus.Name) |
| 13 | Club | varchar(250) | T1 | `DWH_dbo.Dim_PlayerLevel.Name` | Customer experience tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Determines platform features and permissions. (Tier 1 — DWH_dbo.Dim_PlayerLevel.Name) |
| 14 | EvMatchStatusName | nvarchar(500) | T3 | `External_UserApiDB_Ev_CustomerResult` | Enhanced Verification match status name from the latest EV event per GCID. 'None' if no EV performed. (Tier 3 — External_UserApiDB_Ev_CustomerResult) |
| 15 | EvStatusId | int | T3 | `External_UserApiDB_Ev_CustomerResult` | Numeric status code for the latest EV result per GCID. NULL if no EV performed. Requires lookup against EV status dictionary. (Tier 3 — External_UserApiDB_Ev_CustomerResult) |
| 16 | EV_Date | datetime | T3 | `External_UserApiDB_Ev_CustomerResult.OccurredAt` | Timestamp of the most recent Enhanced Verification event per GCID. NULL if no EV performed. (Tier 3 — External_UserApiDB_Ev_CustomerResult.OccurredAt) |
| 17 | ScreeningStatus | varchar(250) | T3 | `External_RiskClassification_dbo_V_RiskClassificationDataLake` | Sanctions and PEP screening result. NoMatch (99.5%), PendingInvestigation (0.36%), PEP (0.01%), RiskMatch (0.003%), SanctionsMatch (0.0002%), Unknown (<0.01%). (Tier 3 — External_RiskClassification_dbo_V_RiskClassificationDataLake) |
| 18 | RiskScoreName | nvarchar(8000) | T3 | `External_RiskClassification_dbo_V_RiskClassificationDataLake` | AML risk score band. Medium (95.3%), High (3.0%), Low (1.5%), NULL/unscored (0.2%). This is the OVERALL AML risk score, not just the screening result. (Tier 3 — External_RiskClassification_dbo_V_RiskClassificationDataLake) |
| 19 | RiskScore_Explanation | nvarchar(8000) | T3 | `External_RiskClassification_dbo_V_RiskClassificationDataLake` | Comma-separated list of risk factors that contributed to the customer's AML risk score (e.g., 'Annual Income,Total Cash And Liquid Assets,Money plan To invest,NFTF'). (Tier 3 — External_RiskClassification_dbo_V_RiskClassificationDataLake) |
| 20 | HasWallet | int | T2 | `DWH_dbo.Dim_Customer.HasWallet` | 1 if customer has an active eToroMoney wallet; 0 otherwise. 12.2% of population (565K) have a wallet. (Tier 2 — DWH_dbo.Dim_Customer.HasWallet) |
| 21 | AccountProgram | nvarchar(500) | T2 | `DWH_dbo.Dim_Customer.AccountProgram` | Payment account program type: NULL=standard account (62.7%), 'iban'=bank-account-linked program (35.3%), 'card'=card-linked program (1.9%). (Tier 2 — DWH_dbo.Dim_Customer.AccountProgram) |
| 22 | IsHighRisk_Screening | int | T2 | `SP_AML_Periodic_Review, External_RiskClassification` | 1 when ScreeningStatus is not 'NoMatch' or 'Unknown' — customer has a potential sanctions, PEP, or risk hit requiring investigation. 0.3% of population (15K). (Tier 2 — SP_AML_Periodic_Review derived from ScreeningStatus) |
| 23 | IsEDD | int | T2 | `DWH_dbo.Dim_Customer.IsEDD` | 1 if the customer is subject to Enhanced Due Diligence. 36.8% of population (1.71M). Regulatory requirement based on risk profile, jurisdiction, or AML flags. (Tier 2 — DWH_dbo.Dim_Customer.IsEDD) |
| 24 | POI_ExpiryDate | datetime | T2 | `DWH_dbo.Dim_Customer.IsIDProofExpiryDate` | Expiry datetime of the customer's Proof of Identity document. NULL if no POI document or expiry date not set. (Tier 2 — DWH_dbo.Dim_Customer.IsIDProofExpiryDate) |
| 25 | POA_ExpiryDate | datetime | T2 | `DWH_dbo.Dim_Customer.IsAddressProofExpiryDate` | Expiry datetime of the customer's Proof of Address document. NULL if no POA document or expiry date not set. (Tier 2 — DWH_dbo.Dim_Customer.IsAddressProofExpiryDate) |
| 26 | Is_POI_ExpiryDate | int | T2 | `SP_AML_Periodic_Review derived from POI_ExpiryDate` | 1 if the customer's Proof of Identity document has expired (POI_ExpiryDate < current date). 12.7% of population (590K). An Orange trigger in the HR/MR Final_Decision logic. (Tier 2 — SP_AML_Periodic_Review derived from POI_ExpiryDate) |
| 27 | Is_POA_ExpiryDate | int | T2 | `SP_AML_Periodic_Review derived from POA_ExpiryDate` | 1 if the customer's Proof of Address document has expired (POA_ExpiryDate < current date). 23.5% of population (1.09M). An Orange trigger in the HR/MR Final_Decision logic. (Tier 2 — SP_AML_Periodic_Review derived from POA_ExpiryDate) |
| 28 | Is_High_Risk_SOF | int | T2 | `SP_AML_Periodic_Review, BI_DB_dbo.BI_DB_KYC_Panel.Q26_AnswerText` | 1 if Q26 (Sources of Funds) answer includes 'Family financial support' or 'Social Security' — high-risk SOF categories. 5.1% of population (248K). (Tier 2 — SP_AML_Periodic_Review derived from BI_DB_dbo.BI_DB_KYC_Panel.Q26_AnswerText) |
| 29 | SOF_Q26_Answer | nvarchar(8000) | T1 | `BI_DB_dbo.BI_DB_KYC_Panel.Q26_AnswerText` | STRING_AGG of all selected Q26 fund source answer texts (multi-select question). Examples: 'Business activities', 'Savings, Salary', 'Family financial support'. NULL if customer has not answered Q26. (Tier 1 — BI_DB_dbo.BI_DB_KYC_Panel.Q26_AnswerText) |
| 30 | Is_High_MOP_Deposit | int | T2 | `SP_AML_Periodic_Review, Fact_CustomerAction.FundingTypeID` | 1 if the customer made any deposit after 2023-01-01 using a non-standard/high-risk payment method (FundingTypeID outside the standard set). 0.45% of population (21K). (Tier 2 — SP_AML_Periodic_Review, DWH_dbo.Fact_CustomerAction) |
| 31 | Occupation_Answer | nvarchar(500) | T1 | `BI_DB_dbo.BI_DB_KYC_Panel.Q18_AnswerText` | Customer's Q18 occupation category text. Examples: 'Finance Industry', 'Transport/Logistics', 'Student', 'None', 'Gambling Industry'. NULL if customer has not answered Q18. (Tier 1 — BI_DB_dbo.BI_DB_KYC_Panel.Q18_AnswerText) |
| 32 | Is_HighRisk_Occupation | int | T2 | `SP_AML_Periodic_Review derived from Occupation_Answer` | 1 if Occupation_Answer IN ('None', 'Gambling Industry', 'Gaming/Casino/Card Club', 'Student') — occupations associated with elevated ML/TF risk. (Tier 2 — SP_AML_Periodic_Review derived from BI_DB_KYC_Panel.Q18_AnswerText) |
| 33 | ReasonType | nvarchar(1000) | T1 | `BI_DB_dbo.BI_DB_AML_KYC_SOF.ReasonType` | SOF reason category passthrough from BI_DB_AML_KYC_SOF. Values contain stored spelling errors — match exactly: 'Normal', 'More then decleared deposit', 'Less then 15% left', 'HNWI'. NULL if customer has no KYC_SOF record. (Tier 1 — BI_DB_dbo.BI_DB_AML_KYC_SOF.ReasonType) |
| 34 | HasBusinessPotential | int | T1 | `BI_DB_dbo.BI_DB_AML_KYC_SOF.HasBusinessPotential` | 1 if ≥85% of the customer's Q14 planned investment ceiling has not yet been deposited — customer has significant investment headroom. (Tier 1 — BI_DB_dbo.BI_DB_AML_KYC_SOF.HasBusinessPotential) |
| 35 | HasSOFLast6Months | int | T1 | `BI_DB_dbo.BI_DB_AML_KYC_SOF.HasSOFLast6Months` | 1 if a qualifying Proof of Income document was submitted by the customer within the last 6 months. Indicates recent SOF documentation is on file. (Tier 1 — BI_DB_dbo.BI_DB_AML_KYC_SOF.HasSOFLast6Months) |
| 36 | Is_SOF_needed | int | T2 | `SP_AML_Periodic_Review derived from BI_DB_AML_KYC_SOF.SOF_Predication` | 1 when SOF_Predication != 'Do not check SOF' (i.e., SOF review is required or recommended for this customer). 14.2% (661K). NULL for 0.6% (26K) with no KYC_SOF record. (Tier 2 — SP_AML_Periodic_Review derived from BI_DB_dbo.BI_DB_AML_KYC_SOF.SOF_Predication) |
| 37 | Planned_Invested_Amount_Q14 | nvarchar(8000) | T1 | `BI_DB_dbo.BI_DB_KYC_Panel.Q14_AnswerText` | Customer's Q14 answer text for planned annual investment amount bracket. Examples: 'Up to $1k', '$1k-$5k', '$20k - $50k', '$50k-$200k', 'Above $1M'. NULL if customer has not answered Q14. (Tier 1 — BI_DB_dbo.BI_DB_KYC_Panel.Q14_AnswerText) |
| 38 | Total_Withdraw | money | T2 | `SP_AML_Periodic_Review, DWH_dbo.Fact_CustomerAction ActionTypeID=8` | All-time total cashout amount in USD (SUM of Fact_CustomerAction.Amount WHERE ActionTypeID=8, WITH NOLOCK). (Tier 2 — SP_AML_Periodic_Review, DWH_dbo.Fact_CustomerAction) |
| 39 | Login_Rank1_2023 | int | T2 | `SP_AML_Periodic_Review, Fact_CustomerAction login events` | Count of login events where the login country (CountryIDByIP) is a Rank-1 AML risk country AND the event occurred after 2023-01-01. 0 for 4.65M customers; 1 for only 558 (0.01%) — a rare but critical AML signal. (Tier 2 — SP_AML_Periodic_Review, DWH_dbo.Fact_CustomerAction login) |
| 40 | Has_Open_AML_SF_Case | int | T2 | `SP_AML_Periodic_Review, BI_DB_dbo.BI_DB_SF_Cases_Panel` | 1 if the customer has an open AML-type Salesforce case. 0.03% of population (1,426 rows). (Tier 2 — SP_AML_Periodic_Review, BI_DB_dbo.BI_DB_SF_Cases_Panel) |
| 41 | Has_Proof_Of_Income | int | T3 | `External_etoro_BackOffice_CustomerDocument` | 1 if a 'Proof of Income' document is on file in BackOffice (DocumentType='Proof of Income' OR SuggestedDocumentType='Proof of Income' for Not Accepted docs). (Tier 3 — External_etoro_BackOffice_CustomerDocument) |
| 42 | Has_Selfie | int | T3 | `External_etoro_BackOffice_CustomerDocument` | 1 if an approved selfie or liveness check document is on file in BackOffice. (Tier 3 — External_etoro_BackOffice_CustomerDocument) |
| 43 | Has_Passed_VI_or_BI | int | T3 | `SolarisBankIdentDb / VideoIdentDb` | 1 if the customer has passed bank identification (SolarisBankIdentDb GlobalStatus='successful') OR video identification (VideoIdentDb Status='Success'). (Tier 3 — SolarisBankIdentDb / VideoIdentDb) |
| 44 | UpdateDate | datetime | Propagation | ETL metadata | SP execution timestamp: `GETDATE()` at INSERT time. All rows in a single daily run share the same UpdateDate. (Propagation) |
| 45 | Has_Proof_Of_Income_FromLastYear | int | T3 | `External_etoro_BackOffice_CustomerDocument` | 1 if a qualifying Proof of Income document was submitted within the last calendar year (DocumentDateAdded >= 1 year ago). Stricter than Has_Proof_Of_Income (any time). (Tier 3 — External_etoro_BackOffice_CustomerDocument) |

**Tier summary**: 9 T1 | 22 T2 | 13 T3 | 1 Propagation

---

## 5. Data Shape and Distributions

| Metric | Value |
|--------|-------|
| Total rows | 4,647,549 (2026-04-12) |
| Distinct customers | 4,647,549 (one row per CID — no duplicates) |
| UpdateDate | 2026-04-12 05:56:23 (single-day snapshot) |
| FTD range | 2007-08-29 to 2026-04-11 |

### RiskScoreName

| Value | Count | % |
|-------|-------|---|
| Medium | 4,430,180 | 95.3% |
| High | 140,145 | 3.0% |
| Low | 68,332 | 1.5% |
| NULL | 8,892 | 0.2% |

### Regulation

| Regulation | Count | % |
|-----------|-------|---|
| CySEC | 2,520,828 | 54.2% |
| FCA | 1,233,055 | 26.5% |
| FinCEN+FINRA | 297,280 | 6.4% |
| FSA Seychelles | 215,684 | 4.6% |
| ASIC & GAML | 202,426 | 4.4% |
| FinCEN | 86,159 | 1.9% |
| FSRA | 76,153 | 1.6% |
| Others | ~15,964 | 0.3% |

### Key AML Risk Indicator Distribution

| Indicator | Flagged (=1) | % |
|-----------|-------------|---|
| IsEDD | 1,711,769 | 36.8% |
| Is_POA_ExpiryDate | 1,092,185 | 23.5% |
| Is_POI_ExpiryDate | 590,437 | 12.7% |
| Is_SOF_needed | 660,578 | 14.2% |
| HasWallet | 565,537 | 12.2% |
| Is_High_Risk_SOF | ~248,432 | 5.3% |
| IsHighRisk_Screening | ~15,064 | 0.3% |
| Is_High_MOP_Deposit | ~20,949 | 0.5% |
| Has_Open_AML_SF_Case | 1,426 | 0.03% |
| Login_Rank1_2023 | 558 | 0.01% |

---

## 6. Companion Tables

| Table | Population | Has Final_Decision |
|-------|-----------|-------------------|
| `BI_DB_AML_Periodic_Review_AR` | ALL depositing VL3 (no risk filter) | No |
| `BI_DB_AML_Periodic_Review_HR` | High Risk, FTD ≤ 1 year | Yes (Red/Orange/Green) |
| `BI_DB_AML_Periodic_Review_MR` | High Risk, FTD ≤ 3 years | Yes (Red/Orange/Green) |

All three tables are generated by `SP_AML_Periodic_Review @Date` using shared temp tables built once and reused across all three outputs.
