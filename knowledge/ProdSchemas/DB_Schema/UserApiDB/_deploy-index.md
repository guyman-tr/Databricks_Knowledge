---

## bronze: UserApiDB

db_key: DB_Schema/UserApiDB
total_deployable: 32
generated: 32
failed: 0
deployed: 0
last_generated: "2026-04-30"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [ASIC.CustomerAnswers](Wiki/ASIC/Tables/ASIC.CustomerAnswers.md) | `main.bi_db.bronze_userapidb_asic_customeranswers` | Generated |
| [ASIC.TestResults](Wiki/ASIC/Tables/ASIC.TestResults.md) | `main.bi_db.bronze_userapidb_asic_testresults` | Generated |
| [Customer.AdditionalCitizenship](Wiki/Customer/Tables/Customer.AdditionalCitizenship.md) | `main.bi_db.bronze_userapidb_customer_additionalcitizenship` | Generated |
| [Customer.Avatars](Wiki/Customer/Tables/Customer.Avatars.md) | `main.compliance.bronze_userapidb_customer_avatars` | Generated |
| [Customer.CustomerIdentification](Wiki/Customer/Tables/Customer.CustomerIdentification.md) | `main.compliance.bronze_userapidb_customer_customeridentification` | Generated |
| [Customer.ExtendedUserField](Wiki/Customer/Tables/Customer.ExtendedUserField.md) | `main.pii_data.bronze_userapidb_customer_extendeduserfield` | Generated |
| [Customer.ExtendedUserField](Wiki/Customer/Tables/Customer.ExtendedUserField.md) | `main.compliance.bronze_userapidb_customer_extendeduserfield_masked` | Generated |
| [Customer.ExtendedUserFieldValidation](Wiki/Customer/Tables/Customer.ExtendedUserFieldValidation.md) | `main.bi_db.bronze_userapidb_customer_extendeduserfieldvalidation` | Generated |
| [Customer.ExtendedUserField_History](Wiki/Customer/Tables/Customer.ExtendedUserField_History.md) | `main.pii_data.bronze_userapidb_customer_extendeduserfield_history` | Generated |
| [Customer.TncSignature](Wiki/Customer/Tables/Customer.TncSignature.md) | `main.compliance.bronze_userapidb_customer_tncsignature` | Generated |
| [DBA.V_NumRows_Sizes](Wiki/DBA/Views/DBA.V_NumRows_Sizes.md) | `main.config.bronze_userapidb_dba_v_numrows_sizes` | Generated |
| [DWH.Questions_Answers_V](Wiki/DWH/Views/DWH.Questions_Answers_V.md) | `main.bi_db.bronze_userapidb_dwh_questions_answers_v` | Generated |
| [Dictionary.DltStatus](Wiki/Dictionary/Tables/Dictionary.DltStatus.md) | `main.general.bronze_userapidb_dictionary_dltstatus` | Generated |
| [Dictionary.EvProvider](Wiki/Dictionary/Tables/Dictionary.EvProvider.md) | `main.compliance.bronze_userapidb_dictionary_evprovider` | Generated |
| [Dictionary.EvStatus](Wiki/Dictionary/Tables/Dictionary.EvStatus.md) | `main.bi_db.bronze_userapidb_dictionary_evstatus` | Generated |
| [Dictionary.ExtendedUserValueType](Wiki/Dictionary/Tables/Dictionary.ExtendedUserValueType.md) | `main.compliance.bronze_userapidb_dictionary_extendeduservaluetype` | Generated |
| [Dictionary.MandatoryType](Wiki/Dictionary/Tables/Dictionary.MandatoryType.md) | `main.compliance.bronze_userapidb_dictionary_mandatorytype` | Generated |
| [Dictionary.NationalPinValueTypeToReportType](Wiki/Dictionary/Tables/Dictionary.NationalPinValueTypeToReportType.md) | `main.bi_db.bronze_userapidb_dictionary_nationalpinvaluetypetoreporttype` | Generated |
| [Dictionary.TanganyStatus](Wiki/Dictionary/Tables/Dictionary.TanganyStatus.md) | `main.bi_db.bronze_userapidb_dictionary_tanganystatus` | Generated |
| [Ev.CustomerResult](Wiki/Ev/Tables/Ev.CustomerResult.md) | `main.compliance.bronze_userapidb_ev_customerresult` | Generated |
| [History.CustomerAnswers](Wiki/History/Tables/History.CustomerAnswers.md) | `main.compliance.bronze_userapidb_history_customeranswers` | Generated |
| [KYC.AnswerThresholds](Wiki/KYC/Tables/KYC.AnswerThresholds.md) | `main.compliance.bronze_userapidb_kyc_answerthresholds` | Generated |
| [KYC.Answers](Wiki/KYC/Tables/KYC.Answers.md) | `main.compliance.bronze_userapidb_kyc_answers` | Generated |
| [KYC.CountryTaxType](Wiki/KYC/Tables/KYC.CountryTaxType.md) | `main.compliance.bronze_userapidb_kyc_countrytaxtype` | Generated |
| [KYC.CryptoAssessmentAnswers](Wiki/KYC/Tables/KYC.CryptoAssessmentAnswers.md) | `main.bi_db.bronze_userapidb_kyc_cryptoassessmentanswers` | Generated |
| [KYC.CustomerAnswers](Wiki/KYC/Tables/KYC.CustomerAnswers.md) | `main.compliance.bronze_userapidb_kyc_customeranswers` | Generated |
| [KYC.Questions](Wiki/KYC/Tables/KYC.Questions.md) | `main.compliance.bronze_userapidb_kyc_questions` | Generated |
| [KYC.QuestionsAnswers](Wiki/KYC/Tables/KYC.QuestionsAnswers.md) | `main.compliance.bronze_userapidb_kyc_questionsanswers` | Generated |
| [KYC.ReasonsForNoTaxID](Wiki/KYC/Tables/KYC.ReasonsForNoTaxID.md) | `main.compliance.bronze_userapidb_kyc_reasonsfornotaxid` | Generated |
| [dbo.Publications](Wiki/dbo/Tables/dbo.Publications.md) | `main.bi_db.bronze_userapidb_dbo_publications` | Generated |
| [dbo.V_CustomerAnswers](Wiki/dbo/Views/dbo.V_CustomerAnswers.md) | `main.bi_db.bronze_userapidb_dbo_v_customeranswers` | Generated |
| [dbo.V_CustomerAnswers](Wiki/dbo/Views/dbo.V_CustomerAnswers.md) | `main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked` | Generated |
