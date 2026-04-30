# Business Glossary - UserApiDB

> Canonical definitions for business terms, value domains, and concepts.
> Object docs reference this glossary for shared terminology.
> Terms are progressively enriched as more objects are documented.

*Last updated: 2026-04-12 | Terms: 51 lookup-backed, 0 concept-based | Sources: 51 Dictionary tables, 35 KYC object docs*

---

## Lookup-Backed Terms

## Account Activation {#account-activation}

**Definition**: Defines activation pathways available for user accounts on the platform. Controls which onboarding flow a user goes through when activating their account.

**Source Table**: `Dictionary.AccountActivation`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Activate_eToro | Standard eToro platform activation flow |

**Used By**: *(to be populated)*

---

## Answer Status {#answer-status}

**Definition**: Tracks the validity state of user-provided answers (e.g., KYC questionnaire responses). Determines whether answers are still current or have been superseded.

**Source Table**: `Dictionary.AnswerStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Outdated | Answer is no longer current - has been superseded by a newer response |
| 1 | Active | Answer is the current, valid response |

**Used By**: KYC.Answers (StatusID)

---

## ASIC Classification {#asic-classification}

**Definition**: Client classification categories under Australian Securities and Investments Commission (ASIC) regulation. Determines the regulatory protections and product access available to Australian users.

**Source Table**: `Dictionary.AsicClassification`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | RetailPending | Awaiting retail classification determination |
| 2 | SophisticatedInvestor | Meets ASIC sophisticated investor criteria - reduced disclosure requirements |
| 3 | WholesaleInvestor | Meets ASIC wholesale investor threshold - broadest product access |
| 4 | Retail | Standard retail client - full regulatory protections apply |
| 5 | Pending | Classification assessment not yet started |

**Used By**: *(to be populated)*

---

## Attribute {#attribute}

**Definition**: Defines user interest or activity attributes used for segmentation and marketing. Tracks which product categories a user has shown interest in or interacted with.

**Source Table**: `Dictionary.Attribute`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Stocks | User has interest/activity in stock trading |
| 2 | Crypto | User has interest/activity in cryptocurrency trading |
| 3 | Copy Trader | User has interest/activity in copy trading (following other traders) |
| 4 | Copy Portfolio | User has interest/activity in copy portfolios (thematic investment strategies) |
| 5 | CFD | User has interest/activity in CFD (Contract for Difference) trading |

**Used By**: *(to be populated)*

---

## Attribute Group {#attribute-group}

**Definition**: Groups user attributes into categories for organized segmentation. Defines the context in which attributes are collected.

**Source Table**: `Dictionary.AttributeGroup`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Funnel | Attributes collected during the registration/onboarding funnel |

**Used By**: *(to be populated)*

---

## Close User Category {#close-user-category}

**Definition**: Top-level categories for user account closure reasons. Part of a three-tier hierarchy: Category -> Reason -> Solution, used in the self-service account closure flow.

**Source Table**: `Dictionary.CloseUserCategory`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | paymentIssues | User wants to close due to payment/financial problems |
| 2 | accountIssues | User wants to close due to account-related problems |
| 3 | notMeetNeeds | Platform does not meet user's trading/investment needs |
| 4 | personalReasons | Personal circumstances driving the closure request |
| 5 | other | Reason does not fit other categories |
| 6 | privacyConcerns | User has data privacy or security concerns |

**Used By**: *(to be populated)*

---

## Close User Not Allowed Reason {#close-user-not-allowed-reason}

**Definition**: Reasons why an account closure request cannot be processed. These are blocking conditions that must be resolved before the account can be closed.

**Source Table**: `Dictionary.CloseUserNotAllowedReason`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | TooHighEquity | Account equity exceeds the threshold for self-service closure |
| 2 | OpenOrders | Account has pending/open orders that must be cancelled first |
| 3 | OpenPositions | Account has open trading positions that must be closed first |
| 4 | OpenMirrors | Account is actively copy-trading (mirroring) other users |
| 5 | OpenCashouts | Account has pending withdrawal requests |
| 6 | WalletNotAllowedToClose | Associated eToro Money wallet has restrictions preventing closure |

**Used By**: *(to be populated)*

---

## Close User Reason {#close-user-reason}

**Definition**: Specific reasons within each closure category. Second tier in the Category -> Reason -> Solution hierarchy. Each reason maps to exactly one category.

**Source Table**: `Dictionary.CloseUserReason`

**Values**:

| ID | Name | Category |
|----|------|----------|
| 1 | paymentIssuesReasonFeeTooHigh | 1 (paymentIssues) |
| 2 | paymentIssuesReasonDepositProblem | 1 (paymentIssues) |
| 3 | paymentIssuesReasonWithdrawalProblem | 1 (paymentIssues) |
| 4 | accountIssuesReasonServiceProblem | 2 (accountIssues) |
| 5 | accountIssuesReasonAccountBlocked | 2 (accountIssues) |
| 6 | accountIssuesReasonPromotionalEmail | 2 (accountIssues) |
| 7 | accountIssuesReasonChangeEmail | 2 (accountIssues) |
| 8 | accountIssuesReasonNewAccount | 2 (accountIssues) |
| 9 | notMeetNeedsReasonMissingInstrument | 3 (notMeetNeeds) |
| 10 | notMeetNeedsReasonTransferToWallet | 3 (notMeetNeeds) |
| 11 | notMeetNeedsReasonUnstablePlatform | 3 (notMeetNeeds) |
| 12 | notMeetNeedsReasonMissingFeature | 3 (notMeetNeeds) |
| 13 | personalReasonsReasonNeedMoney | 4 (personalReasons) |
| 14 | personalReasonsReasonAchieveGoals | 4 (personalReasons) |
| 15 | personalReasonsReasonNotUsingAccount | 4 (personalReasons) |
| 16 | personalReasonsReasonNotHaveTime | 4 (personalReasons) |
| 17 | personalReasonsReasonNotSafe | 4 (personalReasons) |

**Key Characteristics**:
- 1:1 mapping between reasons and solutions
- Naming convention: `{categoryName}Reason{SpecificReason}`

**Used By**: *(to be populated)*

---

## Close User Solution {#close-user-solution}

**Definition**: Retention solutions offered to users for each specific closure reason. Third tier in the Category -> Reason -> Solution hierarchy. Each solution maps to exactly one reason and one category.

**Source Table**: `Dictionary.CloseUserSolution`

**Values**:

| ID | Name | Category | Reason |
|----|------|----------|--------|
| 1 | paymentIssuesSolutionFeeTooHigh | 1 | 1 |
| 2 | paymentIssuesSolutionDepositProblem | 1 | 2 |
| 3 | paymentIssuesSolutionWithdrawalProblem | 1 | 3 |
| 4 | accountIssuesSolutionServiceProblem | 2 | 4 |
| 5 | accountIssuesSolutionAccountBlocked | 2 | 5 |
| 6 | accountIssuessolutionPromotionalEmail | 2 | 6 |
| 7 | accountIssuesSolutionChangeEmail | 2 | 7 |
| 8 | accountIssuesSolutionNewAccount | 2 | 8 |
| 9 | notMeetNeedsSolutionMissingInstrument | 3 | 9 |
| 10 | notMeetNeedsSolutionTransferToWallet | 3 | 10 |
| 11 | notMeetNeedsSolutionUnstablePlatform | 3 | 11 |
| 12 | notMeetNeedsSolutionMissingFeature | 3 | 12 |
| 13 | personalReasonsSolutionNeedMoney | 4 | 13 |
| 14 | personalReasonsSolutionAchieveGoals | 4 | 14 |
| 15 | personalReasonsSolutionNotUsingAccount | 4 | 15 |
| 16 | personalReasonsSolutionNotHaveTime | 4 | 16 |
| 17 | personalReasonsSolutionNotSafe | 4 | 17 |

**Key Characteristics**:
- Naming convention: `{categoryName}Solution{SpecificReason}`
- Each row is a unique Category+Reason+Solution triple

**Used By**: *(to be populated)*

---

## Close User Solve Problem {#close-user-solve-problem}

**Definition**: User's response to the retention solution presented during account closure. Captures whether the solution resolved their concern.

**Source Table**: `Dictionary.CloseUserSolveProblem`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | yesKeepOpen | Solution worked - user decides to keep account open |
| 2 | yesClose | Solution acknowledged but user still wants to close |
| 3 | noClose | Solution did not address the problem - user wants to close |

**Used By**: *(to be populated)*

---

## Country {#country}

**Definition**: Master list of countries recognized by the platform. Used across the system for user registration, regulatory assignment, KYC, and geo-targeting. Contains 251 countries.

**Source Table**: `Dictionary.Country`

**Key Characteristics**:
- 251 rows - full value map omitted for brevity
- Referenced by: CountryIP, RegionByIP, RegionByIP_ISOCode, State, SubRegion
- Core dimension for regulatory jurisdiction assignment

**Used By**: KYC.FastVerificationConfiguration (CountryId), KYC.CountryTaxType (CountryID - implicit), KYC.NationalCountry (CountryID - implicit)

---

## Country IP {#country-ip}

**Definition**: IP address range-to-country mapping table for geo-location of users based on their IP address. Used for regulatory routing, fraud detection, and access control. Contains 6.8M IP range records.

**Source Table**: `Dictionary.CountryIP`

**Key Characteristics**:
- 6,864,024 rows - large reference data table
- Maps IP ranges (IPFrom-IPTo) to CountryID and RegionID
- Used for real-time geo-location during registration and login

**Used By**: *(to be populated)*

---

## Crypto Assessment Answer Category {#crypto-assessment-answer-category}

**Definition**: Categories of questions in the cryptocurrency knowledge assessment required for crypto trading access. Tests user understanding of crypto-specific risks.

**Source Table**: `Dictionary.CryptoAssessmentAnswerCategory`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Complete Loss Potential | Assesses understanding that crypto value can drop to zero |
| 2 | Cyber-Risks | Assesses understanding of hacking, theft, and security risks |
| 3 | Diversification/Risk Management | Assesses understanding of portfolio risk management with crypto |
| 4 | Lack of Regulatory Protection | Assesses understanding that crypto may lack deposit protection |
| 5 | Liquidity | Assesses understanding that crypto markets may lack liquidity |
| 6 | Technical Characteristics | Assesses understanding of blockchain/crypto technology basics |
| 7 | Volatility | Assesses understanding of extreme price swings in crypto |

**Used By**: KYC.CryptoAssessmentAnswers (AnswerCategoryId)

---

## DLT Status {#dlt-status}

**Definition**: Distributed Ledger Technology (blockchain) verification status for crypto-related operations. Tracks the lifecycle of DLT verification processes.

**Source Table**: `Dictionary.DltStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Pending | DLT verification request submitted, awaiting processing |
| 2 | Ongoing | DLT verification in progress |
| 3 | Failed | DLT verification did not pass |
| 4 | Passed | DLT verification completed successfully |
| 5 | Inactive | DLT verification no longer active/relevant |

**Used By**: *(to be populated)*

---

## Email Verification Provider {#email-verification-provider}

**Definition**: Third-party identity providers used to verify user email addresses during registration. Supports direct email verification and social login OAuth providers.

**Source Table**: `Dictionary.EmailVerificationProvider`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | eToro | Direct email verification via eToro's own system |
| 3 | Facebook | Email verified through Facebook OAuth login |
| 5 | Google | Email verified through Google OAuth login |
| 6 | Apple | Email verified through Apple Sign-In |

**Key Characteristics**:
- IDs 2 and 4 are skipped (likely deprecated providers)

**Used By**: *(to be populated)*

---

## EV Match Status {#ev-match-status}

**Definition**: Electronic Verification (EV) match result status. Indicates how well user-provided identity data matched against the verification provider's data sources.

**Source Table**: `Dictionary.EvMatchStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No match attempt has been made |
| 1 | PartiallyVerified | Some identity fields matched but not all required fields |
| 2 | Verified | Full match - all required identity fields confirmed |
| 3 | NotVerified | Match attempted but identity data could not be confirmed |

**Used By**: *(to be populated)*

---

## EV Provider {#ev-provider}

**Definition**: Third-party Electronic Verification (identity verification) service providers integrated with the platform. Each provider is classified by type (electronic or document-based).

**Source Table**: `Dictionary.EvProvider`

**Values**:

| ID | Name | Type | Business Meaning |
|----|------|------|-----------------|
| 1 | GDC | Electronic (0) | GDC electronic identity verification |
| 2 | GBG | Electronic (0) | GBG Group electronic verification |
| 3 | Au10tix-Documents | Documents (1) | Au10tix document verification (ID scanning) |
| 4 | TruNarrative | Electronic (0) | TruNarrative electronic verification |
| 5 | Cognito | Electronic (0) | Cognito electronic verification |
| 6 | Melisa | Electronic (0) | Melissa data quality and identity verification |
| 7 | Au10tix-Ev | Electronic (0) | Au10tix electronic verification (non-document) |
| 8 | Trulioo | Electronic (0) | Trulioo GlobalGateway electronic verification |
| 9 | DataZoo | Electronic (0) | DataZoo electronic verification |
| 10 | Au10tix_Selfie | Documents (1) | Au10tix selfie/biometric verification |
| 11 | IDMerit | Electronic (0) | IDMerit electronic verification |
| 12 | DataZoo2 | Electronic (0) | DataZoo second-generation integration |
| 13 | Onfido | Documents (1) | Onfido document and biometric verification |
| 14 | SumSub | Documents (1) | Sum&Substance document verification |
| 15 | Prove | Electronic (0) | Prove phone-centric identity verification |

**Key Characteristics**:
- FK to Dictionary.ProviderType (0=Electronic, 1=Documents)
- Predominantly electronic verification providers (11 of 15)

**Used By**: *(to be populated)*

---

## EV Provider Settings {#ev-provider-settings}

**Definition**: Configuration setting types for Electronic Verification providers. Defines the credential and configuration fields required to integrate with each EV provider.

**Source Table**: `Dictionary.EvProviderSettings`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | ProfileId | Provider-specific profile/account identifier |
| 1 | ProfileVersion | Version of the provider integration profile |
| 2 | UserName | Authentication username for the provider API |
| 3 | Password | Authentication password/secret for the provider API |

**Used By**: *(to be populated)*

---

## EV Status {#ev-status}

**Definition**: Overall Electronic Verification status for a user's identity verification process. Represents the aggregated outcome across potentially multiple verification sources.

**Source Table**: `Dictionary.EvStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No electronic verification attempted |
| 1 | One Source | Verified by one data source (may need additional) |
| 2 | Two Sources | Verified by two independent data sources |
| 3 | No Match | Verification attempted but no data sources matched |
| 4 | ApprovedWithConflict | Manually approved despite conflicting verification data |
| 5 | Approved | Fully approved through verification process |
| 6 | Rejected | Verification failed - identity could not be confirmed |
| 7 | Alert | Verification flagged for manual review |
| 8 | One Source Verified | Single source verification completed and accepted |

**Used By**: *(to be populated)*

---

## Extended User Field {#extended-user-field}

**Definition**: Defines additional user profile fields beyond the core registration fields. These are regulation-specific or country-specific data collection fields (e.g., tax IDs, national PINs, employer names).

**Source Table**: `Dictionary.ExtendedUserField`

**Values**:

| ID | Name | Type | Business Meaning |
|----|------|------|-----------------|
| 0 | province | Address (0) | User's province/state within their address |
| 1 | SecondSurname | Name (1) | Second surname (common in Spanish-speaking countries) |
| 2 | CodeFiscale | NationalId (2) | Italian fiscal code (Codice Fiscale) |
| 3 | SocialInsuranceNumber | NationalId (2) | Social insurance/security number |
| 4 | NIF | NationalId (2) | Portuguese/Spanish tax identification number |
| 5 | SubBuildingNumber | Address (0) | Apartment/unit number within a building |
| 6 | TaxId | Tax ID (3) | Generic tax identification number |
| 7 | NationalPin | NationalPin (4) | National personal identification number |
| 8 | EmployerName | Employer Name (5) | User's employer name (for source of funds) |
| 9 | DepositQuestion | DepositQuestion (6) | Deposit-related KYC question response |
| 10 | WithdrawQuestion | WithdrawQuestion (7) | Withdrawal-related KYC question response |
| 11 | DedicatedEv | DedicatedEv (9) | Dedicated electronic verification field |

**Key Characteristics**:
- FK to Dictionary.ExtendedUserFieldType via FieldTypeId
- Fields are assigned to users based on their regulation and country

**Used By**: *(to be populated)*

---

## Extended User Field Type {#extended-user-field-type}

**Definition**: Categories of extended user profile fields. Groups related fields by their data nature and purpose.

**Source Table**: `Dictionary.ExtendedUserFieldType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Address | Address-related fields (province, sub-building) |
| 1 | Name | Name-related fields (second surname) |
| 2 | NationalId | National identification document numbers |
| 3 | Tax ID | Tax identification numbers by country |
| 4 | NationalPin | National personal identification numbers for regulatory reporting |
| 5 | Employer Name | Employment information for source-of-funds verification |
| 6 | DepositQuestion | KYC questions related to deposit activity |
| 7 | WithdrawQuestion | KYC questions related to withdrawal activity |
| 8 | Text | Generic text fields |
| 9 | DedicatedEv | Fields specific to electronic verification processes |

**Used By**: *(to be populated)*

---

## Extended User Value Type {#extended-user-value-type}

**Definition**: Specific subtypes of extended user field values, primarily for Tax ID and NationalPin fields. Maps country-specific document types to their parent field type category. Contains 43 value types.

**Source Table**: `Dictionary.ExtendedUserValueType`

**Key Characteristics**:
- FK to Dictionary.ExtendedUserFieldType via FieldTypeID
- Predominantly Tax ID (type 3) and NationalPin (type 4) subtypes
- Examples: LEI, CONCAT, NationalNumber, PassportNumber, TaxNumber, SocialSecurityNumber
- Country-specific tax IDs: taxCPR (Denmark), taxUTR (UK), taxTFN (Australia), taxCPF (Brazil), taxPAN (India)

**Used By**: *(to be populated)*

---

## Guru Status {#guru-status}

**Definition**: Popular Investor (PI) program tier status. Defines the progression levels for traders in eToro's copy-trading program where successful traders ("gurus") are copied by other users.

**Source Table**: `Dictionary.GuruStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | No | Not a Popular Investor - standard user |
| 1 | Certified | Legacy certified PI status |
| 2 | Cadet | Entry-level PI tier - initial qualification achieved |
| 3 | Rising Star | Second PI tier - growing copier base and performance |
| 4 | Champion | Third PI tier - established track record |
| 5 | Elite | Fourth PI tier - top-performing PI with significant AUM |
| 6 | Elite Pro | Highest PI tier - premier status with maximum benefits |
| 7 | Removed | Removed from the PI program (disqualified or voluntarily left) |
| 8 | Rejected | PI application was rejected |

**Key Characteristics**:
- Progression: Cadet -> Rising Star -> Champion -> Elite -> Elite Pro
- PIs earn compensation based on assets under management from copiers

**Used By**: *(to be populated)*

---

## KYC Regulation Config Type {#kyc-regulation-config-type}

**Definition**: Configuration types for KYC (Know Your Customer) regulation-specific settings. Defines the types of locale/format configurations that vary by regulatory jurisdiction.

**Source Table**: `Dictionary.KycRegulationConfigType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Title | User title/salutation format (Mr, Mrs, etc.) per regulation |
| 2 | Prefix | Phone number prefix rules per regulation |
| 3 | Special Char | Allowed special characters in name fields per regulation |

**Used By**: KYC.RegulationConfig (TypeID)

---

## Label {#label}

**Definition**: White-label brand configurations for the platform. Each label represents a distinct brand identity with its own URL and visual assets. Supports eToro's multi-brand architecture.

**Source Table**: `Dictionary.Label`

**Key Characteristics**:
- 25 rows covering brands: eToro, RetailFX, eToroUSA, eToroRussia, eToroChina, and various partner labels
- LabelID 0 and 1 are both eToro (legacy duplication)
- Each label has URL and CashierLogoURL for brand-specific payment pages
- Several labels appear to be historical/deprecated partner brands

**Used By**: *(to be populated)*

---

## Language {#language}

**Definition**: Platform-supported languages for UI localization and user communication. Each language has ISO codes and culture codes for proper formatting of dates, numbers, and text.

**Source Table**: `Dictionary.Language`

**Key Characteristics**:
- 28 supported languages
- Includes ISO 639-1 codes (en, de, ar, etc.) and .NET culture codes (en-GB, de-DE, etc.)
- Unique index on Name ensures no duplicate language entries
- Notable: separate entries for English (en-GB) and EnglishUS (en-US), Portuguese (pt-BR) and EuropeanPortuguese (pt-PT)

**Used By**: *(to be populated)*

---

## Mandatory Type {#mandatory-type}

**Definition**: Defines whether a KYC field or document is required, optional, or exempt for a given regulatory configuration.

**Source Table**: `Dictionary.MandatoryType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Exempt | Field is not applicable for this regulation/country |
| 1 | Optional | Field is available but not required |
| 2 | Mandatory | Field must be provided - registration cannot complete without it |

**Used By**: KYC.NationalCountry (MandatoryTypeID)

---

## MiFID Categorization {#mifid-categorization}

**Definition**: Client classification under the Markets in Financial Instruments Directive (MiFID II) - EU regulation. Determines product access, leverage limits, and regulatory protections.

**Source Table**: `Dictionary.MifidCategorization`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | MiFID categorization not applicable (non-EU regulation) |
| 1 | Retail | Standard retail client - maximum regulatory protections, leverage limits apply |
| 2 | Professional | Professional client - reduced protections, higher leverage allowed |
| 3 | Elective professional | Retail client who has opted up to professional status after meeting criteria |
| 4 | Retail Pending | Pending determination - temporarily treated as retail |
| 5 | Pending | Classification assessment in progress |

**Used By**: *(to be populated)*

---

## National Pin Report Type {#national-pin-report-type}

**Definition**: Reporting format types for national personal identification numbers in regulatory filings (e.g., transaction reporting to regulators).

**Source Table**: `Dictionary.NationalPinReportType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | NIND | National Identifier - standard national ID number |
| 2 | CCCP | Client Country Code + Passport number concatenation |
| 3 | CONCAT | Concatenated identifier format (country code + ID) |
| 4 | LEI | Legal Entity Identifier - for corporate/institutional clients |

**Used By**: *(to be populated)*

---

## National Pin Value Type To Report Type {#national-pin-value-type-to-report-type}

**Definition**: Junction table mapping ExtendedUserValueType PIN types to their appropriate regulatory reporting format. Determines how each type of national identifier is formatted for regulatory reports.

**Source Table**: `Dictionary.NationalPinValueTypeToReportType`

**Key Characteristics**:
- 9 mapping rows
- FK to Dictionary.ExtendedUserValueType (ValueTypeID) and Dictionary.NationalPinReportType (NationalPinReportTypeID)
- Examples: LEI (37) -> LEI report (4), CONCAT (38) -> CONCAT report (3), NationalNumber (39) -> NIND report (1), PassportNumber (40) -> CCCP report (2)

**Used By**: *(to be populated)*

---

## Player Level {#player-level}

**Definition**: eToro Club membership tiers that determine user benefits like cashout speed, wallet access, and priority support. Level is determined by realized equity thresholds.

**Source Table**: `Dictionary.PlayerLevel`

**Values**:

| ID | Name | Equity Range | Cashout Hours | Sort |
|----|------|-------------|---------------|------|
| 1 | Bronze | -$100K to $5K | 120h | 1 |
| 5 | Silver | $5K to $10K | 120h | 2 |
| 3 | Gold | $10K to $25K | 72h | 3 |
| 2 | Platinum | $25K to $50K | 24h | 4 |
| 6 | Platinum Plus | $50K to $250K | 24h | 5 |
| 7 | Diamond | $250K+ | 24h | 6 |
| 4 | Internal | N/A | 120h | 0 |

**Key Characteristics**:
- Progression: Bronze -> Silver -> Gold -> Platinum -> Platinum Plus -> Diamond
- Higher tiers get faster withdrawal processing (120h -> 24h)
- DaysInRiskBeforeDowngrade: 0 for Bronze/Internal, 180 for Silver-Platinum, 365 for Platinum Plus-Diamond
- ThresholdPercentToCurrentLevel: 5% buffer before downgrade
- Internal is a special tier for employee/test accounts

**Used By**: *(to be populated)*

---

## Player Status {#player-status}

**Definition**: Account status that controls what actions a user can perform on the platform. Each status defines a permission matrix across trading, deposits, withdrawals, login, and social features.

**Source Table**: `Dictionary.PlayerStatus`

**Values**:

| ID | Name | Blocked | Key Restrictions |
|----|------|---------|-----------------|
| 1 | Normal | No | Full access - no restrictions |
| 2 | Blocked | Yes | All actions blocked including login |
| 3 | Chat Blocked | No | Cannot chat/post; all other actions allowed |
| 4 | Blocked Upon Request | Yes | User-requested block - all actions blocked |
| 5 | Warning | No | Full access but flagged for monitoring |
| 6 | Blocked - Under Investigation | Yes | Compliance investigation - all blocked |
| 7 | Scalpers Block | Yes | Blocked for scalping trading pattern abuse |
| 8 | Blocked - PayPal Investigation | Yes | Blocked pending PayPal dispute resolution |
| 9 | Trade & MIMO Blocked | No | Can close positions and login, cannot open/deposit/withdraw |
| 10 | Deposit Blocked | No | Cannot deposit; all other actions allowed |
| 11 | Social Index | No | Cannot deposit/withdraw; can trade and use social features |
| 12 | Copy Block | No | Cannot copy other traders; all other actions allowed |
| 13 | Pending Verification | No | Can close positions and login; cannot open new trades or transact |
| 14 | Blocked - Failed Verification | Yes | Identity verification failed - all blocked |
| 15 | Block Deposit & Trading | No | Can close positions and login; no deposits or new trades |

**Key Characteristics**:
- IsBlocked=true means CanLogin=false (complete lockout)
- Partial blocks (9, 10, 13, 15) allow closing existing positions but restrict new activity
- CanCopy defaults to true for all statuses (copy positions auto-managed)

**Used By**: *(to be populated)*

---

## Player Status Reason {#player-status-reason}

**Definition**: Primary reasons for placing a user into a non-Normal player status. Provides the business justification for account restrictions. Contains 43 reasons.

**Source Table**: `Dictionary.PlayerStatusReasons`

**Key Characteristics**:
- 43 values (0-42)
- Major categories: Compliance (AML, KYC, Risk, HRC), Financial (Chargeback, Overpayment), User-initiated (CloseAccountByUser, Self-Service, By request), Operational (Hacked Account, Employee Account, PI Account)
- ID 0 = None (no specific reason)
- Compliance-heavy: 10+ AML/KYC/Risk related reasons

**Used By**: *(to be populated)*

---

## Player Status Sub Reason {#player-status-sub-reason}

**Definition**: Granular sub-reasons providing additional detail within a player status reason. Enables precise categorization for compliance reporting and operational tracking. Contains 80 sub-reasons.

**Source Table**: `Dictionary.PlayerStatusSubReasons`

**Key Characteristics**:
- 80 values (0-79)
- ID 0 = None (no sub-reason)
- Major groupings: Fraud (1-5), Verification (7, 24-26, 61), Screening/WCH (13-16, 31-34), Chargebacks (35-45), AML (17-21, 73-74), Account types (26-29, 54-58), Tax/Compliance (66-68, 76)
- CHBK suffix denotes chargeback-specific sub-reasons
- Screening sub-reasons aligned with world-check/sanctions screening outcomes

**Used By**: *(to be populated)*

---

## Provider Type {#provider-type}

**Definition**: Classification of Electronic Verification (EV) providers by their verification method. Distinguishes between data-matching and document-scanning approaches.

**Source Table**: `Dictionary.ProviderType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | ElectronicVerification | Verifies identity by matching user data against authoritative databases |
| 1 | DocumentsVerification | Verifies identity by scanning and analyzing uploaded documents/selfies |

**Used By**: *(to be populated)*

---

## Region By IP {#region-by-ip}

**Definition**: Geographic regions (states/provinces) mapped from IP address lookups, linked to countries. Used for sub-country geo-targeting and regulatory routing. Contains 4,206 regions.

**Source Table**: `Dictionary.RegionByIP`

**Key Characteristics**:
- 4,206 rows with IDENTITY PK
- Each region belongs to one Country (implicit FK to Dictionary.Country)
- Used by CountryIP for IP-to-region resolution
- Separate from Dictionary.State (which is for user-entered address states)

**Used By**: *(to be populated)*

---

## Region By IP ISO Code {#region-by-ip-iso-code}

**Definition**: ISO code mappings for IP-derived regions. Links RegionByIP entries to standardized ISO 3166-2 region codes. Contains 179 mappings.

**Source Table**: `Dictionary.RegionByIP_ISOCode`

**Key Characteristics**:
- 179 rows - not all RegionByIP entries have ISO codes
- References RegionByIP (RegionByIP_ID) and Country (CountryID)
- Used for standardized regulatory region identification

**Used By**: *(to be populated)*

---

## Regulation {#regulation}

**Definition**: Financial regulatory jurisdictions under which eToro operates. Determines the legal framework, product availability, leverage limits, and compliance requirements for each user.

**Source Table**: `Dictionary.Regulation`

**Values**:

| ID | Name | Jurisdiction | US? | Business Meaning |
|----|------|-------------|-----|-----------------|
| 0 | None | - | No | No regulation assigned |
| 1 | CySEC | eToro EU | No | Cyprus Securities Exchange Commission - EU regulation |
| 2 | FCA | eToro UK | No | Financial Conduct Authority - UK regulation |
| 3 | NFA | - | No | National Futures Association (legacy/unused) |
| 4 | ASIC | eToro AUS | No | Australian Securities and Investments Commission |
| 5 | BVI | - | No | British Virgin Islands (legacy) |
| 6 | eToroUS | - | Yes | eToro USA entity (legacy) |
| 7 | FinCEN | - | Yes | Financial Crimes Enforcement Network - US MSB |
| 8 | FinCEN+FINRA | - | Yes | US broker-dealer regulation (FINRA + FinCEN) |
| 9 | FSA Seychelles | - | No | Financial Services Authority Seychelles |
| 10 | ASIC & GAML | eToro AUS | No | ASIC with additional AML requirements |
| 11 | FSRA | - | No | Financial Services Regulatory Authority (Abu Dhabi) |

**Key Characteristics**:
- BankID links to payment processing configuration
- IsUSA flag enables US-specific compliance workflows
- Active jurisdictions: CySEC (EU), FCA (UK), ASIC (AUS), FinCEN/FINRA (US), FSA Seychelles, FSRA (Abu Dhabi)

**Used By**: *(to be populated)*

---

## Seychelles Categorization {#seychelles-categorization}

**Definition**: Client categorization under FSA Seychelles regulation. Similar to MiFID but specific to the Seychelles jurisdiction.

**Source Table**: `Dictionary.SeychellesCategorization`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Basic | Basic client categorization - standard access |
| 1 | Pending | Categorization assessment in progress |
| 2 | Advanced | Advanced categorization - broader product/leverage access |
| 3 | NotInFlow | User not subject to Seychelles categorization flow |

**Used By**: *(to be populated)*

---

## Sign TnC Reason {#sign-tnc-reason}

**Definition**: Reason or method by which a user signed (accepted) the Terms and Conditions. Tracks the consent mechanism for compliance audit trails.

**Source Table**: `Dictionary.SignTncReason`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | By User | User explicitly accepted TnC through the UI |
| 1 | DeepLink | TnC accepted via deep link (e.g., mobile app redirect) |
| 2 | Negative Consent | TnC accepted through negative consent (deemed accepted if not rejected within timeframe) |

**Used By**: *(to be populated)*

---

## Special Character {#special-character}

**Definition**: Character transliteration/normalization map for converting accented and special characters to their ASCII equivalents. Used in name standardization for identity verification and matching. Contains 136 character mappings.

**Source Table**: `Dictionary.SpecialChar`

**Key Characteristics**:
- 136 rows mapping Unicode characters to ASCII equivalents
- Covers Latin extended characters: accented vowels, cedilla, tilde, umlauts, etc.
- Languages covered: French, German, Spanish, Portuguese, Turkish, Polish, Czech, Romanian, Scandinavian, and more
- Used in EV (Electronic Verification) to normalize names before matching against data sources

**Used By**: *(to be populated)*

---

## State {#state}

**Definition**: States/provinces linked to countries for user address data. Used in registration forms and address verification. Contains 68 states.

**Source Table**: `Dictionary.State`

**Key Characteristics**:
- 68 rows
- FK to Dictionary.Country via CountryID
- Each state has a 2-character Code and full Name
- Separate from RegionByIP (which is IP-derived geographic data)

**Used By**: *(to be populated)*

---

## Strategies {#strategies}

**Definition**: Investment strategy classifications for Popular Investor (PI) profiles. PIs declare their trading strategy so copiers can make informed decisions.

**Source Table**: `Dictionary.Strategies`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | none | No strategy declared |
| 1 | value | Value investing - buying undervalued assets |
| 2 | growth | Growth investing - targeting high-growth companies |
| 3 | income | Income investing - focus on dividend/yield-generating assets |
| 4 | longShort | Long/short strategy - both buy and sell positions |
| 5 | multiStrategy | Combines multiple investment approaches |
| 6 | momentum | Momentum trading - following price trends |
| 7 | macro | Macro investing - based on economic/geopolitical trends |
| 8 | marketNeutral | Market neutral - hedged positions targeting zero market exposure |
| 9 | eventDriven | Event driven - trading around corporate events, earnings, etc. |
| 10 | diversifiedEtf | Diversified ETF - primarily ETF-based portfolio |
| 11 | quant | Quantitative - algorithm/data-driven trading |

**Used By**: *(to be populated)*

---

## Sub Region {#sub-region}

**Definition**: Sub-divisions within IP-derived regions, providing more granular geographic targeting. Links to both Country and RegionByIP. Contains 107 sub-regions.

**Source Table**: `Dictionary.SubRegion`

**Key Characteristics**:
- 107 rows with IDENTITY PK
- FK to Dictionary.Country and Dictionary.RegionByIP
- Has ShortName and full Name fields
- Used for granular geo-targeting below the region level

**Used By**: *(to be populated)*

---

## Sync Entity Types {#sync-entity-types}

**Definition**: Types of user data entities that can be synchronized between systems (e.g., between UserApiDB and other services). Defines the sync granularity.

**Source Table**: `Dictionary.SyncEntityTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | BasicInfo | Core user data: name, DOB, gender |
| 2 | ContactInfo | Contact data: email, phone, address |
| 3 | AccountInfo | Account configuration: regulation, label, status |
| 4 | RiskInfo | Risk profile data: KYC answers, experience levels |
| 5 | User settings | User preferences and UI settings |

**Used By**: *(to be populated)*

---

## Sync Status {#sync-status}

**Definition**: Status of a data synchronization operation between systems.

**Source Table**: `Dictionary.SyncStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Pending | Sync operation queued but not yet executed |
| 2 | Done | Sync operation completed successfully |

**Used By**: *(to be populated)*

---

## Tangany Status {#tangany-status}

**Definition**: Status of a user's Tangany crypto custody wallet. Tangany is a third-party custodial wallet provider used for crypto asset storage under MiCA (Markets in Crypto-Assets) regulation.

**Source Table**: `Dictionary.TanganyStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Pending | Wallet creation requested, awaiting provisioning |
| 2 | Internal | Wallet provisioned in internal/test mode |
| 3 | Customer | Active customer wallet - standard operational state |
| 4 | Inactive | Wallet deactivated |
| 5 | MicaCustomer | Wallet operating under MiCA regulation compliance |
| 6 | ConsentCustomer | Wallet active with explicit user consent recorded |

**Used By**: *(to be populated)*

---

## Tax ID Requirement Type {#tax-id-requirement-type}

**Definition**: Defines whether a tax identification number is required for a given regulation/country combination during KYC.

**Source Table**: `Dictionary.TaxIdRequirmentType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Required | Tax ID must be provided for account activation |
| 2 | Not Required | Tax ID collection is not needed for this jurisdiction |
| 3 | NoTaxRequired | Jurisdiction has no tax ID system or tax ID is exempt |

**Used By**: KYC.CountryTaxType (TaxIdRequirmentTypeId)

---

## Trade Level {#trade-level}

**Definition**: User access level for the trading platform interface. Controls which version of the trading platform UI the user sees.

**Source Table**: `Dictionary.TradeLevel`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Normal | Standard eToro web/mobile trading platform |
| 1 | eToro Pro | Professional-grade trading interface with advanced tools |
| 2 | eToro Visual | Visual/simplified trading interface |
| 3 | Pro Only | Restricted to Pro interface only |
| 4 | Visual Only | Restricted to Visual interface only |

**Used By**: *(to be populated)*

---

## Verification Level {#verification-level}

**Definition**: Progressive levels of user identity verification completion. Higher levels unlock more platform features and higher transaction limits.

**Source Table**: `Dictionary.VerificationLevel`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Level 0 | Unverified - basic registration only, minimal access |
| 1 | Level 1 | Basic verification - email confirmed, limited trading |
| 2 | Level 2 | Standard verification - ID verified, full trading access |
| 3 | Level 3 | Enhanced verification - additional documents verified, highest limits |

**Used By**: *(to be populated)*

---

## Verification Status {#verification-status}

**Definition**: How a user's identity verification was completed - whether by manual agent review or by automated system.

**Source Table**: `Dictionary.VerificationStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No verification performed |
| 1 | Manual | Identity verified through manual review by compliance agent |
| 2 | System | Identity verified automatically by the electronic verification system |

**Used By**: *(to be populated)*

---

## Business Concepts

*(No concept-based terms yet - to be enriched from object documentation)*
