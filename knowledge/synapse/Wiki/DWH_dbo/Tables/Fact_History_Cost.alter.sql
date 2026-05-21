-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_History_Cost
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost SET TBLPROPERTIES (
    'comment' = 'DWH_dbo.Fact_History_Cost > Granular record of every cost (fee, commission, spread cost, overnight fee) charged on trading operations - capturing the cost value in both account and asset currencies, the calculation method, and links to the position/order/credit that triggered it. | Property | Value | |----------|-------| | **Schema** | DWH_dbo | | **Object Type** | Table (Fact - transactional) | | **Row Count** | Hundreds of millions (one row per cost event) | | **Production Source** | `HistoryCosts.History.Costs` via `DWH_staging.HistoryCosts_History_Costs` | | **Refresh** | Daily - DELETE for date + INSERT from staging | | | | | **Synapse Distribution** | HASH(CostID) | | **Synapse Index** | CLUSTERED COLUMNSTORE INDEX | | **Synapse PK** | (DateID, CostID, CID) NOT ENFORCED | | | | | **UC Target** | _Pending - resolved during write-objects_ | | **UC Format** | _Pending - resolved durin'
);

-- ---- Table Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost SET TAGS (
    'source_schema' = 'DWH_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CostID COMMENT 'Unique identifier for this cost event. Distribution key. PK component. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CID COMMENT 'Customer ID (Real account) who was charged this cost. PK component. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN PartitionCol COMMENT 'Application-level partition column from source system. (Tier 4 - inferred from staging passthrough)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN MirrorID COMMENT 'Copy trading mirror relationship ID if cost is related to a copy trade. NULL if direct trade. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CostConfigurationID COMMENT 'Reference to the cost configuration rule that generated this charge. JOINs to Dim_CostConfigurationId. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN ValueInAccountCurrency COMMENT 'Cost amount in the customer''s account currency. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN ValueInAssetCurrency COMMENT 'Cost amount in the underlying asset''s currency. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN ConversionRate COMMENT 'Exchange rate used to convert between asset currency and account currency. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CalculationTypeID COMMENT 'Method used to compute the cost (e.g., flat, percentage, per-unit). JOINs to Dim_CalculationType. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CostConfigValue COMMENT 'Configuration parameter value used in the cost calculation (e.g., fee percentage, flat fee amount). (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN IsIncludedInTransactionValue COMMENT 'Whether the cost was embedded in the transaction price (1=included, e.g., spread) or charged separately (0=standalone, e.g., commission). (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN TransactionUnits COMMENT 'Number of units (shares, lots) involved in the transaction that triggered this cost. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CostCurrencyID COMMENT 'Currency in which the cost was originally calculated. JOINs to Dim_Currency. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN BalanceCurrencyID COMMENT 'Customer''s account balance currency. JOINs to Dim_Currency. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN AssetCurrencyID COMMENT 'Currency of the underlying asset. JOINs to Dim_Currency. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN ActionTypeID COMMENT 'Type of customer action that triggered this cost. JOINs to Dim_ActionType. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN OperationTypeID COMMENT 'Operation type within the action. JOINs to Dim_ExecutionOperationType. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CostTypeID COMMENT 'High-level cost category (spread, overnight, commission). JOINs to Dim_CostType. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CostSubTypeID COMMENT 'Detailed cost sub-category. JOINs to Dim_CostSubtype. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN PositionID COMMENT 'Position that generated this cost. JOINs to Fact_Position. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN OrderID COMMENT 'Order that generated this cost. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CreditID COMMENT 'Credit/bonus event that generated this cost. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN Occurred COMMENT 'Timestamp when the cost event occurred. Business event time. (Tier 2 - DWH_staging.HistoryCosts_History_Costs)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN DateID COMMENT 'Date of the cost event in YYYYMMDD integer format. Computed as CONVERT(INT, CONVERT(VARCHAR(10), Occurred, 112)). PK component. (Tier 2 - SP_Fact_History_Cost_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - GETDATE() during SP execution. (Tier 2 - SP_Fact_History_Cost)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CostID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN PartitionCol SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN MirrorID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CostConfigurationID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN ValueInAccountCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN ValueInAssetCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN ConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CalculationTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CostConfigValue SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN IsIncludedInTransactionValue SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN TransactionUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CostCurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN BalanceCurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN AssetCurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN ActionTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN OperationTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CostTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CostSubTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN OrderID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN CreditID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:18:37 UTC
-- Batch deploy resume: DWH_dbo deploy batch 9
-- Statements: 52/52 succeeded
-- ====================
