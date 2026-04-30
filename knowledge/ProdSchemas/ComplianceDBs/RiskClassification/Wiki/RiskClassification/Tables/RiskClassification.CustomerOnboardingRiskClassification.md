# RiskClassification.CustomerOnboardingRiskClassification

> Customer onboarding risk classification table storing a weighted composite risk score and full JSON scoring breakdown for each customer, powering the new-generation onboarding risk assessment model.

| Property | Value |
|----------|-------|
| **Schema** | RiskClassification |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table stores the results of the new-generation customer onboarding risk classification model. Unlike the legacy `dbo.T_RiskClassification` system which uses discrete score tiers (0/50/100/200), this model produces a continuous weighted composite score (decimal) that incorporates individual parameter contributions with explicit weights.

The table is critical for the onboarding flow - when a new customer registers, the risk assessment engine calculates their onboarding risk score and stores both the final score and the complete JSON breakdown of all contributing factors. This enables immediate risk-based decisioning during onboarding (e.g., additional verification requirements for higher-risk customers) and provides full transparency into why a customer received a particular score.

Data is written via `RiskClassification.UpsertCustomerOnboardingRiskClassification` (IF EXISTS UPDATE ELSE INSERT pattern) and read via `RiskClassification.GetCustomerOnboardingRiskClassification`. The table is actively updated - the most recent records are from today, indicating real-time integration with the onboarding pipeline.

---

## 2. Business Logic

### 2.1 Weighted Composite Scoring Model

**What**: A new scoring model that produces continuous decimal scores based on weighted parameter contributions, replacing the discrete tier model.

**Columns/Parameters Involved**: `Score`, `Data`

**Rules**:
- Each risk parameter has an Answer, Score, Weight, and WeightedScore
- The final `Score` is the sum of all WeightedScores across parameters
- Parameters include: CountryOfResidenceRank, PlaceOfBirthRank, CountryOfCitizenshipRank, and others
- Weights are decimals summing to 1.0 (e.g., CountryOfResidence=0.13, PlaceOfBirth=0.03)
- Common final scores: 5.0, 10.0, 11.5, 13.0, 14.5 - reflecting common parameter combinations
- The `Data` column stores the complete JSON evidence for audit/debug

### 2.2 Upsert Pattern

**What**: Scores are inserted for new customers and updated for existing ones.

**Columns/Parameters Involved**: `GCID`, `Score`, `Data`, `LastUpdate`

**Rules**:
- UpsertCustomerOnboardingRiskClassification checks IF EXISTS by GCID
- UPDATE sets Score, Data, and LastUpdate=CURRENT_TIMESTAMP for existing customers
- INSERT adds new GCID with Score, Data, and LastUpdate=CURRENT_TIMESTAMP
- LastUpdate tracks the most recent scoring event

---

## 3. Data Overview

| GCID | Score | LastUpdate | Data (preview) | Meaning |
|------|-------|-----------|----------------|---------|
| 47590708 | 4.5 | 2026-04-14 13:07 | {"Contributions":{"CountryOfResidenceRank":{"Answer":0,"Score":0,"Weight":0.13,...}...}} | Low-risk onboarding customer. Score 4.5 from weighted contributions. Country of residence scored 0 (low risk). Very recent - scored today. |
| 47586836 | 13.0 | 2026-04-14 13:06 | {"Contributions":{"CountryOfResidenceRank":{"Answer":0,"Score":0,...}...}} | Medium-risk onboarding. Score 13.0 indicates several elevated parameters despite low country risk. |
| 47590673 | 14.5 | 2026-04-14 13:06 | {"Contributions":{"CountryOfResidenceRank":{"Answer":0,"Score":0,...}...}} | Higher-risk onboarding. Score 14.5 - one of the most common elevated scores in the dataset. |

Total: ~488K customers scored. Distribution: 10.0 (50K), 5.0 (49K), 11.5 (48K), 14.5 (38K), 13.0 (28K).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. PK. One row per customer who has completed the onboarding risk assessment. Same customer identifier used across all eToro systems. |
| 2 | Score | DECIMAL(6,3) | YES | - | VERIFIED | Weighted composite onboarding risk score. Continuous decimal value representing the sum of all parameter WeightedScores. Higher values indicate higher risk. Common values: 4.5-5.0 (low), 10.0-11.5 (medium), 13.0-14.5 (elevated). Not on the 0/50/100 scale of the legacy dbo.T_RiskClassification system. |
| 3 | LastUpdate | DATETIME | NO | - | VERIFIED | Timestamp of the most recent score calculation. Set to CURRENT_TIMESTAMP on both INSERT and UPDATE by the Upsert procedure. Actively updated - recent records from today. |
| 4 | Data | NVARCHAR(4000) | YES | - | VERIFIED | Complete JSON scoring breakdown. Contains a "Contributions" object with nested objects per parameter (CountryOfResidenceRank, PlaceOfBirthRank, CountryOfCitizenshipRank, etc.), each with Answer (input value), Score (parameter score), Weight (decimal weight), and WeightedScore (Score * Weight). Added via ALTER TABLE after initial table creation - a later enhancement to provide full scoring transparency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. GCID implicitly references the customer master in the etoro database.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RiskClassification.GetCustomerOnboardingRiskClassification | SELECT | Reader | Retrieves Score and Data for a specific GCID |
| RiskClassification.UpsertCustomerOnboardingRiskClassification | INSERT/UPDATE | Writer | Creates or updates the customer's onboarding risk score |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RiskClassification.GetCustomerOnboardingRiskClassification | Stored Procedure | Reader |
| RiskClassification.UpsertCustomerOnboardingRiskClassification | Stored Procedure | Writer (Upsert) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerOnboardingRiskClassification | CLUSTERED PK | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomerOnboardingRiskClassification | PRIMARY KEY | GCID - one row per customer |

Note: The DDL file contains the CREATE TABLE as commented-out code (table was created externally) with an ALTER TABLE ADD [Data] column - indicating the Data column was added after the initial table creation.

---

## 8. Sample Queries

### 8.1 Get a customer's onboarding risk score and breakdown
```sql
SELECT GCID, Score, Data, LastUpdate
FROM RiskClassification.CustomerOnboardingRiskClassification WITH (NOLOCK)
WHERE GCID = 47590708
```

### 8.2 Find high-risk onboarding customers
```sql
SELECT TOP 100 GCID, Score, LastUpdate
FROM RiskClassification.CustomerOnboardingRiskClassification WITH (NOLOCK)
WHERE Score >= 15
ORDER BY Score DESC
```

### 8.3 Parse JSON scoring contributions
```sql
SELECT GCID, Score,
       JSON_VALUE(Data, '$.Contributions.CountryOfResidenceRank.Score') AS CountryScore,
       JSON_VALUE(Data, '$.Contributions.CountryOfResidenceRank.Weight') AS CountryWeight,
       JSON_VALUE(Data, '$.Contributions.PlaceOfBirthRank.Score') AS BirthCountryScore
FROM RiskClassification.CustomerOnboardingRiskClassification WITH (NOLOCK)
WHERE GCID = 47590708
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RiskClassification.CustomerOnboardingRiskClassification | Type: Table | Source: RiskClassification/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.sql*
