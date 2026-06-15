-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_recurringinvestment_recurringinvestment_plans  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.Plans.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN ID COMMENT 'Unique auto-incrementing identifier for the recurring investment plan. Primary key. Users can have multiple plans (since Phase 0.5 per Confluence). (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN GCID COMMENT 'Global Customer ID - unique identifier of the eToro user who owns this plan. A user can have multiple active plans for different instruments. (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN CID COMMENT 'Customer ID - alternate unique identifier of the user. Both GCID and CID identify the same user in different systems. (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN InstrumentID COMMENT 'ID of the specific instrument (stock, ETF, crypto) for Instrument-type plans (PlanType=1). NULL for Copy-type plans (PlanType=2) which use CopyParentCID instead. A user cannot have more than one active plan for the same InstrumentID (unique filtered index). (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN RecurringDepositID COMMENT 'ID of the Recurring Deposit Plan from MIMO/Money Group that this investment plan is linked to. All of a user''s active investment plans are linked to the same recurring deposit program. More details in Billing DB [Recurring].[Payment]. (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN Amount COMMENT 'Investment amount per cycle in the plan''s CurrencyID. For example, if CurrencyID=2 (EUR) and Amount=50, the user invests 50 EUR per cycle. (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN CurrencyID COMMENT 'Currency of the plan''s Amount. Based on [etoro].[Dictionary].[Currency] (external DB). When CurrencyID is USD, Amount equals AmountUsd. (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN PlanStatusID COMMENT 'Lifecycle state of the plan: 0=Initializing (failed creation), 1=Active (operational), 2=Cancelled (terminal), 3=Stopped (unused), 4=Invalid (unused). Only Active (1) plans generate instances. See [Plan Status](../../_glossary.md#plan-status). (Dictionary.PlanStatus)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN DepositPlanStatusID COMMENT 'DEPRECATED - marked for deletion per Confluence. Status of the linked recurring deposit plan. Being phased out as this tracking moves to the Money Group system.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN StatusReasonID COMMENT 'Reason for the current plan status. Maps to Dictionary.PlanEventCode (e.g., 100=CreatePlanSuccess, 700=CancelPlanByUser, 300=DepositPlanCancelled). See [Plan Event Code](../../_glossary.md#plan-event-code). (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN CreationDate COMMENT 'When the plan was created. Auto-set to current UTC time on creation.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN EndDate COMMENT 'When the plan was cancelled. NULL for active plans. Set when PlanStatusID changes to 2 (Cancelled). (Source: Confluence: "An active plan will be EndDate = NULL")';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN DepositStartDate COMMENT 'When the plan''s first deposit occurred or is scheduled. Auto-defaults to creation time. (Source: Confluence)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN FrequencyID COMMENT 'Execution cadence: 3=Monthly (only active frequency). Weekly (1) and BiWeekly (2) exist but are not in use. See [Plan Frequencies](../../_glossary.md#plan-frequencies). (Dictionary.PlanFrequencies)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN RepeatsOn COMMENT 'Day of the month when the plan executes (1-28). For monthly frequency, this is the calendar day the deposit and order occur. Most plans use 1 (first of month). (Source: Confluence: "The date when the plan is executed")';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN FundingID COMMENT 'ID of the plan''s payment method in the billing system. (Source: Confluence: "The ID of the plan''s payment method")';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN ValidFrom COMMENT 'System-versioned period start.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN ValidTo COMMENT 'System-versioned period end.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN PlanType COMMENT 'Fundamental plan classification: 1=Instrument (direct investment), 2=Copy (copy trading). Determines which columns are relevant and which execution path is used. See [Plan Type](../../_glossary.md#plan-type). (Dictionary.PlanType)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN CopyParentCID COMMENT 'CID of the trader being copied. Only set for Copy-type plans (PlanType=2). NULL for Instrument-type plans.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN CopyParentGCID COMMENT 'GCID of the trader being copied. Used with CopyParentCID for unique identification. Part of the unique filtered index for active plans.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN CopyType COMMENT 'Copy trading relationship type: 0=None (instrument plan), 1=PI (Popular Investor), 4=SmartPortfolio. See [Copy Type](../../_glossary.md#copy-type). (Dictionary.CopyType)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN HasBackupPayment COMMENT 'Whether the plan has a fallback payment method configured. Used for deposit resilience.';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN MopType COMMENT 'Method of Payment type for the plan''s deposits. Defaults to 1. See [MOP Type](../../_glossary.md#mop-type). (Dictionary.MopType)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN AmountUsd COMMENT 'Investment amount per cycle converted to USD. Equals Amount when CurrencyID is USD. Used for USD-normalized reporting and calculations.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:22:24 UTC
-- Statements: 25/25 succeeded
-- ====================
