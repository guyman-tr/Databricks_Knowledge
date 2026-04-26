# BI_DB_dbo.BI_DB_AMLPeriodicReview_PostReview

> Post-review AML compliance state tracker — one row per customer showing their CURRENT compliance status versus the state frozen at periodic-review time, with 8 delta fields quantifying what was resolved or worsened since the review was triggered.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Primary Source** | BI_DB_dbo.BI_DB_AMLPeriodicReview (latest review per RealCID) + 20+ DWH dims and External tables |
| **Refresh** | Daily (OpsDB Priority 0, SB_Daily) |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Column Count** | 65 |
| **Row Count** | ~1,494,257 (2026-04-12) |
| **Writer SP** | SP_BI_DB_AMLPeriodicReview_PostReview (Author: Pavlina Masoura, 2025-06-17) |
| **Load Pattern** | UPSERT — DELETE WHERE RealCID IN (batch) + INSERT (cumulative; all reviews retained) |
| **Downstream Consumers** | None registered in OpsDB — terminal analytics table |
| **UC Target** | Pending |
| **SP Parameter** | `@Date DATE` |

---

## 1. Business Meaning

`BI_DB_AMLPeriodicReview_PostReview` is the post-review outcome tracker for the AML periodic review programme. Where the parent table `BI_DB_AMLPeriodicReview` records what a customer's compliance situation looked like **at review-due time** (the frozen snapshot), this table records what it looks like **right now** and quantifies the delta.

Each row represents one customer (deduplicated to the latest review per RealCID) and contains three layers of information:

1. **Current-state snapshot** — the same demographic, document, EV, screening, economic profile, deposit, and alert data that the parent table captured at review time, but re-fetched from live sources at `@Date`.
2. **Delta layer (8 `*_StatusChange` fields)** — CASE comparisons between the current-state snapshot and the frozen review-time state, identifying whether each compliance issue was Resolved, worsened (New), unchanged (No Change), or absent (OK/Changed).
3. **Outcome summary** — `ReviewOutcomeChange` (Improved / Worsened / No Change) and `NeedsFollowup` (1 if any outstanding checks remain) for quick triage.

**Business usage**: AML compliance analysts use this table to:
- Identify customers who still require action after their review (`NeedsFollowup = 1`, 64% of the population)
- Prioritise urgent cases (`ReviewOutcomeChange = 'Worsened'`, 17%)
- Track SOF (Source of Funds) provision rates
- Compare `CheckAlertSummary` (what was needed at review) vs `CheckAlertSummaryPostReview` (what is still needed) to measure progress

**Population**: All customers from `BI_DB_AMLPeriodicReview`, selected via `ROW_NUMBER OVER (PARTITION BY RealCID ORDER BY Review_Due_DateID DESC)` — one row per customer representing their most recent review. The parent table spans 573K rows across multiple years; this table has ~1.49M rows because each run upserts fresh data and the cumulative upsert retains all customers, with the table growing as new customers enter the review programme.

---

## 2. Business Logic

### 2.1 Post-Review State Re-computation

The SP re-fetches current-state data at `@Date` using the same 8 compliance check categories as the parent table:

| Check # | Category | Condition |
|---------|----------|-----------|
| 1 | POI expired | Is_POI_Expired=1 AND EvMatchStatusName ≠ 'Verified' |
| 2 | POI missing | POI_ExpiryDate IS NULL AND EvMatchStatusDate IS NULL |
| 3 | POA expired | POA IssueDate > 1 year old AND EvMatchStatusName ≠ 'Verified' |
| 4 | POA missing | POA_ExpiryDate IS NULL AND EvMatchStatusDate IS NULL |
| 5 | Tax country discrepancy | Any TIN country ≠ KYC_Country |
| 6 | EV re-run required | EVReviewPending = 'Re-runEV' |
| 7 | Economic profile pending | EconomicProfileReviewPending = 'Pending' |
| 8 | Screening alert | ScreeningStatus ≠ 'NoMatch' |

`TotalCheckAlertsPostReview` = count of triggered checks (0–8). `NeedsFollowup` = 1 if TotalCheckAlertsPostReview > 0.

### 2.2 EVReviewPending Logic

```
EvMatchStatusDate IS NULL            → 'NotEVVerified'
>3 years old + RiskClassification='Medium' → 'Re-runEV'
>1 year old  + RiskClassification='High'   → 'Re-runEV'
Otherwise                             → 'EV ok'
```

### 2.3 EconomicProfileReviewPending Logic

```
>3 years since KYC update + Medium risk → 'Pending'
>1 year since KYC update  + High risk   → 'Pending'
Otherwise                               → 'Not Pending'
```

### 2.4 StatusChange Fields — Common Pattern

All 8 `*_StatusChange` fields compare the review-time state (`#review_snapshot` from BI_DB_AMLPeriodicReview) against the current state (`#finalreport`):

| Value | Meaning |
|-------|---------|
| `'Resolved'` | Issue was present at review time; no longer present now |
| `'New'` | Issue was absent at review time; now present |
| `'No Change'` | Issue is still present (unchanged) |
| `'OK'` | Issue was absent at both review time and now |

Exception: `Screening_StatusChange` uses `'Changed'` as its else branch (not `'OK'`) — see Section 6.

### 2.5 ReviewOutcomeChange Logic

```sql
CASE
  WHEN TotalCheckAlertsPostReview IS NULL      THEN 'Unknown'
  WHEN TotalCheckAlertsPostReview > TotalCheckAlerts THEN 'Worsened'
  WHEN TotalCheckAlertsPostReview < TotalCheckAlerts THEN 'Improved'
  WHEN TotalCheckAlertsPostReview = TotalCheckAlerts THEN 'No Change'
END
```

Observed distribution: No Change 62%, Improved 21%, Worsened 17%.

### 2.6 SOF (Source of Funds) Tracking

`SOF_Status` is only populated for customers where the original review requested SOF documentation (`CheckAlertSummary LIKE '%request SOF%'`). For these customers:
- `SOF_Status = 'SOF provided'` if SOFProvided = 1 (qualifying document on file)
- `SOF_Status = 'SOF still missing'` if SOFProvided = 0

99.4% of rows have NULL `SOF_Status` (SOF was not requested at their review). Only ~9K customers are actively being tracked for SOF provision.

### 2.7 POA_ExpiryDate — Known Naming Bug

Despite the column name, `POA_ExpiryDate` stores `MAX(IssueDate)` of DocumentTypeID=1 documents (NOT an expiry date). The SP CASE expression is a no-op — both branches return `docs.IssueDate`. `Is_POA_Expired` correctly evaluates `IssueDate < DATEADD(YEAR,-1,GETDATE())` (document is >1 year old). This naming issue is inherited from the parent table.

---

## 3. Query Advisory

- **Primary use case**: Filter `NeedsFollowup = 1` (64% of rows) to get customers requiring compliance action.
- **Triage by outcome**: `WHERE ReviewOutcomeChange = 'Worsened'` for urgent cases; `'Improved'` for sign-off queue.
- **SOF tracking**: `WHERE SOF_Status IS NOT NULL` limits to ~9K customers actively tracked for SOF provision.
- **Do not use `POA_ExpiryDate` as a true expiry date** — it stores the IssueDate. Use `Is_POA_Expired` (1 = document >1 year old) for expiry logic.
- **`CheckAlertSummary` vs `CheckAlertSummaryPostReview`**: the former is the review-time checklist (what was needed); the latter is current-state (what is still needed).
- **ROUND_ROBIN HEAP**: no distribution key. For high-volume filters (NeedsFollowup, Regulation, Screening_StatusChange), these will be full scans. Consider materialising to a temp table when chaining joins.
- **Cumulative table**: ~1.49M rows vs parent table's 573K rows. The table grows as new customers enter the review programme and existing rows are upserted with fresh state.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | bigint | YES | Customer ID — platform-internal primary key matching Dim_Customer. One row per customer (deduplicated from BI_DB_AMLPeriodicReview to the latest review per RealCID via ROW_NUMBER DESC on Review_Due_DateID). (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki → DWH_dbo.Dim_Customer) |
| 2 | FirstDepositDate | date | YES | Date of first deposit. DEFAULT='19000101'. Sourced from Dim_Customer.FirstDepositDate (CustomerFinanceDB FTD pipeline). Used as the anchor for GROUP A 3-year review scheduling. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki → DWH_dbo.Dim_Customer) |
| 3 | KYC_Country_ID | int | YES | Country of residence ID (FK to Dim_Country). Primary KYC jurisdiction country. Determines regulatory framework and AML risk level. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki) |
| 4 | POBCountryID | int | YES | Place of birth country ID. FK to Dim_Country. Added for enhanced KYC cross-border monitoring. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki) |
| 5 | CitizenshipCountryID | int | YES | Country of citizenship ID. FK to Dim_Country. Added 2018 for enhanced KYC. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki) |
| 6 | KYC_Country | varchar(max) | YES | Country of residence name (decoded from KYC_Country_ID via Dim_Country.Name). Primary KYC jurisdiction string label. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_Country) |
| 7 | POBCountry | varchar(max) | YES | Place of birth country name (decoded from POBCountryID via Dim_Country.Name). NULL if POBCountryID not set. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_Country) |
| 8 | CitizenshipCountry | varchar(max) | YES | Country of citizenship name (decoded from CitizenshipCountryID via Dim_Country.Name). NULL if CitizenshipCountryID not set. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_Country) |
| 9 | KYC_Country_Rank | int | YES | AML risk group rank of the KYC country (Dim_Country.RiskGroupID). 0=None (safe), 1=High risk, 2=High risk new clients, 3=FATF high risk, 4=Verified before deposit. Used in RoutineMonitoringRedFlagsHRC checks. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_Country.RiskGroupID) |
| 10 | CitizenshipCountry_Rank | int | YES | AML risk group rank of the citizenship country. Same scale as KYC_Country_Rank. NOTE: column order differs from BI_DB_AMLPeriodicReview (CitizenshipCountry_Rank appears before POBCountry_Rank in DDL). (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_Country.RiskGroupID) |
| 11 | POBCountry_Rank | int | YES | AML risk group rank of the place of birth country. Same scale as KYC_Country_Rank. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_Country.RiskGroupID) |
| 12 | ScreeningStatus | varchar(max) | YES | Compliance screening status text from Dim_ScreeningStatus. Examples: NoMatch, PEP, Adverse Media. Non-NoMatch statuses flag the customer for AML rescreening. Drives Screening_StatusChange delta. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_ScreeningStatus) |
| 13 | PhoneVerified | varchar(max) | YES | Phone verification status text from Dim_PhoneVerified. Indicates whether the customer's phone number has been verified. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_PhoneVerified) |
| 14 | EvMatchStatusName | varchar(max) | YES | Electronic verification (EV) match status from Dim_EvMatchStatus. Values: None (31%), Verified (57%), NotVerified (8%), PartiallyVerified (4%). EV-verified customers skip document expiry checks. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_EvMatchStatus) |
| 15 | RiskClassificationName | varchar(max) | YES | AML risk classification name from Dim_RiskClassification. Values: Medium (84%), High (16%), Low (<1%). Controls review frequency (High=annual, Medium=3yr) and EV/EP staleness thresholds. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via Dim_RiskClassification) |
| 16 | VerificationLevelID | int | YES | KYC verification level from Dim_Customer. Always 3 in this table (population filter: VerificationLevelID=3 = fully KYC-verified). (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki; always 3 here) |
| 17 | PlayerStatus | varchar(max) | YES | Compliance and trading account status text from Dim_PlayerStatus. Current-state re-fetch at @Date. Distribution: Normal 86%, Blocked 8%, Block Deposit & Trading 5%. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_PlayerStatus) |
| 18 | PlayerStatusReason | varchar(max) | YES | Reason code text for current PlayerStatus from Dim_PlayerStatusReasons. NULL for Normal/Active status records. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_PlayerStatusReasons) |
| 19 | PlayerStatusSubReason | varchar(max) | YES | Sub-reason text for PlayerStatus from Dim_PlayerStatusSubReasons. Added 2022. NULL for most records. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_PlayerStatusSubReasons) |
| 20 | Club | varchar(max) | YES | eToro Club loyalty tier from Dim_PlayerLevel (PlayerLevelID). Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_PlayerLevel) |
| 21 | Regulation | varchar(max) | YES | Regulatory entity text from Dim_Regulation. Distribution: CySEC 51%, FCA 29%, FSA Seychelles 7%, ASIC&GAML 6%, FinCEN+FINRA 4%. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki via Dim_Regulation) |
| 22 | POI_ExpiryDate | date | YES | Proof of Identity document expiry date from Dim_Customer.IsIDProofExpiryDate. NULL if no POI document on file. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via Dim_Customer.IsIDProofExpiryDate) |
| 23 | POA_ExpiryDate | date | YES | MISLEADING NAME: stores MAX(IssueDate) of the most recent POA document (DocumentTypeID=1 from BackOffice), NOT a true expiry date. The SP CASE expression is a no-op — both branches return IssueDate. Use Is_POA_Expired (1 = IssueDate >1 year old) for expiry logic. NULL if no POA document on file. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via External_etoro_BackOffice_CustomerDocument; naming bug inherited from parent table) |
| 24 | Is_POI_Expired | int | YES | 1 if POI_ExpiryDate < GETDATE() (ID proof is expired); 0 otherwise; NULL if POI_ExpiryDate IS NULL. Drives POI_Expired_StatusChange delta. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 25 | Is_POA_Expired | int | YES | 1 if POA IssueDate (stored in POA_ExpiryDate) < DATEADD(YEAR,-1,GETDATE()) — document is more than 1 year old. 0 otherwise. Distribution: 37% expired. Drives POA_Expired_StatusChange delta. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview, 2025-10-30 policy update) |
| 26 | POI_IsMissing | int | YES | 1 if POI_ExpiryDate IS NULL AND EvMatchStatusDate IS NULL (no identity proof and no electronic verification on file). 0 otherwise. Drives POI_Missing_StatusChange delta. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 27 | POA_IsMissing | int | YES | 1 if POA_ExpiryDate IS NULL AND EvMatchStatusDate IS NULL (no address proof and no electronic verification on file). 0 otherwise. Drives POA_Missing_StatusChange delta. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 28 | TaxCountry | varchar(max) | YES | Comma-separated list of up to 3 TIN (Tax Identification Number) country names from UserApiDB.ExtendedUserField (FieldId=6). Represents where the customer declares tax residency. NULL if no TIN country declared. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via External_UserApiDB_Customer_ExtendedUserField) |
| 29 | TaxCountryDiscrepancy | int | YES | 1 if any TIN country in TaxCountry differs from KYC_Country; 0 if all match or no TIN declared. Contributes to check item #5 (TaxCountryDiscrepancy=1 triggers a POA action item). (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 30 | EVStatus | varchar(max) | YES | Electronic verification status from Dim_EvMatchStatus. Values: Verified, None, NotVerified, PartiallyVerified. Functional duplicate of EvMatchStatusName (col 14) — both set to pop.EvMatchStatusName in the SP. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview; duplicate of col 14) |
| 31 | SOFProvided | int | YES | 1 if the customer has a qualifying Source of Funds document on file: DocumentTypeID=7 (Proof of Income) with approved classification (payslip, tax declaration, bank statement) OR DocumentTypeID=8 (Proof of MOP) with bank statement classification. 0 otherwise. Used to compute SOF_Status. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via External_etoro_BackOffice_CustomerDocument #SOF temp table) |
| 32 | LastEVDate | date | YES | Date of the most recent electronic verification run from BI_DB_CIDFirstDates.EvMatchStatusDate. NULL if no EV has been performed. Used to compute EVReviewPending staleness. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via BI_DB_CIDFirstDates) |
| 33 | EVReviewPending | varchar(max) | YES | EV staleness assessment: 'NotEVVerified' (no EV date), 'Re-runEV' (>3yr for Medium Risk or >1yr for High Risk), 'EV ok' (within validity window). Drives EV_StatusChange delta and check item #6. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 34 | KYC_LastUpdateDate | date | YES | Date of the most recent KYC questionnaire update from BI_DB_KYC_Panel. Used for EconomicProfileReviewPending staleness check. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via BI_DB_KYC_Panel) |
| 35 | EconomicProfileReviewPending | varchar(max) | YES | Economic profile staleness: 'Pending' if KYC update >3yr old for Medium Risk or >1yr for High Risk; 'Not Pending' otherwise. Drives EP_Review_StatusChange delta and check item #7. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 36 | TotalDepositsLifetime | float | YES | Cumulative total approved deposit amount (USD) from Fact_BillingDeposit (PaymentStatusID=2), all time up to @Date. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via Fact_BillingDeposit) |
| 37 | TotalDepositsCurrentYear | float | YES | Total approved deposits from Jan 1 of the current year. NOTE: uses full calendar year (no upper bound at @Date) — includes deposits after @Date in the same year. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via Fact_BillingDeposit) |
| 38 | TotalDeposits12Months | float | YES | Total approved deposits in the trailing 12 months from @Date. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via Fact_BillingDeposit) |
| 39 | TotalDeposits6Months | float | YES | Total approved deposits in the trailing 6 months from @Date. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via Fact_BillingDeposit) |
| 40 | LastEPUpdateDate | date | YES | Duplicate of KYC_LastUpdateDate (col 34). The SP assigns kyc.KYC_LastUpdateDate to both columns. (Tier 2 — SP duplicate of KYC_LastUpdateDate; see col 34) |
| 41 | CheckAlertSummary | varchar(max) | YES | Review-time compliance checklist (action items required at review-due time), copied verbatim from BI_DB_AMLPeriodicReview snapshot. Contrast with CheckAlertSummaryPostReview to see what has been resolved. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki, col 57; passthrough from review snapshot) |
| 42 | TotalCheckAlerts | int | YES | Review-time check count from BI_DB_AMLPeriodicReview snapshot. The baseline for ReviewOutcomeChange comparison. Compare against TotalCheckAlertsPostReview to measure compliance progress. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki, col 58; passthrough from review snapshot) |
| 43 | CheckAlertSummaryPostReview | varchar(max) | YES | Current-state compliance checklist (re-computed at @Date). Same 8-item structure as CheckAlertSummary but reflects today's compliance situation. Prefix: 'Check Alerts:\n' followed by outstanding items. NULL-ish prefix only when all checks pass. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 44 | TotalCheckAlertsPostReview | int | YES | Count of outstanding check items in current state (0–8). Drives NeedsFollowup (>0 → 1) and ReviewOutcomeChange comparison. 64% of customers have ≥1 check remaining post-review. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 45 | RiskAlertSummary | varchar(max) | YES | STRING_AGG of RAMT (Risk Alert Management Tool) alerts for this customer with modification date after Review_Due_Date. Pipe-delimited: 'AlertType | StatusReason | Status | AlertCount'. NULL if no RAMT alerts after review date. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via BI_DB_RiskAlertManagementTool) |
| 46 | LatestRiskAlertDateReview | date | YES | MAX(ModificationDate) of RAMT alerts for this customer after Review_Due_Date. NULL if no RAMT alerts after review date. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via BI_DB_RiskAlertManagementTool) |
| 47 | BIAMLAlerts | varchar(max) | YES | STRING_AGG of BI AML alerts from BI_DB_AML_BI_Alerts_New after Review_Due_Date. Pipe-delimited: 'AlertType | Count'. NULL if no BI alerts after review date. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via BI_DB_AML_BI_Alerts_New) |
| 48 | LatestBIAlertDate | date | YES | MAX(AlertDate) from BI_DB_AML_BI_Alerts_New for this customer across all time (not filtered to post-review period, unlike BIAMLAlerts). NULL if no BI AML alerts. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via BI_DB_AML_BI_Alerts_New; all-time MAX) |
| 49 | APU_Gaps_Summary | varchar(max) | YES | STRING_AGG of APU (compliance interaction) records from External_ComplianceStateDB_Compliance_CustomerInteractions after Review_Due_Date. Format per entry: 'APU: DisplayName | Completed: date | LastEval: date'. NULL if no APU records. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via External_ComplianceStateDB) |
| 50 | Review_Due_Date | date | YES | Original review trigger date for this customer's periodic review, read from BI_DB_AMLPeriodicReview (MAX Review_Due_DateID → date). For GROUP A: FirstDepositDate + 3n years. For GROUP B: reactivation date. For GROUP C/D: risk/screening change date or annual anniversary. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki, col 3) |
| 51 | Review_Due_DateID | int | YES | YYYYMMDD integer representation of Review_Due_Date. Sourced from BI_DB_AMLPeriodicReview. (Tier 1 — BI_DB_dbo.BI_DB_AMLPeriodicReview wiki, col 4) |
| 52 | POI_Expired_StatusChange | varchar(max) | YES | Delta: Is_POI_Expired at review time vs current state. Values: 'Resolved' (was expired, now valid), 'New' (was valid, now expired), 'No Change' (still expired), 'OK' (absent at both times). (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 53 | POA_Expired_StatusChange | varchar(max) | YES | Delta: Is_POA_Expired at review time vs current state. Same value set as POI_Expired_StatusChange. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 54 | POA_Updated_StatusChange | varchar(max) | YES | Tracks POA document refresh post-review: 'POA was not updated' if POA_ExpiryDate (IssueDate) is unchanged AND CheckAlertSummary contained a POA action item; 'OK' otherwise. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 55 | POI_Missing_StatusChange | varchar(max) | YES | Delta: POI_IsMissing at review time vs current state. Values: 'Resolved' (missing, now provided), 'New' (was present, now missing), 'No Change' (still missing), 'OK'. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 56 | POA_Missing_StatusChange | varchar(max) | YES | Delta: POA_IsMissing at review time vs current state. Same value set as POI_Missing_StatusChange. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 57 | EV_StatusChange | varchar(max) | YES | Delta: EVReviewPending at review time vs current state. Values: 'Resolved' (Re-runEV → EV ok), 'New' (EV ok → Re-runEV), 'No Change' (still Re-runEV), 'OK'. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 58 | EP_Review_StatusChange | varchar(max) | YES | Delta: EconomicProfileReviewPending at review time vs current state. Values: 'Resolved' (Pending → Not Pending), 'New' (Not Pending → Pending), 'No Change' (still Pending), 'OK'. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 59 | Screening_StatusChange | varchar(max) | YES | Delta: ScreeningStatus at review time vs current state. Values: 'Resolved' (non-NoMatch → NoMatch), 'New' (NoMatch → non-NoMatch), 'No Change' (same non-NoMatch), 'Changed' (different non-NoMatch status — e.g., PEP → Sanctions). NOTE: uses 'Changed' not 'OK' as the else branch, unlike the other 7 StatusChange fields. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 60 | SOF_Status | varchar(max) | YES | SOF provision outcome. NULL (99.4%) unless CheckAlertSummary at review time contained 'request SOF'. When applicable: 'SOF still missing' (SOFProvided=0) or 'SOF provided' (SOFProvided=1). Only ~9K customers have a non-NULL value. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 61 | NeedsFollowup | int | YES | 1 if TotalCheckAlertsPostReview > 0 (at least one outstanding compliance check item); 0 if all checks are clear. 64% of customers = 1. Primary operational filter for AML compliance action queues. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 62 | ReviewOutcomeChange | varchar(max) | YES | Overall compliance trajectory vs review-time baseline: 'Worsened' (post > pre alert count), 'Improved' (post < pre), 'No Change' (equal), 'Unknown' (TotalCheckAlertsPostReview IS NULL). Distribution: No Change 62%, Improved 21%, Worsened 17%. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview) |
| 63 | HasSOFDocument | int | YES | 1 if customer has a qualifying SOF document on file (DocumentTypeID=7 Proof of Income with payslip/tax declaration/bank statement classification, OR DocumentTypeID=8 Proof of MOP with bank statement classification). Computed unconditionally in the final SP stage — unlike SOFProvided which is conditional. (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via #SOF temp table) |
| 64 | HasSelfieDocument | int | YES | 1 if customer has a selfie/liveness photograph document on file from BackOffice. Sourced from #selfie temp table (qualifying document type IDs for selfie/liveness documents). (Tier 2 — SP_BI_DB_AMLPeriodicReview_PostReview via External_etoro_BackOffice_CustomerDocument #selfie) |
| 65 | UpdateDate | datetime | NO | ETL load timestamp — set to GETDATE() at SP execution time. Not a business event timestamp. 5 distinct batch dates observed: 2025-08-26 to 2026-04-12. (Tier 5 — ETL metadata propagation blacklist) |

---

## 5. Lineage

### 5.1 Sources

| Source | Schema | Role |
|--------|--------|------|
| BI_DB_AMLPeriodicReview | BI_DB_dbo | Population base (latest review per RealCID); pre-review snapshot for StatusChange baseline |
| BI_DB_AML_BI_Alerts_New | BI_DB_dbo | BI AML alerts post-review date |
| BI_DB_CIDFirstDates | BI_DB_dbo | EV verification date (LastEVDate, EVReviewPending) |
| BI_DB_KYC_Panel | BI_DB_dbo | KYC questionnaire dates and answers |
| BI_DB_RiskAlertManagementTool | BI_DB_dbo | RAMT alerts post-review date |
| Dim_Customer | DWH_dbo | Customer master (demographics, verification attributes, IDs) |
| Dim_Country (×3) | DWH_dbo | Country name + RiskGroupID for KYC / POB / Citizenship |
| Dim_EvMatchStatus | DWH_dbo | EV match status label |
| Dim_ScreeningStatus | DWH_dbo | Screening status label |
| Dim_PhoneVerified | DWH_dbo | Phone verification status label |
| Dim_RiskClassification | DWH_dbo | AML risk classification label |
| Dim_PlayerStatus | DWH_dbo | Account restriction status label |
| Dim_PlayerStatusReasons | DWH_dbo | Status reason label |
| Dim_PlayerStatusSubReasons | DWH_dbo | Status sub-reason label |
| Dim_PlayerLevel | DWH_dbo | Club loyalty tier label |
| Dim_Regulation | DWH_dbo | Regulatory entity label |
| Fact_BillingDeposit | DWH_dbo | Deposit aggregations (4 time windows) |
| External_etoro_BackOffice_CustomerDocument | BI_DB_dbo | Document records (POA, SOF, selfie) |
| External_UserApiDB_Customer_ExtendedUserField | BI_DB_dbo | TIN/tax country declarations (FieldId=6) |
| External_ComplianceStateDB_Compliance_CustomerInteractions | BI_DB_dbo | APU gap interactions |

### 5.2 ETL Pipeline

```
BI_DB_AMLPeriodicReview
  ROW_NUMBER OVER (PARTITION BY RealCID ORDER BY Review_Due_DateID DESC)
       |
       v
 #populationfinal  (one row per customer = latest review)
       |
       +-- JOIN Dim_Customer + Dim_Country×3 + 8 dimension tables
       +-- JOIN External_etoro_BackOffice_CustomerDocument
       |    → #CustomerDocuments (DocumentTypeID=1 POA MAX IssueDate)
       |    → #docs (POI_ExpiryDate, POA_ExpiryDate=IssueDate, expiry flags)
       |    → #DOCS (all qualifying documents for SOF/selfie matching)
       |    → #SOF    (TypeID=7/8 with qualifying classifications)
       |    → #selfie (selfie document TypeIDs)
       +-- JOIN External_UserApiDB_ExtendedUserField (FieldId=6) → #tax/#taxcountry
       +-- JOIN BI_DB_CIDFirstDates                              → #evdate
       +-- JOIN BI_DB_KYC_Panel                                  → KYC dates
       +-- JOIN Fact_BillingDeposit (4 time windows)             → #TotalDeposits*
       +-- JOIN BI_DB_RiskAlertManagementTool (> Review_Due_Date)
       +-- JOIN BI_DB_AML_BI_Alerts_New (> Review_Due_Date)
       +-- JOIN External_ComplianceStateDB_CustomerInteractions  → #APU_Summary
       |
       v
 #finalreport  (current-state: all 65 columns minus delta/outcome fields)
       + Compute CheckAlertSummaryPostReview (8-item checklist, CASE build)
       + Compute TotalCheckAlertsPostReview  (SUM of 8 binary check flags)
       |
 JOIN #review_snapshot (BI_DB_AMLPeriodicReview as at review-time baseline)
       |
       v
 #delta_report  (8 × *_StatusChange CASE comparisons, SOF_Status)
       |
 JOIN #finalreportwithdelta:
       + NeedsFollowup     = CASE WHEN TotalCheckAlertsPostReview > 0 THEN 1 ELSE 0
       + ReviewOutcomeChange = CASE TotalCheckAlertsPostReview vs TotalCheckAlerts
       + HasSOFDocument    from #SOF JOIN
       + HasSelfieDocument from #selfie JOIN
       + UpdateDate        = GETDATE()
       |
       v
 DELETE FROM BI_DB_AMLPeriodicReview_PostReview
        WHERE RealCID IN (SELECT RealCID FROM #finalreportwithdelta)
 INSERT INTO BI_DB_AMLPeriodicReview_PostReview  ← cumulative upsert
```

---

## 6. Data Quality Notes

| Issue | Severity | Detail |
|-------|----------|--------|
| `POA_ExpiryDate` stores IssueDate | HIGH | SP CASE is a no-op — both branches return docs.IssueDate. Naming is misleading. `Is_POA_Expired` correctly computes >1yr old. Do not use POA_ExpiryDate as a true expiry date. |
| `EVStatus` duplicates `EvMatchStatusName` | LOW | Cols 14 and 30 are both set to pop.EvMatchStatusName. Intentional for UI convenience or legacy artifact — confirm with AML team. |
| `LastEPUpdateDate` duplicates `KYC_LastUpdateDate` | LOW | Cols 34 and 40 both = kyc.KYC_LastUpdateDate. No functional difference. |
| `TotalDepositsCurrentYear` uses full calendar year | INFO | No upper bound at @Date — includes deposits after @Date in the same year. |
| `LatestBIAlertDate` not restricted to post-review | INFO | Takes MAX(AlertDate) all-time from BI_DB_AML_BI_Alerts_New, unlike BIAMLAlerts which filters > Review_Due_Date. |
| `Screening_StatusChange` uses 'Changed' not 'OK' | INFO | Intentional design difference from the other 7 StatusChange fields. Any ScreeningStatus transition not matching Resolved/New/NoChange returns 'Changed'. |

---

## 7. Relationships

| Related Table | Join Key | Relationship |
|--------------|----------|-------------|
| `BI_DB_dbo.BI_DB_AMLPeriodicReview` | RealCID | Parent table — provides review-time snapshot and population base |
| `DWH_dbo.Dim_Customer` | RealCID | Customer master — demographics and compliance verification attributes |
| `DWH_dbo.Dim_Country` | KYC_Country_ID / POBCountryID / CitizenshipCountryID | Country names and AML risk ranks (3-way join) |
| `BI_DB_dbo.BI_DB_AML_BI_Alerts_New` | RealCID / CID | BI AML alert dependency — also feeds BIAMLAlerts column |

---

## 8. Atlassian

No direct Confluence documentation found for this specific table. Related context:
- The AML Periodic Review programme is documented in the Data Confluence space (DATA) under AML compliance monitoring.
- SP author: Pavlina Masoura (2025-06-17, latest update 2026-01-27). For business logic questions, contact the AML/Compliance data team.
- The parent table `BI_DB_AMLPeriodicReview` should be reviewed alongside this table for full context on review trigger logic and the six alert dimensions.
