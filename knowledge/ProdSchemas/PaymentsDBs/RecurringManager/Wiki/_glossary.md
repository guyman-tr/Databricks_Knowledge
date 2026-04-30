# Business Glossary - RecurringManager

> Canonical definitions for business terms, value domains, and concepts.
> Object docs reference this glossary for shared terminology.
> Terms are progressively enriched as more objects are documented.

*Last updated: 2026-04-16 | Terms: 13 lookup-backed, 0 concept-based | Sources: 13 Dictionary tables, 13 object docs*

---

## Lookup-Backed Terms

## Entity Type {#entity-type}

**Definition**: Classifies the type of entity involved in a recurring payment lifecycle event. Distinguishes between the overarching payment container and an individual execution attempt within that payment.

**Source Table**: `Dictionary.EntityType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Payment | The parent recurring payment record representing the user's recurring payment instruction as a whole |
| 2 | PaymentExecution | A single execution attempt within a recurring payment - one scheduled charge cycle |

**Key Characteristics**:
- Only 2 values - a simple parent/child entity classification
- Used to distinguish context when logging, auditing, or routing events that can apply to either the plan-level payment or a specific execution attempt

**Used By**: Scheduler.Execution, Scheduler.Job

---

## Execution Result Status {#execution-result-status}

**Definition**: Classifies the outcome of a payment execution attempt after it has been processed by the billing/payment provider. Determines whether the execution succeeded, encountered a recoverable issue, or hit a terminal failure.

**Source Table**: `Dictionary.ExecutionResultStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Success | Payment was processed and approved by the provider - funds will be collected |
| 2 | SoftDecline | Provider declined the charge but the reason is potentially recoverable (e.g., insufficient funds, temporary hold) - eligible for dunning/retry |
| 3 | HardDecline | Provider permanently declined the charge (e.g., card expired, account closed, fraud) - no retry should be attempted |

**Key Characteristics**:
- Drives the dunning/retry logic: SoftDecline triggers re-attempts, HardDecline terminates the execution
- Maps directly to payment provider response codes aggregated into three buckets
- HardDecline also appears as a StatusReason (ID=5), linking execution outcome to plan-level status changes

**Used By**: (Not directly referenced by Scheduler schema objects)

---

## Execution Status {#execution-status}

**Definition**: Tracks the lifecycle state of a single scheduled execution record in the Scheduler schema. Represents the progression from initial scheduling through processing to final resolution.

**Source Table**: `Dictionary.ExecutionStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Planned | Execution has been created and scheduled for a future date - not yet picked up for processing |
| 2 | WaitingForProcess | Execution has been stamped/locked and is queued for the processing worker to pick up |
| 3 | Sent | Execution has been dispatched to the billing/payment provider and is awaiting a response |
| 4 | Canceled | Execution was canceled before it could be processed (e.g., plan was stopped or user opted out) |
| 5 | Failed | Execution encountered an error during processing that prevented it from completing |
| 6 | Done | Execution has completed processing - the result (success or decline) is recorded separately in ExecutionResultStatus |

**Key Characteristics**:
- Used by Scheduler.Execution table and indexed heavily for query performance
- Status 1 (Planned) is the initial state; Scheduler.SetStampForExecutionsWithLock stamps Planned executions to transition to WaitingForProcess
- Status 6 (Done) does not imply payment success - the actual outcome is in ExecutionResultStatus
- Scheduler.GetExecutionsToProcessWithLock filters by this status to pick up work
- Scheduler.RevertExecution can move an execution back to an earlier state

**Used By**: Scheduler.Execution, Scheduler.Alert_PlanedDatePassed_NotTaken, Scheduler.Alert_StuckWithNotValidStatus, Scheduler.DD_Alert_PlanedDatePassed_NotTaken, Scheduler.DD_Alert_StuckWithNotValidStatus, Scheduler.GetExecutionsToProcessWithLock, Scheduler.SetStampForExecutionsWithLock, Scheduler.UpdateExecutionsStatus

---

## Execution Type {#execution-type}

**Definition**: Classifies whether a scheduled execution is a regular planned charge or a dunning (retry) attempt following a previous soft decline. Determines which processing path the execution follows.

**Source Table**: `Dictionary.ExecutionType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Planned | A regularly scheduled execution based on the plan's frequency - the normal charge cycle |
| 2 | Dunning | A retry execution created after a previous attempt was soft-declined - part of the recovery/dunning process |

**Key Characteristics**:
- Core branching dimension: many scheduler stored procedures accept @ExecutionTypeId to filter processing
- Scheduler.Execution has multiple indexes including ExecutionTypeId for efficient filtering
- Scheduler.GetPlansWithLastAndNextExecutions specifically filters ExecutionTypeId=1 for planned executions
- Scheduler.CreateOrGetExecution accepts this as a parameter when creating new execution records
- Maps 1:1 to JobType (Recurring=Planned, Dunning=Dunning) but at the execution level vs. the job level

**Used By**: Scheduler.Execution, Scheduler.CreateOrGetExecution, Scheduler.GetExecutionsToProcessWithLock, Scheduler.GetLastExecutionForPlan, Scheduler.SetStampForExecutionsWithLock

---

## Frequency {#frequency}

**Definition**: Defines the recurring cadence at which a payment plan executes. Determines the interval between successive planned execution dates.

**Source Table**: `Dictionary.Frequency`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Weekly | Plan executes once every 7 days |
| 2 | BiWeekly | Plan executes once every 14 days |
| 3 | Monthly | Plan executes once per calendar month |

**Key Characteristics**:
- Drives the scheduling engine's date calculation for next execution
- Only 3 frequencies supported - no daily, quarterly, or annual options
- Monthly is likely the most common for deposit and investment use cases

**Used By**: Scheduler.Plan, Scheduler.CreateOrGetPlan, Scheduler.UpdatePlan, Scheduler.GetPlansWithLastAndNextExecutions

---

## Job Type {#job-type}

**Definition**: Classifies the type of scheduler job being executed. Determines which processing pipeline the job follows - regular recurring payment processing or dunning/retry processing.

**Source Table**: `Dictionary.JobType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Recurring | A regular scheduled job that processes planned executions on their due dates |
| 2 | Dunning | A retry job that processes soft-declined executions, attempting to recover failed payments |

**Key Characteristics**:
- Used by Scheduler.Job to classify the job instance
- Mirrors ExecutionType at the job level - Recurring jobs create Planned executions, Dunning jobs create Dunning executions
- Two distinct processing pipelines likely run on different schedules or with different batch sizes

**Used By**: Scheduler.Job

---

## Message Status {#message-status}

**Definition**: Tracks the delivery lifecycle of messages sent within the recurring program messaging system. Used for outbound communications about payment events.

**Source Table**: `Dictionary.MessageStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | New | Message has been created but not yet dispatched to the delivery service |
| 2 | Sent | Message has been successfully delivered to the messaging service |
| 3 | Failed | Message delivery failed - the messaging service could not process or deliver the message |

**Key Characteristics**:
- Simple 3-state lifecycle: New -> Sent or New -> Failed
- Works in conjunction with RecurringProgramMessageType to classify what kind of message is being tracked
- No retry state - failed messages may need manual intervention or a separate retry mechanism

**Used By**:

---

## Notification Status {#notification-status}

**Definition**: Tracks the lifecycle of notifications sent to external services (e.g., push notifications, emails, or webhook callbacks) about recurring payment events. More granular than MessageStatus, with explicit states for service integration.

**Source Table**: `Dictionary.NotificationStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Created | Notification record has been created but processing has not started |
| 2 | InProgress | Notification is actively being prepared or processed for delivery |
| 3 | SentToService | Notification was successfully handed off to the external notification service |
| 4 | SentToServiceFailed | Attempt to deliver the notification to the external service failed |
| 5 | Canceled | Notification was canceled before delivery (e.g., the triggering event was reversed) |
| 6 | LateCancellation | Notification was canceled after processing had already begun - may have partially been delivered |

**Key Characteristics**:
- Used by both Recurring.Notification and History.Notification tables
- Default value is 1 (Created) as defined by DF_Recurring_Notification_Status constraint
- Distinguishes between Canceled (timely) and LateCancellation (after processing started) - important for audit and reconciliation
- 6-state lifecycle is more granular than MessageStatus (3 states), suggesting notifications are a different delivery channel

**Used By**:

---

## Payment Execution Status {#payment-execution-status}

**Definition**: Tracks the end-to-end lifecycle of a single payment execution attempt within the Recurring schema. Covers the full journey from initial planning through billing provider interaction to final resolution. This is the most granular payment-level status in the system.

**Source Table**: `Dictionary.PaymentExecutionStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Planned | Execution is scheduled for a future date - not yet submitted for processing |
| 2 | InProcess | Execution has been picked up by the processing engine and is actively being handled |
| 3 | SentToBilling | Execution has been submitted to the external billing/payment provider |
| 4 | SendToBillingFailed | Submission to the billing provider failed (network error, validation failure, etc.) |
| 5 | SoftDeclined | Billing provider declined the charge with a recoverable reason - eligible for dunning retry |
| 6 | HardDeclined | Billing provider permanently declined the charge - no further retries |
| 7 | Approved | Billing provider approved the charge - funds will be collected |
| 8 | Cancelled | Execution was canceled before reaching the billing provider |
| 9 | Skipped | Execution was intentionally skipped (e.g., a duplicate cycle or manual override) |
| 10 | Retry | Execution is marked for retry - will be re-attempted in the next dunning cycle |

**Key Characteristics**:
- 10-state lifecycle covering the full payment execution journey
- Referenced by Recurring.UpdatePaymentExecutionStatus stored procedure (granted to multiple pod identities)
- Terminal states: HardDeclined (6), Approved (7), Cancelled (8), Skipped (9)
- Transitional states: Planned (1) -> InProcess (2) -> SentToBilling (3) -> Approved/Declined
- SoftDeclined (5) -> Retry (10) -> back to processing via dunning
- PK constraint name "PK_Dictionary_CycleStatus" reveals this was originally called CycleStatus - renamed to PaymentExecutionStatus

**Used By**:

---

## Plan Status {#plan-status}

**Definition**: Represents the lifecycle state of a recurring payment plan - the top-level entity that governs whether executions continue to be scheduled. Controls whether the scheduling engine creates new execution records. In the History schema, StatusId on History.Payment maps to this dictionary.

**Source Table**: `Dictionary.PlanStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Active | Plan is running normally - new executions will be scheduled according to the plan's frequency |
| 2 | Cancelled | Plan has been permanently terminated - no further executions will be created |
| 3 | Stopped | Plan has been stopped (possibly due to repeated failures or system action) - differs from Cancelled in that it may be system-initiated |
| 4 | Invalid | Plan configuration is invalid or has become invalid (e.g., removed payment method, regulatory restriction) - cannot process |
| 5 | Paused | Plan is temporarily suspended - can be resumed to Active state without recreating the plan |

**Key Characteristics**:
- Only Active (1) plans generate new scheduled executions
- Paused (5) is the only reversible non-active state - designed for temporary holds
- Cancelled (2) vs Stopped (3) distinction likely reflects user-initiated vs system-initiated termination (see StatusReason for causality)
- Invalid (4) suggests automated validation catches configuration problems

**Used By**:

---

## Recurring Program Message Type {#recurring-program-message-type}

**Definition**: Classifies the type of message sent within the recurring program messaging system. Determines the content template and routing of the message.

**Source Table**: `Dictionary.RecurringProgramMessageType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | PaymentExecutionResult | Message communicating the outcome of a payment execution (success, decline, etc.) to downstream consumers |
| 2 | RecurringProgramStatus | Message communicating a change in the recurring program's overall status (activated, paused, cancelled, etc.) |

**Key Characteristics**:
- Two message categories: execution-level events (per-cycle results) and program-level events (plan lifecycle changes)
- Works with MessageStatus to track delivery lifecycle of each message type
- Likely consumed by notification services, analytics, or customer-facing communication systems

**Used By**: (Not directly referenced by Scheduler schema objects - used in Recurring schema)

---

## Recurring Program Type {#recurring-program-type}

**Definition**: Classifies the type of recurring program a user has enrolled in. Determines the business rules, processing logic, and downstream systems involved in executing the recurring plan.

**Source Table**: `Dictionary.RecurringProgramType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | RecurringDeposit | User has set up automatic recurring deposits into their account - funds are added on a schedule |
| 2 | RecurringInvestment | User has set up automatic recurring investments - funds are deposited and then allocated to specific instruments/portfolios |

**Key Characteristics**:
- Core business domain classifier for the entire RecurringManager database
- RecurringInvestment is a superset of RecurringDeposit (deposit + invest), likely involving coordination with the RecurringInvestment database
- Used by Scheduler.CreateOrGetExecution as @RecurringProgramTypeId parameter
- Stored on Scheduler.Execution records to route execution results to the correct downstream handler

**Used By**: Scheduler.Execution, Scheduler.CreateOrGetExecution

---

## Status Reason {#status-reason}

**Definition**: Provides the specific reason why a recurring plan's status changed. Captures the causality behind status transitions to Active->Cancelled, Active->Stopped, or Active->Invalid states.

**Source Table**: `Dictionary.StatusReason`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | RemovedMOP | User's method of payment (credit card, bank account, etc.) was removed from their account - plan cannot execute without a funding source |
| 2 | CancelledByUser | User explicitly requested cancellation of their recurring plan |
| 3 | CancelledByBO | Back-office/operations team manually cancelled the plan (e.g., compliance, support request, account review) |
| 4 | CanceledInvestment | The underlying investment was canceled - the recurring investment plan is no longer valid |
| 5 | HardDecline | Payment provider permanently declined the charge - plan stopped due to unrecoverable payment failure |

**Key Characteristics**:
- Provides audit trail for why a plan is no longer active
- Distinguishes user-initiated (2), system-initiated (1, 4, 5), and operator-initiated (3) cancellations
- RemovedMOP (1) links to payment method management - likely triggers automatic plan invalidation
- HardDecline (5) connects execution-level failure (ExecutionResultStatus.HardDecline) to plan-level status change
- Note: "CanceledInvestment" (ID=4) uses single-L spelling, inconsistent with "Cancelled" elsewhere

**Used By**:

---

## Business Concepts

*No concept-based terms yet. Will be populated as objects are documented.*
