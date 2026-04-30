-- =============================================================================
-- Databricks ALTER Script: bronze RecurringInvestment.History.RecurringInvestmentPlans
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans SET TBLPROPERTIES (
    'comment' = 'System-versioned temporal history table storing previous row versions from RecurringInvestment.Plans - tracks the full history of every plan modification including amount changes, status changes, and cancellations. Source: RecurringInvestment.History.RecurringInvestmentPlans on the RecurringInvestment production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md).'
);

ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringInvestment',
    'source_schema' = 'History',
    'source_table' = 'RecurringInvestmentPlans',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN ID COMMENT 'Same as parent table RecurringInvestment.Plans.ID. Unique identifier for the recurring investment plan. Not an identity column in the history table. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN GCID COMMENT 'Same as parent table RecurringInvestment.Plans.GCID. Global Customer ID of the user who owns this plan. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN CID COMMENT 'Same as parent table RecurringInvestment.Plans.CID. Customer ID - alternate user identifier. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN InstrumentID COMMENT 'Same as parent table RecurringInvestment.Plans.InstrumentID. ID of the instrument for Instrument-type plans (PlanType=1). NULL for Copy-type plans. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN RecurringDepositID COMMENT 'Same as parent table RecurringInvestment.Plans.RecurringDepositID. ID of the linked Recurring Deposit Plan from MIMO/Money Group. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN Amount COMMENT 'Same as parent table RecurringInvestment.Plans.Amount. Investment amount per cycle in the plan''s CurrencyID at the time this row version was current. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN CurrencyID COMMENT 'Same as parent table RecurringInvestment.Plans.CurrencyID. Currency of the plan''s Amount. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN PlanStatusID COMMENT 'Same as parent table RecurringInvestment.Plans.PlanStatusID. Lifecycle state: 0=Initializing, 1=Active, 2=Cancelled. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN DepositPlanStatusID COMMENT 'Same as parent table RecurringInvestment.Plans.DepositPlanStatusID. DEPRECATED. Status of the linked recurring deposit plan. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN StatusReasonID COMMENT 'Same as parent table RecurringInvestment.Plans.StatusReasonID. Reason for the plan status at this point in time. Maps to Dictionary.PlanEventCode. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN CreationDate COMMENT 'Same as parent table RecurringInvestment.Plans.CreationDate. When the plan was originally created. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN EndDate COMMENT 'Same as parent table RecurringInvestment.Plans.EndDate. When the plan was cancelled. NULL while active. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN DepositStartDate COMMENT 'Same as parent table RecurringInvestment.Plans.DepositStartDate. When the plan''s first deposit occurred or was scheduled. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN FrequencyID COMMENT 'Same as parent table RecurringInvestment.Plans.FrequencyID. Execution cadence: 3=Monthly. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN RepeatsOn COMMENT 'Same as parent table RecurringInvestment.Plans.RepeatsOn. Day of the month when the plan executes (1-28). (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN FundingID COMMENT 'Same as parent table RecurringInvestment.Plans.FundingID. ID of the plan''s payment method. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN Trace COMMENT 'Same as parent table RecurringInvestment.Plans.Trace, but stored as nvarchar(733) NOT computed (unlike the parent''s computed column). Contains JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName captured at the time the row was current. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN ValidFrom COMMENT 'Period start - the point in time when this row version became the "current" version in the parent table. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN ValidTo COMMENT 'Period end - the point in time when this row version was superseded by an update or deleted from the parent table. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN PlanType COMMENT 'Same as parent table RecurringInvestment.Plans.PlanType. Plan classification: 1=Instrument, 2=Copy. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN CopyParentCID COMMENT 'Same as parent table RecurringInvestment.Plans.CopyParentCID. CID of the trader being copied. NULL for Instrument-type plans. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN CopyParentGCID COMMENT 'Same as parent table RecurringInvestment.Plans.CopyParentGCID. GCID of the trader being copied. NULL for Instrument-type plans. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN CopyType COMMENT 'Same as parent table RecurringInvestment.Plans.CopyType. Copy relationship type: 0=None, 1=PI, 4=SmartPortfolio. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN HasBackupPayment COMMENT 'Same as parent table RecurringInvestment.Plans.HasBackupPayment. Whether the plan has a fallback payment method. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN MopType COMMENT 'Same as parent table RecurringInvestment.Plans.MopType. Method of Payment type for deposits. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';
ALTER TABLE main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ALTER COLUMN AmountUsd COMMENT 'Same as parent table RecurringInvestment.Plans.AmountUsd. Investment amount per cycle in USD. (Tier 1 - upstream wiki, RecurringInvestment.History.RecurringInvestmentPlans)';

