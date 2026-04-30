---

## bronze: USABroker

db_key: ComplianceDBs/USABroker
total_deployable: 30
generated: 15
failed: 15
deployed: 0
last_generated: "2026-04-30"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Dictionary.AccountType](Wiki/Dictionary/Tables/Dictionary.AccountType.md) | `main.finance.bronze_usabroker_dictionary_accounttype` | Generated |
| [Dictionary.ApexStatus](Wiki/Dictionary/Tables/Dictionary.ApexStatus.md) | `main.finance.bronze_usabroker_dictionary_apexstatus` | Generated |
| [History.ApexData](Wiki/History/Tables/History.ApexData.md) | `main.finance.bronze_usabroker_history_apexdata` | Generated |
| [History.Options](Wiki/History/Tables/History.Options.md) | `main.general.bronze_usabroker_history_options` | Generated |
| [History.UserProgramEnrolment](Wiki/History/Tables/History.UserProgramEnrolment.md) | `main.general.bronze_usabroker_history_userprogramenrolment` | Generated |
| [apex.ApexData](Wiki/apex/Tables/apex.ApexData.md) | `main.finance.bronze_usabroker_apex_apexdata` | Generated |
| [apex.Options](Wiki/apex/Tables/apex.Options.md) | `main.general.bronze_usabroker_apex_options` | Generated |
| [apex.OptionsReasoningForm](Wiki/apex/Tables/apex.OptionsReasoningForm.md) | `main.bi_db.bronze_usabroker_apex_optionsreasoningform` | Generated |
| [apex.OptionsReasoningFormQuestionsAnswers](Wiki/apex/Tables/apex.OptionsReasoningFormQuestionsAnswers.md) | `main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers` | Generated |
| [apex.SketchInvestigationDoNotAppealReason](Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md) | `main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason` | Generated |
| [apex.State](Wiki/apex/Tables/apex.State.md) | `main.finance.bronze_usabroker_apex_state` | Generated |
| [apex.TradingUserData](Wiki/apex/Tables/apex.TradingUserData.md) | `main.finance.bronze_usabroker_apex_tradinguserdata` | Generated |
| [apex.UserData](Wiki/apex/Tables/apex.UserData.md) | `main.finance.bronze_usabroker_apex_userdata` | Generated |
| [apex.UserProgramEnrolment](Wiki/apex/Tables/apex.UserProgramEnrolment.md) | `main.general.bronze_usabroker_apex_userprogramenrolment` | Generated |
| [apex.UserValidationErrors](Wiki/apex/Tables/apex.UserValidationErrors.md) | `main.finance.bronze_usabroker_apex_uservalidationerrors` | Generated |
| [Dictionary.ApexValidationError](Wiki/Dictionary/Tables/Dictionary.ApexValidationError.md) | `main.finance.bronze_usabroker_dictionary_apexvalidationerror` | Failed |
| [Dictionary.AppropriatenessProduct](Wiki/Dictionary/Tables/Dictionary.AppropriatenessProduct.md) | `main.bi_db.bronze_usabroker_dictionary_appropriatenessproduct` | Failed |
| [Dictionary.AppropriatenessTestResult](Wiki/Dictionary/Tables/Dictionary.AppropriatenessTestResult.md) | `main.bi_db.bronze_usabroker_dictionary_appropriatenesstestresult` | Failed |
| [Dictionary.CustomerType](Wiki/Dictionary/Tables/Dictionary.CustomerType.md) | `main.finance.bronze_usabroker_dictionary_customertype` | Failed |
| [Dictionary.DocumentType](Wiki/Dictionary/Tables/Dictionary.DocumentType.md) | `main.finance.bronze_usabroker_dictionary_documenttype` | Failed |
| [Dictionary.EligibilityStatus](Wiki/Dictionary/Tables/Dictionary.EligibilityStatus.md) | `main.bi_db.bronze_usabroker_dictionary_eligibilitystatus` | Failed |
| [Dictionary.ModifyType](Wiki/Dictionary/Tables/Dictionary.ModifyType.md) | `main.finance.bronze_usabroker_dictionary_modifytype` | Failed |
| [Dictionary.OptionsStatus](Wiki/Dictionary/Tables/Dictionary.OptionsStatus.md) | `main.bi_db.bronze_usabroker_dictionary_optionsstatus` | Failed |
| [Dictionary.OptionsStatusControl](Wiki/Dictionary/Tables/Dictionary.OptionsStatusControl.md) | `main.general.bronze_usabroker_dictionary_optionsstatuscontrol` | Failed |
| [Dictionary.PhoneType](Wiki/Dictionary/Tables/Dictionary.PhoneType.md) | `main.finance.bronze_usabroker_dictionary_phonetype` | Failed |
| [Dictionary.ReasoningStatus](Wiki/Dictionary/Tables/Dictionary.ReasoningStatus.md) | `main.bi_db.bronze_usabroker_dictionary_reasoningstatus` | Failed |
| [Dictionary.UserDataUpdatesMask](Wiki/Dictionary/Tables/Dictionary.UserDataUpdatesMask.md) | `main.finance.bronze_usabroker_dictionary_userdataupdatesmask` | Failed |
| [Dictionary.UserDocumentType](Wiki/Dictionary/Tables/Dictionary.UserDocumentType.md) | `main.finance.bronze_usabroker_dictionary_userdocumenttype` | Failed |
| [Dictionary.UserProgram](Wiki/Dictionary/Tables/Dictionary.UserProgram.md) | `main.general.bronze_usabroker_dictionary_userprogram` | Failed |
| [Dictionary.UserProgramEnrolmentStatus](Wiki/Dictionary/Tables/Dictionary.UserProgramEnrolmentStatus.md) | `main.general.bronze_usabroker_dictionary_userprogramenrolmentstatus` | Failed |
