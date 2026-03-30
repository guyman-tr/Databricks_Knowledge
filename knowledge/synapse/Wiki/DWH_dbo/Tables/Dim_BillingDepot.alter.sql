-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_BillingDepot
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot SET TBLPROPERTIES (
    'comment' = 'Dim_BillingDepot is the DWH version of etoro.Billing.Depot -- the central payment gateway routing configuration table. Each row defines one payment depot: a named combination of payment method (FundingTypeID), payment direction (PaymentTypeID: Deposit/Cashout/Refund), and processing gateway (ProtocolID). The routing engine selects a depot to process each transaction based on these three dimensions plus customer-specific factors (regulation, BIN, quotas). Source: etoro.Billing.Depot on etoroDB-REAL. The production table is exported daily to Bronze/etoro/Billing/Depot/ and staged into DWH_staging.etoro_Billing_Depot. SP_Dictionaries_DL_To_Synapse loads from that staging table using a TRUNCATE + INSERT pattern. 163 rows total (DepotID range 1-174 with gaps); 114 active (70%), 49 inactive (legacy or decommissioned). The DWH includes only 7 of the 8 production columns -- PayoutGeneration and Features are excluded by the ETL SELECT. Sample depots: 1=MoneyBookers USD, 7=Neteller, 10=Wire, 3=WebMoney, 4=Giropay. S...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot SET TAGS (
    'domain' = 'billing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (DepotID)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN DepotID COMMENT 'Primary key. Manually assigned (no IDENTITY). Stable identifier for this payment gateway endpoint. Range 1-174 with gaps; 163 rows. Referenced by fact deposit/cashout tables and MID settings. (Tier 1 - upstream wiki, Billing.Depot)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN FundingTypeID COMMENT 'Payment method type (e.g., 1=CreditCard, 2=Wire, 6=Neteller, 8=MoneyBookers/Skrill). References Dictionary.FundingType. 38 distinct values across 163 depots. (Tier 1 - upstream wiki, Billing.Depot)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN PaymentTypeID COMMENT 'Direction of payment flow. 1=Deposit, 2=Cashout, 3=Refund. References Dictionary.PaymentType. (Tier 1 - upstream wiki, Billing.Depot)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN ProtocolID COMMENT 'Payment processing protocol/gateway. References Dictionary.Protocol. Identifies the specific API or connection (e.g., Protocol 7=Neteller, Protocol 6=Wire, Protocol 8=MoneyBookers). (Tier 1 - upstream wiki, Billing.Depot)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN Name COMMENT 'Human-readable depot name (e.g., ''MoneyBookers USD'', ''Neteller'', ''Wire''). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. (Tier 1 - upstream wiki, Billing.Depot)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN IsActive COMMENT 'Whether this depot currently accepts transactions. 1=Active (eligible for routing); 0 or NULL=Inactive (excluded from routing). 114 of 163 rows are active. (Tier 1 - upstream wiki, Billing.Depot)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect when the production depot configuration changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN DepotID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN FundingTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN PaymentTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN ProtocolID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN IsActive SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:38:25 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 16/16 succeeded
-- ====================
