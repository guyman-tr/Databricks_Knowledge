# dbo.T_RiskClassification

> Central customer risk classification table storing the denormalized, per-customer composite risk score and all individual parameter scores used in AML/KYC compliance risk assessment.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table (Temporal - system-versioned) |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This is the primary risk classification table for the RiskClassification database. It stores one row per customer (identified by GCID), containing the overall aggregate risk score and the individual scores for every risk assessment parameter. The table is the denormalized, wide-format representation of the scoring data that also exists in normalized form in `dbo.T_Scores`.

This table is essential for compliance operations, regulatory reporting, and real-time risk decisioning. Views like `V_RiskClassification` and `V_RiskClassificationDataLake` build on it to provide enriched risk data with regulation names and risk level labels. Without it, the system would have no queryable summary of each customer's current risk posture.

Data flows into this table via the `P_RiskClassification` stored procedure, which pivots individual parameter scores from `T_Scores` (fed from `T_ScoresTemporary`) into the wide-column format. The procedure uses the `V_Scores` view to read normalized scores, then performs a DELETE+INSERT pattern for changed customers. The table is temporal (system-versioned), with all historical versions preserved in `History.T_RiskClassification`. The `P_GetRiskClassification` procedure reads this table to return a customer's current risk profile.

---

## 2. Business Logic

### 2.1 Risk Score Aggregation Model

**What**: Each customer receives individual risk scores across ~45 parameters, which are aggregated into a single composite RiskScore.

**Columns/Parameters Involved**: `RiskScore`, `RiskScore_Value`, all `*_RiskScore` columns

**Rules**:
- Each risk parameter (Country of Residence, Age, Screening Status, etc.) contributes an individual score (0, 50, or 100 typically)
- The final `RiskScore` is the aggregate - it maps to a named risk level via `Dictionary.RiskClassificationRegulation` (0=Low, 50=Medium, 100=High, 200=Unacceptable/Block)
- `RiskScore_Value` uses format `N*Score` where N is the count of parameters that contributed to the max score, and Score is the final value (e.g., "2*50" means 2 parameters scored at 50)
- The `P_GetRiskClassification` procedure parses `RiskScore_Value` by extracting the score after the `*` character

**Diagram**:
```
Individual Parameters (T_Scores)          Aggregate (T_RiskClassification)
+---------------------------+             +---------------------------+
| GCID | ParamID | Score    |             | GCID | RiskScore | Value  |
|  91  |    2    |   50     |  PIVOT via  |  91  |    100    | 1*100  |
|  91  |    7    |  100     | ---------> |      | + all individual   |
|  91  |    5    |    0     | P_RiskClass |      |   param columns    |
|  91  |  9999   |  100     |             +---------------------------+
+---------------------------+
```

### 2.2 Dual Parameter Tiers

**What**: Risk parameters are split into two tiers - standard (IDs 2-21) with weighted scoring, and CySEC EDD parameters (IDs 1001-1025) for enhanced due diligence.

**Columns/Parameters Involved**: Standard parameter columns (Country, Age, Income, etc.) and CySEC EDD columns (SectorHighRisk, EstablishmentApproved, etc.)

**Rules**:
- Standard parameters (IDs 2-21) have defined weekly and onboarding weight percentages. See [Risk Classification Parameter](_glossary.md#risk-classification-parameter) for full list.
- CySEC EDD parameters (IDs 1001-1025) have zero weight - they are scored independently for enhanced due diligence assessments
- Many CySEC EDD columns are NULL for non-CySEC customers

### 2.3 Temporal Versioning

**What**: Full history of every customer's risk classification changes is preserved via SQL Server system-versioned temporal tables.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`

**Rules**:
- `BeginTime` records when the current score became effective (set to `GETUTCDATE()` on insert/update)
- `EndTime` is set to `9999-12-31 23:59:59.9999999` for the current row
- On update, the previous version moves to `History.T_RiskClassification` with EndTime set to the update timestamp
- Enables point-in-time queries: `SELECT * FROM T_RiskClassification FOR SYSTEM_TIME AS OF '2023-01-01'`

---

## 3. Data Overview

| GCID | CID | RegulationID | RiskScore | RiskScore_Value | Country Onboarding | Screening Status | Meaning |
|------|-----|-------------|-----------|----------------|-------------------|-----------------|---------|
| 3 | 3694577 | 1 (CySEC) | 50 (Medium) | 2*50 | Israel (100) | No Value (0) | CySEC customer from Israel (high-risk country, score 100) but overall Medium risk. Age 123 suggests data quality issue or very old customer. |
| 11 | 683703 | 1 (CySEC) | 50 (Medium) | 1*50 | Spain (0) | NULL | CySEC customer from Spain (low-risk country). Only 1 parameter scored at 50, pushing to Medium overall. PEP Check score is 0. |
| 91 | 683770 | 1 (CySEC) | 100 (High) | 1*100 | Turkey (50) | 2 (100) | CySEC customer from Turkey (medium-risk). Screening Status value "2" triggers score 100 (High), which becomes the final score. This is the highest-impact parameter for this customer. |

**Distribution**: ~5M rows. RiskScore: 91% Medium (50), 7.7% High (100), 1.3% Low (0), 1 Unacceptable (200). Regulation: 57% CySEC, 24% FCA, 7% ASIC&GAML, 6% FinCEN+FINRA.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID - unique identifier for a customer account across the eToro platform. PK of this table. One row per customer. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID - secondary customer identifier. Populated from T_Scores via P_RiskClassification as `Max(CID)`. |
| 3 | RegulationID | INT | YES | - | VERIFIED | Regulatory jurisdiction for this customer. Determines which risk score thresholds and parameter weights apply. FK to Dictionary.Regulation: 0=None, 1=CySEC, 2=FCA, 4=ASIC, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 14=NYDFSFINRA. See [Regulation](_glossary.md#regulation). |
| 4 | RiskScore | INT | YES | - | VERIFIED | Final aggregate risk classification score. Maps to named levels via Dictionary.RiskClassificationRegulation: 0=Low, 25=Medium Low (CySEC/FCA), 50=Medium, 75=Medium High (CySEC/FCA), 100=High, 200=Unacceptable/Block. See [Risk Classification Regulation](_glossary.md#risk-classification-regulation). Derived from parameter 9999 in T_Scores. |
| 5 | RiskScore_Value | VARCHAR(50) | YES | - | CODE-BACKED | Formula summary for the final score in format `N*Score` where N = count of parameters at the max score level and Score = the aggregate score value. P_GetRiskClassification parses this by extracting the portion after the `*` character. |
| 6 | BeginTime | DATETIME2(7) | NO | GETUTCDATE() | VERIFIED | Temporal system start time. Set automatically when the row is inserted or updated. Indicates when this risk classification became effective. GENERATED ALWAYS AS ROW START. |
| 7 | EndTime | DATETIME2(7) | NO | 9999-12-31 23:59:59.9999999 | VERIFIED | Temporal system end time. Set to far-future for current rows. Updated automatically when the row is modified (previous version moves to History). GENERATED ALWAYS AS ROW END. |
| 8 | Country of Residence, Onboarding_RiskScore | INT | YES | - | VERIFIED | Risk score for customer's country of residence at onboarding. 0=Low risk country, 50=Medium, 100=High risk country. Source: Customer.CustomerStatic. Parameter ID 2. Weekly weight: 2.5%, Onboarding weight: 4%. |
| 9 | Country of Residence, Onboarding_Value | VARCHAR(50) | YES | - | VERIFIED | Country name used for onboarding risk scoring (e.g., "Israel", "Spain", "Turkey"). The actual country name from the customer's registration form. |
| 10 | Country of Residence, Existing clients_RiskScore | INT | YES | - | CODE-BACKED | Risk score for customer's country for ongoing (post-onboarding) monitoring. Same scale as onboarding. Parameter ID 3. Weekly weight: 4%, Onboarding weight: 9%. |
| 11 | Country of Residence, Existing clients_Value | VARCHAR(50) | YES | - | CODE-BACKED | Country name used for existing-client risk scoring. |
| 12 | Age of customer_RiskScore | INT | YES | - | CODE-BACKED | Risk score based on customer age. Parameter ID 5. Source: Customer.CustomerStatic. Weekly weight: 0.2%, Onboarding weight: 2%. |
| 13 | Age of customer_Value | VARCHAR(50) | YES | - | CODE-BACKED | Customer's age as a string (e.g., "41", "123"). Used for risk band determination. |
| 14 | Age Alert_RiskScore | INT | YES | - | CODE-BACKED | Alert flag score for age extremes (<21 or >65). Parameter ID 6. Zero weight - informational only. |
| 15 | Age Alert_Value | VARCHAR(50) | YES | - | CODE-BACKED | Age alert value - indicates whether the age alert was triggered. |
| 16 | PEP Check_RiskScore | INT | YES | - | CODE-BACKED | Risk score from Politically Exposed Person check. Parameter ID not in current Dictionary (may be legacy - replaced by Screening Status). |
| 17 | PEP Check_Value | VARCHAR(50) | YES | - | CODE-BACKED | PEP check result value. |
| 18 | Main Source of Income_RiskScore | INT | YES | - | CODE-BACKED | Risk score based on primary income source (Q15 questionnaire). Parameter ID 8. Social security, family support, "Other" are high-risk categories. Weekly weight: 0.8%, Onboarding weight: 1.5%. |
| 19 | Main Source of Income_Value | VARCHAR(50) | YES | - | CODE-BACKED | Income source category name from questionnaire response. |
| 20 | Occupation_RiskScore | INT | YES | - | CODE-BACKED | Risk score based on occupation type (Q18 questionnaire). Parameter ID 9. Real Estate, Healthcare, Construction, None are elevated-risk. Weekly weight: 0.5%, Onboarding weight: 1%. |
| 21 | Occupation_Value | VARCHAR(100) | YES | - | CODE-BACKED | Occupation description from questionnaire response. VARCHAR(100) - longer than other Value columns due to free-text occupation descriptions. |
| 22 | Special Score_RiskScore | INT | YES | - | CODE-BACKED | Special override score for maximum-score logic. Parameter ID 10. Triggered by Student or None occupation. |
| 23 | Special Score_Value | VARCHAR(50) | YES | - | CODE-BACKED | Special score trigger value. |
| 24 | Annual Income_RiskScore | INT | YES | - | CODE-BACKED | Risk score based on annual income band (Q10 questionnaire). Parameter ID 11. Lower income (<$25k) = higher risk. Weekly weight: 1.2%, Onboarding weight: 1.5%. |
| 25 | Annual Income_Value | VARCHAR(50) | YES | - | CODE-BACKED | Annual income band label from questionnaire response. |
| 26 | Total Cash And Liquid Assets_RiskScore | INT | YES | - | CODE-BACKED | Risk score based on reported liquid assets (Q11). Parameter ID 12. Weekly weight: 1%, Onboarding weight: 2%. |
| 27 | Total Cash And Liquid Assets_Value | VARCHAR(50) | YES | - | CODE-BACKED | Liquid assets band label. |
| 28 | Money plan To invest_RiskScore | INT | YES | - | CODE-BACKED | Risk score based on planned investment amount (Q14). Parameter ID 13. Weekly weight: 0.8%, Onboarding weight: 1.5%. |
| 29 | Money plan To invest_Value | VARCHAR(50) | YES | - | CODE-BACKED | Planned investment amount band label. |
| 30 | High Risk_RiskScore | INT | YES | - | CODE-BACKED | Binary flag for Healthcare/Construction occupations. Parameter ID 14. Zero weight - classification tag only. |
| 31 | High Risk_Value | VARCHAR(50) | YES | - | CODE-BACKED | High risk occupation flag value. |
| 32 | Sector ML TF_RiskScore | INT | YES | - | CODE-BACKED | Money Laundering / Terrorist Financing sector flag. Parameter ID 15. Healthcare/Construction. Zero weight. |
| 33 | Sector ML TF_Value | VARCHAR(50) | YES | - | CODE-BACKED | ML/TF sector flag value. |
| 34 | Sector High Cash_RiskScore | INT | YES | - | CODE-BACKED | High cash-intensive sector flag. Parameter ID 16. Arts/Construction. Zero weight. |
| 35 | Sector High Cash_Value | VARCHAR(50) | YES | - | CODE-BACKED | High cash sector flag value. |
| 36 | Net Deposit_RiskScore | INT | YES | - | CODE-BACKED | Risk score based on net deposit amount. Parameter ID 17. Source: BackOffice.CustomerAllTimeAggregatedData. Zero weight. |
| 37 | Net Deposit_Value | VARCHAR(50) | YES | - | CODE-BACKED | Net deposit amount or band. |
| 38 | Instruments Planned Investment_RiskScore | INT | YES | - | CODE-BACKED | Risk from planned instrument types (Q questionnaire). Parameter ID 18. Weekly weight: 0.3%, Onboarding weight: 1%. |
| 39 | Instruments Planned Investment_Value | VARCHAR(50) | YES | - | CODE-BACKED | Planned investment instrument types. |
| 40 | FTD_RiskScore | INT | YES | - | CODE-BACKED | Risk score based on First Time Deposit amount. Parameter ID 19. Source: Billing.Deposit. Zero weight. |
| 41 | FTD_Value | VARCHAR(50) | YES | - | CODE-BACKED | First Time Deposit amount or band. |
| 42 | ScoreExpectedOriginFunds_RiskScore | INT | YES | - | CODE-BACKED | Risk from expected origin of incoming funds. Parameter ID 20. Source: UserApiDB_rep.Customer.ExtendedUserField. |
| 43 | ScoreExpectedOriginFunds_Value | VARCHAR(50) | YES | - | CODE-BACKED | Expected funds origin category. |
| 44 | ScoreExpectedDestinationPayments_RiskScore | INT | YES | - | CODE-BACKED | Risk from expected destination of outgoing payments. Parameter ID 21. Source: UserApiDB_rep.Customer.ExtendedUserField. |
| 45 | ScoreExpectedDestinationPayments_Value | VARCHAR(50) | YES | - | CODE-BACKED | Expected payments destination category. |
| 46 | SectorHighRisk_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - whether customer's sector is high-risk. Parameter ID 1001. Zero weight. |
| 47 | SectorHighRisk_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD high-risk sector value. |
| 48 | Sector_ML_TF_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - ML/TF sector risk. Parameter ID 1002. Zero weight. |
| 49 | Sector_ML_TF_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD ML/TF sector value. |
| 50 | SectorHighCash_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - high cash-intensive sector. Parameter ID 1003. Zero weight. |
| 51 | SectorHighCash_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD high cash sector value. |
| 52 | EstablishmentApproved_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - whether establishment is approved/regulated. Parameter ID 1004. |
| 53 | EstablishmentApproved_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD establishment approved value. |
| 54 | HighPublicProfile_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - high public profile (PEP-like). Parameter ID 1005. |
| 55 | HighPublicProfile_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD high public profile value. |
| 56 | DisclosureSubjected_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - subject to disclosure requirements. Parameter ID 1006. |
| 57 | DisclosureSubjected_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD disclosure subjected value. |
| 58 | RegionSupervised_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - whether region has adequate AML supervision. Parameter ID 1007. |
| 59 | RegionSupervised_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD region supervised value. |
| 60 | JurisdictionNonCorrupt_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - whether jurisdiction is non-corrupt (Transparency International). Parameter ID 1008. |
| 61 | JurisdictionNonCorrupt_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD jurisdiction non-corrupt value. |
| 62 | AML_CFT_Failure_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - jurisdiction AML/CFT failures (FATF grey/blacklist). Parameter ID 1009. |
| 63 | AML_CFT_Failure_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD AML/CFT failure value. |
| 64 | BackgroundConsistent_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - whether customer background information is consistent. Parameter ID 1010. |
| 65 | BackgroundConsistent_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD background consistency value. |
| 66 | TransactionSuspicious_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - suspicious transaction patterns. Parameter ID 1011. |
| 67 | TransactionSuspicious_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD suspicious transactions value. |
| 68 | IdentityEvidence_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - quality of identity evidence. Parameter ID 1012. |
| 69 | IdentityEvidence_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD identity evidence value. |
| 70 | AvoidBusinessRelations_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - attempts to avoid normal business procedures. Parameter ID 1013. |
| 71 | AvoidBusinessRelations_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD avoid business relations value. |
| 72 | OwnershipTransparent_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - transparency of ownership structure. Parameter ID 1014. |
| 73 | OwnershipTransparent_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD ownership transparency value. |
| 74 | AssetHoldingVehicle_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - use of asset-holding vehicles. Parameter ID 1015. |
| 75 | AssetHoldingVehicle_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD asset holding vehicle value. |
| 76 | TransactionsUnusual_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - unusual transaction patterns. Parameter ID 1016. |
| 77 | TransactionsUnusual_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD unusual transactions value. |
| 78 | SecrecyUnreasonable_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - unreasonable secrecy requests. Parameter ID 1017. |
| 79 | SecrecyUnreasonable_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD unreasonable secrecy value. |
| 80 | NFTF_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - Non-Face-To-Face identification risk. Parameter ID 1018. |
| 81 | NFTF_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD NFTF value. |
| 82 | IdentityDoubts_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - doubts about identity or document authenticity. Parameter ID 1019. |
| 83 | IdentityDoubts_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD identity doubts value. |
| 84 | ExpectedProductsUsed_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - risk from expected product/service usage. Parameter ID 1020. |
| 85 | ExpectedProductsUsed_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD expected products used value. |
| 86 | NonProfitOrgAbused_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - non-profit organization abuse risk. Parameter ID 1021. |
| 87 | NonProfitOrgAbused_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD non-profit org abused value. |
| 88 | CooperativeClient_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - level of customer cooperation during due diligence. Parameter ID 1022. |
| 89 | CooperativeClient_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD cooperative client value. |
| 90 | IdentityAnonymous_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - anonymous/pseudo-anonymous identity indicators. Parameter ID 1023. |
| 91 | IdentityAnonymous_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD identity anonymous value. |
| 92 | TransactionComplexity_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - complexity of transaction patterns. Parameter ID 1024. |
| 93 | TransactionComplexity_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD transaction complexity value. |
| 94 | PaymentsThirdParty_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD - third-party payment involvement. Parameter ID 1025. |
| 95 | PaymentsThirdParty_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD third-party payments value. |
| 96 | Place of Birth_RiskScore | INT | YES | - | CODE-BACKED | Risk score based on country of birth. Parameter ID 4. Weekly weight: 0.3%, Onboarding weight: 2%. |
| 97 | Place of Birth_Value | VARCHAR(50) | YES | - | CODE-BACKED | Country of birth name. |
| 98 | Screening Status_RiskScore | INT | YES | - | VERIFIED | Risk score from external screening/sanctions check. Parameter ID 7. Highest-weighted parameter: 5.2% weekly, 6.5% onboarding. Values observed: 0 (clear), 100 (flagged). |
| 99 | Screening Status_Value | VARCHAR(50) | YES | - | VERIFIED | Screening result value. Observed: "No Value" (no screening result), "2" (flagged - triggers score 100). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RegulationID | Dictionary.Regulation | Implicit FK | Determines which regulatory jurisdiction's scoring thresholds apply to this customer |
| RiskScore + RegulationID | Dictionary.RiskClassificationRegulation | Implicit composite lookup | Maps the numeric RiskScore to a named risk level (Low/Medium/High/etc.) per regulation |
| GCID | etoro.Customer (external) | Implicit cross-DB FK | References the customer master record in the etoro source database |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.V_RiskClassification | R.* | Base table (FROM) | Primary view that enriches this table with regulation names, risk level labels, and score explanations |
| dbo.V_RiskClassificationDataLake | R.* | Base table (FROM) | BI-oriented view with sanitized column names for data lake export |
| dbo.V_RiskClassification_4_SynapseExport | via V_RiskClassification | Indirect (view-on-view) | Synapse export view consuming V_RiskClassification |
| dbo.V_RiskClassification_4_SynapseExport2 | via V_RiskClassification | Indirect (view-on-view) | Synapse export view v2 |
| dbo.V_RiskClassification_4_SynapseExport3 | History.T_RiskClassification | History table read | Reads the temporal history table directly for historical exports |
| dbo.V_RiskClassification_History | History.T_RiskClassification | History table read | Reads the temporal history table for historical analysis |
| dbo.P_RiskClassification | T_RiskClassification | Writer (DELETE+INSERT) | Main procedure that recalculates and writes risk scores |
| dbo.P_GetRiskClassification | T_RiskClassification | Reader (dynamic SQL SELECT) | Reads customer risk profile with dynamic column list |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (it is a table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_RiskClassification | View | Base table (FROM + JOINs to Dictionary tables) |
| dbo.V_RiskClassificationDataLake | View | Base table (FROM + JOINs) |
| dbo.P_RiskClassification | Stored Procedure | Writer - DELETE+INSERT pattern to refresh scores |
| dbo.P_GetRiskClassification | Stored Procedure | Reader - dynamic SQL SELECT with optional GCID filter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_dbo_T_RiskClassification | CLUSTERED PK | GCID ASC | - | - | Active (DATA_COMPRESSION = PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_dbo_T_RiskClassification_BeginTime | DEFAULT | GETUTCDATE() - temporal row start defaults to current UTC time |
| Df_dbo_T_RiskClassification_EndTime | DEFAULT | '99991231 23:59:59.9999999' - temporal row end defaults to far-future |
| SYSTEM_VERSIONING | Temporal | ON with HISTORY_TABLE=[History].[T_RiskClassification], DATA_CONSISTENCY_CHECK=ON |

---

## 8. Sample Queries

### 8.1 Get a customer's current risk classification with named level
```sql
SELECT r.GCID, r.CID, r.RegulationID, reg.Name AS Regulation,
       r.RiskScore, rcr.Name AS RiskLevel, r.RiskScore_Value, r.BeginTime
FROM dbo.T_RiskClassification r WITH (NOLOCK)
INNER JOIN Dictionary.Regulation reg WITH (NOLOCK) ON r.RegulationID = reg.ID
INNER JOIN Dictionary.RiskClassificationRegulation rcr WITH (NOLOCK)
    ON r.RiskScore = rcr.RiskScore AND r.RegulationID = rcr.RegulationID
WHERE r.GCID = 91
```

### 8.2 Find all High or Unacceptable risk customers by regulation
```sql
SELECT r.GCID, reg.Name AS Regulation, rcr.Name AS RiskLevel, r.RiskScore
FROM dbo.T_RiskClassification r WITH (NOLOCK)
INNER JOIN Dictionary.Regulation reg WITH (NOLOCK) ON r.RegulationID = reg.ID
INNER JOIN Dictionary.RiskClassificationRegulation rcr WITH (NOLOCK)
    ON r.RiskScore = rcr.RiskScore AND r.RegulationID = rcr.RegulationID
WHERE r.RiskScore >= 100
ORDER BY r.RiskScore DESC, reg.Name
```

### 8.3 Check which parameters triggered a customer's high score
```sql
SELECT r.GCID, r.RiskScore,
       [Country of Residence, Onboarding_RiskScore] AS CountryOnboard,
       [Screening Status_RiskScore] AS Screening,
       [Age of customer_RiskScore] AS Age,
       [Main Source of Income_RiskScore] AS Income,
       [Occupation_RiskScore] AS Occupation
FROM dbo.T_RiskClassification r WITH (NOLOCK)
WHERE r.GCID = 91
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 95 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (P_RiskClassification, P_GetRiskClassification) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.T_RiskClassification | Type: Table | Source: RiskClassification/dbo/Tables/dbo.T_RiskClassification.sql*
