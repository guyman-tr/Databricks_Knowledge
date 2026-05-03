---

## bronze: USABroker

db_key: ComplianceDBs/USABroker
total_deployable: 30
generated: 0
failed: 15
deployed: 15
last_generated: "2026-04-30"
last_deploy_batch: 1
last_deployed: "2026-05-03"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Dictionary.AccountType](Wiki/Dictionary/Tables/Dictionary.AccountType.md) | `main.finance.bronze_usabroker_dictionary_accounttype` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ApexStatus](Wiki/Dictionary/Tables/Dictionary.ApexStatus.md) | `main.finance.bronze_usabroker_dictionary_apexstatus` | Deployed (Batch 1) - 2026-05-03 |
| [History.ApexData](Wiki/History/Tables/History.ApexData.md) | `main.finance.bronze_usabroker_history_apexdata` | Deployed (Batch 1) - 2026-05-03 |
| [History.Options](Wiki/History/Tables/History.Options.md) | `main.general.bronze_usabroker_history_options` | Deployed (Batch 1) - 2026-05-03 |
| [History.UserProgramEnrolment](Wiki/History/Tables/History.UserProgramEnrolment.md) | `main.general.bronze_usabroker_history_userprogramenrolment` | Deployed (Batch 1) - 2026-05-03 |
| [apex.ApexData](Wiki/apex/Tables/apex.ApexData.md) | `main.finance.bronze_usabroker_apex_apexdata` | Deployed (Batch 1) - 2026-05-03 |
| [apex.Options](Wiki/apex/Tables/apex.Options.md) | `main.general.bronze_usabroker_apex_options` | Deployed (Batch 1) - 2026-05-03 |
| [apex.OptionsReasoningForm](Wiki/apex/Tables/apex.OptionsReasoningForm.md) | `main.bi_db.bronze_usabroker_apex_optionsreasoningform` | Deployed (Batch 1) - 2026-05-03 |
| [apex.OptionsReasoningFormQuestionsAnswers](Wiki/apex/Tables/apex.OptionsReasoningFormQuestionsAnswers.md) | `main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers` | Deployed (Batch 1) - 2026-05-03 |
| [apex.SketchInvestigationDoNotAppealReason](Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md) | `main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason` | Deployed (Batch 1) - 2026-05-03 |
| [apex.State](Wiki/apex/Tables/apex.State.md) | `main.finance.bronze_usabroker_apex_state` | Deployed (Batch 1) - 2026-05-03 |
| [apex.TradingUserData](Wiki/apex/Tables/apex.TradingUserData.md) | `main.finance.bronze_usabroker_apex_tradinguserdata` | Deployed (Batch 1) - 2026-05-03 |
| [apex.UserData](Wiki/apex/Tables/apex.UserData.md) | `main.finance.bronze_usabroker_apex_userdata` | Deployed (Batch 1) - 2026-05-03 |
| [apex.UserProgramEnrolment](Wiki/apex/Tables/apex.UserProgramEnrolment.md) | `main.general.bronze_usabroker_apex_userprogramenrolment` | Deployed (Batch 1) - 2026-05-03 |
| [apex.UserValidationErrors](Wiki/apex/Tables/apex.UserValidationErrors.md) | `main.finance.bronze_usabroker_apex_uservalidationerrors` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ApexValidationError](Wiki/Dictionary/Tables/Dictionary.ApexValidationError.md) | `main.finance.bronze_usabroker_dictionary_apexvalidationerror` | Failed (Batch 1) - alter file not found |
| [Dictionary.AppropriatenessProduct](Wiki/Dictionary/Tables/Dictionary.AppropriatenessProduct.md) | `main.bi_db.bronze_usabroker_dictionary_appropriatenessproduct` | Failed (Batch 1) - alter file not found |
| [Dictionary.AppropriatenessTestResult](Wiki/Dictionary/Tables/Dictionary.AppropriatenessTestResult.md) | `main.bi_db.bronze_usabroker_dictionary_appropriatenesstestresult` | Failed (Batch 1) - alter file not found |
| [Dictionary.CustomerType](Wiki/Dictionary/Tables/Dictionary.CustomerType.md) | `main.finance.bronze_usabroker_dictionary_customertype` | Failed (Batch 1) - alter file not found |
| [Dictionary.DocumentType](Wiki/Dictionary/Tables/Dictionary.DocumentType.md) | `main.finance.bronze_usabroker_dictionary_documenttype` | Failed (Batch 1) - alter file not found |
| [Dictionary.EligibilityStatus](Wiki/Dictionary/Tables/Dictionary.EligibilityStatus.md) | `main.bi_db.bronze_usabroker_dictionary_eligibilitystatus` | Failed (Batch 1) - alter file not found |
| [Dictionary.ModifyType](Wiki/Dictionary/Tables/Dictionary.ModifyType.md) | `main.finance.bronze_usabroker_dictionary_modifytype` | Failed (Batch 1) - alter file not found |
| [Dictionary.OptionsStatus](Wiki/Dictionary/Tables/Dictionary.OptionsStatus.md) | `main.bi_db.bronze_usabroker_dictionary_optionsstatus` | Failed (Batch 1) - alter file not found |
| [Dictionary.OptionsStatusControl](Wiki/Dictionary/Tables/Dictionary.OptionsStatusControl.md) | `main.general.bronze_usabroker_dictionary_optionsstatuscontrol` | Failed (Batch 1) - alter file not found |
| [Dictionary.PhoneType](Wiki/Dictionary/Tables/Dictionary.PhoneType.md) | `main.finance.bronze_usabroker_dictionary_phonetype` | Failed (Batch 1) - alter file not found |
| [Dictionary.ReasoningStatus](Wiki/Dictionary/Tables/Dictionary.ReasoningStatus.md) | `main.bi_db.bronze_usabroker_dictionary_reasoningstatus` | Failed (Batch 1) - alter file not found |
| [Dictionary.UserDataUpdatesMask](Wiki/Dictionary/Tables/Dictionary.UserDataUpdatesMask.md) | `main.finance.bronze_usabroker_dictionary_userdataupdatesmask` | Failed (Batch 1) - alter file not found |
| [Dictionary.UserDocumentType](Wiki/Dictionary/Tables/Dictionary.UserDocumentType.md) | `main.finance.bronze_usabroker_dictionary_userdocumenttype` | Failed (Batch 1) - alter file not found |
| [Dictionary.UserProgram](Wiki/Dictionary/Tables/Dictionary.UserProgram.md) | `main.general.bronze_usabroker_dictionary_userprogram` | Failed (Batch 1) - alter file not found |
| [Dictionary.UserProgramEnrolmentStatus](Wiki/Dictionary/Tables/Dictionary.UserProgramEnrolmentStatus.md) | `main.general.bronze_usabroker_dictionary_userprogramenrolmentstatus` | Failed (Batch 1) - alter file not found |
