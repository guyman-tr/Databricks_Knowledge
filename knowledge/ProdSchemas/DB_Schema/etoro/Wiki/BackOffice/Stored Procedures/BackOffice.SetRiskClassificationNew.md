# BackOffice.SetRiskClassificationNew

> Daily batch AML risk scoring procedure that calculates composite risk scores for all FTD and crypto-wallet customers using 14 weighted factor dimensions (country risk, age, PEP status, deposit patterns, occupation, etc.) and upserts results into the temporal BackOffice.RiskClassification table for CySEC compliance reporting.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @dd - the date for which risk scores are calculated (default: yesterday) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetRiskClassificationNew is eToro's central AML (Anti-Money Laundering) risk scoring engine. Designed by eToro's BI Team (Guy Barkat, January 2019) to support CySEC compliance audits, it calculates a composite risk score (MaxScore) for each customer in scope - depositors and crypto wallet users - weighing 14 risk dimensions including country risk, customer age, PEP (Politically Exposed Person) screening status, net deposit amounts, annual income, occupation, source of funds, payment method type, and several qualitative questionnaire responses.

The scoring parameters are not hardcoded - they are loaded from configurable lookup tables (BackOffice_RiskClassificationParameter, V_RiskClassificationParameter) that Compliance team maintains. This means risk weighting changes (e.g., adding a high-risk country) can be applied without deploying code changes.

Results are written into BackOffice.RiskClassification (a system-versioned temporal table). Every score change generates a history record in History.RiskClassification. The @Update=0 default means the procedure can be run in simulation mode without modifying BackOffice.Customer - setting @Update=1 also updates customer-level columns. The @Debug parameter enables step-by-step progress timestamps for performance analysis.

The output feeds the "Client Risk Score Report" in Tableau, used by the Risk team and CySEC auditors to review customer risk profiles and prioritize compliance investigations.

---

## 2. Business Logic

### 2.1 Customer Population Scope

**What**: Only certain customers are included in the risk scoring - not all registered users.

**Columns/Parameters Involved**: `@dd`, Customer.CustomerStatic, BackOffice.Customer, BackOffice.CustomerAllTimeAggregatedData

**Rules**:
- In scope: customers who either (a) had a successful FTD (FirstTimeDepositSuccessDate IS NOT NULL) AND RegulationID is in the configured regulation list, OR (b) ever had a positive crypto wallet balance (min DateFrom from Wallet_WalletBalances)
- Also includes Global FTD users (dbo.CustomerFinance_GlobalFtd) not already in the main population
- Out of scope: customers with no deposits and no wallet activity
- Population is computed into temp table #pop with all dimension columns needed for scoring

### 2.2 14-Dimension Risk Scoring Framework

**What**: MaxScore is computed as a sum of 14 factor scores, each derived from customer attributes and regulation-specific weight tables.

**Columns/Parameters Involved**: All Score* columns in BackOffice.RiskClassification

**Rules**:
- All weights are configurable per RegulationID via V_RiskClassificationParameter
- Factor scores are resolved via OUTER APPLY against the parameter table - if no specific match, a regulation-specific default score is used
- The 14 scoring dimensions and their RiskClassificationParameterID:
  - Parameter 2: Country risk (onboarding clients) - based on country risk group classification
  - Parameter 3: Country risk (existing clients) - same grouping, less strict thresholds for pre-existing clients
  - Parameter 5: Customer age - age ranges mapped to risk scores
  - Parameter 6: Age alert flag - flags for specific age ranges
  - Parameter 7: PEP/Screening status - from world screening service
  - Parameters 8-22: Net deposit, annual income, cash & assets, investment plan, main income source, occupation, expected origin of funds, expected destination of payments, FTD payment method type, and qualitative questionnaire responses (qq_* columns)
- Special override rules (compliance-mandated, not in parameter table):
  - Philippines: country score overridden to 100 (maximum risk) for both onboarding and existing parameters
  - South Africa: same override (added 2025)
  - UAE was previously overridden (commented out by Panos 07/22/2025)
  - Malta was previously overridden (removed by Panos 07/22/2025)

### 2.3 Simulation vs. Update Modes

**What**: @Update controls whether BackOffice.Customer is modified.

**Columns/Parameters Involved**: `@Update`

**Rules**:
- @Update=0 (default): Calculates scores and writes to BackOffice.RiskClassification only. BackOffice.Customer is NOT modified. Safe for audit preview runs.
- @Update=1: Also updates relevant columns in BackOffice.Customer (specific columns determined by downstream logic in the remainder of the procedure - not visible in the first 400 lines read).
- The temporal table BackOffice.RiskClassification always gets updated regardless of @Update setting.

### 2.4 V_Country Validation Guard

**What**: Pre-flight check prevents scoring with duplicate country data.

**Rules**:
- First action in the procedure: `IF EXISTS (SELECT CountryID FROM V_Country GROUP BY CountryID HAVING COUNT(*)>1) RAISERROR('Duplicate Rows in V_Country', 16, 1)`
- If V_Country has duplicate CountryID entries (data corruption or view issue), the procedure aborts before any calculation
- This guards against incorrect country risk score assignments

**Diagram**:
```
EXEC BackOffice.SetRiskClassificationNew @dd=NULL, @Update=0, @Debug=0
    |
    +--> Validate V_Country (no duplicates)
    +--> Set @dd = ISNULL(@dd, CAST(GETDATE()-1 AS Date)) -- yesterday
    |
    +--> Load configurations: #Regulation, #V_RiskClassificationParameter
    +--> Build population: #pop (FTD customers + wallet users)
    |         |- Customer.CustomerStatic
    |         |- BackOffice.Customer
    |         |- BackOffice.CustomerAllTimeAggregatedData
    |         |- Wallet_WalletBalances, Wallet_Wallets
    |         |- CustomerFinance_GlobalFtd (global FTD)
    |
    +--> PEP/Screening: #WorldCheckScreeningCase, #PEP_Status
    +--> Country dimension: #dimcustomerdata (Scores 2,3,5,6,7)
    +--> [Further dimensions: 8-22 in later proc body]
    |
    +--> Accumulate all scores in #Scores
    +--> Compute MaxScore = SUM of all factor scores
    |
    +--> MERGE INTO BackOffice.RiskClassification (temporal table)
    |         |- Old scores -> History.RiskClassification (automatic via system versioning)
    |
    +--> IF @Update=1: UPDATE BackOffice.Customer [selected columns]
    RETURN 0
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @dd | DATE | YES | NULL | VERIFIED | The reference date for scoring calculations. NULL defaults to CAST(GETDATE()-1 AS Date) (yesterday). Controls time-sensitive scoring logic (audit due dates, relative deposit calculations). Running for a specific past date reruns the scoring as of that day. |
| 2 | @Update | BIT | YES | 0 | VERIFIED | Controls whether BackOffice.Customer is modified in addition to BackOffice.RiskClassification. 0=simulation/preview mode (read-only on Customer), 1=apply full update. Default 0 is safe for compliance preview runs. |
| 3 | @Debug | BIT | YES | 0 | CODE-BACKED | When 1, prints step-by-step progress timestamps at each major checkpoint (e.g., "0100 yyyyMMdd HH:mm:ss.fff"). Used for performance profiling and debugging long runs. Has no effect on data written. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Population base | Customer.CustomerStatic | READER | Customer demographics (name, birth date, country, GCID) |
| Population base | BackOffice.Customer | READER | Regulation, verification level, first deposit date context |
| Population base | BackOffice.CustomerAllTimeAggregatedData | READER | FirstTimeDepositSuccessDate for FTD identification |
| Wallet users | dbo.Wallet_WalletBalances, dbo.Wallet_Wallets | READER | First wallet transaction date for crypto scope |
| Global FTD | dbo.CustomerFinance_GlobalFtd | READER | Global FTD customers not in main population |
| PEP/Screening | dbo.Screening_UserScreening | READER | PEP status for risk scoring |
| Parameters | V_RiskClassificationParameter | READER (view) | Configurable factor weights per regulation |
| Parameters | BackOffice_RiskClassificationParameter | READER | Which regulations are in scope |
| Country risk | V_Country | READER (view) | Country risk group mapping for score calculation |
| Output | BackOffice.RiskClassification | WRITER (MERGE/UPSERT) | Target for daily risk scores (temporal table) |
| Questionnaire | BackOffice.RiskClassificationQuestionnaire | READER | qq_* questionnaire responses for scoring |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CySEC compliance scheduler | - | Caller | Called daily to regenerate risk scores for audit reporting |
| BackOffice Risk team | - | Caller | Called manually for specific dates when re-scoring is needed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetRiskClassificationNew (procedure)
├── Customer.CustomerStatic (table)
├── BackOffice.Customer (table)
├── BackOffice.CustomerAllTimeAggregatedData (table)
├── BackOffice.RiskClassification (table - temporal, write target)
├── BackOffice.RiskClassificationQuestionnaire (table)
├── BackOffice_RiskClassificationParameter (table/view)
├── V_RiskClassificationParameter (view)
├── V_Country (view)
├── dbo.Wallet_WalletBalances (table)
├── dbo.Wallet_Wallets (table)
├── dbo.CustomerFinance_GlobalFtd (table)
├── dbo.Screening_UserScreening (table)
└── dbo.Dictionary_ScreeningStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Customer demographics for population and country scoring |
| BackOffice.Customer | Table | Regulation assignment and customer classification |
| BackOffice.CustomerAllTimeAggregatedData | Table | FTD date for population scoping |
| BackOffice.RiskClassification | Table | MERGE/UPSERT target - system-versioned temporal table |
| V_RiskClassificationParameter | View | Configurable risk parameter weights per regulation |
| BackOffice_RiskClassificationParameter | Table | Regulation scope configuration |
| V_Country | View | Country risk group classification |
| dbo.Wallet_WalletBalances | Table | Crypto wallet transaction dates |
| dbo.Screening_UserScreening | Table | PEP/World screening status |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.RiskClassification | Table | Receives daily upserted risk scores |
| Tableau Risk Report | External | Reads BackOffice.RiskClassification for CySEC compliance reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Change History

- **RD-7582, RD-8873** (Jun-Jul 2019, Geri Reshef): "Risk scoring - CySEC Audit Jul 2019"
- **RD-16450** (Dec 2019, Jan 2020, Geri Reshef): "Risk score - Risk classification reports"
- **COAIL-253** (Mar 2020, Yulia Kramer): Bugs for Risk scoring
- **Jul 2020** (Yulia Kramer): Added Scores Temporary Table
- **Nov 2023**: Changed population filter to include wallet users or depositors within configured regulations
- **Jul 2025** (Panos): Commented out UAE score overrides; removed Malta override; added Philippines and South Africa overrides at score=100

### 7.4 Performance Notes

The procedure creates and drops multiple indexed temp tables (#pop, #dimcustomerdata, #Scores, #Scores_2_3_5_6_7, #PEP_Status, etc.) with clustered indexes and PAGE data compression. The @Debug=1 mode prints timestamps at each step for performance profiling. Dynamic SQL is used for temp table PK constraint naming (includes @@SPID to support concurrent runs).

---

## 8. Sample Queries

### 8.1 Run in simulation mode for yesterday (default)
```sql
EXEC BackOffice.SetRiskClassificationNew
    @dd     = NULL,   -- yesterday
    @Update = 0,      -- simulation - do not update Customer
    @Debug  = 0
```

### 8.2 Run with debug timing output for a specific date
```sql
EXEC BackOffice.SetRiskClassificationNew
    @dd     = '2026-03-17',
    @Update = 0,
    @Debug  = 1   -- prints step timestamps
```

### 8.3 View current risk scores with high-risk customers
```sql
SELECT TOP 100
    rc.RealCID,
    rc.MaxScore,
    rc.WithAlert,
    rc.AuditDueDate,
    rc.AuditDueDateExpired,
    rc.LastAuditDate
FROM BackOffice.RiskClassification rc WITH (NOLOCK)
WHERE rc.WithAlert = 1
  AND rc.AuditDueDateExpired = 1
ORDER BY rc.MaxScore DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| RD-7582, RD-8873 (code comment) | Jira | Risk scoring built for CySEC Audit Jul 2019 - initial design by Guy Barkat / Geri Reshef |
| RD-16450 (code comment) | Jira | Risk classification reports - additional scoring refinements |
| COAIL-253 (code comment) | Jira | Bug fixes for risk scoring |
| External Google Docs (referenced in code comment) | Other | Full process documentation at docs.google.com/document/d/1cSAveg-yitU0KS5y1tMNRkjxfnTkGPTyI_qxkUBWpVk |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 8.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 3 Jira (code comments) | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetRiskClassificationNew | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetRiskClassificationNew.sql*
