# BI_DB_dbo.BI_DB_Q_AML_EDD_US_Report

> 1,787-row quarterly AML Enhanced Due Diligence report for high-risk US customers (FinCEN/FinCEN+FINRA regulation, Platinum/Platinum Plus/Diamond club tier, VL3 verified, RiskScoreName='High'), covering 385 distinct customers across 6 quarterly snapshots from Q4 2024 to Q1 2026 -- sourced from Fact_SnapshotCustomer + 12 dimension lookups + risk classification + KYC panel + document status + activity tracking via SP_Q_AML_EDD_US_Report.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: Fact_SnapshotCustomer + Dim_Customer + External_RiskClassification + BI_DB_KYC_Panel + BI_DB_AML_Documents_Request + BI_DB_AML_PlayerStatus_Changes + V_Liabilities + Fact_CustomerAction + 10 dim lookups via SP_Q_AML_EDD_US_Report |
| **Refresh** | Quarterly (DELETE+INSERT by Report_Date = end of previous quarter) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Q_AML_EDD_US_Report` is a quarterly AML (Anti-Money Laundering) Enhanced Due Diligence report targeting high-risk US customers. This table provides a comprehensive compliance snapshot for each qualifying customer, including PII, KYC status, document status, risk scoring, financial activity, and equity position.

**Population criteria** (all must be true):
- RegulationID IN (7=FinCEN, 8=FinCEN+FINRA) -- US-regulated customers
- PlayerLevelID IN (2=Platinum, 6=Platinum Plus, 7=Diamond) -- high-tier accounts
- VerificationLevelID = 3 -- fully verified (VL3)
- IsValidCustomer = 1
- RiskScoreName = 'High' -- high-risk classification from RiskClassification external source

The ETL runs quarterly via `SP_Q_AML_EDD_US_Report`. The @Date parameter is "day minus one" adjusted: the SP computes the previous quarter's end date (e.g., @Date=2026-01-01 → Report_Date=20251231). 1,787 rows across 6 quarters (Q4 2024 - Q1 2026), 385 distinct customers. All customers are FinCEN+FINRA regulated.

The report aggregates data from 18+ sources: core customer profile (Dim_Customer), snapshot state (Fact_SnapshotCustomer with 10 dimension lookups), risk classification (External_RiskClassification), KYC questionnaire answers (BI_DB_KYC_Panel), document compliance (BI_DB_AML_Documents_Request), player status history (BI_DB_AML_PlayerStatus_Changes), equity (V_Liabilities), and activity flags (Fact_CustomerAction).

---

## 2. Business Logic

### 2.1 Quarterly Date Computation

**What**: The SP takes @Date and computes the previous quarter's date range.

**Columns Involved**: `Report_Date`

**Rules**:
- @TargetDate = @Date + 1 day (adjusting for "day minus one" convention)
- @FirstDayOfCurrentQuarter = start of quarter containing @TargetDate
- @EndDate = @FirstDayOfCurrentQuarter - 1 day (last day of previous quarter)
- @StartDate = first day of previous quarter
- Report_Date = @EndDateID (YYYYMMDD int of quarter end, e.g., 20260331)

### 2.2 Risk Classification (High-Risk INNER JOIN)

**What**: Only customers classified as 'High' risk are included.

**Columns Involved**: `RiskScoreName`, `RiskScore_Explanation`

**Rules**:
- INNER JOIN to External_RiskClassification_dbo_V_RiskClassificationDataLake ON CID with RiskScoreName='High'
- RiskScore_Explanation contains comma-separated reasons (e.g., "Age of customer,Occupation,Net Deposit")
- The JOIN is an INNER JOIN, meaning customers without a High risk score are excluded entirely

### 2.3 Document Compliance Flags

**What**: Binary flags indicating whether specific compliance documents exist.

**Columns Involved**: `Has_POI`, `Has_POA`, `Has_Proof_of_Income`, `Has_Selfie`, `Has_VideoIdent`

**Rules**:
- Has_POI, Has_POA: Passthrough from BI_DB_AML_Documents_Request (ISNULL default 0)
- Has_Proof_of_Income: CASE WHEN DocumentType_POIncome IS NOT NULL OR SuggestedDocumentType_POIncome IS NOT NULL THEN 1 ELSE 0
- Has_Selfie: Same CASE logic on DocumentType_Selfie / SuggestedDocumentType_Selfie
- Has_VideoIdent: Same CASE logic on DocumentType_VideoIdent / SuggestedDocumentType_VideoIdent

### 2.4 Activity Flags (12-Month Lookback)

**What**: Two binary flags indicating customer activity in the past 365 days.

**Columns Involved**: `Active_Dep_or_CO`, `Active_Trade_or_Loggedin`

**Rules**:
- Active_Dep_or_CO = 1 if customer had approved deposits or cashouts in last 365 days (Fact_CustomerAction CategoryID IN 8=Deposit, 4=Cashout)
- Active_Trade_or_Loggedin = 1 if customer had position opens/closes or logins in last 365 days (CategoryID IN 13=LoggedIn, 17=PositionClose, 18=PositionOpen)

### 2.5 Last Player Status Change (Filtered)

**What**: Most recent player status change, excluding certain transitions.

**Columns Involved**: `Last_PlayerStatus_Change_Date`

**Rules**:
- Source: BI_DB_AML_PlayerStatus_Changes, ROW_NUMBER=1 partitioned by CID ordered by Change_Date DESC
- Excluded: Current_ID IN (2,4) -- specific player statuses filtered out
- Excluded: Previous_ID = 0 -- initial state transitions filtered out
- NULL if no qualifying status change exists

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN** distribution, **HEAP** -- no indexes; small table suitable for full scans
- Filter by `Report_Date` for specific quarter

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest quarterly EDD report | `WHERE Report_Date = (SELECT MAX(Report_Date) FROM BI_DB_Q_AML_EDD_US_Report)` |
| Customers missing documents | `WHERE Has_POI = 0 OR Has_POA = 0` |
| High-risk inactive customers | `WHERE Active_Dep_or_CO = 0 AND Active_Trade_or_Loggedin = 0` |
| Risk explanation breakdown | Parse comma-separated `RiskScore_Explanation` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Additional customer attributes |
| BI_DB_dbo.BI_DB_AML_Documents_Request | CID = CID | Full document details |
| BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | CID = CID | Full status change history |

### 3.4 Gotchas

- **PII-heavy**: FirstName, MiddleName, LastName, BirthDate-derived Age, Country of birth. Handle with care.
- **RiskScoreName always 'High'**: The INNER JOIN to RiskClassification filters to High only. This is not a general customer table.
- **Regulation always FinCEN+FINRA**: Population is US-only. All 1,787 rows have the same regulation.
- **Club tier restricted**: Only Platinum, Platinum Plus, Diamond. Lower tiers excluded.
- **Report_Date is an INT**: YYYYMMDD format, not a date type. E.g., 20260331.
- **Equity can be 0**: ISNULL defaults to 0 if customer not found in V_Liabilities.
- **Active flags look back 365 days**: Not calendar year -- rolling 365 days from quarter end.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data patterns |
| Tier 4 | Best available knowledge, limited confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Fact_SnapshotCustomer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Report_Date | int | YES | End-of-quarter date in YYYYMMDD integer format (e.g., 20260331). Computed from SP @Date parameter via quarter boundary logic. Used for quarterly DELETE+INSERT partitioning. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 3 | FirstName | nvarchar(250) | YES | Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). PII. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 4 | MiddleName | nvarchar(250) | YES | Middle name in Unicode. Added 2018. PII. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 5 | Age | int | YES | Customer age in years. Computed: DATEDIFF(YEAR, BirthDate, GETDATE()). Approximate (does not account for birthday within current year). (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 6 | LastName | nvarchar(250) | YES | Legal last name in Unicode. PII. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 7 | Regulation | nvarchar(250) | YES | Regulatory entity name. Always 'FinCEN+FINRA' in this table (filtered RegulationID IN 7,8). Passthrough from Dim_Regulation.Name. (Tier 2 — SP_Q_AML_EDD_US_Report, Dim_Regulation) |
| 8 | Country | nvarchar(250) | YES | Customer's country of residence. Passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID. (Tier 1 — Dictionary.Country) |
| 9 | POB_Country | nvarchar(250) | YES | Customer's place of birth country. Passthrough from Dim_Country.Name via Dim_Customer.POBCountryID. NULL if POBCountryID not set. (Tier 1 — Dictionary.Country) |
| 10 | Club | nvarchar(250) | YES | Tier display name: Platinum, Platinum Plus, Diamond (filtered population). Passthrough from Dim_PlayerLevel.Name. (Tier 1 — Dictionary.PlayerLevel) |
| 11 | PlayerStatus | nvarchar(250) | YES | Current player status name (Normal, Blocked, Restricted, etc.). Passthrough from Dim_PlayerStatus.Name. (Tier 2 — SP_Q_AML_EDD_US_Report, Dim_PlayerStatus) |
| 12 | PlayerStatusReasons | nvarchar(250) | YES | Reason for current player status. Passthrough from Dim_PlayerStatusReasons.Name. 'None' if no specific reason. (Tier 2 — SP_Q_AML_EDD_US_Report, Dim_PlayerStatusReasons) |
| 13 | PlayerStatusSubReasonName | nvarchar(250) | YES | Sub-reason for player status. Passthrough from Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName. 'None' if no sub-reason. (Tier 2 — SP_Q_AML_EDD_US_Report, Dim_PlayerStatusSubReasons) |
| 14 | Account_Type | nvarchar(250) | YES | Account type name (Private, Corporate). Passthrough from Dim_AccountType.Name. (Tier 2 — SP_Q_AML_EDD_US_Report, Dim_AccountType) |
| 15 | ScreeningStatus | nvarchar(250) | YES | Compliance screening status name (NoMatch, PendingMatch, Match). Passthrough from Dim_ScreeningStatus.Name via Dim_Customer.ScreeningStatusID. (Tier 2 — SP_Q_AML_EDD_US_Report, Dim_ScreeningStatus) |
| 16 | HasWallet | int | YES | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. Passthrough from Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 17 | EvMatchStatusName | nvarchar(250) | YES | Electronic verification match status name (Verified, Not Verified, etc.). Passthrough from Dim_EvMatchStatus.EvMatchStatusName. (Tier 2 — SP_Q_AML_EDD_US_Report, Dim_EvMatchStatus) |
| 18 | IsDepositor | int | YES | 1 = customer has made at least one deposit. Passthrough from Fact_SnapshotCustomer.IsDepositor. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 19 | FirstDepositDate | datetime | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. Passthrough from Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 20 | RegisteredReal | datetime | YES | Account registration date. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 21 | RiskScoreName | nvarchar(250) | YES | Risk classification score name. Always 'High' in this table (INNER JOIN filter). Source: External_RiskClassification_dbo_V_RiskClassificationDataLake. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 22 | RiskScore_Explanation | nvarchar(max) | YES | Comma-separated list of risk factors (e.g., "Age of customer,Occupation,Net Deposit,Annual Income"). Source: External_RiskClassification. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 23 | Q18_Occupation | nvarchar(250) | YES | KYC questionnaire Q18 answer: customer's stated occupation (e.g., "Real estate", "None"). Source: BI_DB_KYC_Panel.Q18_AnswerText. (Tier 2 — SP_Q_AML_EDD_US_Report, BI_DB_KYC_Panel) |
| 24 | Q14_Planned_Invested_Amount | nvarchar(250) | YES | KYC questionnaire Q14 answer: planned investment amount range (e.g., "$20k - $50k", "Up to $20K", "$50k-$200k"). Source: BI_DB_KYC_Panel.Q14_AnswerText. (Tier 2 — SP_Q_AML_EDD_US_Report, BI_DB_KYC_Panel) |
| 25 | Total_Deposits | money | YES | Cumulative total deposit amount in USD. SUM of Fact_CustomerAction.Amount WHERE ActionTypeID=7 (Deposits). ISNULL default 0. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 26 | Has_POI | int | YES | 1 = Proof of Identity document exists. ISNULL default 0. Source: BI_DB_AML_Documents_Request. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 27 | POI_ExpiryDate | datetime | YES | Proof of Identity document expiry date. NULL if no POI. Source: BI_DB_AML_Documents_Request. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 28 | Has_POA | int | YES | 1 = Proof of Address document exists. ISNULL default 0. Source: BI_DB_AML_Documents_Request. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 29 | POA_ExpiryDate | datetime | YES | Proof of Address document expiry date. NULL if no POA. Source: BI_DB_AML_Documents_Request. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 30 | Has_Proof_of_Income | int | YES | 1 = Proof of Income document exists (DocumentType or SuggestedDocumentType is NOT NULL). Computed CASE. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 31 | DocumentDateAdded_POIncome | datetime | YES | Date when Proof of Income document was uploaded. NULL if no document. Source: BI_DB_AML_Documents_Request. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 32 | Has_Selfie | int | YES | 1 = Selfie document exists (DocumentType or SuggestedDocumentType is NOT NULL). Computed CASE. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 33 | DocumentDateAdded_Selfie | datetime | YES | Date when selfie was uploaded. NULL if no selfie. Source: BI_DB_AML_Documents_Request. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 34 | Has_VideoIdent | int | YES | 1 = Video identification document exists (DocumentType or SuggestedDocumentType is NOT NULL). Computed CASE. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 35 | DocumentDateAdded_VideoIdent | datetime | YES | Date when video identification was uploaded. NULL if no video. Source: BI_DB_AML_Documents_Request. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 36 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the ETL pipeline (GETDATE()). (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 37 | Last_PlayerStatus_Change_Date | date | YES | Date of most recent player status change, excluding transitions to status IDs 2,4 and from status ID 0 (initial). NULL if no qualifying change. Source: BI_DB_AML_PlayerStatus_Changes (ROW_NUMBER=1). (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 38 | Equity | money | YES | Customer account equity: ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) from V_Liabilities at quarter end. Default 0 if not found. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 39 | Active_Dep_or_CO | int | YES | 1 = customer had at least one approved deposit or cashout in the last 365 days from quarter end (Fact_CustomerAction CategoryID IN 8=Deposit, 4=Cashout). NULL if no activity data. (Tier 2 — SP_Q_AML_EDD_US_Report) |
| 40 | Active_Trade_or_Loggedin | int | YES | 1 = customer had at least one position open/close or login in the last 365 days from quarter end (Fact_CustomerAction CategoryID IN 13=LoggedIn, 17=PositionClose, 18=PositionOpen). NULL if no activity data. (Tier 2 — SP_Q_AML_EDD_US_Report) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | RealCID | Passthrough via Fact_SnapshotCustomer |
| FirstName/MiddleName/LastName | Customer.CustomerStatic | Same | Passthrough via Dim_Customer |
| Age | Customer.CustomerStatic | BirthDate | DATEDIFF(YEAR, BirthDate, GETDATE()) |
| Country/POB_Country | Dictionary.Country | Name | Dim lookup via Dim_Country |
| Club | Dictionary.PlayerLevel | Name | Dim lookup via Dim_PlayerLevel |
| HasWallet | BackOffice.Customer | HasWallet | Passthrough via Dim_Customer |
| RegisteredReal | Customer.CustomerStatic | Registered | Passthrough via Dim_Customer |
| Total_Deposits | Fact_CustomerAction | Amount | SUM WHERE ActionTypeID=7 |
| Equity | V_Liabilities | Liabilities + ActualNWA | ISNULL addition |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (VL3, IsValid=1, RegID IN(7,8), PlayerLevel IN(2,6,7))
  |-- JOIN Dim_Customer (PII: FirstName, MiddleName, LastName, BirthDate, HasWallet, etc.)
  |-- JOIN Dim_Regulation, Dim_Country, Dim_PlayerLevel, Dim_PlayerStatus + 5 more dims
  |-- INNER JOIN External_RiskClassification (RiskScoreName='High')
  v
#pop (base high-risk US population)
  |-- LEFT JOIN BI_DB_KYC_Panel (Q18_Occupation, Q14_Planned_Invested_Amount)
  |-- LEFT JOIN Fact_CustomerAction (SUM deposits, activity flags - 365 day lookback)
  |-- LEFT JOIN BI_DB_AML_Documents_Request (POI/POA/POIncome/Selfie/VideoIdent)
  |-- LEFT JOIN BI_DB_AML_PlayerStatus_Changes (last change date, ROW_NUMBER=1)
  |-- LEFT JOIN V_Liabilities (Equity = Liabilities + ActualNWA)
  v
SP_Q_AML_EDD_US_Report @Date (quarterly DELETE+INSERT by Report_Date)
  v
BI_DB_dbo.BI_DB_Q_AML_EDD_US_Report (1,787 rows, ROUND_ROBIN)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension |
| Club | DWH_dbo.Dim_PlayerLevel | Club tier lookup |
| Country | DWH_dbo.Dim_Country | Country lookup |
| KYC data | BI_DB_dbo.BI_DB_KYC_Panel | KYC questionnaire answers |
| Documents | BI_DB_dbo.BI_DB_AML_Documents_Request | Document compliance status |
| Status changes | BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | Player status history |

### 6.2 Referenced By (other objects point to this)

No known consumers in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Latest Quarter -- Customers Missing Critical Documents

```sql
SELECT CID, FirstName, LastName, Country, Club, Equity,
       Has_POI, Has_POA, Has_Proof_of_Income, Has_Selfie
FROM BI_DB_dbo.BI_DB_Q_AML_EDD_US_Report
WHERE Report_Date = (SELECT MAX(Report_Date) FROM BI_DB_dbo.BI_DB_Q_AML_EDD_US_Report)
  AND (Has_POI = 0 OR Has_POA = 0 OR Has_Proof_of_Income = 0)
ORDER BY Equity DESC
```

### 7.2 Inactive High-Equity Customers

```sql
SELECT CID, FirstName, LastName, Equity, Total_Deposits,
       Active_Dep_or_CO, Active_Trade_or_Loggedin, Last_PlayerStatus_Change_Date
FROM BI_DB_dbo.BI_DB_Q_AML_EDD_US_Report
WHERE Report_Date = (SELECT MAX(Report_Date) FROM BI_DB_dbo.BI_DB_Q_AML_EDD_US_Report)
  AND Active_Dep_or_CO = 0 AND Active_Trade_or_Loggedin = 0
  AND Equity > 50000
ORDER BY Equity DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 8 T1, 32 T2, 0 T3, 0 T4, 0 T5 | Elements: 40/40, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Q_AML_EDD_US_Report | Type: Table | Production Source: Multi-source via SP_Q_AML_EDD_US_Report*
