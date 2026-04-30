# Business Glossary - RiskClassification

> Canonical definitions for business terms, value domains, and concepts.
> Object docs reference this glossary for shared terminology.
> Terms are progressively enriched as more objects are documented.

*Last updated: 2026-04-14 | Terms: 4 lookup-backed, 0 concept-based | Sources: 4 Dictionary tables, 0 object docs*

---

## Lookup-Backed Terms

## Regulation {#regulation}

**Definition**: Regulatory jurisdiction under which a customer account operates. Each regulation corresponds to a financial regulatory body and determines which compliance rules, risk scoring thresholds, and KYC requirements apply to the customer. Customers are assigned a regulation based on their country of residence and the eToro entity they register with.

**Source Table**: `Dictionary.Regulation`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No regulation assigned - placeholder for unclassified or legacy accounts |
| 1 | CySEC | Cyprus Securities and Exchange Commission - eToro EU entity. Covers European Economic Area customers |
| 2 | FCA | Financial Conduct Authority - eToro UK entity. Covers United Kingdom customers |
| 3 | NFA | National Futures Association - US futures regulatory body |
| 4 | ASIC | Australian Securities and Investments Commission - eToro AUS entity |
| 5 | BVI | British Virgin Islands - offshore regulation |
| 6 | eToroUS | eToro US entity - general US securities regulation (IsUSA=1) |
| 7 | FinCEN | Financial Crimes Enforcement Network - US anti-money-laundering regulation (IsUSA=1) |
| 8 | FinCEN+FINRA | Combined FinCEN and FINRA regulation - US customers with both AML and broker-dealer oversight (IsUSA=1) |
| 9 | FSA Seychelles | Financial Services Authority of Seychelles - offshore jurisdiction |
| 10 | ASIC & GAML | Australian regulation with GAML (Global AML) overlay - eToro AUS entity with enhanced AML requirements |
| 11 | FSRA | Financial Services Regulatory Authority - Abu Dhabi Global Market |
| 12 | FINRAONLY | FINRA-only regulation - US broker-dealer oversight without FinCEN (IsUSA=1) |
| 14 | NYDFSFINRA | New York Department of Financial Services + FINRA - NY-specific enhanced regulation (IsUSA=1) |

**Key Characteristics**:
- IsUSA flag distinguishes US jurisdictions (IDs 6,7,8,12,14) from non-US
- JurisdictionName maps to eToro entity names (eToro EU, eToro UK, eToro AUS)
- ID 13 is skipped in the sequence
- Risk score thresholds vary by regulation (see RiskClassificationRegulation)

**Used By**: *(populated progressively)*

---

## Risk Classification Parameter {#risk-classification-parameter}

**Definition**: Individual risk factor used in the customer risk scoring model. Each parameter represents a specific dimension of risk assessment (e.g., country of residence, age, income, occupation). Parameters are assigned scores per customer and aggregated into a final composite risk score. Two tiers exist: standard parameters (IDs 2-21) with weights and data sources, and CySEC-specific enhanced due diligence parameters (IDs 1001-1025) used for ongoing monitoring.

**Source Table**: `Dictionary.RiskClassificationParameter`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 2 | Country of Residence, Onboarding | Risk score based on customer's registration country at onboarding. Source: Customer.CustomerStatic. Weekly weight: 2.5%, Onboarding weight: 4% |
| 3 | Country of Residence, Existing clients | Risk score based on customer's country for existing (post-onboarding) clients. Higher weekly weight (4%) reflects ongoing country-risk monitoring |
| 4 | Place of Birth | Risk score based on country of birth. Low weekly weight (0.3%) but 2% onboarding weight |
| 5 | Age of customer | Risk contribution from customer age. Source: Customer.CustomerStatic |
| 6 | Age Alert | Binary alert flag triggered when customer age is below 21 or above 65. Zero weight - informational only |
| 7 | Screening Status | Risk score from external screening service (sanctions/watchlist checks). Highest weighted parameter - 5.2% weekly, 6.5% onboarding |
| 8 | Main Source of Income | Risk based on primary income source (Q15 onboarding questionnaire). Social security, family support, and "Other" are flagged categories |
| 9 | Occupation | Risk based on occupation type (Q18 questionnaire). Real Estate, Healthcare, Construction, and None are elevated-risk categories |
| 10 | Special Score | Maximum score override for high-risk occupations - Student or None trigger special scoring |
| 11 | Annual Income | Risk based on annual income bands. Lower income brackets ($25k and below) carry higher risk scores |
| 12 | Total Cash And Liquid Assets | Risk based on reported liquid assets. Same income band thresholds as Annual Income |
| 13 | Money plan To invest | Risk based on planned investment amount. Higher planned amounts ($500k+) may indicate elevated risk |
| 14 | High Risk | Binary flag for Healthcare/Construction occupations. Zero weight - used as a tag, not a scoring input |
| 15 | Sector ML TF | Money Laundering / Terrorist Financing sector flag for Healthcare/Construction. Zero weight - classification tag |
| 16 | Sector High Cash | High cash-intensive sector flag for Arts/Construction. Zero weight - classification tag |
| 17 | Net Deposit | Risk based on net deposit amount. Source: BackOffice.CustomerAllTimeAggregatedData |
| 18 | Instruments Planned Investment | Risk based on instrument types the customer plans to trade |
| 19 | FTD | First Time Deposit amount risk score. Source: Billing.Deposit |
| 20 | ScoreExpectedOriginFunds | Risk based on expected origin of incoming funds. Source: UserApiDB_rep.Customer.ExtendedUserField |
| 21 | ScoreExpectedDestinationPayments | Risk based on expected destination of outgoing payments. Source: UserApiDB_rep.Customer.ExtendedUserField |
| 1001 | SectorHighRisk | CySEC EDD parameter - whether customer's sector is classified as high-risk |
| 1002 | Sector_ML_TF | CySEC EDD parameter - ML/TF sector risk indicator |
| 1003 | SectorHighCash | CySEC EDD parameter - high cash-intensive sector indicator |
| 1004 | EstablishmentApproved | CySEC EDD parameter - whether establishment is approved/regulated |
| 1005 | HighPublicProfile | CySEC EDD parameter - whether customer has a high public profile (similar to PEP) |
| 1006 | DisclosureSubjected | CySEC EDD parameter - whether customer is subject to disclosure requirements |
| 1007 | RegionSupervised | CySEC EDD parameter - whether customer's region has adequate AML supervision |
| 1008 | JurisdictionNonCorrupt | CySEC EDD parameter - whether customer's jurisdiction is non-corrupt (Transparency International based) |
| 1009 | AML_CFT_Failure | CySEC EDD parameter - whether jurisdiction has known AML/CFT failures (FATF grey/blacklist) |
| 1010 | BackgroundConsistent | CySEC EDD parameter - whether customer's background information is consistent |
| 1011 | TransactionSuspicious | CySEC EDD parameter - whether transactions appear suspicious |
| 1012 | IdentityEvidence | CySEC EDD parameter - quality of identity evidence provided |
| 1013 | AvoidBusinessRelations | CySEC EDD parameter - customer attempts to avoid normal business relationship procedures |
| 1014 | OwnershipTransparent | CySEC EDD parameter - transparency of ownership structure |
| 1015 | AssetHoldingVehicle | CySEC EDD parameter - use of asset-holding vehicles that may obscure ownership |
| 1016 | TransactionsUnusual | CySEC EDD parameter - unusual transaction patterns |
| 1017 | SecrecyUnreasonable | CySEC EDD parameter - unreasonable requests for secrecy |
| 1018 | NFTF | CySEC EDD parameter - Non-Face-To-Face identification risk |
| 1019 | IdentityDoubts | CySEC EDD parameter - doubts about customer identity or document authenticity |
| 1020 | ExpectedProductsUsed | CySEC EDD parameter - risk from expected product/service usage |
| 1021 | NonProfitOrgAbused | CySEC EDD parameter - involvement with non-profit organizations at risk of abuse |
| 1022 | CooperativeClient | CySEC EDD parameter - level of customer cooperation during due diligence |
| 1023 | IdentityAnonymous | CySEC EDD parameter - anonymous or pseudo-anonymous identity indicators |
| 1024 | TransactionComplexity | CySEC EDD parameter - complexity of transaction patterns |
| 1025 | PaymentsThirdParty | CySEC EDD parameter - third-party payment involvement |
| 9999 | Final score | Aggregated final risk classification score - composite of all weighted parameter scores |

**Key Characteristics**:
- IDs 2-21 are standard risk parameters with defined weights and external data sources
- IDs 1001-1025 are CySEC-specific Enhanced Due Diligence (EDD) parameters with zero weight - scored separately
- ID 9999 is the special "Final score" entry representing the aggregate classification result
- Weights differ between weekly (recurring re-assessment) and onboarding (initial assessment)
- Parameters sourced from questionnaire answers (V_CustomerAnswersNrml) reference specific question/answer codes

**Used By**: *(populated progressively)*

---

## Risk Classification Regulation {#risk-classification-regulation}

**Definition**: Maps numeric risk score thresholds to named risk classification levels per regulation. Each regulation has its own set of score breakpoints and classification labels. This is the lookup that converts a raw numeric RiskScore into a human-readable risk level name (Low, Medium, High, etc.).

**Source Table**: `Dictionary.RiskClassificationRegulation`

**Values**:

| RegulationID | RiskScore | Name | Business Meaning |
|-------------|-----------|------|-----------------|
| 1 (CySEC) | 0 | Low | Minimal compliance risk - standard monitoring |
| 1 (CySEC) | 25 | Medium Low | Slightly elevated risk - standard monitoring with periodic review |
| 1 (CySEC) | 50 | Medium | Moderate risk - enhanced monitoring may be required |
| 1 (CySEC) | 75 | Medium High | Elevated risk - enhanced due diligence required |
| 1 (CySEC) | 100 | High | High risk - intensive monitoring, senior management approval required |
| 1 (CySEC) | 200 | Unacceptable | Risk exceeds acceptable thresholds - relationship termination may be required |
| 2 (FCA) | 0 | Low | Same 6-tier scale as CySEC |
| 2 (FCA) | 25 | Medium Low | |
| 2 (FCA) | 50 | Medium | |
| 2 (FCA) | 75 | Medium High | |
| 2 (FCA) | 100 | High | |
| 2 (FCA) | 200 | Unacceptable | |
| 4 (ASIC) | 0 | Low | 4-tier scale: Low/Medium/High/Block |
| 4 (ASIC) | 50 | Medium | |
| 4 (ASIC) | 100 | High | |
| 4 (ASIC) | 200 | Block | Account blocked - cannot operate |
| 7 (FinCEN) | 0/50/100/200 | Low/Medium/High/Block | 4-tier US AML scale |
| 8 (FinCEN+FINRA) | 0/50/100/200 | Low/Medium/High/Block | 4-tier US combined scale |
| 9 (FSA Seychelles) | 0/50/100 | Low/Medium/High | 3-tier scale (no Block) |
| 10 (ASIC & GAML) | 0/50/100/200 | Low/Medium/High/Block | 4-tier scale |
| 11 (FSRA) | 0/50/100 | Low/Medium/High | 3-tier scale (no Block) |
| 12 (FINRAONLY) | 0/50/100/200 | Low/Medium/High/Block | 4-tier scale |
| 14 (NYDFSFINRA) | 0/50/100/200 | Low/Medium/High/Block | 4-tier scale |

**Key Characteristics**:
- CySEC and FCA use a 6-tier scale (Low through Unacceptable) - most granular
- US regulations (FinCEN, FINRA, NYDFS) use a 4-tier scale ending in "Block"
- FSA Seychelles and FSRA use only 3 tiers (no Block level)
- "Block" at score 200 means the account is blocked from operations
- "Unacceptable" (CySEC/FCA only) at 200 is the equivalent severity level
- Score breakpoints are consistent across regulations that share the same tier count

**Used By**: *(populated progressively)*

---

## CySEC Risk Classification Parameter {#cysec-risk-classification-parameter}

**Definition**: CySEC-specific version of the risk classification parameter dictionary. Contains the same parameter definitions as Dictionary.RiskClassificationParameter but specifically for CySEC regulatory context. Includes weight percentages for weekly recurring assessments and onboarding assessments. This table appears to be a regulation-specific overlay that allows CySEC parameters to have different weights or configurations than the global defaults.

**Source Table**: `Dictionary.CySecRiskClassificationParameter`

**Key Characteristics**:
- Mirrors Dictionary.RiskClassificationParameter structure with ParameterID, Name, Description, Source
- Adds WeeklyWeightPercent and OnboardingWeightPercent columns for CySEC-specific weighting
- Contains the same 46 parameters as the main table (IDs 2-21, 1001-1025, 9999)
- Created conditionally (IF NOT EXISTS) suggesting it was added as a later enhancement

**Used By**: *(populated progressively)*

---

## Business Concepts

*(No concept terms yet - will be populated as objects are documented)*
