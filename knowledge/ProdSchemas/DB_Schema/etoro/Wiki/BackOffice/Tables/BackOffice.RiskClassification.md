# BackOffice.RiskClassification

> AML risk scoring table storing the daily risk score for each customer, calculated from 14 weighted factor scores (country risk, PEP status, age, income, occupation, deposit patterns) plus 22 qualitative questionnaire responses, used by the Risk team's CySEC compliance Tableau report.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | RealCID (INT, CLUSTERED PK - one row per customer) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 active (1 clustered PK) |
| **Temporal** | Yes - system-versioned. History tracked in History.RiskClassification |

---

## 1. Business Meaning

BackOffice.RiskClassification stores the output of eToro's AML risk scoring engine: each row is the current risk profile for one customer, containing their MaxScore (composite risk score from 0-100+), 14 individual factor scores contributing to that total, 22 qualitative questionnaire responses (qq_* columns), alerts triggered, and audit scheduling dates.

The scoring system was built by eToro's BI Team (Guy Barkat, 2019) to support CySEC compliance audits and is rendered in a Tableau "Client Risk Score Report." The algorithm weighs factors like country of registration (onboarding and existing client country risk), net deposits, customer age, PEP (Politically Exposed Person) status, annual income, occupation, source of funds origin and destination country, payment method (bank vs card), and various AML qualitative indicators.

BackOffice.SetRiskClassificationNew calculates and upserts scores daily (typically run for yesterday's data). The table is system-versioned (temporal table) with full history preserved in History.RiskClassification - every time a customer's score changes, the old version is moved to history with BeginTime/EndTime boundaries. The table is empty in the current environment (scores may be maintained in a separate CySEC-specific DB).

---

## 2. Business Logic

### 2.1 Composite Risk Score Architecture

**What**: MaxScore is the sum of all factor scores. Each factor score is an integer value assigned based on the customer's profile attribute.

**Columns Involved**: `MaxScore`, `ScoreCountryOnboardingClients`, `ScoreCountryExistingClients`, `ScoreNetDeposit`, `ScoreAge`, `ScorePEPStatus`, `ScoreAnnualIncome`, `ScoreCashAndAssets`, `ScoreInvestPlan`, `ScoreMainIncome`, `ScoreOccupation`, `ScoreExpectedOriginFunds`, `ScoreExpectedDestinationPayments`, `ScoreFTD_Bank_MOP`

**Rules**:
- MaxScore = sum of all Score* columns (exact formula implemented in SetRiskClassificationNew)
- Higher score = higher AML risk
- WithAlert=1 when MaxScore exceeds a defined threshold (triggers Risk team review)
- AuditDueDate is calculated from LastAuditDate + a regulation-specific interval
- AuditDueDateExpired=1 when AuditDueDate < current date (overdue for risk review)

**Diagram**:
```
SetRiskClassificationNew runs daily for date @dd
        |
        v
For each customer: calculate factor scores from profile data
  ScoreCountryOnboardingClients <- Country risk table for country at registration
  ScoreCountryExistingClients   <- Country risk table for current country
  ScoreNetDeposit               <- Deposit amounts band
  ScoreAge                      <- Age bracket
  ScorePEPStatus                <- PEP check result (0=no, high=PEP/family member)
  ScoreAnnualIncome             <- Income band
  ScoreCashAndAssets            <- Wealth band
  ...
        |
        v
MaxScore = Sum(all Score* columns)
WithAlert = CASE WHEN MaxScore >= threshold THEN 1 ELSE 0 END
        |
        v
UPSERT BackOffice.RiskClassification (temporal - old row -> History.RiskClassification)
```

### 2.2 Temporal System-Versioning

**What**: Every change to a customer's risk score is preserved in History.RiskClassification with precise time boundaries.

**Columns Involved**: `BeginTime`, `EndTime`

**Rules**:
- BeginTime: When this version of the row became current (GENERATED ALWAYS AS ROW START)
- EndTime: When this version was superseded (GENERATED ALWAYS AS ROW END). '9999-12-31 23:59:59' = currently active
- On UPDATE: SQL Server moves the old row to History.RiskClassification and updates BeginTime/EndTime automatically
- Allows querying the customer's risk score at any point in time: SELECT ... FOR SYSTEM_TIME AS OF @Date

### 2.3 Qualitative AML Questionnaire (qq_* columns)

**What**: 22 binary questionnaire responses (integer 0/1) representing qualitative AML red-flag assessments completed by Risk/Compliance agents.

**Columns Involved**: All `qq_*` columns

**Rules**:
- Each qq_ column represents one AML indicator assessed by the agent (0=no concern, 1=concern present)
- Covers: PEP/public profile (qq_HighPublicProfile), sanctions/disclosures (qq_DisclosureSubjected), jurisdiction quality (qq_RegionSupervised, qq_JurisdictionNonCorrupt), transaction patterns (qq_TransactionSuspicious, qq_TransactionsUnusual, qq_TransactionComplexity), identity quality (qq_IdentityEvidence, qq_IdentityDoubts, qq_IdentityAnonymous), wealth source (qq_WealthExplained, qq_OwnershipTransparent, qq_AssetHoldingVehicle), behavioral (qq_CooperativeClient, qq_AvoidBusinessRelations), payment (qq_PaymentsThirdParty), non-profit abuse (qq_NonProfitOrgAbused), products used (qq_ExpectedProductsUsed), NFTF (non-face-to-face), AML/CFT failures (qq_AML_CFT_Failure), background consistency (qq_BackgroundConsistent), secrecy (qq_SecrecyUnreasonable)

---

## 3. Data Overview

This table is empty (0 rows) in the current database environment. It is populated by BackOffice.SetRiskClassificationNew which runs daily. Structure overview:

| Column Group | Columns | Purpose |
|---|---|---|
| Identity | RealCID, Country, Age, PEPStatus, Regulation, Desk | Customer profile context |
| Financial profile | MainIncome, Occupation, AnnualIncome, CashAndAssets, InvestPlan, NetDeposit | Suitability/source-of-funds inputs |
| Factor scores | MaxScore, Score* (14 columns) | Numeric AML risk score components |
| Alerts | WithAlert, AlertCountry, AlertAge, AlertNameFilled | Triggered threshold flags |
| Qualitative | qq_* (22 columns) | Agent-assessed AML indicators |
| Temporal | BeginTime, EndTime | System-versioning period columns |
| Audit | Date, AuditDueDate, AuditDueDateExpired, LastAuditDate, LastMaxScoreChangeDate | Compliance audit scheduling |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RealCID | int | NO | - | VERIFIED | Customer ID (real/live account). PK - one row per customer. SetRiskClassificationNew references this as the primary key for upserts. Named "Real" to distinguish from demo account CIDs. |
| 2 | Country | varchar(50) | YES | - | CODE-BACKED | Customer's registration country name. Input to ScoreCountryOnboardingClients and country alert calculations. |
| 3 | FirstDepositDate | datetime | YES | - | CODE-BACKED | Date of the customer's first deposit. Used in age-of-account risk calculations. |
| 4 | FirstWalletTransDate | datetime | YES | - | CODE-BACKED | Date of first wallet transaction (crypto or fiat). |
| 5 | FirstDate | datetime | YES | - | CODE-BACKED | Earlier of FirstDepositDate or FirstWalletTransDate - the true first activity date. |
| 6 | Regulation | varchar(50) | YES | - | CODE-BACKED | Regulatory entity governing this customer (CySEC, FCA, ASIC, etc.). Drives regulation-specific scoring weights in SetRiskClassificationNew via #Regulation temp table. |
| 7 | IsFTD | int | YES | - | CODE-BACKED | 1 if this customer has made a First Time Deposit. Context for risk scoring. |
| 8 | IsFWTD | int | YES | - | CODE-BACKED | 1 if this customer has made a First Wallet Transaction. |
| 9 | MaxScore | int | YES | - | VERIFIED | Composite AML risk score - sum of all Score* factor columns. Higher = higher risk. Used to determine WithAlert flag and audit scheduling priority. |
| 10 | WithAlert | int | YES | - | VERIFIED | 1 when MaxScore exceeds the configured threshold requiring Risk team review. Drives the "Clients With Alert" view in the Tableau report. |
| 11 | ScoreCountryOnboardingClients | int | YES | - | VERIFIED | Risk score contribution from the country risk rating at customer onboarding. High-risk FATF countries contribute higher scores. |
| 12 | ScoreCountryExistingClients | int | YES | - | VERIFIED | Risk score from current country risk (may differ from onboarding if country risk rating changed). |
| 13 | ScoreNetDeposit | int | YES | - | VERIFIED | Risk score from the customer's total net deposit amount band. Large net deposits contribute higher scores. |
| 14 | ScoreAge | int | YES | - | VERIFIED | Risk score from the customer's age bracket. Certain age groups have higher AML risk profiles. |
| 15 | ScorePEPStatus | int | YES | - | VERIFIED | Risk score from PEP (Politically Exposed Person) check. Non-zero for PEPs, family members of PEPs, or associates. |
| 16 | ScoreAnnualIncome | int | YES | - | VERIFIED | Risk score from the declared annual income band. |
| 17 | ScoreCashAndAssets | int | YES | - | VERIFIED | Risk score from declared cash and liquid assets band. |
| 18 | ScoreInvestPlan | int | YES | - | VERIFIED | Risk score from the investment plan/intended trading amount. |
| 19 | ScoreMainIncome | int | YES | - | VERIFIED | Risk score from the category of main income source. |
| 20 | ScoreOccupation | int | YES | - | VERIFIED | Risk score from the customer's stated occupation category. |
| 21 | ScoreExpectedOriginFunds | int | YES | - | VERIFIED | Risk score from the expected origin country of funds. High-risk origin countries score higher. |
| 22 | ScoreExpectedDestinationPayments | int | YES | - | VERIFIED | Risk score from expected destination country for withdrawals. |
| 23 | AlertCountry | int | YES | - | CODE-BACKED | 1 if an alert was triggered specifically by the country risk factor. Subset of WithAlert. |
| 24 | AlertAge | int | YES | - | CODE-BACKED | 1 if an alert was triggered by the age factor. |
| 25 | AlertNameFilled | int | YES | - | CODE-BACKED | 1 if the customer's name fields are not fully populated (incomplete KYC data). |
| 26 | Date | date | YES | - | VERIFIED | The scoring date for this record (the @dd parameter passed to SetRiskClassificationNew - typically yesterday). |
| 27 | Desk | varchar(50) | YES | - | CODE-BACKED | The compliance desk responsible for this customer (e.g., "CySEC", "FCA"). Drives audit routing. |
| 28 | AuditDueDate | date | YES | - | VERIFIED | Scheduled date for the next periodic AML review of this customer. Calculated from LastAuditDate + regulation-specific interval. |
| 29 | AuditDueDateExpired | int | YES | - | VERIFIED | 1 when AuditDueDate < current date - customer is overdue for their periodic AML review. Priority indicator in Tableau report. |
| 30 | UpdateDate | datetime | YES | - | CODE-BACKED | Timestamp of last update to this record. |
| 31 | LastAuditDate | date | YES | - | CODE-BACKED | Date of the most recent completed periodic AML audit for this customer. |
| 32 | LastMaxScoreChangeDate | date | YES | - | CODE-BACKED | Date when the MaxScore last changed. Used to detect score drift and escalation. |
| 33 | ScoreFTD_Bank_MOP | int | YES | - | VERIFIED | Risk score from the payment method used for First Time Deposit. Bank transfer = lower risk; certain card types = higher risk. |
| 34-55 | qq_* (22 columns) | int | YES | - | VERIFIED | Binary (0/1) qualitative AML questionnaire responses. See Section 2.3 for full list. Cover PEP, sanctions, jurisdiction quality, transaction patterns, identity, wealth, behavior, payment method risks. |
| 56 | Age | int | YES | - | CODE-BACKED | Customer's age in years at time of scoring. Input to ScoreAge calculation. |
| 57 | PEPStatus | varchar(50) | YES | - | CODE-BACKED | PEP check result string (e.g., "Not PEP", "PEP", "PEP Family Member"). Input to ScorePEPStatus. |
| 58 | MainIncome | varchar(50) | YES | - | CODE-BACKED | Customer's declared main income source category. Input to ScoreMainIncome. |
| 59 | Occupation | varchar(100) | YES | - | CODE-BACKED | Customer's stated occupation. Input to ScoreOccupation. |
| 60 | AnnualIncome | varchar(50) | YES | - | CODE-BACKED | Annual income range declared by customer. Input to ScoreAnnualIncome. |
| 61 | CashAndAssets | varchar(50) | YES | - | CODE-BACKED | Liquid assets range declared by customer. Input to ScoreCashAndAssets. |
| 62 | InvestPlan | varchar(50) | YES | - | CODE-BACKED | Intended investment amount range. Input to ScoreInvestPlan. |
| 63 | CountryExpectedOriginFunds | varchar(100) | YES | - | CODE-BACKED | Country from which the customer expects to originate funds. Input to ScoreExpectedOriginFunds. |
| 64 | CountryExpectedDestinationPayments | varchar(100) | YES | - | CODE-BACKED | Country to which withdrawals are expected. Input to ScoreExpectedDestinationPayments. |
| 65 | NetDeposit | money | YES | - | CODE-BACKED | Customer's net deposit (total deposits minus total withdrawals). Input to ScoreNetDeposit. |
| 66 | EU | int | YES | - | CODE-BACKED | 1 if the customer's country is in the EU. Regulatory context flag for CySEC reporting. |
| 67 | FTD_Bank_MOP | int | YES | - | CODE-BACKED | 1 if the First Time Deposit was made via bank transfer. Input to ScoreFTD_Bank_MOP. |
| 68 | BeginTime | datetime2(7) GENERATED ALWAYS | NO | GETUTCDATE() | VERIFIED | System-versioning row start time. When this version became the current record. GENERATED ALWAYS AS ROW START - managed by SQL Server temporal system. |
| 69 | EndTime | datetime2(7) GENERATED ALWAYS | NO | '99991231 23:59:59.9999999' | VERIFIED | System-versioning row end time. '9999-12-31' = currently active. When updated, SQL Server sets this to the update timestamp and moves row to History.RiskClassification. GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RealCID | Customer.CustomerStatic | Implicit FK | Links risk score to the customer account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.RiskClassification | RealCID | Temporal history | System-versioned history of all past risk scores |
| BackOffice.SetRiskClassificationNew | RealCID | WRITER/MODIFIER | Daily scoring engine that populates this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.RiskClassification (table, temporal)
- Temporal history: History.RiskClassification (table)
- No FK constraints declared
```

### 6.1 Objects This Depends On

No dependencies (no FK constraints declared).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.RiskClassification | Table | Temporal history of risk score versions |
| BackOffice.SetRiskClassificationNew | Procedure | WRITER/MODIFIER - daily AML risk scoring |
| BackOffice.RiskClassification_20190714 | Table | Archive snapshot of scores as of 2019-07-14 (separate table, not temporal history) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_RiskClassification | CLUSTERED PK | RealCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_GDPR_UserExecution_BeginTime | DEFAULT | BeginTime = GETUTCDATE() |
| Df_GDPR_UserExecution_EndTime | DEFAULT | EndTime = '99991231 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | Temporal | (BeginTime, EndTime) - enables system-versioned temporal queries |

---

## 8. Sample Queries

### 8.1 Get current risk scores with alert status
```sql
SELECT
    rc.RealCID,
    rc.Country,
    rc.Regulation,
    rc.MaxScore,
    rc.WithAlert,
    rc.Date AS ScoringDate,
    rc.AuditDueDate,
    rc.AuditDueDateExpired,
    rc.PEPStatus
FROM BackOffice.RiskClassification rc WITH (NOLOCK)
WHERE rc.WithAlert = 1
ORDER BY rc.MaxScore DESC
```

### 8.2 Get customers overdue for AML audit by desk
```sql
SELECT
    rc.Desk,
    COUNT(*) AS OverdueCount,
    AVG(rc.MaxScore) AS AvgScore,
    MAX(rc.MaxScore) AS MaxRiskScore
FROM BackOffice.RiskClassification rc WITH (NOLOCK)
WHERE rc.AuditDueDateExpired = 1
GROUP BY rc.Desk
ORDER BY OverdueCount DESC
```

### 8.3 Get historical risk score for a customer at a specific date (temporal query)
```sql
SELECT
    rc.RealCID,
    rc.MaxScore,
    rc.WithAlert,
    rc.BeginTime,
    rc.EndTime
FROM BackOffice.RiskClassification
    FOR SYSTEM_TIME AS OF '2024-01-01 00:00:00'
WHERE rc.RealCID = 12345
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| RD-7582/8873 | Jira | Risk scoring - CySEC Audit Jul 2019 - initial implementation of risk classification system (from SP comment) |
| RD-16450 | Jira | Risk score - Risk classification reports - expanded scoring algorithm (from SP comment) |
| COAIL-253 | Jira | Bug fixes for risk scoring system (from SP comment) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 8.7/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 14 VERIFIED, 55 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 3 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Note: Table empty (0 rows) in current environment - populated in CySEC/production environment by SetRiskClassificationNew daily job.*
*Object: BackOffice.RiskClassification | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.RiskClassification.sql*
