# BI_DB_dbo.BI_DB_OPS_MastersAndSubAccounts_AlignmentMonitoringReport

> 44K-row compliance monitoring table tracking master-sub account relationships (20.3K masters, 23.7K sub-accounts) for KYC/AML alignment. Combines KYC questionnaire answers (Q2-Q32), customer PII, compliance attributes (verification level, regulation, screening, risk classification, player status), and financial aggregations (deposits, compensations, withdrawals, redeems, pending withdrawals). Daily TRUNCATE+INSERT via SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport. Only IsValidCustomer=1, PlayerStatusID NOT IN (2,4), VL IN (2,3).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Key Identifier** | CID (not enforced -- no PK in DDL) |
| **Production Source** | SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport (Pavlina Masoura, 2025-04-14) |
| **Refresh** | Daily, TRUNCATE+INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | ~44K (20.3K masters, 23.7K sub-accounts) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Copy Strategy** | N/A |

---

## 1. Business Meaning

`BI_DB_OPS_MastersAndSubAccounts_AlignmentMonitoringReport` is a daily compliance monitoring table that enables operations to compare KYC questionnaire answers, financial activity, and compliance attributes between master accounts and their sub-accounts. The goal is to detect misalignment -- where a sub-account's KYC profile (risk tolerance, income, trading experience) significantly differs from its controlling master account, potentially indicating regulatory evasion or identity inconsistency.

Each row represents one customer account (either master or sub-account). Master accounts appear as rows where CID=MasterAccountCID; sub-accounts appear where CID!=MasterAccountCID. Both are linked via MasterAccountCID.

**Population**:
- Sourced from `External_etoro_BackOffice_Customer` where `MasterAccountCID IS NOT NULL AND <> 0`
- Both master and sub must be IsValidCustomer=1, PlayerStatusID NOT IN (2=Blocked, 4=Blocked Upon Request), VerificationLevelID IN (2,3), PlayerLevelID<>4 (excludes internal/PI accounts)
- Employee accounts excluded (per change history 2025-11-10)

**Data includes**: 11 KYC questionnaire question-answer pairs (Q2, Q3, Q5, Q8, Q9, Q10, Q11, Q14, Q15, Q18, Q26) from BI_DB_KYC_Panel + 3 additional answers (Q12, Q32, Q150) from V_CustomerAnswers, PII (name, address, DOB, gender, phone, country, POB, citizenship), compliance attributes (VL, risk classification, regulation, screening, pending closure, player status, account type, risk status), and financial aggregations (total deposits, compensations, combined deposits+compensations, lifetime redeems, total withdrawals, pending withdrawals, selfie document status).

---

## 2. Business Logic

### 2.1 Master-Sub Account Relationship

**What**: Identifies master accounts and their sub-accounts from BackOffice.Customer.
**Columns Involved**: CID, MasterAccountCID, AccountType
**Rules**:
- UNION ALL of two SELECTs: first pulls MasterAccountCID as both CID and MasterAccountCID (Master rows), second pulls CID with its MasterAccountCID (SubAccount rows when CID != MasterAccountCID)
- AccountType = 'Master' when CID = MasterAccountCID, 'SubAccount' otherwise
- Both parties must pass all filters (IsValidCustomer, PlayerStatus, VL, PlayerLevel)

### 2.2 KYC Questionnaire Alignment

**What**: Captures KYC questionnaire answers for master-sub comparison.
**Columns Involved**: Q2_Experience through Q32_AnswerText
**Rules**:
- Q2 (Experience), Q3 (Trading Knowledge), Q5 (Strategy), Q8 (Purpose), Q9 (Risk/Reward), Q10 (Income), Q11 (Liquid Assets), Q14 (Investment Amount), Q15 (Income Sources), Q18 (Occupation), Q26 (Funds Sources) -- from BI_DB_KYC_Panel via LEFT JOIN on RealCID
- Q32 (PEP/MM Question) -- from both KYC_Panel (Q32_PEP_MM_Question) and V_CustomerAnswers (Q32_AnswerText, latest per GCID)
- Q150 and Q12 -- from V_CustomerAnswers (latest answer per GCID via DENSE_RANK)

### 2.3 Financial Aggregations

**What**: Computes lifetime financial metrics per customer.
**Columns Involved**: TotalDeposits, TotalCompensation, TotalAmountDepositsAndCompensations, TotalRedeemsLifetime, TotalWithdraws, TotalPendingWithdraws
**Rules**:
- TotalDeposits: SUM(AmountUSD) from Fact_BillingDeposit WHERE PaymentStatusID=2 (approved)
- TotalCompensation: SUM(Amount) from Fact_CustomerAction WHERE ActionTypeID=36 AND Amount>0 (positive compensations)
- TotalAmountDepositsAndCompensations: COALESCE(TotalDeposits,0) + COALESCE(TotalCompensation,0)
- TotalRedeemsLifetime: SUM(AmountOnClose) from Fact_BillingRedeem WHERE RedeemStatusID=8 (TransactionDone)
- TotalWithdraws: SUM(Amount_WithdrawToFunding) from Fact_BillingWithdraw WHERE CashoutStatusID_Funding=3, excluding FundingTypeID_Funding=27 (eToroCryptoWallet)
- TotalPendingWithdraws: SUM(Amount_Withdraw) from recent Fact_BillingWithdraw (last 1 day, or 3 days on Mondays) excluding terminal statuses (3=Processed, 4=Canceled, 0=N/A, 7=Rejected, 8=RejectedByProvider, 13=Failed)

### 2.4 Selfie Document Check

**What**: Checks whether customer has selfie-type verification documents.
**Columns Involved**: HasSelfie
**Rules**:
- 1 when DocumentTypeID IN (15=Selfie, 18=SelfieLiveliness, 23=SelfieMotion) exists in BackOffice.CustomerDocumentToDocumentType
- 0 otherwise

### 2.5 Date Tracking

**What**: Tracks when compliance status changes occurred.
**Columns Involved**: PendingClosureDate, ScreeningDate
**Rules**:
- PendingClosureDate: MIN date from Fact_SnapshotCustomer + Dim_Range where PendingClosureStatusID matches current
- ScreeningDate: MIN(BeginTime) from ScreeningService_Screening_UserScreening where ScreeningStatusID matches current

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN HEAP**: No distribution key. With 44K rows, full table scan is fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Compare master vs sub KYC answers | Self-JOIN on MasterAccountCID comparing Q2-Q18 answers |
| Find sub-accounts with different risk profile than master | JOIN master.Q9 != sub.Q9 OR master.Q10 != sub.Q10 |
| Master accounts with highest sub-account counts | GROUP BY MasterAccountCID with COUNT WHERE AccountType='SubAccount' |
| Compliance gaps | WHERE ScreeningStatus = 'PendingReview' OR PendingClosureStatusID > 1 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Self-JOIN | m.MasterAccountCID = s.MasterAccountCID AND m.AccountType='Master' AND s.AccountType='SubAccount' | Master-sub comparison |
| DWH_dbo.Dim_Customer | dc.RealCID = rpt.CID | Full customer profile |

### 3.4 Gotchas

- **PlayerStatus has trailing spaces**: Use `RTRIM(PlayerStatus)` or `LIKE 'Blocked%'`.
- **TotalDeposits can be NULL**: LEFT JOIN means customers without deposits have NULL TotalDeposits. Use ISNULL for aggregations.
- **KYC answers are sparse**: Many Q columns will be NULL if the customer hasn't completed the questionnaire.
- **Q26/Q32/Q150/Q12 added later**: These columns (added 2025-11-18) may be NULL for older snapshots.
- **Name is PII**: `FirstName + ' ' + LastName` concatenation -- handle as PII.
- **AccountType logic has bug**: The Master SELECT uses `CASE WHEN bc.MasterAccountCID = bc.MasterAccountCID` which is always true -- all rows from the first SELECT are 'Master'. This is intentional (first SELECT only pulls MasterAccountCID as CID).
- **PendingWithdraws window varies**: Uses 1-day window normally, but 3-day window on Mondays to capture Friday+weekend pending withdrawals.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 1 | Verbatim from upstream wiki (production source documented) | Upstream dimension/fact wiki |
| Tier 2 | Derived from SP code analysis | SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | bigint | YES | Customer ID -- platform-internal primary key. For master accounts, equals MasterAccountCID. For sub-accounts, the sub-account's own RealCID. (Tier 1 -- Customer.CustomerStatic) |
| 2 | MasterAccountCID | bigint | YES | The master account CID that controls this account. From External_etoro_BackOffice_Customer.MasterAccountCID. For masters, equals CID. For sub-accounts, references the controlling master. (Tier 2 -- SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport) |
| 3 | AccountType | nvarchar(max) | YES | Account classification: 'Master' when CID=MasterAccountCID, 'SubAccount' otherwise. ETL-computed via CASE expression. (Tier 2 -- SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport) |
| 4 | TotalDeposits | numeric(38,6) | YES | Lifetime total approved deposits in USD. SUM(AmountUSD) from Fact_BillingDeposit WHERE PaymentStatusID=2. NULL if no deposits. (Tier 2 -- SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport) |
| 5 | Q2_Experience | nvarchar(max) | YES | KYC questionnaire Q2 -- customer's self-reported trading experience level. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 6 | Q2_AnswerText | nvarchar(max) | YES | KYC questionnaire Q2 -- full answer text for trading experience. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 7 | Q3_Trading_Knowledge | nvarchar(max) | YES | KYC questionnaire Q3 -- trading knowledge self-assessment. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 8 | Q3_AnswerText | nvarchar(max) | YES | KYC questionnaire Q3 -- full answer text for trading knowledge. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 9 | Q5_Trading_Strategy | nvarchar(max) | YES | KYC questionnaire Q5 -- preferred trading strategy. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 10 | Q5_AnswerText | nvarchar(max) | YES | KYC questionnaire Q5 -- full answer text for trading strategy. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 11 | Q8_Trading_Primary_Purpose | nvarchar(max) | YES | KYC questionnaire Q8 -- primary purpose of trading. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 12 | Q8_AnswerText | nvarchar(max) | YES | KYC questionnaire Q8 -- full answer text for trading purpose. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 13 | Q9_Risk_Reward_Scenario | nvarchar(max) | YES | KYC questionnaire Q9 -- risk/reward tolerance scenario answer. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 14 | Q9_AnswerText | nvarchar(max) | YES | KYC questionnaire Q9 -- full answer text for risk/reward. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 15 | Q10_Annual_Income | nvarchar(max) | YES | KYC questionnaire Q10 -- annual income range. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 16 | Q10_AnswerText | nvarchar(max) | YES | KYC questionnaire Q10 -- full answer text for annual income. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 17 | Q11_Liquid_Assets | nvarchar(max) | YES | KYC questionnaire Q11 -- liquid assets range. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 18 | Q11_AnswerText | nvarchar(max) | YES | KYC questionnaire Q11 -- full answer text for liquid assets. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 19 | Q14_Planned_Invested_Amount | nvarchar(max) | YES | KYC questionnaire Q14 -- planned investment amount. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 20 | Q14_AnswerText | nvarchar(max) | YES | KYC questionnaire Q14 -- full answer text for planned investment. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 21 | Q15_Sources_of_Income | nvarchar(max) | YES | KYC questionnaire Q15 -- sources of income. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 22 | Q15_AnswerText | nvarchar(max) | YES | KYC questionnaire Q15 -- full answer text for income sources. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 23 | Q18_Occupation | nvarchar(max) | YES | KYC questionnaire Q18 -- customer's occupation. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 24 | Q18_AnswerText | nvarchar(max) | YES | KYC questionnaire Q18 -- full answer text for occupation. From BI_DB_KYC_Panel. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 25 | Name | nvarchar(max) | YES | Full customer name. ETL-computed as FirstName + ' ' + LastName from Dim_Customer. PII field. (Tier 2 -- SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport) |
| 26 | Address | nvarchar(max) | YES | Street address in Unicode. PII field. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 27 | BirthDate | date | YES | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. PII field. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 28 | Gender | nvarchar(10) | YES | Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. PII field. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 29 | Country | nvarchar(max) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via Dim_Customer.CountryID. (Tier 1 -- Dictionary.Country) |
| 30 | POB | nvarchar(max) | YES | Place of birth country name in English. Dim-lookup passthrough from Dim_Country.Name via Dim_Customer.POBCountryID. (Tier 1 -- Dictionary.Country) |
| 31 | Citizenship | nvarchar(max) | YES | Citizenship country name in English. Dim-lookup passthrough from Dim_Country.Name via Dim_Customer.CitizenshipCountryID. (Tier 1 -- Dictionary.Country) |
| 32 | Phone | nvarchar(50) | YES | Phone number from production Customer.CustomerStatic. PII field. Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 33 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values in this table: 2=intermediate, 3=fully verified (filtered to IN (2,3) by SP). Default=0. Passthrough from Dim_Customer. (Tier 1 -- BackOffice.Customer) |
| 34 | RiskClassificationName | nvarchar(max) | YES | Operational risk tier label. Dim-lookup passthrough from Dim_RiskClassification.RiskClassificationName via Dim_Customer.RiskClassificationID. (Tier 2 -- Dim_RiskClassification) |
| 35 | DesignatedRegulation | nvarchar(max) | YES | Short code for the designated regulation. Values match production Dictionary.Regulation.Name. Dim-lookup passthrough from Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID. (Tier 1 -- Dictionary.Regulation) |
| 36 | Regulation | nvarchar(max) | YES | Short code for the regulation. Used in analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup passthrough from Dim_Regulation.Name via Dim_Customer.RegulationID. (Tier 1 -- Dictionary.Regulation) |
| 37 | ScreeningStatus | nvarchar(max) | YES | Screening status label. Dim-lookup passthrough from Dim_ScreeningStatus.Name via Dim_Customer.ScreeningStatusID. (Tier 2 -- Dim_ScreeningStatus) |
| 38 | PendingClosureStatusName | nvarchar(max) | YES | Pending closure status label. Dim-lookup passthrough from Dim_PendingClosureStatus.PendingClosureStatusName via Dim_Customer.PendingClosureStatusID. (Tier 2 -- Dim_PendingClosureStatus) |
| 39 | PendingClosureStatusID | int | YES | Status in the pending closure workflow. Default=1 (no pending closure). Passthrough from Dim_Customer. (Tier 1 -- Customer.CustomerStatic) |
| 40 | ScreeningStatusID | int | YES | Compliance screening status ID. Updated from ScreeningService. Passthrough from Dim_Customer. (Tier 2 -- SP_Dim_Customer) |
| 41 | TotalCompensation | numeric(38,6) | YES | Lifetime total positive compensation amount. SUM(Amount) from Fact_CustomerAction WHERE ActionTypeID=36 AND Amount>0. NULL if no compensations. (Tier 2 -- SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport) |
| 42 | TotalAmountDepositsAndCompensations | numeric(38,6) | YES | Combined total of deposits and compensations. ETL-computed as COALESCE(TotalDeposits,0) + COALESCE(TotalCompensation,0). (Tier 2 -- SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport) |
| 43 | TotalRedeemsLifetime | numeric(38,6) | YES | Lifetime total redeems (completed). SUM(AmountOnClose) from Fact_BillingRedeem WHERE RedeemStatusID=8 (TransactionDone). NULL if no redeems. (Tier 2 -- SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport) |
| 44 | TotalWithdraws | numeric(38,6) | YES | Lifetime total completed withdrawals excluding crypto. SUM(Amount_WithdrawToFunding) from Fact_BillingWithdraw WHERE CashoutStatusID_Funding=3, FundingTypeID_Funding<>27 (eToroCryptoWallet). NULL if no withdrawals. (Tier 2 -- SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport) |
| 45 | HasSelfie | int | YES | 1 when selfie-type document exists (DocumentTypeID IN 15=Selfie, 18=SelfieLiveliness, 23=SelfieMotion). 0 otherwise. From External BackOffice CustomerDocument + CustomerDocumentToDocumentType. (Tier 2 -- SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport) |
| 46 | TotalPendingWithdraws | decimal(18,2) | YES | Total pending withdrawal amount (recent window -- last 1 day, or last 3 days on Mondays). Excludes terminal statuses: Processed (3), Canceled (4), N/A (0), Rejected (7), RejectedByProvider (8), Failed (13). NULL if no pending withdrawals. (Tier 2 -- SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport) |
| 47 | PendingClosureDate | date | YES | Date when current PendingClosureStatusID was first observed. MIN(FromDateID) from Fact_SnapshotCustomer + Dim_Range matching current status. NULL if not in pending closure. (Tier 2 -- SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport) |
| 48 | ScreeningDate | date | YES | Date of the earliest screening event matching current ScreeningStatusID. MIN(BeginTime) from External ScreeningService. NULL if no screening record. (Tier 2 -- SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport) |
| 49 | PlayerStatus | nvarchar(max) | YES | Human-readable restriction state label. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Dim-lookup passthrough from Dim_PlayerStatus.Name via Dim_Customer.PlayerStatusID. Filtered to NOT IN (2,4). (Tier 1 -- Dictionary.PlayerStatus) |
| 50 | AccountTypeBO | nvarchar(max) | YES | Back-office account type label. Dim-lookup passthrough from Dim_AccountType.Name via Dim_Customer.AccountTypeID. (Tier 2 -- Dim_AccountType) |
| 51 | RiskStatus | nvarchar(max) | YES | Risk status label. Dim-lookup passthrough from Dim_RiskStatus.Name via Dim_Customer.RiskStatusID. (Tier 2 -- Dim_RiskStatus) |
| 52 | UpdateDate | datetime | YES | ETL load timestamp. GETDATE() at SP execution time. Uniform across all rows (TRUNCATE+INSERT). (Tier 2 -- SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport) |
| 53 | Q26_Sources_of_Funds | nvarchar(max) | YES | KYC questionnaire Q26 -- sources of funds. From BI_DB_KYC_Panel. Added 2025-11-18. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 54 | Q26_AnswerText | nvarchar(max) | YES | KYC questionnaire Q26 -- full answer text for sources of funds. From BI_DB_KYC_Panel. Added 2025-11-18. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 55 | Q32_PEP_MM_Question | nvarchar(max) | YES | KYC questionnaire Q32 -- PEP (Politically Exposed Person) / Money Muling question answer. From BI_DB_KYC_Panel. Added 2025-11-18. NULL if unanswered. (Tier 2 -- BI_DB_KYC_Panel) |
| 56 | Q150_AnswerText | nvarchar(max) | YES | KYC additional question 150 answer text. From External_UserApiDB_dbo_V_CustomerAnswers, latest answer per GCID via DENSE_RANK. Added 2025-11-18. NULL if unanswered. (Tier 2 -- External_UserApiDB_dbo_V_CustomerAnswers) |
| 57 | Q12_AnswerText | nvarchar(max) | YES | KYC additional question 12 answer text. From External_UserApiDB_dbo_V_CustomerAnswers, latest answer per GCID via DENSE_RANK. Added 2025-11-18. NULL if unanswered. (Tier 2 -- External_UserApiDB_dbo_V_CustomerAnswers) |
| 58 | Q32_AnswerText | nvarchar(max) | YES | KYC question 32 answer text (from V_CustomerAnswers source -- separate from Q32_PEP_MM_Question which comes from KYC_Panel). Latest per GCID via DENSE_RANK. Added 2025-11-27. NULL if unanswered. (Tier 2 -- External_UserApiDB_dbo_V_CustomerAnswers) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CID | BackOffice.Customer (via External) | CID / MasterAccountCID | Passthrough |
| Country | Dictionary.Country | Name (via Dim_Country) | Dim-lookup passthrough |
| Regulation | Dictionary.Regulation | Name (via Dim_Regulation) | Dim-lookup passthrough |
| PlayerStatus | Dictionary.PlayerStatus | Name (via Dim_PlayerStatus) | Dim-lookup passthrough |
| TotalDeposits | Billing.Deposit (via Fact_BillingDeposit) | AmountUSD | SUM WHERE PaymentStatusID=2 |

### 5.2 ETL Pipeline

```
BI_DB_dbo.External_etoro_BackOffice_Customer (MasterAccountCID filter)
  + DWH_dbo.Dim_Customer (x2: for CID and MasterAccountCID validation)
  |-- #cids (UNION ALL: Master rows + SubAccount rows) ---|
  |
  + DWH_dbo.Fact_BillingDeposit (PaymentStatusID=2)
  |-- #CIDTotalDeposits ---|
  |
  + DWH_dbo.Fact_CustomerAction (ActionTypeID=36, Amount>0)
  |-- #totalCompensation ---|
  |
  + #CIDTotalDeposits FULL OUTER JOIN #totalCompensation
  |-- #TotalDepositsAndCompensations ---|
  |
  + DWH_dbo.Fact_BillingWithdraw (CashoutStatusID_Funding=3, excl crypto)
  |-- #TotalWithdraws ---|
  |
  + DWH_dbo.Fact_BillingWithdraw (recent, pending statuses)
  |-- #pendingWithdrawsRedeems ---|
  |
  + DWH_dbo.Fact_BillingRedeem (RedeemStatusID=8)
  |-- #TotalRedeemsLifetime ---|
  |
  + External_BackOffice_CustomerDocument + DocumentToDocumentType (types 15,18,23)
  |-- #selfie ---|
  |
  + External_UserApiDB_dbo_V_CustomerAnswers (Q150, Q12, Q32)
  |-- #KYC_Q_A (latest per GCID via DENSE_RANK) ---|
  |
  + BI_DB_KYC_Panel (Q2-Q26 questionnaire answers)
  + DWH_dbo.Dim_Customer + Dim_Country(x3) + Dim_Regulation(x2)
  + Dim_RiskClassification + Dim_ScreeningStatus + Dim_PendingClosureStatus
  |-- #KYCPANEL (all attributes assembled) ---|
  |
  + DWH_dbo.Fact_SnapshotCustomer + Dim_Range
  |-- #pendingclosuredate ---|
  |
  + External_ScreeningService_Screening_UserScreening
  |-- #screening ---|
  |
  + DWH_dbo.Dim_PlayerStatus + Dim_AccountType + Dim_RiskStatus
  |-- #finaltable ---|
  v
TRUNCATE BI_DB_dbo.BI_DB_OPS_MastersAndSubAccounts_AlignmentMonitoringReport
INSERT FROM #finaltable (~44K rows)
  |
  UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID / MasterAccountCID | DWH_dbo.Dim_Customer | Customer dimension master (RealCID) |
| Country / POB / Citizenship | DWH_dbo.Dim_Country | Country name lookups |
| Regulation / DesignatedRegulation | DWH_dbo.Dim_Regulation | Regulatory entity |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Account restriction status |
| KYC answers | BI_DB_dbo.BI_DB_KYC_Panel | KYC questionnaire answers |
| Q150/Q12/Q32 answers | External_UserApiDB_dbo_V_CustomerAnswers | Additional KYC answers |

### 6.2 Referenced By (other objects point to this)

No known consumers in the SSDT repo. Operational reporting endpoint for compliance monitoring.

---

## 7. Sample Queries

### 7.1 Master-Sub KYC Alignment Check

```sql
SELECT
    m.CID AS master_cid,
    s.CID AS sub_cid,
    m.Q2_Experience AS master_experience,
    s.Q2_Experience AS sub_experience,
    m.Q10_Annual_Income AS master_income,
    s.Q10_Annual_Income AS sub_income,
    m.Q9_Risk_Reward_Scenario AS master_risk,
    s.Q9_Risk_Reward_Scenario AS sub_risk
FROM BI_DB_dbo.BI_DB_OPS_MastersAndSubAccounts_AlignmentMonitoringReport m
JOIN BI_DB_dbo.BI_DB_OPS_MastersAndSubAccounts_AlignmentMonitoringReport s
  ON m.MasterAccountCID = s.MasterAccountCID
WHERE m.AccountType = 'Master'
  AND s.AccountType = 'SubAccount'
  AND (m.Q2_Experience <> s.Q2_Experience OR m.Q10_Annual_Income <> s.Q10_Annual_Income)
```

### 7.2 Financial Overview by Account Type

```sql
SELECT
    AccountType,
    COUNT(*) AS accounts,
    SUM(TotalDeposits) AS total_deposits,
    SUM(TotalCompensation) AS total_compensations,
    SUM(TotalWithdraws) AS total_withdrawals,
    SUM(TotalPendingWithdraws) AS pending_withdrawals
FROM BI_DB_dbo.BI_DB_OPS_MastersAndSubAccounts_AlignmentMonitoringReport
GROUP BY AccountType
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 12 T1, 46 T2, 0 T3, 0 T4, 0 T5 | Elements: 58/58, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_OPS_MastersAndSubAccounts_AlignmentMonitoringReport | Type: Table | Production Source: SP_OPS_MastersAndSubAccounts_AlignmentMonitoringReport*
