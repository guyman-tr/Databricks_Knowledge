-- =============================================================================
-- Databricks ALTER Script: bronze RecurringManager.Scheduler.Execution
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md
-- Layer: bronze
-- UC Target: main.billing.bronze_recurringmanager_scheduler_execution
-- =============================================================================

-- ---- UC Target: main.billing.bronze_recurringmanager_scheduler_execution (business_group=billing) ----
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution SET TBLPROPERTIES (
    'comment' = 'Tracks every individual payment execution attempt within a recurring plan, recording its lifecycle from initial scheduling through processing to completion or cancellation. Source: RecurringManager.Scheduler.Execution on the RecurringManager production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Execution.md).'
);

ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringManager',
    'source_schema' = 'Scheduler',
    'source_table' = 'Execution',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution ALTER COLUMN ExecutionId COMMENT 'Auto-incrementing primary key. ~856K rows exist. Referenced in GetExecutionByPaymentExecution, GetExecutionsForPlan, UpdateExecutionPlannedDate, RevertExecution, and alert procedures. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Execution)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution ALTER COLUMN PlanId COMMENT 'FK to Scheduler.Plan.PlanId. Links this execution to its parent schedule. Indexed with ExecutionStatusId and ExecutionTypeId for efficient lookups. Each plan generates one execution per billing cycle. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Execution)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution ALTER COLUMN PaymentExecutionId COMMENT 'Cross-schema FK to the payment execution record in the Recurring schema. One-to-one relationship per execution attempt. Used by GetExecutionByPaymentExecution for reverse lookups. The unique filtered index UQ_Scheduler_Execution ensures only one active (status=1) execution exists per PaymentExecutionId + ExecutionTypeId combination. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Execution)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution ALTER COLUMN PlannedDate COMMENT 'UTC timestamp of when this execution should be processed. Set during creation based on the plan''s frequency, start date, and charging day. Used by GetExecutionsToProcessWithLock''s WHERE clause (PlannedDate < GETUTCDATE()) to pick up due executions. Can be modified by UpdateExecutionPlannedDate when rescheduling. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Execution)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution ALTER COLUMN ExecutionTypeId COMMENT 'Classification of execution attempt: 1=Planned (regular scheduled charge), 2=Dunning (retry after soft decline). Currently 100% of rows are Planned. Filtered by GetExecutionsToProcessWithLock and SetStampForExecutionsWithLock. See Execution Type. (Dictionary.ExecutionType) (Tier 1 - upstream wiki, RecurringManager.Scheduler.Execution)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution ALTER COLUMN ExecutionStatusId COMMENT 'Lifecycle state: 1=Planned (1.9%), 2=WaitingForProcess, 3=Sent (0.01%), 4=Canceled (12.6%), 5=Failed (0.003%), 6=Done (85.4%). Heavily indexed across 5 indexes. UpdateExecutionsStatus refuses to update rows in status 4 or 6 (terminal states). See Execution Status. (Dictionary.ExecutionStatus) (Tier 1 - upstream wiki, RecurringManager.Scheduler.Execution)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution ALTER COLUMN CreateDate COMMENT 'UTC timestamp of when the execution record was created, set to GETDATE() in CreateOrGetExecution. Distinct from PlannedDate (when it should run) and ActualExecutionDate (when it was actually picked up). (Tier 1 - upstream wiki, RecurringManager.Scheduler.Execution)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution ALTER COLUMN Stamp COMMENT 'Distributed lock token. NULL = unclaimed and available for processing. Set to a GUID by GetExecutionsToProcessWithLock/SetStampForExecutionsWithLock to claim ownership. Prevents duplicate processing across multiple RecurringScheduler worker pods. 14.5% NULL (unclaimed: Planned + Canceled-before-processing). (Tier 1 - upstream wiki, RecurringManager.Scheduler.Execution)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution ALTER COLUMN ActualExecutionDate COMMENT 'UTC timestamp of when the execution was actually picked up for processing (not when the charge completed). Set to GETUTCDATE() simultaneously with Stamp by the lock procedures. NULL = not yet processed (7%). Indexed for alert queries that detect stuck executions. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Execution)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution ALTER COLUMN SysStartTime COMMENT 'System-versioning row start time. Automatically managed by SQL Server temporal tables. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Execution)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution ALTER COLUMN SysEndTime COMMENT 'System-versioning row end time. 9999-12-31 = current version. Previous versions stored in History.Execution. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Execution)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution ALTER COLUMN RecurringProgramTypeId COMMENT 'Program classification: 1=RecurringDeposit, 2=RecurringInvestment. NULL for 52% of rows (legacy - column added after initial launch). Routes execution results to the correct downstream handler. See Recurring Program Type. (Dictionary.RecurringProgramType) (Tier 1 - upstream wiki, RecurringManager.Scheduler.Execution)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_execution ALTER COLUMN VersionStamp COMMENT 'Optimistic concurrency token for planned date modifications. Set by UpdateExecutionPlannedDate, checked by RevertExecution before reverting. NULL for 99.4% of rows. Non-NULL indicates the execution''s PlannedDate was rescheduled and the VersionStamp identifies the modification version. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Execution)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:40:10 UTC
-- Bronze deploy: RecurringManager batch 1
-- ====================
