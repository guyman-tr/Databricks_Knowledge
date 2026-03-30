-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_FirstCustomerAction
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction SET TBLPROPERTIES (
    'comment' = '`Fact_FirstCustomerAction` captures the milestone moment when a customer performs each type of action for the first time. While `Fact_CustomerAction` logs every action event, this table filters down to only the **first occurrence** per customer per action type. It answers: - "When did this customer make their first deposit?" (ActionTypeID for deposit) - "When was their first trade?" (ActionTypeID for trade) - "What was the funnel conversion path - registration -> first deposit -> first trade?" The table enables: - **Customer funnel analysis** - time between registration and first deposit (FTD), first trade, etc. - **Cohort analysis** - grouping customers by the date of their first key action - **Marketing attribution** - linking first actions to acquisition campaigns via CampaignID - **Lifecycle milestones** - tracking which customers have completed key activation steps ### FirstEver flag The `FirstEver` column distinguishes: - **FirstEver = 1**: This is the absolute first time this customer performed this A...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction SET TAGS (
    'domain' = 'customer',
    'object_type' = 'fact',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(RealCID)',
    'synapse_index' = 'CLUSTERED INDEX (RealCID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN GCID COMMENT 'Global Customer ID - unique cross-platform identifier. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN RealCID COMMENT 'Real-money account Customer ID. Distribution key and clustered index. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN DemoCID COMMENT 'Demo account Customer ID. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN FirstOccurred COMMENT 'Timestamp when this action type was first performed by the customer. Mapped from Fact_CustomerAction.Occurred. (Tier 2 - SP_Fact_FirstCustomerAction)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN IPNumber COMMENT 'IP address (as integer) from which the first action was performed. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN IsReal COMMENT 'Whether the first action was on a Real (1) or Demo (0) account. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN ActionTypeID COMMENT 'Type of customer action (e.g., deposit, trade, withdrawal). JOINs to Dim_ActionType. Part of the business key with GCID. (Tier 2 - SP_Fact_FirstCustomerAction)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN PlatformTypeID COMMENT 'Platform used for the first action (web, iOS, Android). JOINs to Dim_PlatformType. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN InstrumentID COMMENT 'Instrument involved in the first action (for trades). Default 0 = not applicable. JOINs to Dim_Instrument. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN Amount COMMENT 'Monetary amount of the first action (e.g., first deposit amount). (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN PositionID COMMENT 'Position ID for trade-related first actions. Default 0 = not applicable. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN CampaignID COMMENT 'Marketing campaign active at time of first action. Default 0 = no campaign. JOINs to Dim_Campaign. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN BonusTypeID COMMENT 'Bonus type associated with the first action. Default 0 = none. JOINs to Dim_BonusType. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN FundingTypeID COMMENT 'Funding method for the first deposit/withdrawal. Default 0 = not applicable. JOINs to Dim_FundingType. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN LoginID COMMENT 'Login session ID for the first action. Default 0 = not applicable. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN MirrorID COMMENT 'Copy trading mirror ID if the first action was a copy trade. Default 0 = not a copy trade. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN WithdrawID COMMENT 'Withdrawal transaction ID for first withdrawal actions. Default 0 = not applicable. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN PostID COMMENT 'Social feed post ID if the first action was a social interaction. NULL if not applicable. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN CaseID COMMENT 'Support case ID if the first action was case-related. Default 0 = not applicable. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN UpdateDate COMMENT 'ETL timestamp - GETDATE() during MERGE execution. (Tier 2 - SP_Fact_FirstCustomerAction)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN UpdateDateID COMMENT 'Date portion of UpdateDate in YYYYMMDD format (ETL lineage key; BI Dictionary references first-deposit and milestone dates in DWH). (Tier 4 - Confluence, BI Dictionary)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN DateID COMMENT 'Date of the first action in YYYYMMDD format. JOINs to Dim_Date. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN TimeID COMMENT 'Time of the first action in HHMMSS format. JOINs to Dim_Time. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN CompensationReasonID COMMENT 'Reason for compensation if the first action was a compensation event. Default 0 = not applicable. JOINs to Dim_CompensationReason. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN WithdrawPaymentID COMMENT 'Payment method ID for first withdrawal. Default 0 = not applicable. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN DepositID COMMENT 'Deposit transaction ID for first deposit actions. NULL if not a deposit. (Tier 2 - Fact_CustomerAction passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN HistoryID COMMENT 'Unique history event identifier from production. Links back to Fact_CustomerAction.HistoryID. Used as secondary MERGE key. (Tier 2 - SP_Fact_FirstCustomerAction)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN FirstEver COMMENT '1 = absolute first time this GCID performed this ActionTypeID. 0 = unique HistoryID event captured via secondary MERGE. (Tier 2 - SP_Fact_FirstCustomerAction)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN DemoCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN FirstOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN IPNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN IsReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN ActionTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN PlatformTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN CampaignID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN BonusTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN FundingTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN LoginID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN MirrorID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN WithdrawID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN PostID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN CaseID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN UpdateDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN TimeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN CompensationReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN WithdrawPaymentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN HistoryID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN FirstEver SET TAGS ('pii' = 'none');
