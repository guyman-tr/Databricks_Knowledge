# dbo.T_RiskClassification20200122

> Archived snapshot of the customer risk classification table from 2020-01-22, preserving the legacy schema that included SubValue columns for each risk parameter alongside Score and Value columns.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table (Temporal - system-versioned) |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table is a point-in-time archive of the customer risk classification data, created on or around 2020-01-22 to preserve the legacy schema before a structural change to the main `T_RiskClassification` table. It contains the same core data (one row per customer with aggregate and individual parameter risk scores) but includes an additional `_SubValue` column for every risk parameter that was later removed from the current schema.

The table exists to preserve historical risk classification data in its original format, including the SubValue dimension that was dropped from the active table. This ensures compliance audit trails and regulatory lookback requirements can reference the exact data as it existed before the schema migration.

Data in this table is static from the original snapshot period. It is temporal (system-versioned with `History.T_RiskClassification20200122`) to preserve any modifications made to the archive itself. The table has ~698K rows, significantly fewer than the current T_RiskClassification (~5M rows), reflecting the smaller customer base at the time.

---

## 2. Business Logic

### 2.1 Three-Dimensional Parameter Scoring (Legacy Schema)

**What**: Unlike the current T_RiskClassification which stores Score + Value per parameter, this archive table stored Score + Value + SubValue - a three-dimensional representation of each risk factor.

**Columns/Parameters Involved**: All `*_RiskScore`, `*_Value`, `*_SubValue` column triplets

**Rules**:
- `_RiskScore`: The numeric risk score for the parameter (same as current schema: 0, 50, 100)
- `_Value`: The score value or label used to determine the risk score (in legacy format - often numeric codes like "0" rather than descriptive names)
- `_SubValue`: An additional dimension - appears to contain reference IDs or codes (e.g., country IDs like "79", "102" for Country of Residence). This provided the raw source identifier that was used to derive the Value and Score
- The SubValue columns were removed from the main T_RiskClassification table in the 2020 schema redesign, consolidating to the two-column (Score + Value) pattern

### 2.2 Temporal Versioning

**What**: Same temporal versioning as the main table.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`

**Rules**:
- History preserved in `History.T_RiskClassification20200122`
- BeginTime defaults to GETUTCDATE(), EndTime to far-future
- Data appears to originate from early January 2020 based on sample BeginTime values

---

## 3. Data Overview

| GCID | CID | RegulationID | RiskScore | RiskScore_Value | Country Onboarding Score | Country Value | Country SubValue | Meaning |
|------|-----|-------------|-----------|----------------|------------------------|---------------|-----------------|---------|
| 512105 | 1064903 | 1 (CySEC) | 0 (Low) | 31*0 | 0 | 0 | 79 | CySEC customer with Low risk. 31 parameters scored at 0. Country SubValue "79" is a country reference ID used to derive the zero risk score. Legacy value format uses numeric codes rather than country names. |
| 512309 | 1065073 | 1 (CySEC) | 0 (Low) | 34*0 | 0 | 0 | 102 | CySEC customer with Low risk. 34 parameters at 0. Different country (SubValue 102) but same zero country risk. |

Total: ~698K rows (smaller customer base at time of snapshot).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. PK. Same as in T_RiskClassification - one row per customer at time of snapshot. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID - secondary identifier. |
| 3 | RegulationID | INT | YES | - | VERIFIED | Regulatory jurisdiction. FK to Dictionary.Regulation. See [Regulation](_glossary.md#regulation). |
| 4 | RiskScore | INT | YES | - | VERIFIED | Final aggregate risk score. See [Risk Classification Regulation](_glossary.md#risk-classification-regulation). |
| 5 | RiskScore_Value | VARCHAR(50) | YES | - | CODE-BACKED | Formula summary in `N*Score` format. |
| 6 | BeginTime | DATETIME2(7) | NO | GETUTCDATE() | VERIFIED | Temporal row start. GENERATED ALWAYS AS ROW START. |
| 7 | EndTime | DATETIME2(7) | NO | 9999-12-31... | VERIFIED | Temporal row end. GENERATED ALWAYS AS ROW END. |
| 8 | Country of Residence, Onboarding_RiskScore | INT | YES | - | CODE-BACKED | Risk score for onboarding country. Parameter ID 2. |
| 9 | Country of Residence, Onboarding_Value | VARCHAR(50) | YES | - | CODE-BACKED | Country value used for scoring (legacy format - numeric code, not country name). |
| 10 | Country of Residence, Onboarding_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Raw country reference ID (e.g., "79", "102") used to derive the risk score. This additional dimension was removed in the 2020 schema redesign of T_RiskClassification. |
| 11 | Country of Residence, Existing clients_RiskScore | INT | YES | - | CODE-BACKED | Risk score for existing-client country monitoring. Parameter ID 3. |
| 12 | Country of Residence, Existing clients_Value | VARCHAR(50) | YES | - | CODE-BACKED | Existing-client country value. |
| 13 | Country of Residence, Existing clients_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Raw country reference ID for existing-client scoring. |
| 14 | Age of customer_RiskScore | INT | YES | - | CODE-BACKED | Age risk score. Parameter ID 5. |
| 15 | Age of customer_Value | VARCHAR(50) | YES | - | CODE-BACKED | Age value for scoring. |
| 16 | Age of customer_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Raw age sub-value. |
| 17 | Age Alert_RiskScore | INT | YES | - | CODE-BACKED | Age alert score. Parameter ID 6. |
| 18 | Age Alert_Value | VARCHAR(50) | YES | - | CODE-BACKED | Age alert value. |
| 19 | Age Alert_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Age alert sub-value. |
| 20 | PEP Check_RiskScore | INT | YES | - | CODE-BACKED | PEP check score. |
| 21 | PEP Check_Value | VARCHAR(50) | YES | - | CODE-BACKED | PEP check value. |
| 22 | PEP Check_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | PEP check sub-value. |
| 23 | Main Source of Income_RiskScore | INT | YES | - | CODE-BACKED | Income source risk score. Parameter ID 8. |
| 24 | Main Source of Income_Value | VARCHAR(50) | YES | - | CODE-BACKED | Income source value. |
| 25 | Main Source of Income_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Income source sub-value. |
| 26 | Occupation_RiskScore | INT | YES | - | CODE-BACKED | Occupation risk score. Parameter ID 9. |
| 27 | Occupation_Value | VARCHAR(50) | YES | - | CODE-BACKED | Occupation value. |
| 28 | Occupation_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Occupation sub-value. |
| 29 | Special Score_RiskScore | INT | YES | - | CODE-BACKED | Special override score. Parameter ID 10. |
| 30 | Special Score_Value | VARCHAR(50) | YES | - | CODE-BACKED | Special score value. |
| 31 | Special Score_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Special score sub-value. |
| 32 | Annual Income_RiskScore | INT | YES | - | CODE-BACKED | Annual income risk score. Parameter ID 11. |
| 33 | Annual Income_Value | VARCHAR(50) | YES | - | CODE-BACKED | Annual income value. |
| 34 | Annual Income_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Annual income sub-value. |
| 35 | Total Cash And Liquid Assets_RiskScore | INT | YES | - | CODE-BACKED | Liquid assets risk score. Parameter ID 12. |
| 36 | Total Cash And Liquid Assets_Value | VARCHAR(50) | YES | - | CODE-BACKED | Liquid assets value. |
| 37 | Total Cash And Liquid Assets_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Liquid assets sub-value. |
| 38 | Money plan To invest_RiskScore | INT | YES | - | CODE-BACKED | Planned investment risk score. Parameter ID 13. |
| 39 | Money plan To invest_Value | VARCHAR(50) | YES | - | CODE-BACKED | Planned investment value. |
| 40 | Money plan To invest_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Planned investment sub-value. |
| 41 | High Risk_RiskScore | INT | YES | - | CODE-BACKED | High-risk sector flag. Parameter ID 14. |
| 42 | High Risk_Value | VARCHAR(50) | YES | - | CODE-BACKED | High risk value. |
| 43 | High Risk_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | High risk sub-value. |
| 44 | Sector ML TF_RiskScore | INT | YES | - | CODE-BACKED | ML/TF sector flag. Parameter ID 15. |
| 45 | Sector ML TF_Value | VARCHAR(50) | YES | - | CODE-BACKED | ML/TF sector value. |
| 46 | Sector ML TF_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | ML/TF sector sub-value. |
| 47 | Sector High Cash_RiskScore | INT | YES | - | CODE-BACKED | High cash sector flag. Parameter ID 16. |
| 48 | Sector High Cash_Value | VARCHAR(50) | YES | - | CODE-BACKED | High cash sector value. |
| 49 | Sector High Cash_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | High cash sector sub-value. |
| 50 | Net Deposit_RiskScore | INT | YES | - | CODE-BACKED | Net deposit risk score. Parameter ID 17. |
| 51 | Net Deposit_Value | VARCHAR(50) | YES | - | CODE-BACKED | Net deposit value. |
| 52 | Net Deposit_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Net deposit sub-value. |
| 53 | Instruments Planned Investment_RiskScore | INT | YES | - | CODE-BACKED | Planned instruments risk. Parameter ID 18. |
| 54 | Instruments Planned Investment_Value | VARCHAR(50) | YES | - | CODE-BACKED | Planned instruments value. |
| 55 | Instruments Planned Investment_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Planned instruments sub-value. |
| 56 | FTD_RiskScore | INT | YES | - | CODE-BACKED | First Time Deposit risk. Parameter ID 19. |
| 57 | FTD_Value | VARCHAR(50) | YES | - | CODE-BACKED | FTD value. |
| 58 | FTD_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | FTD sub-value. |
| 59 | ScoreExpectedOriginFunds_RiskScore | INT | YES | - | CODE-BACKED | Expected funds origin risk. Parameter ID 20. |
| 60 | ScoreExpectedOriginFunds_Value | VARCHAR(50) | YES | - | CODE-BACKED | Expected funds origin value. |
| 61 | ScoreExpectedOriginFunds_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Expected funds origin sub-value. |
| 62 | ScoreExpectedDestinationPayments_RiskScore | INT | YES | - | CODE-BACKED | Expected payments destination risk. Parameter ID 21. |
| 63 | ScoreExpectedDestinationPayments_Value | VARCHAR(50) | YES | - | CODE-BACKED | Expected payments destination value. |
| 64 | ScoreExpectedDestinationPayments_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | Expected payments destination sub-value. |
| 65 | SectorHighRisk_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD high-risk sector. Parameter ID 1001. |
| 66 | SectorHighRisk_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD high-risk sector value. |
| 67 | SectorHighRisk_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD high-risk sector sub-value. |
| 68 | Sector_ML_TF_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD ML/TF sector. Parameter ID 1002. |
| 69 | Sector_ML_TF_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD ML/TF value. |
| 70 | Sector_ML_TF_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD ML/TF sub-value. |
| 71 | SectorHighCash_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD high cash sector. Parameter ID 1003. |
| 72 | SectorHighCash_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD high cash value. |
| 73 | SectorHighCash_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD high cash sub-value. |
| 74 | EstablishmentApproved_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD establishment approved. Parameter ID 1004. |
| 75 | EstablishmentApproved_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD establishment approved value. |
| 76 | EstablishmentApproved_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD establishment approved sub-value. |
| 77 | HighPublicProfile_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD high public profile. Parameter ID 1005. |
| 78 | HighPublicProfile_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD high public profile value. |
| 79 | HighPublicProfile_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD high public profile sub-value. |
| 80 | DisclosureSubjected_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD disclosure subjected. Parameter ID 1006. |
| 81 | DisclosureSubjected_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD disclosure subjected value. |
| 82 | DisclosureSubjected_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD disclosure subjected sub-value. |
| 83 | RegionSupervised_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD region supervised. Parameter ID 1007. |
| 84 | RegionSupervised_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD region supervised value. |
| 85 | RegionSupervised_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD region supervised sub-value. |
| 86 | JurisdictionNonCorrupt_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD jurisdiction non-corrupt. Parameter ID 1008. |
| 87 | JurisdictionNonCorrupt_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD jurisdiction value. |
| 88 | JurisdictionNonCorrupt_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD jurisdiction sub-value. |
| 89 | AML_CFT_Failure_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD AML/CFT failure. Parameter ID 1009. |
| 90 | AML_CFT_Failure_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD AML/CFT value. |
| 91 | AML_CFT_Failure_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD AML/CFT sub-value. |
| 92 | BackgroundConsistent_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD background consistent. Parameter ID 1010. |
| 93 | BackgroundConsistent_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD background value. |
| 94 | BackgroundConsistent_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD background sub-value. |
| 95 | TransactionSuspicious_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD suspicious transactions. Parameter ID 1011. |
| 96 | TransactionSuspicious_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD suspicious transactions value. |
| 97 | TransactionSuspicious_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD suspicious transactions sub-value. |
| 98 | IdentityEvidence_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD identity evidence. Parameter ID 1012. |
| 99 | IdentityEvidence_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD identity evidence value. |
| 100 | IdentityEvidence_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD identity evidence sub-value. |
| 101 | AvoidBusinessRelations_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD avoid business relations. Parameter ID 1013. |
| 102 | AvoidBusinessRelations_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD value. |
| 103 | AvoidBusinessRelations_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD sub-value. |
| 104 | OwnershipTransparent_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD ownership transparent. Parameter ID 1014. |
| 105 | OwnershipTransparent_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD value. |
| 106 | OwnershipTransparent_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD sub-value. |
| 107 | AssetHoldingVehicle_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD asset holding vehicle. Parameter ID 1015. |
| 108 | AssetHoldingVehicle_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD value. |
| 109 | AssetHoldingVehicle_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD sub-value. |
| 110 | TransactionsUnusual_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD unusual transactions. Parameter ID 1016. |
| 111 | TransactionsUnusual_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD value. |
| 112 | TransactionsUnusual_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD sub-value. |
| 113 | SecrecyUnreasonable_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD unreasonable secrecy. Parameter ID 1017. |
| 114 | SecrecyUnreasonable_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD value. |
| 115 | SecrecyUnreasonable_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD sub-value. |
| 116 | NFTF_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD Non-Face-To-Face. Parameter ID 1018. |
| 117 | NFTF_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD value. |
| 118 | NFTF_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD sub-value. |
| 119 | IdentityDoubts_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD identity doubts. Parameter ID 1019. |
| 120 | IdentityDoubts_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD value. |
| 121 | IdentityDoubts_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD sub-value. |
| 122 | ExpectedProductsUsed_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD expected products. Parameter ID 1020. |
| 123 | ExpectedProductsUsed_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD value. |
| 124 | ExpectedProductsUsed_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD sub-value. |
| 125 | NonProfitOrgAbused_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD non-profit abuse. Parameter ID 1021. |
| 126 | NonProfitOrgAbused_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD value. |
| 127 | NonProfitOrgAbused_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD sub-value. |
| 128 | CooperativeClient_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD cooperative client. Parameter ID 1022. |
| 129 | CooperativeClient_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD value. |
| 130 | CooperativeClient_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD sub-value. |
| 131 | IdentityAnonymous_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD anonymous identity. Parameter ID 1023. |
| 132 | IdentityAnonymous_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD value. |
| 133 | IdentityAnonymous_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD sub-value. |
| 134 | TransactionComplexity_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD transaction complexity. Parameter ID 1024. |
| 135 | TransactionComplexity_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD value. |
| 136 | TransactionComplexity_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD sub-value. |
| 137 | PaymentsThirdParty_RiskScore | INT | YES | - | CODE-BACKED | CySEC EDD third-party payments. Parameter ID 1025. |
| 138 | PaymentsThirdParty_Value | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD value. |
| 139 | PaymentsThirdParty_SubValue | VARCHAR(50) | YES | - | CODE-BACKED | CySEC EDD sub-value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RegulationID | Dictionary.Regulation | Implicit FK | Regulatory jurisdiction lookup |
| RiskScore + RegulationID | Dictionary.RiskClassificationRegulation | Implicit composite lookup | Risk level name resolution |

### 5.2 Referenced By (other objects point to this)

No other objects in the SSDT repo reference this archive table. It is a standalone historical artifact.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_dbo_T_RiskClassification20200122 | CLUSTERED PK | GCID ASC | - | - | Active (DATA_COMPRESSION = PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_dbo_T_RiskClassification_BeginTime20200122 | DEFAULT | GETUTCDATE() |
| Df_dbo_T_RiskClassification_EndTime20200122 | DEFAULT | '99991231 23:59:59.9999999' |
| SYSTEM_VERSIONING | Temporal | ON with HISTORY_TABLE=[History].[T_RiskClassification20200122] |

---

## 8. Sample Queries

### 8.1 Compare a customer's legacy vs current risk score
```sql
SELECT 'Legacy (2020)' AS Source, a.GCID, a.RiskScore, a.RiskScore_Value, a.RegulationID
FROM dbo.T_RiskClassification20200122 a WITH (NOLOCK)
WHERE a.GCID = @GCID
UNION ALL
SELECT 'Current' AS Source, c.GCID, c.RiskScore, c.RiskScore_Value, c.RegulationID
FROM dbo.T_RiskClassification c WITH (NOLOCK)
WHERE c.GCID = @GCID
```

### 8.2 Find customers with SubValue data for country analysis
```sql
SELECT TOP 100 GCID, [Country of Residence, Onboarding_Value],
       [Country of Residence, Onboarding_SubValue],
       [Country of Residence, Onboarding_RiskScore]
FROM dbo.T_RiskClassification20200122 WITH (NOLOCK)
WHERE [Country of Residence, Onboarding_SubValue] IS NOT NULL
```

### 8.3 Risk distribution in the legacy snapshot
```sql
SELECT RiskScore, COUNT(*) AS CustomerCount
FROM dbo.T_RiskClassification20200122 WITH (NOLOCK)
GROUP BY RiskScore
ORDER BY RiskScore
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 136 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.T_RiskClassification20200122 | Type: Table | Source: RiskClassification/dbo/Tables/dbo.T_RiskClassification20200122.sql*
