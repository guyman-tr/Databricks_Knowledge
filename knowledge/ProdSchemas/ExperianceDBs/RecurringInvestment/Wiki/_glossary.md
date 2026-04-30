# Business Glossary - RecurringInvestment

> Canonical definitions for business terms, value domains, and concepts.
> Object docs reference this glossary for shared terminology.
> Terms are progressively enriched as more objects are documented.

*Last updated: 2026-04-13 | Terms: 13 lookup-backed, 0 concept-based | Sources: 13 Dictionary tables, 0 object docs*

---

## Lookup-Backed Terms

## Copy Fail Error Code {#copy-fail-error-code}

**Definition**: Error codes that describe why a copy trading position failed to open or replicate. Used to classify failure reasons in the copy trading flow of recurring investment plans.

**Source Table**: `Dictionary.CopyFailErrorCode`

**Values**: Table is currently empty - no error codes defined. Values may be populated at runtime or maintained externally.

**Key Characteristics**:
- Simple lookup: ID + Name
- Referenced by PlanInstances.CopyFailErrorCode

**Used By**:

---

## Copy Position Status {#copy-position-status}

**Definition**: Tracks the status of copy trading position creation steps - whether registration and fund allocation to the copied portfolio succeeded or failed.

**Source Table**: `Dictionary.CopyPositionStatusID`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | RegisterSuccess | Copy relationship was successfully registered with the parent trader's portfolio |
| 2 | AddFundsSuccess | Funds were successfully allocated to the copy position after registration |
| 3 | RegisterFailed | Attempt to register the copy relationship with the parent trader failed |
| 4 | AddFundFailed | Fund allocation to the copy position failed after successful registration |

**Key Characteristics**:
- Two-step process: Register first, then AddFunds
- Success/failure tracked independently for each step
- Only ID=1 (TRUE) exists in MirrorOrderCreated, suggesting copy orders are flagged but not tracked with FALSE

**Used By**:

---

## Copy Type {#copy-type}

**Definition**: Classifies what kind of copy trading relationship a recurring investment plan uses. Determines whether the plan invests in a specific instrument directly, copies a Popular Investor (PI), or copies a SmartPortfolio.

**Source Table**: `Dictionary.CopyType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | Plan is not a copy plan - it invests directly in an instrument |
| 1 | PI | Plan copies a Popular Investor (PI) - allocates funds to mirror a specific trader's portfolio |
| 4 | SmartPortfolio | Plan copies a SmartPortfolio - a curated thematic portfolio managed by eToro |

**Key Characteristics**:
- Gap in IDs (no 2 or 3) suggests deprecated or reserved copy types
- CopyType=0 (None) is the default for standard instrument-based recurring plans
- PI and SmartPortfolio copy types link to CopyParentCID/CopyParentGCID in the Plans table

**Used By**:

---

## High Level Deposit Status {#high-level-deposit-status}

**Definition**: Summarizes the outcome of a recurring investment deposit attempt at a high level - whether the payment succeeded, was softly declined (retryable), or hard declined (permanent failure).

**Source Table**: `Dictionary.HighLevelDepositStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Success | Deposit was processed successfully and funds are available for investment |
| 2 | SoftDecline | Deposit was declined but the issue is temporary (e.g., insufficient funds, network timeout) - eligible for retry |
| 3 | HardDecline | Deposit was permanently declined (e.g., card expired, account closed) - no retry, may trigger plan cancellation |

**Key Characteristics**:
- Three-state classification of deposit outcomes
- SoftDecline vs HardDecline distinction drives different business flows: soft declines allow retry, hard declines may block or cancel the plan
- Maps to more granular DepositStatusID for detailed tracking

**Used By**:

---

## Instance Status {#instance-status}

**Definition**: Describes the lifecycle state of a single plan instance (one execution cycle of a recurring investment plan). Tracks whether the instance completed successfully, was skipped, cancelled, or encountered issues.

**Source Table**: `Dictionary.InstanceStatusID`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Success | Instance completed the full cycle: deposit -> order -> position opened successfully |
| 2 | Cancelled | Instance was cancelled before completion (system or business rule) |
| 3 | Skipped | Instance was automatically skipped by the system (e.g., eligibility check failed, blacklist match) |
| 4 | UserSkipped | Instance was explicitly skipped by the user's action |
| 5 | InProgress | Instance is currently executing - deposit, order, or position step is underway |
| 6 | Techenical Issue | Instance failed due to a technical/system error (note: original spelling preserved from source) |
| 7 | Completed without position | Instance completed the deposit but no position was opened (e.g., order cancelled, expired, or rejected) |

**Key Characteristics**:
- Terminal states: Success (1), Cancelled (2), Skipped (3), UserSkipped (4), Technical Issue (6), Completed without position (7)
- Non-terminal state: InProgress (5)
- "Techenical Issue" retains original spelling from the database
- Skipped (3) vs UserSkipped (4) distinguishes system-initiated skips from user-initiated ones

**Used By**:

---

## Mirror Order Created {#mirror-order-created}

**Definition**: Flag indicating whether a mirror (copy) order was created for a copy trading recurring investment instance. Used exclusively to mark that a copy order was successfully initiated.

**Source Table**: `Dictionary.MirrorOrderCreated`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | TRUE | A mirror order was created for this copy trading instance |

**Key Characteristics**:
- Boolean-like lookup with only a TRUE value - NULL or absence indicates no mirror order was created
- Only applies to copy trading plans (CopyType = 1 or 4)

**Used By**:

---

## MOP Type {#mop-type}

**Definition**: Method of Payment type - classifies the payment method used for recurring investment deposits. MOP determines how funds are collected for the recurring plan.

**Source Table**: `Dictionary.MopType`

**Values**: Table is currently empty - MOP types may be maintained externally or populated at runtime. Plans table has a default of 1 for MopType.

**Key Characteristics**:
- Simple lookup: ID + Name
- Plans.MopType defaults to 1, suggesting at least one MOP type exists in practice
- Referenced by Plans table and several stored procedures that filter by MOP type

**Used By**:

---

## Order Status {#order-status}

**Definition**: Tracks the lifecycle state of a trading order placed as part of a recurring investment instance. Covers the full order lifecycle from receipt through execution or cancellation.

**Source Table**: `Dictionary.OrderStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Received | Order was received by the system but not yet sent to market |
| 2 | Placed | Order was sent to the market/exchange and is awaiting execution |
| 3 | Filled | Order was fully executed - all requested units were purchased |
| 4 | Rejected | Order was rejected by the market/exchange or internal validation |
| 5 | PartiallyFilled | Order was partially executed - some but not all units were purchased |
| 6 | PendingCancel | Cancellation request was submitted but not yet confirmed |
| 7 | Canceled | Order was successfully cancelled before full execution |
| 8 | Expired | Order expired without being fully executed (e.g., market closed, time limit reached) |
| 9 | CanceledPartiallyFilled | Order was cancelled after partial execution - some units purchased, remainder cancelled |
| 10 | RejectedPartiallyFilled | Order was rejected after partial execution |
| 11 | WaitingForMarket | Order is queued and waiting for market to open before it can be placed |

**Key Characteristics**:
- Success states: Filled (3), PartiallyFilled (5)
- Failure states: Rejected (4), Canceled (7), Expired (8)
- Hybrid states: CanceledPartiallyFilled (9), RejectedPartiallyFilled (10) - partial success + cancellation/rejection
- In-progress states: Received (1), Placed (2), PendingCancel (6), WaitingForMarket (11)

**Used By**:

---

## Plan Event Code {#plan-event-code}

**Definition**: Comprehensive event classification system for recurring investment plan lifecycle events. Organizes events by numeric range to categorize successes, failures, cancellations, eligibility issues, and compliance blocks.

**Source Table**: `Dictionary.PlanEventCode`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 100 | CreatePlanSuccess | Plan was successfully created |
| 101 | DepositSuccess | Recurring deposit was processed successfully |
| 102 | OrderSuccess | Trading order was placed and executed |
| 103 | OpenPositionSuccess | Position was successfully opened |
| 200 | DepositFailedHardDeclineBlocked | Deposit hard-declined and plan is now blocked |
| 201 | DepositFailedHardDeclineNotBlocked_Phase02 | Deposit hard-declined in Phase 2 but plan not blocked |
| 203 | DepositFailedHardDeclineNotBlocked_Phase05 | Deposit hard-declined in Phase 5 but plan not blocked |
| 204 | DepositFailedSoftDecline | Deposit soft-declined (retryable) |
| 205 | DepositFailed | Generic deposit failure |
| 300 | DepositPlanCancelled | Recurring deposit plan was cancelled (generic) |
| 301 | DepositPlanCancelledRemovedMOP | Deposit plan cancelled because payment method was removed |
| 302 | DepositPlanCancelledByBO | Deposit plan cancelled by Back Office |
| 303 | DepositPlanCancelledByUser | Deposit plan cancelled by the user |
| 400 | DepositPlanFailedToBeCreated_Phase02 | Deposit plan creation failed during Phase 2 |
| 401 | NotEligibleAfterPlanCreated_Phase02 | User became ineligible after plan was created (Phase 2 check) |
| 402 | NotEligibleBeforeDeposit_Phase02 | User ineligible before deposit attempt (Phase 2 check) |
| 500 | NotEligibleBeforeOrderRequest_Phase02 | User ineligible before order request (Phase 2) |
| 501 | NoBalanceBeforeOrderRequest_Phase02 | Insufficient balance for order (Phase 2) |
| 503 | MissedOrder_Phase02 | Order was missed during Phase 2 processing |
| 504 | NoBalanceBeforeOrderRequest_Phase05 | Insufficient balance for order (Phase 5) |
| 506 | MissedOrder_Phase05 | Order was missed during Phase 5 processing |
| 507 | HasBeenAnOrderThisMonth | An order already exists for this month - skip duplicate |
| 508 | OrderCanceledByUser | User cancelled the order |
| 509 | OrderCanceledByEtoro | eToro system cancelled the order |
| 600 | OpenPositionFailed_Phase02 | Position open failed during Phase 2 |
| 601 | MissingPositionData_Phase02 | Position data missing in Phase 2 |
| 602 | MissingPositionDataDeadLinePassed_Phase05 | Position data still missing after Phase 5 deadline |
| 700 | CancelPlanByUser | User requested plan cancellation |
| 800 | PiLevelNotCompatible | Popular Investor level incompatible with plan requirements |
| 801 | NotEligibleForRecurringDepositPlan | User not eligible for recurring deposit plans |
| 802 | VerificationLevelNotCompatible | User verification level insufficient |
| 803 | PlayerStatusNotCompatible | User account status incompatible |
| 900 | CountryAndInstrumentIdNotCompatible | Instrument not available in user's country |
| 901 | CountryAndInstrumentTypeNotCompatible | Instrument type not available in user's country |
| 902 | InstrumentIdNotCompatible | Instrument is not compatible with recurring investment |
| 903 | InstrumentTypeNotCompatible | Instrument type is not compatible |
| 904 | InstrumentIdIsUsedInAnotherActivePlan | User already has an active plan for this instrument |
| 905 | InstrumentIdNotValid | Instrument ID does not exist or is invalid |
| 1000 | InvalidDepositPlan | Deposit plan configuration is invalid |
| 1001 | PlanIsNotActive | Attempted operation on a non-active plan |
| 1100 | ComplianceGapInstrumentTypeNotAllowed | Compliance: instrument type not permitted for user |
| 1101 | ComplianceGapLeverageNotSupported | Compliance: leverage not supported for this product |
| 1102 | ComplianceGapCryptoNotSupportedInCountry | Compliance: crypto not available in user's country |
| 1103 | ComplianceGapUserIsNotVerified | Compliance: user has not completed verification |
| 1104 | ComplianceGapUsaNotSupported | Compliance: feature not available for US users |
| 1105 | ComplianceGapAsicNotSupported | Compliance: feature not available under ASIC regulation |
| 1106 | ComplianceGapUserHasCnvmGap | Compliance: user has CNVM regulatory gap |
| 1107 | ComplianceGapElevatedRiskStock | Compliance: stock flagged as elevated risk |
| 1108 | ComplianceGapCryptoDltRequired | Compliance: crypto DLT questionnaire required |
| 1109 | ComplianceGapCryptoUkConditions | Compliance: UK crypto conditions not met |
| 1110 | ComplianceGapSelfieRequired | Compliance: selfie verification required |
| 1200 | LeverageTooHigh | Position rejected: leverage exceeds maximum |
| 1201 | UnitsTooHigh | Position rejected: units exceed maximum |
| 1202 | PositionAmountTooLow | Position rejected: amount below minimum |
| 1203 | LeverageTooLow | Position rejected: leverage below minimum |
| 1204 | MaxNopLimitReached | Position rejected: maximum number of positions limit reached |
| 1205 | AdminPositionSettlementTypeValidationFailure | Position rejected: settlement type validation failed |
| 1206 | InsufficientFundsError | Position rejected: insufficient funds in account |
| 1207 | InsertPosToDbError | Position rejected: database insert error |
| 1208 | OrderAlreadyExecutedError | Position rejected: order was already executed |
| 1209 | PlayerStatusBlocked | Position rejected: user account is blocked |
| 1210 | InstrumentBuyOperationsDisallowed | Position rejected: buy operations disabled for instrument |
| 1211 | InstrumentOpenEntryOrderDisallowed | Position rejected: entry orders disabled for instrument |
| 1212 | OperationBlockedDueToCustomerRestriction | Position rejected: customer has trading restriction |
| 1213 | InstrumentIsRestrictedManualOpen | Position rejected: instrument restricted from manual open |
| 1214 | PositionOpenFailedW8BenInvalid | Position rejected: W-8BEN tax form invalid or missing |
| 1215 | InternalSettingsUnavailable | Position rejected: internal configuration unavailable |
| 1216 | BlockedByCompliance | Position rejected: blocked by compliance rules |
| 1217 | OrderForOpenRejected | Position rejected: the opening order was rejected |
| 1218 | OrderForCloseRejected | Position rejected: the closing order was rejected |
| 1219 | OrderForCloseFailedPendingOrderForOpenExists | Position rejected: close failed because a pending open order exists |

**Key Characteristics**:
- Range-based organization: 100s=success, 200s=deposit failures, 300s=cancellations, 400s=creation failures, 500s=order issues, 600s=position issues, 700s=user actions, 800s=eligibility, 900s=instrument compatibility, 1000s=validation, 1100s=compliance gaps, 1200s=position open errors
- Phase suffixes (_Phase02, _Phase05) indicate which processing phase detected the issue
- Compliance gap codes (1100s) reference specific regulatory jurisdictions (USA, ASIC, CNVM, UK)

**Used By**:

---

## Plan Frequencies {#plan-frequencies}

**Definition**: Defines the frequency/cadence options for how often a recurring investment plan executes. Determines the interval between deposit and order cycles.

**Source Table**: `Dictionary.PlanFrequencies`

**Values**: DB table is empty but Confluence documents the canonical values:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Weekly | Plan executes weekly - NOT currently in use for Recurring Investment Plans |
| 2 | BiWeekly | Plan executes every two weeks - NOT currently in use for Recurring Investment Plans |
| 3 | Monthly | Plan executes every month on a specific day of the month chosen by the user - this is the ONLY frequency currently active |

**Key Characteristics**:
- Only Monthly (3) is currently active for Recurring Investment Plans
- Weekly and BiWeekly exist in the system but are disabled for this feature
- Values maintained externally (not in DB table) - see Confluence "Recurring Investment Database" page
- Referenced by Plans.FrequencyID

**Used By**:

---

## Plan Status {#plan-status}

**Definition**: Describes the lifecycle state of a recurring investment plan. Controls whether the plan actively creates new instances and processes deposits.

**Source Table**: `Dictionary.PlanStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Initializing | Plan creation started but something went wrong during the process - the plan never fully activated (per Confluence) |
| 1 | Active | Plan is fully active and executes - new instances will be created on schedule and deposits will be processed |
| 2 | Cancelled | Plan has been permanently cancelled and cannot be reactivated - by user, system, or back office |
| 3 | Stopped | NOT currently in use (per Confluence). Reserved status - potentially for future pause/resume functionality |
| 4 | Invalid | NOT currently in use (per Confluence). Reserved status for configuration or eligibility issues |

**Key Characteristics**:
- Only Active (1) plans generate new instances
- Confluence also documents a value 5=Paused ("not in use") which exists in the wiki but not in the DB table
- Unique constraint on Plans table: GCID+InstrumentID+PlanStatusID+CopyParentGCID filtered WHERE PlanStatusID=1, ensuring one active plan per user per instrument per copy parent
- Cancelled (2) is the only terminal state currently in production use
- Initializing (0) indicates a failed creation attempt, not a normal entry state

**Used By**:

---

## Plan Type {#plan-type}

**Definition**: Classifies the fundamental nature of a recurring investment plan - whether it targets a specific financial instrument or copies another trader's portfolio.

**Source Table**: `Dictionary.PlanType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Instrument | Plan invests in a specific instrument (stock, ETF, crypto, etc.) on a recurring schedule |
| 2 | Copy | Plan copies another trader (Popular Investor or SmartPortfolio) on a recurring schedule |

**Key Characteristics**:
- PlanType works together with CopyType: Instrument plans have CopyType=0 (None), Copy plans have CopyType=1 (PI) or 4 (SmartPortfolio)
- Determines which columns in Plans are relevant: Instrument plans use InstrumentID, Copy plans use CopyParentCID/CopyParentGCID

**Used By**:

---

## Position Status {#position-status}

**Definition**: Tracks the outcome of position creation after a trading order is filled in a recurring investment cycle. Indicates whether the resulting position was successfully opened or encountered issues.

**Source Table**: `Dictionary.PositionStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Success | Position was successfully opened after order fill |
| 2 | Failed | Position opening failed (see PositionFailErrorCode for details) |
| 3 | InProgress | Position is being created/processed - not yet final |
| 4 | Unknown | Position status cannot be determined (data gap or system issue) |
| 6 | NoPositionOrderCanceledByUser | No position exists because the user cancelled the order before execution |
| 7 | NoPositionOrderExpiredOrCanceledByEtoro | No position exists because the order expired or was cancelled by eToro |

**Key Characteristics**:
- Gap in IDs (no 5) suggests a deprecated or reserved status
- Terminal success: Success (1)
- Terminal failure: Failed (2), NoPositionOrderCanceledByUser (6), NoPositionOrderExpiredOrCanceledByEtoro (7)
- Non-terminal: InProgress (3), Unknown (4)
- Statuses 6 and 7 explicitly link position absence to order cancellation reasons

**Used By**:

---

## Business Concepts

*No concept-based terms yet. Will be populated as objects are documented.*
