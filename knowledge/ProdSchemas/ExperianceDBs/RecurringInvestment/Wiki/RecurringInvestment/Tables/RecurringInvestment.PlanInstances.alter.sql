-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_recurringinvestment_recurringinvestment_planinstances  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.PlanInstances.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN InstanceID COMMENT 'Unique auto-incrementing surrogate key for the instance. Used for application lookups. Not part of PK (PK is PlanID+NextOrderDate). (Source: Confluence: "Unique identifier for the recurring investment plan that triggered the open position")';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN PlanID COMMENT 'FK to Plans.ID. Identifies which plan this instance belongs to. Part of composite PK. (Source: Confluence: "Same ID as [RecurringInvestment].[Plans].ID")';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN NextOrderDate COMMENT 'Scheduled execution date for this instance. Part of composite PK. Calculated by Plan Instances Job based on FrequencyID and RepeatsOn. (Source: Confluence: "The upcoming date of the next execution")';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN CreationDate COMMENT 'When this instance record was created by the Plan Instances Job.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN DepositID COMMENT 'Deposit identifier from Money ServiceBus. References Billing DB [Recurring].[Payment]. Also appears in UserDeposits table. (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN DepositAmountUsd COMMENT 'DEPRECATED - marked for deletion per Confluence. Deposit amount in USD. Data sourced from Billing DB via Money ServiceBus.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN DepositAmountCurrency COMMENT 'DEPRECATED - marked for deletion per Confluence. Deposit amount in plan currency.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN DepositCycleNumber COMMENT 'Deposit cycle number from Billing system. Identifies which recurring deposit cycle this instance corresponds to. (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN DepositDate COMMENT 'When the deposit was made or attempted. Source: Billing DB via Money ServiceBus. (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN HighLevelDepositStatusId COMMENT 'High-level deposit outcome: 1=Success, 2=SoftDecline, 3=HardDecline. Source: [Dictionary].[ExecutionResultStatus] in Billing DB per Confluence. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status).';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN DepositStatusID COMMENT 'Detailed deposit status from Billing DB PaymentStatusId enum. More granular than HighLevelDepositStatusId. (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN OrderStatusId COMMENT 'Order lifecycle state from Trading API enum: 1=Received, 2=Placed, 3=Filled, 4=Rejected...11=WaitingForMarket. See [Order Status](../../_glossary.md#order-status). (Dictionary.OrderStatus) (Source: Confluence confirms Trading enum)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN OrderID COMMENT 'Order identifier from Trading API (TAPI). The ID of the request to open a position before it was opened. (Source: Confluence: "this value is from TAPI")';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN OrderTradeDate COMMENT 'The time that the order needs to be requested from Trading API. Indexed for efficient order processing. (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN PositionStatus COMMENT 'Position creation outcome: 1=Success, 2=Failed, 3=InProgress, 4=Unknown, 6=CanceledByUser, 7=ExpiredOrCanceledByEtoro. See [Position Status](../../_glossary.md#position-status). (Dictionary.PositionStatus)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN PositionAmountUsd COMMENT 'Actual position amount in USD. May differ from plan Amount due to partial fills or market conditions.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN PositionAmountCurrency COMMENT 'Actual position amount in the plan''s currency.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN PositionExecutionDate COMMENT 'When the position was actually opened. (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN PositionFailErrorCode COMMENT 'Error code from Trading API''s TradingOpenPositionErrorCodes enum when position open fails. (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN NotificationSent COMMENT 'DEPRECATED - marked for deletion per Confluence. Flag indicating if a notification was sent to the client.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN NotificationReason COMMENT 'DEPRECATED - marked for deletion per Confluence. Reason for notification, based on PlanEventCode.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN InstanceStatus COMMENT 'DEPRECATED - marked for deletion per Confluence. Legacy done flag: 1=Done, NULL=not done. Replaced by InstanceStatusID.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN UpdateDate COMMENT 'Last modification timestamp for this instance record.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN ValidFrom COMMENT 'System-versioned period start.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN ValidTo COMMENT 'System-versioned period end.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN InstanceStatusReasonID COMMENT 'Specific reason for the instance''s final status. Maps to Dictionary.PlanEventCode ("same as PlanEventCode" per Confluence). See [Plan Event Code](../../_glossary.md#plan-event-code).';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN InstanceStatusID COMMENT 'Instance lifecycle state: 1=Success, 2=Cancelled, 3=Skipped, 4=UserSkipped, 5=InProgress, 6=Technical Issue, 7=Completed without position. See [Instance Status](../../_glossary.md#instance-status). (Dictionary.InstanceStatusID)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN MirrorOrderCreated COMMENT 'Copy trading flag: 1=TRUE when mirror order was initiated. NULL for instrument-type plans. See [Mirror Order Created](../../_glossary.md#mirror-order-created).';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN MirrorID COMMENT 'ID of the mirror/copy relationship for copy trading instances. NULL for instrument-type plans.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN CopyPositionStatusID COMMENT 'Copy position creation step: 1=RegisterSuccess, 2=AddFundsSuccess, 3=RegisterFailed, 4=AddFundFailed. NULL for instrument-type plans. See [Copy Position Status](../../_glossary.md#copy-position-status).';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN CopyFailErrorCode COMMENT 'Error code for copy position failures. NULL for instrument-type plans. See [Copy Fail Error Code](../../_glossary.md#copy-fail-error-code).';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_planinstances ALTER COLUMN DepositFailReason COMMENT 'Reason for deposit failure when applicable.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:21:15 UTC
-- Statements: 32/32 succeeded
-- ====================
