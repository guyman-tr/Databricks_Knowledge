-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.Depot
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_depot
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_depot (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_depot SET TBLPROPERTIES (
    'comment' = 'Master registry of payment gateway endpoints; each row configures one (FundingType + PaymentType + Protocol) combination as a named "depot" through which deposits, cashouts, or refunds are routed. Source: etoro.Billing.Depot on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_depot SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'Depot',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN DepotID COMMENT 'Primary key. Manually assigned (no IDENTITY). Stable identifier referenced by deposits, MID settings, and routing tables. (Tier 1 - upstream wiki, etoro.Billing.Depot)';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN FundingTypeID COMMENT 'Payment method type (e.g., 1=CreditCard, 2=Wire, 6=Neteller, 8=MoneyBookers/Skrill). References Dictionary.FundingType implicitly (no FK constraint in DDL). 38 distinct values across 163 depots. (Tier 1 - upstream wiki, etoro.Billing.Depot)';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN PaymentTypeID COMMENT 'Direction of payment flow. FK to Dictionary.PaymentType (FK_DPMT_BDPT): 1=Deposit, 2=Cashout, 3=Refund. Indexed (BDPT_PAYMENTTYPE). (Tier 1 - upstream wiki, etoro.Billing.Depot)';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN ProtocolID COMMENT 'Payment processing protocol/gateway. FK to Dictionary.Protocol (FK_DPRT_BDPT). Identifies the specific API or connection used (e.g., Protocol 7=Neteller, Protocol 6=Wire, Protocol 8=MoneyBookers). Indexed (BDPT_PROTOCOL). (Tier 1 - upstream wiki, etoro.Billing.Depot)';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN Name COMMENT 'Human-readable depot name (e.g., ''MoneyBookers USD'', ''Neteller'', ''Wire''). UNIQUE (BDPT_NAME index). Used in admin dashboards, routing logs, and discrepancy reports. (Tier 1 - upstream wiki, etoro.Billing.Depot)';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN IsActive COMMENT 'Whether this depot is currently accepting transactions. 1=Active (eligible for routing); 0 or NULL=Inactive (excluded from routing). 114 of 163 rows are active. Queried as IsActive = 1 in routing logic. (Tier 1 - upstream wiki, etoro.Billing.Depot)';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN PayoutGeneration COMMENT 'Controls automated payout file generation capability: 1=enabled (system can generate payment batch files for this depot); 0=disabled (manual or provider-managed). Default=0. (Tier 1 - upstream wiki, etoro.Billing.Depot)';
ALTER TABLE main.billing.bronze_etoro_billing_depot ALTER COLUMN Features COMMENT 'Depot-specific configuration features in structured text (JSON or XML format). Used for newer integrations requiring behavioral flags (e.g., 3DS2 settings, specific API options). NULL or empty for most legacy depots. (Tier 1 - upstream wiki, etoro.Billing.Depot)';

