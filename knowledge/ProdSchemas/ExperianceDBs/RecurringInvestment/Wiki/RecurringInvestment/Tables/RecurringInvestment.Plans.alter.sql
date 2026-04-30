-- =============================================================================
-- Databricks ALTER Script: bronze RecurringInvestment.RecurringInvestment.Plans
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.Plans.md
-- Layer: bronze
-- UC Target: main.general.bronze_recurringinvestment_recurringinvestment_plans
-- =============================================================================

-- ---- UC Target: main.general.bronze_recurringinvestment_recurringinvestment_plans (business_group=general) ----
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans SET TBLPROPERTIES (
    'comment' = 'Core table storing recurring investment plan subscriptions - each row is a user''s automated investment configuration for a specific instrument or copy target. Source: RecurringInvestment.RecurringInvestment.Plans on the RecurringInvestment production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.Plans.md).'
);

ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringInvestment',
    'source_schema' = 'RecurringInvestment',
    'source_table' = 'Plans',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN ID COMMENT 'Unique auto-incrementing identifier for the recurring investment plan. Primary key. Users can have multiple plans (since Phase 0.5 per Confluence). (Source: Confluence) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN GCID COMMENT 'Global Customer ID - unique identifier of the eToro user who owns this plan. A user can have multiple active plans for different instruments. (Source: Confluence) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN CID COMMENT 'Customer ID - alternate unique identifier of the user. Both GCID and CID identify the same user in different systems. (Source: Confluence) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN InstrumentID COMMENT 'ID of the specific instrument (stock, ETF, crypto) for Instrument-type plans (PlanType=1). NULL for Copy-type plans (PlanType=2) which use CopyParentCID instead. A user cannot have more than one active plan for the same InstrumentID (unique filtered index). (Source: Confluence) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN RecurringDepositID COMMENT 'ID of the Recurring Deposit Plan from MIMO/Money Group that this investment plan is linked to. All of a user''s active investment plans are linked to the same recurring deposit program. More details in Billing DB [Recurring].[Payment]. (Source: Confluence) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN Amount COMMENT 'Investment amount per cycle in the plan''s CurrencyID. For example, if CurrencyID=2 (EUR) and Amount=50, the user invests 50 EUR per cycle. (Source: Confluence) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN CurrencyID COMMENT 'Currency of the plan''s Amount. Based on [etoro].[Dictionary].[Currency] (external DB). When CurrencyID is USD, Amount equals AmountUsd. (Source: Confluence) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN PlanStatusID COMMENT 'Lifecycle state of the plan: 0=Initializing (failed creation), 1=Active (operational), 2=Cancelled (terminal), 3=Stopped (unused), 4=Invalid (unused). Only Active (1) plans generate instances. See Plan Status. (Dictionary.PlanStatus) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN DepositPlanStatusID COMMENT 'DEPRECATED - marked for deletion per Confluence. Status of the linked recurring deposit plan. Being phased out as this tracking moves to the Money Group system. (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN StatusReasonID COMMENT 'Reason for the current plan status. Maps to Dictionary.PlanEventCode (e.g., 100=CreatePlanSuccess, 700=CancelPlanByUser, 300=DepositPlanCancelled). See Plan Event Code. (Source: Confluence) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN CreationDate COMMENT 'When the plan was created. Auto-set to current UTC time on creation. (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN EndDate COMMENT 'When the plan was cancelled. NULL for active plans. Set when PlanStatusID changes to 2 (Cancelled). (Source: Confluence: "An active plan will be EndDate = NULL") (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN DepositStartDate COMMENT 'When the plan''s first deposit occurred or is scheduled. Auto-defaults to creation time. (Source: Confluence) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN FrequencyID COMMENT 'Execution cadence: 3=Monthly (only active frequency). Weekly (1) and BiWeekly (2) exist but are not in use. See Plan Frequencies. (Dictionary.PlanFrequencies) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN RepeatsOn COMMENT 'Day of the month when the plan executes (1-28). For monthly frequency, this is the calendar day the deposit and order occur. Most plans use 1 (first of month). (Source: Confluence: "The date when the plan is executed") (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN FundingID COMMENT 'ID of the plan''s payment method in the billing system. (Source: Confluence: "The ID of the plan''s payment method") (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN Trace COMMENT 'Computed audit column: JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName. (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN ValidFrom COMMENT 'System-versioned period start. (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN ValidTo COMMENT 'System-versioned period end. (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN PlanType COMMENT 'Fundamental plan classification: 1=Instrument (direct investment), 2=Copy (copy trading). Determines which columns are relevant and which execution path is used. See Plan Type. (Dictionary.PlanType) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN CopyParentCID COMMENT 'CID of the trader being copied. Only set for Copy-type plans (PlanType=2). NULL for Instrument-type plans. (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN CopyParentGCID COMMENT 'GCID of the trader being copied. Used with CopyParentCID for unique identification. Part of the unique filtered index for active plans. (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN CopyType COMMENT 'Copy trading relationship type: 0=None (instrument plan), 1=PI (Popular Investor), 4=SmartPortfolio. See Copy Type. (Dictionary.CopyType) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN HasBackupPayment COMMENT 'Whether the plan has a fallback payment method configured. Used for deposit resilience. (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN MopType COMMENT 'Method of Payment type for the plan''s deposits. Defaults to 1. See MOP Type. (Dictionary.MopType) (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
ALTER TABLE main.general.bronze_recurringinvestment_recurringinvestment_plans ALTER COLUMN AmountUsd COMMENT 'Investment amount per cycle converted to USD. Equals Amount when CurrencyID is USD. Used for USD-normalized reporting and calculations. (Tier 1 - upstream wiki, RecurringInvestment.RecurringInvestment.Plans)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-04-30 08:48:09 UTC
-- Bronze deploy: RecurringInvestment batch 1
-- ====================
