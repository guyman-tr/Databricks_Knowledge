-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.Funding_DataFactory
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_funding_datafactory
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_funding_datafactory (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory SET TBLPROPERTIES (
    'comment' = 'Azure Data Factory integration view exposing the core Billing.Funding columns (excluding computed hash/dedup fields) with the pre-computed PaymentDetails trigger column, for ETL pipeline consumption. Source: etoro.Billing.Funding_DataFactory on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'Funding_DataFactory',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN FundingID COMMENT 'Payment instrument PK. From Billing.Funding. IDENTITY(1000,1). (Tier 1 - upstream wiki, etoro.Billing.Funding_DataFactory)';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN FundingTypeID COMMENT 'Payment method type. From Billing.Funding. 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 33=eToroMoney, etc. (Tier 1 - upstream wiki, etoro.Billing.Funding_DataFactory)';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN ManagerID COMMENT 'Operations manager ID. NULL=self-registered. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.Funding_DataFactory)';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN IsBlocked COMMENT '1=instrument blocked. 0=active. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.Funding_DataFactory)';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN BlockedDescription COMMENT 'Block reason text. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.Funding_DataFactory)';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN BlockedAt COMMENT 'Block timestamp. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.Funding_DataFactory)';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN FundingData COMMENT 'Provider-specific instrument data as native XML. Not CAST to NVARCHAR (unlike other Funding views). Subject to DDM masking. ADF pipelines must handle XML serialization. (Tier 1 - upstream wiki, etoro.Billing.Funding_DataFactory)';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN IsRefundExcluded COMMENT '1=excluded from automatic refund. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.Funding_DataFactory)';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN DocumentRequired COMMENT '1=KYC documentation required. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.Funding_DataFactory)';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN DateCreated COMMENT 'UTC timestamp of instrument registration. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.Funding_DataFactory)';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN PaymentDetails COMMENT 'Pre-computed human-readable payment account identifier. Trigger-maintained column from Billing.Funding (populated by TR_FundingPaymentDetails via Billing.FormatFundingPaymentDetailsForWithdraw on each FundingData change). Unlike other views where PaymentDetails is computed in the view''s CASE expression, this is a stored column from the base table. (Tier 1 - upstream wiki, etoro.Billing.Funding_DataFactory)';

