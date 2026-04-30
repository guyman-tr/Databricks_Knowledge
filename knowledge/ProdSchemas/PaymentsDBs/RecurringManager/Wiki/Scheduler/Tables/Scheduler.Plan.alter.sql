-- =============================================================================
-- Databricks ALTER Script: bronze RecurringManager.Scheduler.Plan
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md
-- Layer: bronze
-- UC Target: main.billing.bronze_recurringmanager_scheduler_plan
-- =============================================================================

-- ---- UC Target: main.billing.bronze_recurringmanager_scheduler_plan (business_group=billing) ----
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_plan SET TBLPROPERTIES (
    'comment' = 'Defines the recurring payment schedule for each user payment instruction, including frequency, start/end dates, and the preferred charging day within the billing cycle. Source: RecurringManager.Scheduler.Plan on the RecurringManager production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Scheduler/Tables/Scheduler.Plan.md).'
);

ALTER TABLE main.billing.bronze_recurringmanager_scheduler_plan SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringManager',
    'source_schema' = 'Scheduler',
    'source_table' = 'Plan',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_plan ALTER COLUMN PlanId COMMENT 'Auto-incrementing primary key uniquely identifying each recurring payment schedule. Referenced by Scheduler.Execution.PlanId to link executions to their parent plan. Currently ~189K plans exist. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Plan)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_plan ALTER COLUMN PaymentId COMMENT 'Foreign key to the Recurring.Payment table identifying which user payment instruction this schedule belongs to. One-to-one relationship enforced by CreateOrGetPlan''s idempotent check. Used as the primary lookup key by GetPlanByPaymentId and SetEndDateForPlanOfPayment. Indexed for fast lookups. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Plan)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_plan ALTER COLUMN FrequencyId COMMENT 'Billing cycle frequency: 1=Weekly (15%), 2=BiWeekly (7%), 3=Monthly (78%). See Frequency for full definitions. Determines how the scheduler calculates the next PlannedDate for each execution. Can be updated via UpdatePlan. (Dictionary.Frequency) (Tier 1 - upstream wiki, RecurringManager.Scheduler.Plan)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_plan ALTER COLUMN StartDate COMMENT 'UTC timestamp of when the first execution should occur. Used by the scheduling engine to calculate subsequent execution dates based on FrequencyId. Set once during plan creation via CreateOrGetPlan. Range: 2021-06-09 to 2026-05-15. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Plan)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_plan ALTER COLUMN StartDateWithUserOffset COMMENT 'ISO 8601 formatted start date preserving the user''s local timezone offset (e.g., "2026-05-10T03:00:00+02:00"). Stored alongside StartDate to prevent timezone conversion ambiguity when displaying the schedule to the user. Never used for scheduling calculations - only for display. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Plan)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_plan ALTER COLUMN EndDate COMMENT 'UTC timestamp when the plan was terminated. NULL = plan is active and generating executions. Set by SetEndDateForPlanOfPayment to GETUTCDATE() when the user cancels or the system stops the plan. 91.2% of plans have EndDate set (ended). Once set, the plan is permanently inactive. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Plan)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_plan ALTER COLUMN SysStartTime COMMENT 'System-versioning row start time. Automatically managed by SQL Server temporal tables. Tracks when this version of the row became current. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Plan)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_plan ALTER COLUMN SysEndTime COMMENT 'System-versioning row end time. Value of 9999-12-31 indicates the current version. When a row is modified, the previous version is moved to History.Plan with SysEndTime set to the modification timestamp. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Plan)';
ALTER TABLE main.billing.bronze_recurringmanager_scheduler_plan ALTER COLUMN ChargingDay COMMENT 'Day of the month (1-28) when the charge should occur for Monthly plans. NULL for 66% of plans (legacy plans created before this column was added, or Weekly/BiWeekly plans where the charge day is derived from StartDate). Can be updated via UpdatePlan if the user changes their preferred billing day. (Tier 1 - upstream wiki, RecurringManager.Scheduler.Plan)';

