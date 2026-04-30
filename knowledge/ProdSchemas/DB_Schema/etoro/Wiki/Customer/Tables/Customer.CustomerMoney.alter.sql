-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Customer.CustomerMoney
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_customer_customermoney
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_customer_customermoney (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_customer_customermoney SET TBLPROPERTIES (
    'comment' = 'The current balance table for all 18.7M customers: one row per CID storing Credit (available cash), BonusCredit, RealizedEquity, TotalCash, and BSLRealFunds - all USD-denominated. As of March 2026, this table is being replaced by a split multi-currency architecture (CustomerMoneyByCurrency + CustomerAccount), after which CustomerMoney will become a backward-compatible VIEW. Source: etoro.Customer.CustomerMoney on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_customer_customermoney SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Customer',
    'source_table' = 'CustomerMoney',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_customer_customermoney ALTER COLUMN CID COMMENT 'Customer ID - primary key. Matches CID in Customer.CustomerStatic. One row per customer. (Tier 1 - upstream wiki, etoro.Customer.CustomerMoney)';
ALTER TABLE main.bi_db.bronze_etoro_customer_customermoney ALTER COLUMN GCID COMMENT 'Group Customer ID - same as Customer.CustomerStatic.GCID. Redundant storage for lookup performance - avoids join to CustomerStatic for GCID resolution. Confirmed as account-level field (not per-currency) in multi-currency design. (Tier 1 - upstream wiki, etoro.Customer.CustomerMoney)';
ALTER TABLE main.bi_db.bronze_etoro_customer_customermoney ALTER COLUMN Credit COMMENT 'Current available cash balance in USD. The primary trading balance - what the customer can use to open positions. Updated by every financial event (deposit, withdrawal, position open/close, fee, bonus). Classified as per-currency in the upcoming multi-currency migration (Credit becomes per CID+CurrencyId). (Tier 1 - upstream wiki, etoro.Customer.CustomerMoney)';
ALTER TABLE main.bi_db.bronze_etoro_customer_customermoney ALTER COLUMN BonusCredit COMMENT 'Promotional/bonus credits, separate from real funds. Default = 0. Confirmed as account-level (USD-only) in multi-currency design (March 8 decision). (Tier 1 - upstream wiki, etoro.Customer.CustomerMoney)';
ALTER TABLE main.bi_db.bronze_etoro_customer_customermoney ALTER COLUMN RealizedEquity COMMENT 'Running total of realized value: increases on deposits and position close proceeds, decreases on withdrawals. Answers "how much has the customer realized?" Confirmed as account-level (single USD number) in multi-currency design - Mor: "Realized equity is per account." (Tier 1 - upstream wiki, etoro.Customer.CustomerMoney)';
ALTER TABLE main.bi_db.bronze_etoro_customer_customermoney ALTER COLUMN TotalCash COMMENT 'Reconciled cash total maintained by Trade.UpdateTotalCash reconciliation job. Uses dtPrice UDT (higher decimal precision than money). Per-currency vs account-level classification is open in multi-currency design. (Tier 1 - upstream wiki, etoro.Customer.CustomerMoney)';
ALTER TABLE main.bi_db.bronze_etoro_customer_customermoney ALTER COLUMN BSLRealFunds COMMENT 'Real funds threshold for Balance Stop Loss (BSL) system. Updated by PostMIMOOperations. When customer equity drops to this level, BSL liquidation triggers. BSL is account-wide (USD aggregate), confirmed as account-level field. Default = 0. (Tier 1 - upstream wiki, etoro.Customer.CustomerMoney)';

