# Business Glossary - FiatDwhDB

> Canonical definitions for business terms, value domains, and concepts.
> Object docs reference this glossary for shared terminology.
> Terms are progressively enriched as more objects are documented.

*Last updated: 2026-04-14 | Terms: 19 lookup-backed, 1 concept-based | Sources: 19 Dictionary tables, 1 dbo lookup table*

---

## Lookup-Backed Terms

## Account Program {#account-program}

**Definition**: Classifies the type of fiat account a customer holds. Determines whether the account is card-based (physical/virtual card issuing) or IBAN-based (bank account with IBAN for payments/transfers). Each account program maps to a set of SubPrograms that define regional and tier variations.

**Source Table**: `Dictionary.AccountPrograms`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unknown | Default/unassigned state before account type is determined |
| 1 | card | Account supports card issuance (debit cards, virtual cards) for point-of-sale and ATM transactions |
| 2 | iban | Account supports IBAN-based banking (SEPA transfers, Faster Payments, direct debits) |

**Key Characteristics**:
- Each SubProgram belongs to exactly one AccountProgram
- Default value for new accounts is 1 (card)

**Used By**: dbo.FiatAccount, dbo.FiatAccountsProperties, dbo.SubPrograms

---

## Account Status {#account-status}

**Definition**: Lifecycle state of a fiat account. Controls whether the account holder can perform transactions, receive funds, or if the account has been permanently removed.

**Source Table**: `Dictionary.AccountStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Active | Account is fully operational - holder can send, receive, and transact |
| 1 | Suspended | Account is temporarily frozen - no transactions allowed, pending review or customer action |
| 2 | Deleted | Account has been permanently closed and removed from active service |

**Key Characteristics**:
- Status changes are tracked in dbo.FiatAccountStatuses with timestamps
- Suspension can be triggered by risk actions, compliance reviews, or customer requests

**Used By**: dbo.FiatAccountStatuses

---

## Authorization Type {#authorization-type}

**Definition**: Classification of how a card transaction was authorized by the payment network. Determines the authorization flow, hold behavior, and settlement rules for each transaction event.

**Source Table**: `Dictionary.AuthorizationTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unknown | Authorization type could not be determined from provider data |
| 1 | Normal | Standard single-use authorization for a card purchase or payment |
| 2 | PreAuthorize | Initial hold placed before final amount is known (e.g., hotel check-in, car rental) |
| 3 | FinalAuthorize | Completion of a pre-authorized transaction with the final settled amount |
| 4 | Incremental | Additional authorization added to an existing pre-auth (e.g., extended hotel stay) |
| 5 | Instalment | Transaction split into multiple payment installments |
| 6 | PreferredCustomer | Authorization for a trusted/preferred merchant with special processing rules |
| 7 | Recurring | Subscription or recurring payment authorization (e.g., monthly streaming service) |
| 8 | DelayedCharges | Charges added after initial authorization (e.g., minibar charges at hotel checkout) |
| 9 | NoShow | Charge applied when customer fails to honor a reservation |
| 10 | AuthorizeAdvice | Advisory message from payment network confirming an authorization decision |
| 11 | Refund | Merchant-initiated return of funds to the cardholder |
| 12 | Reversal | Cancellation of a previous authorization before settlement |
| 13 | SysReversal | System-initiated reversal due to timeout or processing error |
| 14 | AccountFunding | Transaction that loads funds onto the card account |

**Key Characteristics**:
- Pre-auth flow: PreAuthorize -> (optional Incremental) -> FinalAuthorize
- Reversals release held funds back to available balance

**Used By**: dbo.FiatTransactionsStatuses

---

## Card Status {#card-status}

**Definition**: Lifecycle state of a physical or virtual payment card. Controls whether the card can be used for transactions and the reason for any restriction.

**Source Table**: `Dictionary.CardStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | NotActivated | Card has been issued but not yet activated by the cardholder |
| 1 | Activated | Card is active and can be used for transactions |
| 2 | Blocked | Card is temporarily blocked by the cardholder or system (reversible) |
| 3 | Suspended | Card is suspended pending investigation or review |
| 4 | Risk | Card flagged by risk engine due to suspicious activity patterns |
| 5 | Stolen | Card reported stolen - permanently disabled, replacement may be issued |
| 6 | Lost | Card reported lost - permanently disabled, replacement may be issued |
| 7 | Expired | Card has passed its expiration date |
| 8 | Fraud | Card confirmed involved in fraudulent activity - permanently disabled |

**Key Characteristics**:
- Status changes tracked in dbo.FiatCardStatuses with EventTimestamp
- Risk actions from transaction processing can automatically change card status
- Terminal states: Stolen, Lost, Expired, Fraud (card cannot be reactivated)

**Used By**: dbo.FiatCardStatuses

---

## Currency Balance Status {#currency-balance-status}

**Definition**: Operational state of a specific currency balance within an account. Controls what types of money movement are permitted for that balance.

**Source Table**: `Dictionary.CurrencyBalanceStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Active | Balance is fully operational - can send and receive funds |
| 1 | ReceiveOnly | Balance can only receive incoming funds - outgoing transactions blocked |
| 2 | SpendOnly | Balance can only be spent down - no new incoming funds accepted |
| 3 | Suspended | Balance is frozen - no inbound or outbound transactions permitted |
| 4 | Blocked | Balance is blocked, typically due to compliance or legal hold |

**Key Characteristics**:
- Status changes tracked in dbo.FiatCurrencyBalancesStatuses with source and reason
- ReceiveOnly and SpendOnly are partial restriction states used during account wind-down

**Used By**: dbo.FiatCurrencyBalancesStatuses

---

## ISO Currency Info {#iso-currency-info}

**Definition**: Reference data for ISO 4217 currency codes used across the fiat platform. Contains the alphabetical code, numeric code, and minor unit (decimal places) for each currency.

**Source Table**: `Dictionary.IsoCurrencyInfo`

**Values**: 155 currencies (ISO 4217 standard). Key currencies used in the platform:

| Code | Numeric | MinorUnit | Notes |
|------|---------|-----------|-------|
| GBP | 826 | 2 | UK region primary currency |
| EUR | 978 | 2 | EU region primary currency |
| USD | 840 | 2 | Base currency for USD conversion rates |
| AUD | 036 | 2 | Australia region currency |
| DKK | 208 | 2 | Denmark region currency |
| AED | 784 | 2 | UAE region currency |
| ILS | 376 | 2 | Israel (eToro HQ) currency |
| JPY | 392 | 0 | Zero minor units (no decimal places) |
| BHD | 048 | 3 | Three minor units example |

**Key Characteristics**:
- MinorUnit determines decimal precision for amount storage and display
- Zero minor unit currencies (JPY, KRW, etc.) have no fractional amounts
- CurrencyISON columns in dbo tables reference AlphabeticalCode values

**Used By**: dbo.FiatCurrencyBalances, dbo.BalanceReports, dbo.FiatTransactionsStatuses

---

## Payment Schema Type {#payment-schema-type}

**Definition**: The payment network or scheme through which a banking transaction is processed. Determines routing, settlement speed, and applicable regulations.

**Source Table**: `Dictionary.PaymentSchemaType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unknown | Payment scheme not identified or not applicable |
| 1 | Transfer | Internal transfer between accounts within the platform |
| 2 | FasterPayments | UK Faster Payments Service - near-instant GBP transfers |
| 3 | Chaps | UK CHAPS - same-day high-value GBP settlement |
| 4 | Bacs | UK Bacs - batch processing for direct debits and credits (2-3 day settlement) |
| 5 | SEPAstandart | SEPA Credit Transfer - standard EUR transfers across EU (1 business day) |
| 6 | SEPAinstantTransfer | SEPA Instant Credit Transfer - near-instant EUR transfers |
| 7 | SEPAdirectDebit | SEPA Direct Debit - EUR direct debit collections |

**Key Characteristics**:
- UK payments: FasterPayments (instant), Chaps (same-day, high-value), Bacs (batch)
- EU payments: SEPA standard, instant, and direct debit
- Scheme determines settlement timing and fee structure

**Used By**: dbo.FiatTransactions

---

## Payment Specification Status Type {#payment-specification-status-type}

**Definition**: Lifecycle state of a payment specification (e.g., a direct debit mandate). Tracks the specification from creation through activation to potential cancellation.

**Source Table**: `Dictionary.PaymentSpecificationStatusTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | New | Specification has been created but not yet activated with the provider |
| 1 | Active | Specification is live and can trigger payment collections |
| 2 | Cancelled | Specification has been fully cancelled and will not collect further payments |
| 3 | CancelledPending | Cancellation has been requested but not yet confirmed by the provider |
| 4 | Error | Specification encountered an error during setup or processing |

**Key Characteristics**:
- Status transitions tracked in dbo.PaymentSpecificationStatuses
- CancelledPending is a transitional state awaiting provider confirmation

**Used By**: dbo.PaymentSpecificationStatuses

---

## Payment Specification Type {#payment-specification-type}

**Definition**: The type of recurring or automated payment instruction set up on a currency balance.

**Source Table**: `Dictionary.PaymentSpecificationTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unknown | Type not determined |
| 1 | DirectDebit | Recurring direct debit mandate allowing third parties to collect payments |

**Key Characteristics**:
- Currently only DirectDebit is supported as a payment specification type

**Used By**: dbo.PaymentSpecifications

---

## Program Transition Eligibility Source {#program-transition-eligibility-source}

**Definition**: Identifies how a program transition eligibility record was created - whether automatically via the UserAPI integration or manually by an operator.

**Source Table**: `Dictionary.ProgramTransitionEligibilitySources`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unknown | Source of the eligibility record is not determined |
| 1 | UserAPI | Eligibility determined automatically based on UserAPI customer data |
| 2 | Manual | Eligibility set manually by an internal operator or support team |

**Key Characteristics**:
- Most transitions are expected to be UserAPI-driven (automated)
- Manual source is used for exceptions and overrides

**Used By**: dbo.ProgramTransitionsEligibility

---

## Program Transition Eligibility Status {#program-transition-eligibility-status}

**Definition**: State of a customer's eligibility to transition between sub-programs (e.g., from Standard to Premium or from Card to IBAN).

**Source Table**: `Dictionary.ProgramTransitionEligibilityStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Pending | Eligibility assessment is in progress, awaiting evaluation |
| 1 | Completed | Transition has been successfully completed |
| 2 | Rejected | Customer does not meet eligibility criteria for the transition |
| 3 | Disabled | Transition path has been administratively disabled |
| 4 | Expired | Eligibility window has passed without the transition being executed |

**Key Characteristics**:
- Status tracked in dbo.ProgramTransitionsEligibilityStatuses
- Expired status prevents stale eligibility records from being actioned

**Used By**: dbo.ProgramTransitionsEligibilityStatuses

---

## Provider {#provider}

**Definition**: External financial services provider that handles card issuing, payment processing, and account management on behalf of the platform.

**Source Table**: `Dictionary.Providers`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Tribe | Tribe Payments - the card issuing and payment processing provider |

**Key Characteristics**:
- Currently single-provider model (Tribe only)
- Provider mapping tables link internal IDs to provider-side IDs for cards, currency balances, transactions, and payment specifications

**Used By**: dbo.CardsProvidersMapping, dbo.CurrencyBalancesProvidersMapping, dbo.TransactionsProvidersMapping, dbo.PaymentSpecificationsProvidersMapping

---

## Status Change Reason {#status-change-reason}

**Definition**: The business reason that triggered a status change on a currency balance. Provides audit trail context for compliance and support investigations.

**Source Table**: `Dictionary.StatusChangeReasons`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unknown | Reason not recorded or not applicable |
| 1 | PositiveReview | Compliance/risk review cleared the account - restriction removed |
| 2 | NegativeReview | Compliance/risk review found issues - restriction applied |
| 3 | CustomerRequest | Customer explicitly requested the status change |
| 4 | SuspectedFraud | Fraud detection flagged suspicious activity |
| 5 | DeathOfAnAccountHolder | Account holder reported deceased |
| 6 | CompromisedAccount | Account credentials or security have been compromised |
| 7 | CompromisedCard | Card details have been compromised (skimming, data breach) |
| 8 | Investigation | Status changed as part of an ongoing internal investigation |
| 9 | IndemnityReceived | Indemnity received from another institution or party |
| 10 | ThirdPartyNotification | External party (bank, regulator) notified of an issue |
| 11 | PoliceRequest | Law enforcement requested account restriction |
| 12 | InternalBlockRequest | Internal team requested a block (operations, compliance) |
| 13 | SuspectedIdentityTheft | Identity theft indicators detected |
| 14 | ChargeBackFraud | Fraudulent chargeback activity detected |
| 15 | InternalInvestigations | Ongoing internal investigations team review |
| 16 | LostOrStolenCards | Cards reported lost or stolen |
| 17 | SuspiciousPayments | Payment patterns flagged as suspicious |
| 18 | SuspectedMoneyLaunderingConcerns | AML flags raised on the account |
| 19 | UnknownSourceOfFunds | Source of deposited funds cannot be verified |

**Key Characteristics**:
- Used exclusively for currency balance status changes
- Reasons 4-19 are compliance/risk/fraud related and may trigger regulatory reporting

**Used By**: dbo.FiatCurrencyBalancesStatuses

---

## Status Change Source {#status-change-source}

**Definition**: Identifies which system or actor initiated a currency balance status change. Provides audit trail for who/what triggered the change.

**Source Table**: `Dictionary.StatusChangeSources`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unknown | Source not recorded |
| 1 | ProgramManager | Status changed by the program management team (eToro internal) |
| 2 | ProviderBO | Status changed via provider back-office (Tribe operations) |
| 3 | ProviderSystem | Automated status change by the provider's systems |
| 4 | ExternalProvider | Status change originated from an external third-party provider |

**Key Characteristics**:
- Distinguishes internal (ProgramManager) from provider-side (ProviderBO, ProviderSystem) changes
- Important for incident root cause analysis

**Used By**: dbo.FiatCurrencyBalancesStatuses

---

## Transaction Category {#transaction-category}

**Definition**: High-level classification of a financial transaction by its channel or nature. Groups individual transaction types into broader categories for reporting and processing rules.

**Source Table**: `Dictionary.TransactionCategories`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unknown | Category not determined |
| 1 | CardTransaction | Transaction initiated via physical or virtual card (POS, ATM, online) |
| 2 | BankingTransaction | Transaction via banking rails (Faster Payments, SEPA, CHAPS, Bacs) |
| 3 | TransferTransaction | Internal platform transfer between accounts or currency balances |
| 4 | BalanceAdjustmentTransaction | Manual or system adjustment to correct a balance (credits/debits) |

**Key Characteristics**:
- Category determines which payment scheme and processing rules apply
- CardTransactions use card network authorization; BankingTransactions use bank payment schemes

**Used By**: dbo.FiatTransactions

---

## Transaction Status {#transaction-status}

**Definition**: Lifecycle state of a financial transaction from initiation through final settlement or failure.

**Source Table**: `Dictionary.TransactionStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Failed | Transaction processing failed - no funds moved |
| 1 | Authorized | Transaction has been authorized but not yet settled (funds held) |
| 2 | Settled | Transaction has been fully settled - funds have moved |
| 3 | Rejected | Transaction was rejected by the system or provider before processing |
| 4 | Returned | Previously settled transaction was returned (e.g., failed direct debit) |
| 5 | Expired | Authorization expired before settlement occurred |
| 6 | Reserved | Funds reserved/held pending transaction completion |
| 7 | Cancelled | Transaction was cancelled before settlement |

**Key Characteristics**:
- Normal flow: Authorized -> Settled
- Pre-auth flow: Reserved -> Authorized -> Settled
- Terminal states: Failed, Rejected, Returned, Expired, Cancelled

**Used By**: dbo.FiatTransactionsStatuses

---

## Transaction Type {#transaction-type}

**Definition**: Specific type of financial transaction, providing granular classification of money movement within the fiat platform.

**Source Table**: `Dictionary.TransactionTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unknown | Transaction type not determined |
| 1 | CardPayment | In-person card payment at a merchant terminal |
| 2 | Contactless | Contactless tap-to-pay card transaction |
| 3 | OnlinePayment | Card-not-present online/e-commerce payment |
| 4 | CashWithdrawal | ATM cash withdrawal using the card |
| 5 | TransferReceived | Incoming bank transfer received into the account |
| 6 | Transfer | Outgoing bank transfer sent from the account |
| 7 | PaymentReceived | Incoming payment received (non-transfer, e.g., refund from merchant) |
| 8 | Payment | Outgoing payment sent |
| 9 | Refund | Refund credited back to the account |
| 10 | Fee | Platform or provider fee charged to the account |
| 11 | CreditBA | Credit balance adjustment (positive correction) |
| 12 | DebitBA | Debit balance adjustment (negative correction) |
| 13 | DirectDebit | Direct debit collection from the account |
| 14 | CryptoToFiat | Conversion of cryptocurrency to fiat currency |

**Key Characteristics**:
- Card-based types (1-4): Processed through card networks
- Banking types (5-8): Processed through payment schemes (SEPA, Faster Payments, etc.)
- Adjustment types (11-12): Used for manual or system corrections
- CryptoToFiat (14): Cross-asset conversion from crypto wallet to fiat balance

**Used By**: dbo.FiatTransactions

---

## Transition Type {#transition-type}

**Definition**: How a program transition rule is triggered - automatically by the system or manually by an operator.

**Source Table**: `Dictionary.TransitionTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unknown | Transition trigger not determined |
| 1 | Automatic | Transition is triggered automatically when eligibility criteria are met |
| 2 | Manual | Transition requires manual initiation by an operator |

**Key Characteristics**:
- Used in ProgramTransitionRules to define how each transition path operates

**Used By**: dbo.ProgramTransitionRules

---

## Tribe Script Status {#tribe-script-status}

**Definition**: Approval workflow state for scripts executed against the Tribe provider system. Controls whether a script can be run in the provider environment.

**Source Table**: `Dictionary.TribeScriptStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unapproved | Script has been submitted but not yet reviewed/approved |
| 1 | Approved | Script has been reviewed and approved for execution |
| 2 | Executed | Script has been successfully executed in the provider environment |

**Key Characteristics**:
- Three-step workflow: submission -> approval -> execution
- Used by the Tribe schema operations (Monitoring/Tribe schemas)

**Used By**:

---

## Business Concepts

## Sub-Program {#sub-program}

**Definition**: A regional and tier-specific variant of an Account Program. Each sub-program defines the exact product offering (e.g., "Card Premium UK", "IBAN Green EU") that determines the customer's available features, limits, and pricing.

**Source Table**: `dbo.SubPrograms`

**Values**:

| ID | Name | AccountProgram | CugProgramName | Region |
|----|------|---------------|----------------|--------|
| 1 | Card Premium UK | card (1) | Card_Premium_UK | UK |
| 2 | Card Standard UK | card (1) | Card_Standard_UK | UK |
| 3 | IBAN Premium UK | iban (2) | IBAN_Premium_UK | UK |
| 4 | IBAN Standard UK | iban (2) | IBAN_Standard_UK | UK |
| 5 | IBAN Standard EU Test | iban (2) | IBAN_Standard_EU_Test | EU |
| 6 | IBAN EU Green | iban (2) | IBAN_EU_Green | EU |
| 7 | IBAN EU Black | iban (2) | IBAN_EU_Black | EU |
| 8 | IBAN LIMITED UK | iban (2) | IBAN_LIMITED_UK | UK |
| 9 | IBAN LIMITED EU | iban (2) | IBAN_LIMITED_EU | EU |
| 10 | Card Premium UAE | card (1) | Card_Premium_UAE | UAE |
| 11 | Card Green EU | card (1) | Card_Green_EU | EU |
| 12 | Card Black EU | card (1) | Card_Black_EU | EU |
| 13 | IBAN Green AUS | iban (2) | IBAN_Green_AUS | AUS |
| 14 | IBAN Black AUS | iban (2) | IBAN_Black_AUS | AUS |
| 15 | IBAN Green DKK | iban (2) | IBAN_Green_DKK | DK |
| 16 | IBAN Black DKK | iban (2) | IBAN_Black_DKK | DK |

**Key Characteristics**:
- Tier hierarchy: LIMITED < Standard/Green < Premium/Black
- Regions: UK, EU, UAE, AUS, DK
- CugProgramName is the identifier used in the CUG (Closed User Group) provider system
- Program transitions move customers between sub-programs (e.g., Standard -> Premium upgrade)

**Used By**: dbo.FiatAccount, dbo.FiatAccountsProperties, dbo.EligibilityRules, dbo.ProgramTransitionRules, dbo.ProgramTransitionsEligibility
