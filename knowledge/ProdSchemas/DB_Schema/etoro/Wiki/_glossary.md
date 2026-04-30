# Business Glossary — etoro

> Canonical definitions for business terms, value domains, and concepts.
> Object docs reference this glossary for shared terminology.
> Terms are progressively enriched as more objects are documented.

*Last updated: 2026-03-21 | Terms: 36 lookup-backed, 7 concept-based | Sources: 36 Dictionary tables, 12 Compliance SP docs + 253 Customer objects + 1,422 Trade objects + 502 BackOffice objects + 771 Billing objects + 230 Hedge objects + 484 History objects | Enriched: 2026-03-21 (History schema Phase 12 - 3 new concepts: Stock Split, Introducing Broker, Crypto Airdrop)*

---

## Lookup-Backed Terms

## Account Status {#account-status}

**Definition**: The open/closed state of an eToro trading account. Determines whether the account can participate in platform activities.

**Source Table**: `Dictionary.AccountStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Open | Account is active and can trade, deposit, withdraw, and use all platform features |
| 2 | Closed | Account has been closed — all positions liquidated, no further activity permitted |

**Key Characteristics**:
- Binary state: accounts are either fully operational or fully closed
- Closing an account triggers position liquidation and fund withdrawal flows

**Used By**:
- [Customer.CustomerStatic](Customer/Tables/Customer.CustomerStatic.md) - AccountStatusID column (tinyint, DEFAULT=1); 93.9% of 18.7M accounts = 1 (Active), 0.5% = 2 (Closed), 5.6% NULL (pre-AccountStatusID era); indexed via Idx_Customer_Customer_AccountStatusID

---

## Account Type {#account-type}

**Definition**: Classification of an eToro account by its ownership and purpose. Controls which features, regulations, and fee structures apply.

**Source Table**: `Dictionary.AccountType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Private | Standard retail individual account — the default for most users |
| 2 | Corporate | Business entity account with separate KYC requirements and regulatory treatment |
| 3 | IB Account | Introducing Broker account for partners who refer clients |
| 4 | Joint Account | Shared account owned by two individuals |
| 5 | White Label | Platform-branded account operated by a third-party partner |
| 6 | Affiliate Private Account | Individual account with affiliate program participation |
| 7 | Employee Account | Internal eToro employee account with special monitoring |
| 8 | Custodian | Account held by a custodian on behalf of beneficial owners |
| 9 | Fund | Managed fund account for collective investment |
| 10 | eToro Group Account | Internal eToro corporate/operational account |
| 11 | News | System account used for news-related content publishing |
| 12 | White List | Privileged account with reduced restrictions |
| 13 | Analyst | Account used by eToro market analysts for publishing insights |
| 14 | SMSF | Self-Managed Super Fund (Australian retirement vehicle) |
| 15 | Affiliate Corporate Account | Corporate entity with affiliate program participation |
| 16 | Administrated Account | Account managed by an administrator (e.g., estate or court-ordered) |
| 17 | Funded Employee Account | Employee account seeded with company-provided trading funds |

**Key Characteristics**:
- Determines regulatory treatment and available instrument types
- IB, Affiliate, and White Label types drive revenue-sharing calculations
- Employee and Group accounts have enhanced compliance monitoring

**Used By**:
- [Compliance.GetPOADocumentsExpirationPopulationFor3Years](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationFor3Years.md) - AccountTypeID NOT IN (2, 4) excludes Corporate and Joint Account types from POA expiry notification population
- [Compliance.GetPOIDocumentsExpirationPopulation](Compliance/Stored%20Procedures/Compliance.GetPOIDocumentsExpirationPopulation.md) - AccountTypeID NOT IN (2, 4) excludes Corporate and Joint Account types from POI expiry population
- [Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325.md) - DEPRECATED, same AccountTypeID exclusion
- [Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325.md) - DEPRECATED, same AccountTypeID exclusion
- [Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325.md) - DEPRECATED, same AccountTypeID exclusion
- [BackOffice.Customer](BackOffice/Tables/BackOffice.Customer.md) - AccountTypeID (tinyint, NOT NULL DEFAULT=1): distribution: 1(Private)=18.614M(99.3%), 0=44K, 2(Corporate)=37K, 6(Affiliate Private)=17K, others <6K. Filtered NC index on AccountTypeID=9 (Fund) for frequent queries. One of the core classification fields in the BackOffice governance layer.

---

## Cashout Status {#cashout-status}

**Definition**: Lifecycle state of a withdrawal (cashout) request. Tracks the request from submission through processing to completion or rejection.

**Source Table**: `Dictionary.CashoutStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Pending | Withdrawal submitted, awaiting initial processing |
| 2 | InProcess | Actively being processed by the system |
| 3 | Processed | Successfully sent to the payment provider — money has left eToro |
| 4 | Canceled | Canceled before money was transferred (by user or system) |
| 5 | Partially Processed | Only a portion of the requested amount was successfully sent |
| 6 | Payment Sent | Payment instruction sent to provider, awaiting confirmation |
| 7 | Rejected | Denied by compliance, fraud, or business rules — no money moved |
| 8 | RejectedByProvider | Payment provider refused the transaction |
| 9 | PendingByProvider | Provider acknowledged but has not yet settled |
| 10 | SentToProvider | Instruction transmitted to external provider |
| 11 | SentToBilling | Forwarded to billing system for execution |
| 12 | ReceivedByBilling | Billing system acknowledged receipt |
| 13 | Failed | Technical or business failure during processing |
| 14 | Pending Review | Flagged for manual compliance/fraud review before processing |
| 15 | Under Review | Currently being examined by compliance team |
| 16 | Reversed | Previously processed withdrawal was reversed (money returned to account) |
| 17 | Partialy Reversed | Partial amount of a processed withdrawal was reversed |

**Key Characteristics**:
- IsFinalStatus flag distinguishes terminal states (3,4,5,7,8,13) from intermediate ones
- IsFinishedWithoutMoneyTransfer flag identifies rejections/cancellations where no funds moved
- Reversed states (16,17) indicate money returned after initial processing

**Used By**:

---

## Client Withdraw Comment {#client-withdraw-comment}

**Definition**: A customer-selectable pre-defined comment attached to a withdrawal request. Used to flag specific issues or actions needed (e.g., invalid payment method, bank details update) that operations staff must action. Shown in back-office withdrawal views.

**Source Table**: `Dictionary.ClientWithdrawComment`

**Values**:

| ID | Comment | Business Meaning |
|----|---------|-----------------|
| 0 | (none) | No comment - standard withdrawal with no special action required |
| 1 | Report Non Valid Mean Of Payment Used In The Account | Customer is flagging that the payment instrument on file is invalid or should be removed; triggers ops review |
| 2 | Update Intermediary Bank Details | Bank wire requires updated intermediary (correspondent) bank routing details before payment can proceed |
| 3 | Other | Free-form comment - customer has a different concern not covered by the other options |

**Key Characteristics**:
- IsActive flag allows retiring specific comments without deleting them
- DisplayOrder controls the order shown in the withdrawal UI (0 is shown last as "no comment" default)
- Stored in `Billing.Withdraw.ClientWithdrawCommentID` and surfaced in BackOffice withdrawal views

**Used By**:
- [Billing.Withdraw](Billing/Tables/Billing.Withdraw.md) - ClientWithdrawCommentID column; stores the customer's selected comment
- [Billing.WithdrawalService_GetClientWitdrawComments](Billing/Stored Procedures/Billing.WithdrawalService_GetClientWitdrawComments.md) - Returns active comments for the withdrawal UI dropdown
- [Billing.WithdrawalService_WithdrawRequestAdd](Billing/Stored Procedures/Billing.WithdrawalService_WithdrawRequestAdd.md) - @ClientWithdrawCommentID parameter; records customer comment on new withdrawal

---

## Client Withdraw Reason {#client-withdraw-reason}

**Definition**: The customer's self-reported reason for making a withdrawal. Collected at withdrawal submission time to support retention analysis and customer lifecycle tracking. Displayed in back-office views for operations and CRM teams.

**Source Table**: `Dictionary.ClientWithdrawReason`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | None of the reasons above | Customer selected none of the offered reasons; catch-all for non-standard cases |
| 2 | Withdrawing profits | Routine profit-taking; positive intent - customer is successful on the platform |
| 3 | Fulfill other financial commitments | External financial need (mortgage, bills); not platform-related dissatisfaction |
| 4 | I Have not achieved my trading goals | Performance-based exit; customer did not meet their own targets |
| 5 | This platform is not for me | Platform fit issue - potential candidate for re-engagement or feedback collection |
| 6 | I Would like to close my account | Strong exit intent; triggers account closure workflow in conjunction with withdrawal |
| 7 | Moving to a competitor | Competitive churn signal; high-priority retention flag |

**Key Characteristics**:
- DisplayOrder controls UI ordering (2=first, presented as most expected reason; 1=last catch-all)
- Used by retention teams to identify at-risk customers and prioritize outreach
- Reason 6 (close account) typically triggers a parallel account-closure review process

**Used By**:
- [Billing.Withdraw](Billing/Tables/Billing.Withdraw.md) - ClientWithdrawReasonID column; stores the customer's selected reason
- [Billing.WithdrawalService_GetClientWitdrawReasons](Billing/Stored Procedures/Billing.WithdrawalService_GetClientWitdrawReasons.md) - Returns active reasons for the withdrawal form dropdown
- [Billing.WithdrawalService_WithdrawRequestAdd](Billing/Stored Procedures/Billing.WithdrawalService_WithdrawRequestAdd.md) - @ClientWithdrawReasonID parameter; records reason on new withdrawal

---

## Close Position Action Type {#close-position-action-type}

**Definition**: The trigger or reason for closing a trading position. Determines attribution and affects fee/PnL calculations.

**Source Table**: `Dictionary.ClosePositionActionType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Customer | User manually closed the position |
| 1 | Stop Loss | Triggered by the position's stop-loss price level |
| 2 | End of Week | Forced close at market close for instruments not allowing weekend holding |
| 3 | Stop Loss (via trade server) | Stop loss executed by the trade server engine (automated) |
| 4 | Return to Market | Closed as part of a return-to-market cycle after downtime |
| 5 | Take Profit | Triggered by the position's take-profit price level |
| 6 | Take Profit (via trade server) | Take profit executed by the trade server engine (automated) |
| 7 | Contact Rollover | Contract rollover — position closed to re-open on the next contract period |
| 8 | BackOffice User | Closed by eToro operations/back-office staff |
| 9 | Hierarchical Close | Position closed because the copied trader closed (CopyTrading chain) |
| 10 | Hierarchical close by recovery | Copy position closed during a recovery/alignment process |
| 11 | Join Demo Challenge | Closed because user joined a demo trading challenge |
| 12 | Close All | User triggered "Close All Positions" action |
| 13 | Copy Stop Loss | CopyTrading stop-loss threshold triggered for the copy relationship |
| 14 | Mirror position manual close | User manually closed a copy-trading position |
| 15 | Manual Liquidation | Operations team forced liquidation of the position |
| 16 | BSL | Below Stop Loss — system protection close when price gaps below SL |
| 17 | Manual Unregister | User unregistered from copy relationship, closing mirrored positions |
| 18 | BackOffice Unregister | Operations unregistered user from copy, closing mirrored positions |
| 19 | Redeem | Position closed as part of withdrawal (redeem) to free up cash |
| 20 | Operational position adjustment | Internal operational correction to position data |
| 21 | Orphaned position | System detected a position with no valid owner/relationship |
| 22 | Transferred Out | Position moved to another account or system (ACATS, entity transfer) |
| 23 | Alignment | Closed during copy-trading alignment to match leader's portfolio |
| 24 | Delist | Instrument was delisted from the platform |
| 25 | Close by rate | Closed when price hit a specified rate (variant of limit close) |
| 26 | Expiry | Position expired (e.g., options/futures with expiration date) |

**Key Characteristics**:
- Customer-initiated (0, 12, 14, 17) vs system-initiated (1, 3, 5, 6, 16) vs ops-initiated (8, 15, 18, 20)
- CopyTrading-specific actions: 9, 10, 13, 14, 17, 18, 23
- Critical for PnL attribution and fee calculation

**Used By**:
- [Trade.PositionTbl](Trade/Tables/Trade.PositionTbl.md) - ActionType column (tinyint): set on INSERT by PositionOpen as OpenActionType; set on UPDATE by PositionClose as CloseOccurred/ActionType
- [Trade.PositionClose](Trade/Stored%20Procedures/Trade.PositionClose.md) - @ActionType parameter: caller specifies which close reason to stamp on the position
- [Trade.PostClosePositionActions](Trade/Stored%20Procedures/Trade.PostClosePositionActions.md) - ActionType read to determine post-close routing (e.g., BSL close vs customer close vs copy close)

---

## Currency Type {#currency-type}

**Definition**: Classification of tradeable instruments into asset classes. Determines trading rules, minimum position sizes, price sources, and UI presentation.

**Source Table**: `Dictionary.CurrencyType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Forex | Foreign exchange currency pairs (e.g., EUR/USD) — the original eToro product |
| 2 | Commodity | Physical commodities (Gold, Oil, Natural Gas, etc.) |
| 3 | CFD | Generic Contract for Difference — legacy/catch-all category |
| 4 | Indices | Market indices (S&P 500, NASDAQ, FTSE, etc.) |
| 5 | Stocks | Individual company equities — supports both CFD and real ownership |
| 6 | ETF | Exchange-Traded Funds — basket instruments |
| 7 | Bonds | Government and corporate bonds |
| 8 | TrustFunds | Trust fund instruments |
| 9 | Options | Options contracts |
| 10 | Crypto | Cryptocurrencies (Bitcoin, Ethereum, etc.) |

**Key Characteristics**:
- MinPositionAmountAbsolute defines the minimum trade size in account currency
- PricesBy indicates the price feed provider (eToro internal vs Xignite)
- Priority controls display ordering in the platform UI
- SLTPApproachPercent defines how close SL/TP can be set to the current price (percentage)

**Used By**:

---

## Delayed Order Status {#delayed-order-status}

**Definition**: State of a limit/stop order (delayed execution order) in its lifecycle.

**Source Table**: `Dictionary.DelayedOrderStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | PLACED | Order is active, waiting for price to reach the trigger level |
| 2 | FILLED | Price reached the trigger — order has been executed into a position |
| 3 | REMOVED | Order was canceled by user, system, or expiration without executing |

**Key Characteristics**:
- Simple three-state lifecycle: pending → filled/removed
- FILLED transitions to a new position in the PositionTbl

**Used By**:

---

## Deposit Type {#deposit-type}

**Definition**: Classification of the nature/purpose of a deposit transaction.

**Source Table**: `Dictionary.DepositType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Regular | Standard one-time deposit initiated by the user |
| 2 | CvvFree | Deposit without CVV re-entry (stored card on file) |
| 3 | Recurring | Scheduled automatic recurring deposit |
| 4 | MoneyTransfer | Internal transfer between accounts (not a true external deposit) |
| 5 | RecurringInvestment | Automated deposit tied to a recurring investment plan |

**Key Characteristics**:
- ApplyFtd flag indicates if this deposit counts toward First Time Deposit tracking
- MoneyTransfer (4) does NOT count as FTD because no external money enters

**Used By**:

---

## Document Status {#document-status}

**Definition**: Review state of a user-uploaded verification document in the KYC process.

**Source Table**: `Dictionary.DocumentStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No document submitted for this category |
| 1 | New Upload | Document uploaded by user, awaiting compliance review |
| 2 | Reviewed | Compliance team has viewed but not yet decided |
| 3 | Accepted | Document approved — verification requirement satisfied |
| 4 | Rejected | Document did not meet requirements — user must resubmit |
| 5 | POIApproved | Proof of Identity specifically approved (partial approval) |
| 6 | POAApproved | Proof of Address specifically approved (partial approval) |

**Key Characteristics**:
- POIApproved and POAApproved allow granular tracking when a document covers only one verification type

**Used By**:
- [BackOffice.Customer](BackOffice/Tables/BackOffice.Customer.md) - DocumentStatusID (int, nullable): current state of the customer's KYC document submission and review queue. NULL if no documents submitted. Updated by BackOffice agents after reviewing documents in BackOffice.CustomerDocument.

---

## Document Type {#document-type}

**Definition**: Category of verification document a customer can upload for KYC/AML compliance.

**Source Table**: `Dictionary.DocumentType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Proof of address | Utility bill, bank statement, etc. confirming residential address |
| 2 | Proof of Identity | Government-issued ID (passport, driver's license, national ID) |
| 3 | Credit Card | Photo of payment card used for deposits |
| 4 | Authorization Form | Signed form authorizing specific account actions |
| 5 | Corporate doc | Business registration, articles of incorporation for corporate accounts |
| 6 | Not Accepted | Document that was submitted but categorized as invalid/irrelevant |
| 7 | Proof of Income | Salary slip, tax return, or bank statements proving income source |
| 8 | Proof of MOP | Proof of Method of Payment — verifying ownership of payment method |
| 9 | Client Forms | Miscellaneous forms filled by the client |
| 10 | Financial Reference Letter | Bank-issued letter confirming financial standing |
| 11 | Proof of Relation | Document proving relationship between joint account holders |
| 12 | W-8BEN Form | US tax form for non-US persons (36-month validity) |
| 13 | POI & POA | Combined document serving as both identity and address proof |
| 14 | W9 | US tax form for US persons (36-month validity) |
| 15 | Selfie | Photo of user holding their ID for liveness verification |
| 16 | TaxReport | Tax reporting document |
| 17 | VideoIdent | Video-based identity verification recording |
| 18 | SelfieLiveliness | Automated liveness check with facial movement |
| 19 | 3210 Letter | FINRA 3210 letter for employees of financial firms |
| 20 | Translation | Translated version of another document |
| 21 | Professional Customer Document | Qualification docs for professional investor categorization |
| 22 | SSN Card | US Social Security Number card |
| 23 | Selfie Motion | Motion-based selfie for anti-spoofing verification |
| 24 | VAT Invoice | Value Added Tax invoice for corporate billing |
| 25 | 1099 | US tax form 1099 for reporting income |

**Key Characteristics**:
- MaxAgeInMonths defines document freshness requirement — NULL means no expiration
- Tax forms (12, 14) have 36-month validity windows
- Types 15-18, 23 are technology-based verification methods (selfie, video, liveness)

**Used By**:
- [Compliance.GetPOADocumentsExpirationPopulationFor3Years](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationFor3Years.md) - DocumentTypeID=1 (POA), filters BackOffice.CustomerDocumentToDocumentType
- [Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325.md) - DEPRECATED, same DocumentTypeID=1 filter
- [Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325.md) - DEPRECATED, same DocumentTypeID=1 filter
- [Compliance.GetPOIDocumentsExpirationPopulation](Compliance/Stored%20Procedures/Compliance.GetPOIDocumentsExpirationPopulation.md) - DocumentTypeID=2 (POI), filters BackOffice.CustomerDocumentToDocumentType
- [Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325.md) - DEPRECATED, same DocumentTypeID=2 filter
- [BackOffice.CustomerDocument](BackOffice/Tables/BackOffice.CustomerDocument.md) - SuggestedDocumentTypeID (FK WITH CHECK, 99.99% populated): AI vendor's (Au10tix/Onfido) predicted type for 8.78M documents. BackOffice agents confirm/override via CustomerDocumentToDocumentType. Most common: 1=Proof of Address, 2=Proof of Identity.

---

## Funding Status {#funding-status}

**Definition**: Whether a user's account funding state meets platform requirements.

**Source Table**: `Dictionary.FundingStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Partial | User has deposited but hasn't met the full funding requirement |
| 1 | Valid | User has met the minimum funding threshold — fully funded |

**Key Characteristics**:
- Binary status used to gate features or trading access

**Used By**:

---

## Funding Type {#funding-type}

**Definition**: Payment method/provider used for deposits and withdrawals. Controls transaction limits, currencies, and processing rules.

**Source Table**: `Dictionary.FundingType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | CreditCard | Visa/Mastercard credit or debit card payment |
| 2 | WireTransfer | International bank wire transfer |
| 3 | PayPal | PayPal e-wallet payment |
| 6 | Neteller | Neteller e-wallet |
| 8 | MoneyBookers | Skrill (formerly MoneyBookers) e-wallet |
| 11 | Giropay | German online banking payment method |
| 15 | Sofort | European instant bank transfer |
| 16 | InternalPayment | System-generated internal credit/debit (not user-initiated) |
| 18 | TestDeposit | QA/test environment deposit |
| 19 | IBDeposit | Introducing Broker deposit |
| 22 | UnionPay | China UnionPay card network |
| 27 | eToroCryptoWallet | Transfer from eToro's crypto wallet product |
| 28 | OnlineBanking | General online banking payment |
| 30 | RapidTransfer | Skrill RapidTransfer instant bank transfer |
| 32 | PWMB | Pay With My Bank (open banking) |
| 33 | eToroMoney | Transfer from eToro Money debit card/account |
| 34 | iDEAL | Dutch instant bank transfer |
| 35 | Trustly | Nordic/EU open banking payment |
| 36 | Przelewy24 | Polish online banking payment |
| 37 | POLI | Australian/NZ instant bank transfer |
| 38 | OpenBanking | Generic PSD2 open banking payment |
| 39 | Payoneer | Payoneer payment platform |
| 40 | NFT | NFT-related transfer |
| 42 | EtoroOptions | eToro Options product transfer |
| 43 | GCCInstantBankTransfer | Gulf Cooperation Council region instant bank transfer |
| 44 | MoneyFarm | MoneyFarm investment platform integration |

**Key Characteristics**:
- IsFundingTypeActive (0/1) indicates whether the method is currently available to users
- IsRefundable determines if deposits can be reversed to the same method
- IsRedeemable indicates if withdrawals can be sent via this method
- IsSingleFunding limits the method to one-time use (no repeat deposits)
- MaxDepositAmount caps the single-transaction deposit limit
- DefaultCurrency references Dictionary.Currency for the default processing currency
- Temporal table (ValidFrom/ValidTo) — changes are historically tracked

**Used By**:

---

## Hedge Account Type {#hedge-account-type}

**Definition**: Classification of a physical trading account held at an external liquidity provider. Determines whether the account is used for actual hedge order execution or only for OMS pricing/margin calculations.

**Source Table**: `Dictionary.HedgeAccountType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 2 | Execution Account | The primary account for placing real hedge orders with the liquidity provider. Used for actual trade execution and position management. |
| 4 | OMS IM Pricing Account | Account used by the Order Management System for initial margin (IM) pricing calculations only. Does NOT execute real trades - provides reference prices and margin data. |

**Key Characteristics**:
- Operational procedures filter `AccountTypeID != 4` to exclude OMS pricing accounts from hedge routing logic
- Multiple Execution Accounts can exist per provider for load distribution (e.g., ZBFX has 3)
- ID values are non-sequential (2 and 4 only) - reflects partial enumeration

**Used By**:
- [Hedge.Accounts](Hedge/Tables/Hedge.Accounts.md) - AccountTypeID column; classifies each registered LP account as execution or pricing

---

## Hedge Execution Strategy {#hedge-execution-strategy}

**Definition**: Algorithm used by the hedge server to submit orders to liquidity providers. Controls whether orders are sent as standard market orders or using smart execution techniques.

**Source Table**: `Dictionary.HedgeServerExecutionStrategy`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Normal | Standard direct order submission to the liquidity provider. Order is sent immediately at current market price. |
| 1 | Smart | Smart execution algorithm - may use techniques such as TWAP (time-weighted average price), iceberg orders, or multi-LP routing to minimize market impact. |

**Key Characteristics**:
- Configured per hedge server via Hedge.ServerConfiguration.ExecutionStrategy
- NOTE: `GetServerConfiguration` SP does not return this column (schema evolution gap - column added after SP was written)

**Used By**:
- [Hedge.ServerConfiguration](Hedge/Tables/Hedge.ServerConfiguration.md) - ExecutionStrategy column (FK WITH CHECK); controls the execution algorithm for the hedge server

---

## Hedge Exposure Mode {#hedge-exposure-mode}

**Definition**: The exposure calculation regime used by a hedge server instance. Controls how the server aggregates and computes net market risk exposure across positions.

**Source Table**: `Dictionary.HedgeServerExposureMode`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Normal | Standard per-instrument net exposure calculation. Each instrument's exposure computed independently. |
| 1 | Major | Exposure calculated using major currency pairs only. Works in conjunction with the ConvertToMajors flag to decompose cross-pairs into major equivalents. |
| 2 | Portfolio | Exposure aggregated at portfolio level across all instruments. Allows cross-instrument netting of offsetting positions. |
| 3 | SpotExposureMode | Spot-rate based exposure calculation, designed for FX spot instrument hedging. |

**Key Characteristics**:
- Configured per hedge server via Hedge.ServerConfiguration.ExposureMode
- Default value is 0 (Normal) for all current hedge server instances
- Interacts with ConvertToMajors flag and PortfolioConversionConfigurations for modes 1 and 2

**Used By**:
- [Hedge.ServerConfiguration](Hedge/Tables/Hedge.ServerConfiguration.md) - ExposureMode column (FK WITH CHECK); defines exposure calculation regime for the hedge server
- [Hedge.HedgeServerExposureModeConfiguration](Hedge/Tables/Hedge.HedgeServerExposureModeConfiguration.md) - per-server exposure mode configuration

---

## Hedge Order State {#hedge-order-state}

**Definition**: Lifecycle state of a hedge order as it progresses through execution at a liquidity provider. Each state transition generates a new row in Hedge.ExecutionLog, creating a complete timeline of the order's lifecycle.

**Source Table**: `Dictionary.HedgeOrderState`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | Default/unset state. Not observed in active ExecutionLog data. |
| 1 | Sent | Order dispatched to the liquidity provider. Not observed in production data (transient state). |
| 2 | New | LP has acknowledged receipt of the order. First state typically seen in ExecutionLog. |
| 3 | Partial | Partial fill received - the LP executed a portion of the requested quantity. Multiple Partial rows accumulate for the same order. |
| 4 | Fill | Order fully filled by the LP. Success=1. Terminal success state. |
| 5 | Reject | LP rejected the order. Success=0. Common reasons: price stale, no liquidity, size exceeded. |
| 6 | Fail | Internal failure state. Not observed in production data (may indicate internal routing failure). |
| 7 | Cancelled | Order was cancelled before fill. Rare - 360 rows observed vs 2.37M total. |

**Key Characteristics**:
- A typical successful order sequence: 2 (New) -> 3 (Partial, repeated) -> 4 (Fill)
- A rejected order: 2 (New) -> 5 (Reject)
- 44% of rows are Partial (3), 31% are Reject (5), 19% are Fill (4)
- Hedge.ExecutionLog uses WITH NOCHECK FK - existing rows are not re-validated

**Used By**:
- [Hedge.ExecutionLog](Hedge/Tables/Hedge.ExecutionLog.md) - OrderState column (smallint, FK WITH NOCHECK); one row per state transition, multiple rows per order
- [Hedge.LogExecution](Hedge/Stored%20Procedures/Hedge.LogExecution.md) - @OrderState parameter; the state being recorded for each execution call
- [Hedge.ExecutionLogInsertBulk](Hedge/Stored%20Procedures/Hedge.ExecutionLogInsertBulk.md) - OrderState within TVP bulk insert

---

## Hedge Recovery State {#hedge-recovery-state}

**Definition**: Classification of the reconciliation action taken for a specific instrument during a hedge server recovery session. Describes what the recovery process found and did to align the internal hedge book with the liquidity provider's actual positions.

**Source Table**: `Dictionary.HedgeRecoveryState`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | Default/unset state. Not typically used in active recovery log entries. |
| 1 | Added | A position exists at the LP that was NOT in the hedge server's internal state. The LP position was adopted and added to the internal record. |
| 2 | Updated | The hedge server's position was corrected to match the LP's actual position (different units, rate, or direction). Prev* and New* columns capture the before/after state. |
| 3 | Removed | A position was in the hedge server's internal state but NOT at the LP. The internal record was removed to align with LP reality. |
| 4 | Detected | A position was found at the LP and verified as matching the internal state. No correction needed - purely informational. |

**Key Characteristics**:
- State is part of the composite PK of RecoveryLog - multiple states can be recorded for the same instrument in one recovery session
- Added+Detected are the expected normal states; Updated+Removed indicate discrepancies that needed correction
- Recovery sessions are infrequent (server restart, LP reconnection)

**Used By**:
- [Hedge.RecoveryLog](Hedge/Tables/Hedge.RecoveryLog.md) - State column (smallint, FK WITH CHECK); classifies each reconciliation action in a recovery session
- [Hedge.LogRecovery](Hedge/Stored%20Procedures/Hedge.LogRecovery.md) - @State parameter; records the action type per instrument per recovery session

---

## Hedge Strategy Mode {#hedge-strategy-mode}

**Definition**: Strategy used by eToro's hedge execution engine to manage market risk exposure from client positions.

**Source Table**: `Dictionary.HedgeStrategyMode`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | STRATEGY_FULLY | Every client position is fully hedged 1:1 with the liquidity provider |
| 1 | STRATEGY_BOUNDARIES | Hedging only when net exposure exceeds configured boundary thresholds |
| 2 | STRATEGY_HBC | Hedge-By-Client — hedging decisions based on per-client risk profile |
| 3 | STRATEGY_PERIODIC_BOUNDARIES | Similar to boundaries but rebalanced on a periodic schedule |

**Key Characteristics**:
- Controls the risk management approach at the instrument/regulation level
- Fully hedged (0) is the safest but most expensive strategy

**Used By**:
- [Customer.CustomerStatic](Customer/Tables/Customer.CustomerStatic.md) - LanguageID (FK Dictionary.Language, controls UI language) and CommunicationLanguageID (separate language for emails/notifications)
- [Customer.UpdateCustomerLanguageID](Customer/Stored%20Procedures/Customer.UpdateCustomerLanguageID.md) - Updates CustomerStatic.LanguageID for a given CID

---

## Language {#language}

**Definition**: User interface and communication language supported by the eToro platform.

**Source Table**: `Dictionary.Language`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | English | Default platform language (en-GB) |
| 2 | German | de-DE |
| 3 | Arabic | ar-AE |
| 4 | Chinese | Simplified Chinese (zh-CN) |
| 5 | Russian | ru-RU |
| 6 | Spanish | es-ES |
| 7 | French | fr-FR |
| 8 | Italian | it-IT |
| 9 | Japanese | ja-JP |
| 10 | Portuguese | Brazilian Portuguese (pt-BR) |
| 11 | Turkish | tr-TR |
| 12 | Greek | el-GR |
| 13 | Korean | ko-KR |
| 14 | Swedish | sv-SE |
| 15 | Norwegian | nb-NO |
| 16 | Hungarian | hu-HU |
| 17 | Polish | pl-PL |
| 18 | ChineseTraditional | Traditional Chinese/Taiwan (zh-TW) |
| 19 | Dutch | nl-NL |
| 20 | EuropeanPortuguese | pt-PT (distinct from Brazilian Portuguese) |
| 21 | Czech | cs-CZ |
| 22 | Malay | ms-MY |
| 23 | Danish | da-DK |
| 24 | Romanian | ro-RO |
| 25 | EnglishUS | US English (en-US) — distinct from UK English for regulatory text |
| 26 | Vietnamese | vi-VN |
| 27 | Thai | th-TH |
| 28 | Finnish | fi-FI |

**Key Characteristics**:
- IsoCode and CultureCode enable localization of UI, emails, and legal documents
- Some languages have regional variants (English UK vs US, Portuguese BR vs EU)

**Used By**:

---

## Leverage {#leverage}

**Definition**: Available leverage multiplier values for trading positions. Determines the ratio of position exposure to required margin.

**Source Table**: `Dictionary.Leverage`

**Values**:

| ID | Value | Business Meaning |
|----|-------|-----------------|
| 1 | 1 | No leverage (1:1) — full cash position, used for real stock purchases |
| 9 | 2 | 2x leverage — doubles exposure for half the margin |
| 2 | 5 | 5x leverage |
| 3 | 10 | 10x leverage |
| 11 | 20 | 20x leverage — ESMA retail limit for major indices |
| 10 | 30 | 30x leverage — ESMA retail limit for major forex pairs |
| 5 | 50 | 50x leverage |
| 6 | 100 | 100x leverage |
| 7 | 200 | 200x leverage |
| 8 | 400 | 400x leverage — highest, restricted to professional clients |

**Key Characteristics**:
- ESMA regulations cap retail leverage: 30x forex, 20x indices, 10x commodities, 5x stocks, 2x crypto
- Leverage 1 (ID=1) enables real asset ownership (SettlementType=REAL)
- Higher leverage = higher risk but lower margin requirement

**Used By**:

---

## Leverage Types {#leverage-types}

**Definition**: Categories of leverage rule sets applied to different regulatory or market contexts.

**Source Table**: `Dictionary.LeverageTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Default | Standard leverage rules for most jurisdictions |
| 2 | USA Leverages | US-specific leverage limits (NFA/FINRA regulated) |

**Key Characteristics**:
- Controls which leverage values are available to users based on their regulation

**Used By**:

---

## Market Range Validation Type {#market-range-validation-type}

**Definition**: Unit of measurement for market range (slippage tolerance) on order execution.

**Source Table**: `Dictionary.MarketRangeValidationType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | PIPS | Market range expressed in price pips (fixed-unit distance) |
| 2 | Percentage | Market range expressed as a percentage of the current price |

**Key Characteristics**:
- Configurable per instrument — forex typically uses PIPS, others may use Percentage

**Used By**:

---

## Mirror Status {#mirror-status}

**Definition**: State of a CopyTrading (mirror) relationship between a copying user and a copied trader.

**Source Table**: `Dictionary.MirrorStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Active | Copy relationship is live — new positions from the leader are automatically replicated |
| 1 | Pause | Copy is temporarily paused — existing positions remain but no new ones are opened |
| 2 | PendingClose | Copy is being terminated — system is closing all mirrored positions |
| 3 | InAlignment | System is aligning the copier's portfolio to match the leader's current positions |

**Key Characteristics**:
- InAlignment occurs when a user first starts copying or when resyncing after a pause

**Used By**:

---

## Mirror Type {#mirror-type}

**Definition**: Category of CopyTrading relationship, determining the source type being copied.

**Source Table**: `Dictionary.MirrorType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Regular | Standard copy of another user's manual trading |
| 2 | CopyMe | Legacy CopyMe variant |
| 3 | Social Index | Copying a social-based index strategy |
| 4 | Fund | Copying a managed fund portfolio |

**Key Characteristics**:
- Regular (1) is the primary CopyTrading product

**Used By**:

---

## Open Position Action Type {#open-position-action-type}

**Definition**: The trigger or reason for opening a new trading position. Used for attribution, analytics, and fee routing.

**Source Table**: `Dictionary.OpenPositionActionType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| -1 | Undefined | Unknown origin (legacy data or system error) |
| 0 | Customer | User manually opened the position |
| 1 | Hierarchical Open | Position opened because the copied trader opened (CopyTrading chain) |
| 2 | Reopen | Position reopened after a previous close (e.g., contract rollover) |
| 3 | Open Open | Opened via a "fill delayed order" flow |
| 4 | Stock Dividend | New position created from a stock dividend issuance |
| 5 | Corporate Action | Position created/adjusted by a corporate action (split, merger) |
| 6 | Technical Issue | Position created to correct a technical error |
| 7 | Operational position adjustment | Internal operational correction |
| 8 | Add Funds | Additional funds allocated to an existing copy relationship |
| 9 | Reinvestment | Dividend reinvestment into the same instrument |
| 10 | Admin | Opened by operations/admin staff |
| 11 | Stacking | Position opened as part of staking (crypto) |
| 12 | Promotion | Promotional/bonus position |
| 13 | ACATS_IN | Position transferred in via ACATS (Automated Customer Account Transfer Service) |
| 14 | ReedemForNFT | Position related to NFT redemption |
| 15 | Technical | Generic technical position creation |
| 16 | Alignment | Opened during CopyTrading portfolio alignment |
| 17 | Recurring Investment | Position opened by automated recurring investment plan |

**Key Characteristics**:
- Customer (0) and Hierarchical Open (1) account for the vast majority of positions
- Corporate Action (5) and Stock Dividend (4) positions are system-generated
- ACATS_IN (13) supports US regulatory requirements for account transfers

**Used By**:

---

## Operation Type {#operation-type}

**Definition**: Specific type of trading operation in the order execution pipeline. Tracks the exact nature of each order/position lifecycle event.

**Source Table**: `Dictionary.OperationType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | OrderForOpen | New order submitted for opening a position |
| 1 | OrderForOpenInMirror | New order submitted as part of CopyTrading |
| 2 | OrderForClose | Order submitted to close a position |
| 3 | OrderForCloseInMirror | Close order from CopyTrading chain |
| 4 | CancelDelayedOrderForOpen | Cancellation of a pending open order |
| 5 | CancelDelayedOrderForClose | Cancellation of a pending close order |
| 6 | CancelOrderForOpen | Cancellation of an active open order |
| 7 | CancelOrderForClose | Cancellation of an active close order |
| 8 | OrderForOpenStatusUpdateRejected | Open order was rejected by the execution engine |
| 9 | OrderForCloseStatusUpdateRejected | Close order was rejected by the execution engine |
| 10 | OrderForCloseStatusUpdateFilled | Close order successfully executed |
| 11 | OrderForOpenStatusUpdateFilled | Open order successfully executed |
| 12 | PositionClose | Direct position close (not order-based) |
| 13 | PositionCloseByLimit | Position closed by SL/TP limit |
| 14 | PositionOpen | Direct position open (not order-based) |
| 15 | OperationalOpenPosition | Position opened by operations team |
| 16 | OperationalClosePosition | Position closed by operations team |
| 17 | OperationalPositionAdjustment | Position parameters adjusted by operations |
| 18 | DirectOpenPosition | Direct market open bypassing the order queue |
| 19 | DirectClosePosition | Direct market close bypassing the order queue |
| 20 | OrderForCloseByLimit | Limit-triggered close order |
| 21 | OrderForCloseByRate | Rate-triggered close order |
| 22 | AdminOrderForOpenWithHedge | Admin order with hedge instruction |
| 23 | AdminOrderForOpenWithoutHedge | Admin order without hedge (B-book) |
| 24 | AdminPositionOpen | Admin-opened position |
| 25 | Reopen | Position reopened (contract rollover, recovery) |

**Key Characteristics**:
- FeeOperationTypeID links to fee calculation: 1=Open fees, 2=Close fees, NULL=no fee
- Mirror/hierarchical operations (1, 3) share the same fee structure as their parent types
- Direct operations (18, 19) skip the order queue for immediate execution

**Used By**:

---

## Payment Status {#payment-status}

**Definition**: State of a deposit payment transaction through its processing lifecycle. Covers approval, rejection, and reversal states.

**Source Table**: `Dictionary.PaymentStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | New | Payment record created, not yet processed |
| 2 | Approved | Payment authorized and funds credited to account |
| 3 | Decline | Payment declined by card issuer or provider |
| 4 | Technical | Technical failure during processing |
| 5 | InProcess | Payment being processed by the payment provider |
| 6 | Canceled | Payment canceled before completion |
| 7 | Confirmed | Payment verified and settled |
| 8-9 | DeclineBlockCard/DeclineBadBins | Card-level blocks (stolen card, known fraud BINs) |
| 10 | DeclineMemberLimits | User exceeded deposit limits |
| 11 | Chargeback | Customer disputed the charge with their bank |
| 12 | Refund | eToro initiated a return of funds |
| 13 | Pending | Awaiting external confirmation |
| 26 | RefundAsChargeback | Refund issued proactively to avoid a chargeback |
| 36 | PendingReview | Flagged for manual compliance review |
| 37 | ChargebackReversal | Chargeback was overturned in eToro's favor |
| 38 | RefundReversal | Previously issued refund was reversed |
| 39 | ReversedDeposit | Deposit was reversed (funds removed from account) |

**Key Characteristics**:
- Multiple Decline* statuses (8-10, 14-35) provide granular fraud/risk rejection reasons
- Chargeback (11) and its reversal (37) track dispute lifecycle
- DeclineByRRE (35) indicates rejection by the Risk Rules Engine
- PaymentStatusID=2 (Approved) is used by legacy Compliance SPs as the deposit eligibility filter (replaced by IsFTD=1 in newer SPs)

**Used By**:
- [Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325.md) - DEPRECATED, uses PaymentStatusID=2 to check deposit eligibility
- [Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325.md) - DEPRECATED, same PaymentStatusID=2 filter
- [Compliance.GetPOIDocumentsExpirationPopulation](Compliance/Stored%20Procedures/Compliance.GetPOIDocumentsExpirationPopulation.md) - uses PaymentStatusID=2 for deposit eligibility (this active SP still uses the legacy filter, unlike GetPOADocumentsExpirationPopulationFor3Years which uses IsFTD=1)

---

## Player Status {#player-status}

**Definition**: The behavioral restriction state of an eToro user account. Each status enables or disables specific platform capabilities via boolean permission flags.

**Source Table**: `Dictionary.PlayerStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Normal | Fully active — all capabilities enabled |
| 2 | Blocked | Fully locked — no access to any platform features |
| 3 | Chat Blocked | Can trade normally but cannot post to social feed or chat |
| 4 | Blocked Upon Request | User self-requested account lock |
| 5 | Warning | Active with a compliance warning flag — under observation |
| 6 | Blocked - Under Investigation | Locked during active compliance/fraud investigation |
| 7 | Scalpers Block | Blocked due to detected scalping behavior |
| 8 | Blocked - PayPal Investigation | Locked during PayPal fraud investigation |
| 9 | Trade & MIMO Blocked | Can log in and view but cannot open positions or move money |
| 10 | Deposit Blocked | Can trade existing positions but cannot add new funds |
| 11 | Social Index | Special status for social index accounts |
| 12 | Copy Block | Can trade normally but cannot copy other users |
| 13 | Pending Verification | Account awaiting KYC completion — trading restricted |
| 14 | Blocked – Failed Verification | Locked because KYC verification was not completed/approved |
| 15 | Block Deposit & Trading | Cannot deposit or open new positions, can only close |

**Key Characteristics**:
- IsBlocked flag: true for full blocks (2, 4, 6, 7, 8, 14), false for partial restrictions
- Permission matrix: CanOpenPosition, CanClosePosition, CanDeposit, CanRequestWithdraw, CanLogin, CanChatAndPost, CanBeCopied, CanCopy
- GetsInterest flag determines overnight fee/credit eligibility
- In document expiration SPs: IsBlocked=1 statuses (2, 4, 6, 7, 8, 14) are excluded from notification campaigns

**Used By**:
- [Compliance.GetPOADocumentsExpirationPopulationFor3Years](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationFor3Years.md) - excludes customers with IsBlocked=1 statuses from POA expiry population
- [Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325.md) - DEPRECATED, same block exclusion
- [Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325.md) - DEPRECATED, same block exclusion
- [Compliance.GetPOIDocumentsExpirationPopulation](Compliance/Stored%20Procedures/Compliance.GetPOIDocumentsExpirationPopulation.md) - excludes blocked customers from POI expiry population
- [Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325.md) - DEPRECATED, same block exclusion
- [Compliance.GetQuestionsExpirationPopulation](Compliance/Stored%20Procedures/Compliance.GetQuestionsExpirationPopulation.md) - used indirectly via Customer.CustomerStatic PlayerStatusID filter
- [Compliance.GetQuestionsExpirationPopulationNew](Compliance/Stored%20Procedures/Compliance.GetQuestionsExpirationPopulationNew.md) - same usage via #users pre-filter
- [Customer.CustomerStatic](Customer/Tables/Customer.CustomerStatic.md) - PlayerStatusID column (FK Dictionary.PlayerStatus, DEFAULT=0); distribution: 97.5% = 1 (Normal/Active) across 18.7M accounts; also PlayerStatusReasonID and PlayerStatusSubReasonID provide hierarchical reason codes for non-Active statuses
- [Customer.SetStatus](Customer/Stored%20Procedures/Customer.SetStatus.md) - Updates CustomerStatic.PlayerStatusID; the primary SP for changing an account's compliance/trading status (block, unblock, restrict)
- [Customer.OperationBlockForCID](Customer/Stored%20Procedures/Customer.OperationBlockForCID.md) - Sets a blocking PlayerStatus on a CID (e.g., Status 2/Blocked, 9/Trade+MIMO Blocked, 10/Deposit Blocked)
- [Customer.OperationUnBlockForCID](Customer/Stored%20Procedures/Customer.OperationUnBlockForCID.md) - Resets PlayerStatus to 1 (Normal) for a CID
- [Customer.GetCustomerRelationsWithPlayerStatuses](Customer/Stored%20Procedures/Customer.GetCustomerRelationsWithPlayerStatuses.md) - Returns customer copy relationships with their PlayerStatus - used for filtering active vs restricted users in CopyTrading

---

## Redeem Status {#redeem-status}

**Definition**: Lifecycle state of a CopyTrading withdrawal (redeem) request. Tracks from initial request through position closure to fund transfer.

**Source Table**: `Dictionary.RedeemStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | PositionPending | Redeem requested, waiting for positions to be queued for closure |
| 2 | Rejected | Redeem request denied (insufficient equity, compliance block) |
| 3 | Approved | Request approved, positions about to be closed |
| 4 | ReadyToRedeem | Positions closed, funds ready to be transferred back to available balance |
| 5 | PositionClosing | Positions are actively being closed in the market |
| 6 | PositionClosed | All positions successfully closed |
| 7 | TransactionInProcess | Fund transfer in progress |
| 8 | TransactionDone | Funds successfully returned to available balance — complete |
| 20 | Terminated | Redeem process terminated abnormally |
| 21 | FailedToCancel | Cancellation of the redeem was attempted but failed |
| 25 | TransferNegativeBalance | Redeem completed but resulted in a negative balance transfer |
| 100 | New | Initial state when redeem is first created |

**Key Characteristics**:
- IsCancelable flag: true for early states (1-5, 21, 25, 100), false once positions are closed (6-8, 20)
- Follows a linear lifecycle: New → PositionPending → Approved → PositionClosing → PositionClosed → TransactionInProcess → TransactionDone

**Used By**:

---

## Region {#region}

**Definition**: Geographic region grouping for countries. Used for regulatory bucketing, marketing segmentation, and default currency assignment.

**Source Table**: `Dictionary.Region`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unknown | Unclassified region |
| 1 | Northern America | USA (default currency: USD) |
| 2 | Southern America | Latin America (default currency: USD) |
| 3 | Europe | Continental Europe (default currency: EUR) |
| 4 | Asia | Asian countries (default currency: USD) |
| 5 | Africa | African countries (default currency: USD) |
| 6 | Oceania | Pacific region (default currency: USD) |
| 7 | Canada | Canada (default currency: CAD) |
| 8 | UK | United Kingdom (default currency: GBP) |
| 9-25 | Country-specific | Individual countries elevated to region level for marketing granularity |

**Key Characteristics**:
- DefaultCurrency references Dictionary.Currency for the region's primary trading currency
- Some individual countries (UK, Netherlands, Italy, Spain, etc.) have their own region IDs for targeted marketing

**Used By**:

---

## MiFID Categorization {#mifid-categorization}

**Definition**: Classifies customers under MiFID II (Markets in Financial Instruments Directive) investor protection rules. Determines leverage limits, disclosure requirements, and product access. Critical input to the TradingRiskStatusID computed column in BackOffice.Customer.

**Source Table**: `Dictionary.MifidCategorization`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | Not classified (system/internal accounts) |
| 1 | Retail | Standard retail investor - highest investor protection, lowest leverage, full disclosure requirements. 97.3% of 18.7M customers. |
| 2 | Professional | Professional client - reduced protection, higher leverage available. Assessed based on experience, portfolio, and frequency of trading. |
| 3 | Elective professional | Client who has elected professional status (Opted-Up) from retail. Reduced protection by request with documented eligibility criteria. |
| 4 | Retail Pending | Classification in progress or under review. Customer is treated as Retail during review. Maps to TradingRiskStatusID=1 (highest protection) in BackOffice.Customer computed column. |
| 5 | Pending | Classification pending - awaiting final determination. Maps to TradingRiskStatusID=2 in BackOffice.Customer computed column. |

**Key Characteristics**:
- DEFAULT=1 (Retail) for all new BackOffice.Customer rows
- Drives TradingRiskStatusID computed column: 1=standard retail -> TradingRiskStatusID=3; 2/3=professional/elective -> TradingRiskStatusID=2; 4=retail pending -> TradingRiskStatusID=1; 5=pending -> TradingRiskStatusID=2
- FCA and CySEC/eToro EU require MiFID II categorization for all retail customers
- MifidCategorizationID=2 and 3 (Professional/Elective) combined = 0.08% of customers

**Used By**:
- [BackOffice.Customer](BackOffice/Tables/BackOffice.Customer.md) - MifidCategorizationID (int, FK WITH CHECK, NOT NULL DEFAULT=1): distribution: 1=18.239M(97.3%), 2/3=sub-categories(0.08%), 4=retail pending(~2.6%), 5=pending(~0.03%). Key input to TradingRiskStatusID computed column.

---

## Regulation {#regulation}

**Definition**: Financial regulatory authority under which an eToro entity operates. Determines compliance rules, leverage limits, instrument availability, and legal jurisdiction.

**Source Table**: `Dictionary.Regulation`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No specific regulation (system/internal accounts) |
| 1 | CySEC | Cyprus Securities Exchange Commission — EU regulation (eToro EU) |
| 2 | FCA | Financial Conduct Authority — UK regulation (eToro UK) |
| 3 | NFA | National Futures Association — US futures regulation |
| 4 | ASIC | Australian Securities and Investments Commission |
| 5 | BVI | British Virgin Islands — fallback for unregulated jurisdictions |
| 6 | eToroUS | eToro US entity |
| 7 | FinCEN | Financial Crimes Enforcement Network — US crypto regulation (MSB license) |
| 8 | FinCEN+FINRA | Dual US regulation: crypto (FinCEN) + securities (FINRA) |
| 9 | FSA Seychelles | Financial Services Authority Seychelles |
| 10 | ASIC & GAML | ASIC with additional anti-money-laundering rules |
| 11 | FSRA | Financial Services Regulatory Authority (Abu Dhabi) |
| 12 | FINRAONLY | FINRA-only regulation for securities |
| 13 | MAS | Monetary Authority of Singapore |
| 14 | NYDFS+FINRA | New York DFS + FINRA dual regulation |

**Key Characteristics**:
- IsUSA flag identifies US-regulated entities (6, 7, 8, 12, 14) for special compliance handling
- JurisdictionName maps to the eToro legal entity name
- BankID references the banking partner for fund custody
- DefaultRegulationID points to a fallback regulation (BVI=5 for non-US, eToroUS=6 for US)

**Used By**:
- [Compliance.AddNewRegulation](Compliance/Stored%20Procedures/Compliance.AddNewRegulation.md) - inserts new row into Dictionary.Regulation; @defaultRegulationId self-references this table
- [Compliance.GetQuestionsExpirationPopulation](Compliance/Stored%20Procedures/Compliance.GetQuestionsExpirationPopulation.md) - @RegulationID parameter scopes reconfirmation population to a specific regulation
- [Compliance.GetQuestionsExpirationPopulationNew](Compliance/Stored%20Procedures/Compliance.GetQuestionsExpirationPopulationNew.md) - same @RegulationID filter as original SP
- [Compliance.GetPOADocumentsExpirationPopulationFor3Years](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationFor3Years.md) - @ExcludeRegulationIDs TVP parameter excludes specific regulatory populations from POA document expiry notifications
- [BackOffice.Customer](BackOffice/Tables/BackOffice.Customer.md) - RegulationID (WITH CHECK FK, NOT NULL DEFAULT 0, distribution: CySEC=7.39M/39.4%, BVI=7.30M/38.9%, FCA=1.17M/6.2%) and DesignatedRegulationID (secondary/override regulation for multi-jurisdiction accounts). RegulationID changes trigger RegulationChangeDate update and RegulationChangeLog insert via CustomerHistoryUpdate trigger. Key input to TradingRiskStatusID computed column.

---

## Risk Categories {#risk-categories}

**Definition**: Classification of risk alerts and compliance triggers. Used to categorize detected anomalies for investigation routing.

**Source Table**: `Dictionary.RiskCategories`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | MIMO - Amount | Deposit/withdrawal amount exceeds normal thresholds |
| 2 | MIMO - Velocity | Unusually rapid sequence of money movements |
| 3 | MIMO - Details Conflict | Mismatched personal/payment details across transactions |
| 4 | Login - Conflict | Login from unexpected location, device, or IP pattern |
| 5 | Affiliate Alert | Suspicious affiliate referral pattern |
| 6 | Affiliate activity | Unusual affiliate program activity |
| 7 | MIMO - Fraud | Known fraud pattern detected in money movements |
| 8 | Relations - Accounts | Multiple accounts detected for the same person |
| 9 | High Risk Country | Activity from a country flagged as high-risk |
| 10 | Trading Alert | Abnormal trading pattern (potential market abuse) |
| 11 | User Details | Suspicious user profile data |
| 12 | Login - HRC | Login from a high-risk country |
| 13 | Relations - IP | Multiple unrelated accounts sharing IP addresses |
| 14 | Funding Alert | Suspicious funding source or pattern |
| 15 | Affiliate | General affiliate risk flag |
| 16 | Login - Fraud | Login credentials compromised or stolen |
| 17 | Withdraw - Low trading | Withdrawal request with minimal trading activity (potential money laundering) |
| 18 | Risk Suspicious activity | General suspicious activity flag from risk engine |
| 19 | AML - Suspicious activity | Anti-Money Laundering specific suspicious activity |

**Key Characteristics**:
- MIMO = Money In, Money Out — covers deposit and withdrawal risk
- Categories route alerts to specific investigation teams (fraud, AML, compliance)

**Used By**:

---

## Risk Event Status {#risk-event-status}

**Definition**: Lifecycle state of a risk flag raised against a customer in BackOffice.CustomerRisk. Tracks the flag from automated detection through investigation to resolution.

**Source Table**: `Dictionary.RiskEventStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | On | Active risk flag - risk rule triggered or manually set. Requires Risk team review. 93.7% of all risk flags are in this state. |
| 2 | InProcess | Under active investigation by a Risk team agent. ManagerID identifies the investigating agent. |
| 3 | Off | Resolved/cleared. Flag no longer active. IsActive=false in dictionary. |

**Key Characteristics**:
- Flags move: On -> InProcess (agent claims) -> Off (resolved) or Off -> On (re-triggered)
- 1.37M flags are On, ~97K are InProcess or Off across 1.46M total rows
- Used together with RiskStatusID to fully classify a customer's risk posture

**Used By**:
- [BackOffice.CustomerRisk](BackOffice/Tables/BackOffice.CustomerRisk.md) - RiskEventStatusID (int, FK WITH CHECK, NOT NULL): lifecycle status of each risk flag. Used in the Risk team queue to filter active (On) vs in-progress vs resolved flags.

---

## Risk Status {#risk-status}

**Definition**: Specific type of risk alert that can be raised against a customer group (GCID). 90 defined types organized into 17 risk categories, from deposit velocity to fraud indicators to high-risk country flags. Managed by BackOffice Risk team agents.

**Source Table**: `Dictionary.RiskStatus`

**Key Active Values (grouped by category)**:

| Category | Key IDs | Risk Types |
|----------|---------|-----------|
| 1 - Deposit Limits | 2, 3, 38, 75, 77, 78 | OverTheLimit, FTDOverDailyLimit, OverTheLimitSingleDeposit, PMWBChargeback, BlacklistedRegistrationIp, FtdsWithSameRegistrationIp |
| 2 - Payment Velocity | 4, 5, 39-41, 61, 66, 68, 74, 88 | TooManyCreditCards, TooManyPayPalAccounts, CreditCardVelocity, UserVelocity, First24HVelocity, TooManyMoPs, TooManyDeclines, MultiplePaymentMethods, FirstHoursFromFtdVelocity, eToroCardVelocity |
| 3 - Identity Conflicts | 6, 7, 28, 87 | BinToRegCountryConflict, DepositNameConflict, NameConflict, WithdrawCountryConflict |
| 7 - Fraud | 12, 31, 37, 42, 63, 64, 69, 73, 89 | PayPalInvestigation, FundingStolenReportedByProcessor, FraudRequestResponseMismatch, CreditCardBruteForce, BinInBlackList, SuspiciousDepositPattern, RafDeclineFundingAlreadyExists, ACHInvestigation, CreditcardInvestigation |
| 9 - High Risk Country | 17, 70 | HighRiskAccountCountry, HighRiskFATFCountry |
| 11 - Document Quality | 29, 30, 43, 45, 46, 48-50, 71 | NotCommunicative, Poor/FakeDocs, AllDocsFake, FakeBills, FakeID, InvalidEmailAddress, InvalidPhoneNumber, InvalidDetails, PendingVerification |
| 17 - Withdraw Behavior | 82, 83 | WithdrawWithShortTermTrades, WithdrawWithLowTradingRatio |

**Key Characteristics**:
- 0=None, 1=Normal are non-alert baseline values
- IsActive=false on deprecated types (IDs 9, 13, 15-16, 18-25, 33-34, 36, 85, 86)
- Composite PK on (GCID, RiskStatusID) in CustomerRisk allows one flag per type per person
- Each active flag requires Risk team investigation before resolution

**Used By**:
- [BackOffice.CustomerRisk](BackOffice/Tables/BackOffice.CustomerRisk.md) - RiskStatusID (int, FK WITH CHECK, NOT NULL): identifies the specific alert type. Part of the composite PK with GCID. 90 defined types (90% are active), categorized into 17 risk domains.

---

## Verification Level {#verification-level}

**Definition**: KYC (Know Your Customer) verification milestone level for a customer account. Controls access to platform features and financial services. Customers progress through levels as they submit and pass document verification.

**Source Table**: `Dictionary.VerificationLevel`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Level 0 | Unverified - no identity documents submitted or approved. 34.2% of 18.7M customers. Full trading access requires advancing to Level 3. |
| 1 | Level 1 | Partial KYC - initial document submission started but not complete. 12.4% of customers. |
| 2 | Level 2 | Intermediate verification - some documents approved. 6.2% of customers. |
| 3 | Level 3 | Fully verified - all required KYC documents submitted and approved. 47.1% of customers. Required for full withdrawal access and increased deposit limits. |

**Key Characteristics**:
- Progression is triggered by BackOffice agents approving KYC documents (via BackOffice.CustomerSetDocumentStatus and related SPs)
- VerificationLevelID=3 is required for full withdrawal eligibility under most regulatory frameworks
- Distinct from the `Verified` bit in BackOffice.Customer (legacy field; customer can have Verified=1 with VerificationLevelID<3 from older process)
- Document Expiration Campaign eligibility requires VerificationLevelID >= 2

**Used By**:
- [BackOffice.Customer](BackOffice/Tables/BackOffice.Customer.md) - VerificationLevelID (int, FK WITH CHECK, NOT NULL DEFAULT=0): core KYC compliance field. Distribution: 0=34.2%, 1=12.4%, 2=6.2%, 3=47.1%. Indexed via Idx_BackOffice_Customer_VerificationLevelID for compliance reporting queries.

---

## Settlement Type {#settlement-type}

**Definition**: Determines how a trading position is settled — whether the user owns the underlying asset or holds a derivative contract. This is one of the most critical business concepts in eToro.

**Source Table**: `Dictionary.SettlementTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | CFD | Contract for Difference — user does not own the asset, only a derivative contract tracking price movement. Allows short positions and leverage. |
| 1 | REAL | Real ownership — user owns the actual underlying asset (shares, crypto). No leverage, long only. |
| 2 | TRS | Total Return Swap — derivative contract where eToro swaps total return with the user. Used in certain regulatory jurisdictions. |
| 3 | CMT | Commitment — reserved for specific operational scenarios |
| 4 | REAL_FUTURES | Real futures contract ownership |
| 5 | MARGIN_TRADE | Margin-based trading position with borrowing |

**Key Characteristics**:
- CFD (0) and REAL (1) account for the vast majority of positions
- REAL positions require Leverage=1 (no leverage allowed for real ownership)
- Settlement type determines dividend treatment, voting rights, and regulatory reporting
- TRS (2) was introduced for jurisdictions where CFDs face regulatory restrictions

**Used By**:
- [Trade.PositionTbl](Trade/Tables/Trade.PositionTbl.md) - SettlementTypeID column (tinyint, nullable): modern settlement classification on every position. NULL for legacy positions (fallback to IsSettled BIT). New positions always set both SettlementTypeID and IsSettled.
- [Trade.FnIsRealPosition](Trade/Functions/Trade.FnIsRealPosition.md) - Takes (IsSettled, InstrumentID) and returns 1 if real stock based on both legacy and modern settlement indicators
- [Trade.PositionOpen](Trade/Stored%20Procedures/Trade.PositionOpen.md) - @SettlementTypeID parameter: caller specifies settlement type; sets both SettlementTypeID and IsSettled for backward compatibility
- [Trade.FeeInPercentageConfigurations](Trade/Tables/Trade.FeeInPercentageConfigurations.md) - IsSettled column: determines which fee rate applies (different rates for CFD vs REAL)
- [Trade.FixPerLotConfigurations](Trade/Tables/Trade.FixPerLotConfigurations.md) - IsSettled column: determines which fix-per-lot rate applies

---

## Business Concepts

## KYC Reconfirmation {#kyc-reconfirmation}

**Definition**: The process by which eToro requires customers to periodically re-answer KYC questionnaires to confirm their trading knowledge, experience, and financial situation remains current. Under MiFID II appropriateness testing requirements, answers have a time-to-live (TTL) defined in seconds (`@BasePeriodSec`, typically 15552000 = 180 days). When answers expire, the customer enters a reconfirmation workflow.

**Key Characteristics**:
- TTL-based expiry: `DATEADD(Second, @BasePeriodSec, OccurredAt) < GETUTCDATE()` determines expiry
- Active workflow exclusion: Customers already in WorkFlowID=5 (not yet in StateTypeID=5 terminal) are excluded from the notification population to prevent duplicate campaigns
- Paginated results (`@Page`, `@PageSize`) enable batch processing of large populations
- Question 100 is a special "reconfirmation anchor" question used to detect whether an answer set was an initial assessment or a reconfirmation pass
- UK customers have a separate specialized flow using questions 172/175 and the RequirementID=23 tracking system

**Used By**:
- [Compliance.GetQuestionsExpirationPopulation](Compliance/Stored%20Procedures/Compliance.GetQuestionsExpirationPopulation.md) - primary SP for reconfirmation population identification
- [Compliance.GetQuestionsExpirationPopulationNew](Compliance/Stored%20Procedures/Compliance.GetQuestionsExpirationPopulationNew.md) - performance-optimized variant (has a known @questions bug)
- [Compliance.GetUkClassificationGapPopulation](Compliance/Stored%20Procedures/Compliance.GetUkClassificationGapPopulation.md) - UK-specific variant using hardcoded questions 172/175 and RequirementID=23

---

## Document Expiration Campaign {#document-expiration-campaign}

**Definition**: The compliance workflow that identifies customers whose KYC verification documents (POA or POI) are approaching or have reached expiry, and notifies them to re-upload fresh documents. eToro must maintain current documentation under KYC/AML regulations. The notification population is identified by these SPs and fed to the compliance notification service (SQL_Compliance).

**Key Characteristics**:
- POA (Proof of Address, DocumentTypeID=1): 3-year expiry from upload date (Occurred) or issue date. Active SP: `GetPOADocumentsExpirationPopulationFor3Years` with 1-month forward window.
- POI (Proof of Identity, DocumentTypeID=2): Uses government-printed ExpiryDate stored directly. Active SP: `GetPOIDocumentsExpirationPopulation` with 15-day forward window.
- Eligibility filters common to all active SPs: not blocked, has FTD (or approved deposit in legacy SPs), VerificationLevelID >= 2, AccountTypeID not Corporate/Joint, EvMatchStatus != 2 (EV-confirmed customers do not need manual re-verification)
- Internal employees (`PlayerLevelID=4`) handled via separate `@IsInternal=1` call
- Legacy 1-year expiry SPs carry `_JUNKYulia0325` suffix and should NOT be called

**Used By**:
- [Compliance.GetPOADocumentsExpirationPopulationFor3Years](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationFor3Years.md) - active POA expiry SP (3-year/1-month window)
- [Compliance.GetPOIDocumentsExpirationPopulation](Compliance/Stored%20Procedures/Compliance.GetPOIDocumentsExpirationPopulation.md) - active POI expiry SP (stored ExpiryDate/15-day window)
- [Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325.md) - DEPRECATED predecessor (1-year/15-day, RUNTIME ERROR)
- [Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325.md) - DEPRECATED predecessor (1-year/15-day, executables but legacy)
- [Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325](Compliance/Stored%20Procedures/Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325.md) - DEPRECATED sibling of active POI SP

---

## Copy Trading (CopyTrader / Mirror System) {#copy-trading}

**Definition**: eToro's flagship social trading feature allowing customers (copiers) to automatically replicate the trading activity of other customers (leaders/Popular Investors). When a leader opens a position, the system opens proportionally-sized mirror positions for all active copiers. The copy relationship (Mirror) persists until the copier stops copying or a stop-loss threshold is breached.

**Key Characteristics**:
- A Mirror row (Trade.Mirror) represents one copy relationship: one copier (CID) following one leader (ParentCID) with a specified allocation Amount
- MirrorID in Trade.PositionTbl: 0 or NULL = manual trade; positive = copy position FK to Trade.Mirror
- TreeID: Copy hierarchy identifier. Root position TreeID = own PositionID. Copier positions share the root's TreeID. Negative = demo tree.
- PositionRatio: Copier's allocation as fraction of leader's equity (Amount / RealizedEquity) determines copy sizing
- Mirror Stop-Loss (MSL): Equity-based threshold (MirrorSL in dollars, MirrorSLPercentage default 2%) that auto-closes the copy relationship when breached
- MirrorStatusID: 0=Active, 1=Pause, 2=PendingClose, 3=InAlignment
- CloseMirrorActionType: Why the mirror closed (0=Customer, 1=StopLoss, 2=BSL, 3=ManualLiquidation, 4=BackOffice, 5=CustomerDetach, 6=BackOfficeDetach)
- INSTEAD OF DELETE trigger on Trade.Mirror prevents deletion if open positions exist

**Used By**:
- [Trade.Mirror](Trade/Tables/Trade.Mirror.md) - core copy relationship table; PK MirrorID referenced by all copy positions
- [Trade.PositionTbl](Trade/Tables/Trade.PositionTbl.md) - MirrorID column, TreeID column, ParentPositionID column, PositionRatio column
- [Trade.RegisterMirror](Trade/Stored%20Procedures/Trade.RegisterMirror.md) - creates new copy relationship; validates MSL, checks copier's blocked operations
- [Trade.MirrorPauseCopy](Trade/Stored%20Procedures/Trade.MirrorPauseCopy.md) - pauses copying without closing the relationship
- [Trade.MirrorReopen](Trade/Stored%20Procedures/Trade.MirrorReopen.md) - reactivates a paused mirror
- [Trade.PostClosePositionActions](Trade/Stored%20Procedures/Trade.PostClosePositionActions.md) - handles copy hierarchy chain close when root position closes

---

## Crypto Airdrop {#crypto-airdrop}

**Definition**: An automated position operation performed as part of a cryptocurrency token distribution event. eToro executes airdrop positions on behalf of eligible customers (typically opening or closing positions in a crypto instrument). When an airdrop position operation fails, the failure is dual-logged: once to `History.PositionFail` (standard async failure path) and once to `Trade.PositionAirdropLog` (airdrop-specific result log with `Result=0`).

**Key Characteristics**:
- Airdrop operations are system-initiated (not customer-driven)
- `Trade.PositionAirdropLog` tracks the airdrop event: AirdropID, PositionID, Result (0=fail, 1=success), FailReason, ExecutionOccurred
- Failure path calls `History.PositionAirdropFailInfo` which wraps `History.PositionFailInfo` + updates `Trade.PositionAirdropLog`
- Airdrop failures track a FailReason string but NOT an ErrorCode (unlike standard position failures)

**Used By**:
- [History.PositionAirdropFailInfo](History/Stored%20Procedures/History.PositionAirdropFailInfo.md) - dual failure recorder (standard fail log + airdrop log update)

---

## Introducing Broker (IB) {#introducing-broker}

**Definition**: A third-party financial broker or affiliate partner who brings customers to eToro and authenticates them using the broker's own credentials. IB customers log in via the IB-specific authentication path (`History.LogInIB`) which either finds an existing customer by ProviderID+UserName, auto-registers from a pre-filled `Customer.RegistrationRequest`, or registers with minimal defaults (Country=USA, Currency=USD, Language=English). The IB partner is identified by `ProviderID`.

**Key Characteristics**:
- IB accounts have `ProviderID != 0` in `Customer.Customer` (ProviderID=0 = direct eToro customer)
- The IB authentication entry point handles all three scenarios: existing customer, new customer with RegistrationRequest, new customer with minimal defaults
- Password sync: if the IB partner updates the customer's password, eToro updates to match on next login
- Blocked customers (PlayerStatusID=2) return LoginResult=3; ProviderID mismatch returns LoginResult=1
- Dictionary.AccountType row 3 = "IB Account" (Introducing Broker account)
- FundingType row 19 = "IBDeposit" (Introducing Broker deposit)

**Used By**:
- [History.LogInIB](History/Stored%20Procedures/History.LogInIB.md) - IB combined register-and-login procedure

---

## Stock Split Adjustment {#stock-split-adjustment}

**Definition**: When a publicly traded company performs a stock split (e.g., 2-for-1), all historical closed positions in `History.Position` for that instrument must be retroactively adjusted so the economic value is preserved: rates (InitForexRate, LimitRate, StopRate, EndForexRate, etc.) are multiplied by PriceRatio (< 1 for splits), and unit counts (AmountInUnitsDecimal, LotCountDecimal) are multiplied by AmountRatio (> 1 for splits).

**Key Characteristics**:
- Split parameters stored in `History.SplitRatio`: InstrumentID, PriceRatioUnAdjusted, AmountRatioUnAdjusted, MinDate, IsCompletedClosePositions
- Only stock positions (InstrumentTypeID=5) opened before the split date (InitDateTime < MinDate) are adjusted
- Positions already processed are tracked in `History.PositionSplit` (idempotency via OUTPUT clause)
- Batch processing: 2000-row chunks with WHILE loop to limit lock contention
- `History.SplitRatio.IsCompletedClosePositions=1` guards against double-processing at split level
- Precision for rate rounding comes from `Trade.ProviderToInstrument.Precision` per instrument
- Example 2:1 split: PriceRatio=0.5 (halves all rates), AmountRatio=2.0 (doubles all unit counts)

**Used By**:
- [History.SplitClosePositions](History/Stored%20Procedures/History.SplitClosePositions.md) - closed position split adjustment processor
- [History.SplitRatio](History/Tables/History.SplitRatio.md) - split event parameter store
- [History.PositionSplit](History/Tables/History.PositionSplit.md) - processed-position idempotency audit log

---

## Position Lifecycle {#position-lifecycle}

**Definition**: The complete state machine for a trading position on the eToro platform, from customer request through execution to history archival. Every CFD, real stock, copy, and manual trade passes through this lifecycle.

**Key Characteristics**:
- Phase 1 - Order Creation: Customer (or CopyTrader engine) calls Trade.OrderForOpenCreate -> Trade.OrderForOpen row (REQUEST state)
- Phase 2 - Execution Planning: Trade.OrderForOpenJob reads pending orders -> Trade.OpenExecutionPlan row (PLAN state)
- Phase 3 - Position Open: Trade.OrderExitOpen executes plan -> Trade.PositionTbl INSERT (StatusID=1, OpenActionType set, InitDateTime, OpenRate)
- Phase 4 - Live Position: Position accumulates PnL, incurs overnight fees, receives dividends. Margin consumed. Hedge placed at LP (HedgeID populated via SetHedgeOrderID).
- Phase 5 - Position Close: Trade.PositionClose -> UPDATE StatusID=2, EndDateTime, ActionType, CloseRate, NetProfit, CommissionOnClose, EndForexRate
- Phase 6 - History Archival: Trade.PositionClose (or PostClosePositionActions) -> INSERT History.Position_Active -> DELETE from Trade.PositionTbl
- Parallel for orders: OrderForOpen/Close -> OpenExecutionPlan/CloseExecutionPlan -> ExecutedOpenOrders/ExecutedCloseOrders (archived to DB_Logs.History.*)
- Demo positions: Same lifecycle, negative TreeID, isolated from real position reporting

**Used By**:
- [Trade.PositionTbl](Trade/Tables/Trade.PositionTbl.md) - holds all open and recently-closed positions (StatusID 1=Open, 2=Closed)
- [Trade.PositionOpen](Trade/Stored%20Procedures/Trade.PositionOpen.md) - Phase 3: INSERTs the position row with StatusID=1
- [Trade.PositionClose](Trade/Stored%20Procedures/Trade.PositionClose.md) - Phase 5-6: UPDATEs StatusID=2, then moves to History
- [Trade.OrderForOpenCreate](Trade/Stored%20Procedures/Trade.OrderForOpenCreate.md) - Phase 1: creates the ORDER request
- [Trade.OrderForOpenJob](Trade/Stored%20Procedures/Trade.OrderForOpenJob.md) - Phase 2: processes pending orders into execution plans

---

