# BI_DB_dbo.BI_DB_RiskClassification

> 4.9M-row customer risk classification table storing per-customer, per-regulation composite risk scores and individual risk factor breakdowns (46 factor categories). Sourced from the production RiskClassification database (`V_RiskClassificationDataLake`) via Generic Pipeline weekly Override. Data spans 2020-01-23 to 2024-06-02; all rows show UpdateDate 2024-06-02 indicating the table has not refreshed since that date (appears dormant).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | RiskClassification.dbo.V_RiskClassificationDataLake (risk-fg-RiskClassification) |
| **Refresh** | Weekly (10080 min) via Generic Pipeline, Override — appears dormant since 2024-06-02 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | `bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake` |
| **UC Format** | Parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze (Generic Pipeline export) |

---

## 1. Business Meaning

BI_DB_RiskClassification is a compliance-oriented table that stores the full risk classification breakdown for each customer (CID) under each regulatory jurisdiction. Each row represents a single risk assessment period for a customer, with an SCD Type 2 pattern using BeginTime/EndTime (EndTime = 9999-12-31 indicates the current active assessment).

The table contains 103 columns organized around a central pattern: for each of 46 risk factor categories (e.g., Country of Residence, PEP Check, Occupation, AML/CFT Failure), the table stores both a numeric `_RiskScore` (integer) and a textual `_Value` (the answer or context that produced that score). Individual factor scores combine into an overall `RiskScore` with a corresponding `RiskScoreName` classification (Low=0, Medium=50, High=100, Unacceptable=200 — matching the Dim_RiskClassification lookup values).

The data originates from the production RiskClassification microservice database on `risk-fg-RiskClassification`, exported via the `V_RiskClassificationDataLake` view through the Generic Pipeline. No Synapse writer SP exists — data is loaded directly. The table appears dormant since 2024-06-02 (all UpdateDate values are identical). It contains ~5M rows covering customers from 2020 onward.

Two downstream SPs consume this table: SP_LTV_By_FTD_MOP (to flag high-risk customers in LTV analysis) and SP_EXW_UserSettingsWalletAllowance (to include risk scores in wallet eligibility decisions).

---

## 2. Business Logic

### 2.1 Risk Factor Scoring Pattern

**What**: Each risk factor is stored as a paired `_RiskScore` (int) + `_Value` (varchar) column pair.

**Columns Involved**: All `*_RiskScore` and `*_Value` column pairs (46 factors)

**Rules**:
- `_RiskScore` = 0 indicates no risk contribution from that factor
- `_RiskScore` > 0 indicates the factor contributes to overall risk (values like 50, 100 observed)
- `_Value` contains the contextual answer (e.g., country name, age, "Predefined Questions", numeric amounts)
- NULL in both `_RiskScore` and `_Value` means the factor was not evaluated for that customer/regulation combination
- Some factor pairs appear duplicated with different naming conventions (e.g., `Sector ML TF` vs `Sector_ML_TF`, `Sector High Cash` vs `SectorHighCash`) — likely regulation-specific variants

### 2.2 Overall Risk Classification

**What**: The composite risk level derived from individual factor scores.

**Columns Involved**: `RiskScore`, `RiskScoreName`, `RiskScore_Value`, `RiskScore_Explanation`

**Rules**:
- `RiskScoreName` values: Low, Medium (91%), High (8%), Unacceptable (1 row)
- `RiskScore` maps to Dim_RiskClassification levels: 0=Low, 50=Medium, 100=High, 200=Unacceptable
- `RiskScore_Value` contains the scoring formula expression (e.g., "2*50", "1*100", "3*50")
- `RiskScore_Explanation` lists the factor names that contributed to the score (comma-separated)

### 2.3 SCD Type 2 Temporal Pattern

**What**: Each row has a validity period allowing historical risk tracking.

**Columns Involved**: `BeginTime`, `EndTime`, `PreviousRisk`, `PreviousRiskUpdateDate`

**Rules**:
- `EndTime` = 9999-12-31 23:59:59.997 indicates the current active assessment
- `BeginTime` marks when this assessment became effective
- `PreviousRisk` stores the prior composite risk score (enables risk trend analysis)
- `PreviousRiskUpdateDate` stores the timestamp of the previous assessment
- Multiple rows can exist per CID (one per regulation, one per time period)

### 2.4 Regulation-Scoped Assessment

**What**: Each assessment is scoped to a specific regulatory jurisdiction.

**Columns Involved**: `RegulationID`, `Regulation`

**Rules**:
- 8 regulations observed: CySEC (57%), FCA (24%), ASIC & GAML (7%), FinCEN+FINRA (6%), FinCEN (2%), FSA Seychelles (2%), ASIC (2%), FSRA (<1%)
- Different regulations evaluate different risk factors (some factor columns are NULL for certain regulations)
- A customer may have multiple rows for different regulations

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with CLUSTERED INDEX on CID. For customer-level lookups, filter on CID for index seek. For regulation-scoped queries, add `AND RegulationID = N`. For current-only records, filter `WHERE EndTime = '9999-12-31 23:59:59.997'`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get current risk classification for a customer | `WHERE CID = @cid AND EndTime = '9999-12-31 23:59:59.997'` |
| Count customers by risk level per regulation | `GROUP BY Regulation, RiskScoreName WHERE EndTime = '9999-12-31 23:59:59.997'` |
| Find customers whose risk changed | `WHERE PreviousRisk IS NOT NULL AND PreviousRisk <> RiskScore` |
| Get high-risk customers for a regulation | `WHERE RiskScoreName = 'High' AND Regulation = 'CySEC' AND EndTime = '9999-12-31 23:59:59.997'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `dc.RealCID = rc.CID` | Enrich with customer demographics |
| DWH_dbo.Dim_Regulation | `dr.ID = rc.RegulationID` | Resolve regulation details |
| DWH_dbo.Dim_RiskClassification | `drc.RiskScore = rc.RiskScore` | Resolve risk level metadata |

### 3.4 Gotchas

- **Table appears dormant**: All UpdateDate values are 2024-06-02. No data after that date. Verify pipeline status before relying on current risk data.
- **Duplicate factor columns**: Some risk factors appear with two naming conventions (spaces vs underscores, e.g., `Sector ML TF` and `Sector_ML_TF`). These may represent different regulation versions of the same factor.
- **Column names contain spaces and commas**: Many column names include spaces and commas (e.g., `[Country of Residence, Onboarding_RiskScore]`). Always use square brackets in SQL.
- **ROUND_ROBIN + no partition key**: Full table scans are required for aggregate queries. Filter on CID (clustered index) when possible.
- **PreviousRisk can be NULL**: Not all rows have a previous risk assessment.
- **Net Deposit_Value stores numeric amounts**: Unlike most `_Value` columns (which store text labels), `Net Deposit_Value` stores monetary amounts as varchar (e.g., "-6410.6000", "337.3100").

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★☆☆☆ | Tier 3 - No upstream wiki or SP code | `(Tier 3 — V_RiskClassificationDataLake)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RiskScore_Explanation | nvarchar(max) | YES | Comma-separated list of risk factor names that contributed to the overall risk score (e.g., "Annual Income,NFTF", "Occupation,Special Score,Annual Income,NFTF"). Identifies which factors elevated the customer's classification above Low. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 2 | Regulation | varchar(50) | YES | Name of the regulatory jurisdiction under which this risk assessment was performed. 8 values observed: CySEC (57%), FCA (24%), ASIC & GAML (7%), FinCEN+FINRA (6%), FinCEN (2%), FSA Seychelles (2%), ASIC (2%), FSRA (<1%). (Tier 3 — no upstream wiki; grounded in DDL + data distribution from V_RiskClassificationDataLake) |
| 3 | RiskScoreName | varchar(20) | YES | Overall risk classification label. Values: Low, Medium (91%), High (8%), Unacceptable (1 row). Maps to Dim_RiskClassification.RiskClassificationName. (Tier 3 — no upstream wiki; grounded in DDL + data distribution from V_RiskClassificationDataLake) |
| 4 | GCID | int | YES | Global customer identifier. Unique per customer across all systems. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 5 | CID | int | YES | Customer identifier. Clustered index column. Joins to DWH_dbo.Dim_Customer.RealCID. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 6 | RegulationID | int | YES | Foreign key to the regulation lookup. Joins to DWH_dbo.Dim_Regulation.ID. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 7 | RiskScore | int | YES | Overall composite risk score. Maps to Dim_RiskClassification.RiskScore values: 0=Low, 50=Medium, 100=High, 200=Unacceptable. Higher values indicate greater risk. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 8 | RiskScore_Value | varchar(50) | YES | Scoring formula expression showing how the composite RiskScore was calculated. Format: "{count}*{factor_score}" (e.g., "2*50" = 2 factors contributing 50 each, "1*100" = 1 factor contributing 100). (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 9 | BeginTime | datetime | YES | Start of the validity period for this risk assessment. Part of SCD Type 2 pattern. Ranges from 2020-01-23 to 2024-06-02. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 10 | EndTime | datetime | YES | End of the validity period for this risk assessment. 9999-12-31 23:59:59.997 indicates the current active record. Part of SCD Type 2 pattern. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 11 | Country of Residence, Onboarding_RiskScore | int | YES | Risk score contribution from the customer's country of residence at onboarding. 0 = no risk contribution. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 12 | Country of Residence, Onboarding_Value | varchar(50) | YES | Country name used for the onboarding country-of-residence risk factor evaluation. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 13 | Country of Residence, Existing clients_RiskScore | int | YES | Risk score contribution from the customer's country of residence for existing (post-onboarding) clients. 0 = no risk contribution. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 14 | Country of Residence, Existing clients_Value | varchar(50) | YES | Country name used for the existing-client country-of-residence risk factor evaluation. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 15 | Age of customer_RiskScore | int | YES | Risk score contribution from the customer's age. 0 = no risk contribution; 100 observed for young customers (e.g., age 21). (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 16 | Age of customer_Value | varchar(50) | YES | Customer's age at the time of risk assessment. Stored as varchar. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 17 | Age Alert_RiskScore | int | YES | Risk score contribution from age-related alerts. Separate from the base age factor; flags anomalous age patterns. 0 = no alert. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 18 | Age Alert_Value | varchar(50) | YES | Value associated with age alert evaluation. Typically mirrors the customer age value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 19 | PEP Check_RiskScore | int | YES | Risk score contribution from Politically Exposed Person (PEP) screening. 0 = not flagged as PEP. NULL if not evaluated for this regulation. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 20 | PEP Check_Value | varchar(50) | YES | Result of PEP screening. Value of 1 observed in samples (likely 1=screened/clear). NULL if not evaluated. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 21 | Main Source of Income_RiskScore | int | YES | Risk score contribution from the customer's declared main source of income. 0 = standard source. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 22 | Main Source of Income_Value | varchar(50) | YES | Numeric code or identifier for the customer's declared main source of income. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 23 | Occupation_RiskScore | int | YES | Risk score contribution from the customer's occupation. 0 = standard occupation; 50 observed for higher-risk occupations. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 24 | Occupation_Value | varchar(50) | YES | Numeric code or identifier for the customer's declared occupation. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 25 | Special Score_RiskScore | int | YES | Risk score contribution from a special/override scoring factor. 0 = no special score applied; 50 observed. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 26 | Special Score_Value | varchar(50) | YES | Value associated with the special scoring factor. Appears to store numeric identifiers. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 27 | Annual Income_RiskScore | int | YES | Risk score contribution from the customer's declared annual income level. 0 = standard range; 50 observed for elevated risk income ranges. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 28 | Annual Income_Value | varchar(50) | YES | Numeric code or range identifier for the customer's annual income bracket. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 29 | Total Cash And Liquid Assets_RiskScore | int | YES | Risk score contribution from the customer's total cash and liquid assets level. 0 = standard range; 50, 100 observed. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 30 | Total Cash And Liquid Assets_Value | varchar(50) | YES | Numeric code or range identifier for the customer's liquid assets bracket. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 31 | Money plan To invest_RiskScore | int | YES | Risk score contribution from the customer's planned investment amount. 0 = standard plan. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 32 | Money plan To invest_Value | varchar(50) | YES | Numeric code or range identifier for the customer's investment plan bracket. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 33 | High Risk_RiskScore | int | YES | Risk score contribution from the high-risk flag factor. 0 = not flagged. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 34 | High Risk_Value | varchar(50) | YES | Value associated with the high-risk flag evaluation. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 35 | Sector ML TF_RiskScore | int | YES | Risk score contribution from the customer's sector exposure to money laundering and terrorist financing risk (space-separated naming variant). 0 = no sector risk. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 36 | Sector ML TF_Value | varchar(50) | YES | Value associated with ML/TF sector risk evaluation (space-separated naming variant). (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 37 | Sector High Cash_RiskScore | int | YES | Risk score contribution from the customer's exposure to high-cash-turnover sectors (space-separated naming variant). 0 = no sector risk. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 38 | Sector High Cash_Value | varchar(50) | YES | Value associated with high-cash sector risk evaluation (space-separated naming variant). (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 39 | Net Deposit_RiskScore | int | YES | Risk score contribution from the customer's net deposit amount. 0 = standard amount. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 40 | Net Deposit_Value | varchar(50) | YES | Net deposit amount stored as varchar (e.g., "-6410.6000", "337.3100", "500.0000"). Unlike most _Value columns, this stores a monetary amount rather than a code or label. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 41 | Instruments Planned Investment_RiskScore | int | YES | Risk score contribution from the instruments the customer plans to invest in. 0 = standard instruments. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 42 | Instruments Planned Investment_Value | varchar(50) | YES | Value or code identifying planned investment instruments. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 43 | FTD_RiskScore | int | YES | Risk score contribution from the customer's first-time deposit characteristics. 0 = standard. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 44 | FTD_Value | varchar(50) | YES | Value associated with first-time deposit risk factor. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 45 | ScoreExpectedOriginFunds_RiskScore | int | YES | Risk score contribution from the expected origin of funds assessment. 0 = standard origin. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 46 | ScoreExpectedOriginFunds_Value | varchar(50) | YES | Value associated with expected origin of funds evaluation. Large numeric values observed (e.g., 45411841) — possibly an internal reference ID. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 47 | ScoreExpectedDestinationPayments_RiskScore | int | YES | Risk score contribution from the expected destination of payments assessment. 0 = standard destination. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 48 | ScoreExpectedDestinationPayments_Value | varchar(50) | YES | Value associated with expected destination of payments evaluation. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 49 | SectorHighRisk_RiskScore | int | YES | Risk score contribution from high-risk sector classification (underscore naming variant). 0 = no sector risk. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 50 | SectorHighRisk_Value | varchar(50) | YES | Value associated with high-risk sector evaluation (underscore naming variant). Country names observed (e.g., "United Kingdom", "Colombia"). (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 51 | Sector_ML_TF_RiskScore | int | YES | Risk score contribution from money laundering and terrorist financing sector risk (underscore naming variant). 0 = no sector risk. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 52 | Sector_ML_TF_Value | varchar(50) | YES | Value associated with ML/TF sector risk evaluation (underscore naming variant). Country names observed. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 53 | SectorHighCash_RiskScore | int | YES | Risk score contribution from high-cash sector classification (underscore naming variant). 0 = no sector risk. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 54 | SectorHighCash_Value | varchar(50) | YES | Value associated with high-cash sector evaluation (underscore naming variant). "Predefined Questions" observed as common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 55 | EstablishmentApproved_RiskScore | int | YES | Risk score contribution from establishment approval status (EDD factor). 0 = approved/no risk. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 56 | EstablishmentApproved_Value | varchar(50) | YES | Value associated with establishment approval evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 57 | HighPublicProfile_RiskScore | int | YES | Risk score contribution from high public profile / prominent public function assessment. 0 = no high profile. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 58 | HighPublicProfile_Value | varchar(50) | YES | Value associated with high public profile evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 59 | DisclosureSubjected_RiskScore | int | YES | Risk score contribution from disclosure/regulatory subjection assessment. 0 = no risk from disclosure status. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 60 | DisclosureSubjected_Value | varchar(50) | YES | Value associated with disclosure subjection evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 61 | RegionSupervised_RiskScore | int | YES | Risk score contribution from whether the customer's region is under supervised regulatory regime. 0 = supervised region. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 62 | RegionSupervised_Value | varchar(50) | YES | Value associated with region supervision evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 63 | JurisdictionNonCorrupt_RiskScore | int | YES | Risk score contribution from jurisdiction corruption/transparency assessment. 0 = non-corrupt jurisdiction. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 64 | JurisdictionNonCorrupt_Value | varchar(50) | YES | Value associated with jurisdiction corruption evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 65 | AML_CFT_Failure_RiskScore | int | YES | Risk score contribution from AML/CFT (Anti-Money Laundering / Combating the Financing of Terrorism) failure assessment. 0 = no failure detected. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 66 | AML_CFT_Failure_Value | varchar(50) | YES | Value associated with AML/CFT failure evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 67 | BackgroundConsistent_RiskScore | int | YES | Risk score contribution from background consistency check. 0 = consistent background. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 68 | BackgroundConsistent_Value | varchar(50) | YES | Value associated with background consistency evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 69 | TransactionSuspicious_RiskScore | int | YES | Risk score contribution from suspicious transaction pattern detection. 0 = no suspicious activity. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 70 | TransactionSuspicious_Value | varchar(50) | YES | Value associated with suspicious transaction evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 71 | IdentityEvidence_RiskScore | int | YES | Risk score contribution from identity evidence verification assessment. 0 = adequate identity evidence. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 72 | IdentityEvidence_Value | varchar(50) | YES | Value associated with identity evidence evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 73 | AvoidBusinessRelations_RiskScore | int | YES | Risk score contribution from avoidance of business relations assessment (EDD red flag). 0 = no avoidance detected. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 74 | AvoidBusinessRelations_Value | varchar(50) | YES | Value associated with business relations avoidance evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 75 | OwnershipTransparent_RiskScore | int | YES | Risk score contribution from ownership transparency assessment. 0 = transparent ownership structure. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 76 | OwnershipTransparent_Value | varchar(50) | YES | Value associated with ownership transparency evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 77 | AssetHoldingVehicle_RiskScore | int | YES | Risk score contribution from asset holding vehicle usage assessment. 0 = no asset holding vehicle risk. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 78 | AssetHoldingVehicle_Value | varchar(50) | YES | Value associated with asset holding vehicle evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 79 | TransactionsUnusual_RiskScore | int | YES | Risk score contribution from unusual transaction pattern assessment. 0 = no unusual patterns. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 80 | TransactionsUnusual_Value | varchar(50) | YES | Value associated with unusual transactions evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 81 | SecrecyUnreasonable_RiskScore | int | YES | Risk score contribution from unreasonable secrecy assessment (EDD red flag). 0 = no unreasonable secrecy. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 82 | SecrecyUnreasonable_Value | varchar(50) | YES | Value associated with unreasonable secrecy evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 83 | NFTF_RiskScore | int | YES | Risk score contribution from the NFTF (Non-Face-To-Face) interaction assessment. 0 = no NFTF risk; 50 observed frequently. NFTF is the most commonly contributing factor in RiskScore_Explanation. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 84 | NFTF_Value | varchar(50) | YES | Value associated with NFTF evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 85 | IdentityDoubts_RiskScore | int | YES | Risk score contribution from identity doubts assessment (EDD red flag). 0 = no identity doubts. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 86 | IdentityDoubts_Value | varchar(50) | YES | Value associated with identity doubts evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 87 | ExpectedProductsUsed_RiskScore | int | YES | Risk score contribution from expected products/services usage assessment. 0 = standard product usage. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 88 | ExpectedProductsUsed_Value | varchar(50) | YES | Value associated with expected products used evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 89 | NonProfitOrgAbused_RiskScore | int | YES | Risk score contribution from non-profit organization abuse assessment. 0 = no NPO abuse risk. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 90 | NonProfitOrgAbused_Value | varchar(50) | YES | Value associated with non-profit organization abuse evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 91 | CooperativeClient_RiskScore | int | YES | Risk score contribution from client cooperation assessment. 0 = cooperative client. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 92 | CooperativeClient_Value | varchar(50) | YES | Value associated with client cooperation evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 93 | IdentityAnonymous_RiskScore | int | YES | Risk score contribution from identity anonymity assessment. 0 = identified (not anonymous). (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 94 | IdentityAnonymous_Value | varchar(50) | YES | Value associated with identity anonymity evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 95 | TransactionComplexity_RiskScore | int | YES | Risk score contribution from transaction complexity assessment. 0 = standard complexity. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 96 | TransactionComplexity_Value | varchar(50) | YES | Value associated with transaction complexity evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 97 | PaymentsThirdParty_RiskScore | int | YES | Risk score contribution from third-party payments assessment. 0 = no third-party payment risk. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 98 | PaymentsThirdParty_Value | varchar(50) | YES | Value associated with third-party payments evaluation. "Predefined Questions" is the most common value. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 99 | UpdateDate | datetime | YES | Timestamp of the last update to this risk classification record. All rows show 2024-06-02 01:39:57.930, indicating a bulk refresh or pipeline staleness. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 100 | Place of Birth_RiskScore | int | YES | Risk score contribution from the customer's place of birth. 0 = no birth-place risk. NULL for most rows — only populated for certain regulations. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 101 | Place of Birth_Value | varchar(50) | YES | Value associated with place of birth risk evaluation. NULL for most rows — only populated for certain regulations. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 102 | PreviousRisk | int | YES | The customer's previous composite risk score before the current assessment. Enables risk trend analysis. NULL if no prior assessment exists. Values match Dim_RiskClassification.RiskScore (0, 50, 100). (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |
| 103 | PreviousRiskUpdateDate | datetime | YES | Timestamp of the previous risk classification assessment. NULL if no prior assessment exists. Used with PreviousRisk for risk change tracking. (Tier 3 — no upstream wiki; grounded in DDL + data sample from V_RiskClassificationDataLake) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| All 103 columns | RiskClassification.dbo.V_RiskClassificationDataLake | Same name | passthrough (assumed — no SP code) |

### 5.2 ETL Pipeline

```
RiskClassification.dbo.V_RiskClassificationDataLake (risk-fg-RiskClassification)
  |-- Generic Pipeline (weekly, Override, parquet) ---|
  v
Bronze/RiskClassification/dbo/V_RiskClassificationDataLake/ (Data Lake)
  |-- Direct load (no Synapse SP) ---|
  v
BI_DB_dbo.BI_DB_RiskClassification (4.9M rows, ROUND_ROBIN)
  |-- Generic Pipeline (Gold export) ---|
  v
bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake (UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer identifier join |
| RegulationID | DWH_dbo.Dim_Regulation.ID | Regulation lookup |
| RiskScore | DWH_dbo.Dim_RiskClassification.RiskScore | Risk level metadata (conceptual; not FK) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Join Condition | Purpose |
|--------------|---------------|---------|
| BI_DB_dbo.SP_LTV_By_FTD_MOP | `dc.RealCID = bdrc.CID` | Flags high-risk customers (`RiskScoreName='High'`) in LTV analysis |
| EXW_dbo.SP_EXW_UserSettingsWalletAllowance | `rc.CID = e.RealCID` | Reads `RiskScore_Explanation`, `RiskScoreName`, `RiskScore` for wallet eligibility decisions |

---

## 7. Sample Queries

### 7.1 Current risk classification for a specific customer

```sql
SELECT CID, Regulation, RiskScoreName, RiskScore, RiskScore_Explanation, BeginTime
FROM [BI_DB_dbo].[BI_DB_RiskClassification]
WHERE CID = 6843263
  AND EndTime = '9999-12-31 23:59:59.997'
```

### 7.2 Distribution of risk levels by regulation (current records only)

```sql
SELECT Regulation, RiskScoreName, COUNT(*) AS customer_count
FROM [BI_DB_dbo].[BI_DB_RiskClassification]
WHERE EndTime = '9999-12-31 23:59:59.997'
GROUP BY Regulation, RiskScoreName
ORDER BY Regulation, customer_count DESC
```

### 7.3 Customers whose risk level changed from previous assessment

```sql
SELECT CID, Regulation, PreviousRisk, RiskScore, RiskScoreName,
       PreviousRiskUpdateDate, BeginTime
FROM [BI_DB_dbo].[BI_DB_RiskClassification]
WHERE PreviousRisk IS NOT NULL
  AND PreviousRisk <> RiskScore
  AND EndTime = '9999-12-31 23:59:59.997'
ORDER BY BeginTime DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (Phase 10 skipped for regen harness).

---

*Generated: 2026-04-30 | Quality: 6.5/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 103 T3, 0 T4, 0 T5 | Elements: 103/103, Logic: 7/10, Relationships: 6/10, Sources: 5/10*
*Object: BI_DB_dbo.BI_DB_RiskClassification | Type: Table | Production Source: RiskClassification.dbo.V_RiskClassificationDataLake*
