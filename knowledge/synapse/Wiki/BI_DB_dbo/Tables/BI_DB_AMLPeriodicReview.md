# BI_DB_dbo.BI_DB_AMLPeriodicReview

> Cumulative daily AML periodic review workbook for all verified eToro depositors — triggering scheduled KYC reviews (3-year Medium Risk, annual High Risk/PEP, dormancy reactivation) and computing six alert dimensions across PII changes, login anomalies, high-risk transactions, document validity, economic profile, and jurisdiction risk.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Sources** | DWH_dbo.Dim_Customer + Fact_CustomerAction + Fact_SnapshotCustomer + 25+ source tables (see Section 5) |
| **Refresh** | Daily (OpsDB P0) — DELETE+INSERT per review date |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Writer SP** | SP_BI_AMLPeriodicReview |
| | |
| **UC Target** | pending |

---

## 1. Business Meaning

`BI_DB_dbo.BI_DB_AMLPeriodicReview` is the primary AML periodic review workbook. Each row represents an eToro customer who has been flagged for a scheduled KYC review on a given date, along with a full snapshot of their KYC status, documents, economic profile, and six computed AML alert dimensions. The table is consumed by AML analysts to prioritize and work through review queues.

The SP `SP_BI_AMLPeriodicReview` (Author: Pavlina Masoura, 2025-06-17, @Date parameter) runs daily to populate reviews triggered for that day:

**Four review trigger groups (AlertCategory)**:
| Group | Trigger | Review Interval |
|-------|---------|----------------|
| GROUP A | 3-year anniversary of FirstDepositDate for Medium Risk customers (RiskClassificationID=1) | Every 3 years |
| GROUP B | Customer reactivates after 12 months of inactivity (dormancy + reactivation) | Event-triggered |
| GROUP C | High Risk customers (RiskClassificationID=0) — annual review + day of risk classification change | Annual |
| GROUP D | Customers who became PEPs (ScreeningStatusID=3) — annual review + day of screening change | Annual/event |

**ETL mode**: Unlike most BI_DB tables, this uses DELETE+INSERT (not TRUNCATE). The SP deletes rows for Review_Due_Date=@Date then inserts fresh data for that date. This means the table **accumulates historical review records** — 573,216 rows as of 2026-04-23 spanning all past review dates. RealCID can appear multiple times across different Review_Due_Dates and AlertCategories.

**De-duplication logic**: The SP reads the table itself to avoid re-inserting a review entry if the customer already has a recent entry for the same AlertCategory (GROUP A: within 3 years; GROUP B/C/D: within 12 months).

The companion table `BI_DB_AMLPeriodicReview_PostReview` records the outcome of completed reviews (SOF provision, status changes, follow-up requirements).

---

## 2. Business Logic

### 2.1 Population Base

All customers meeting: IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3, PlayerStatusID NOT IN (2,4), PendingClosureStatusID NOT IN (2,3). This is the KYC-complete active depositor universe used across multiple AML tables.

### 2.2 Review Trigger Logic

**GROUP A** (#pop): `CAST(DATEADD(YEAR, 3*N, FirstDepositDate) AS DATE) = @Date` for N=1..10 AND `RiskClassificationID=1` (Medium). Generates reviews on exact 3-year anniversaries of the first deposit.

**GROUP B** (#dormant_alert): Customer made a transaction (PositionOpen/Close/Deposit/Cashout/Withdraw) on @Date after having NO activity for the preceding 12 months AND was not a new depositor (FirstDepositDate < 1 year ago) AND is not already in GROUP A.

**GROUP C** (#riskclassificationchangeonalertdate): `RiskClassificationID=0` (High) customers whose risk changed to High on @Date, OR whose annual anniversary of the High classification change matches @Date.

**GROUP D** (#screeningstatuschangeonalertdate): ScreeningStatusID=3 (PEP) customers whose PEP screening change occurred on @Date, OR whose annual PEP anniversary matches @Date.

### 2.3 Six AML Alert Dimensions

| Column | Alert Type | Logic Summary |
|--------|-----------|---------------|
| MaterialChangePII | PII data change | Name, address, email, phone changed within 3-year lookback window |
| MaterialChangeLogins | Geographic login anomaly | ≥25% of login days from non-KYC country (excl. EEA) AND ≥30 days, OR ≥25% VPN logins AND ≥30 VPN days |
| MaterialChangeMIMO | Cross-border transactions | Deposits or withdrawals from non-KYC, non-POB, non-citizenship country (excl. EEA) |
| RoutineMonitoringRedFlagsOutdatedData | Document/KYC validity | Expired/missing POI or POA (and not EV-verified) OR Tax country ≠ KYC country |
| RoutineMonitoringRedFlagsEP | Economic profile | Deposits > declared income+assets; suspicious occupation; deposits > planned investment |
| RoutineMonitoringRedFlagsHRC | High-risk jurisdiction | Deposits, logins, or country change to RiskGroupID IN (1,2) countries |

All six flags are 0/1 binary. TotalAlerts = sum of all six flags.

### 2.4 Economic Profile Evaluation

Sources from `BI_DB_KYC_Panel` (KYC questionnaire answers):
- Q10 → AnnualIncome (income bracket → USD midpoint)
- Q11 → TotalCashAndLiquidAssets (cash bracket → USD midpoint)
- Q14 → PlannedInvestmentAmount
- Q15 → SourcesOfIncome (text)
- Q18 → Occupation (text)

Alert conditions:
- `SourceOfIncomeAlert`: Q15 contains Inheritance/Other/Lottery/Pension/etc. AND TotalDepositsLifetime > $50K
- `OccupationAlert`: Q18 = Unemployed/Student/None AND TotalDepositsLifetime > $50K
- `DeclaredIncomeANDAssetsAlert`: TotalDepositsCurrentYear > AnnualIncome + TotalCashAndLiquidAssets
- `PlannedInvestmentAlert`: TotalDepositsCurrentYear > PlannedInvestmentAmount AND > $10K

### 2.5 EVReviewPending and EconomicProfileReviewPending

Staleness checks based on risk classification:
- **Medium Risk**: EV > 3 years old → 'Re-runEV'; KYC > 3 years old → EP 'Pending'
- **High Risk**: EV > 1 year old → 'Re-runEV'; KYC > 1 year old → EP 'Pending'
- Otherwise: 'EV ok' / 'Not Pending'

---

## 3. Query Advisory

- **Table is cumulative**: Filter on `Review_Due_Date` to get a specific day's reviews. A single RealCID may appear multiple times across dates/groups.
- **573,216 rows**: Represents multi-year historical accumulation. Always date-filter for performance.
- **AlertCategory values**: Exactly four string values — 'GROUP A: Periodic Review for Medium Risk Classification', 'GROUP B: Dormancy and Reactivation', 'GROUP C: Scheduled Reviews for High Risk Classification', 'GROUP D: Scheduled Reviews for PEPs'.
- **TotalAlerts vs TotalCheckAlerts**: TotalAlerts (0-6) counts the six high-level alert flags. TotalCheckAlerts is more granular (counts individual check items within each flag category, e.g., each expired document counts separately).
- **ROUND_ROBIN HEAP**: No optimal join key. For historical analysis, date-filtering or RealCID filtering will result in full scans — pre-filter by Review_Due_Date range.
- **BI_DB_AMLPeriodicReview_PostReview**: Join on RealCID to get review outcomes.

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | RealCID | bigint | YES | Customer ID (RealCID) — platform-internal primary key. Assigned at registration. May appear multiple times across different Review_Due_Dates and AlertCategories. (Tier 1 — DWH_dbo.Dim_Customer wiki, originally Customer.CustomerStatic) |
| 2 | FirstDepositDate | date | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. Used as the anchor date for GROUP A 3-year review scheduling. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 3 | Review_Due_Date | date | YES | The review trigger date — the date this customer's review is due. For GROUP A: FirstDepositDate + 3n years. For GROUP B: @Date (day of reactivation). For GROUP C/D: day of classification/screening change or its annual anniversary. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 4 | Review_Due_DateID | int | YES | Integer representation of Review_Due_Date in YYYYMMDD format. Used for OpsDB date-range operations. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 5 | KYC_Country_ID | int | YES | Country of residence ID (CountryID from Dim_Customer). FK to Dictionary.Country. Determines regulatory framework. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 6 | POBCountryID | int | YES | Place of birth country ID. FK to Dictionary.Country. Added for enhanced KYC. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 7 | CitizenshipCountryID | int | YES | Country of citizenship ID. FK to Dictionary.Country. Added 2018 for enhanced KYC. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 8 | KYC_Country | nvarchar(max) | YES | Country of residence name from Dim_Country. The primary KYC country for this customer. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_Country JOIN) |
| 9 | POBCountry | nvarchar(max) | YES | Place of birth country name from Dim_Country (POBCountryID). May differ from KYC_Country. NULL if POBCountryID not set. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_Country LEFT JOIN) |
| 10 | CitizenshipCountry | nvarchar(max) | YES | Country of citizenship name from Dim_Country. May differ from KYC_Country. NULL if CitizenshipCountryID not set. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_Country LEFT JOIN) |
| 11 | KYC_Country_Rank | int | YES | Risk group rank of the KYC country from Dim_Country.RiskGroupID. Lower values = higher risk (1,2 = high-risk jurisdictions). Used in RoutineMonitoringRedFlagsHRC alert logic. (Tier 2 — SP_BI_AMLPeriodicReview via Dim_Country.RiskGroupID) |
| 12 | POBCountry_Rank | int | YES | Risk group rank of the place of birth country. Used in high-risk jurisdiction alert checks. (Tier 2 — SP_BI_AMLPeriodicReview via Dim_Country.RiskGroupID) |
| 13 | CitizenshipCountry_Rank | int | YES | Risk group rank of the citizenship country. Used in high-risk jurisdiction alert checks. (Tier 2 — SP_BI_AMLPeriodicReview via Dim_Country.RiskGroupID) |
| 14 | ScreeningStatus | nvarchar(max) | YES | Compliance screening status text name from Dim_ScreeningStatus. Updated from ScreeningService. GROUP D triggers when ScreeningStatusID=3 (PEP). Sample: NoMatch, PEP, Adverse Media. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_ScreeningStatus) |
| 15 | PhoneVerified | nvarchar(max) | YES | Phone verification status text from Dim_PhoneVerified (PhoneVerifiedID). Indicates whether the customer's phone number has been verified. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_PhoneVerified) |
| 16 | EvMatchStatusName | nvarchar(max) | YES | Electronic verification match status name from Dim_EvMatchStatus (EvMatchStatus). Decision from automated identity verification vendors (Onfido, Au10tix). Sample: Verified, NotVerified, NULL. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_EvMatchStatus) |
| 17 | AlertCategory | nvarchar(max) | YES | Review trigger group: 'GROUP A: Periodic Review for Medium Risk Classification', 'GROUP B: Dormancy and Reactivation', 'GROUP C: Scheduled Reviews for High Risk Classification', 'GROUP D: Scheduled Reviews for PEPs'. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 18 | VerificationLevelID | int | YES | KYC verification level. Always 3 in this table (population filter: VerificationLevelID=3 = fully verified). (Tier 1 — DWH_dbo.Dim_Customer wiki; always 3 here) |
| 19 | PlayerStatus | nvarchar(max) | YES | Compliance and trading account status text from Dim_PlayerStatus. Population excludes PlayerStatusID IN (2,4). (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_PlayerStatus) |
| 20 | PlayerStatusReason | nvarchar(max) | YES | Reason code text for current PlayerStatus from Dim_PlayerStatusReasons. NULL if status is Normal/Active. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_PlayerStatusReasons) |
| 21 | PlayerStatusSubReason | nvarchar(max) | YES | Sub-reason text for PlayerStatus from Dim_PlayerStatusSubReasons. Added 2022. NULL for most records. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_PlayerStatusSubReasons) |
| 22 | Club | nvarchar(max) | YES | Customer experience/permission level text from Dim_PlayerLevel (PlayerLevelID). Sample: Bronze, Silver, Platinum, Platinum Plus. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_PlayerLevel) |
| 23 | RiskClassification | nvarchar(max) | YES | AML risk classification name from Dim_RiskClassification. Sample: Medium (GROUP A), High (GROUP C). NULL for some records (risk classification not assigned). (Tier 2 — SP_BI_AMLPeriodicReview via Dim_RiskClassification) |
| 24 | Regulation | nvarchar(max) | YES | Regulatory entity text from Dim_Regulation (RegulationID). Sample: CySEC, FCA, FinCEN+FINRA. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_Regulation) |
| 25 | POI_ExpiryDate | date | YES | Proof of Identity document expiry date from Dim_Customer.IsIDProofExpiryDate. NULL if no POI document on file. (Tier 2 — SP_BI_AMLPeriodicReview via Dim_Customer.IsIDProofExpiryDate) |
| 26 | POA_ExpiryDate | date | YES | Proof of Address document issue date from External_etoro_BackOffice_CustomerDocument (DocumentTypeID=1, MAX IssueDate). The POA is considered expired if IssueDate < 1 year ago AND the customer has flagged activity. NULL if no POA document. (Tier 2 — SP_BI_AMLPeriodicReview, new POA expiry policy 2025-10-30) |
| 27 | Is_POI_Expired | int | YES | 1 if POI_ExpiryDate < today (ID proof is expired); 0 otherwise. NULL when POI_ExpiryDate is NULL. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 28 | Is_POA_Expired | int | YES | 1 if POA_ExpiryDate (issue date) < 1 year ago AND customer has flagged activity (FlaggedCustomers); 0 otherwise. (Tier 2 — SP_BI_AMLPeriodicReview, 2025-10-30 policy update) |
| 29 | POI_IsMissing | int | YES | 1 if POI_ExpiryDate IS NULL AND no EV date exists (EvMatchStatusDate IS NULL); 0 otherwise. Indicates no identity proof on file and no electronic verification. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 30 | POA_IsMissing | int | YES | 1 if POA_ExpiryDate IS NULL AND no EV date exists; 0 otherwise. Indicates no address proof and no electronic verification. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 31 | TaxCountry | nvarchar(max) | YES | Comma-separated list of up to 3 TIN (Tax Identification Number) country names from External_UserApiDB_Customer_ExtendedUserField (FieldId=6). Represents where the customer declares tax residency. NULL if no TIN country declared. (Tier 2 — SP_BI_AMLPeriodicReview, UserApiDB) |
| 32 | LastUpdatedDateTaxCountry | date | YES | Date of the most recent TIN/tax country update in UserApiDB. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 33 | TaxCountryDiscrepancy | int | YES | 1 if any TIN country differs from KYC_Country; 0 if all TIN countries match. Used in RoutineMonitoringRedFlagsOutdatedData alert. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 34 | EVStatus | nvarchar(max) | YES | Electronic verification status name from Dim_EvMatchStatus (fresh lookup at #finalreport stage). Equivalent to EvMatchStatusName but re-joined at a later SP step. Sample: Verified, NotVerified. (Tier 2 — SP_BI_AMLPeriodicReview, same source as EvMatchStatusName) |
| 35 | LastEVDate | date | YES | Date of the most recent electronic verification run from BI_DB_CIDFirstDates.EvMatchStatusDate. NULL if no EV has been performed. (Tier 2 — SP_BI_AMLPeriodicReview via BI_DB_CIDFirstDates) |
| 36 | EVReviewPending | nvarchar(max) | YES | EV staleness assessment: 'Re-runEV' (EV > 3yr for Medium or > 1yr for High Risk), 'NotEVVerified' (no EV date), 'EV ok' (within validity window). (Tier 2 — SP_BI_AMLPeriodicReview, staleness logic) |
| 37 | KYC_LastUpdateDate | date | YES | Date of the most recent KYC questionnaire update from BI_DB_KYC_Panel.KYC_LastUpdateDate. Used for EconomicProfileReviewPending staleness check. (Tier 2 — SP_BI_AMLPeriodicReview via BI_DB_KYC_Panel) |
| 38 | EconomicProfileReviewPending | nvarchar(max) | YES | Economic profile staleness: 'Pending' if KYC update > 3yr old for Medium Risk or > 1yr for High Risk; 'Not Pending' otherwise. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 39 | TotalDepositsLifetime | money | YES | Cumulative total approved deposit amount (USD) from Fact_BillingDeposit (PaymentStatusID=2), all time up to @Date. (Tier 2 — SP_BI_AMLPeriodicReview via Fact_BillingDeposit) |
| 40 | TotalDepositsCurrentYear | money | YES | Total approved deposits from Jan 1 of the current year to @Date. (Tier 2 — SP_BI_AMLPeriodicReview via Fact_BillingDeposit) |
| 41 | TotalDeposits12Months | money | YES | Total approved deposits in the trailing 12 months from @Date. (Tier 2 — SP_BI_AMLPeriodicReview via Fact_BillingDeposit) |
| 42 | TotalDeposits6Months | money | YES | Total approved deposits in the trailing 6 months from @Date. (Tier 2 — SP_BI_AMLPeriodicReview via Fact_BillingDeposit) |
| 43 | LastEPUpdateDate | date | YES | Duplicate of KYC_LastUpdateDate — SP assigns kyc.KYC_LastUpdateDate to both columns. (Tier 2 — SP duplicate of KYC_LastUpdateDate) |
| 44 | SourcesOfIncome | nvarchar(max) | YES | Customer's declared sources of income text (KYC questionnaire Q15). Free-text answer. Examples: Employment, Pension, Savings, Inheritance. (Tier 2 — SP_BI_AMLPeriodicReview via BI_DB_KYC_Panel Q15) |
| 45 | SourceOfIncomeAlert | nvarchar(max) | YES | 'Alert' if SourcesOfIncome includes Inheritance/Lottery/Pension/Other/etc. AND TotalDepositsLifetime > $50K; 'No Alert' otherwise. Contributes to RoutineMonitoringRedFlagsEP. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 46 | Occupation | nvarchar(max) | YES | Customer's declared occupation text (KYC questionnaire Q18). Free-text answer. (Tier 2 — SP_BI_AMLPeriodicReview via BI_DB_KYC_Panel Q18) |
| 47 | OccupationAlert | nvarchar(max) | YES | 'Alert' if Occupation contains None/Unemployed/Student AND TotalDepositsLifetime > $50K; 'No Alert' otherwise. Contributes to RoutineMonitoringRedFlagsEP. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 48 | AnnualIncome | money | YES | Customer's declared annual income (KYC Q10 bracket midpoint in USD). Converted from text range (e.g., '$50K-100K' → 100000). NULL if no Q10 answer. (Tier 2 — SP_BI_AMLPeriodicReview via BI_DB_KYC_Panel Q10) |
| 49 | TotalCashAndLiquidAssets | money | YES | Customer's declared total cash and liquid assets (KYC Q11 bracket midpoint in USD). NULL if no Q11 answer. (Tier 2 — SP_BI_AMLPeriodicReview via BI_DB_KYC_Panel Q11) |
| 50 | DeclaredAmountforIncomeAssets | money | YES | AnnualIncome + TotalCashAndLiquidAssets — the total declared financial resources. Compared against TotalDepositsCurrentYear for DeclaredIncomeANDAssetsAlert. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 51 | DeclaredIncomeANDAssetsAlert | nvarchar(max) | YES | 'Alert' if TotalDepositsCurrentYear > DeclaredAmountforIncomeAssets; 'No Alert' otherwise. Deposits exceed declared financial capacity. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 52 | PlannedInvestmentAmount | money | YES | Customer's planned investment amount for the year (KYC Q14 bracket midpoint in USD). NULL if no Q14 answer. (Tier 2 — SP_BI_AMLPeriodicReview via BI_DB_KYC_Panel Q14) |
| 53 | PlannedInvestmentAlert | nvarchar(max) | YES | 'Alert' if TotalDepositsCurrentYear > PlannedInvestmentAmount AND TotalDepositsCurrentYear > $10K AND PlannedInvestmentAmount > 0; 'No Alert' otherwise. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 54 | LastScreeningStatusChange | date | YES | Date of the most recent screening status change from External_ScreeningService_Screening_UserScreening. NULL if no recent change. (Tier 2 — SP_BI_AMLPeriodicReview via External_ScreeningService) |
| 55 | TotalAlerts | int | YES | Sum of the six binary alert flags (MaterialChangePII + MaterialChangeLogins + MaterialChangeMIMO + RoutineMonitoringRedFlagsOutdatedData + RoutineMonitoringRedFlagsEP + RoutineMonitoringRedFlagsHRC). Range: 0–6. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 56 | AlertsSummary | nvarchar(max) | YES | Human-readable concatenated summary of triggered alert categories. Starts with 'Total Alerts: N' followed by bullet lines for each triggered flag. AML analyst-facing text. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 57 | CheckAlertSummary | nvarchar(max) | YES | Detailed action-oriented review checklist — specific documents or actions required for each alert. E.g. 'Request new POI as part of full re-KYC', 'Re-run EV required'. AML analyst action guide. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 58 | TotalCheckAlerts | int | YES | Count of specific check items (more granular than TotalAlerts). Counts individual sub-checks: each expired document, each EV issue, each EP flag separately. Range: 0+. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 59 | RiskAlertSummary | nvarchar(max) | YES | STRING_AGG of RAMT (Risk Alert Management Tool) alerts for this customer — AlertType, StatusReason, Status, AlertCount. Pipe-delimited. NULL if no RAMT alerts. Source: BI_DB_RiskAlertManagementTool. (Tier 2 — SP_BI_AMLPeriodicReview via BI_DB_RiskAlertManagementTool) |
| 60 | LatestRiskAlertDateReview | datetime | YES | Date of the most recent RAMT alert modification for this customer. (Tier 2 — SP_BI_AMLPeriodicReview via BI_DB_RiskAlertManagementTool) |
| 61 | BIAMLAlerts | nvarchar(max) | YES | STRING_AGG of BI AML alerts for this customer from BI_DB_AML_BI_Alerts_New — AlertType and count. Pipe-delimited. NULL if no BI AML alerts. (Tier 2 — SP_BI_AMLPeriodicReview via BI_DB_AML_BI_Alerts_New) |
| 62 | LatestBIAlertDate | datetime | YES | Date of the most recent BI AML alert for this customer from BI_DB_AML_BI_Alerts_New. (Tier 2 — SP_BI_AMLPeriodicReview via BI_DB_AML_BI_Alerts_New) |
| 63 | APU_Gaps_Summary | nvarchar(max) | YES | STRING_AGG of APU (AML/compliance interaction) records from External_ComplianceStateDB_Compliance_CustomerInteractions. Each line: 'APU: DisplayName | Completed: date | LastEval: date'. NULL if no APU records. (Tier 2 — SP_BI_AMLPeriodicReview via External_ComplianceStateDB) |
| 64 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() by SP_BI_AMLPeriodicReview. Does NOT reflect production event time. (Tier 5 — ETL metadata propagation) |
| 65 | MaterialChangePII | varchar(max) | YES | Binary flag (0/1): 1 if customer had a material change in PII (name, address, city, zip, email, or phone) within the 3-year lookback window. Source: DWH_dbo.Fact_SnapshotCustomer historical delta. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 66 | MaterialChangeLogins | varchar(max) | YES | Binary flag (0/1): 1 if ≥25% of login days used a non-KYC country IP (excl. EEA) with ≥30 qualifying days, OR ≥25% VPN/proxy logins with ≥30 VPN days. Uses Fact_CustomerAction (ActionTypeID=14 Login). (Tier 2 — SP_BI_AMLPeriodicReview) |
| 67 | MaterialChangeMIMO | varchar(max) | YES | Binary flag (0/1): 1 if any deposits (Fact_BillingDeposit) or withdrawals (Fact_BillingWithdraw) originated from a non-KYC, non-POB, non-citizenship country that is not in the EEA list. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 68 | RoutineMonitoringRedFlagsOutdatedData | varchar(max) | YES | Binary flag (0/1): 1 if (expired/missing POI or POA AND EV not Verified) OR tax country ≠ KYC country. Triggers 'Outdated or inconsistent client data' alert. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 69 | RoutineMonitoringRedFlagsEP | varchar(max) | YES | Binary flag (0/1): 1 if any economic profile violation — deposits > declared income/assets, unusual source of income, suspicious occupation + activity, or deposits > planned investment. (Tier 2 — SP_BI_AMLPeriodicReview) |
| 70 | RoutineMonitoringRedFlagsHRC | varchar(max) | YES | Binary flag (0/1): 1 if customer had deposits, logins, or country changes involving a RiskGroupID IN (1,2) country (high-risk jurisdiction) within 3-year lookback. (Tier 2 — SP_BI_AMLPeriodicReview) |

---

## 5. Lineage

### 5.1 Production Sources (Key)

| Synapse Column Group | Source | Notes |
|---------------------|--------|-------|
| RealCID, FirstDepositDate, country IDs, PlayerStatus, VerificationLevelID, HasWallet, ScreeningStatus, PhoneVerified, EvMatchStatusName | DWH_dbo.Dim_Customer | Base population |
| KYC_Country / POBCountry / CitizenshipCountry names, Ranks | DWH_dbo.Dim_Country (×3) | LEFT JOINs on Country/POB/Citizenship IDs |
| Regulation | DWH_dbo.Dim_Regulation | JOIN on RegulationID |
| PlayerStatus text, Reason, SubReason | DWH_dbo.Dim_PlayerStatus/Reasons/SubReasons | JOINs |
| Club | DWH_dbo.Dim_PlayerLevel | JOIN on PlayerLevelID |
| RiskClassification | DWH_dbo.Dim_RiskClassification | JOIN on RiskClassificationID |
| EvMatchStatusName, EVStatus | DWH_dbo.Dim_EvMatchStatus | JOIN on EvMatchStatus |
| AlertCategory GROUP A trigger | DWH_dbo.Dim_Customer.FirstDepositDate | 3n-year rolling window |
| AlertCategory GROUP B trigger | DWH_dbo.Fact_CustomerAction | Dormancy/reactivation detection |
| AlertCategory GROUP C trigger | DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_RiskClassification | RiskClassification change history |
| AlertCategory GROUP D trigger | BI_DB_dbo.External_ScreeningService_Screening_UserScreening | PEP screening change date |
| MaterialChangePII | DWH_dbo.Fact_SnapshotCustomer | PII field delta via LAG window functions |
| MaterialChangeLogins | DWH_dbo.Fact_CustomerAction (ActionTypeID=14) | Login country analysis vs KYC country |
| MaterialChangeMIMO | DWH_dbo.Fact_BillingDeposit + Fact_BillingWithdraw | Country mismatch on payment instruments |
| POI_ExpiryDate, Is_POI_Expired | DWH_dbo.Dim_Customer.IsIDProofExpiryDate | Passthrough |
| POA_ExpiryDate, Is_POA_Expired | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument (DocumentTypeID=1) | MAX IssueDate |
| TaxCountry, TaxCountryDiscrepancy | BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField (FieldId=6) | TIN entries |
| EVStatus, LastEVDate, EVReviewPending | BI_DB_dbo.BI_DB_CIDFirstDates + Dim_EvMatchStatus | EV date + staleness logic |
| KYC answers (income, occupation, etc.) | BI_DB_dbo.BI_DB_KYC_Panel | Q10/Q11/Q14/Q15/Q18 |
| Deposit totals | DWH_dbo.Fact_BillingDeposit (PaymentStatusID=2) | Date-bounded SUMs |
| RiskAlertSummary | BI_DB_dbo.BI_DB_RiskAlertManagementTool | RAMT alerts aggregation |
| BIAMLAlerts | BI_DB_dbo.BI_DB_AML_BI_Alerts_New | BI AML alerts aggregation |
| APU_Gaps_Summary | BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerInteractions | APU interaction records |
| UpdateDate | — | GETDATE() |

### 5.2 ETL Pipeline

```
[Population Triggers]
DWH_dbo.Dim_Customer (VerificationLevelID=3, active depositor)
  + Fact_SnapshotCustomer (GROUP C risk history)
  + Fact_CustomerAction (GROUP B dormancy, logins, deposits)
  + External_ScreeningService (GROUP D PEP history)
    → #populationfinal (4 review groups, UNION)

[Alert Computation — 25+ source tables]
#populationfinal + Fact_CustomerAction + Fact_BillingDeposit/Withdraw
  + CustomerDocument + UserApiDB + KYC_Panel + BI_DB_CIDFirstDates
  + RAMT + BI_DB_AML_BI_Alerts_New + ComplianceStateDB
    → #populationfinalwithalerts (6 binary alert flags)
    → #finalreport (full 70-column result set)

[Deduplication — self-reference]
BI_DB_dbo.BI_DB_AMLPeriodicReview (own table)
    → exclude reviews already logged within 12m/3yr window
    → #populationfinal_deduped

[Write]
DELETE FROM BI_DB_AMLPeriodicReview WHERE Review_Due_Date = @Date
INSERT INTO BI_DB_AMLPeriodicReview SELECT FROM #finalreport
(cumulative, ROUND_ROBIN HEAP — 573,216 rows as of 2026-04-23)
```

---

## 6. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| BI_DB_dbo.BI_DB_AMLPeriodicReview_PostReview | RealCID + ReviewDate | Companion: review outcomes (SOF status, status changes) |
| DWH_dbo.Dim_Customer | RealCID | Source of all customer attributes |
| BI_DB_dbo.BI_DB_KYC_Panel | RealCID | Source of economic profile Q&A answers |
| BI_DB_dbo.BI_DB_RiskAlertManagementTool | RealCID | Source of RiskAlertSummary |
| BI_DB_dbo.BI_DB_AML_BI_Alerts_New | RealCID (as CID) | Source of BIAMLAlerts |
| BI_DB_dbo.BI_DB_CIDFirstDates | RealCID (as CID) | Source of EV date |

---

## 7. Sample Queries

```sql
-- Today's pending reviews (most recent batch)
SELECT RealCID, AlertCategory, KYC_Country, RiskClassification,
       Regulation, TotalAlerts, TotalCheckAlerts
FROM [BI_DB_dbo].[BI_DB_AMLPeriodicReview]
WHERE Review_Due_Date = CAST(GETDATE() AS DATE)
ORDER BY TotalAlerts DESC;

-- High-alert customers requiring immediate review
SELECT RealCID, AlertCategory, KYC_Country, ScreeningStatus,
       TotalAlerts, AlertsSummary, CheckAlertSummary
FROM [BI_DB_dbo].[BI_DB_AMLPeriodicReview]
WHERE Review_Due_Date >= DATEADD(DAY, -30, GETDATE())
  AND TotalAlerts >= 3
ORDER BY TotalAlerts DESC, Review_Due_Date DESC;

-- Volume by AlertCategory (recent 90 days)
SELECT AlertCategory, COUNT(*) AS ReviewCount,
       AVG(CAST(TotalAlerts AS FLOAT)) AS AvgAlerts
FROM [BI_DB_dbo].[BI_DB_AMLPeriodicReview]
WHERE Review_Due_Date >= DATEADD(DAY, -90, GETDATE())
GROUP BY AlertCategory
ORDER BY ReviewCount DESC;

-- PEP customers with outstanding EV review
SELECT RealCID, KYC_Country, ScreeningStatus, EVReviewPending,
       LastEVDate, RiskClassification
FROM [BI_DB_dbo].[BI_DB_AMLPeriodicReview]
WHERE AlertCategory LIKE 'GROUP D%'
  AND EVReviewPending IN ('Re-runEV', 'NotEVVerified');
```

---

## 8. Atlassian Sources

No Confluence pages identified for this specific table. Consult the DATA space in Confluence for AML periodic review process documentation, risk classification policies, and PEP screening procedures.

---

*Tier breakdown: RealCID/FirstDepositDate/KYC_Country_ID/POBCountryID/CitizenshipCountryID/KYC_Country/POBCountry/CitizenshipCountry/ScreeningStatus/PhoneVerified/EvMatchStatusName/VerificationLevelID/PlayerStatus/PlayerStatusReason/PlayerStatusSubReason/Club/Regulation (Tier 1 — DWH_dbo.Dim_Customer wiki) | AlertCategory/Review_Due_Date/Review_Due_DateID/KYC_Country_Rank/POBCountry_Rank/CitizenshipCountry_Rank/RiskClassification/POI fields/POA fields/TaxCountry fields/EVStatus/EVReviewPending/EconomicProfileReviewPending/KYC answers/deposit totals/all alert flags/summaries/RiskAlertSummary/BIAMLAlerts/APU_Gaps_Summary (Tier 2 — SP_BI_AMLPeriodicReview) | UpdateDate (Tier 5 — ETL metadata)*
*Quality score: 8.5/10 (Phase 16 adversarial evaluation, 2026-04-23)*
