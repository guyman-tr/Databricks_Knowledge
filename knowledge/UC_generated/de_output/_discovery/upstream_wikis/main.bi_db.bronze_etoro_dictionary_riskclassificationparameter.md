# Dictionary.RiskClassificationParameter

> Reference table defining 46 risk classification parameters — customer attributes scored for AML/KYC risk assessment — including country of residence, occupation, income, deposits, and enhanced due diligence indicators.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RiskClassificationParameterID (INT, PK) |
| **Partition** | DICTIONARY filegroup (LOB on DICTIONARY) |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.RiskClassificationParameter defines every attribute that is scored as part of eToro's customer risk classification system. The AML/KYC risk engine evaluates each customer across these parameters to produce a risk score. Parameters span onboarding data (country, age, occupation), financial data (income, deposits, net deposit), regulatory data (screening status, World Check), and enhanced due diligence (EDD) indicators.

Parameters are split into two ranges: IDs 2-21 are standard parameters sourced from customer profile data, and IDs 1001-1025 are enhanced due diligence (EDD) parameters used for high-risk manual assessments.

Consumed by RiskCalculation.SetRiskClassificationForCySec, BackOffice.SetRiskClassificationNew, RiskCalculation.ScoresTemporary, dbo.ScoresDaily, and exposed via dbo.V_RiskClassificationParameter. Also referenced by History.RiskParameterConfiguration for audit and RiskCalculation.RiskParameterConfiguration for runtime configuration.

---

## 2. Business Logic

### 2.1 Standard Parameters (IDs 2-21)

**What**: Automated parameters sourced from customer profile, questionnaire answers, and transaction data.

**Columns/Parameters Involved**: `RiskClassificationParameterID`, `Name`, `Description`, `Source`

**Rules**:
- **Country (2-3)**: Country of residence risk, scored separately for onboarding and existing clients. Source: Customer.CustomerStatic.
- **Demographics (4-6)**: Place of birth, age, and age alerts (<21 or >65). Source: Customer.CustomerStatic.
- **Screening (7)**: World Check/screening service status. External data source.
- **Questionnaire (8-16)**: Income, occupation, investment plans, and sector risk. Source: V_CustomerAnswersNrml (customer questionnaire).
- **Financial (17-19)**: Net deposit, FTD (first-time deposit), instruments. Sources: BackOffice.CustomerAllTimeAggregatedData, Billing.Deposit.
- **Extended (20-21)**: Expected fund origin and destination. Source: UserApiDB external database.

### 2.2 EDD Parameters (IDs 1001-1025)

**What**: Enhanced Due Diligence indicators for manual/high-risk assessments.

**Rules**:
- These parameters lack Description and Source — they are manually assessed by compliance officers.
- Cover: sector risk, establishment status, public profile, disclosure, jurisdiction, AML failures, suspicious transactions, identity evidence, ownership transparency, and more.
- ID 9999 is the final composite score.

---

## 3. Data Overview

| ID | Name | Description | Source | Meaning |
|---|---|---|---|---|
| 2 | Country of Residence, Onboarding | Country by Reg. Form - Onboarding | Customer.CustomerStatic | Risk score for onboarding country |
| 7 | Screening Status | Screening Service | - | World Check/PEP screening result |
| 8 | Main Source of Income | Q15 Main income | V_CustomerAnswersNrml | Income source risk (social security/family = higher risk) |
| 17 | Net Deposit | Net Deposit | BackOffice aggregation | Total net deposits (high deposits may indicate elevated risk) |
| 1001 | SectorHighRisk | - | - | EDD: Is the customer in a high-risk sector? |
| 9999 | Final score | Final Score | - | Composite risk classification result |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RiskClassificationParameterID | int | NO | - | VERIFIED | Primary key. Standard params: 2-21, EDD params: 1001-1025, Final: 9999. Referenced by RiskCalculation.ScoresTemporary and dbo.ScoresDaily. |
| 2 | Name | varchar(50) | YES | - | VERIFIED | Short parameter label (e.g., "Country of Residence, Onboarding", "SectorHighRisk"). Used in reporting and configuration UI. |
| 3 | Description | varchar(max) | YES | - | VERIFIED | Extended description of what the parameter measures and how it maps to questionnaire answers. Empty for EDD parameters. |
| 4 | Source | varchar(200) | YES | - | VERIFIED | Data source table/view for the parameter value (e.g., "Customer.CustomerStatic", "V_CustomerAnswersNrml"). Empty for EDD and external parameters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RiskCalculation.ScoresTemporary | RiskClassificationParameterID | Implicit | Temporary scoring results |
| dbo.ScoresDaily | RiskClassificationParameterID | Implicit | Daily scoring archive |
| RiskCalculation.RiskParameterConfiguration | RiskClassificationParameterID | Implicit | Runtime parameter configuration |
| History.RiskParameterConfiguration | RiskClassificationParameterID | Implicit | Configuration audit trail |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RiskCalculation.ScoresTemporary | Table | Stores per-parameter scores |
| dbo.ScoresDaily | Table | Daily scoring archive |
| RiskCalculation.RiskParameterConfiguration | Table | Runtime parameter config |
| History.RiskParameterConfiguration | Table | Configuration audit |
| dbo.V_RiskClassificationParameter | View | Exposes parameters for reporting |
| RiskCalculation.SetRiskClassificationForCySec | Stored Procedure | Risk calculation engine |
| BackOffice.SetRiskClassificationNew | Stored Procedure | Manual risk classification |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_RiskClassificationParameter | CLUSTERED PK | RiskClassificationParameterID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_RiskClassificationParameter | PRIMARY KEY | Unique parameter identifier |

---

## 8. Sample Queries

### 8.1 List all risk parameters
```sql
SELECT  RiskClassificationParameterID,
        Name,
        Description,
        Source
FROM    [Dictionary].[RiskClassificationParameter] WITH (NOLOCK)
ORDER BY RiskClassificationParameterID;
```

### 8.2 List standard vs EDD parameters
```sql
SELECT  CASE WHEN RiskClassificationParameterID < 1000 THEN 'Standard'
             WHEN RiskClassificationParameterID = 9999 THEN 'Final Score'
             ELSE 'EDD' END AS Category,
        COUNT(*) AS ParamCount
FROM    [Dictionary].[RiskClassificationParameter] WITH (NOLOCK)
GROUP BY CASE WHEN RiskClassificationParameterID < 1000 THEN 'Standard'
              WHEN RiskClassificationParameterID = 9999 THEN 'Final Score'
              ELSE 'EDD' END;
```

### 8.3 Find parameters sourced from customer static
```sql
SELECT  RiskClassificationParameterID,
        Name
FROM    [Dictionary].[RiskClassificationParameter] WITH (NOLOCK)
WHERE   Source LIKE '%CustomerStatic%';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RiskClassificationParameter | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RiskClassificationParameter.sql*
