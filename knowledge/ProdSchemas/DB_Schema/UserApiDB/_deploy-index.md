---

## bronze: UserApiDB

db_key: DB_Schema/UserApiDB
total_deployable: 32
generated: 0
failed: 0
deployed: 32
last_generated: "2026-04-30"
last_deploy_batch: 1
last_deployed: "2026-05-03"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [ASIC.CustomerAnswers](Wiki/ASIC/Tables/ASIC.CustomerAnswers.md) | `main.bi_db.bronze_userapidb_asic_customeranswers` | Deployed (Batch 1) - 2026-05-03 |
| [ASIC.TestResults](Wiki/ASIC/Tables/ASIC.TestResults.md) | `main.bi_db.bronze_userapidb_asic_testresults` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.AdditionalCitizenship](Wiki/Customer/Tables/Customer.AdditionalCitizenship.md) | `main.bi_db.bronze_userapidb_customer_additionalcitizenship` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.Avatars](Wiki/Customer/Tables/Customer.Avatars.md) | `main.compliance.bronze_userapidb_customer_avatars` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.CustomerIdentification](Wiki/Customer/Tables/Customer.CustomerIdentification.md) | `main.compliance.bronze_userapidb_customer_customeridentification` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.ExtendedUserField](Wiki/Customer/Tables/Customer.ExtendedUserField.md) | `main.pii_data.bronze_userapidb_customer_extendeduserfield` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.ExtendedUserField](Wiki/Customer/Tables/Customer.ExtendedUserField.md) | `main.compliance.bronze_userapidb_customer_extendeduserfield_masked` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.ExtendedUserFieldValidation](Wiki/Customer/Tables/Customer.ExtendedUserFieldValidation.md) | `main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.ExtendedUserField_History](Wiki/Customer/Tables/Customer.ExtendedUserField_History.md) | `main.pii_data.bronze_userapidb_customer_extendeduserfield_history` | Deployed (Batch 1) - 2026-05-03 |
| [Customer.TncSignature](Wiki/Customer/Tables/Customer.TncSignature.md) | `main.compliance.bronze_userapidb_customer_tncsignature` | Deployed (Batch 1) - 2026-05-03 |
| [DBA.V_NumRows_Sizes](Wiki/DBA/Views/DBA.V_NumRows_Sizes.md) | `main.config.bronze_userapidb_dba_v_numrows_sizes` | Deployed (Batch 1) - 2026-05-03 |
| [DWH.Questions_Answers_V](Wiki/DWH/Views/DWH.Questions_Answers_V.md) | `main.bi_db.bronze_userapidb_dwh_questions_answers_v` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.DltStatus](Wiki/Dictionary/Tables/Dictionary.DltStatus.md) | `main.general.bronze_userapidb_dictionary_dltstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.EvProvider](Wiki/Dictionary/Tables/Dictionary.EvProvider.md) | `main.compliance.bronze_userapidb_dictionary_evprovider` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.EvStatus](Wiki/Dictionary/Tables/Dictionary.EvStatus.md) | `main.bi_db.bronze_userapidb_dictionary_evstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ExtendedUserValueType](Wiki/Dictionary/Tables/Dictionary.ExtendedUserValueType.md) | `main.compliance.bronze_userapidb_dictionary_extendeduservaluetype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.MandatoryType](Wiki/Dictionary/Tables/Dictionary.MandatoryType.md) | `main.compliance.bronze_userapidb_dictionary_mandatorytype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.NationalPinValueTypeToReportType](Wiki/Dictionary/Tables/Dictionary.NationalPinValueTypeToReportType.md) | `main.bi_db.bronze_userapidb_dictionary_nationalpinvaluetypetoreporttype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.TanganyStatus](Wiki/Dictionary/Tables/Dictionary.TanganyStatus.md) | `main.bi_db.bronze_userapidb_dictionary_tanganystatus` | Deployed (Batch 1) - 2026-05-03 |
| [Ev.CustomerResult](Wiki/Ev/Tables/Ev.CustomerResult.md) | `main.compliance.bronze_userapidb_ev_customerresult` | Deployed (Batch 1) - 2026-05-03 |
| [History.CustomerAnswers](Wiki/History/Tables/History.CustomerAnswers.md) | `main.compliance.bronze_userapidb_history_customeranswers` | Deployed (Batch 1) - 2026-05-03 |
| [KYC.AnswerThresholds](Wiki/KYC/Tables/KYC.AnswerThresholds.md) | `main.compliance.bronze_userapidb_kyc_answerthresholds` | Deployed (Batch 1) - 2026-05-03 |
| [KYC.Answers](Wiki/KYC/Tables/KYC.Answers.md) | `main.compliance.bronze_userapidb_kyc_answers` | Deployed (Batch 1) - 2026-05-03 |
| [KYC.CountryTaxType](Wiki/KYC/Tables/KYC.CountryTaxType.md) | `main.compliance.bronze_userapidb_kyc_countrytaxtype` | Deployed (Batch 1) - 2026-05-03 |
| [KYC.CryptoAssessmentAnswers](Wiki/KYC/Tables/KYC.CryptoAssessmentAnswers.md) | `main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers` | Deployed (Batch 1) - 2026-05-03 |
| [KYC.CustomerAnswers](Wiki/KYC/Tables/KYC.CustomerAnswers.md) | `main.compliance.bronze_userapidb_kyc_customeranswers` | Deployed (Batch 1) - 2026-05-03 |
| [KYC.Questions](Wiki/KYC/Tables/KYC.Questions.md) | `main.compliance.bronze_userapidb_kyc_questions` | Deployed (Batch 1) - 2026-05-03 |
| [KYC.QuestionsAnswers](Wiki/KYC/Tables/KYC.QuestionsAnswers.md) | `main.compliance.bronze_userapidb_kyc_questionsanswers` | Deployed (Batch 1) - 2026-05-03 |
| [KYC.ReasonsForNoTaxID](Wiki/KYC/Tables/KYC.ReasonsForNoTaxID.md) | `main.compliance.bronze_userapidb_kyc_reasonsfornotaxid` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.Publications](Wiki/dbo/Tables/dbo.Publications.md) | `main.bi_db.bronze_userapidb_dbo_publications` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.V_CustomerAnswers](Wiki/dbo/Views/dbo.V_CustomerAnswers.md) | `main.bi_db.bronze_userapidb_dbo_v_customeranswers` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.V_CustomerAnswers](Wiki/dbo/Views/dbo.V_CustomerAnswers.md) | `main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked` | Deployed (Batch 1) - 2026-05-03 |
