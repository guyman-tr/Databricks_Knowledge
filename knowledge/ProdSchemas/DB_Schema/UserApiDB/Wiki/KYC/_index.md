# KYC Schema - UserApiDB

| Metric | Value |
|--------|-------|
| **Database** | UserApiDB |
| **Schema** | KYC |
| **Total Objects** | 35 |
| **Documented** | 35 (100%) |
| **Remaining** | 0 |
| **Last Updated** | 2026-04-12 |

---

## User Defined Types

| Object | Quality | Status |
|--------|---------|--------|
| [KYC.CustomerAnswer](User Defined Types/KYC.CustomerAnswer.md) | 7.0 | Done (Batch 1) |
| [KYC.CustomerAnswerWithFreeText](User Defined Types/KYC.CustomerAnswerWithFreeText.md) | 7.0 | Done (Batch 1) |
| [KYC.CustomerAnswersQuestions](User Defined Types/KYC.CustomerAnswersQuestions.md) | 7.0 | Done (Batch 1) |

## Tables

| Object | Quality | Status |
|--------|---------|--------|
| [KYC.Answers](Tables/KYC.Answers.md) | 8.4 | Done (Batch 1) |
| [KYC.AnswerThresholds](Tables/KYC.AnswerThresholds.md) | 7.8 | Done (Batch 1) |
| [KYC.CountryTaxType](Tables/KYC.CountryTaxType.md) | 8.2 | Done (Batch 1) |
| [KYC.CryptoAssessmentAnswers](Tables/KYC.CryptoAssessmentAnswers.md) | 8.4 | Done (Batch 1) |
| [KYC.CustomerAnswers](Tables/KYC.CustomerAnswers.md) | 8.4 | Done (Batch 1) |
| [KYC.FastVerificationConfiguration](Tables/KYC.FastVerificationConfiguration.md) | 8.0 | Done (Batch 1) |
| [KYC.NationalCountry](Tables/KYC.NationalCountry.md) | 8.2 | Done (Batch 1) |
| [KYC.NationalCountryTypes](Tables/KYC.NationalCountryTypes.md) | 8.0 | Done (Batch 1) |
| [KYC.Questions](Tables/KYC.Questions.md) | 8.0 | Done (Batch 1) |
| [KYC.QuestionsAnswers](Tables/KYC.QuestionsAnswers.md) | 7.8 | Done (Batch 1) |
| [KYC.QuestionsOption](Tables/KYC.QuestionsOption.md) | 7.8 | Done (Batch 1) |
| [KYC.ReasonsForNoTaxID](Tables/KYC.ReasonsForNoTaxID.md) | 8.2 | Done (Batch 1) |
| [KYC.RegulationConfig](Tables/KYC.RegulationConfig.md) | 8.0 | Done (Batch 1) |

## Views

| Object | Quality | Status |
|--------|---------|--------|
| [KYC.NationalPinCountry](Views/KYC.NationalPinCountry.md) | 8.4 | Done (Batch 1) |

## Functions

| Object | Quality | Status |
|--------|---------|--------|
| [KYC.QuestionRequired](Functions/KYC.QuestionRequired.md) | 7.8 | Done (Batch 1) |

## Stored Procedures

| Object | Quality | Status |
|--------|---------|--------|
| [KYC.ClearCustomerAnswers](Stored Procedures/KYC.ClearCustomerAnswers.md) | 8.2 | Done (Batch 1) |
| [KYC.GetBulkGCIDForRecalculateAppropriateness](Stored Procedures/KYC.GetBulkGCIDForRecalculateAppropriateness.md) | 8.0 | Done (Batch 2) |
| [KYC.GetCountryTaxTypes](Stored Procedures/KYC.GetCountryTaxTypes.md) | 7.4 | Done (Batch 1) |
| [KYC.GetCryptoAssessmentAnswers](Stored Procedures/KYC.GetCryptoAssessmentAnswers.md) | 7.4 | Done (Batch 1) |
| [KYC.GetCustomerAnswers](Stored Procedures/KYC.GetCustomerAnswers.md) | 8.0 | Done (Batch 1) |
| [KYC.GetFastVerificationConfigurations](Stored Procedures/KYC.GetFastVerificationConfigurations.md) | 7.2 | Done (Batch 1) |
| [KYC.GetGCIDForRecalculateAppropriateness](Stored Procedures/KYC.GetGCIDForRecalculateAppropriateness.md) | 7.6 | Done (Batch 2) |
| [KYC.GetGCIDsForClientRiskProfileRecalculate](Stored Procedures/KYC.GetGCIDsForClientRiskProfileRecalculate.md) | 7.4 | Done (Batch 2) |
| [KYC.GetKycQuestions](Stored Procedures/KYC.GetKycQuestions.md) | 8.2 | Done (Batch 1) |
| [KYC.GetNationalPinCountry](Stored Procedures/KYC.GetNationalPinCountry.md) | 7.2 | Done (Batch 1) |
| [KYC.GetNoTaxReasons](Stored Procedures/KYC.GetNoTaxReasons.md) | 7.2 | Done (Batch 2) |
| [KYC.GetUserAnswerHistory](Stored Procedures/KYC.GetUserAnswerHistory.md) | 8.0 | Done (Batch 2) |
| [KYC.GetUserDataForRestrictions](Stored Procedures/KYC.GetUserDataForRestrictions.md) | 7.4 | Done (Batch 2) |
| [KYC.MetadataLoader](Stored Procedures/KYC.MetadataLoader.md) | 7.8 | Done (Batch 2) |
| [KYC.NationalPinMigration](Stored Procedures/KYC.NationalPinMigration.md) | 7.8 | Done (Batch 2) |
| [KYC.SaveCustomerAnswer](Stored Procedures/KYC.SaveCustomerAnswer.md) | 8.4 | Done (Batch 2) |
| [KYC.SaveCustomerAnswerWithFreeText](Stored Procedures/KYC.SaveCustomerAnswerWithFreeText.md) | 8.2 | Done (Batch 2) |

## Dependency Graph

### Level 0 - Leaf Tables (10 tables)
Answers, CountryTaxType, CustomerAnswers, FastVerificationConfiguration, NationalCountry, Questions, QuestionsAnswers, QuestionsOption, ReasonsForNoTaxID, RegulationConfig

### Level 1 - Single Dependency (3 tables)
- AnswerThresholds -> KYC.Answers (explicit FK)
- CryptoAssessmentAnswers -> KYC.Answers + Dictionary.CryptoAssessmentAnswerCategory (explicit FKs)
- NationalCountryTypes -> KYC.NationalCountry (explicit FK)

### Cross-Schema Dependencies (all satisfied)
- Answers -> Dictionary.AnswerStatus [done]
- CountryTaxType -> Dictionary.TaxIdRequirmentType [done]
- CryptoAssessmentAnswers -> Dictionary.CryptoAssessmentAnswerCategory [done]
- FastVerificationConfiguration -> Dictionary.Country [done]
- NationalCountry -> Dictionary.MandatoryType [done]
- RegulationConfig -> Dictionary.KycRegulationConfigType [done]
