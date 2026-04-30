# KYC Schema Overview - UserApiDB

> Know Your Customer (KYC) schema for regulatory compliance, suitability assessment, and identity verification.

*Last updated: 2026-04-12 | Objects: 35 | Enrichment: Complete*

---

## Purpose

The KYC schema manages the full lifecycle of regulatory compliance questionnaires and identity verification within the eToro platform. It handles:

- **Suitability Assessment**: Multi-language questionnaires evaluating user knowledge and experience for product access (CFDs, crypto, copy trading)
- **Crypto Knowledge Test**: Dedicated assessment for crypto trading access with 7 risk categories
- **Tax Identification**: Country-specific tax ID collection, validation, and CRS (Common Reporting Standard) compliance
- **National PIN Management**: Per-country configuration for national personal identification numbers with fast electronic verification
- **Regulation Configuration**: Jurisdiction-specific form customization (titles, phone prefixes, special characters)
- **Fast Electronic Verification**: Data collection rules for electronic identity verification per country and document type

---

## Schema Statistics

| Metric | Value |
|--------|-------|
| **User Defined Types** | 3 |
| **Tables** | 13 |
| **Views** | 1 |
| **Functions** | 1 |
| **Stored Procedures** | 17 |
| **Total Objects** | 35 |
| **Largest Table** | KYC.CustomerAnswers (180M+ rows) |
| **Cross-Schema Dependencies** | Dictionary (6 tables), History (1 table), Customer (2 tables), dbo (3 synonyms/UDTs) |

---

## Business Domains

### 1. Questionnaire System (Questions - Answers - Customer Responses)

The core suitability assessment system:

- **KYC.Questions** - Master question catalog with localized text (126 rows across languages)
- **KYC.Answers** - Master answer catalog with 635 options, status tracking, and translation keys
- **KYC.QuestionsAnswers** - Junction table mapping 870 question-answer combinations with display ordering
- **KYC.QuestionsOption** - Conditional display rules (country/regulation-based question visibility)
- **KYC.AnswerThresholds** - Numeric ranges for quantity-based answers (e.g., income brackets)
- **KYC.CustomerAnswers** - 180M+ row transactional table storing all user selections
- **KYC.QuestionRequired** - Function for conditional question logic (currently disabled)

**Key Procedures**:
- `GetKycQuestions` - Assembles full questionnaire from 4 tables
- `GetCustomerAnswers` - Retrieves user's answers with FirstUpdated from History
- `SaveCustomerAnswer` / `SaveCustomerAnswerWithFreeText` - Atomic archive-delete-insert pattern
- `ClearCustomerAnswers` - Archive then delete specific question answers
- `GetUserAnswerHistory` - UNION of current + archived answers for audit trail

### 2. Crypto Assessment

Specialized crypto knowledge test required for crypto trading access:

- **KYC.CryptoAssessmentAnswers** - Maps 240 answers to 7 risk categories with correctness tracking
- `GetCryptoAssessmentAnswers` - Returns enabled quiz structure

Categories: Complete Loss, Cyber-Risks, Diversification, Regulatory, Liquidity, Technical, Volatility

### 3. Tax Identification (CRS Compliance)

Country-specific tax ID configuration:

- **KYC.CountryTaxType** - 250 country-tax type combinations with validation rules
- **KYC.ReasonsForNoTaxID** - 5 CRS-aligned reasons for non-provision
- `GetCountryTaxTypes` - Returns configs joined with type names
- `GetNoTaxReasons` - Returns validation regex per reason

### 4. National PIN / Identity Numbers

Per-country national identification number management:

- **KYC.NationalCountry** - 251 countries with mandatory type, validation, and fast EV flags
- **KYC.NationalCountryTypes** - 495 country-to-PIN-type mappings with priority ordering
- **KYC.NationalPinCountry** (View) - Pivots types into flat FirstTypeID-FifthTypeID structure
- `GetNationalPinCountry` - Returns pivoted view for registration service
- `NationalPinMigration` - Bulk import procedure for migration scenarios

### 5. Regulation Configuration

Jurisdiction-specific form settings:

- **KYC.RegulationConfig** - 71 config values (titles, prefixes, special chars) by type
- **KYC.FastVerificationConfiguration** - 18 rules for fast EV data collection per country/doc type
- `GetFastVerificationConfigurations` - Active configs for service startup
- `MetadataLoader` - Multi-result set metadata loader for caching

### 6. Appropriateness Recalculation

Bulk and single-user recalculation procedures:

- `GetBulkGCIDForRecalculateAppropriateness` - Paginated bulk retrieval with regulation filter
- `GetGCIDForRecalculateAppropriateness` - Non-paginated CySEC/FCA retrieval
- `GetGCIDsForClientRiskProfileRecalculate` - Batch GCIDs for risk profile recalc
- `GetUserDataForRestrictions` - Single user data for restriction evaluation

---

## Key Patterns

### Archive-Then-Delete
Both Save and Clear procedures follow the same transactional pattern:
1. INSERT existing data to History.CustomerAnswers
2. DELETE from KYC.CustomerAnswers
3. INSERT new data (Save only)
4. ROLLBACK on error

### TVP-Based Batch Operations
Three UDTs support batch operations:
- `CustomerAnswer` (AnswerId) - for SaveCustomerAnswer
- `CustomerAnswerWithFreeText` (AnswerId + FreeText) - for SaveCustomerAnswerWithFreeText
- `CustomerAnswersQuestions` (QuestionId) - for ClearCustomerAnswers

### Localized Content
Questions and Answers store text per language (LanguageId). The composite PK on Questions (LanguageId + QuestionId) ensures one text per language per question.

---

## Cross-Schema Dependencies

| External Object | Schema | Used By |
|----------------|--------|---------|
| Dictionary.AnswerStatus | Dictionary | KYC.Answers (StatusID) |
| Dictionary.CryptoAssessmentAnswerCategory | Dictionary | KYC.CryptoAssessmentAnswers (AnswerCategoryId) |
| Dictionary.Country | Dictionary | KYC.FastVerificationConfiguration (CountryId) |
| Dictionary.MandatoryType | Dictionary | KYC.NationalCountry (MandatoryTypeID) |
| Dictionary.TaxIdRequirmentType | Dictionary | KYC.CountryTaxType (TaxIdRequirmentTypeId) |
| Dictionary.KycRegulationConfigType | Dictionary | KYC.RegulationConfig (TypeID) |
| History.CustomerAnswers | History | Archive target for answer changes |
| Customer.CustomerIdentification | Customer | GCID-CID mapping in risk recalc |
| Customer.ExtendedUserField | Customer | Target for NationalPinMigration |
| dbo.Real_Customer | dbo | User data in recalculation SPs |
| dbo.Real_BackOfficeCustomer | dbo | Regulation/verification in recalculation SPs |
| dbo.IdList | dbo | TVP for GetUserAnswerHistory |

---

## Dependency Graph

```
Level 0 (Leaf Tables - no deps):
  Questions, QuestionsAnswers, QuestionsOption, CustomerAnswers,
  FastVerificationConfiguration*, CountryTaxType*, NationalCountry*,
  ReasonsForNoTaxID, RegulationConfig*
  (* = depends on Dictionary tables only)

Level 1 (Single internal dep):
  AnswerThresholds -> Answers
  CryptoAssessmentAnswers -> Answers
  NationalCountryTypes -> NationalCountry

Level 2 (View):
  NationalPinCountry -> NationalCountry + NationalCountryTypes

Level 3 (Function):
  QuestionRequired -> QuestionsOption (dead code)

Level 4 (Stored Procedures):
  All 17 SPs depend on Level 0-2 tables/views
```

---

*Generated: 2026-04-12 | Schema: KYC | Database: UserApiDB*
