# Business Glossary - USABroker

> Canonical definitions for business terms, value domains, and concepts.
> Object docs reference this glossary for shared terminology.
> Terms are progressively enriched as more objects are documented.

*Last updated: 2026-04-14 | Terms: 21 lookup-backed, 0 concept-based | Sources: 21 Dictionary tables, 0 object docs*

---

## Lookup-Backed Terms

## Account Type {#account-type}

**Definition**: Classification of the brokerage account structure determining ownership type and tax treatment. Each account is opened under one of these types, which dictates the regulatory forms required and the trading capabilities available.

**Source Table**: `Dictionary.AccountType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | CASH | Standard brokerage account where securities are purchased with settled funds only - no borrowing or leverage |
| 2 | MARGIN | Account that allows borrowing against securities to increase purchasing power - subject to margin requirements and maintenance calls |
| 3 | OPTION | Account enabled for options trading - requires additional approval and suitability assessment |

**Key Characteristics**:
- Account type determines which Apex Clearing forms and agreements are required at onboarding
- Typo in DDL column name: `AccuntTypeID` (missing 'o')

**Used By**:

---

## Apex Status {#apex-status}

**Definition**: The high-level lifecycle status of a user's Apex Clearing account application or account itself. Tracks the overall state from initial creation through completion, rejection, or closure.

**Source Table**: `Dictionary.ApexStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | NEW | Application just created, no processing has begun |
| 2 | PENDING | Application submitted and awaiting processing by Apex Clearing |
| 3 | INVESTIGATION_SUBMITTED | Identity verification (Sketch/CIP) investigation has been submitted |
| 4 | ACTION_REQUIRED | Apex requires additional information or documents from the user |
| 5 | SUSPENDED | Account temporarily suspended - may be due to compliance or investigation hold |
| 6 | READY_FOR_BACK_OFFICE | Application approved and ready for back-office account setup at Apex |
| 7 | BACK_OFFICE | Currently being processed by Apex back-office team |
| 8 | ACCOUNT_SETUP | Account is being configured in Apex systems |
| 9 | CANCELED | Application was canceled before completion |
| 10 | ERROR | Processing encountered a system error |
| 11 | REJECTED | Application was rejected by Apex Clearing |
| 12 | COMPLETE | Account successfully created and active |
| 13 | NOTAPPLICABLE | Status not applicable to this user/flow |
| 14 | NOTEXISTS | No Apex account record exists for this user |
| 15 | RESTRICTED | Account restricted from trading - compliance or regulatory hold |
| 16 | CLOSED | Account has been closed |

**Key Characteristics**:
- Statuses 1-8 represent the happy-path progression of account creation
- Statuses 9-11 are terminal failure states
- Status 12 is the successful terminal state for account creation
- Statuses 15-16 are post-creation account lifecycle states

**Used By**:

---

## Apex Validation Error {#apex-validation-error}

**Definition**: Enumeration of specific validation errors that can occur when submitting account applications or updates to the Apex Clearing API. Each error identifies a specific field or business rule that failed validation.

**Source Table**: `Dictionary.ApexValidationError`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | GeneralApiError | Unspecified error from the Apex API |
| 2 | GeneralValidationError | Generic validation failure not covered by specific codes |
| 3 | UpdateNotSuitable | Account update request is not suitable for the current account state |
| 4 | FirstNameError | First name failed validation (format, length, or characters) |
| 5 | LastNameError | Last name failed validation |
| 6 | AddressError | Address failed validation |
| 7 | PhoneError | Phone number failed validation |
| 8 | FormVersionMismatch | Submitted form version does not match expected version |
| 9 | FormVersionNotWhiteListed | Form version is not in the approved whitelist |
| 10 | FormSchemaHashWrong | Form schema hash does not match expected value |
| 11 | FormHashWrongInvalidHashAlgorithm | Hash algorithm used for form validation is not accepted |
| 12 | AccountIsRequired | Account identifier is missing from the request |
| 13 | NotValidAccountForAccountRequest | Account specified is not valid for the requested operation |
| 14 | OneJointAgreementNeeded | Joint account requires exactly one joint agreement form |
| 15 | ForeignDueDiligenceFormShouldBeProvided | Foreign due diligence form required for non-US persons |
| 16 | ExactlyOneIraAdoptionAgreementIsRequiredToCreateIraAccount | IRA account creation requires exactly one IRA adoption agreement |
| 17 | AnIraAgreementShouldOnlyBeProvidedWithAnIraAccount | IRA agreement submitted but account type is not IRA |
| 18 | AJointAgreementShouldOnlyBeProvidedWithJointAccount | Joint agreement submitted but account type is not Joint |
| 19 | OneNewAccountFormPossible | Only one new account form can be submitted per request |
| 20 | FormNotAllowed | The submitted form type is not permitted for this operation |
| 21 | OneFormShouldBeProvided | Request must include at least one form |
| 22 | PhoneTooShort | Phone number is too short to be valid |
| 23 | EmploymentStatusIsRequired | Employment status field is mandatory |
| 24 | EmployerIsRequired | Employer name required when employment status indicates employed |
| 25 | SsnIsMustForUsa | Social Security Number is mandatory for US persons |
| 26 | EnumNotFound | Referenced enumeration value does not exist |
| 27 | ObjectHasMissingRequiredProperties | Required properties are missing from the submitted object |
| 28 | InputForCountryAlpha3IsInvalidSeeIso3166Alpha3 | Country code does not conform to ISO 3166 alpha-3 standard |
| 29 | InputMustBeAsciiPrintable | Field contains non-ASCII-printable characters |
| 30 | InputNotAllowedByTheSchema | Value not permitted by the form schema definition |
| 31 | PostOfficeBoxNotAllowedForHomeAddress | PO Box addresses cannot be used as home address |
| 32 | PercentageForPrimaryBeneficiaries | Beneficiary percentage allocation does not sum correctly |
| 33 | StateIdFromForUsIsRequired | State-issued ID is required for US residents |
| 34 | GivenNameInvalid | Given name contains invalid characters or format |
| 35 | HomeAddressError | Home address failed validation |
| 36 | WrongCombinationOfZipCityAndState | ZIP code, city, and state combination does not match USPS records |
| 37 | NationalPinIsEmpty | National identification PIN is missing |
| 38 | AffiliatedApprovalRequired | User is affiliated with a broker-dealer and requires pre-approval |
| 39 | ManualProcessingRequired | Application cannot be auto-processed and requires manual review |
| 40 | DisclosureFirmNameError | Disclosure firm name failed validation |
| 41 | MailingAddressError | Mailing address failed validation |
| 42 | UserIsNotPermanentResident | User does not meet permanent residency requirements |
| 43 | CipCheckRejectedBySketch | CIP (Customer Identification Program) check rejected by Sketch identity verification |
| 44 | AddressCouldNotBeVerified | Address could not be verified through identity verification services |
| 45 | SsnCouldNotBeVerified | SSN could not be verified through identity verification services |
| 46 | LastNameCouldNotBeVerified | Last name could not be verified through identity verification |
| 47 | FirstNameCouldNotBeVerified | First name could not be verified through identity verification |
| 48 | ApplicantProfileContainsHighRiskFraudWarning | Identity verification flagged the applicant as high-risk for fraud |
| 49 | DateOfBirthCouldNotBeVerified | Date of birth could not be verified through identity verification |
| 50 | CannotAutoAcceptForDeceased | Applicant flagged as deceased - cannot auto-approve |

**Key Characteristics**:
- Errors 1-3 are general/system errors
- Errors 4-7, 22, 34-36, 41 are field-level validation failures
- Errors 8-11 are form integrity/version errors
- Errors 12-21 are form/account type mismatch errors
- Errors 23-33, 37 are missing required data errors
- Errors 38-39, 46 are compliance/manual review triggers
- Errors 43-50 are CIP/identity verification failures from Sketch

**Used By**:

---

## Appropriateness Product {#appropriateness-product}

**Definition**: Financial product types that require suitability/appropriateness assessment before a user is permitted to trade them. Regulatory requirement to ensure the product is suitable for the user's experience and risk profile.

**Source Table**: `Dictionary.AppropriatenessProduct`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No specific product - default/placeholder |
| 1 | CFD | Contract for Difference - leveraged derivative product |
| 2 | FPSL | Fully Paid Securities Lending - program where user lends shares for income |
| 3 | Options | Options contracts - derivatives requiring additional suitability assessment |

**Key Characteristics**:
- Each product has its own appropriateness test and eligibility rules
- FPSL and Options are US-specific programs requiring separate enrolment

**Used By**:

---

## Appropriateness Recalculation Reason {#appropriateness-recalculation-reason}

**Definition**: The reason why a user's appropriateness/suitability assessment was recalculated. Tracks the trigger event that caused a re-evaluation of whether the user is suitable to trade a particular product.

**Source Table**: `Dictionary.AppropriatenessRecalculationReason`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No recalculation has occurred |
| 1 | BulkRecalculation | System-initiated mass recalculation across multiple users |
| 2 | RegulationChanged | Regulatory rule change triggered reassessment of all affected users |
| 3 | ReachedVerificationLevel2 | User reached a higher verification level, triggering eligibility reassessment |
| 4 | AnswerChanged | User updated their suitability questionnaire answers |
| 5 | Manual | Compliance team manually triggered a recalculation |

**Key Characteristics**:
- Reasons 1-2 are system/regulatory-driven bulk events
- Reasons 3-4 are user-driven individual events
- Reason 5 is compliance-team-driven

**Used By**:

---

## Appropriateness Test Result {#appropriateness-test-result}

**Definition**: The outcome of a suitability/appropriateness assessment for a specific financial product. Determines whether the user is permitted to trade the assessed product.

**Source Table**: `Dictionary.AppropriatenessTestResult`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | Assessment has not been performed yet |
| 1 | Failed | User did not meet suitability criteria - trading this product is blocked |
| 2 | Passed | User meets suitability criteria - trading this product is permitted |

**Key Characteristics**:
- Binary pass/fail outcome with a "not yet assessed" default
- Failing an appropriateness test blocks access to the specific product, not the entire account

**Used By**:

---

## Customer Type {#customer-type}

**Definition**: Classification of the brokerage account ownership structure at Apex Clearing. Determines the legal entity type for the account, which affects required forms, tax reporting, and account management rules.

**Source Table**: `Dictionary.CustomerType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | INDIVIDUAL | Single-owner account for one natural person |
| 2 | IRA | Individual Retirement Account - tax-advantaged retirement savings account |
| 3 | JOINT | Joint account owned by two or more individuals |
| 4 | CUSTODIAN | Custodial account managed by a custodian on behalf of a minor or beneficiary |

**Key Characteristics**:
- Customer type determines which Apex API forms and agreements are required
- IRA accounts have special IRS reporting and contribution/distribution rules
- Joint accounts require joint agreement forms

**Used By**:

---

## Document Type {#document-type}

**Definition**: Classification of identification documents submitted during the Apex account opening process for CIP (Customer Identification Program) compliance. These are government-issued IDs and supporting documents used to verify the applicant's identity.

**Source Table**: `Dictionary.DocumentType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | DRIVERS_LICENSE | State-issued driver's license |
| 2 | STATE_ID_CARD | State-issued identification card (non-driver) |
| 3 | PASSPORT | Government-issued passport |
| 4 | MILITARY_ID | US military identification card |
| 5 | SSN_CARD | Social Security Number card |
| 6 | SSA_LETTER | Social Security Administration letter confirming SSN |
| 7 | IRS_ITIN_LETTER | IRS letter assigning Individual Taxpayer Identification Number |
| 8 | OTHER_GOVERNMENT_ID | Other form of government-issued identification |
| 9 | CDD_DOCUMENT | Customer Due Diligence document for enhanced compliance review |
| 10 | ALL_PASSING_CIP_RESULTS | Composite record indicating all CIP checks passed |

**Key Characteristics**:
- Types 1-8 are primary identification documents
- Type 9 is for enhanced due diligence (CDD) requirements
- Type 10 is a synthetic record type indicating successful identity verification

**Used By**:

---

## Eligibility Status {#eligibility-status}

**Definition**: Binary indicator of whether a user is eligible/allowed to access a specific product or feature. Used in appropriateness and options eligibility assessments.

**Source Table**: `Dictionary.EligibilityStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Disallowed | User is not eligible - access to the product/feature is blocked |
| 1 | Allowed | User is eligible - access to the product/feature is permitted |

**Key Characteristics**:
- Simple binary gate used across multiple product eligibility checks

**Used By**:

---

## Modify Type {#modify-type}

**Definition**: The type of modification operation being performed on an Apex account. Tracks whether an API request is creating, updating, or closing an account.

**Source Table**: `Dictionary.ModifyType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Create | Initial account creation request to Apex Clearing |
| 2 | Update | Modification of an existing account's data (address, name, etc.) |
| 3 | Close | Account closure request to Apex Clearing |

**Key Characteristics**:
- Maps directly to the three main Apex API operation types
- Each modify type triggers a different state machine flow

**Used By**:

---

## Options Reasoning Form Answers {#options-reasoning-form-answers}

**Definition**: Predefined answer choices for the options reasoning form, which is presented to users who want to change their options trading level or re-apply after a rejection. The form captures the user's rationale for the change.

**Source Table**: `Dictionary.OptionsReasoningFormAnswers`

**Values**:

| ID | AnswerText | TranslationKey | Business Meaning |
|----|-----------|----------------|-----------------|
| 1 | Other | optionsReasoning.option1 | Free-text reason not covered by other options |
| 2 | Incorrect Selection | optionsReasoning.option2 | User originally selected the wrong option and wants to correct it |
| 3 | Changed Mind | optionsReasoning.option3 | User reconsidered their previous choice |
| 4 | Lifestyle Change | optionsReasoning.option4 | User's financial situation or risk tolerance changed |

**Key Characteristics**:
- TranslationKey enables UI localization of answer text
- These are the only valid answers for the reasoning form

**Used By**:

---

## Options Status {#options-status}

**Definition**: The approval status of a user's options trading application. Tracks the progression from initial request through review to final approval or rejection.

**Source Table**: `Dictionary.OptionsStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | User has not applied for options trading |
| 1 | Pending | Options application submitted and awaiting review |
| 2 | InProcess | Application is actively being reviewed |
| 3 | Approved | Options trading approved - user can trade options |
| 4 | Rejected | Options trading application rejected |

**Key Characteristics**:
- Separate from the main Apex account status - options is an add-on feature
- Only status 3 (Approved) enables options trading capability

**Used By**:

---

## Options Status Control {#options-status-control}

**Definition**: Administrative control flag that determines whether a user's options trading capability is blocked or allowed at a system level, independent of the options approval status.

**Source Table**: `Dictionary.OptionsStatusControl`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No control override applied |
| 1 | Blocked | Options trading is blocked by administrative control regardless of approval status |
| 2 | Allowed | Options trading is allowed by administrative control |

**Key Characteristics**:
- Acts as an override layer on top of OptionsStatus
- A user with OptionsStatus=Approved but OptionsStatusControl=Blocked cannot trade options

**Used By**:

---

## Phone Type {#phone-type}

**Definition**: Classification of phone numbers collected during account onboarding. Used to categorize the different phone numbers a user may provide.

**Source Table**: `Dictionary.PhoneType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Home | Residential landline phone number |
| 2 | Work | Business/employer phone number |
| 3 | Mobile | Personal mobile/cell phone number |
| 4 | Fax | Fax number |
| 5 | Other | Phone number that does not fit other categories |

**Key Characteristics**:
- Standard phone type classification for financial account applications

**Used By**:

---

## Reasoning Status {#reasoning-status}

**Definition**: The status of a user's options reasoning form submission. Tracks the review workflow when a user provides reasoning for an options trading level change or re-application.

**Source Table**: `Dictionary.ReasoningStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No reasoning form has been submitted |
| 1 | PendingReasoningScreen | User needs to complete the reasoning form screen |
| 2 | PendingManualReview | Reasoning form submitted and awaiting manual compliance review |
| 3 | Allowed | Reasoning accepted - options level change approved |
| 4 | DisallowedByManualReview | Manual reviewer rejected the reasoning - change denied |

**Key Characteristics**:
- Workflow: None -> PendingReasoningScreen -> PendingManualReview -> Allowed/DisallowedByManualReview
- Only applies when user is attempting to change options trading level

**Used By**:

---

## Sketch Investigation Reason Type {#sketch-investigation-reason-type}

**Definition**: The outcome category from a Sketch identity verification (CIP) investigation. Sketch is the identity verification provider used during account onboarding to verify applicant identity.

**Source Table**: `Dictionary.SketchInvestigationReasonType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No investigation outcome recorded |
| 1 | Indeterminate | Identity verification was inconclusive - may require additional documents or manual review |
| 2 | Reject | Identity verification definitively failed - applicant cannot proceed |

**Key Characteristics**:
- "Sketch" is the CIP (Customer Identification Program) provider
- Indeterminate results may trigger auto-appeal or manual review flows
- Reject is a hard stop requiring the applicant to appeal or be denied

**Used By**:

---

## State (Apex State) {#state-apex-state}

**Definition**: The granular state machine state for Apex account processing. Represents the exact step in the account creation, update, closure, or investigation workflow. This is the core workflow engine that drives the Apex integration.

**Source Table**: `Dictionary.State`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | CreateState | Initial state - account creation flow begins |
| 2 | CollectUserData | Gathering user personal/financial data for account application |
| 3 | SendCreateAccountRequest | Sending account creation request to Apex Clearing API |
| 4 | PullCreateAccountRequest | Polling Apex API for account creation response |
| 5 | WaitForFailingUserDataUpdateAfterCreateAccountRequest | Waiting after failed user data update post-creation request |
| 6 | WaitForUserDataUpdate | Waiting for user to provide updated/corrected data |
| 7 | NotifyTradingCompleted | Notifying the trading platform that account creation is complete |
| 8 | Observation | Account in observation/monitoring period |
| 9 | CreateAccountRejected | Account creation was rejected by Apex |
| 10 | InitiateAutoAppeal | System automatically appealing a rejected account creation |
| 11 | CollectUserDataForAccountUpdate | Gathering data for an account update operation |
| 12 | SendUpdateAccountRequest | Sending account update request to Apex API |
| 13 | WaitForUserDataUpdateForAccountUpdate | Waiting for user data during account update flow |
| 14 | WaitForFailingUserDataUpdateAfterUpdateAccountRequest | Waiting after failed user data update post-update request |
| 15 | PullUpdateAccountRequest | Polling Apex API for account update response |
| 16 | NotifyTradingUpdateAccountRejected | Notifying trading platform that account update was rejected |
| 17 | UpdateAccountRejected | Account update was rejected by Apex |
| 18 | InitiateAutoAppealForUpdate | System automatically appealing a rejected account update |
| 19 | ManualUpdateRequired | Account update requires manual intervention |
| 20 | GetSketchInvestigationState | Checking Sketch investigation status during account creation |
| 21 | SketchInvestigationRejected | Sketch investigation rejected during account creation |
| 22 | SketchInvestigationResolved | Sketch investigation resolved successfully during account creation |
| 23 | ResolveSketchIndeterminateState | Handling indeterminate Sketch result during account creation |
| 24 | AppealRejectedSketchInvestigation | Appealing rejected Sketch investigation during account creation |
| 25 | GetSketchInvestigationStateAfterAppeal | Checking Sketch status after appeal during account creation |
| 26 | SketchInvestigationRejectedAfterAppeal | Sketch investigation still rejected after appeal during account creation |
| 27 | GetSketchInvestigationStateForUpdateAccount | Checking Sketch investigation during account update |
| 28 | SketchInvestigationRejectedForUpdateAccount | Sketch investigation rejected during account update |
| 29 | SketchInvestigationResolvedForUpdateAccount | Sketch investigation resolved during account update |
| 30 | ResolveSketchIndeterminateStateForUpdateAccount | Handling indeterminate Sketch result during account update |
| 31 | AppealRejectedSketchInvestigationForUpdateAccount | Appealing rejected Sketch investigation during account update |
| 32 | GetSketchInvestigationStateAfterAppealForUpdateAccount | Checking Sketch status after appeal during account update |
| 33 | SketchInvestigationRejectedAfterAppealForUpdateAccount | Sketch investigation still rejected after appeal during account update |
| 34 | SketchInvestigationError | Error during Sketch investigation for account creation |
| 35 | SketchInvestigationErrorForUpdateAccount | Error during Sketch investigation for account update |
| 36 | AffiliatedApprovalRequired | User is affiliated with a broker-dealer; requires pre-trade approval |
| 37 | AffiliatedApprovalRequiredForAccountUpdate | Affiliated approval needed for account update |
| 38 | RestrictAccount | Initiating account restriction |
| 39 | AccountRestricted | Account has been restricted |
| 40 | NotifyTradingAfterAccountUpdate | Notifying trading platform after successful account update |
| 41 | CloseAccountCleanupData | Cleaning up data prior to account closure |
| 42 | SendCloseAccountRequest | Sending account closure request to Apex API |
| 43 | PullCloseAccountRequest | Polling Apex API for account closure response |
| 44 | CloseAccountRequestCompleted | Account closure completed successfully |
| 45 | CloseAccountRequestRejected | Account closure request rejected by Apex |
| 46 | VisaAppovalRequired | Visa approval required (non-US resident verification) |
| 47 | ManualAppealRequired | Manual appeal process required - cannot be auto-appealed |

**Key Characteristics**:
- States 1-10 are the account CREATION flow
- States 11-19 are the account UPDATE flow
- States 20-35 are Sketch identity INVESTIGATION states (duplicated for create vs update flows)
- States 36-37 are AFFILIATED approval states
- States 38-39 are RESTRICTION states
- States 41-45 are the account CLOSURE flow
- States 46-47 are special approval states
- The state machine is the central orchestrator of all Apex integration workflows

**Used By**:

---

## User Data Updates Mask {#user-data-updates-mask}

**Definition**: Bitmask values identifying which specific fields were updated in a user data change. Each bit position represents a different data field, allowing multiple field changes to be tracked in a single integer value.

**Source Table**: `Dictionary.UserDataUpdatesMask`

**Values**:

| Mask | Name | Business Meaning |
|------|------|-----------------|
| 1 | Disclosures | Regulatory disclosures and agreements were updated |
| 2 | Name | User's legal name was changed |
| 4 | DateOfBirth | Date of birth was corrected |
| 8 | CitizenshipCountry | Citizenship country was updated |
| 16 | SocialSecurityNumber | SSN was changed or corrected |
| 32 | BirthCountry | Country of birth was updated |
| 64 | PhoneNumber | Phone number was changed |
| 128 | HomeAddress | Home/residential address was updated |
| 256 | Email | Email address was changed |
| 512 | PermanentResident | Permanent residency status was updated |
| 1024 | TrustedContact | Trusted contact information was changed |
| 2048 | MailingAddress | Mailing address (if different from home) was updated |
| 4096 | Instructions | Special instructions or notes were updated |

**Key Characteristics**:
- Bitmask pattern: values are powers of 2, allowing bitwise OR to combine multiple fields
- Example: Mask=192 (128+64) means both HomeAddress and PhoneNumber were updated
- Used to determine which Apex API update calls need to be made

**Used By**:

---

## User Document Type {#user-document-type}

**Definition**: Classification of documents uploaded by users during the Apex account lifecycle. These are user-submitted files (not the identification document types used for CIP verification).

**Source Table**: `Dictionary.UserDocumentType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | SIGNATURE_IMAGE | Digital signature image for account agreements |
| 2 | ID_DOCUMENT | Uploaded copy of identification document |
| 3 | IRA_DEPOSIT_SLIP | Deposit slip for IRA account funding |
| 4 | ACCOUNT_TRANSFER_FORM | Form to transfer account from another broker (ACAT transfer) |
| 5 | AFFILIATED_APPROVAL | Pre-approval document for broker-dealer affiliated persons |
| 6 | OTHER | Miscellaneous document not fitting other categories |

**Key Characteristics**:
- Distinct from Dictionary.DocumentType which classifies government ID types for CIP
- These are user-uploaded files stored and tracked in the system

**Used By**:

---

## User Program {#user-program}

**Definition**: Optional programs and features that users can enrol in beyond basic trading. Each program has its own eligibility requirements and enrolment workflow.

**Source Table**: `Dictionary.UserProgram`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No program - default/placeholder |
| 1 | FPSL | Fully Paid Securities Lending - user lends owned shares to short sellers for income |
| 2 | CryptoStaking | Cryptocurrency staking program for earning staking rewards |
| 3 | EthStaking | Ethereum-specific staking program |
| 4 | ProxyVotingManualPositions | Proxy voting for manually-held stock positions |
| 5 | ProxyVotingCopiedPositions | Proxy voting for positions held via copy trading |

**Key Characteristics**:
- Programs 1-3 are income-generating features
- Programs 4-5 are shareholder governance features
- Each program requires separate opt-in/opt-out tracking

**Used By**:

---

## User Program Enrolment Status {#user-program-enrolment-status}

**Definition**: The enrolment state of a user for a specific optional program. Tracks whether the user has opted in or out of the program.

**Source Table**: `Dictionary.UserProgramEnrolmentStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | User has not made an enrolment decision for this program |
| 1 | OptIn | User has actively enrolled in the program |
| 2 | OptOut | User has actively declined or withdrawn from the program |

**Key Characteristics**:
- Three-state model distinguishing "never decided" (None) from "actively declined" (OptOut)

**Used By**:

---

## Business Concepts

*No concept-based terms yet. Will be populated as objects are documented.*
